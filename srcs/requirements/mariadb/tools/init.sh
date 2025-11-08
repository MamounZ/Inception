#!/bin/bash

#Exit immediately if any command fails
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting MariaDB initialization...${NC}"

# Create the run directory for the socket file
echo -e "${YELLOW}Creating socket directory...${NC}"
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

# Check if database is already initialized
# -d : path is a directory
if [ -d "/var/lib/mysql/mysql" ]; then
    echo -e "${YELLOW}Database already initialized.${NC}"
else
    echo -e "${YELLOW}Initializing database...${NC}"
    
    # Install the database (create system tables)
    #--user=mysql : Run as mysql user (not root)
    #--datadir=/var/lib/mysql : Where to create database files
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    echo -e "${GREEN}Database installed.${NC}"
fi

# Start MariaDB in the background temporarily
# --skip-networking : Don't listen on TCP/IP ports
# & : Runs command in background, Script continues immediately, Command runs in parallel
# why run it in the background : We need MariaDB running, But also need to execute more commands, Start in background, configure, then stop it
echo -e "${YELLOW}Starting MariaDB temporarily...${NC}"
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
# $! : PID of last background process
MYSQL_PID=$!

# Wait for MariaDB to be ready
# 2>/dev/null : Redirect stderr to /dev/null file(Black hole (discard))
echo -e "${YELLOW}Waiting for MariaDB to be ready...${NC}"
for i in {30..0}; do
    if mysqladmin ping --silent 2>/dev/null; then
        break
    fi
    echo -e "${YELLOW}Waiting for MariaDB... $i${NC}"
    sleep 1
done

if [ "$i" = 0 ]; then
    echo -e "${RED}MariaDB failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}MariaDB is ready!${NC}"

# Configure database and users
echo -e "${YELLOW}Setting up database and users...${NC}"
mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOF
-- Set root password (currently root has no password)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Remove anonymous users (security)
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely (security)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Flush privileges to ensure they take effect
FLUSH PRIVILEGES;
EOF

echo -e "${GREEN}Database and users configured successfully!${NC}"

# Stop the temporary MariaDB instance
echo -e "${YELLOW}Stopping temporary MariaDB instance...${NC}"
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown

# Wait for the process to stop
wait $MYSQL_PID

echo -e "${GREEN}Starting MariaDB in foreground...${NC}"

# Start MariaDB in foreground (container will keep running)
# --bind-address=0.0.0.0 : Listen on all network interfaces
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
EOF


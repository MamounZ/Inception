#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}WordPress Setup Starting...${NC}"
echo -e "${GREEN}================================${NC}"

# Function to wait for MariaDB
wait_for_db() {
    echo -e "${YELLOW}Waiting for MariaDB to be ready...${NC}"
    # -h hostname = mariadb
    # -e execute query "SELECT 1" "wordpress(database)"
    for i in {60..0}; do
        if mysql -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" "${MYSQL_DATABASE}" >/dev/null 2>&1; then
            echo -e "${GREEN}MariaDB is ready!${NC}"
            return 0
        fi
        
        if [ $i -eq 0 ]; then
            echo -e "${RED}MariaDB failed to become ready in time${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Waiting for MariaDB... $i seconds remaining${NC}"
        sleep 1
    done
}

# Wait for MariaDB
wait_for_db

# Check if WordPress is already installed
# -f : file
if [ -f /var/www/html/wp-config.php ]; then
    echo -e "${BLUE}WordPress is already installed.${NC}"
else
    echo -e "${YELLOW}WordPress not found. Installing...${NC}"
    
    # Download WordPress
    # wp core download : Downloads latest WordPress version, Creates WordPress file structure
    # --allow-root : allows root execution
    echo -e "${YELLOW}Downloading WordPress...${NC}"
    wp core download --allow-root
    echo -e "${GREEN}WordPress downloaded successfully!${NC}"
    
    # Create wp-config.php
    echo -e "${YELLOW}Creating wp-config.php...${NC}"
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --dbcharset="utf8" \
        --dbcollate="utf8_general_ci" \
        --allow-root
    echo -e "${GREEN}wp-config.php created!${NC}"
    
    # Install WordPress
    # wp core install : Creates database tables,  Creates admin user, Makes WordPress operational
    echo -e "${YELLOW}Installing WordPress...${NC}"
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    echo -e "${GREEN}WordPress installed successfully!${NC}"
    
    # Create additional user
    echo -e "${YELLOW}Creating additional user...${NC}"
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
    echo -e "${GREEN}User '${WP_USER}' created successfully!${NC}"
    
    # Update URLs to HTTPS
    # if we didnt update the urls to https it might defaults to http
    wp option update home "https://${DOMAIN_NAME}" --allow-root
    wp option update siteurl "https://${DOMAIN_NAME}" --allow-root
    echo -e "${GREEN}Site URLs updated to HTTPS${NC}"
fi

# Set permissions
# find <path> <options> <action>
# -type d : Find only directories (not files)
# -type f : Find only files (not directories)
echo -e "${YELLOW}Setting file permissions...${NC}"
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
echo -e "${GREEN}Permissions set!${NC}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}WordPress setup complete!${NC}"
echo -e "${GREEN}Starting PHP-FPM...${NC}"
echo -e "${GREEN}================================${NC}"

# Start PHP-FPM in foreground
# PHP FastCGI Process Manager : handle PHP requests efficiently, and it...
    # 1.Runs the PHP code.
    # 2.Returns the generated HTML back to Nginx.
    # 3.Nginx then sends that HTML to the user’s browser.
# -F flag (Foreground)
# -R flag (Allow root)
exec php-fpm7.4 -F -R

# Start from Debian Bullseye (stable, well-supported)
FROM debian:bullseye

# Update package list and install MariaDB server
# --no-install-recommends: Don't install recommended packages (smaller image)
# rm -rf /var/lib/apt/lists/*: Clean up to reduce image size
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy our custom MariaDB configuration
# This tells MariaDB to listen on all interfaces (0.0.0.0)
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy our initialization script
COPY tools/init.sh /usr/local/bin/init.sh

# Make the script executable
RUN chmod +x /usr/local/bin/init.sh

# Expose port 3306 (standard MySQL/MariaDB port)
# This doesn't actually publish the port, just documents it
EXPOSE 3306

# Run our initialization script when container starts
ENTRYPOINT ["init.sh"]

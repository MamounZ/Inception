FROM debian:bullseye

# Install PHP-FPM and all required extensions
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    php7.4-intl \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Download and install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Completely remove the default www.conf
RUN rm -f /etc/php/7.4/fpm/pool.d/www.conf

# Create our own www.conf with correct settings
RUN printf '[www]\n\
user = www-data\n\
group = www-data\n\
listen = 0.0.0.0:9000\n\
pm = dynamic\n\
pm.max_children = 5\n\
pm.start_servers = 2\n\
pm.min_spare_servers = 1\n\
pm.max_spare_servers = 3\n\
pm.max_requests = 500\n\
chdir = /var/www/html\n\
catch_workers_output = yes\n\
clear_env = no\n' > /etc/php/7.4/fpm/pool.d/www.conf

# Copy the setup script
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Create PHP-FPM runtime directory
RUN mkdir -p /run/php

# Set working directory
WORKDIR /var/www/html

# Expose port 9000
EXPOSE 9000

# Run the setup script
ENTRYPOINT ["setup.sh"]

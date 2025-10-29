FROM debian:bullseye

ARG DOMAIN_NAME=localhost

# Install NGINX, OpenSSL, and curl (for health checks)
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=JO/ST=Irbid/L=Irbid/O=42School/OU=42/CN=${DOMAIN_NAME}"

# Copy NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Replace ${DOMAIN_NAME} placeholder
RUN sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

# Create directory for PID file
RUN mkdir -p /var/run/nginx

# Expose port 443
EXPOSE 443

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]

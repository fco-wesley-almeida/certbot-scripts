#!/bin/bash

# Variables
DOMAIN=$1
NGINX_CERT_DIR="/etc/nginx/certs/$DOMAIN"
LETSENCRYPT_DIR="/etc/letsencrypt/live/$DOMAIN"

mkdir -p $NGINX_CERT_DIR
mkdir -p $LETSENCRYPT_DIR

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# Obtain SSL certificate with Certbot
echo "Obtaining SSL certificate for $DOMAIN..."

certbot certonly --standalone -d "$DOMAIN"

# Check if Certbot succeeded
if [ $? -ne 0 ]; then
  echo "Certbot failed to obtain the certificate. Please check the logs."
  exit 1
fi

# Create Nginx certificate directory if it doesn't exist
if [ ! -d "$NGINX_CERT_DIR" ]; then
  echo "Creating Nginx certificate directory: $NGINX_CERT_DIR"
  mkdir -p "$NGINX_CERT_DIR"
fi

# Copy certificates to Nginx directory
echo "Copying certificates to $NGINX_CERT_DIR..."
cp "$LETSENCRYPT_DIR/fullchain.pem" "$NGINX_CERT_DIR/server.crt"
cp "$LETSENCRYPT_DIR/privkey.pem" "$NGINX_CERT_DIR/server.key"

# Set permissions on the copied files
chmod 644 "$NGINX_CERT_DIR/server.crt"
chmod 600 "$NGINX_CERT_DIR/server.key"

# Restart Nginx
echo "Restarting Nginx..."
systemctl restart nginx

# Check if Nginx restarted successfully
if [ $? -eq 0 ]; then
  echo "Nginx restarted successfully. SSL setup is complete."
else
  echo "Failed to restart Nginx. Please check your Nginx configuration."
  exit 1
fi


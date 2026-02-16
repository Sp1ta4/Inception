#!/bin/bash
set -e

echo "Starting Nginx container..."

certs.sh

sed -i "s/DOMAIN_NAME_PLACEHOLDER/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

nginx -t

echo "Nginx configuration validated"
echo "Starting Nginx..."

exec nginx -g 'daemon off;'
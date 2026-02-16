#!/bin/bash

if [ -f /etc/ssl/certs/certificate.crt ]; then
    echo "TLS certificate already exists"
    exit 0
fi

echo "Generating TLS certificate..."

mkdir -p /etc/ssl/private /etc/ssl/certs

openssl req -x509 -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/private.key \
    -out /etc/ssl/certs/certificate.crt \
    -subj "/C=AM/ST=Yerevan/L=Yerevan/O=42/OU=Inception/CN=${DOMAIN_NAME}"

chmod 600 /etc/ssl/private/private.key
chmod 644 /etc/ssl/certs/certificate.crt

echo "TLS certificate generated successfully"
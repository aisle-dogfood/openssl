#!/bin/sh

# Generate ephemeral keys and certificates for the sslecho demo
# This script generates fresh keys at runtime to avoid using hard-coded keys

echo "Generating ephemeral private key and self-signed certificate for sslecho demo..."

# Determine OpenSSL command location
if [ -x "../../apps/openssl" ]; then
    OPENSSL="../../apps/openssl"
    export LD_LIBRARY_PATH=../..
else
    OPENSSL="openssl"
fi

# Generate a new private key
$OPENSSL genrsa -out key.pem 4096 2>/dev/null

# Generate a self-signed certificate
$OPENSSL req -new -x509 -key key.pem -out cert.pem -days 365 -subj "/CN=localhost" 2>/dev/null

echo "Generated key.pem and cert.pem for localhost"
echo "WARNING: These are for demo purposes only. Never use in production!"

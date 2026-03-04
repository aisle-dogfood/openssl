#!/bin/sh
# Script to generate test certificates and keys for OpenSSL Guide demos
# This script should be run before running the demo programs

opensslcmd() {
    LD_LIBRARY_PATH=../.. ../../apps/openssl "$@"
}

OPENSSL_CONF=../../apps/openssl.cnf
export OPENSSL_CONF

echo "Generating test certificates and keys for OpenSSL Guide demos..."

# Generate root CA key and certificate
echo "Generating root CA certificate..."
opensslcmd req -x509 -newkey rsa:2048 -keyout rootkey.pem -out rootcert.pem \
    -days 3650 -nodes -subj "/CN=OpenSSL Test Root CA"

# Generate server key and certificate request
echo "Generating server certificate..."
opensslcmd req -newkey rsa:2048 -keyout serverkey.pem -out server_req.pem \
    -nodes -subj "/CN=localhost"

# Sign the server certificate with the root CA
opensslcmd x509 -req -in server_req.pem -CA rootcert.pem -CAkey rootkey.pem \
    -CAcreateserial -out servercert.pem -days 3650

# Clean up intermediate files
rm -f server_req.pem

echo "Test certificates and keys generated successfully!"
echo "Files created: rootkey.pem, rootcert.pem, serverkey.pem, servercert.pem"

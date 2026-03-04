#!/bin/sh
# Script to generate test certificates and keys for BIO demos
# This script should be run before running the demo programs

opensslcmd() {
    LD_LIBRARY_PATH=../.. ../../apps/openssl "$@"
}

OPENSSL_CONF=../../apps/openssl.cnf
export OPENSSL_CONF

echo "Generating test certificates and keys for BIO demos..."

# Generate RSA server certificate and private key
echo "Generating RSA server certificate..."
opensslcmd req -x509 -newkey rsa:2048 -keyout server_key.pem -out server_cert.pem \
    -days 3650 -nodes -subj "/CN=localhost/OU=Test Certificate"

# Combine certificate and key into server.pem
cat server_cert.pem server_key.pem > server.pem

# Generate EC server certificate and private key
echo "Generating EC server certificate..."
opensslcmd req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
    -keyout server_ec_key.pem -out server_ec_cert.pem \
    -days 3650 -nodes -subj "/CN=localhost/OU=Test ECDSA Certificate"

# Combine certificate and key into server-ec.pem
cat server_ec_key.pem server_ec_cert.pem > server-ec.pem

# Clean up intermediate files
rm -f server_cert.pem server_key.pem
rm -f server_ec_cert.pem server_ec_key.pem

echo "Test certificates and keys generated successfully!"
echo "Files created: server.pem, server-ec.pem"

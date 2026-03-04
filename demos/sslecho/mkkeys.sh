#!/bin/sh
# Script to generate test certificate and key for SSL echo demo
# This script should be run before running the demo program

opensslcmd() {
    LD_LIBRARY_PATH=../.. ../../apps/openssl "$@"
}

OPENSSL_CONF=../../apps/openssl.cnf
export OPENSSL_CONF

echo "Generating test certificate and key for SSL echo demo..."

# Generate server certificate and private key
opensslcmd req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
    -days 3650 -nodes -subj "/CN=localhost/O=OpenSSL Demo"

echo "Test certificate and key generated successfully!"
echo "Files created: key.pem, cert.pem"

#!/bin/sh

# Script to generate test certificates and keys for CMS demos
# This script should be run before running the CMS demo programs

set -e

opensslcmd() {
    LD_LIBRARY_PATH=../.. ../../apps/openssl "$@"
}

# Check if we can use the built OpenSSL, otherwise fall back to system OpenSSL
if [ ! -f "../../apps/openssl" ]; then
    echo "Warning: ../../apps/openssl not found, using system openssl"
    opensslcmd() {
        openssl "$@"
    }
    unset OPENSSL_CONF
else
    OPENSSL_CONF=../../apps/openssl.cnf
    export OPENSSL_CONF
fi

echo "Generating certificates and keys for CMS demos..."

# Create Root CA certificate and key
echo "Creating Root CA..."
opensslcmd req -x509 -nodes \
    -keyout cacert.pem -out cacert.pem -newkey rsa:3072 -days 3650 \
    -subj "/C=UK/L=Test City/O=OpenSSL Group/CN=Test S/MIME Root CA"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create Root CA certificate"
    exit 1
fi

# Extract the CA key to a separate file (for consistency with existing setup)
opensslcmd pkey -in cacert.pem -out cakey.pem

# Create first signer certificate and key
echo "Creating signer 1..."
opensslcmd req -nodes -keyout signer_key.pem -out signer_req.pem -newkey rsa:2048 \
    -subj "/C=UK/CN=OpenSSL test S/MIME signer 1/emailAddress=test1@openssl.org"

# Sign the first signer certificate
opensslcmd x509 -req -in signer_req.pem -CA cacert.pem -CAkey cakey.pem \
    -CAcreateserial -days 3650 -out signer_cert.pem

# Combine certificate and key into signer.pem (certificate first, then key)
cat signer_cert.pem signer_key.pem > signer.pem

# Create second signer certificate and key
echo "Creating signer 2..."
opensslcmd req -nodes -keyout signer2_key.pem -out signer2_req.pem -newkey rsa:2048 \
    -subj "/C=UK/CN=OpenSSL test S/MIME signer 2/emailAddress=test2@openssl.org"

# Sign the second signer certificate
opensslcmd x509 -req -in signer2_req.pem -CA cacert.pem -CAkey cakey.pem \
    -CAcreateserial -days 3650 -out signer2_cert.pem

# Combine certificate and key into signer2.pem (certificate first, then key)
cat signer2_cert.pem signer2_key.pem > signer2.pem

# Clean up temporary files
rm -f signer_req.pem signer_cert.pem signer_key.pem
rm -f signer2_req.pem signer2_cert.pem signer2_key.pem
rm -f cacert.srl

echo ""
echo "Certificate generation complete!"
echo "Generated files:"
echo "  - cacert.pem (Root CA certificate)"
echo "  - cakey.pem (Root CA private key)"
echo "  - signer.pem (First signer certificate and key)"
echo "  - signer2.pem (Second signer certificate and key)"
echo ""

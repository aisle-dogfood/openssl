#!/bin/sh
# Script to generate test certificates and keys for CMS demos
# This script should be run before running the demo programs

opensslcmd() {
    LD_LIBRARY_PATH=../.. ../../apps/openssl "$@"
}

OPENSSL_CONF=../../apps/openssl.cnf
export OPENSSL_CONF

echo "Generating test certificates and keys for CMS demos..."

# Generate CA certificate and private key
echo "Generating CA certificate..."
opensslcmd req -x509 -newkey rsa:2048 -keyout cakey.pem -out cacert.pem \
    -days 3650 -nodes -subj "/C=UK/O=OpenSSL Group/CN=Test S/MIME Root CA"

# Generate first signer certificate and private key
echo "Generating signer certificate..."
opensslcmd req -newkey rsa:2048 -keyout signer_key.pem -out signer_req.pem \
    -nodes -subj "/C=UK/CN=OpenSSL test S/MIME signer 1/emailAddress=test1@openssl.org"

# Sign the signer certificate with the CA
opensslcmd x509 -req -in signer_req.pem -CA cacert.pem -CAkey cakey.pem \
    -CAcreateserial -out signer_cert.pem -days 3650

# Combine certificate and key into signer.pem
cat signer_cert.pem signer_key.pem > signer.pem

# Generate second signer certificate and private key
echo "Generating second signer certificate..."
opensslcmd req -newkey rsa:2048 -keyout signer2_key.pem -out signer2_req.pem \
    -nodes -subj "/C=UK/CN=OpenSSL test S/MIME signer 2/emailAddress=test2@openssl.org"

# Sign the second signer certificate with the CA
opensslcmd x509 -req -in signer2_req.pem -CA cacert.pem -CAkey cakey.pem \
    -CAcreateserial -out signer2_cert.pem -days 3650

# Combine certificate and key into signer2.pem
cat signer2_cert.pem signer2_key.pem > signer2.pem

# Clean up intermediate files
rm -f signer_req.pem signer_cert.pem signer_key.pem
rm -f signer2_req.pem signer2_cert.pem signer2_key.pem

echo "Test certificates and keys generated successfully!"
echo "Files created: cacert.pem, cakey.pem, signer.pem, signer2.pem"

⚠️  SECURITY WARNING ⚠️
========================
The private keys in the apps/ subdirectory (rootkey.pem, intkey.pem, skey.pem,
skey2.pem, ckey.pem) are PUBLICLY AVAILABLE in this repository and are FOR
DEMONSTRATION AND TESTING PURPOSES ONLY.

NEVER use these keys in production environments or publicly accessible systems.
Using these keys in production would provide NO security as they are publicly
known and anyone can impersonate your services.

See SECURITY.md for complete security guidance.

Demo Certificate Generation Scripts
====================================
There is often a need to generate test certificates automatically using
a script. This is often a cause for confusion which can result in incorrect
CA certificates, obsolete V1 certificates or duplicate serial numbers.
The range of command line options can be daunting for a beginner.

The mkcerts.sh script is an example of how to generate certificates
automatically using scripts. Example creates a root CA, an intermediate CA
signed by the root and several certificates signed by the intermediate CA.

The script then creates an empty index.txt file and adds entries for the
certificates and generates a CRL. Then one certificate is revoked and a
second CRL generated.

The script ocsprun.sh runs the test responder on port 8888 covering the
client certificates.

The script ocspquery.sh queries the status of the certificates using the
test responder.

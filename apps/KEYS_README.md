# Test Keys for OpenSSL

This directory previously contained example private keys used for testing and documentation purposes. For security reasons, private keys should not be committed to version control.

## Generating Test Keys

If you need to generate test keys for development or testing purposes, use the following OpenSSL commands:

### Generate PCA (Private Certificate Authority) Key

```bash
# Generate a 1024-bit RSA private key (for testing only - use 2048+ bits in production)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:1024 -out apps/pca-key.pem
```

### Generate Other Test Keys

```bash
# Generate a 512-bit RSA private key (for testing only)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:512 -out apps/s512-key.pem

# Generate a 1024-bit RSA private key (for testing only)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:1024 -out apps/s1024key.pem
```

## Security Notice

**IMPORTANT**: 
- Never commit private keys to version control
- The keys generated above are for testing purposes only
- In production environments, use keys with at least 2048 bits
- Store production private keys securely using proper key management systems
- These test keys are included in `.gitignore` to prevent accidental commits

## Usage in Documentation

Some documentation examples may reference `pca-key.pem` or other key files. Generate them locally using the commands above before running those examples.

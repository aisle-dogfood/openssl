# Security Notice: Demo Private Keys

**WARNING: This directory contains PRIVATE KEYS for demonstration purposes only!**

## Affected Files

All `.pem` files in this directory contain RSA private keys that are hard-coded demo fixtures:

- `ckey.pem` - Client demo private key
- `skey.pem` - Server demo private key
- `skey2.pem` - Additional server demo private key
- `intkey.pem` - Intermediate CA demo private key (used by mkacerts.sh)
- `rootkey.pem` - Root CA demo private key

## Security Requirements

These private keys:
- **MUST NEVER** be used in production environments
- **MUST BE EXCLUDED** from production distributions
- **ARE ONLY** for demonstrating certificate generation and SSL/TLS functionality

## Special Note: intkey.pem

The `intkey.pem` file is used by `mkacerts.sh` to sign demo certificates. If packaging 
processes are not careful, this intermediate CA key could be incorporated into demo 
artifacts. This key must remain test-only and never be distributed.

## For Distributors

**EXCLUDE** all `.pem` files from this directory in production packages.

## For Developers

These keys are for demonstrating OpenSSL certificate and SSL/TLS functionality.
Generate new keys for any real-world usage.

See `SECURITY-DEMO-KEYS.md` in the repository root for complete details.
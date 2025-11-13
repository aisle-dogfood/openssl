# Security Notice: ML-KEM Test Private Keys

**WARNING: This directory contains PRIVATE KEYS for testing purposes only!**

## Affected Files

All `.pem` files in this directory contain ML-KEM private keys that are hard-coded test fixtures:

- `prv-512-*.pem` - ML-KEM-512 test private keys
- `prv-768-*.pem` - ML-KEM-768 test private keys  
- `prv-1024-*.pem` - ML-KEM-1024 test private keys

## Security Requirements

These private keys:
- **MUST NEVER** be used in production environments
- **MUST BE EXCLUDED** from production distributions
- **ARE ONLY** for testing ML-KEM codec functionality

## For Distributors

**EXCLUDE** all `.pem` files from this directory in production packages.

## For Developers

These keys are test vectors for validating ML-KEM implementation correctness. 
Generate new keys for any real-world usage.

See `SECURITY-DEMO-KEYS.md` in the repository root for complete details.
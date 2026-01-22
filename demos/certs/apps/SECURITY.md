# Security Notice: Demo Private Keys

## WARNING: TEST-ONLY KEYS - DO NOT USE IN PRODUCTION

This directory contains hard-coded RSA private keys that are **ONLY** for demonstration and testing purposes:

- `ckey.pem` - Demo client private key
- `skey.pem` - Demo server private key
- `skey2.pem` - Demo server #2 private key
- `intkey.pem` - Demo intermediate CA private key
- `rootkey.pem` - Demo root CA private key

## Security Implications

These private keys are publicly accessible in the repository and **MUST NEVER** be used in production environments. Using these keys in production would expose your systems to credential compromise and unauthorized access.

## Proper Usage

### For Demonstrations
The `mkacerts.sh` script has been updated to generate ephemeral private keys at runtime. When running demos:

```bash
cd demos/certs/apps
./mkacerts.sh
```

This will generate fresh private keys for each demo run.

### For Packaging/Distribution
**These PEM files MUST be excluded from all production packages and distributions.**

Add exclusions in your packaging configuration:
- `demos/certs/apps/*.pem`
- `demos/sslecho/key.pem`
- `test/recipes/*/prv-*.pem`
- `test/recipes/*/evppkey_ml_kem_*_decap.txt`

## Alternative: Runtime Key Generation

For production or security-sensitive testing, always generate keys at runtime:

```bash
# Generate a new RSA key
openssl genrsa -out mykey.pem 2048

# Generate a new EC key
openssl ecparam -name prime256v1 -genkey -out mykey.pem
```

## References

- CWE-321: Use of Hard-coded Cryptographic Key
- This addresses the vulnerability regarding hard-coded private keys in the repository

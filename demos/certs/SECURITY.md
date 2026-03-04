# SECURITY NOTICE - Demo Certificates and Private Keys

**⚠️ WARNING: The private keys in this directory are FOR DEMONSTRATION AND TESTING PURPOSES ONLY.**

## Overview

This directory contains hard-coded RSA private keys and certificates that are **publicly available** in the OpenSSL repository. These materials are provided solely for:

- Local testing and development
- Demonstration of OpenSSL certificate generation
- Learning and educational purposes

## Security Impact

**These private keys MUST NEVER be used in production environments.**

Using these keys in production would expose your systems to immediate compromise because:

1. **Public Availability**: All keys are publicly visible in the OpenSSL repository and its Git history
2. **Known Credentials**: Anyone can access these private keys and impersonate your services
3. **No Security**: Any TLS/SSL connection using these keys provides NO actual security

## Files Affected

The following private key files are checked into this repository:

- `apps/rootkey.pem` - Demo root CA private key
- `apps/intkey.pem` - Demo intermediate CA private key  
- `apps/skey.pem` - Demo server private key
- `apps/skey2.pem` - Demo server private key #2
- `apps/ckey.pem` - Demo client private key

## Proper Usage

### ✅ Acceptable Use

- Running the demo scripts (`mkacerts.sh`, `mkxcerts.sh`) locally
- Learning how OpenSSL certificate chains work
- Testing OpenSSL applications in isolated development environments
- Unit testing and CI/CD test suites

### ❌ NEVER Use For

- Production web servers or services
- Any publicly accessible systems
- Distributed applications or packages
- Production PKI infrastructure
- Any environment where security matters

## For Packagers and Distributors

**IMPORTANT**: When creating distribution packages of OpenSSL:

1. **EXCLUDE** this entire `demos/certs/` directory from production packages
2. Demo materials should only be included in separate development/documentation packages
3. Verify that no demo private keys are inadvertently installed to system directories
4. Consider adding package build validation to detect hard-coded credentials

## For Developers

If you need certificates for testing:

1. **Generate ephemeral keys at runtime** for automated tests
2. Use the provided scripts as examples, but generate new keys locally
3. Never commit real private keys to version control
4. Use separate test-only certificates that are clearly marked

## Generating New Keys

To generate your own certificates for testing:

```bash
# Generate a new private key
openssl genpkey -algorithm RSA -out mykey.pem -pkeyopt rsa_keygen_bits:2048

# Generate a self-signed certificate
openssl req -new -x509 -key mykey.pem -out mycert.pem -days 365
```

## Vulnerability Classification

These hard-coded secrets are classified as **CWE-321: Use of Hard-coded Credentials**.

While acceptable for demonstration purposes, their presence requires careful handling to prevent:
- Accidental deployment to production systems
- Inclusion in software distributions
- Misuse by developers unfamiliar with their purpose

## Questions or Concerns

If you believe demo certificates have been accidentally deployed in production, or if you have questions about proper key management, please refer to the OpenSSL security policy.

---

**Last Updated**: 2024
**Classification**: Demo/Test Materials Only

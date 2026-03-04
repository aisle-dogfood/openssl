# Security Notice: Test and Demo Private Keys

## Overview

The OpenSSL repository contains hard-coded private keys in demonstration and test directories. This document explains their purpose, security implications, and proper handling.

## Executive Summary

**⚠️ CRITICAL: Private keys in `demos/` and `test/` directories are PUBLIC and must NEVER be used in production.**

These keys are intentionally committed for demonstration and testing purposes. They provide **zero security** if used outside these contexts because they are publicly accessible to anyone with repository access.

## Locations of Hard-coded Private Keys

### Demo Private Keys (`demos/`)

Purpose: Educational demonstrations and local testing

**Demo Certificate Infrastructure** (`demos/certs/apps/`):
- `rootkey.pem` - Demo Root CA private key
- `intkey.pem` - Demo Intermediate CA private key
- `skey.pem`, `skey2.pem` - Demo server private keys
- `ckey.pem` - Demo client private key

**SSL Echo Demo** (`demos/sslecho/`):
- `key.pem` - Demo SSL server private key

**Other Demo Keys**:
- `demos/guide/rootkey.pem`, `demos/guide/serverkey.pem`
- `demos/bio/server.pem` (contains embedded private key)
- `demos/cms/cakey.pem`, `demos/cms/signer.pem`, `demos/cms/signer2.pem`
- `demos/smime/cakey.pem`, `demos/smime/signer.pem`, `demos/smime/signer2.pem`

See: `demos/certs/SECURITY.md` for complete demo security guidance.

### Test Private Keys (`test/`)

Purpose: Automated testing, Known Answer Tests (KATs), codec validation

**Classical Cryptography**:
- RSA, DSA, EC, Ed25519, Ed448, X25519, X448, DH test keys
- Located in `test/recipes/*/` subdirectories
- Used for PEM/DER codec testing and cryptographic validation

**Post-Quantum Cryptography**:
- ML-KEM (Module-Lattice Key Encapsulation Mechanism): 512, 768, 1024-bit variants
- ML-DSA (Module-Lattice Digital Signature Algorithm): 44, 65, 87 parameter sets
- SLH-DSA fixtures (if present)

See: `test/recipes/SECURITY-NOTICE.md` for complete test fixture documentation.

## Vulnerability Classification

**CWE-321: Use of Hard-coded Credentials**

While these hard-coded credentials are appropriate for their intended demo/test purposes, they constitute a vulnerability if:
1. Accidentally included in production distributions
2. Mistakenly used in production environments
3. Installed to system directories by packaging errors

## Security Impact Analysis

### Risk: LOW (When Properly Handled)
- Test/demo keys are clearly isolated in dedicated directories
- No installation targets exist for demo/test materials
- Purpose is obvious from directory structure

### Risk: CRITICAL (If Misused)
Using these keys in production would:
- ❌ Provide **zero cryptographic security** (keys are public)
- ❌ Allow **anyone to impersonate** your services
- ❌ Enable **decryption** of supposedly secure communications
- ❌ Permit **signature forgery** using known private keys
- ❌ Violate **compliance requirements** (PCI-DSS, HIPAA, etc.)

## Mitigation and Best Practices

### For OpenSSL Users

**✅ DO**:
- Use demo/test keys ONLY for local learning and testing
- Generate new keys for any real-world use:
  ```bash
  openssl genpkey -algorithm RSA -out mykey.pem -pkeyopt rsa_keygen_bits:2048
  ```
- Treat demo code as educational examples only
- Regenerate keys at runtime for automated testing when possible

**❌ DON'T**:
- Never use demo/test keys in production
- Never distribute applications containing these keys
- Never deploy test certificates to public-facing systems

### For Package Maintainers

**Required Actions**:

1. **Exclude from Production Packages**:
   ```
   # Exclude these paths from production packages:
   /demos/certs/apps/*.pem
   /demos/sslecho/key.pem
   /demos/*/ca*.pem
   /demos/*/signer*.pem
   /test/recipes/*/*.priv.pem
   /test/recipes/*/evppkey_*_decap.txt
   ```

2. **Separate Test Packages**:
   - Ship test fixtures only in `-test` or `-dev` packages
   - Clearly mark such packages as development/testing only
   - Include security notices in package documentation

3. **Validation**:
   - Scan built packages for `-----BEGIN PRIVATE KEY-----`
   - Cross-reference against known test fixture paths
   - Implement CI/CD checks to prevent test key installation
   - Verify no files from `demos/` or `test/recipes/` are in production packages

4. **Documentation**:
   - Document package contents and intended use
   - Include this security notice in development packages
   - Provide guidance on proper key generation

### For OpenSSL Developers

**Development Guidelines**:
- Keep test fixtures in `test/` hierarchy
- Keep demo materials in `demos/` hierarchy
- Use consistent naming: `*key.pem` for private keys
- Document test-only nature in adjacent README files
- Never add production keys to repository

**Test Design**:
- Prefer ephemeral key generation where feasible
- Use fixed keys only when needed for:
  - Known Answer Tests (KAT)
  - Reproducible test results
  - Codec format validation

### For Security Auditors

**Assessment Points**:

1. **Verify Isolation**:
   - Confirm demo/test keys are not in main codebase
   - Check no references to test keys in production code
   - Validate install targets exclude test/demo paths

2. **Packaging Review**:
   - Audit distribution packages for hard-coded keys
   - Verify test fixtures are in separate packages
   - Confirm production packages contain no .pem private keys

3. **Documentation**:
   - Ensure security notices are present and visible
   - Verify README files warn about test-only nature
   - Check package metadata describes contents accurately

## Detection of Accidental Deployment

### Automated Detection

#### Package Validation Script

OpenSSL provides a validation script for package maintainers:

```bash
# Check a package installation for hard-coded keys
./util/check-hardcoded-keys.sh /path/to/install/prefix

# Example: Check system installation
./util/check-hardcoded-keys.sh /usr/local

# Example: Check package staging directory
./util/check-hardcoded-keys.sh /tmp/openssl-package-root
```

This script scans for PEM-encoded private keys and reports any found in
installation directories. Integrate it into your package build process.

#### Manual Detection

Scan for accidental deployment of test/demo keys:

```bash
# Find PEM-encoded private keys in installed locations
find /usr /opt -name "*.pem" -exec grep -l "BEGIN.*PRIVATE KEY" {} \;

# Check against known demo/test key fingerprints
openssl rsa -in /path/to/key.pem -noout -modulus | openssl md5
```

### Known Test Key Fingerprints

Demo keys can be identified by matching their public key fingerprints (documented separately for automation).

## Incident Response

If test/demo keys are discovered in production:

1. **Immediate Actions**:
   - Identify all systems using the compromised keys
   - Generate new keys with proper entropy
   - Replace certificates and redeploy

2. **Impact Assessment**:
   - Determine if systems were publicly accessible
   - Review logs for suspicious access patterns
   - Assess data exposure risk

3. **Remediation**:
   - Update deployment/packaging processes
   - Implement validation checks
   - Document lessons learned

4. **Prevention**:
   - Add CI/CD checks for hard-coded credentials
   - Implement package content validation
   - Train teams on key management

## Frequently Asked Questions

**Q: Why are private keys committed to the repository?**
A: Test keys enable reproducible Known Answer Tests and codec validation. Demo keys provide working examples for learning. They are clearly marked as test/demo only.

**Q: Is it safe to use these keys for internal testing?**
A: Only in completely isolated environments with no network exposure. For any networked testing, generate ephemeral keys.

**Q: How do I generate proper keys for production?**
A: Use `openssl genpkey` with appropriate algorithms and parameters. Never use pre-generated keys from any source.

**Q: Are these keys included in OpenSSL releases?**
A: Demo and test materials should not be in production packages. They may be in separate development/testing packages.

**Q: What if I already deployed a demo key?**
A: Immediately generate new keys, revoke affected certificates, and replace on all systems. Review access logs for potential compromise.

## References

- **CWE-321**: Use of Hard-coded Credentials
  https://cwe.mitre.org/data/definitions/321.html

- **OpenSSL Key Generation**:
  ```bash
  # RSA
  openssl genpkey -algorithm RSA -out key.pem -pkeyopt rsa_keygen_bits:2048
  
  # EC
  openssl genpkey -algorithm EC -out key.pem -pkeyopt ec_paramgen_curve:P-256
  
  # Ed25519
  openssl genpkey -algorithm Ed25519 -out key.pem
  ```

## Contact

For security concerns related to test/demo credentials:
- Review this document and related SECURITY.md files
- Follow OpenSSL security reporting guidelines for vulnerabilities
- Contact package maintainers for distribution-specific issues

---

**Document Version**: 1.0
**Last Updated**: 2024
**Classification**: Security Notice - Test/Demo Materials
**Applies To**: All OpenSSL versions containing demos/ and test/ directories

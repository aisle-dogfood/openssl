# SECURITY NOTICE - Test Private Keys and Fixtures

**⚠️ WARNING: This directory tree contains hard-coded private keys for testing purposes.**

## Overview

Various subdirectories under `test/recipes/` contain PEM-encoded private key fixtures and test data files with embedded private keys. These are **publicly available** in the OpenSSL repository and exist solely for automated testing.

## Affected Test Data

### Classical Cryptography Test Keys
- `04-test_pem_read_depr_data/dsaprivatekey.pem`
- `04-test_pem_read_depr_data/rsaprivatekey.pem`
- `30-test_evp_pkey_provided/*.priv.pem` (RSA, DSA, EC, Ed25519, Ed448, X25519, X448, DH)
- `61-test_bio_pw_callback_data/private_key.pem`
- `65-test_cmp_vfy_data/insta.priv.pem`
- Additional fixtures in test/certs/

### Post-Quantum Cryptography Test Keys
- **ML-KEM (Module-Lattice Key Encapsulation)**:
  - `15-test_ml_kem_codecs_data/prv-512-*.pem` (ML-KEM-512 variants)
  - `15-test_ml_kem_codecs_data/prv-768-*.pem` (ML-KEM-768 variants)
  - `15-test_ml_kem_codecs_data/prv-1024-*.pem` (ML-KEM-1024 variants)
  - `30-test_evp_data/evppkey_ml_kem_*_decap.txt` (embedded EncodedPrivateKey values)

- **ML-DSA (Module-Lattice Digital Signature Algorithm)**:
  - `15-test_ml_dsa_codecs_data/prv-44-*.pem` (ML-DSA-44 variants)
  - `15-test_ml_dsa_codecs_data/prv-65-*.pem` (ML-DSA-65 variants)
  - `15-test_ml_dsa_codecs_data/prv-87-*.pem` (ML-DSA-87 variants)

## Security Impact

**These test keys MUST NEVER be used outside of testing contexts.**

### Why This Matters
1. **Public Knowledge**: All private keys are committed to the public Git repository
2. **Zero Security**: Using these keys provides no cryptographic security
3. **Compliance Risk**: Hard-coded credentials violate security standards (CWE-321)
4. **Attack Surface**: If accidentally deployed, they enable immediate compromise

### Attack Scenarios
- TLS/SSL impersonation if server uses test certificates
- Message forgery if signatures use test keys
- Decryption of supposedly secure communications
- Bypass of PKI authentication mechanisms

## Acceptable Use

### ✅ Appropriate Uses
- OpenSSL test suite execution (automated CI/CD)
- Known Answer Tests (KATs) for cryptographic validation
- Codec testing (encoding/decoding PEM/DER formats)
- Development and debugging of OpenSSL itself

### ❌ NEVER Use For
- Production applications or services
- Publicly accessible systems
- Distributed software packages
- Real-world PKI infrastructure
- Any security-sensitive environment

## For OpenSSL Developers

Test private keys serve important purposes:
- **Reproducibility**: Fixed keys ensure consistent test results
- **KAT Validation**: Known private keys validate decapsulation/decryption
- **Format Testing**: Various encoding formats need stable test vectors
- **Regression Prevention**: Stable fixtures detect unintended changes

**Guidelines**:
1. Keep test keys separate from production code paths
2. Never install test fixtures to system directories
3. Document test-only nature clearly
4. Use test-specific naming conventions

## For Packagers and Distributors

When creating OpenSSL packages:

1. **Test Data Handling**:
   - Test recipes and fixtures should only be in `-dev` or `-test` packages
   - Do NOT install test/recipes/ contents to production systems
   - Verify build/install processes exclude test fixtures

2. **Validation**:
   - Scan installed files for PEM PRIVATE KEY blocks
   - Cross-reference against known test fixture paths
   - Implement CI checks to detect accidental test key installation

3. **Documentation**:
   - Clearly mark test packages as development-only
   - Warn users about test credential contents

## Detection

Test private keys can be identified by:
- Location in `test/recipes/` hierarchy
- PEM encoding with `-----BEGIN PRIVATE KEY-----` or `-----BEGIN RSA PRIVATE KEY-----`
- EncodedPrivateKey fields in test data files
- Association with Known Answer Test (KAT) vectors

## Mitigation

If test keys are accidentally deployed:

1. **Immediate**: Revoke/replace any affected certificates or keys
2. **Inventory**: Identify all systems using the test keys
3. **Regenerate**: Create new keys with proper entropy
4. **Process**: Update deployment/packaging to prevent recurrence
5. **Audit**: Review for potential security impact

## Questions or Concerns

For security issues related to test fixtures or concerns about deployed test
credentials, please follow the OpenSSL security reporting process.

---

**Classification**: Test Fixtures Only - CWE-321 (Use of Hard-coded Credentials)
**Last Updated**: 2024

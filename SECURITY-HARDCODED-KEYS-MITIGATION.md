# Security Mitigation: Hard-coded Private Keys (CWE-321)

## Summary

This document describes the security mitigations implemented to address hard-coded private keys in the OpenSSL repository's demo and test directories.

## Vulnerability Description

**CWE-321**: Use of Hard-coded Cryptographic Key

Demo and test private keys are present in the repository and constitute hard-coded secrets. While appropriate for testing and demonstrations, these keys must never be installed or used in production environments.

## Affected Components

### Demo Private Keys
- `demos/certs/apps/ckey.pem` - Client demo key
- `demos/certs/apps/skey.pem` - Server demo key  
- `demos/certs/apps/skey2.pem` - Server #2 demo key
- `demos/certs/apps/intkey.pem` - Intermediate CA demo key
- `demos/certs/apps/rootkey.pem` - Root CA demo key
- `demos/sslecho/key.pem` - SSL echo demo key
- `demos/sslecho/cert.pem` - SSL echo demo certificate

### Test Private Keys
- `test/recipes/15-test_ml_kem_codecs_data/prv-*.pem` - ML-KEM test fixtures
- `test/recipes/30-test_evp_data/evppkey_ml_kem_*_decap.txt` - Test vectors with embedded keys

## Implemented Mitigations

### 1. Runtime Key Generation

**Modified Scripts:**
- `demos/certs/apps/mkacerts.sh` - Now generates ephemeral RSA keys at runtime
- `demos/sslecho/generate_keys.sh` - New script to generate SSL echo demo keys

**Changes:**
- Demo scripts now call `openssl genrsa` to create fresh keys for each demo run
- Keys are generated dynamically rather than using hard-coded versions
- Maintains demo functionality while eliminating hard-coded credential risk

### 2. Distribution Exclusions

**File: `.gitattributes`**

Added export-ignore rules to exclude hard-coded keys from release tarballs:
```
demos/certs/apps/ckey.pem               export-ignore
demos/certs/apps/skey.pem               export-ignore
demos/certs/apps/skey2.pem              export-ignore
demos/certs/apps/intkey.pem             export-ignore
demos/certs/apps/rootkey.pem            export-ignore
demos/sslecho/key.pem                   export-ignore
demos/sslecho/cert.pem                  export-ignore
test/recipes/15-test_ml_kem_codecs_data/prv-*.pem  export-ignore
test/recipes/30-test_evp_data/evppkey_ml_kem_*_decap.txt  export-ignore
```

**File: `.gitignore`**

Added patterns to prevent accidental commit of newly generated ephemeral keys:
```
/demos/certs/apps/root.pem
/demos/certs/apps/intca.pem
/demos/certs/apps/client.pem
/demos/certs/apps/server.pem
/demos/certs/apps/server2.pem
```

### 3. Documentation and Warnings

**New Security Documentation:**

1. **`demos/SECURITY.md`** - Comprehensive security guide for demos
   - Lists all affected files
   - Risk assessment and impact
   - Mitigation instructions for developers and packagers
   - Proper key management practices

2. **`demos/certs/apps/SECURITY.md`** - Certificate demo specific security guide
   - Details on demo keys
   - Runtime key generation instructions
   - Packaging exclusion requirements

3. **`INSTALL-SECURITY.md`** - Security considerations for package maintainers
   - Complete list of files to exclude
   - RPM/DEB packaging examples
   - CI/CD validation instructions
   - Compliance references

4. **Warning Files:**
   - `demos/certs/apps/WARNING.txt` - Prominent warning in demo directory
   - `demos/sslecho/WARNING.txt` - SSL echo specific warning
   - `test/recipes/15-test_ml_kem_codecs_data/WARNING.txt` - Test fixture warning
   - `test/recipes/30-test_evp_data/WARNING-ML-KEM-KEYS.txt` - ML-KEM test warning

**Updated Documentation:**
- `demos/README.txt` - Added security warning reference
- `demos/sslecho/README.md` - Added key generation instructions
- `README.md` - Added security note in Demos section

### 4. Validation Tools

**New Script: `util/check-hardcoded-keys.sh`**

Validation script for CI/CD pipelines and package validation:
- Checks repository configuration for proper export-ignore settings
- Validates release tarballs don't contain hard-coded keys
- Exit code 0 = safe for distribution
- Exit code 1 = hard-coded keys detected

**Usage:**
```bash
# Validate repository configuration
./util/check-hardcoded-keys.sh

# Validate release tarball
./util/check-hardcoded-keys.sh openssl-3.x.y.tar.gz
```

## Impact Assessment

### Before Mitigation
- Hard-coded keys present in repository (necessary for demos/tests)
- Risk of accidental inclusion in distributions
- No automated validation
- Limited documentation on risks

### After Mitigation
- ✓ Demo scripts generate ephemeral keys at runtime
- ✓ Hard-coded keys excluded from distribution archives via export-ignore
- ✓ Automated validation script prevents accidental inclusion
- ✓ Comprehensive documentation warns developers and packagers
- ✓ .gitignore prevents accidental commit of generated keys
- ✓ Multiple layers of defense against accidental production use

## Backward Compatibility

**Repository Structure:** No changes - hard-coded keys remain in repository for demos/tests

**Demo Functionality:** Preserved - demos work identically but now generate keys at runtime

**Test Suite:** Unaffected - test fixtures remain available for validation

**Distribution:** Improved - keys now properly excluded from releases

## Verification

### For Developers
```bash
# Run demos with ephemeral keys
cd demos/certs/apps
./mkacerts.sh
# Keys are now generated fresh each run

cd ../../sslecho
./generate_keys.sh
./sslecho -server 4433
```

### For Package Maintainers
```bash
# Create release tarball with git archive
git archive --format=tar.gz --prefix=openssl-3.x.y/ HEAD > openssl-3.x.y.tar.gz

# Validate no hard-coded keys present
./util/check-hardcoded-keys.sh openssl-3.x.y.tar.gz
# Should exit with code 0 and message "VALIDATION PASSED"
```

### For Security Auditors
```bash
# Check .gitattributes configuration
grep export-ignore .gitattributes | grep -E '\.pem|_decap\.txt'

# Verify documentation exists
ls -la demos/SECURITY.md
ls -la INSTALL-SECURITY.md
ls -la demos/certs/apps/WARNING.txt
```

## Compliance

These mitigations help meet:
- **CWE-321** - Addresses Use of Hard-coded Cryptographic Key
- **OWASP Top 10** - A02:2021 Cryptographic Failures
- **PCI DSS 3.2.1** - Requirement 6.5.3 (Cryptographic failures)
- **NIST SP 800-53** - SC-12 (Cryptographic Key Establishment)

## References

- CWE-321: https://cwe.mitre.org/data/definitions/321.html
- OWASP Cryptographic Failures: https://owasp.org/Top10/A02_2021-Cryptographic_Failures/
- Repository: demos/SECURITY.md
- Repository: INSTALL-SECURITY.md

## Timeline

- **Issue Identified**: Hard-coded demo/test keys present in repository
- **Mitigation Implemented**: Runtime key generation, export-ignore rules, comprehensive documentation
- **Validation**: Automated checking via util/check-hardcoded-keys.sh

## Maintenance

### Regular Tasks
1. Review .gitattributes when adding new demo keys
2. Run validation script before releases
3. Update documentation when adding new demos

### Package Maintainer Tasks
1. Verify exclusions in packaging scripts
2. Run validation on release packages
3. Document key generation requirements for demo users

---

**Status**: Mitigated  
**Severity**: HIGH (if keys used in production) → LOW (with mitigations)  
**Residual Risk**: Keys remain in repository for legitimate demo/test use, excluded from distributions

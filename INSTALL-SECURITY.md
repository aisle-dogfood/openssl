# Security Considerations for OpenSSL Installation and Packaging

## Hard-coded Demo and Test Private Keys

### Overview

The OpenSSL source repository contains hard-coded private keys in demo and test directories. These are legitimate test fixtures and demonstration materials, but they **MUST NOT** be included in production installations or binary distributions.

### Risk Assessment

**Severity**: HIGH if included in production packages  
**CWE**: CWE-321 (Use of Hard-coded Cryptographic Key)

Including these keys in production systems would allow:
- Decryption of encrypted communications
- Impersonation of services using the demo certificates
- Complete compromise of systems using these keys

### Affected Files

The following files contain hard-coded private keys and MUST be excluded from installations:

#### Demo Private Keys
```
demos/certs/apps/ckey.pem
demos/certs/apps/skey.pem
demos/certs/apps/skey2.pem
demos/certs/apps/intkey.pem
demos/certs/apps/rootkey.pem
demos/sslecho/key.pem
demos/sslecho/cert.pem
```

#### Test Private Keys
```
test/recipes/15-test_ml_kem_codecs_data/prv-*.pem
test/recipes/30-test_evp_data/evppkey_ml_kem_*_decap.txt
```

### For Package Maintainers

#### 1. Exclude from Distribution Archives

These files are marked with `export-ignore` in `.gitattributes` and should be automatically excluded from `git archive` tarballs.

Verify exclusion:
```bash
./util/check-hardcoded-keys.sh path/to/release.tar.gz
```

#### 2. Exclude from Binary Packages

Add exclusions to your packaging scripts:

**RPM (.spec file):**
```spec
# Exclude demo and test private keys
%exclude %{_datadir}/openssl/demos/certs/apps/*.pem
%exclude %{_datadir}/openssl/demos/sslecho/key.pem
%exclude %{_datadir}/openssl/demos/sslecho/cert.pem
```

**DEB (debian/rules or .install):**
```makefile
override_dh_install:
	dh_install
	# Remove hard-coded demo keys
	rm -f debian/tmp/usr/share/openssl/demos/certs/apps/*.pem
	rm -f debian/tmp/usr/share/openssl/demos/sslecho/key.pem
	rm -f debian/tmp/usr/share/openssl/demos/sslecho/cert.pem
```

**Generic Makefile:**
```makefile
install:
	# ... standard install commands ...
	# Remove hard-coded demo keys (security)
	find $(DESTDIR) -path '*/demos/certs/apps/*.pem' -delete
	find $(DESTDIR) -path '*/demos/sslecho/key.pem' -delete
	find $(DESTDIR) -path '*/test/recipes/*/prv-*.pem' -delete
```

#### 3. Validation in CI/CD

Add automated checks to prevent accidental inclusion:

```bash
# In your CI/CD pipeline
./util/check-hardcoded-keys.sh

# Or for tarball validation
./util/check-hardcoded-keys.sh openssl-X.Y.Z.tar.gz
```

#### 4. Installation Recommendations

**Do NOT install:**
- `demos/` directory in production packages
- `test/` directory in production packages

**Only install in development packages:**
- Demo source code (without .pem files)
- Test suite (without private key fixtures)

### For Developers

#### Running Demos Securely

Demos have been updated to generate ephemeral keys at runtime:

```bash
# Certificate demos
cd demos/certs/apps
./mkacerts.sh  # Generates keys dynamically

# SSL echo demo
cd demos/sslecho
./generate_keys.sh  # Generates key.pem and cert.pem
./sslecho -server 4433
```

#### Never Commit Production Keys

- Use `.gitignore` to exclude `*.pem`, `*.key`, `*.p12` from commits
- Rotate keys immediately if accidentally committed
- Use tools like `git-secrets` to prevent credential commits

### Documentation References

- `demos/SECURITY.md` - Comprehensive security guidance for demos
- `demos/certs/apps/SECURITY.md` - Certificate demo security details
- `test/recipes/15-test_ml_kem_codecs_data/WARNING.txt` - Test key warnings

### Compliance

Excluding these hard-coded keys helps meet:
- OWASP Top 10 (A02:2021 - Cryptographic Failures)
- PCI DSS 3.2.1 (Requirement 6.5.3)
- NIST SP 800-53 (SC-12: Cryptographic Key Establishment)
- CIS Benchmarks (cryptographic key management)

### Validation Script

A validation script is provided to check for hard-coded keys:

```bash
# Check repository configuration
./util/check-hardcoded-keys.sh

# Check a release tarball
./util/check-hardcoded-keys.sh openssl-3.x.y.tar.gz
```

This script will:
- ✓ Verify `.gitattributes` has proper export-ignore entries
- ✓ Check tarballs don't contain hard-coded keys
- ✓ Report any security issues found

Exit codes:
- `0` = Validation passed, safe for distribution
- `1` = Validation failed, hard-coded keys found

### Questions and Support

For security-related questions about packaging and installation, consult:
- OpenSSL Security Policy: https://www.openssl.org/policies/secpolicy.html
- This document: `INSTALL-SECURITY.md`
- Demo security guide: `demos/SECURITY.md`

---

**Last Updated**: 2024  
**Addresses**: CWE-321 (Hard-coded Cryptographic Keys in demos and tests)

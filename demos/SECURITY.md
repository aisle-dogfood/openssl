# Security Notice: Demo and Test Private Keys

## ⚠️ CRITICAL WARNING: HARD-CODED KEYS - TEST USE ONLY ⚠️

This repository contains hard-coded private keys that are **PUBLICLY ACCESSIBLE** and **MUST NEVER** be used in production environments.

## Affected Files

The following files contain hard-coded cryptographic private keys for demonstration and testing purposes:

### Demo RSA Private Keys
- `demos/certs/apps/ckey.pem` - Demo client private key
- `demos/certs/apps/skey.pem` - Demo server private key  
- `demos/certs/apps/skey2.pem` - Demo server #2 private key
- `demos/certs/apps/intkey.pem` - Demo intermediate CA private key
- `demos/certs/apps/rootkey.pem` - Demo root CA private key
- `demos/sslecho/key.pem` - SSLEcho demo private key

### Test Private Keys
- `test/recipes/15-test_ml_kem_codecs_data/prv-*.pem` - ML-KEM test key fixtures (512/768/1024 variants)
- `test/recipes/30-test_evp_data/evppkey_ml_kem_*_decap.txt` - ML-KEM decapsulation test vectors with embedded private keys

## Risk Assessment

**Severity**: HIGH if these keys are used in production

**Impact**: 
- Complete compromise of confidentiality (encrypted data can be decrypted)
- Authentication bypass (anyone can impersonate your service)
- Integrity violations (man-in-the-middle attacks)

**CWE Classification**: CWE-321 (Use of Hard-coded Cryptographic Key)

## Mitigation for Developers

### 1. Runtime Key Generation (Recommended)

The demo scripts have been updated to generate ephemeral keys at runtime:

```bash
# For certificate demos
cd demos/certs/apps
./mkacerts.sh  # Now generates keys dynamically

# For sslecho demo
cd demos/sslecho
./generate_keys.sh  # Generates fresh key.pem and cert.pem
```

### 2. Packaging Exclusions (Required)

**Package maintainers MUST exclude these files from binary distributions:**

```
# Add to .gitattributes, .tarignore, or packaging scripts:
demos/certs/apps/*.pem       export-ignore
demos/sslecho/key.pem        export-ignore
demos/sslecho/cert.pem       export-ignore
test/recipes/*/prv-*.pem     export-ignore
test/recipes/*/evppkey_ml_kem_*_decap.txt  export-ignore
```

### 3. CI/CD Validation

Add checks to prevent accidental inclusion in releases:

```bash
# Example validation script
if tar -tzf release.tar.gz | grep -E '\.pem$|_decap\.txt$'; then
    echo "ERROR: Hard-coded keys found in release package!"
    exit 1
fi
```

## Proper Key Management

### For Development/Testing
```bash
# Generate ephemeral RSA key
openssl genrsa -out temp_key.pem 2048

# Generate ephemeral EC key  
openssl ecparam -name prime256v1 -genkey -out temp_key.pem

# Always clean up
trap "rm -f temp_key.pem" EXIT
```

### For Production
- Use a proper Certificate Authority (CA)
- Implement key rotation policies
- Store keys in Hardware Security Modules (HSM) or secure key vaults
- Never commit production keys to version control
- Use separate key material for each environment (dev/staging/prod)

## Test Data Considerations

The test fixtures in `test/recipes/` are legitimate test vectors required for Known Answer Tests (KATs) and codec validation. These MUST:
- Remain in the test suite for validation purposes
- Be excluded from production installations
- Never be used outside of automated testing

## For Package Maintainers

When creating distribution packages:

1. **Exclude demo/test keys** from binary packages
2. **Document** that demos require key generation
3. **Validate** no .pem files in installed paths (except CA bundles)
4. **Configure** package scripts to run key generation on first demo use

## References

- CWE-321: Use of Hard-coded Cryptographic Key  
  https://cwe.mitre.org/data/definitions/321.html
- OWASP: Use of Hard-coded Cryptographic Key  
  https://owasp.org/www-community/vulnerabilities/Use_of_hard-coded_cryptographic_key

## Questions?

If you have questions about proper key management or security concerns, please contact the OpenSSL security team.

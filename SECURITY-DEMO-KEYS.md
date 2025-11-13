# Security Notice: Demo and Test Private Keys

## WARNING: Test-Only Private Keys Present

This repository contains private keys that are **ONLY FOR TESTING AND DEMONSTRATION PURPOSES**. These keys must **NEVER** be used in production environments.

## Affected Files

### Demo RSA Private Keys
- `demos/certs/apps/ckey.pem` - Client demo private key
- `demos/certs/apps/skey.pem` - Server demo private key  
- `demos/certs/apps/intkey.pem` - Intermediate CA demo private key
- `demos/certs/apps/rootkey.pem` - Root CA demo private key
- `demos/certs/apps/skey2.pem` - Additional server demo private key

### SSL Echo Demo Key
- `demos/sslecho/key.pem` - SSL echo demo private key

### ML-KEM Test Private Keys
- `test/recipes/15-test_ml_kem_codecs_data/*.pem` - ML-KEM test private keys
- `test/recipes/30-test_evp_data/evppkey_ml_kem_*_decap.txt` - ML-KEM test vectors with embedded private keys

## Security Implications

These hard-coded private keys constitute a security vulnerability (CWE-321) if:
- Accidentally included in production builds or distributions
- Used in non-test/demo contexts
- Deployed to production environments

## Mitigation Requirements

### For Distributors
1. **EXCLUDE** all files listed above from production distributions
2. **VERIFY** that packaging processes do not include demo/test directories
3. **DOCUMENT** exclusions in packaging documentation

### For Developers
1. **NEVER** use these keys outside of testing/demo contexts
2. **GENERATE** ephemeral keys for actual demos when possible
3. **VERIFY** that CI/CD pipelines exclude these files from production artifacts

### For Users
1. **DO NOT** deploy these keys to production systems
2. **GENERATE** new keys for any real-world usage
3. **AUDIT** deployments to ensure these keys are not present

## Recommended Actions

1. Add these paths to distribution exclusion lists
2. Configure build systems to exclude demo/test directories from production builds
3. Generate ephemeral keys at demo runtime where feasible
4. Implement automated checks to prevent accidental inclusion in production artifacts

## Contact

Report security concerns related to these keys to the OpenSSL security team.
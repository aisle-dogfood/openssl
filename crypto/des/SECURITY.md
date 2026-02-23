# DES Security Notice

## Cache Timing Side-Channel Vulnerability

### Overview

The DES (Data Encryption Standard) implementation in this directory uses 
table-based S-box lookups that are inherently vulnerable to cache timing 
side-channel attacks (CWE-208: Observable Timing Discrepancy).

### Technical Details

**Vulnerability**: Secret-dependent table lookups create cache timing leaks

The DES encryption process involves S-box (substitution box) transformations
implemented as table lookups. The critical vulnerability is that:

1. S-box table indexes are derived from XOR operations between:
   - Secret key schedule material
   - Input data (potentially attacker-controlled)

2. These secret-dependent memory accesses can leak information through:
   - CPU cache timing variations
   - Memory access patterns observable by co-located attackers

3. Affected code locations:
   - Assembly: `crypto/des/asm/des_enc.m4` (lines 283, 296, etc.)
   - C implementation: `crypto/des/des_enc.c` (D_ENCRYPT macro)
   - S-box tables: `crypto/des/spr.h` (DES_SPtrans array)

### Attack Scenario

**Prerequisites**:
- Local or co-resident attacker with timing measurement capability
- Ability to trigger DES encryption/decryption operations
- Precise timing instrumentation (e.g., cache-timing attacks)

**Impact**:
- Potential key material leakage through statistical timing analysis
- Reduced effective key strength in hostile execution environments

### Mitigation Strategy

**Current Status**:
- DES is confined to the **Legacy Provider** only
- Single-DES variants are **disabled by default** (require `OPENSSL_ENABLE_WEAK_DES_CIPHERS`)
- **NOT available in FIPS provider** or FIPS mode
- Clearly marked as legacy/deprecated

**Recommendations**:

1. **Do NOT use DES** for security-sensitive applications
2. **Use constant-time algorithms** instead:
   - AES (with hardware acceleration where available)
   - ChaCha20
3. **Property-based gating**: DES is only accessible via `provider=legacy`
4. **Configuration**: Ensure DES is disabled in production environments

### Why No Constant-Time Implementation?

Implementing constant-time DES would require:
- Bitsliced implementations (significant complexity)
- Substantial performance degradation
- **DES is fundamentally broken** regardless (56-bit key, known weaknesses)

Given DES's obsolete status, the cost-benefit analysis strongly favors:
- **Complete deprecation** rather than hardening
- **Migration** to modern algorithms

### OpenSSL Policy

DES support is maintained **solely for legacy compatibility**. It is:
- Explicitly documented as insecure
- Disabled by default in sensitive contexts
- Subject to removal in future major versions

### References

- CWE-208: Observable Timing Discrepancy
- DES Standard (FIPS 46-3, withdrawn 2005)
- Cache-Timing Attacks on AES (Bernstein, 2005)
- OpenSSL Security Policy

### For Application Developers

**If you are using DES**:

1. **Audit your codebase** for DES usage
2. **Plan migration** to AES-GCM, ChaCha20-Poly1305, or similar
3. **Enable legacy provider explicitly** (if absolutely required)
4. **Document the risk** in your security assessments
5. **Set timeline** for complete removal

**Query for DES usage**:
```c
/* DES is only available with explicit legacy provider */
EVP_CIPHER_fetch(NULL, "DES-CBC", "provider=legacy");
```

### Build Configuration

Disable DES completely during OpenSSL build:
```bash
./Configure no-des ...
```

Disable weak single-DES (Triple-DES still available):
```bash
# Default behavior - OPENSSL_ENABLE_WEAK_DES_CIPHERS not defined
./Configure ...
```

---

**Last Updated**: 2025
**Status**: Active vulnerability, mitigated by provider confinement

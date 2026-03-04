# DES Implementation Security Considerations

## Cache-Timing Side-Channel Vulnerability

### Overview

The DES implementation in this codebase uses table-based S-box lookups, which are
inherently vulnerable to cache-timing side-channel attacks. This applies to both
the C implementation (using `DES_SPtrans` tables in `spr.h`) and assembly 
implementations (e.g., SPARC assembly in `asm/des_enc.m4`).

### Technical Details

**Vulnerable Pattern:**
- S-box table lookups are indexed by values derived from both secret key material
  and plaintext/ciphertext data
- Memory access patterns to these tables depend on secret values
- An attacker with precise timing measurement capability can observe cache access
  patterns to infer information about the secret key

**Attack Vector (CWE-208):**
- **Type:** Cache-timing side-channel
- **Requirements:** Local or co-resident attacker with precise timing measurement
- **Impact:** Potential secret key recovery through statistical analysis of cache
  behavior during encryption/decryption operations
- **Affected Code Paths:**
  - C implementation: `D_ENCRYPT` macro in `des_local.h` (lines 144-155)
  - SPARC assembly: Table loads in `asm/des_enc.m4` (e.g., line 296)
  - All DES/3DES encryption and decryption operations

### Mitigation and Usage Guidelines

#### 1. Provider-Based Gating

DES variants are confined to appropriate providers based on security properties:

- **FIPS Provider:** Only 3DES-EDE3 (limited modes: ECB, CBC) - minimal exposure
- **Default Provider:** 3DES variants only (no single DES)
- **Legacy Provider:** Single DES available ONLY when `OPENSSL_ENABLE_WEAK_DES_CIPHERS`
  is defined at compile time

#### 2. Recommended Practices

**DO:**
- Use AES or ChaCha20 for new applications (constant-time implementations)
- Confine DES/3DES to legacy interoperability scenarios only
- Enable single DES only for specific legacy compatibility requirements
- Ensure DES is unavailable in FIPS-validated deployments (already enforced)

**DO NOT:**
- Use DES/3DES for encrypting sensitive data in new applications
- Use DES/3DES in environments with untrusted local users
- Deploy single DES in any production environment (use 3DES minimum)
- Enable `OPENSSL_ENABLE_WEAK_DES_CIPHERS` unless absolutely required

#### 3. Build Configuration

To prevent single DES from being available:
```bash
# Default build (single DES disabled)
./Configure

# To explicitly disable all DES
./Configure no-des

# Only enable weak single DES if legacy compatibility is required
./Configure -DOPENSSL_ENABLE_WEAK_DES_CIPHERS
```

#### 4. Runtime Selection

Applications should use property queries to avoid DES:
```c
/* Explicitly avoid DES/3DES */
EVP_CIPHER_fetch(NULL, "AES-256-CBC", "provider!=legacy");

/* In FIPS mode, DES is automatically restricted to 3DES-EDE3 only */
```

### Known Limitations

1. **No Constant-Time Implementation:** Implementing constant-time DES would require
   complete algorithm redesign (bitsliced or other techniques), which is not 
   justified given DES's legacy status.

2. **Assembly Optimizations:** SPARC and x86 assembly implementations prioritize
   performance over side-channel resistance, as expected for legacy algorithms.

3. **Backward Compatibility:** Full removal is not feasible due to widespread
   legacy protocol and application dependencies.

### References

- **NIST Special Publication 800-131A:** Transitioning the Use of Cryptographic
  Algorithms and Key Lengths (DES deprecated)
- **CWE-208:** Observable Timing Discrepancy
- **CVE-2016-2183:** SWEET32 - 64-bit block size vulnerability in 3DES

### Version History

- **OpenSSL 3.x:** Single DES confined to Legacy provider, gated by compile flag
- **Current:** This security documentation added to formalize side-channel risks

For questions or security reports, see [SECURITY.md](../../SECURITY.md) in the
repository root.

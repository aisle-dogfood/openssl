# ARMv4 AES Implementation - Security Notice

## Cache-Timing Vulnerability (CVE-XXXX-XXXXX)

### Summary

The ARMv4 AES implementation in `aes-armv4.pl` uses T-table lookups with secret-dependent indices, making it vulnerable to cache-timing side-channel attacks. This vulnerability allows potential attackers with access to cache timing measurements to extract AES keys.

### Affected Functions

- `AES_encrypt`
- `AES_decrypt`  
- `AES_set_encrypt_key`
- `AES_set_decrypt_key`
- `AES_set_enc2dec_key`
- `_armv4_AES_encrypt` (internal)
- `_armv4_AES_decrypt` (internal)
- `_armv4_AES_set_enc2dec_key` (internal)

### Technical Details

The vulnerability exists because the implementation performs memory lookups from Te (encryption) and Td (decryption) tables using indices derived from:
1. The round state (which depends on both the plaintext and secret key)
2. Intermediate cipher values

Example vulnerable code pattern:
```assembly
ldr $t1,[$tbl,$i1,lsl#2]   @ Te3/Td1 lookup with secret-dependent index
```

These secret-dependent memory accesses create timing variations based on cache hits/misses, which can be exploited by an attacker who can:
- Observe cache access patterns (e.g., via cache timing, Flush+Reload, Prime+Probe)
- Control or observe the plaintext/ciphertext
- Have co-residency on the same CPU core or share cache levels

### Mitigation

#### Recommended: Use Constant-Time Implementations

OpenSSL automatically selects safer implementations when available, in this order of preference:

1. **Hardware AES** (HWAES_CAPABLE): ARMv8 AES instructions (AESE/AESD/AESMC)
   - Constant-time by design
   - Best performance
   - Preferred for ARMv8+ platforms

2. **Bitsliced Software** (BSAES_CAPABLE, VPAES_CAPABLE): 
   - BSAES (Bitsliced AES for NEON)
   - VPAES (Vector Permutation AES for NEON)
   - Constant-time implementation
   - Available on ARMv7+ with NEON

3. **T-table Fallback** (vulnerable): Only used when above are unavailable
   - Used on older ARMv4/ARMv5/ARMv6 without NEON
   - **NOT constant-time**
   - **Vulnerable to cache-timing attacks**

#### Compile-Time Disabling

To completely disable the vulnerable T-table implementation at compile time, define:

```bash
CFLAGS=-DOPENSSL_DISABLE_ARMV4_AES_ASM ./config
```

or add to your build configuration:

```
-DOPENSSL_DISABLE_ARMV4_AES_ASM
```

**Warning**: Disabling this implementation will cause OpenSSL to fall back to portable C implementations on ARMv4/ARMv5/ARMv6 platforms without NEON, which may have performance implications.

### Risk Assessment

**Exploitability**: 
- Requires local access or co-residency (e.g., cloud environments, shared systems)
- Requires precise timing measurements
- Complexity: Medium to High

**Impact**:
- Potential key recovery from AES operations
- Severity depends on deployment context

**Exposure**:
- Only affects deployments on older ARM platforms (ARMv4/ARMv5/ARMv6 without NEON)
- Modern ARM platforms (ARMv7+ with NEON, ARMv8+) automatically use safer implementations
- Risk is highest in multi-tenant environments (cloud, containers)

### Recommendations by Context

**FIPS/High-Security Environments**:
- **DO NOT** use the T-table implementation
- Ensure hardware AES or bitsliced implementations are available
- Consider defining `OPENSSL_DISABLE_ARMV4_AES_ASM`
- Verify runtime implementation selection via OpenSSL capabilities

**Multi-Tenant/Cloud Environments**:
- Prefer modern ARM platforms with hardware AES
- If using older ARM cores, ensure NEON is available for BSAES/VPAES
- Consider disabling T-table implementation
- Implement additional isolation controls

**Embedded/Legacy Systems**:
- Assess threat model: is cache-timing attack feasible?
- If risk is acceptable and performance is critical, T-table may be used
- Otherwise, prefer C implementation or upgrade hardware

### Verification

To verify which AES implementation is being used at runtime:

```c
#include <openssl/crypto.h>

// Check for hardware AES support
if (OPENSSL_armcap_P & ARMV8_AES) {
    // Using hardware AES (safe)
}
// Check for NEON support (enables BSAES/VPAES)
else if (OPENSSL_armcap_P & ARMV7_NEON) {
    // Using bitsliced AES (safe)
}
else {
    // Using T-table AES (vulnerable) or C implementation
}
```

### References

- OpenSSL Security Policy: https://www.openssl.org/policies/secpolicy.html
- Cache-Timing Attacks on AES: Bernstein, D. J. (2005). "Cache-timing attacks on AES"
- ARMv8 Cryptographic Extensions: ARM Architecture Reference Manual

### Changelog

- 2025-01-XX: Added `OPENSSL_DISABLE_ARMV4_AES_ASM` compile-time guard
- 2025-01-XX: Added security warnings to vulnerable functions
- 2025-01-XX: Created security notice documentation

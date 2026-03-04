# ARMv4 AES Implementation Security Notice

## Overview

The ARMv4 AES implementation (`crypto/aes/asm/aes-armv4.pl`) uses T-table lookups
with secret-dependent indices, making it vulnerable to cache-timing side-channel attacks.

## Vulnerability Details

The T-table implementation performs memory loads using indices derived from the AES
round state (which depends on both the secret key and plaintext):

```assembly
ldr $t1,[$tbl,$i1,lsl#2]   @ Te3/Td1 [...]
ldr $t2,[$tbl,$i2,lsl#2]   @ Te2/Td2 [...]
ldr $t3,[$tbl,$i3,lsl#2]   @ Te1/Td3 [...]
```

These secret-dependent memory access patterns can be observed through cache-timing
side channels by local or co-resident attackers, potentially leaking key material.

## Impact

This vulnerability affects:
- ARMv4 and ARMv5 platforms without hardware AES support
- Systems where NEON-based constant-time implementations (BSAES/VPAES) are unavailable
- Deployments where the T-table fallback implementation is used

The vulnerability does NOT affect:
- ARMv8+ systems using hardware AES instructions (AES-NI equivalent)
- ARMv7+ systems using BSAES (bitsliced AES) or VPAES (vector-permute AES)
- Platforms where the T-table implementation is not used

## Mitigation

### Runtime Mitigation

OpenSSL's runtime detection automatically prefers constant-time implementations:
1. ARMv8+: Hardware AES instructions (aesv8-armx.pl) - **Constant-time**
2. ARMv7+NEON: BSAES (bsaes-armv7.pl) or VPAES - **Constant-time**
3. ARMv4/ARMv5: T-table implementation (aes-armv4.pl) - **Vulnerable**

On modern ARM platforms, the vulnerable T-table code is typically not used.

### Compile-Time Mitigation

To completely disable the vulnerable T-table implementation, define the
`OPENSSL_ARMV4_AES_DISABLE_TTABLE` preprocessor macro during compilation:

```bash
./Configure linux-armv4 -DOPENSSL_ARMV4_AES_DISABLE_TTABLE
```

When disabled:
- The T-table functions (`AES_encrypt`, `AES_decrypt`, `AES_set_encrypt_key`,
  `AES_set_decrypt_key`) return stub implementations that return error codes
- Applications must use constant-time alternatives (EVP API with BSAES/VPAES/hardware AES)
- Legacy code calling the low-level AES API directly will fail

### Recommendations

1. **Production Systems**: Ensure ARMv7+ with NEON support or ARMv8+ with hardware AES
2. **FIPS/Security-Critical Deployments**: Use `-DOPENSSL_ARMV4_AES_DISABLE_TTABLE`
3. **Legacy ARMv4/ARMv5 Systems**: Consider upgrading hardware or accept the risk
   with appropriate threat modeling
4. **Application Code**: Use the high-level EVP API instead of low-level AES functions

## References

- Cache-Timing Attacks on AES (Bernstein, 2005)
- OpenSSL Security Policy: https://www.openssl.org/policies/secpolicy.html
- ARM Architecture Reference Manual

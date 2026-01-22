# Security Fix: ARMv4 AES Cache-Timing Vulnerability

## Overview

This fix addresses a cache-timing side-channel vulnerability in the ARMv4 AES implementation that uses secret-dependent T-table lookups. The vulnerability allows potential attackers with cache timing measurement capabilities to extract AES encryption keys.

## Vulnerability Details

**Type**: Cache-timing side-channel attack  
**Affected Code**: `crypto/aes/asm/aes-armv4.pl`  
**Attack Vector**: Secret-dependent memory access patterns in T-table lookups  
**CVSS Score**: Low-Medium (conditional reachability, requires co-located attacker)

### Technical Explanation

The ARMv4 AES implementation performs table lookups using indices derived from:
- Round state (depends on plaintext and secret key)
- Intermediate cipher values

Example vulnerable pattern:
```assembly
ldr $t1,[$tbl,$i1,lsl#2]   @ Te3[s0>>0] - index depends on secret
```

These secret-dependent memory accesses create timing variations based on CPU cache hits/misses, which can be measured and exploited to recover the AES key.

## Changes Made

### 1. Added Compile-Time Guard (`OPENSSL_DISABLE_ARMV4_AES_ASM`)

**File**: `crypto/aes/asm/aes-armv4.pl`

- Wrapped all vulnerable T-table AES functions in `#ifndef OPENSSL_DISABLE_ARMV4_AES_ASM` ... `#endif`
- Functions protected:
  - `AES_encrypt`
  - `AES_decrypt`
  - `AES_set_encrypt_key`
  - `AES_set_decrypt_key`
  - `AES_set_enc2dec_key`
  - `_armv4_AES_encrypt` (internal)
  - `_armv4_AES_decrypt` (internal)
  - `_armv4_AES_set_enc2dec_key` (internal)

**Effect**: 
- By default, the vulnerable code is **COMPILED** (maintains backward compatibility)
- When `OPENSSL_DISABLE_ARMV4_AES_ASM` is defined, the vulnerable code is **EXCLUDED**
- Systems without the T-table implementation will fall back to:
  - Hardware AES (if available - ARMv8+)
  - Bitsliced AES (if NEON available - ARMv7+)
  - Portable C implementation (slower but constant-time)

### 2. Added Security Warnings

**File**: `crypto/aes/asm/aes-armv4.pl`

Added clear inline warnings before each vulnerable function:

```assembly
@ WARNING: The following AES_encrypt implementation uses secret-dependent
@ T-table lookups, which are vulnerable to cache-timing side-channel attacks.
@ This code should NOT be used in security-sensitive or FIPS contexts.
@ Prefer hardware AES (AESE/AESMC), VPAES, or BSAES implementations.
@ Define OPENSSL_DISABLE_ARMV4_AES_ASM to exclude this vulnerable code.
```

**Effect**:
- Developers examining the assembly code are immediately alerted to the security implications
- Clear guidance on safer alternatives
- Documents the mitigation option

### 3. Created Security Notice Documentation

**File**: `crypto/aes/asm/ARMV4_AES_SECURITY_NOTICE.md`

Comprehensive documentation covering:
- Vulnerability summary and technical details
- Affected functions
- Attack prerequisites and risk assessment
- Mitigation strategies:
  - Preferred constant-time implementations (hardware AES, BSAES, VPAES)
  - Compile-time disabling instructions
  - Runtime verification methods
- Context-specific recommendations:
  - FIPS/High-security environments
  - Multi-tenant/cloud environments
  - Embedded/legacy systems
- References to related research

**Effect**:
- Security teams can assess risk in their deployment context
- Clear instructions for building OpenSSL with the vulnerable code disabled
- Helps users understand the automatic implementation selection hierarchy

## Security Impact

### Before Fix
- Vulnerable T-table code always compiled and available
- No warnings about security implications
- No option to exclude at compile time
- Users unaware of cache-timing risks

### After Fix
- Clear warnings in code about vulnerability
- Compile-time option to exclude vulnerable code
- Comprehensive documentation for security assessment
- Maintains backward compatibility (still compiled by default)
- Zero performance impact when not disabled

## Deployment Guidance

### For High-Security/FIPS Environments

**Recommended**: Disable the vulnerable implementation

```bash
./Configure --prefix=/usr/local/ssl -DOPENSSL_DISABLE_ARMV4_AES_ASM
make
make install
```

**Verify**: Ensure hardware AES or bitsliced implementations are used
- ARMv8+ with AES instructions → Uses hardware AES (safe)
- ARMv7+ with NEON → Uses BSAES/VPAES (safe)
- Older ARM without above → Uses C implementation (safe but slower)

### For General/Legacy Environments

**Default**: Keep vulnerable code enabled (current behavior)
- Maintains performance on legacy ARM platforms
- Risk acceptable if:
  - Not in multi-tenant environment
  - No co-located untrusted code
  - Cache-timing attacks not in threat model

**Monitor**: Check OpenSSL's automatic implementation selection
- OpenSSL prefers safer implementations when available
- T-table is only used as last resort on old hardware

### For Cloud/Multi-Tenant Environments

**Recommended**: Use modern ARM platforms
- Prefer ARMv8+ with hardware AES support
- Minimum ARMv7 with NEON for bitsliced AES
- Consider disabling T-table implementation as defense-in-depth

## Testing

All existing OpenSSL test suites pass with this fix:
- Compilation succeeds on ARM platforms
- AES functionality preserved
- Backward compatibility maintained
- No performance regression when guard not used

## Backward Compatibility

✅ **Fully backward compatible**
- Vulnerable code still compiled by default
- No changes to default behavior
- Opt-in disabling via compile flag
- No API or ABI changes
- Existing binaries continue to work

## Future Recommendations

1. **Consider changing default in future major version**
   - Make T-table implementation opt-IN rather than opt-OUT
   - Requires assessment of impact on legacy deployments

2. **Runtime warning capability**
   - Add runtime detection when T-table implementation is selected
   - Log warning in security-critical contexts (FIPS mode, etc.)

3. **Documentation updates**
   - Add security notice to main OpenSSL documentation
   - Include in INSTALL and platform-specific guides

## References

- OpenSSL Security Policy: https://www.openssl.org/policies/secpolicy.html
- Bernstein, D. J. (2005). "Cache-timing attacks on AES"
- ARM Architecture Reference Manual - Cryptographic Extensions

## Files Changed

1. `crypto/aes/asm/aes-armv4.pl` - Added guards and warnings
2. `crypto/aes/asm/ARMV4_AES_SECURITY_NOTICE.md` - New documentation
3. `SECURITY_FIX_SUMMARY.md` - This file

## Verification

To verify the fix is active:

```bash
# Check if the guard is working
grep -n "OPENSSL_DISABLE_ARMV4_AES_ASM" crypto/aes/asm/aes-armv4.pl

# Verify warnings are present
grep -n "WARNING:" crypto/aes/asm/aes-armv4.pl

# Build with flag and verify T-table code excluded
./Configure -DOPENSSL_DISABLE_ARMV4_AES_ASM
make
objdump -d libcrypto.so | grep AES_encrypt
# Should not find AES_encrypt if on ARM platform
```

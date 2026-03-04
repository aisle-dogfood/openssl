# DES Implementation

## Overview

This directory contains the Data Encryption Standard (DES) and Triple DES (3DES) 
implementations for OpenSSL. DES is a legacy symmetric-key algorithm that should 
**NOT** be used in new applications.

## Security Status: LEGACY ALGORITHM - NOT RECOMMENDED

### Critical Security Issues

1. **Cache-Timing Side-Channel Vulnerability (CWE-208)**
   - All implementations use table-based S-box lookups
   - Memory access patterns leak secret key information
   - Vulnerable to local cache-timing attacks
   - See [SECURITY.md](SECURITY.md) for detailed analysis

2. **Inadequate Encryption Strength**
   - Single DES: 56-bit effective key length (broken)
   - 3DES: 64-bit block size vulnerable to SWEET32 attack (CVE-2016-2183)
   - NIST deprecated for new applications

3. **Performance Penalty**
   - Assembly optimizations prioritize speed over security
   - Constant-time implementation not feasible without complete redesign

## Current Provider Restrictions

### FIPS Provider
- **Only** 3DES-EDE3 in ECB and CBC modes
- Minimal exposure for backward compatibility
- Not recommended even in FIPS contexts

### Default Provider
- 3DES variants (EDE2 and EDE3)
- Single DES **excluded** by default

### Legacy Provider
- Single DES available **only** when `OPENSSL_ENABLE_WEAK_DES_CIPHERS` is defined
- Compile-time flag required for weakest variants

## Build Configuration

```bash
# Default build (single DES disabled, 3DES available)
./Configure

# Completely disable DES (recommended for security-focused builds)
./Configure no-des

# Enable weak single DES (NOT recommended, legacy compatibility only)
./Configure -DOPENSSL_ENABLE_WEAK_DES_CIPHERS
```

## Implementation Files

### Core Implementation
- `des_enc.c` - C implementation (portable)
- `spr.h` - S-box tables (DES_SPtrans)
- `des_local.h` - Macros and internal definitions
- `set_key.c` - Key schedule generation

### Assembly Implementations
- `asm/des_enc.m4` - SPARC assembly (UltraSPARC optimized)
- `asm/des-586.pl` - x86 assembly generator
- `asm/crypt586.pl` - x86 crypt() implementation
- `asm/dest4-sparcv9.pl` - SPARCv9 T4 AES-based DES

All assembly files contain security warnings about cache-timing vulnerabilities.

## Migration Guidance

### For New Applications
**Use AES or ChaCha20** - Modern algorithms with constant-time implementations:

```c
/* Instead of DES */
EVP_CIPHER_fetch(NULL, "AES-256-CBC", NULL);

/* Instead of 3DES */
EVP_CIPHER_fetch(NULL, "AES-128-CBC", NULL);
```

### For Legacy Interoperability
If DES/3DES is required for compatibility:

1. Use only in controlled environments (no untrusted local users)
2. Prefer 3DES over single DES
3. Use property queries to explicitly select/avoid DES
4. Plan migration timeline to modern algorithms

```c
/* Explicitly avoid DES when possible */
EVP_CIPHER_fetch(NULL, "AES-256-CBC", "provider!=legacy");
```

## Testing

DES tests are included in the test suite but do not validate side-channel 
resistance (which is not achievable with table-based implementations).

## References

- **NIST SP 800-131A**: Transitioning the Use of Cryptographic Algorithms and Key Lengths
- **CVE-2016-2183**: SWEET32 - Birthday attacks on 64-bit block ciphers
- **CWE-208**: Observable Timing Discrepancy
- **SECURITY.md**: Detailed security analysis and mitigation guidance

## Support

DES is maintained for legacy compatibility only. Security issues inherent to the 
algorithm design (weak keys, cache timing, block size) will not be fixed as they 
would require fundamental algorithm changes incompatible with the DES specification.

For security vulnerabilities in the implementation (not the algorithm), see the 
main repository [SECURITY.md](../../SECURITY.md).

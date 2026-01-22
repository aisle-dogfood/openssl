# Test Keys Security Notice

## WARNING: INSECURE TEST-ONLY CRYPTOGRAPHIC KEYS

This directory contains header files (`testrsa.h`, `testdsa.h`) with **hard-coded private cryptographic keys** that are intended **EXCLUSIVELY** for performance benchmarking and internal testing.

### Critical Security Information

**These keys are PUBLIC KNOWLEDGE and provide ZERO SECURITY.**

#### Files Containing Test Keys:
- `testrsa.h` - RSA private keys (512, 1024, 2048, 3072, 4096, 7680, 15360-bit)
- `testdsa.h` - DSA private keys (512, 1024, 2048-bit)

#### Security Warnings:

1. **Never Use in Production**: These keys must NEVER be used in production systems, staging environments, or any real-world deployments.

2. **Public Knowledge**: These keys are embedded in public source code and should be considered compromised from the moment of their creation.

3. **No Security**: Any data encrypted or signed with these keys should be considered completely insecure and publicly accessible.

4. **Build Exclusion**: Production builds should exclude these files or ensure they are not linked into shipped binaries beyond the speed benchmark utility.

5. **CWE References**: 
   - CWE-321: Use of Hard-coded Cryptographic Key
   - CWE-798: Use of Hard-coded Credentials

#### Intended Use:

These keys are used **only** by `apps/speed.c` for:
- Performance benchmarking of cryptographic operations
- Comparing algorithm speeds without the overhead of key generation
- Internal testing and validation

#### For Developers:

If you are building or distributing OpenSSL:
- Ensure these test keys are not included in security-sensitive contexts
- Consider excluding test headers from production builds
- Document that `apps/speed` is a benchmarking tool, not for production use
- Never copy or reuse these keys in other projects or systems

#### Compliance:

Using these keys in production systems may violate:
- Security compliance requirements (PCI-DSS, HIPAA, etc.)
- Industry best practices
- Organizational security policies
- Regulatory requirements

---

**When in doubt, generate fresh cryptographic keys specific to your use case.**

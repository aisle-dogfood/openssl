# SEH (Structured Exception Handling) Security Documentation

## Overview

The poly1305-x86_64.pl Perl assembler script generates Win64 assembly code with custom SEH exception handlers for AVX/AVX2/AVX512 code paths. These handlers are **security-critical** components that manage XMM register restoration during exception unwinding.

## Security-Critical Components

### 1. Custom Exception Handlers

- **avx_handler**: Restores XMM6-XMM15 registers during exception unwinding
- **se_handler**: Standard handler for non-XMM code paths

### 2. SEH Metadata Labels

The following labels mark precise boundaries in the code and are referenced in .pdata/.xdata sections:

#### AVX Path:
- `.Ldo_avx_body` - Marks completion of XMM register saves
- `.Ldo_avx_epilogue` - Marks start of XMM register restoration

#### AVX2 Path:
- `.Ldo_avx2_body` - Marks completion of XMM register saves
- `.Ldo_avx2_epilogue` - Marks start of XMM register restoration

#### AVX512 Path:
- `.Ldo_avx512_body` - Marks completion of XMM register saves
- `.Ldo_avx512_epilogue` - Marks start of XMM register restoration

## Security Risk: Label Drift

### The Vulnerability

Any drift between SEH metadata labels and actual code structure can cause:

1. **Incorrect XMM Register Restoration**: The exception handler may restore XMM6-XMM15 at the wrong time or from wrong locations, corrupting cryptographic state
2. **Stack Unwinding Errors**: Incorrect RIP boundary checks could cause crashes or undefined behavior
3. **Potential Security Exploits**: If exception handling can be triggered and controlled, incorrect state restoration could be exploited

### Root Cause

The HandlerData[] entries in .xdata sections contain RVA (Relative Virtual Address) pointers to body/epilogue labels. These labels must be:
- Placed at exact prologue/epilogue boundaries
- Kept synchronized with any code changes
- Referenced correctly in .xdata sections

Manual maintenance of this synchronization is error-prone.

## Mitigation: Build-Time Validation

### Implementation

The poly1305-x86_64.pl script now includes build-time validation (lines 4245-4285) that:

1. **Verifies Label Existence**: Checks that all required body/epilogue labels exist in generated code
2. **Fails Fast**: Build fails immediately if labels are missing
3. **Provides Clear Error Messages**: Indicates which label is missing and why it's critical

### Validation Code

```perl
if ($win64) {
    my @required_labels = (
        '.Lblocks_body', '.Lblocks_epilogue'
    );
    
    if ($avx) {
        push @required_labels, (
            '.Lblocks_avx_body', '.Lblocks_avx_epilogue',
            '.Lbase2_64_avx_body', '.Lbase2_64_avx_epilogue',
            '.Ldo_avx_body', '.Ldo_avx_epilogue'
        );
    }
    
    # ... additional checks for AVX2, AVX512
    
    foreach my $label (@required_labels) {
        if ($code !~ /\Q$label\E:/) {
            die "CRITICAL SEH VALIDATION ERROR: Required label '$label' not found...";
        }
    }
}
```

## Developer Guidelines

### When Modifying Prologues/Epilogues

1. **DO NOT MOVE LABELS**: The body/epilogue labels must remain at exact boundaries
   - Body labels: AFTER all XMM register saves complete
   - Epilogue labels: BEFORE any XMM register restoration begins

2. **UPDATE ALL REFERENCES**: If you must change label positions:
   - Update the label definition in the code
   - Update the .xdata HandlerData[] reference
   - Verify stack offsets (0x50-0xf8 from R11) match actual layout

3. **TEST THOROUGHLY**: After any changes:
   - Build for Win64 to trigger validation
   - Run exception handling tests if available
   - Verify with debugging tools that unwinding works correctly

### Adding New AVX Functions

If adding new AVX functions with custom SEH handling:

1. **Define Body/Epilogue Labels**: 
   ```assembly
   vmovdqa %xmm15, 0xe0(%r11)
   .Lnew_function_body:     # After all XMM saves
   # ... function body ...
   .Lnew_function_epilogue:  # Before XMM restoration
   vmovdqa 0x50(%r11), %xmm6
   ```

2. **Add .xdata Entry**:
   ```assembly
   .rva avx_handler
   .rva .Lnew_function_body, .Lnew_function_epilogue
   ```

3. **Add to Validation**:
   ```perl
   push @required_labels, (
       '.Lnew_function_body', '.Lnew_function_epilogue'
   );
   ```

## CI/CD Recommendations

### Recommended Tests

1. **Build Validation**: Ensure Win64 builds succeed (validates labels exist)
2. **Exception Testing**: If possible, add tests that trigger exceptions in AVX paths
3. **Unwind Metadata Verification**: Use tools like `dumpbin /unwindinfo` to verify .pdata/.xdata correctness

### Future Enhancements

Consider:
1. **Position Validation**: Extend validation to check labels are at correct positions (currently only checks existence)
2. **Offset Validation**: Verify XMM save/restore offsets match between prologue/epilogue and handler
3. **Automated Testing**: Create test harness that triggers exceptions and verifies correct unwinding

## References

- Windows x64 ABI: https://docs.microsoft.com/en-us/cpp/build/exception-handling-x64
- RtlVirtualUnwind: https://docs.microsoft.com/en-us/windows/win32/api/winnt/nf-winnt-rtlvirtualunwind
- OpenSSL perlasm documentation: crypto/perlasm/x86_64-xlate.pl

## Contact

For questions about this security-critical code, consult:
- OpenSSL security team
- Assembly code maintainers
- Windows ABI experts

**IMPORTANT**: This is not theoretical - incorrect SEH metadata can and will cause real crashes and potential security vulnerabilities. Treat with appropriate care.

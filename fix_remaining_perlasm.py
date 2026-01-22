#!/usr/bin/env python3
"""
Script to fix command injection vulnerabilities in remaining perlasm scripts.
This adds the shell_quote function and wraps $ENV{CC} calls.
"""

import re
import os
import sys

# Shell quote function to insert
SHELL_QUOTE_FUNC = '''# Shell-escape a string for safe inclusion in shell commands
# Implements POSIX shell single-quote escaping
sub shell_quote {
    my $arg = shift;
    return "''" if !defined($arg) || $arg eq '';
    # For safety, if the argument contains only safe characters, return as-is
    # Safe characters: alphanumeric, dash, underscore, dot, forward slash, equals, plus
    if ($arg =~ /^[-\\w.\\/=+]+\\z/) {
        return $arg;
    }
    # Otherwise, use single-quote escaping (replace ' with '\\'' )
    $arg =~ s/'/'\\\\''/g;
    return "'$arg'";
}

'''

# List of files that still need fixing
FILES_TO_FIX = [
    'crypto/aes/asm/aes-parisc.pl',
    'crypto/aes/asm/aesni-mb-x86_64.pl',
    'crypto/aes/asm/aesni-sha1-x86_64.pl',
    'crypto/aes/asm/aesni-sha256-x86_64.pl',
    'crypto/aes/asm/aesni-xts-avx512.pl',
    'crypto/bn/asm/parisc-mont.pl',
    'crypto/bn/asm/rsaz-2k-avx512.pl',
    'crypto/bn/asm/rsaz-2k-avxifma.pl',
    'crypto/bn/asm/rsaz-3k-avx512.pl',
    'crypto/bn/asm/rsaz-3k-avxifma.pl',
    'crypto/bn/asm/rsaz-4k-avx512.pl',
    'crypto/bn/asm/rsaz-4k-avxifma.pl',
    'crypto/bn/asm/rsaz-avx2.pl',
    'crypto/bn/asm/rsaz-x86_64.pl',
    'crypto/bn/asm/x86_64-mont5.pl',
    'crypto/chacha/asm/chacha-x86.pl',
    'crypto/chacha/asm/chacha-x86_64.pl',
    'crypto/ec/asm/x25519-x86_64.pl',
    'crypto/modes/asm/aesni-gcm-x86_64.pl',
    'crypto/modes/asm/ghash-parisc.pl',
    'crypto/pariscid.pl',
    'crypto/poly1305/asm/poly1305-x86.pl',
    'crypto/poly1305/asm/poly1305-x86_64.pl',
    'crypto/rc4/asm/rc4-parisc.pl',
    'crypto/sha/asm/sha1-586.pl',
    'crypto/sha/asm/sha1-mb-x86_64.pl',
    'crypto/sha/asm/sha1-parisc.pl',
    'crypto/sha/asm/sha256-586.pl',
    'crypto/sha/asm/sha256-mb-x86_64.pl',
    'crypto/sha/asm/sha512-parisc.pl',
    'crypto/sha/asm/sha512-x86_64.pl',
]

def fix_file(filepath):
    """Fix a single perlasm file."""
    if not os.path.exists(filepath):
        print(f"Skipping {filepath} - file not found")
        return False
        
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Skip if already fixed
    if 'sub shell_quote' in content:
        print(f"Skipping {filepath} - already has shell_quote")
        return False
    
    # Skip if no $ENV{CC} usage
    if'$ENV{CC}' not in content:
        print(f"Skipping {filepath} - no $ENV{{CC}} usage")
        return False
    
    # Find insertion point (after xlate.pl die statement)
    match = re.search(r'die "can\'t locate [^"]*xlate\.pl";?\n', content)
    if match:
        insert_pos = match.end()
    else:
        # Try to find before first $ENV{CC} usage
        match = re.search(r'\$ENV\{CC\}', content)
        if match:
            # Find beginning of line
            insert_pos = content.rfind('\n', 0, match.start()) + 1
        else:
            print(f"Could not find insertion point in {filepath}")
            return False
    
    # Insert shell_quote function
    new_content = content[:insert_pos] + '\n' + SHELL_QUOTE_FUNC + content[insert_pos:]
    
    # Fix all backtick commands with $ENV{CC}
    # Pattern 1: if (`$ENV{CC} ...`) -> if (defined($ENV{CC})) { my $quoted_cc = shell_quote($ENV{CC}); if (`$quoted_cc ...`) }
    
    # Replace standalone backtick checks
    def replace_env_cc_check(match):
        indent = match.group(1)
        full_cmd = match.group(2)
        condition = match.group(3)
        body = match.group(4)
        
        # Replace $ENV{CC} with $quoted_cc in the command
        new_cmd = full_cmd.replace('$ENV{CC}', '$quoted_cc', 1)
        
        return (f'{indent}if (defined($ENV{{CC}})) {{\n'
                f'{indent}    my $quoted_cc = shell_quote($ENV{{CC}});\n'
                f'{indent}    if (`{new_cmd}`\n'
                f'{indent}{condition}) {{\n'
                f'{body}\n'
                f'{indent}    }}\n'
                f'{indent}}}')
    
    # Pattern: if (`$ENV{CC} ... 2>&1` =~ /.../) { ... }
    pattern1 = r'^([ \t]*)if \(`\$ENV\{CC\}([^`]+)`\s*\n\s*=~ (/[^/]+/)\) \{\n((?:.*\n)*?^\1\})'
    new_content = re.sub(pattern1, replace_env_cc_check, new_content, flags=re.MULTILINE)
    
    # Pattern 2: Simple if (!$var && `$ENV{CC} ...` =~ /.../) { ... }
    def replace_conditional_check(match):
        indent = match.group(1)
        pre_cond = match.group(2)
        full_cmd = match.group(3)
        condition = match.group(4)
        body = match.group(5)
        
        new_cmd = full_cmd.replace('$ENV{CC}', '$quoted_cc', 1)
        
        return (f'{indent}if ({pre_cond} && defined($ENV{{CC}})) {{\n'
                f'{indent}    my $quoted_cc = shell_quote($ENV{{CC}});\n'
                f'{indent}    if (`{new_cmd}`\n'
                f'{indent}{condition}) {{\n'
                f'{body}\n'
                f'{indent}    }}\n'
                f'{indent}}}')
    
    pattern2 = r'^([ \t]*)if \(([^&]+&& )`\$ENV\{CC\}([^`]+)`\s*\n\s*=~ (/[^/]+/)\) \{\n((?:.*\n)*?^\1\})'
    new_content = re.sub(pattern2, replace_conditional_check, new_content, flags=re.MULTILINE)
    
    # Write back
    with open(filepath, 'w') as f:
        f.write(new_content)
    
    print(f"Fixed {filepath}")
    return True

def main():
    """Main function."""
    fixed_count = 0
    for filepath in FILES_TO_FIX:
        if fix_file(filepath):
            fixed_count += 1
    
    print(f"\nFixed {fixed_count} files")
    return 0

if __name__ == '__main__':
    sys.exit(main())

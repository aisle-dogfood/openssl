#!/bin/sh
#
# check-hardcoded-keys.sh - Detect hard-coded private keys in installation paths
#
# This script checks for PEM-encoded private keys in directories that should
# not contain demo or test credentials. It helps package maintainers verify
# that production packages do not accidentally include hard-coded secrets.
#
# Usage:
#   ./check-hardcoded-keys.sh [install_prefix]
#
# Examples:
#   ./check-hardcoded-keys.sh /usr/local
#   ./check-hardcoded-keys.sh /tmp/openssl-package
#
# Exit codes:
#   0 - No hard-coded keys found in installation paths
#   1 - Hard-coded keys detected or other errors
#
# This script is intended for CI/CD pipelines and package build validation.
#
# See SECURITY-TESTING.md for complete guidance on handling demo/test keys.

set -e

# Installation prefix to check (default: /usr/local)
INSTALL_PREFIX="${1:-/usr/local}"

# Check if directory exists
if [ ! -d "$INSTALL_PREFIX" ]; then
    echo "ERROR: Directory does not exist: $INSTALL_PREFIX"
    exit 1
fi

echo "Checking for hard-coded private keys in: $INSTALL_PREFIX"
echo "========================================================"
echo ""

# Find all .pem files
PEM_FILES=$(find "$INSTALL_PREFIX" -name "*.pem" -type f 2>/dev/null || true)

if [ -z "$PEM_FILES" ]; then
    echo "No .pem files found in installation directory."
    echo "Check PASSED: No hard-coded keys detected."
    exit 0
fi

echo "Found .pem files, checking for private keys..."
echo ""

PRIVATE_KEYS_FOUND=0
SUSPICIOUS_FILES=""

# Check each .pem file for private key markers
for pem_file in $PEM_FILES; do
    # Check if file contains a private key marker
    if grep -q "BEGIN.*PRIVATE KEY" "$pem_file" 2>/dev/null; then
        # Get relative path from install prefix
        REL_PATH=$(echo "$pem_file" | sed "s|^$INSTALL_PREFIX/||")
        
        # Check if this is in an expected location for demos/tests
        # (These should NOT be in production packages)
        case "$REL_PATH" in
            share/doc/*/demos/* | \
            share/openssl/demos/* | \
            share/doc/*/test/* | \
            share/openssl/test/* | \
            usr/share/doc/*/demos/* | \
            usr/share/doc/*/test/*)
                echo "WARNING: Demo/test private key found: $pem_file"
                echo "         This file should be in a separate dev/test package,"
                echo "         NOT in the production package."
                PRIVATE_KEYS_FOUND=$((PRIVATE_KEYS_FOUND + 1))
                SUSPICIOUS_FILES="$SUSPICIOUS_FILES\n  $pem_file"
                ;;
            *)
                # Private key in unexpected location - this is critical
                echo "CRITICAL: Private key found in production path: $pem_file"
                echo "          Private keys should NEVER be in production packages."
                PRIVATE_KEYS_FOUND=$((PRIVATE_KEYS_FOUND + 1))
                SUSPICIOUS_FILES="$SUSPICIOUS_FILES\n  $pem_file"
                ;;
        esac
    fi
done

echo ""
echo "========================================================"

if [ $PRIVATE_KEYS_FOUND -eq 0 ]; then
    echo "Check PASSED: No hard-coded private keys detected."
    echo ""
    echo "All .pem files in the installation directory are certificates"
    echo "or other non-sensitive materials."
    exit 0
else
    echo "Check FAILED: Found $PRIVATE_KEYS_FOUND file(s) containing private keys."
    echo ""
    echo "Files with private keys:"
    echo "$SUSPICIOUS_FILES" | grep -v "^$"
    echo ""
    echo "ACTION REQUIRED:"
    echo "1. Remove these files from the production package"
    echo "2. Move demo/test materials to separate dev/test packages"
    echo "3. Verify packaging scripts exclude demos/ and test/ directories"
    echo ""
    echo "See .packaging-exclude for a list of files to exclude."
    echo "See SECURITY-TESTING.md for complete guidance."
    echo ""
    exit 1
fi

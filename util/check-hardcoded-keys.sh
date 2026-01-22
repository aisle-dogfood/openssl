#!/bin/sh
# Validation script to ensure hard-coded private keys are not included in release packages
# This script checks for the presence of demo/test private keys that should never be distributed

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Checking for hard-coded private keys that should not be in distributions..."

FOUND_KEYS=0

# List of hard-coded key files that must not be in releases
HARDCODED_KEYS="
demos/certs/apps/ckey.pem
demos/certs/apps/skey.pem
demos/certs/apps/skey2.pem
demos/certs/apps/intkey.pem
demos/certs/apps/rootkey.pem
demos/sslecho/key.pem
demos/sslecho/cert.pem
"

# Check if we're validating a tarball or the repository
if [ -n "$1" ]; then
    # Validating a tarball
    if [ ! -f "$1" ]; then
        echo "ERROR: File not found: $1"
        exit 1
    fi
    
    echo "Validating tarball: $1"
    
    for key in $HARDCODED_KEYS; do
        if tar -tzf "$1" 2>/dev/null | grep -q "$(basename "$1" .tar.gz)/$key"; then
            echo "ERROR: Found hard-coded key in tarball: $key"
            FOUND_KEYS=$((FOUND_KEYS + 1))
        fi
    done
    
    # Check for ML-KEM test keys
    if tar -tzf "$1" 2>/dev/null | grep -E 'test/recipes/15-test_ml_kem_codecs_data/prv-.*\.pem'; then
        echo "ERROR: Found ML-KEM test private keys in tarball"
        FOUND_KEYS=$((FOUND_KEYS + 1))
    fi
    
    # Check for ML-KEM decapsulation test vectors with embedded keys
    if tar -tzf "$1" 2>/dev/null | grep -E 'test/recipes/30-test_evp_data/evppkey_ml_kem_.*_decap\.txt'; then
        echo "ERROR: Found ML-KEM decapsulation test vectors in tarball"
        FOUND_KEYS=$((FOUND_KEYS + 1))
    fi
else
    # Validating the repository
    echo "Validating repository at: $REPO_ROOT"
    
    for key in $HARDCODED_KEYS; do
        if [ -f "$REPO_ROOT/$key" ]; then
            # File exists - check if it's marked for export-ignore
            if ! grep -q "^$key.*export-ignore" "$REPO_ROOT/.gitattributes" 2>/dev/null; then
                echo "WARNING: Key exists but not marked export-ignore: $key"
                FOUND_KEYS=$((FOUND_KEYS + 1))
            else
                echo "OK: Key marked as export-ignore: $key"
            fi
        fi
    done
    
    # Verify .gitattributes has the necessary entries
    if [ -f "$REPO_ROOT/.gitattributes" ]; then
        if ! grep -q "demos/certs/apps/.*\.pem.*export-ignore" "$REPO_ROOT/.gitattributes"; then
            echo "WARNING: .gitattributes missing demo key exclusions"
            FOUND_KEYS=$((FOUND_KEYS + 1))
        fi
        
        if ! grep -q "export-ignore" "$REPO_ROOT/.gitattributes"; then
            echo "WARNING: .gitattributes has no export-ignore entries"
            FOUND_KEYS=$((FOUND_KEYS + 1))
        fi
    else
        echo "WARNING: .gitattributes not found"
        FOUND_KEYS=$((FOUND_KEYS + 1))
    fi
fi

if [ $FOUND_KEYS -gt 0 ]; then
    echo ""
    echo "VALIDATION FAILED: Found $FOUND_KEYS issue(s) with hard-coded keys"
    echo "Hard-coded private keys MUST NOT be included in distribution packages!"
    echo "See demos/SECURITY.md for details."
    exit 1
else
    echo ""
    echo "VALIDATION PASSED: No hard-coded keys found in distribution"
    exit 0
fi

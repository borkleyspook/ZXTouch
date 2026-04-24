#!/bin/bash
# ldid-to-codesign wrapper for THEOS
# Converts ldid -S flag syntax to codesign --entitlements syntax

if [[ "$1" == -S* ]]; then
    ENTITLEMENTS="${1#-S}"
    BINARY="$2"
    
    # Handle empty entitlements (just -S with no file)
    if [ -z "$ENTITLEMENTS" ]; then
        # Just ad-hoc sign without entitlements
        codesign -f -s - "$BINARY"
    else
        # Sign with entitlements file
        if [ -f "$ENTITLEMENTS" ]; then
            codesign -f -s - --entitlements "$ENTITLEMENTS" "$BINARY"
        else
            echo "Error: Entitlements file not found: $ENTITLEMENTS" >&2
            exit 1
        fi
    fi
elif [[ "$1" == "-e" ]]; then
    # Extract entitlements
    BINARY="$2"
    codesign -d --entitlements - "$BINARY" 2>/dev/null
else
    echo "Error: Unsupported ldid operation: $@" >&2
    exit 1
fi
#!/bin/bash

# Script to add #if os(iOS) platform guards to remaining iOS service files

cd /Users/J/aiko

echo "Adding platform guards to remaining iOS service files..."

# List of remaining iOS service files that need platform guards
files=(
    "Sources/AIKOiOS/Services/iOSTextFieldService.swift"
    "Sources/AIKOiOS/Services/iOSNavigationService.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        
        # Check if file already has platform guards
        if grep -q "#if os(iOS)" "$file"; then
            echo "  -> Already has platform guards, skipping"
            continue
        fi
        
        # Create temporary file with platform guards
        {
            echo "#if os(iOS)"
            cat "$file"
            echo "#endif"
        } > "${file}.tmp"
        
        # Replace original file
        mv "${file}.tmp" "$file"
        echo "  -> Added platform guards"
    else
        echo "Warning: $file not found"
    fi
done

echo "Platform guard addition complete for remaining iOS service files!"
#!/bin/bash

# Script to add #if os(iOS) platform guards to iOS service client files

cd /Users/J/aiko

echo "Adding platform guards to iOS service client files..."

# List of iOS dependency files that need platform guards
files=(
    "Sources/AIKOiOS/Dependencies/iOSImageLoaderClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSClipboardServiceClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSFileServiceClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSVoiceRecordingClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSEmailServiceClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSNavigationServiceClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSDependencyRegistration.swift"
    "Sources/AIKOiOS/Dependencies/iOSShareServiceClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSKeyboardServiceClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSFileSystemClient.swift"
    "Sources/AIKOiOS/Dependencies/iOSTextFieldServiceClient.swift"
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

echo "Platform guard addition complete for iOS service client files!"
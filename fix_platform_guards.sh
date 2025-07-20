#\!/bin/bash

# List of files that need platform guards (without them currently)
files=(
    "Sources/AIKOiOS/Services/iOSFileService.swift"
    "Sources/AIKOiOS/Services/iOSClipboardService.swift"
    "Sources/AIKOiOS/Services/PerspectiveCorrectionPipeline.swift"
    "Sources/AIKOiOS/Services/iOSShareService.swift"
    "Sources/AIKOiOS/Services/iOSImageLoader.swift"
    "Sources/AIKOiOS/Services/iOSDocumentImageProcessor.swift"
    "Sources/AIKOiOS/Services/iOSEmailService.swift"
    "Sources/AIKOiOS/Services/iOSKeyboardService.swift"
)

echo "Adding platform guards to iOS files..."

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        
        # Create temporary file
        tmp_file="${file}.tmp"
        
        # Add #if os(iOS) at the beginning
        echo "#if os(iOS)" > "$tmp_file"
        cat "$file" >> "$tmp_file"
        
        # Add #endif at the end
        echo "#endif" >> "$tmp_file"
        
        # Replace original file
        mv "$tmp_file" "$file"
        
        echo "  ✓ Added platform guards to $file"
    else
        echo "  ✗ File not found: $file"
    fi
done

echo "Platform guard fixes completed\!"

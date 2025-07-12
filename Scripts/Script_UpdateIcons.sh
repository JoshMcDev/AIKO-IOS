#!/bin/bash

# Script to replace all filled SF Symbol icons with non-filled versions

echo "Updating all filled SF Symbol icons to non-filled versions..."

# Define the directories to search
SEARCH_DIRS=(
    "Sources/UI"
    "Sources/Features"
    "Sources/Models"
)

# Counter for replacements
total_replacements=0

# Function to replace filled icons in a file
replace_filled_icons() {
    local file="$1"
    local temp_file="${file}.tmp"
    local replacements=0
    
    # Create a copy and perform replacements
    cp "$file" "$temp_file"
    
    # List of common filled icon replacements
    # Replace .fill" with just " (for systemName: "icon.fill" patterns)
    sed -i '' 's/\.fill"/"/g' "$temp_file"
    
    # Also handle cases where .fill might be followed by other characters
    sed -i '' 's/\.fill)/)/g' "$temp_file"
    sed -i '' 's/\.fill,/,/g' "$temp_file"
    sed -i '' 's/\.fill]/]/g' "$temp_file"
    
    # Check if file was modified
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        replacements=$(grep -o 'systemName:.*"' "$file" | grep -c '\.fill"' || echo 0)
        echo "Updated: $file"
        return 0
    else
        rm "$temp_file"
        return 1
    fi
}

# Process each directory
for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        
        # Find all Swift files
        while IFS= read -r file; do
            if replace_filled_icons "$file"; then
                ((total_replacements++))
            fi
        done < <(find "$dir" -name "*.swift" -type f)
    fi
done

echo "Update complete! Modified $total_replacements files."
echo ""
echo "Note: Please review the changes and ensure all icons display correctly."
echo "Some icons may need manual adjustment if they don't have exact non-filled equivalents."
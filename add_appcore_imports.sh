#!/bin/bash

# Add import AppCore to files that use UserProfile but don't already import AppCore
cd /Users/J/AIKO

# Find all Swift files that reference UserProfile
files_with_userprofile=$(grep -r "UserProfile" Sources --include="*.swift" -l | grep -v "AppCore/" | grep -v "AIKOiOS/" | grep -v "AIKOmacOS/")

for file in $files_with_userprofile; do
    # Check if the file already imports AppCore
    if ! grep -q "import AppCore" "$file"; then
        # Add import AppCore after the Foundation import
        if grep -q "import Foundation" "$file"; then
            # Use a temporary file for safe in-place editing
            awk '/import Foundation/ && !done {print; print "import AppCore"; done=1; next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            echo "Added import AppCore to $file"
        fi
    fi
done

# Also add import AppCore to files that use UploadedDocument
files_with_uploaded=$(grep -r "UploadedDocument" Sources --include="*.swift" -l | grep -v "AppCore/" | grep -v "AIKOiOS/" | grep -v "AIKOmacOS/")

for file in $files_with_uploaded; do
    # Check if the file already imports AppCore
    if ! grep -q "import AppCore" "$file"; then
        # Add import AppCore after the Foundation import
        if grep -q "import Foundation" "$file"; then
            # Use a temporary file for safe in-place editing
            awk '/import Foundation/ && !done {print; print "import AppCore"; done=1; next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            echo "Added import AppCore to $file"
        fi
    fi
done

# Add import AppCore to files that use GeneratedDocument
files_with_generated=$(grep -r "GeneratedDocument" Sources --include="*.swift" -l | grep -v "AppCore/" | grep -v "AIKOiOS/" | grep -v "AIKOmacOS/")

for file in $files_with_generated; do
    # Check if the file already imports AppCore
    if ! grep -q "import AppCore" "$file"; then
        # Add import AppCore after the Foundation import
        if grep -q "import Foundation" "$file"; then
            # Use a temporary file for safe in-place editing
            awk '/import Foundation/ && !done {print; print "import AppCore"; done=1; next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            echo "Added import AppCore to $file"
        fi
    fi
done

# Add import AppCore to files that use SettingsData
files_with_settings=$(grep -r "SettingsData" Sources --include="*.swift" -l | grep -v "AppCore/" | grep -v "AIKOiOS/" | grep -v "AIKOmacOS/")

for file in $files_with_settings; do
    # Check if the file already imports AppCore
    if ! grep -q "import AppCore" "$file"; then
        # Add import AppCore after the Foundation import
        if grep -q "import Foundation" "$file"; then
            # Use a temporary file for safe in-place editing
            awk '/import Foundation/ && !done {print; print "import AppCore"; done=1; next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            echo "Added import AppCore to $file"
        fi
    fi
done

echo "Done adding AppCore imports"
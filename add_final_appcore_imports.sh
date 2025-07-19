#!/bin/bash

# Add AppCore import to remaining files that need it

files=(
    "Sources/Core/Components/EnhancedCard.swift"
    "Sources/Domain/Events/EventSourcingAggregate.swift"
    "Sources/Features/AgenticChatFeature.swift"
    "Sources/Features/LLMProviderSettingsFeature.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        # Check if AppCore import already exists
        if ! grep -q "import AppCore" "$file"; then
            # Add import AppCore after import Foundation
            sed -i '' 's/import Foundation/import Foundation\
import AppCore/' "$file"
            echo "Added AppCore import to $file"
        else
            echo "AppCore import already exists in $file"
        fi
    else
        echo "File not found: $file"
    fi
done

echo "Done adding final AppCore imports"
#!/bin/bash

# Add AppCore import to service files that need it

files=(
    "Sources/Services/FARCompliance.swift"
    "Sources/Services/FARPart12Compliance.swift"
    "Sources/Services/LLM/LLMManager.swift"
    "Sources/Services/LLM/LLMProviderProtocol+FollowOnActions.swift"
    "Sources/Services/FollowOnActionService.swift"
    "Sources/Services/RequirementAnalyzer.swift"
    "Sources/Services/FormMappingService.swift"
    "Sources/Services/MappingEngine.swift"
    "Sources/Services/FormRepository.swift"
    "Sources/Services/GovernmentAcquisitionPrompts.swift"
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

echo "Done adding AppCore imports to services"
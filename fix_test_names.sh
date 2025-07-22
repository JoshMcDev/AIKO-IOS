#!/bin/bash
cd "/Users/J/aiko"

echo "Fixing test class names with underscores..."

# Fix Unit test classes
find . -name "*.swift" -type f -exec sed -i '' 's/\bUnit_DocumentRepositoryTests\b/UnitDocumentRepositoryTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\bUnit_AcquisitionRepositoryTests\b/UnitAcquisitionRepositoryTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\bUnit_SAMGovRepositoryTests\b/UnitSAMGovRepositoryTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\bUnit_FormFactoryTests\b/UnitFormFactoryTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\bUnit_AcquisitionAggregateTests\b/UnitAcquisitionAggregateTests/g' {} \;

# Fix Integration test classes
find . -name "*.swift" -type f -exec sed -i '' 's/\bIntegration_FARPart53Tests\b/IntegrationFARPart53Tests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\bIntegration_SAMGovRepositoryTests\b/IntegrationSAMGovRepositoryTests/g' {} \;

# Fix Phase test classes
find . -name "*.swift" -type f -exec sed -i '' 's/\bPhase4_2_QATests\b/Phase42QATests/g' {} \;

echo "Test class name fixes completed."
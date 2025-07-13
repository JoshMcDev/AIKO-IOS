#!/bin/bash

# OCR Test Runner Script
# Validates OCR functionality on quote files

echo "🔍 AIKO OCR Validation Test Runner"
echo "=================================="
echo ""

# Change to project directory
cd /Users/J/aiko

# Check if test files exist
echo "📁 Checking test files..."
if [ -f "/Users/J/Desktop/quote pic.jpeg" ]; then
    echo "  ✅ quote pic.jpeg found"
else
    echo "  ❌ quote pic.jpeg NOT FOUND"
    exit 1
fi

if [ -f "/Users/J/Desktop/quote scan.pdf" ]; then
    echo "  ✅ quote scan.pdf found"
else
    echo "  ❌ quote scan.pdf NOT FOUND"
    exit 1
fi

echo ""
echo "🧪 Running OCR accuracy tests..."
echo ""

# Run the specific OCR test
swift test --filter OCRAccuracyTest 2>&1 | tee /Users/J/aiko/Tests/OCRValidation/test_output.log

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ OCR tests completed successfully!"
    echo ""
    echo "📊 Check the following for results:"
    echo "  - Test output: /Users/J/aiko/Tests/OCRValidation/test_output.log"
    echo "  - Validation report: /Users/J/aiko/Tests/OCRValidation/ValidationReport.md"
else
    echo ""
    echo "❌ OCR tests failed!"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check test output above for errors"
    echo "  2. Ensure Xcode project builds successfully"
    echo "  3. Verify test files are accessible"
    echo "  4. Review OCR implementation for issues"
fi

echo ""
echo "📝 Next Steps:"
echo "  1. Review extracted data in test output"
echo "  2. Compare with actual document content"
echo "  3. Calculate accuracy percentage"
echo "  4. Update ValidationReport.md with results"
echo "  5. Determine if 95% threshold is met"
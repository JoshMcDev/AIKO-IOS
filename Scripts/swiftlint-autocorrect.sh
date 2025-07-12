#!/bin/bash

# SwiftLint Autocorrect Script
# Runs SwiftLint with --fix to automatically correct violations

echo "🔧 Running SwiftLint autocorrect..."

# Change to project directory
cd "$(dirname "$0")/.." || exit 1

# Check if SwiftLint is installed
if which swiftlint >/dev/null; then
    swiftlint --fix --format
    echo "✅ SwiftLint autocorrect completed"
else
    echo "❌ Error: SwiftLint not installed"
    echo "Install with: brew install swiftlint"
    exit 1
fi
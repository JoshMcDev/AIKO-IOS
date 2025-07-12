#!/bin/bash

# SwiftLint Build Phase Script for AIKO-IOS
# This script runs SwiftLint during the build process

# Set the path to SwiftLint
# Check if SwiftLint is installed via Swift Package Manager
if which swiftlint >/dev/null; then
    swiftlint
elif [ -f "${BUILD_DIR%Build/*}SourcePackages/checkouts/SwiftLint/swiftlint" ]; then
    "${BUILD_DIR%Build/*}SourcePackages/checkouts/SwiftLint/swiftlint"
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
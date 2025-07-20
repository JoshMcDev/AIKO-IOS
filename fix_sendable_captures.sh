#!/bin/bash

# Script to help identify and fix Sendable capture issues in DocumentAnalysisFeature

echo "Finding all .run closures that need dependency capturing..."

# Extract line numbers and context for each .run closure
grep -n "\.run {" /Users/J/aiko/Sources/Features/DocumentAnalysisFeature.swift | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    echo "Line $line_num:"
    
    # Show context around the .run closure
    sed -n "$((line_num-2)),$((line_num+10))p" /Users/J/aiko/Sources/Features/DocumentAnalysisFeature.swift
    echo "---"
done
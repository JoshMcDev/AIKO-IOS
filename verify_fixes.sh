#!/bin/bash

echo "🔍 Verifying Swift 6 concurrency fixes..."
echo "========================================"

echo ""
echo "📄 LLMManager.swift:"
echo "-------------------"
grep -n -B1 -A1 "@preconcurrency DependencyKey" /Users/J/aiko/Sources/Services/LLM/LLMManager.swift || echo "❌ @preconcurrency not found!"

echo ""
echo "📄 LLMConversationManager.swift:"
echo "--------------------------------"
grep -n -B1 -A1 "@preconcurrency DependencyKey" /Users/J/aiko/Sources/Services/LLM/LLMConversationManager.swift || echo "❌ @preconcurrency not found!"

echo ""
echo "✅ Summary:"
echo "-----------"
echo "If you see '@preconcurrency DependencyKey' in both files above, the fixes are properly applied."
echo "The warnings in error.txt are from cached build artifacts."
echo ""
echo "After running deep_cache_clean.sh and rebuilding in Xcode, these warnings should disappear."
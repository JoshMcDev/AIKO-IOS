#\!/bin/bash

echo "🛑 Stopping Xcode and build processes..."
# Kill any existing Xcode or build processes
killall Xcode 2>/dev/null || true
killall xcodebuild 2>/dev/null || true

echo "🧹 Deep cleaning all build artifacts..."
# Clean derived data for this specific project
rm -rf ~/Library/Developer/Xcode/DerivedData/aiko-*

# Clean module cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/*

# Clean local build folders
rm -rf .build
rm -rf .swiftpm/xcode/build
rm -rf build/

# Clean SPM cache for good measure
rm -rf ~/Library/Caches/org.swift.swiftpm

echo "📝 Verifying fixes are in place..."
echo ""
echo "SmartDefaultsDemoView.swift - Color extension check:"
grep -n "static var windowBackground" /Users/J/aiko/Sources/Views/SmartDefaultsDemoView.swift || echo "WARNING: windowBackground not found\!"
echo ""
echo "SmartDefaultsDemoView.swift - Usage check (should show Color.windowBackground):"
grep -n "\.background(" /Users/J/aiko/Sources/Views/SmartDefaultsDemoView.swift | grep -v "^[[:space:]]*#"
echo ""

echo "✅ Deep clean complete\!"
echo ""
echo "🔨 Next steps:"
echo "1. Open Xcode"
echo "2. Let SPM packages resolve completely (wait for 'Fetching' to finish)" 
echo "3. Product → Clean Build Folder (⇧⌘K)"
echo "4. Product → Build (⌘B)"
echo ""
echo "⚠️  IMPORTANT: Make sure to let SPM finish resolving packages before building\!"

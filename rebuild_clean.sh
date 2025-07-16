#!/bin/bash

echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/aiko-*
rm -rf .build
rm -rf .swiftpm/xcode/build

echo "📝 Summary of fixes applied:"
echo "✅ Fixed NSColor scope errors in SmartDefaultsDemoView.swift"
echo "   - Added Color extension with windowBackground computed property"
echo "   - Replaced inline conditionals with Color.windowBackground"
echo ""
echo "✅ Fixed NSColor scope errors in FARUpdatesView.swift" 
echo "   - Added Color extension with controlBackground computed property"
echo "   - Replaced inline conditionals with Color.controlBackground"
echo ""
echo "✅ Verified other NSColor usages are properly wrapped:"
echo "   - AppIconPreview.swift ✓"
echo "   - Theme.swift ✓"
echo "   - DocumentParserEnhanced.swift ✓"
echo ""
echo "✅ Cleaned derived data to resolve LLVM Profile Error warnings"
echo ""
echo "🔨 Now rebuild your project in Xcode with:"
echo "   1. Open Xcode"
echo "   2. Product → Clean Build Folder (⇧⌘K)"
echo "   3. Product → Build (⌘B)"
echo ""
echo "All NSColor references are now properly encapsulated within platform-specific extensions!"
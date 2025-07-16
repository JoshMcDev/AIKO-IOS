#!/bin/bash

echo "🚨 AGGRESSIVE CACHE CLEAN - This will clear ALL Xcode caches"
echo "=================================================="

# Kill Xcode and related processes
echo "🛑 Stopping all Xcode processes..."
killall Xcode 2>/dev/null || true
killall xcodebuild 2>/dev/null || true
killall IBAgent-iOS 2>/dev/null || true
killall CoreSimulatorService 2>/dev/null || true

# Clear derived data
echo "🧹 Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clear module cache
echo "🧹 Clearing Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/*

# Clear build intermediates
echo "🧹 Clearing build intermediates..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*/Build/Intermediates.noindex/*

# Clear Swift Package Manager cache
echo "🧹 Clearing SPM cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages/

# Clear Xcode caches
echo "🧹 Clearing Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/

# Clear local project build folders
echo "🧹 Clearing local build folders..."
rm -rf .build/
rm -rf build/
rm -rf .swiftpm/

# Clear LLVM profile data
echo "🧹 Clearing LLVM profile data..."
rm -f default.profraw
find . -name "*.profraw" -delete 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "*.profraw" -delete 2>/dev/null || true

echo ""
echo "✅ Aggressive clean complete!"
echo ""
echo "🔨 Next steps:"
echo "1. Open Xcode"
echo "2. Wait for indexing to complete"
echo "3. Product → Clean Build Folder (⇧⌘K)"
echo "4. Close and reopen the project"
echo "5. Let SPM resolve packages completely"
echo "6. Product → Build (⌘B)"
echo ""
echo "⚠️  The first build will take longer as everything is rebuilt from scratch"
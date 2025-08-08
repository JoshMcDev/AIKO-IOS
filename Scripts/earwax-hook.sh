#!/bin/bash

# Earwax Hook - AIKO Swift Compilation Error Auto-Resolver
# Automatically resolves common Swift compilation errors when todos are completed
# Designed specifically for the AIKO project's multi-platform Swift architecture

set -euo pipefail

# Configuration
PROJECT_ROOT="/Users/J/aiko"
LOG_FILE="$PROJECT_ROOT/earwax-hook.log"
SOURCES_DIR="$PROJECT_ROOT/Sources"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] EARWAX: $1" | tee -a "$LOG_FILE"
}

# Check if we're in AIKO project
if [[ ! -d "$PROJECT_ROOT" ]] || [[ ! -f "$PROJECT_ROOT/Package.swift" ]]; then
    log "Not in AIKO project directory, skipping Earwax hook"
    exit 0
fi

log "Earwax hook triggered - analyzing todo completion"

# Function to detect TDD process completion ONLY
detect_tdd_completion() {
    local todo_content="$1"
    
    log "Analyzing content for TDD completion..."
    
    # ONLY trigger for complete TDD workflow completion
    # Must have ALL of these indicators:
    # 1. Multiple completed tasks (full TDD workflow)
    # 2. Specific TDD phase completion keywords
    # 3. Documentation phase completion (final step)
    
    if echo "$todo_content" | grep -q '"status":\s*"completed"'; then
        
        local completed_count=$(echo "$todo_content" | grep -o '"status":\s*"completed"' | wc -l)
        local total_count=$(echo "$todo_content" | grep -o '"status":\s*"[^"]*"' | wc -l)
        
        log "Found $completed_count completed tasks out of $total_count total"
        
        # Must have at least 6 completed tasks (full TDD workflow: research, prd, design, guardian, dev, green, refactor, qa, docs)
        if (( completed_count >= 6 && completed_count == total_count )); then
            
            # Check for SPECIFIC TDD workflow completion indicators
            if echo "$todo_content" | grep -qi -e "tdd-updoc-manager.*complete" -e "documentation.*complete" -e "Update ProjectTasks.*complete"; then
                
                # Must also contain TDD-specific terminology
                if echo "$todo_content" | grep -qi -e "tdd.*process" -e "regulation.*processing.*pipeline" -e "qa.*phase" -e "refactor.*phase" -e "green.*phase"; then
                    log "🎉 COMPLETE TDD WORKFLOW DETECTED!"
                    log "✅ Full workflow: $completed_count tasks completed"
                    log "✅ Documentation phase complete"
                    log "✅ TDD-specific terminology found"
                    return 0
                else
                    log "❌ Missing TDD-specific terminology"
                fi
            else
                log "❌ Missing documentation completion indicator"
            fi
        else
            log "❌ Insufficient tasks completed ($completed_count < 6 or not all complete)"
        fi
    else
        log "❌ No completed tasks found"
    fi
    
    log "⏳ TDD process not yet complete, skipping Earwax..."
    return 1
}

# Parse hook input (JSON from TodoWrite completion)
INPUT=$(cat)

# Check for TDD completion before proceeding
if ! detect_tdd_completion "$INPUT"; then
    log "Not a complete TDD workflow, skipping Earwax"
    exit 0
fi

log "COMPLETE TDD WORKFLOW detected - running Swift compilation fixes"

# Swift compilation error resolution functions
fix_sendable_warnings() {
    log "Fixing @Sendable capture warnings"
    find "$SOURCES_DIR" -name "*.swift" -type f | while read -r file; do
        # Fix common @Sendable capture patterns
        if grep -q "capture of" "$file" && grep -q "@Sendable" "$file"; then
            # Add @Sendable to closure parameters that need it
            sed -i '' 's/{ \[\(.*\)\] in/{ @Sendable [\1] in/g' "$file" 2>/dev/null || true
            sed -i '' 's/{ (\([^)]*\)) in/{ @Sendable (\1) in/g' "$file" 2>/dev/null || true
        fi
    done
}

fix_platform_guards() {
    log "Adding missing platform availability guards"
    find "$SOURCES_DIR" -name "*.swift" -type f | while read -r file; do
        # Add iOS availability guards for iOS-specific APIs
        if grep -q "UIKit\|UIApplication\|UIViewController" "$file" && ! grep -q "@available.*iOS" "$file"; then
            if [[ "$file" == *"iOS"* ]] || [[ "$file" == *"UIKit"* ]]; then
                # Add iOS availability at the beginning of iOS-specific files
                if ! head -5 "$file" | grep -q "@available.*iOS"; then
                    echo -e "@available(iOS 14.0, *)\n$(cat "$file")" > "$file.tmp" && mv "$file.tmp" "$file"
                fi
            fi
        fi
        
        # Add macOS availability guards for macOS-specific APIs
        if grep -q "AppKit\|NSApplication\|NSViewController" "$file" && ! grep -q "@available.*macOS" "$file"; then
            if [[ "$file" == *"macOS"* ]] || [[ "$file" == *"AppKit"* ]]; then
                if ! head -5 "$file" | grep -q "@available.*macOS"; then
                    echo -e "@available(macOS 11.0, *)\n$(cat "$file")" > "$file.tmp" && mv "$file.tmp" "$file"
                fi
            fi
        fi
    done
}

fix_import_conflicts() {
    log "Resolving platform-specific import conflicts"
    find "$SOURCES_DIR" -name "*.swift" -type f | while read -r file; do
        # Wrap conflicting imports with platform conditionals
        if grep -q "import UIKit" "$file" && grep -q "import AppKit" "$file"; then
            sed -i '' 's/import UIKit/#if canImport(UIKit)\nimport UIKit\n#endif/g' "$file"
            sed -i '' 's/import AppKit/#if canImport(AppKit)\nimport AppKit\n#endif/g' "$file"
        fi
        
        # Fix VisionKit imports for cross-platform compatibility
        if grep -q "import VisionKit" "$file"; then
            sed -i '' 's/import VisionKit/#if canImport(VisionKit)\nimport VisionKit\n#endif/g' "$file"
        fi
    done
}

fix_async_concurrency_warnings() {
    log "Fixing async/await concurrency warnings"
    find "$SOURCES_DIR" -name "*.swift" -type f | while read -r file; do
        # Add @MainActor to UI-related classes that need it
        if grep -q "ObservableObject\|@Published\|SwiftUI" "$file" && ! grep -q "@MainActor" "$file"; then
            # Add @MainActor to view models and UI classes
            sed -i '' 's/class \([A-Za-z]*ViewModel\|[A-Za-z]*View\)/@MainActor\nclass \1/g' "$file" 2>/dev/null || true
        fi
        
        # Fix Task creation with proper isolation
        sed -i '' 's/Task {/Task { @MainActor in/g' "$file" 2>/dev/null || true
    done
}

fix_test_compilation_issues() {
    log "Fixing test compilation issues"
    find "$PROJECT_ROOT/Tests" -name "*.swift" -type f 2>/dev/null | while read -r file; do
        # Fix @testable import issues for cross-platform modules
        if grep -q "@testable import AIKO" "$file"; then
            # Replace with platform-specific imports to avoid compilation conflicts
            if [[ "$file" == *"iOS"* ]]; then
                sed -i '' 's/@testable import AIKO/@testable import AIKOiOS/g' "$file"
            elif [[ "$file" == *"macOS"* ]]; then
                sed -i '' 's/@testable import AIKO/@testable import AIKOmacOS/g' "$file"
            else
                sed -i '' 's/@testable import AIKO/@testable import AppCore/g' "$file"
            fi
        fi
    done
}

run_swiftlint_autofix() {
    log "Running SwiftLint autocorrect for style fixes"
    if command -v swiftlint >/dev/null 2>&1; then
        cd "$PROJECT_ROOT"
        swiftlint --fix --quiet 2>/dev/null || log "SwiftLint fix completed with warnings"
    else
        log "SwiftLint not available, skipping style fixes"
    fi
}

validate_swift_compilation() {
    log "Validating Swift compilation"
    cd "$PROJECT_ROOT"
    
    # Try to build the project to check for compilation errors
    if swift build --quiet 2>/dev/null; then
        log "✅ Swift compilation successful"
        return 0
    else
        log "⚠️ Swift compilation still has issues, may need manual intervention"
        return 1
    fi
}

# Main execution
main() {
    log "Starting Earwax automatic Swift compilation fix"
    
    # Run all fix functions
    fix_sendable_warnings
    fix_platform_guards
    fix_import_conflicts
    fix_async_concurrency_warnings
    fix_test_compilation_issues
    run_swiftlint_autofix
    
    # Validate the fixes
    if validate_swift_compilation; then
        log "🎉 Earwax successfully resolved Swift compilation issues"
    else
        log "🔧 Earwax applied fixes, but manual review may be needed"
    fi
    
    log "Earwax hook completed"
}

# Run main function
main

exit 0
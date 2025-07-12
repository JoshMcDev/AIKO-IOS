#!/bin/bash

# Install Git hooks for AIKO-IOS project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GIT_DIR="$PROJECT_ROOT/.git"
HOOKS_DIR="$GIT_DIR/hooks"

echo "🔧 Installing Git hooks for AIKO-IOS..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# SwiftLint pre-commit hook
echo "🔍 Running SwiftLint..."

# Run SwiftLint on staged Swift files only
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep "\.swift$")

if [ -z "$SWIFT_FILES" ]; then
    echo "✅ No Swift files to lint"
    exit 0
fi

# Check if SwiftLint is available
if ! which swiftlint >/dev/null 2>&1; then
    echo "⚠️  Warning: SwiftLint not installed. Install with: brew install swiftlint"
    echo "Continuing without linting..."
    exit 0
fi

# Run SwiftLint on staged files
LINT_RESULT=0
for FILE in $SWIFT_FILES; do
    swiftlint lint --path "$FILE" --config .swiftlint.yml
    if [ $? -ne 0 ]; then
        LINT_RESULT=1
    fi
done

if [ $LINT_RESULT -ne 0 ]; then
    echo ""
    echo "❌ SwiftLint found issues in staged files"
    echo "Fix the issues and try committing again"
    echo "You can run './Scripts/swiftlint-autocorrect.sh' to auto-fix some issues"
    exit 1
fi

echo "✅ SwiftLint passed"
exit 0
EOF

# Make pre-commit hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will now run SwiftLint on staged Swift files before each commit."
echo "To bypass the hook (not recommended), use: git commit --no-verify"
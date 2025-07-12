.PHONY: build clean test lint lint-fix install-hooks help

# Default target
default: help

# Build the project
build:
	@echo "🔨 Building AIKO-IOS..."
	swift build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	swift package clean
	rm -rf .build
	rm -rf DerivedData

# Run tests
test:
	@echo "🧪 Running tests..."
	xcodebuild test -scheme AIKO

# Run SwiftLint
lint:
	@echo "🔍 Running SwiftLint..."
	@if which swiftlint >/dev/null; then \
		swiftlint; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
		exit 1; \
	fi

# Run SwiftLint with auto-fix
lint-fix:
	@echo "🔧 Running SwiftLint auto-fix..."
	@./Scripts/swiftlint-autocorrect.sh

# Install Git hooks
install-hooks:
	@echo "🪝 Installing Git hooks..."
	@./Scripts/install-hooks.sh

# Run all quality checks
quality: lint test
	@echo "✅ All quality checks passed!"

# Quick setup for new developers
setup: install-hooks
	@echo "🚀 Setting up AIKO-IOS development environment..."
	@echo "1. Installing Git hooks..."
	@./Scripts/install-hooks.sh
	@echo "2. Checking for SwiftLint..."
	@if which swiftlint >/dev/null; then \
		echo "✅ SwiftLint is installed"; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
	fi
	@echo "3. Building project..."
	@swift build
	@echo ""
	@echo "✅ Setup complete! Open Package.swift in Xcode to start developing."

# Show help
help:
	@echo "AIKO-IOS Makefile"
	@echo "================"
	@echo ""
	@echo "Available targets:"
	@echo "  make build         - Build the project"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make test          - Run tests"
	@echo "  make lint          - Run SwiftLint checks"
	@echo "  make lint-fix      - Run SwiftLint with auto-fix"
	@echo "  make install-hooks - Install Git pre-commit hooks"
	@echo "  make quality       - Run all quality checks (lint + test)"
	@echo "  make setup         - Quick setup for new developers"
	@echo "  make help          - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make setup      - Set up development environment"
	@echo "  2. make build      - Build the project"
	@echo "  3. make quality    - Run quality checks before committing"
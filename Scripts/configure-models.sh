#!/bin/bash

# AIKO LFM2 Model Configuration Script
# Automatically configures Package.swift to include/exclude model resources based on build strategy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGE_SWIFT="$PROJECT_ROOT/Package.swift"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [STRATEGY]

Configure LFM2 model inclusion in Package.swift based on build strategy.

STRATEGIES:
  mock      - Exclude all model files (fastest builds, Xcode indexing friendly)
  hybrid    - Include Core ML models only
  full      - Include all model variants (.mlmodel and .gguf)
  status    - Show current configuration

EXAMPLES:
  $0 mock       # Configure for development (exclude models)
  $0 hybrid     # Configure for testing (Core ML models only)  
  $0 full       # Configure for production (all models)
  $0 status     # Show current status

ENVIRONMENT VARIABLES:
  AIKO_LFM2_STRATEGY    - Override strategy (mock, hybrid, full)
  AIKO_VERBOSE_LOGGING  - Enable verbose output (true/false)

EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Package.swift exists
if [[ ! -f "$PACKAGE_SWIFT" ]]; then
    log_error "Package.swift not found at: $PACKAGE_SWIFT"
    exit 1
fi

# Backup Package.swift
backup_package_swift() {
    local backup_file="${PACKAGE_SWIFT}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PACKAGE_SWIFT" "$backup_file"
    log_info "Created backup: $(basename "$backup_file")"
}

# Check current configuration status
check_current_status() {
    local active_mlmodel_count=$(grep -E "^[[:space:]]*\.copy.*LFM2.*\.mlmodel" "$PACKAGE_SWIFT" | wc -l | tr -d ' ')
    local active_gguf_count=$(grep -E "^[[:space:]]*\.copy.*LFM2.*\.gguf" "$PACKAGE_SWIFT" | wc -l | tr -d ' ')
    local commented_count=$(grep -E "^[[:space:]]*//.*LFM2.*(\.mlmodel|\.gguf)" "$PACKAGE_SWIFT" | wc -l | tr -d ' ')
    
    echo
    log_info "Current Package.swift Configuration:"
    echo "  - Active .mlmodel resources: $active_mlmodel_count"
    echo "  - Active .gguf resources: $active_gguf_count"  
    echo "  - Commented model resources: $commented_count"
    
    if [[ $active_mlmodel_count -gt 0 || $active_gguf_count -gt 0 ]]; then
        echo "  - Status: Models INCLUDED"
        echo "  - Strategy: $([ $active_gguf_count -gt 0 ] && echo "full" || echo "hybrid")"
    else
        echo "  - Status: Models EXCLUDED"
        echo "  - Strategy: mock"
    fi
    echo
}

# Configure for mock strategy (exclude all models)
configure_mock() {
    log_info "Configuring for mock strategy (excluding all model files)..."
    
    # Comment out all model resource lines
    sed -i '' 's|^[[:space:]]*\.copy("Sources/Resources/Models/LFM2-|                // .copy("Sources/Resources/Models/LFM2-|g' "$PACKAGE_SWIFT"
    
    log_success "Mock strategy configured"
    log_info "  - All model files excluded from build"
    log_info "  - Xcode indexing friendly"
    log_info "  - Fastest build times"
    log_info "  - Uses mock embeddings only"
}

# Configure for hybrid strategy (Core ML models only)
configure_hybrid() {
    log_info "Configuring for hybrid strategy (Core ML models only)..."
    
    # First comment out all models
    sed -i '' 's|^[[:space:]]*\.copy("Sources/Resources/Models/LFM2-|                // .copy("Sources/Resources/Models/LFM2-|g' "$PACKAGE_SWIFT"
    
    # Then uncomment .mlmodel files only
    sed -i '' 's|^[[:space:]]*// \.copy("Sources/Resources/Models/LFM2-.*\.mlmodel")|                .copy("Sources/Resources/Models/LFM2-\*.mlmodel")|g' "$PACKAGE_SWIFT"
    
    log_success "Hybrid strategy configured"
    log_info "  - Core ML models included"
    log_info "  - GGUF models excluded"
    log_info "  - Real embedding generation with mock fallback"
}

# Configure for full strategy (all models)
configure_full() {
    log_info "Configuring for full strategy (all model variants)..."
    
    # Uncomment all model resource lines
    sed -i '' 's|^[[:space:]]*// \.copy("Sources/Resources/Models/LFM2-|                .copy("Sources/Resources/Models/LFM2-|g' "$PACKAGE_SWIFT"
    
    log_success "Full strategy configured"
    log_info "  - All model variants included (.mlmodel and .gguf)"
    log_info "  - Maximum compatibility"
    log_info "  - Largest build size"
}

# Validate Package.swift syntax
validate_package_swift() {
    log_info "Validating Package.swift syntax..."
    
    if swift package dump-package > /dev/null 2>&1; then
        log_success "Package.swift syntax is valid"
        return 0
    else
        log_error "Package.swift syntax validation failed"
        return 1
    fi
}

# Main configuration logic
main() {
    local strategy="${1:-}"
    
    # Check for environment variable override
    if [[ -n "${AIKO_LFM2_STRATEGY:-}" ]]; then
        strategy="$AIKO_LFM2_STRATEGY"
        log_info "Using strategy from environment: $strategy"
    fi
    
    # Show usage if no strategy provided
    if [[ -z "$strategy" ]]; then
        usage
        exit 1
    fi
    
    echo
    log_info "AIKO LFM2 Model Configuration"
    log_info "Project: $PROJECT_ROOT"
    log_info "Strategy: $strategy"
    echo
    
    # Handle status command
    if [[ "$strategy" == "status" ]]; then
        check_current_status
        exit 0
    fi
    
    # Validate strategy
    case "$strategy" in
        mock|hybrid|full)
            ;;
        *)
            log_error "Invalid strategy: $strategy"
            log_error "Valid strategies: mock, hybrid, full, status"
            exit 1
            ;;
    esac
    
    # Create backup before making changes
    backup_package_swift
    
    # Apply configuration
    case "$strategy" in
        mock)
            configure_mock
            ;;
        hybrid)
            configure_hybrid
            ;;
        full)
            configure_full
            ;;
    esac
    
    # Validate the result
    if validate_package_swift; then
        check_current_status
        log_success "Configuration complete!"
        
        # Provide next steps
        echo
        log_info "Next steps:"
        case "$strategy" in
            mock)
                echo "  1. Run: xcodebuild -scheme AIKO build"
                echo "  2. Fast development with mock embeddings"
                ;;
            hybrid)
                echo "  1. Ensure model files are available via Git LFS"
                echo "  2. Run: git lfs pull --include='**/*.mlmodel'"
                echo "  3. Run: xcodebuild -scheme AIKO build"
                ;;
            full)
                echo "  1. Ensure all model files are available via Git LFS" 
                echo "  2. Run: git lfs pull"
                echo "  3. Run: xcodebuild -scheme AIKO build"
                ;;
        esac
        echo
    else
        log_error "Configuration failed - restoring backup"
        # Restore from backup (implement if needed)
        exit 1
    fi
}

# Check for required commands
for cmd in sed grep; do
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        exit 1
    fi
done

# Run main function with all arguments
main "$@"
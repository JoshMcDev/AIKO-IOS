# LFM2 Model Build Configuration Guide

## Problem Statement

The LFM2-700M model files (149MB) were causing Xcode indexing issues and slow development builds. This document describes the hybrid architecture solution that allows developers to work efficiently while still supporting production model deployment.

## Solution Overview

The **Hybrid Architecture with Build-time Exclusion** approach provides:

1. **Development Mode**: Fast builds with mock embeddings (no large model files)
2. **Production Mode**: Real Core ML models with mock fallback
3. **Lazy Loading**: Models loaded only when needed, with automatic memory management
4. **Environment Control**: Easy switching between modes via environment variables

## Build Configuration Modes

### 1. Development Mock Mode (Default for DEBUG)
```bash
# Fastest builds, Xcode indexing friendly
AIKO_LFM2_STRATEGY=mock xcodebuild -scheme AIKO build
```
- **Behavior**: Mock embeddings only
- **Model Files**: Excluded from build
- **Build Time**: ~3-5 seconds
- **Xcode Indexing**: No issues
- **Use Case**: Daily development, testing UI/UX

### 2. Hybrid Lazy Mode (Default for RELEASE)
```bash
# Real models with fallback
AIKO_LFM2_STRATEGY=hybrid xcodebuild -scheme AIKO build
```
- **Behavior**: Lazy-load Core ML model, fallback to mock if unavailable
- **Model Files**: Included if available
- **Build Time**: ~8-12 seconds (with models)
- **Memory**: Auto-unload after 5 minutes of inactivity
- **Use Case**: Integration testing, pre-production validation

### 3. Disabled Mode
```bash
# No model loading attempted
AIKO_LFM2_STRATEGY=disabled xcodebuild -scheme AIKO build
```
- **Behavior**: No model initialization, immediate mock responses
- **Model Files**: Excluded
- **Build Time**: ~2-3 seconds
- **Use Case**: CI/CD pipelines, automated testing

### 4. Full Production Mode
```bash
# All model variants included
AIKO_LFM2_STRATEGY=full xcodebuild -scheme AIKO build
```
- **Behavior**: Multiple model formats available
- **Model Files**: All variants included (.mlmodel, .gguf)
- **Build Time**: ~15-20 seconds
- **Use Case**: App Store releases, comprehensive testing

## File Structure

```
Sources/
├── GraphRAG/
│   └── LFM2Service.swift              # Main service with hybrid architecture
├── AppCore/
│   └── Configuration/
│       └── BuildConfiguration.swift   # Build-time configuration management
└── Resources/
    └── Models/                       # Model files (conditionally included)
        ├── LFM2-700M-Unsloth-XL-GraphRAG.mlmodel  # Primary Core ML model
        ├── LFM2-700M-Q6K.gguf                     # GGUF format (future)
        └── LFM2-700M.mlmodel                      # Alternative Core ML
```

## Xcode Project Configuration

### Package.swift Configuration
```swift
// LFM2 Model Resources (conditionally included)
// Note: These large model files are excluded by default to prevent Xcode indexing issues
// Uncomment for production builds that need the actual model files:
// .copy("Resources/Models/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel"),
// .copy("Resources/Models/LFM2-700M-Q6K.gguf"),
// .copy("Resources/Models/LFM2-700M.mlmodel"),
```

### Xcode Scheme Configuration
1. **Edit Scheme** → **Run** → **Arguments** → **Environment Variables**
2. Add `AIKO_LFM2_STRATEGY` with desired value (`mock`, `hybrid`, `disabled`, `full`)
3. Optionally add `AIKO_VERBOSE_LOGGING=true` for detailed logs

## Development Workflow

### Daily Development (Recommended)
```bash
# Fast development with mock embeddings
export AIKO_LFM2_STRATEGY=mock
xcodebuild -scheme AIKO build
```

### Testing Model Integration
```bash
# Test real model loading behavior
export AIKO_LFM2_STRATEGY=hybrid
xcodebuild -scheme AIKO build
```

### CI/CD Pipeline
```bash
# Automated testing without models
export AIKO_LFM2_STRATEGY=disabled
xcodebuild -scheme AIKO test -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

### Production Release
```bash
# Full production build with models
export AIKO_LFM2_STRATEGY=full
xcodebuild -scheme AIKO archive
```

## Memory Management

The hybrid architecture includes automatic memory management:

1. **Lazy Loading**: Models loaded only on first embedding request
2. **Auto-Unload**: Models unloaded after 5 minutes of inactivity
3. **Fallback Safety**: Always falls back to mock if model loading fails
4. **Memory Monitoring**: Tracks model load/unload cycles

## Troubleshooting

### Xcode Indexing Still Slow
```bash
# Ensure mock mode is active
export AIKO_LFM2_STRATEGY=mock
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/AIKO-*
# Restart Xcode
```

### Model Loading Fails in Production
```bash
# Enable verbose logging
export AIKO_VERBOSE_LOGGING=true
# Check logs for model file availability
# Verify Bundle.main.url(forResource:withExtension:) results
```

### Build Time Too Slow
```bash
# Use mock mode for development
export AIKO_LFM2_STRATEGY=mock
# Or disable model loading entirely
export AIKO_LFM2_STRATEGY=disabled
```

## Configuration Validation

The system automatically validates configuration at startup:

```
AIKO Build Configuration:
- Build Environment: Xcode Development
- LFM2 Strategy: developmentMock
- Exclude Large Models: Yes
- Model Size Limit: 50MB
- Verbose Logging: true
```

## Future Enhancements

1. **Model Compression**: Implement Q4/Q8 quantization for smaller files
2. **Progressive Loading**: Load model segments on demand
3. **Cache Management**: Intelligent model caching across app launches
4. **A/B Testing**: Dynamic model selection based on device capabilities

## Related Files

- `Sources/GraphRAG/LFM2Service.swift` - Main implementation
- `Sources/AppCore/Configuration/BuildConfiguration.swift` - Build configuration
- `Package.swift` - Swift Package Manager configuration
- `Documentation/LFM2-Build-Configuration.md` - This documentation
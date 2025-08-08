# Project Configuration - AIKO
**Adaptive Intelligence for Kontract Optimization**

## Project Information

- **Project Name**: AIKO (Adaptive Intelligence for Kontract Optimization)
- **Version**: 6.2
- **Platform**: iOS 17.0+ / macOS 14.0+
- **Language**: Swift 6.0
- **Architecture**: Clean Architecture with Multi-Platform Support
- **Last Updated**: August 8, 2025
- **Development Status**: Active Development (55% Complete) - Regulation Processing Pipeline Production Ready

## Development Environment

### Requirements
- **Xcode**: 15.0+
- **macOS**: 14.0+ (for development)
- **Swift**: 6.0+
- **Git**: Latest version recommended

### Build Configuration
- **Swift Tools Version**: 6.0
- **Deployment Targets**: iOS 17.0+, macOS 14.0+
- **Swift Settings**: Strict concurrency enabled (`-strict-concurrency=complete`)
- **Build Time**: ~2.6s (optimized SPM configuration)

## Project Structure

### Swift Package Targets

#### 1. Main Application (`AIKO`)
- **Path**: `Sources/`
- **Dependencies**: AppCore, GraphRAG, AIKOiOS (iOS), AIKOmacOS (macOS)
- **Purpose**: Main application entry point with platform-specific UI

#### 2. Shared Core (`AppCore`)
- **Path**: `Sources/AppCore/`
- **Dependencies**: AikoCompat, Collections, MLX
- **Purpose**: Platform-agnostic business logic and services

#### 3. iOS Platform (`AIKOiOS`)
- **Path**: `Sources/AIKOiOS/`
- **Dependencies**: AppCore
- **Purpose**: iOS-specific implementations (VisionKit, UIKit integrations)

#### 4. macOS Platform (`AIKOmacOS`)
- **Path**: `Sources/AIKOmacOS/`
- **Dependencies**: AppCore
- **Purpose**: macOS-specific implementations (AppKit integrations)

#### 5. Compatibility Layer (`AikoCompat`)
- **Path**: `Sources/AikoCompat/`
- **Dependencies**: SwiftAnthropic
- **Purpose**: Wrapper for non-Sendable dependencies

#### 6. Knowledge System (`GraphRAG`)
- **Path**: `Sources/GraphRAG/`
- **Dependencies**: AppCore
- **Purpose**: Semantic search and regulatory knowledge processing
- **Status**: Production-ready regulation processing pipeline with smart chunking
- **Features**: 
  - RegulationHTMLParser: SwiftSoup-based parsing with government document format recognition
  - SmartChunkingEngine: GraphRAG-optimized 512-token chunking with semantic boundary detection  
  - MemoryManagedBatchProcessor: Actor-based processing with <100MB memory constraint enforcement
  - RegulationEmbeddingService: LFM2 integration ready for 768-dimensional vectors
  - GraphRAGRegulationStorage: ObjectBox vector database integration prepared
  - Complete Swift 6 concurrency compliance with zero critical vulnerabilities

## Dependencies

### External Dependencies
```swift
.package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", branch: "main")
.package(url: "https://github.com/apple/swift-collections", from: "1.0.0")
.package(url: "https://github.com/vapor/multipart-kit", from: "4.5.0")
.package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0")
```

### Purpose
- **SwiftAnthropic**: Anthropic Claude API integration
- **Swift Collections**: Advanced collection types
- **MultipartKit**: HTTP multipart form data handling
- **MLX Swift**: On-device ML model execution

## Development Standards

### Code Style
- Follow Swift naming conventions
- Use SwiftUI with @Observable patterns (no TCA)
- Implement protocol-based dependency injection
- Maintain platform-specific implementations
- Use async/await for asynchronous operations
- Enable strict concurrency checking

### Architecture Principles
1. **Clean Architecture**: Separate business logic from platform concerns
2. **Dependency Injection**: Use protocol-based clients for testability
3. **Multi-Platform**: Share business logic, separate platform implementations
4. **Privacy-First**: All processing on-device, no cloud dependencies
5. **Performance**: Optimize for mobile constraints (memory, battery)

### Testing Requirements
- **Unit Tests**: >80% code coverage target
- **Integration Tests**: Critical user workflows
- **Platform Tests**: iOS and macOS specific functionality
- **Performance Tests**: Document processing and AI operations

### File Organization
```
Sources/
├── AppCore/
│   ├── Dependencies/       # Protocol-based dependency injection
│   ├── Models/            # Core data models
│   ├── Services/          # Business logic services
│   │   └── Core/          # Five core engines
│   ├── Protocols/         # Service protocols
│   └── Views/             # Shared view protocols
├── AIKOiOS/
│   ├── Dependencies/      # iOS client implementations
│   └── Services/          # iOS-specific services
├── AIKOmacOS/
│   ├── Dependencies/      # macOS client implementations
│   └── Services/          # macOS-specific services
└── GraphRAG/              # Semantic search system
```

## Core Engines Architecture

### 1. AIOrchestrator
- **Location**: `Sources/AppCore/Services/Core/AIOrchestrator.swift`
- **Purpose**: Central coordination hub for all AI operations
- **Pattern**: MainActor singleton with async/await

### 2. DocumentEngine
- **Location**: `Sources/AppCore/Services/Core/DocumentEngine.swift`
- **Purpose**: Document generation and template management
- **Pattern**: Actor for thread-safe document processing

### 3. PromptRegistry
- **Location**: `Sources/AppCore/Services/Core/PromptRegistry.swift`
- **Purpose**: Optimized prompts for different document types
- **Pattern**: Struct with caching for performance

### 4. ComplianceValidator
- **Location**: `Sources/AppCore/Services/Core/ComplianceValidator.swift`
- **Purpose**: Automated FAR/DFARS compliance checking
- **Pattern**: Actor for complex validation workflows

### 5. PersonalizationEngine
- **Location**: `Sources/AppCore/Services/Core/PersonalizationEngine.swift`
- **Purpose**: User preference learning and adaptation
- **Pattern**: Actor with Core Data persistence

## Build and Test Commands

### Build Commands
```bash
# Build all targets
swift build

# Build specific target
swift build --target AIKO
swift build --target AppCore

# Build for release
swift build -c release
```

### Test Commands
```bash
# Run all tests
swift test

# Run specific test target
swift test --filter AppCoreTests
swift test --filter AIKOiOSTests
swift test --filter GraphRAGTests

# Generate test coverage
swift test --enable-code-coverage
```

## Development Workflow

### Feature Development
1. Create feature branch from `main`
2. Implement feature with appropriate tests
3. Ensure all tests pass (`swift test`)
4. Update documentation if needed
5. Submit pull request for review

### Code Review Checklist
- [ ] Code follows Swift style guidelines
- [ ] All tests pass
- [ ] New functionality has appropriate test coverage
- [ ] Documentation updated for public APIs
- [ ] No breaking changes to existing interfaces
- [ ] Performance impact considered for mobile constraints

## Debugging and Development

### Common Issues
- **Build Errors**: Ensure Xcode 15.0+ and Swift 6.0+
- **Dependency Issues**: Run `swift package resolve` to refresh
- **Platform Issues**: Check conditional compilation for iOS/macOS
- **Performance Issues**: Profile memory usage and async operations

### Development Tools
- **Xcode**: Primary IDE with Swift 6 support
- **Instruments**: Performance profiling
- **Swift Package Manager**: Dependency management
- **Git**: Version control with feature branch workflow

## Documentation References

- [Architecture Guide](Project_Architecture.md) - Detailed technical architecture
- [Project Tasks](Project_Tasks.md) - Current development roadmap
- [API Documentation](Documentation/) - Technical API references

## Environment Configuration

### Local Development
- Clone repository
- Open `Package.swift` in Xcode
- Build and run appropriate target
- Configure LLM provider keys in app settings

### CI/CD (Future)
- Automated testing on push
- Build verification for all platforms
- Code coverage reporting
- Release automation

---

**Last Updated**: August 8, 2025  
**Maintained By**: Development Team  
**Status**: Active Development
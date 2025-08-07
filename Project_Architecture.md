# AIKO Project Architecture
**Adaptive Intelligence for Kontract Optimization**

## Overview

AIKO is built using a clean, multi-platform architecture that separates business logic from platform-specific implementations. The system is designed around five core engines that handle different aspects of the application's functionality, with a strong emphasis on privacy, performance, and maintainability.

## Architectural Principles

### Core Principles
1. **Clean Architecture**: Clear separation of concerns with dependency inversion
2. **Multi-Platform**: Shared business logic with platform-specific implementations
3. **Privacy-First**: All processing happens on-device, no cloud dependencies
4. **Protocol-Based Design**: Dependency injection through protocols for testability
5. **Swift Concurrency**: Modern async/await patterns with strict concurrency
6. **Performance-Optimized**: Mobile-first design considering memory and battery constraints

### Design Patterns
- **Dependency Injection**: Protocol-based clients for platform abstraction
- **Actor Model**: Thread-safe shared state management
- **Observable Pattern**: SwiftUI state management with @Observable
- **Repository Pattern**: Data access abstraction
- **Strategy Pattern**: Algorithm selection for different document types

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      AIKO Application Layer                      │
├─────────────────────────┬───────────────────────────────────────┤
│       iOS Target        │          macOS Target                │
│   (AIKOiOS Module)      │        (AIKOmacOS Module)            │
│                         │                                       │
│  - VisionKit Scanner    │  - File Import System               │
│  - UIKit Integration    │  - AppKit Integration                │
│  - iOS-specific UI      │  - macOS-specific UI                 │
│  - Touch/Gesture        │  - Mouse/Keyboard                    │
└─────────────────────────┼───────────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────────┐
│                     AppCore (Shared Layer)                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                Five Core Engines                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │   │
│  │  │AIOrchestrator│  │DocumentEngine│  │PromptRegistry│   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘    │   │
│  │  ┌─────────────┐  ┌─────────────┐                     │   │
│  │  │ComplianceVal│  │Personalizat│                      │   │
│  │  │idator       │  │ionEngine    │                      │   │
│  │  └─────────────┘  └─────────────┘                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Service Layer (Protocols)                  │   │
│  │  - Document Processing  - Form Auto-Population         │   │
│  │  - Regulatory Lookup   - User Profile Management       │   │
│  │  - Media Management    - Progress Tracking             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                 Data Layer                              │   │
│  │  - Core Data Models    - Cache Management               │   │
│  │  - Vector Database     - Keychain Storage              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────────┐
│                   GraphRAG Knowledge System                     │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  LFM2 Service   │  │ObjectBox Vector │  │ Regulation      │ │
│  │  (On-Device ML) │  │   Database      │  │  Processor      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────────────┐
│                  External Integration Layer                     │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  LLM Providers  │  │  Regulation     │  │  System APIs    │ │
│  │  (OpenAI, etc.) │  │   Sources       │  │  (VisionKit)    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Module Architecture

### 1. Main Application (AIKO)
**Location**: `Sources/AIKO/`
**Purpose**: Application entry point and main UI coordination

```swift
// Example structure
@main struct AIKOApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(AppEnvironment.shared)
        }
    }
}
```

**Key Components**:
- Application lifecycle management
- Platform-specific UI coordination
- Environment setup and dependency injection
- Main navigation structure

### 2. Shared Core (AppCore)
**Location**: `Sources/AppCore/`
**Purpose**: Platform-agnostic business logic and services

**Structure**:
```
AppCore/
├── Dependencies/          # Protocol-based dependency injection
│   ├── CameraClient.swift
│   ├── DocumentScannerClient.swift
│   └── ...
├── Models/               # Core data models
│   ├── DocumentTypes.swift
│   ├── FormField.swift
│   └── ...
├── Services/            # Business logic services
│   ├── Core/           # Five core engines
│   ├── DocumentImageProcessor.swift
│   └── ...
├── Protocols/          # Service protocols
└── Views/             # Shared view protocols
```

**Key Features**:
- Protocol-based architecture for testability
- Shared business logic across platforms
- Core data models and types
- Service layer abstractions

### 3. iOS Platform (AIKOiOS)
**Location**: `Sources/AIKOiOS/`
**Purpose**: iOS-specific implementations

```swift
// Example iOS-specific service
public struct iOSCameraClient: CameraClient {
    public func startScanning() async throws -> ScanResult {
        // VisionKit implementation
    }
}
```

**Key Features**:
- VisionKit document scanning
- UIKit integration where needed
- iOS-specific UI components
- Touch and gesture handling

### 4. macOS Platform (AIKOmacOS)
**Location**: `Sources/AIKOmacOS/`
**Purpose**: macOS-specific implementations

```swift
// Example macOS-specific service
public struct macOSFileClient: FileClient {
    public func openDocument() async throws -> URL {
        // NSOpenPanel implementation
    }
}
```

**Key Features**:
- AppKit integration
- File system access via NSOpenPanel
- macOS-specific UI patterns
- Mouse and keyboard interactions

### 5. Compatibility Layer (AikoCompat)
**Location**: `Sources/AikoCompat/`
**Purpose**: Wrapper for non-Sendable dependencies

This module ensures Swift 6 strict concurrency compliance by wrapping external dependencies that may not be Sendable-compliant.

### 6. Knowledge System (GraphRAG)
**Location**: `Sources/GraphRAG/`
**Purpose**: Semantic search and regulatory knowledge processing

**Key Components**:
- **LFM2Service**: On-device ML model for embeddings
- **ObjectBoxSemanticIndex**: Vector database for similarity search
- **RegulationProcessor**: Processing regulatory documents
- **UnifiedSearchService**: Cross-domain semantic search

## Five Core Engines

### 1. AIOrchestrator
**File**: `Sources/AppCore/Services/Core/AIOrchestrator.swift`
**Pattern**: MainActor singleton
**Purpose**: Central coordination hub for all AI operations

```swift
@MainActor
public final class AIOrchestrator: ObservableObject, Sendable {
    public static let shared = AIOrchestrator()
    
    // Coordinates with other engines
    private let documentEngine: DocumentEngine
    private let promptRegistry: PromptRegistry
    // ... other engines
    
    public func processRequest(_ request: AIRequest) async throws -> AIResponse {
        // Central routing and coordination logic
    }
}
```

**Responsibilities**:
- Route requests to appropriate engines
- Coordinate complex multi-engine operations
- Manage AI provider selection and failover
- Performance monitoring and caching

### 2. DocumentEngine
**File**: `Sources/AppCore/Services/Core/DocumentEngine.swift`
**Pattern**: Actor for thread safety
**Purpose**: Document generation and template management

```swift
public actor DocumentEngine: Sendable {
    public func generateDocument(
        type: DocumentType,
        requirements: String,
        context: AcquisitionContext
    ) async throws -> GeneratedDocument {
        // Document generation logic
    }
}
```

**Responsibilities**:
- Generate documents from templates
- Manage document templates and formats
- Handle document versioning and tracking
- Export to various formats (PDF, RTF, etc.)

### 3. PromptRegistry
**File**: `Sources/AppCore/Services/Core/PromptRegistry.swift`
**Pattern**: Struct with caching
**Purpose**: Optimized prompts for different document types

```swift
public struct PromptRegistry: Sendable {
    public func getOptimizedPrompt(
        for documentType: DocumentType,
        context: AcquisitionContext
    ) -> String {
        // Prompt optimization logic
    }
}
```

**Responsibilities**:
- Manage prompt templates for different document types
- Optimize prompts for specific LLM providers
- A/B testing of prompt effectiveness
- Context-aware prompt selection

### 4. ComplianceValidator
**File**: `Sources/AppCore/Services/Core/ComplianceValidator.swift`
**Pattern**: Actor for complex workflows
**Purpose**: Automated FAR/DFARS compliance checking

```swift
public actor ComplianceValidator: Sendable {
    public func validateCompliance(
        document: GeneratedDocument,
        requirements: ComplianceRequirements
    ) async throws -> ValidationResult {
        // Compliance validation logic
    }
}
```

**Responsibilities**:
- Validate documents against FAR/DFARS requirements
- Generate compliance reports and citations
- Track regulatory changes and updates
- Risk assessment and mitigation suggestions

### 5. PersonalizationEngine
**File**: `Sources/AppCore/Services/Core/PersonalizationEngine.swift`
**Pattern**: Actor with Core Data persistence
**Purpose**: User preference learning and adaptation

```swift
public actor PersonalizationEngine: Sendable {
    public func getPersonalizedRecommendations(
        for user: UserProfile,
        context: AcquisitionContext
    ) async -> [Recommendation] {
        // Personalization logic
    }
}
```

**Responsibilities**:
- Learn user preferences and patterns
- Provide personalized document templates
- Adapt UI and workflows to user behavior
- Privacy-preserving analytics

## Data Architecture

### Core Data Models
**Location**: `Sources/Models/AIKO.xcdatamodeld`

The application uses Core Data for local persistence with the following key entities:
- **Document**: Generated documents and templates
- **UserProfile**: User preferences and settings
- **AcquisitionProject**: Project tracking and history
- **ComplianceRecord**: Compliance validation results

### Vector Database (ObjectBox Semantic Index)
For semantic search and regulatory knowledge, AIKO uses a sophisticated vector database system with configurable backends:

#### Architecture Overview
- **Mock Implementation (Default)**: Immediate development capability with full API compatibility
- **ObjectBox Production Backend**: High-performance native vector operations when enabled
- **Conditional Compilation**: Seamless switching between mock and production implementations

#### Data Models
```swift
// Entity model for ObjectBox integration
public final class RegulationEmbedding {
    @Id var id: Id = 0
    var content: String = ""
    var vector: Data = Data()  // Serialized [Float] embedding
    var metadata: String = ""  // JSON serialized metadata
    var timestamp: Date = Date()
    
    // ObjectBox entity annotations
    // objectbox:Entity
    required init() {}
}

// Mock implementation for development
public struct MockRegulationEmbedding {
    let id: UUID
    let vector: [Float]  // 768-dimensional LFM2 embedding
    let content: String  // Original regulation text
    let metadata: RegulationMetadata
    let timestamp: Date
}
```

#### Configuration Strategy
The mock-first approach provides:
- **Development Velocity**: Sub-second builds (0.18s) vs potential ObjectBox download timeouts
- **API Compatibility**: Identical interface regardless of backend implementation
- **Production Migration**: Clear path to enable ObjectBox via Package.swift uncommenting
- **Testing Excellence**: Full mock capabilities enable comprehensive test validation

### Keychain Storage
Sensitive data (API keys, authentication tokens) is stored securely in the iOS/macOS Keychain using the Security framework.

## Multi-Platform Implementation

### Dependency Injection Pattern
The application uses protocol-based dependency injection to abstract platform differences:

```swift
// Protocol definition in AppCore
public protocol CameraClient: Sendable {
    func startScanning() async throws -> ScanResult
}

// iOS implementation in AIKOiOS
public struct iOSCameraClient: CameraClient {
    public func startScanning() async throws -> ScanResult {
        // VisionKit implementation
    }
}

// macOS implementation in AIKOmacOS  
public struct macOSCameraClient: CameraClient {
    public func startScanning() async throws -> ScanResult {
        // File picker implementation
    }
}
```

### Platform-Specific Features

#### iOS Features
- Document scanning via VisionKit
- Touch gestures and haptic feedback
- iOS-specific UI patterns (sheets, navigation)
- Background processing capabilities

#### macOS Features
- File system integration via NSOpenPanel
- Menu bar integration
- Keyboard shortcuts and mouse interactions
- Multi-window support

## Security Architecture

### Privacy-First Design
- All AI processing uses user-provided API keys
- No data transmitted to AIKO servers
- On-device document processing and storage
- Secure keychain storage for sensitive data

### Data Protection
```swift
// Example secure storage
public actor SecureStorage {
    public func store(_ data: Data, forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        // Keychain storage implementation
    }
}
```

### Network Security
- Certificate pinning for API connections
- Request/response validation
- Rate limiting and retry logic with exponential backoff

## Performance Considerations

### Memory Management
- Actor-based concurrency for thread safety
- Lazy loading of large resources (ML models)
- Efficient image processing with CoreImage
- Cache management with LRU eviction

### Optimization Strategies
- Streaming document processing for large files
- Background processing for non-critical tasks
- Efficient vector search with approximate algorithms
- Batched API requests to minimize network overhead

## Testing Architecture

### Test Structure
```
Tests/
├── AppCoreTests/          # Shared logic tests
├── AIKOiOSTests/         # iOS-specific tests
├── AIKOmacOSTests/       # macOS-specific tests
├── GraphRAGTests/        # Knowledge system tests
└── AIKOTests/            # Integration tests
```

### Testing Patterns
- Protocol-based mocking for external dependencies
- Actor testing with async/await patterns
- UI testing with ViewInspector
- Performance testing for critical paths

### Test Coverage Goals
- Unit tests: >80% code coverage
- Integration tests: Critical user workflows
- Performance tests: Document processing, AI operations
- UI tests: Platform-specific interactions

## Future Architecture Considerations

### Scalability
- Microservice architecture for backend services (future)
- API gateway for multiple client applications
- Horizontal scaling of document processing

### Extensibility
- Plugin architecture for custom document types
- Third-party integration framework
- Extensible AI provider system

### Monitoring
- Application performance monitoring
- User analytics (privacy-compliant)
- Error tracking and crash reporting
- Usage metrics for optimization

---

**Architecture Version**: 6.2  
**Last Updated**: August 7, 2025  
**Next Review**: Quarterly architectural review
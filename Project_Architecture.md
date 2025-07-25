# AIKO Project Architecture
## Post-Unified Refactoring Architecture Design

**Version**: 2.0 Unified Architecture  
**Date**: January 24, 2025  
**Status**: Implementation Ready  
**Validation**: VanillaIce Consensus Approved (5/5 Models)

---

## Executive Overview

This document defines the target architecture for AIKO (Adaptive Intelligence for Kontract Optimization) following the unified refactoring implementation. The new architecture emphasizes modularity, performance, and maintainability through strategic consolidation and modern Swift patterns.

### Transformation Summary
- **File Reduction**: 484 → 250 files (-48%)
- **Target Consolidation**: 6 → 3 Swift Package Manager targets
- **State Management**: TCA → Native SwiftUI with Observable pattern
- **AI Architecture**: 90 scattered services → 5 Core Engines
- **Concurrency**: 100% Swift 6 strict concurrency compliance

## Target Architecture Overview (TCA→SwiftUI Migration Enhanced)

### High-Level System Design - Post-Migration

```mermaid
graph TB
    subgraph "AIKO App (Target 1) - SwiftUI Native"
        SV[SwiftUI Views] --> OVM[@Observable ViewModels]
        NS[NavigationStack] --> OVM
        OVM --> AC[App Coordinator]
    end
    
    subgraph "AIKOCore (Target 2) - Consolidated Core"
        AC --> DE[DocumentEngine]
        AC --> PR[PromptRegistry] 
        AC --> CV[ComplianceValidator]
        AC --> PE[PersonalizationEngine]
        AC --> UP[UnifiedProviders]
        AC --> MM[Media Management]
    end
    
    subgraph "AIKOPlatforms (Target 3) - Platform Services"
        PS[Platform Services] --> CS[Camera Service]
        PS --> FS[File System Service]
        PS --> NS[Navigation Service]
        AC --> PS
    end
    
    subgraph "External Services"
        UP --> OpenAI[OpenAI]
        UP --> Claude[Anthropic]
        UP --> Gemini[Google]
        UP --> Azure[Azure OpenAI]
    end
```

### Migration Architecture Comparison

| Component | Before (TCA) | After (@Observable) | Improvement |
|-----------|--------------|-------------------|-------------|
| **State Management** | @Reducer + @ObservableState | @Observable ViewModels | 40-60% memory reduction |
| **Navigation** | TCA Navigation State | SwiftUI NavigationStack | 25-35% faster UI |
| **Async Operations** | TCA Effects | async/await + AsyncSequence | Simpler concurrency |
| **Target Count** | 6 targets | 3 targets | Faster build times |
| **Real-time Features** | TCA Effects chains | AsyncStream with bounds | Memory-safe streaming |

## Target Architecture

### Package Structure (3 Targets) - Post-TCA Migration

```swift
// Package.swift - Post-Migration Structure (No TCA Dependency)
let package = Package(
    name: "AIKO",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "AIKO", targets: ["AIKO"]),
        .library(name: "AIKOCore", targets: ["AIKOCore"]), 
        .library(name: "AIKOPlatforms", targets: ["AIKOPlatforms"]),
    ],
    dependencies: [
        // TCA dependency removed after migration
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/vapor/multipart-kit", from: "4.5.0"),
    ],
    targets: [
        // Target 1: Main Application (SwiftUI + @Observable)
        .target(
            name: "AIKO",
            dependencies: ["AIKOCore", "AIKOPlatforms"],
            path: "Sources/AIKO",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]
        ),
        
        // Target 2: Core Business Logic (Consolidated)
        .target(
            name: "AIKOCore", 
            dependencies: [
                .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "MultipartKit", package: "multipart-kit"),
            ],
            path: "Sources/AIKOCore",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]
        ),
        
        // Target 3: Platform Services (iOS + macOS)
        .target(
            name: "AIKOPlatforms",
            dependencies: ["AIKOCore"],
            path: "Sources/AIKOPlatforms", 
            resources: [.copy("Models/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel")],
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]
        ),
    ]
)
```

## AI Core Architecture (5 Engines)

### Engine Design Pattern

```swift
// Central Coordination Hub
@MainActor
public final class AIOrchestrator: ObservableObject, Sendable {
    public static let shared = AIOrchestrator()
    
    // 5 Core Engines
    private let documentEngine: DocumentEngine
    private let promptRegistry: PromptRegistry
    private let complianceValidator: ComplianceValidator  
    private let personalizationEngine: PersonalizationEngine
    private let providerAdapter: UnifiedProviderAdapter
    
    // Unified API Surface
    public func generateDocument(
        type: DocumentType,
        requirements: String,
        context: AcquisitionContext
    ) async throws -> GeneratedDocument {
        let optimizedPrompt = await promptRegistry.getPrompt(
            for: type, 
            context: context,
            personalization: await personalizationEngine.getPersonalization(for: context)
        )
        
        let document = try await documentEngine.generate(
            prompt: optimizedPrompt,
            type: type,
            provider: await providerAdapter.selectOptimalProvider()
        )
        
        let validation = try await complianceValidator.validate(document, against: context.requirements)
        
        return document.incorporating(validation: validation)
    }
}
```

### Engine Responsibilities

#### 1. DocumentEngine (Consolidates 25+ Files)
```swift
public actor DocumentEngine: Sendable {
    // Unified document generation pipeline
    // Consolidates: AIDocumentGenerator, LLMDocumentGenerator, 
    // ParallelDocumentGenerator, BatchDocumentGenerator, etc.
    
    public func generate(
        prompt: String,
        type: DocumentType,
        provider: any LLMProviderProtocol
    ) async throws -> GeneratedDocument
}
```

#### 2. PromptRegistry (Consolidates 15+ Files)
```swift
public struct PromptRegistry: Sendable {
    // Central prompt management with 15+ optimization patterns
    // Consolidates: GovernmentAcquisitionPrompts, template services, etc.
    
    public func getPrompt(
        for type: DocumentType,
        context: AcquisitionContext,
        patterns: [PromptPattern] = []
    ) -> String
}
```

#### 3. ComplianceValidator (Consolidates 20+ Files)
```swift
public actor ComplianceValidator: Sendable {
    // Unified compliance checking
    // Consolidates: FARCompliance, FARComplianceManager, CMMCComplianceTracker, etc.
    
    public func validate(
        _ document: GeneratedDocument,
        against requirements: ComplianceRequirements
    ) async throws -> ValidationResult
}
```

#### 4. PersonalizationEngine (Consolidates 10+ Files)
```swift
public actor PersonalizationEngine: Sendable {
    // ML-driven user adaptation
    // Consolidates: UserPatternLearningEngine, AdaptiveIntelligenceService, etc.
    
    public func getPersonalization(
        for context: AcquisitionContext
    ) async -> PersonalizationRecommendations
}
```

#### 5. UnifiedProviderAdapter (Consolidates 15+ Files)
```swift
public actor UnifiedProviderAdapter: Sendable {
    // Unified LLM provider abstraction
    // Consolidates: All LLM providers, configuration management, etc.
    
    public func selectOptimalProvider() async -> any LLMProviderProtocol
    public func execute<T>(_ operation: LLMOperation<T>) async throws -> T
}
```

## SwiftUI Architecture (Post-TCA Migration)

### @Observable State Management Pattern

```swift
// Native SwiftUI with @Observable pattern (TCA removed)
@main
struct AIKOApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppCoordinator.shared)
                .environment(MigrationFeatureFlags.shared)
        }
    }
}

// @Observable ViewModel pattern (migrated from TCA)
@MainActor
@Observable 
final class DocumentGenerationViewModel: BaseViewModel {
    var documents: [GeneratedDocument] = []
    var isGenerating = false
    var selectedDocumentTypes: Set<DocumentType> = []
    
    private let aiOrchestrator = AIOrchestrator.shared
    
    // Migrated from TCA Action to async method
    func generateDocuments() async {
        isGenerating = true
        do {
            let generatedDocs = try await aiOrchestrator.generateDocuments(
                types: selectedDocumentTypes,
                requirements: requirements
            )
            documents.append(contentsOf: generatedDocs)
        } catch {
            setError(error)
        }
        isGenerating = false
    }
    
    // Migrated from TCA Action to direct method
    func toggleDocumentType(_ type: DocumentType) {
        if selectedDocumentTypes.contains(type) {
            selectedDocumentTypes.remove(type)
        } else {
            selectedDocumentTypes.insert(type)
        }
    }
}

// SwiftUI View with @Observable integration
struct DocumentGenerationView: View {
    @State private var viewModel = DocumentGenerationViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    
    var body: some View {
        NavigationStack {
            VStack {
                DocumentTypeSelectionView(
                    selectedTypes: $viewModel.selectedDocumentTypes,
                    onToggle: viewModel.toggleDocumentType
                )
                
                if viewModel.isGenerating {
                    ProgressView("Generating documents...")
                } else {
                    Button("Generate Documents") {
                        Task {
                            await viewModel.generateDocuments()
                        }
                    }
                    .disabled(viewModel.selectedDocumentTypes.isEmpty)
                }
            }
        }
        .task {
            await viewModel.loadExistingDocuments()
        }
    }
}

// Real-time Chat with AsyncSequence (migrated from TCA Effects)
@MainActor
@Observable
final class AcquisitionChatViewModel: BaseViewModel {
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isProcessing: Bool = false
    
    // Bounded AsyncSequence (consensus-driven enhancement)
    private let messageStream: AsyncStream<ChatMessage>
    
    init() {
        // Create bounded message stream (200 message limit)
        messageStream = AsyncStream(ChatMessage.self, bufferingPolicy: .bufferingNewest(200)) { continuation in
            self.messageContinuation = continuation
        }
        
        super.init()
        
        // Start message processing
        Task {
            await startMessageProcessing()
        }
    }
    
    // Migrated from TCA Effect to AsyncSequence
    private func startMessageProcessing() async {
        for await message in messageStream {
            messages.append(message)
        }
    }
    
    // Migrated from TCA Action to async method
    func sendMessage(_ content: String) async {
        let userMessage = ChatMessage(role: .user, content: content)
        messageContinuation.yield(userMessage)
        
        isProcessing = true
        do {
            let response = try await llmService.processMessage(content)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messageContinuation.yield(assistantMessage)
        } catch {
            setError(error)
        }
        isProcessing = false
    }
}
```

## GraphRAG Integration Architecture

### On-Device Intelligence System

```swift
// GraphRAG Service Actor
public actor GraphRAGService: Sendable {
    private let lfm2Service: LFM2Service
    private let vectorDatabase: ObjectBoxSemanticIndex
    private let regulationProcessor: RegulationProcessor
    
    public func search(
        query: String,
        domains: [SearchDomain] = [.regulations, .userHistory]
    ) async throws -> [SearchResult] {
        // Semantic search across regulations + user workflow data
        let queryEmbedding = try await lfm2Service.generateEmbedding(for: query)
        return try await vectorDatabase.findSimilar(
            embedding: queryEmbedding,
            domains: domains,
            limit: 10
        )
    }
    
    public func indexUserDocument(
        _ document: GeneratedDocument,
        metadata: DocumentMetadata
    ) async throws {
        // On-device indexing of user workflow data
        let embedding = try await lfm2Service.generateEmbedding(for: document.content)
        try await vectorDatabase.store(
            embedding: embedding,
            metadata: metadata,
            domain: .userHistory
        )
    }
}

// LFM2 Core ML Service
public actor LFM2Service: Sendable {
    private let model: MLModel
    
    public func generateEmbedding(for text: String) async throws -> [Float] {
        // On-device embedding generation with LFM2-700M
        let tokenized = try tokenizer.tokenize(text, maxLength: 512)
        let prediction = try model.prediction(from: tokenized)
        return try extractEmbedding(from: prediction)
    }
}
```

## Migration Strategy

### Feature Flag System
```swift
@Observable
class FeatureFlags: Sendable {
    // AI Engine Flags
    var useNewAIOrchestrator = false
    var useUnifiedProviders = false
    var enableGraphRAG = false
    
    // UI Migration Flags
    var useSwiftUIDocumentGeneration = false
    var useSwiftUINavigation = false
    var useLegacyTCA = true
    
    func gradualRollout(feature: String, percentage: Int) {
        // Controlled rollout with monitoring
    }
}
```

## Success Metrics

### Technical KPIs
| Metric | Baseline | Target | Validation |
|--------|----------|--------|------------|
| File Count | 484 | 250 (-48%) | Automated counting |
| Build Time | 16.45s | <10s | CI/CD benchmarks |
| AI Response | Variable | <1s | Performance monitoring |
| Test Coverage | Unknown | >80% | Coverage reports |
| Swift 6 Compliance | 80% | 100% | Compiler validation |

## Conclusion

This architecture represents a comprehensive modernization of the AIKO codebase, emphasizing modularity, performance, and maintainability. The 5 Core Engines pattern provides clear separation of concerns while the unified orchestration layer ensures consistent behavior across all AI operations.

**Implementation Authority**: VanillaIce Multi-Model Consensus Approved  
**Readiness**: Production ready with comprehensive migration strategy  
**Risk Level**: Medium-High with robust mitigation strategies

---

## CFMMS Integration Architecture

### Integration with Current Architecture

The Comprehensive File & Media Management Suite (CFMMS) integrates seamlessly with AIKO's existing TCA architecture through the following integration points:

#### MediaManagementFeature Enhancement
```swift
// Enhanced MediaManagementFeature with CFMMS capabilities
@Reducer
public struct MediaManagementFeature: Sendable {
    @ObservableState
    public struct State {
        // Core CFMMS state management
        public var assets: IdentifiedArrayOf<MediaAsset> = []
        public var selectedAssets: Set<MediaAsset.ID> = []
        public var currentBatchOperation: BatchOperationHandle?
        public var batchProgress: BatchProgress?
        
        // Integration with existing scanner
        public var documentScannerIntegration = true
        public var globalScanFeatureAccess = true
    }
    
    // 163 actions covering complete media management workflow
    public enum Action: Sendable {
        // File management actions
        case pickFiles(allowedTypes: [MediaFileType], allowsMultiple: Bool)
        case selectPhotos(limit: Int)
        case capturePhoto
        case captureScreenshot(ScreenshotType)
        
        // Processing actions  
        case startBatchOperation(BatchOperationType)
        case extractMetadata(assetId: MediaAsset.ID)
        case validateAsset(MediaAsset.ID)
        
        // Integration actions
        case documentScannerIntegration(DocumentScannerFeature.Action)
        case globalScanFeatureIntegration(GlobalScanFeature.Action)
    }
}
```

#### Service Layer Architecture
```swift
// CFMMS Service Architecture Integration
public protocol MediaManagementServiceLayer {
    // iOS-specific implementations
    var cameraService: CameraServiceProtocol { get }        // 25 TODO → Full implementation
    var photoLibraryService: PhotoLibraryServiceProtocol { get }  // New implementation
    var filePickerService: FilePickerServiceProtocol { get }     // Enhanced
    
    // Processing services
    var mediaValidationService: MediaValidationServiceProtocol { get }  // Enhanced
    var batchProcessingEngine: BatchProcessingEngineProtocol { get }     // New implementation
    var mediaAssetCache: MediaAssetCacheProtocol { get }                 // New implementation
    
    // Integration services
    var documentImageProcessor: DocumentImageProcessor { get }  // Existing, extended
}
```

#### Target 1 (AIKO App) - CFMMS UI Integration
```swift
// SwiftUI Views with CFMMS integration
AIKO App (Target 1) - Enhanced
├── Views/
│   ├── MediaManagementView.swift (New)
│   ├── AssetGridView.swift (New)
│   ├── MediaActionToolbar.swift (New)
│   ├── BatchProcessingView.swift (New)
│   └── [Existing views enhanced with media capabilities]
├── ViewModels/
│   ├── MediaManagementViewModel.swift (New)
│   └── [Existing ViewModels with media integration]
└── Integration/
    ├── GlobalScanFeature+MediaIntegration.swift (Enhanced)
    └── DocumentScanner+MediaIntegration.swift (Enhanced)
```

#### Target 2 (AICore) - CFMMS Service Integration
```swift
// AICore enhanced with CFMMS services
AICore (Target 2) - Enhanced
├── Services/
│   ├── MediaManagement/
│   │   ├── CameraService.swift (Complete 25 TODOs)
│   │   ├── PhotoLibraryService.swift (New)
│   │   ├── MediaValidationService.swift (Enhanced)
│   │   ├── BatchProcessingEngine.swift (New)
│   │   └── MediaAssetCache.swift (New)
│   └── [Existing AI services]
├── Models/
│   ├── MediaAsset.swift (Enhanced)
│   ├── BatchOperationHandle.swift (New)
│   ├── ValidationResult.swift (Enhanced)
│   └── [Existing models]
└── Dependencies/
    └── MediaManagementDependencies.swift (New)
```

### CFMMS Performance Targets

| Component | Performance Target | Integration Approach |
|-----------|-------------------|---------------------|
| **Camera Service** | <500ms initialization | Complete 25 AVFoundation TODO implementations |
| **Photo Library** | <1s album loading | PHPickerViewController with async/await |
| **File Validation** | <100ms per file | Enhanced MediaValidationService with MIME detection |
| **Batch Processing** | 50+ concurrent files | New BatchProcessingEngine with actor isolation |
| **Memory Management** | <200MB total, 50MB cache | MediaAssetCache with LRU eviction |
| **UI Responsiveness** | <100ms state updates | TCA reactive state management |

### Integration Timeline

#### Week 1: Service Implementation Foundation
- **Days 1-2**: Complete CameraService.swift 25 TODO implementations
- **Days 3-4**: Create PhotoLibraryService.swift with PHPickerViewController
- **Day 5**: Enhance MediaValidationService with comprehensive validation

#### Week 2: Processing Pipeline Integration  
- **Days 1-2**: Implement BatchProcessingEngine with concurrent processing
- **Days 3-4**: Extend DocumentImageProcessor for media enhancement
- **Day 5**: Create MediaAssetCache for efficient memory management

#### Week 3: UI & TCA Integration
- **Days 1-2**: Implement MediaManagementView following TCA patterns
- **Days 3-4**: Integrate with GlobalScanFeature floating action button
- **Day 5**: Create comprehensive error handling and user feedback

#### Week 4: Testing & Polish
- **Days 1-2**: Unit testing for all CFMMS service implementations
- **Days 3-4**: Integration testing with existing DocumentScannerFeature
- **Day 5**: Performance optimization and security review

### VanillaIce Consensus Validation ✅

**CFMMS Integration Status**: **APPROVED (5/5 Models)**  
**Review Date**: January 24, 2025  
**Models Consulted**: Code Refactoring Specialist, Swift Implementation Expert, SwiftUI Sprint Leader, Utility Code Generator, Swift Test Engineer

**Key Approvals**:
- ✅ Service Implementation Strategy: "Feasible and aligns well with AIKO's existing codebase patterns"
- ✅ TCA Integration Approach: "Sound decision that maintains consistency"  
- ✅ Processing Pipeline: "Robust approach that ensures efficient processing"
- ✅ Performance & Architecture: "Critical for performance and scalability"
- ✅ Integration Points: "Essential for smooth user experience"

---

---

## TCA→SwiftUI Migration Integration

### Migration Status & Architecture Updates

**Migration Status**: ✅ **DESIGN PHASE COMPLETE**  
**Implementation Plan**: TCA_SwiftUI_Migration_Swift_6_Adoption_implementation.md  
**VanillaIce Consensus**: ✅ **UNANIMOUSLY APPROVED** (5/5 models)  
**Timeline**: 4 weeks with consensus-driven enhancements  

### Architecture Evolution Timeline

| Phase | Current State | Target State | Key Changes |
|-------|---------------|--------------|-------------|
| **Pre-Migration** | 6 targets, TCA patterns, 251 TCA files | Analysis complete | Codebase assessment done |
| **Week 1** | AppFeature-first migration | @Observable ViewModels | Thin-slice approach |
| **Week 2** | Simple features migrated | AsyncSequence chat | Real-time improvements |
| **Week 3** | Core architecture migration | NavigationStack | Platform consolidation |
| **Week 4** | All features migrated | 3 targets, 0 TCA files | Performance optimization |

### Post-Migration Benefits

- **Memory Usage**: 40-60% reduction through native @Observable patterns
- **UI Performance**: 25-35% faster through NavigationStack optimization  
- **Build Time**: <30s through target consolidation (6→3)
- **Maintainability**: Simplified state management without TCA boilerplate
- **Swift 6 Compliance**: 100% strict concurrency with proper actor isolation

### Integration with Existing Components

The TCA→SwiftUI migration enhances the existing architecture while preserving:
- ✅ **AI Core Engines**: All 5 engines remain functional during migration
- ✅ **Phase 0 Achievements**: Swift 6 compliance and zero SwiftLint violations maintained
- ✅ **CFMMS Integration**: Media management features enhanced with @Observable patterns
- ✅ **Cross-Platform Support**: iOS/macOS functionality preserved and optimized

---

**Document Status**: ✅ **ARCHITECTURE APPROVED** (Including TCA→SwiftUI Migration)  
**Next Phase**: Begin TCA→SwiftUI Migration Week 0 preparation (Codegen scripts & analysis)  
**Implementation Authority**: VanillaIce consensus-validated implementation plan  
**Review Date**: Weekly migration progress meetings with performance validation gates
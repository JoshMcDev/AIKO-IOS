# Implementation Plan: Launch-Time Regulation Fetching

## Document Metadata
- Task: Implement Launch-Time Regulation Fetching
- Version: Initial Draft v1.0
- Date: 2025-08-07
- Author: tdd-design-architect
- Consensus Method: Pending zen:consensus validation

## Overview

This implementation plan details the architectural design and technical approach for integrating Launch-Time Regulation Fetching into the AIKO iOS Government Contracting App. The solution enables automatic download, processing, and population of the local ObjectBox vector database with official government regulations from the GSA acquisition.gov repository during initial onboarding, while maintaining strict performance requirements (<400ms launch time) through background processing.

## Architecture Impact

### Current State Analysis

The AIKO application currently has:
- **Completed ObjectBox Vector Database Foundation**: Mock-first architecture with production-ready API surface
- **LFM2-700M Core ML Model**: 149MB model integrated for 768-dimensional embeddings
- **SwiftUI + @Observable Architecture**: TCA fully migrated with modern state management
- **Swift 6 Strict Concurrency**: Complete compliance across all components
- **GraphRAG Module**: Semantic search infrastructure with RegulationProcessor and UnifiedSearchService
- **Zero Technical Debt**: Clean build status with no SwiftLint violations

### Proposed Changes

The implementation will introduce:
1. **New Service Layer Components**:
   - `RegulationFetchService`: GitHub API integration for regulation downloads
   - `BackgroundRegulationProcessor`: Background task management for processing
   - `OnboardingRegulationSetup`: Onboarding flow integration component

2. **Enhanced Existing Components**:
   - `RegulationProcessor`: Extended with batch processing and progress tracking
   - `ObjectBoxSemanticIndex`: Enhanced with bulk insert operations
   - `OnboardingViewModel`: Integration of regulation setup phase

3. **New State Management**:
   - `RegulationSetupState`: Observable state for setup progress
   - `RegulationSyncState`: Background sync state management

### Integration Points

1. **Onboarding Flow**: Insert regulation setup phase after user authentication
2. **Background Tasks**: Register background task for periodic regulation updates
3. **ObjectBox Database**: Extend schema for regulation metadata and indexing
4. **LFM2 Service**: Optimize for batch embedding generation
5. **Progress Tracking**: Integrate with existing ProgressTrackingEngine

## Implementation Details

### Components

#### 1. RegulationFetchService

```swift
// Sources/AppCore/Services/RegulationFetchService.swift
public actor RegulationFetchService: Sendable {
    private let session: URLSession
    private let rateLimiter: RateLimiter
    private let networkMonitor: NetworkMonitor
    
    public struct Configuration {
        let githubBaseURL = "https://api.github.com"
        let repository = "GSA/GSA-Acquisition-FAR"
        let branch = "master"
        let maxConcurrentDownloads = 4
        let chunkSize = 100 // Files per chunk
        let requestsPerHour = 60 // GitHub API limit
    }
    
    public func fetchRegulationManifest() async throws -> [RegulationFile] {
        // Implementation for fetching file list from GitHub API
    }
    
    public func downloadRegulations(
        files: [RegulationFile],
        progressHandler: @escaping (FetchProgress) -> Void
    ) async throws -> [DownloadedRegulation] {
        // Chunked, resumable download implementation
    }
}
```

#### 2. BackgroundRegulationProcessor

```swift
// Sources/AppCore/Services/BackgroundRegulationProcessor.swift
@MainActor
public final class BackgroundRegulationProcessor: ObservableObject {
    @Published public var state: ProcessingState = .idle
    @Published public var progress: ProcessingProgress = .init()
    
    private let fetchService: RegulationFetchService
    private let processor: RegulationProcessor
    private let semanticIndex: ObjectBoxSemanticIndex
    private let lfm2Service: LFM2Service
    
    public enum ProcessingState {
        case idle
        case fetching(phase: FetchPhase)
        case processing(phase: ProcessPhase)
        case indexing
        case completed
        case failed(Error)
    }
    
    public func startBackgroundSetup() async {
        // Orchestrate full setup pipeline
    }
    
    public func resumeFromInterruption() async {
        // Resume processing from saved checkpoint
    }
}
```

#### 3. OnboardingRegulationSetup View

```swift
// Sources/AIKOiOS/Views/OnboardingRegulationSetup.swift
struct OnboardingRegulationSetup: View {
    @StateObject private var processor = BackgroundRegulationProcessor.shared
    @State private var showDataWarning = false
    @State private var userChoice: SetupChoice = .automatic
    
    enum SetupChoice {
        case automatic
        case wifiOnly
        case skipForNow
    }
    
    var body: some View {
        VStack(spacing: 20) {
            RegulationSetupHeader()
            
            ProgressView(value: processor.progress.percentage)
                .progressViewStyle(DetailedProgressStyle())
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("\(processor.progress.filesProcessed) of \(processor.progress.totalFiles) regulations")
                }
                
                HStack {
                    Image(systemName: "clock")
                    Text("Estimated time: \(processor.progress.estimatedTimeRemaining)")
                }
                
                if networkMonitor.isUsingCellular {
                    CellularDataWarning(
                        estimatedSize: processor.progress.estimatedDownloadSize,
                        onChoice: handleDataChoice
                    )
                }
            }
            
            SetupActionButtons(
                canSkip: true,
                onSkip: skipSetup,
                onContinue: continueSetup
            )
        }
    }
}
```

### Data Models

#### 1. Regulation Entity Extensions

```swift
// Sources/GraphRAG/Models/RegulationEntities.swift
public struct RegulationMetadata: Codable {
    let source: String        // GitHub file path
    let farPart: String      // FAR part number
    let section: String      // Section identifier
    let title: String        // Regulation title
    let lastModified: Date   // Last update date
    let checksum: String     // SHA-256 hash
    let version: String      // Content version
}

public struct RegulationChunk: Codable {
    let id: UUID
    let regulationId: String
    let content: String
    let embedding: [Float]  // 768-dimensional vector
    let chunkIndex: Int
    let metadata: ChunkMetadata
}

public struct FetchProgress: Sendable {
    let phase: FetchPhase
    let filesDownloaded: Int
    let totalFiles: Int
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let currentFile: String?
    let estimatedTimeRemaining: TimeInterval
}
```

#### 2. ObjectBox Schema Extensions

```swift
// Sources/GraphRAG/ObjectBoxSchema.swift
extension RegulationEmbedding {
    // Enhanced ObjectBox entity with indexing
    @Index
    var farPart: String = ""
    
    @Index
    var section: String = ""
    
    @Index
    var lastModified: Date = Date()
    
    var checksum: String = ""
    
    // Vector index configuration
    static func configureHNSW() -> HnswIndex {
        return HnswIndex(
            dimensions: 768,
            neighborsPerNode: 30,
            indexingSearchCount: 100,
            flagOptions: .debugLogs
        )
    }
}
```

### API Design

#### 1. GitHub API Integration

```swift
// Sources/AppCore/Services/GitHub/GitHubAPIClient.swift
public protocol GitHubAPIClient: Sendable {
    func fetchRepositoryContents(
        owner: String,
        repo: String,
        path: String,
        ref: String?
    ) async throws -> [GitHubContent]
    
    func downloadFile(
        url: URL,
        progress: @escaping (Double) -> Void
    ) async throws -> Data
}

public struct GitHubContent: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let downloadUrl: URL?
    let type: ContentType
    
    enum ContentType: String, Codable {
        case file
        case dir
    }
}
```

#### 2. Background Task Registration

```swift
// Sources/AppCore/Services/BackgroundTaskManager.swift
import BackgroundTasks

public actor BackgroundTaskManager {
    static let regulationUpdateTaskIdentifier = "com.aiko.regulation-update"
    
    public func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.regulationUpdateTaskIdentifier,
            using: nil
        ) { task in
            await self.handleRegulationUpdate(task: task as! BGProcessingTask)
        }
    }
    
    public func scheduleRegulationUpdate() {
        let request = BGProcessingTaskRequest(
            identifier: Self.regulationUpdateTaskIdentifier
        )
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // Daily
        
        try? BGTaskScheduler.shared.submit(request)
    }
}
```

### Testing Strategy

#### 1. Unit Tests

```swift
// Tests/AppCoreTests/RegulationFetchServiceTests.swift
class RegulationFetchServiceTests: XCTestCase {
    func testManifestFetching() async throws {
        // Test GitHub API manifest retrieval
    }
    
    func testChunkedDownload() async throws {
        // Test chunked download with progress
    }
    
    func testRateLimiting() async throws {
        // Verify rate limiting compliance
    }
    
    func testNetworkInterruption() async throws {
        // Test resume from network failure
    }
}

// Tests/GraphRAGTests/RegulationProcessorTests.swift
class RegulationProcessorTests: XCTestCase {
    func testBatchProcessing() async throws {
        // Test batch processing efficiency
    }
    
    func testMemoryUsage() async throws {
        // Verify memory stays under 300MB
    }
    
    func testEmbeddingGeneration() async throws {
        // Test LFM2 embedding accuracy
    }
}
```

#### 2. Integration Tests

```swift
// Tests/AIKOTests/RegulationSetupIntegrationTests.swift
class RegulationSetupIntegrationTests: XCTestCase {
    func testFullSetupPipeline() async throws {
        // End-to-end setup validation
    }
    
    func testOnboardingIntegration() async throws {
        // Verify onboarding flow
    }
    
    func testBackgroundTaskExecution() async throws {
        // Test background task handling
    }
}
```

#### 3. Performance Tests

```swift
// Tests/PerformanceTests/LaunchPerformanceTests.swift
class LaunchPerformanceTests: XCTestCase {
    func testLaunchTimeWithRegulationSetup() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            // Verify <400ms launch time
        }
    }
    
    func testMemoryPressure() {
        measure(metrics: [XCTMemoryMetric()]) {
            // Verify <300MB peak memory
        }
    }
}
```

## Implementation Steps

### Phase 1: Foundation (Days 1-3)

1. **GitHub API Client Implementation**
   - Create GitHubAPIClient protocol and implementation
   - Implement rate limiting with exponential backoff
   - Add certificate pinning for security
   - Test with GSA repository access

2. **Network Monitoring Setup**
   - Implement NetworkMonitor for connectivity detection
   - Add cellular vs WiFi detection
   - Create data usage estimation logic
   - Implement network change notifications

3. **Progress Tracking Infrastructure**
   - Create ProcessingProgress model
   - Implement progress calculation algorithms
   - Add ETA estimation logic
   - Create progress persistence for resume

4. **Background Task Registration**
   - Register background task identifiers in Info.plist
   - Implement BackgroundTaskManager
   - Create task scheduling logic
   - Test background execution

### Phase 2: Core Processing (Days 4-7)

5. **Regulation Fetch Service**
   - Implement manifest fetching from GitHub
   - Create chunked download system
   - Add resume capability with checkpointing
   - Implement file validation with SHA-256

6. **Batch Processing Pipeline**
   - Extend RegulationProcessor for batching
   - Implement memory-efficient chunking
   - Add autoreleasepool management
   - Create parallel processing with Task groups

7. **LFM2 Optimization**
   - Optimize for batch embedding generation
   - Implement tensor memory management
   - Add model quantization option for older devices
   - Test on A12-A17 chip generations

8. **ObjectBox Integration**
   - Extend schema for regulation entities
   - Implement bulk insert operations
   - Configure HNSW vector indexing
   - Add transaction management

### Phase 3: UI Integration (Days 8-10)

9. **Onboarding Flow Update**
   - Create OnboardingRegulationSetup view
   - Integrate with existing onboarding flow
   - Add cellular data warning UI
   - Implement skip and resume options

10. **Progress UI Components**
    - Create DetailedProgressStyle view
    - Implement smooth progress animations
    - Add phase-specific messaging
    - Create background notification system

11. **Error Handling UI**
    - Design error recovery screens
    - Implement retry mechanisms
    - Add troubleshooting guidance
    - Create fallback options

### Phase 4: Production Readiness (Days 11-14)

12. **Error Recovery System**
    - Implement comprehensive error handling
    - Add corruption detection and repair
    - Create rollback mechanisms
    - Test all failure scenarios

13. **Performance Optimization**
    - Profile memory usage across devices
    - Optimize download and processing speed
    - Reduce launch time impact
    - Implement caching strategies

14. **Security Hardening**
    - Implement certificate pinning
    - Add signature verification
    - Secure storage encryption
    - Audit all network communications

15. **Testing and Validation**
    - Complete unit test suite
    - Run integration tests
    - Perform device-specific testing
    - Validate App Store compliance

### Phase 5: Post-Launch Features (Days 15-18)

16. **Delta Update System**
    - Implement change detection
    - Create incremental sync logic
    - Add version tracking
    - Test update scenarios

17. **Monitoring and Analytics**
    - Add performance metrics collection
    - Implement error tracking
    - Create usage analytics
    - Build admin dashboard

18. **Documentation and Handoff**
    - Complete API documentation
    - Create user guides
    - Document troubleshooting steps
    - Prepare maintenance guide

## Risk Assessment

### Technical Risks

1. **Memory Pressure on Older Devices (HIGH)**
   - **Impact**: App crashes or poor performance on A12/A13 devices
   - **Mitigation**: 
     - Device-specific memory budgets
     - Progressive download options
     - Model quantization for older chips
   - **Contingency**: Selective regulation subset for constrained devices

2. **GitHub API Rate Limiting (MEDIUM)**
   - **Impact**: Slow initial setup for some users
   - **Mitigation**:
     - Implement smart request batching
     - Use conditional requests with ETags
     - Cache API responses
   - **Contingency**: Pre-computed regulation bundles as fallback

3. **App Store Rejection Risk (MEDIUM)**
   - **Impact**: Delayed release or feature removal
   - **Mitigation**:
     - Strict adherence to 400ms launch requirement
     - Proper background task registration
     - Clear user consent for data downloads
   - **Contingency**: User-initiated setup as alternative

### Operational Risks

1. **GSA Repository Changes (MEDIUM)**
   - **Impact**: Breaking changes in regulation structure
   - **Mitigation**:
     - Flexible parsing with schema validation
     - Version detection and migration
     - Graceful degradation
   - **Contingency**: Manual update process with admin review

2. **Network Reliability Issues (LOW)**
   - **Impact**: Incomplete downloads or setup failures
   - **Mitigation**:
     - Comprehensive retry logic
     - Resume from interruption
     - Offline mode with partial data
   - **Contingency**: Progressive enhancement approach

### Performance Risks

1. **Launch Time Regression (HIGH)**
   - **Impact**: Violates iOS performance guidelines
   - **Mitigation**:
     - Async initialization without blocking
     - Lazy loading of components
     - Performance monitoring
   - **Contingency**: Defer all setup to post-launch

2. **Battery Impact (LOW)**
   - **Impact**: User complaints about battery drain
   - **Mitigation**:
     - Efficient batch processing
     - Respect low power mode
     - Background task optimization
   - **Contingency**: Manual trigger for processing

## Timeline Estimate

### Development Timeline (14 Working Days)

- **Week 1 (Days 1-5)**: Foundation and Core Services
  - Days 1-3: GitHub API, Network, Progress, Background Tasks
  - Days 4-5: Begin Regulation Fetch Service and Batch Processing

- **Week 2 (Days 6-10)**: Processing and UI
  - Days 6-7: Complete Processing Pipeline and ObjectBox Integration
  - Days 8-10: UI Integration and Progress Components

- **Week 3 (Days 11-14)**: Hardening and Testing
  - Days 11-12: Error Recovery and Performance Optimization
  - Days 13-14: Security Hardening and Complete Testing

### Milestones

1. **Day 3**: Foundation services operational
2. **Day 7**: Core processing pipeline complete
3. **Day 10**: UI integration functional
4. **Day 14**: Production-ready with full testing

### Resource Requirements

- **Development**: 1 senior iOS developer (full-time)
- **Testing**: QA engineer (50% allocation)
- **Design**: UI/UX designer (25% allocation for Days 8-10)
- **Review**: Tech lead review at each milestone

### Dependencies

- GitHub API access and rate limits confirmed
- ObjectBox vector database schema finalized
- LFM2 model optimization completed
- Onboarding flow design approved

## Success Metrics

### Primary Metrics
- Launch time remains <400ms (100% compliance)
- Setup completion rate >95% of users
- Memory usage <300MB peak on all devices
- Zero crashes during regulation processing

### Secondary Metrics
- Download completion in <5 minutes on WiFi
- Successful resume from interruption >90%
- User satisfaction rating >4.5/5
- Search performance <1 second response time

### Technical Metrics
- Test coverage >90% for new components
- Zero new SwiftLint violations
- Swift 6 strict concurrency compliance
- Build time increase <0.5 seconds
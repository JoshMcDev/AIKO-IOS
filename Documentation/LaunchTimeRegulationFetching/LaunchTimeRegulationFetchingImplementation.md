# Implementation Plan: Launch-Time Regulation Fetching

## Document Metadata
- Task: Implement Launch-Time Regulation Fetching
- Version: Enhanced v1.0
- Date: 2025-08-07
- Author: tdd-design-architect
- Consensus Method: zen:consensus synthesis applied

## Consensus Enhancement Summary

Multi-model consensus (Gemini 2.5 Pro, O3, O3-mini, GPT-4.1, O4-mini) validated the architecture with average confidence of 8.2/10. Key enhancements include: streaming JSON parsing to prevent memory bloat, deferred HNSW indexing, comprehensive dependency injection framework, pre-bundled seed data strategy, CDN alternative consideration, and feature flag implementation for staged rollout.

## Overview

This implementation plan details the architectural design and technical approach for integrating Launch-Time Regulation Fetching into the AIKO iOS Government Contracting App. The solution enables automatic download, processing, and population of the local ObjectBox vector database with official government regulations from the GSA acquisition.gov repository, while maintaining strict performance requirements (<400ms launch time) through deferred background processing and streaming optimizations.

**Enhanced with consensus insights**: Implementation prioritizes launch performance through complete deferral of heavy operations, uses streaming JSON parsing to maintain memory constraints, and includes comprehensive fallback strategies for network and device limitations.

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

**Enhanced through consensus**: Architecture refined for optimal performance and maintainability.

The implementation will introduce:

1. **New Service Layer Components**:
   - `RegulationFetchService`: Actor-based GitHub API integration with ETag caching
   - `BackgroundRegulationProcessor`: Deferred orchestration with streaming support
   - `OnboardingRegulationSetup`: Non-blocking UI with progressive disclosure
   - `DependencyContainer`: Comprehensive dependency injection framework

2. **Enhanced Existing Components**:
   - `RegulationProcessor`: Streaming JSON parsing with inputStream
   - `ObjectBoxSemanticIndex`: Deferred HNSW indexing, on-disk storage
   - `OnboardingViewModel`: Skip-and-remind-later flow support
   - `NetworkMonitor`: Enhanced with quality detection beyond cellular/WiFi

3. **New State Management**:
   - `RegulationSetupState`: Observable state with checkpoint persistence
   - `RegulationSyncState`: Background sync with versioning support
   - `FeatureFlagManager`: Staged rollout control system

### Integration Points

**Consensus-validated integration strategy**:

1. **Onboarding Flow**: Non-blocking setup with "skip & defer" option
2. **Background Tasks**: Overnight BGProcessingTask scheduling
3. **ObjectBox Database**: Lazy HNSW index building on first search
4. **LFM2 Service**: Incremental warm-up post-launch
5. **Progress Tracking**: 500ms update frequency (reduced from 100ms)
6. **Monitoring**: os_signpost integration for telemetry

## Implementation Details

### Components

#### 1. RegulationFetchService (Enhanced)

```swift
// Sources/AppCore/Services/RegulationFetchService.swift
public actor RegulationFetchService: Sendable {
    private let session: URLSession
    private let rateLimiter: ExponentialBackoffRateLimiter
    private let networkMonitor: NetworkQualityMonitor
    private let etagCache: ETagCache
    
    public struct Configuration {
        let githubBaseURL = "https://api.github.com"
        let cdnFallbackURL = "https://cdn.aiko.app/regulations" // Future CDN option
        let repository = "GSA/GSA-Acquisition-FAR"
        let branch = "master"
        let maxConcurrentDownloads = 4
        let chunkSize = 50 // Reduced for memory efficiency
        let requestsPerHour = 60
        let streamingBufferSize = 16384 // 16KB streaming buffer
    }
    
    public func fetchRegulationManifest() async throws -> AsyncStream<RegulationFile> {
        // Streaming manifest retrieval with ETag validation
        guard let etag = await etagCache.getETag(for: "manifest") else {
            return try await fetchFreshManifest()
        }
        
        // Use If-None-Match for efficiency
        return try await fetchWithETag(etag: etag)
    }
    
    public func streamRegulations(
        files: AsyncSequence<RegulationFile>,
        progressHandler: @escaping (FetchProgress) -> Void
    ) async throws -> AsyncStream<DownloadedRegulation> {
        // Memory-efficient streaming with checkpoint support
        return AsyncStream { continuation in
            Task {
                await withTaskGroup(of: DownloadedRegulation?.self) { group in
                    // Use inputStream for JSON parsing
                    // Implement os_proc_available_memory checks
                    // Support resume from checkpoint
                }
            }
        }
    }
}
```

#### 2. BackgroundRegulationProcessor (Enhanced)

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
    private let memoryMonitor: MemoryPressureMonitor
    private let logger: OSSignpostLogger
    
    public enum ProcessingState {
        case idle
        case deferred // New state for post-launch processing
        case fetching(phase: FetchPhase)
        case processing(phase: ProcessPhase)
        case indexing(deferred: Bool) // HNSW deferred until first search
        case completed
        case failed(Error)
        case skipped // User chose to skip
    }
    
    public func deferSetupPostLaunch() async {
        // Called after app launch completes
        state = .deferred
        
        // Check memory availability
        guard await memoryMonitor.hasAvailableMemory(mb: 100) else {
            await scheduleForLaterAttempt()
            return
        }
        
        // Begin background setup
        await startBackgroundSetup()
    }
    
    public func startBackgroundSetup() async {
        logger.beginInterval("regulation_setup")
        
        // Stream and process with checkpointing
        do {
            // Pre-bundled seed data first
            await loadSeedRegulations()
            
            // Then incremental updates
            await performIncrementalFetch()
            
            // Defer HNSW indexing
            state = .completed
            
        } catch {
            logger.endInterval("regulation_setup", .failure)
            state = .failed(error)
        }
    }
}
```

#### 3. Dependency Injection Framework (New)

```swift
// Sources/AppCore/Dependencies/DependencyContainer.swift
public protocol DependencyContainerProtocol {
    var networkClient: NetworkClientProtocol { get }
    var githubClient: GitHubClientProtocol { get }
    var objectBoxStore: ObjectBoxStoreProtocol { get }
    var lfm2Service: LFM2ServiceProtocol { get }
}

public final class DependencyContainer: DependencyContainerProtocol {
    // Production dependencies
    public lazy var networkClient: NetworkClientProtocol = NetworkClient()
    public lazy var githubClient: GitHubClientProtocol = GitHubClient()
    public lazy var objectBoxStore: ObjectBoxStoreProtocol = ObjectBoxStore()
    public lazy var lfm2Service: LFM2ServiceProtocol = LFM2Service()
}

public final class TestDependencyContainer: DependencyContainerProtocol {
    // Mock dependencies for testing
    public var networkClient: NetworkClientProtocol = MockNetworkClient()
    public var githubClient: GitHubClientProtocol = MockGitHubClient()
    public var objectBoxStore: ObjectBoxStoreProtocol = MockObjectBoxStore()
    public var lfm2Service: LFM2ServiceProtocol = MockLFM2Service()
}
```

#### 4. Enhanced OnboardingRegulationSetup View

```swift
// Sources/AIKOiOS/Views/OnboardingRegulationSetup.swift
struct OnboardingRegulationSetup: View {
    @StateObject private var processor = BackgroundRegulationProcessor.shared
    @State private var showDataWarning = false
    @State private var userChoice: SetupChoice = .deferToBackground
    
    enum SetupChoice {
        case deferToBackground // Default: non-blocking
        case downloadNowWiFi
        case downloadNowCellular
        case skipCompletely
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Progressive disclosure UI
            if processor.state == .idle {
                MinimalSetupPrompt(
                    onContinue: { userChoice = .deferToBackground },
                    onCustomize: { showDataWarning = true }
                )
            } else {
                DetailedProgressView(processor: processor)
            }
            
            // Network quality indicator
            NetworkQualityBadge(quality: networkMonitor.currentQuality)
            
            // Skip option always available
            Button("Skip & Remind Later") {
                processor.skipAndScheduleReminder()
            }
            .buttonStyle(.tertiary)
        }
        .task {
            // Non-blocking: schedule for background
            if userChoice == .deferToBackground {
                await processor.deferSetupPostLaunch()
            }
        }
    }
}
```

### Data Models (Enhanced)

#### 1. Streaming Support Models

```swift
// Sources/GraphRAG/Models/StreamingModels.swift
public struct StreamingRegulationChunk {
    let buffer: Data
    let isComplete: Bool
    let checkpointToken: String
    
    func parseIncremental() async throws -> [RegulationFragment] {
        // Use JSONDecoder with inputStream
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try await withCheckedThrowingContinuation { continuation in
            // Stream parsing implementation
        }
    }
}

public struct MemoryEfficientEmbedding {
    let vector: UnsafeBufferPointer<Float> // Direct memory access
    let dimensionality: Int = 768
    
    func releaseMemory() {
        // Explicit memory management for tensors
    }
}
```

#### 2. Feature Flag Configuration

```swift
// Sources/AppCore/FeatureFlags/FeatureFlagManager.swift
public struct FeatureFlags {
    public static let regulationFetchEnabled = FeatureFlag(
        key: "regulation_fetch_enabled",
        defaultValue: false, // Start disabled
        rolloutPercentage: 10 // 10% initial rollout
    )
    
    public static let deferredHNSWIndexing = FeatureFlag(
        key: "deferred_hnsw_indexing",
        defaultValue: true, // Always defer
        rolloutPercentage: 100
    )
    
    public static let useCDNFallback = FeatureFlag(
        key: "use_cdn_fallback",
        defaultValue: false,
        rolloutPercentage: 0 // Future enhancement
    )
}
```

### API Design (Enhanced)

#### 1. GitHub API with Security

```swift
// Sources/AppCore/Services/GitHub/SecureGitHubClient.swift
public actor SecureGitHubClient: GitHubClientProtocol {
    private let certificatePinner: CertificatePinner
    private let signatureValidator: SignatureValidator
    
    public func fetchWithIntegrity(
        url: URL,
        expectedSHA: String
    ) async throws -> Data {
        // Certificate pinning
        try await certificatePinner.validateCertificate(for: url)
        
        // Download with validation
        let data = try await download(url: url)
        
        // SHA-256 verification
        guard signatureValidator.verify(data: data, sha: expectedSHA) else {
            throw SecurityError.integrityCheckFailed
        }
        
        // Additional zip-bomb protection
        guard data.count < 10_000_000 else { // 10MB max per file
            throw SecurityError.suspiciousFileSize
        }
        
        return data
    }
}
```

#### 2. Monitoring and Telemetry

```swift
// Sources/AppCore/Services/Monitoring/TelemetryService.swift
import os.signpost

public final class TelemetryService {
    private let log = OSLog(subsystem: "com.aiko.regulations", category: .pointsOfInterest)
    private let signposter: OSSignposter
    
    public func trackMemoryUsage() {
        let memoryInfo = ProcessInfo.processInfo
        let physicalMemory = memoryInfo.physicalMemory
        let memoryUsage = getMemoryUsage()
        
        os_signpost(.event, log: log, name: "memory_snapshot",
                   "Used: %{public}d MB, Available: %{public}d MB",
                   memoryUsage / 1_000_000,
                   (physicalMemory - memoryUsage) / 1_000_000)
    }
    
    public func trackGitHubAPIUsage(remaining: Int, reset: Date) {
        os_signpost(.event, log: log, name: "github_rate_limit",
                   "Remaining: %{public}d, Reset: %{public}@",
                   remaining, reset as NSDate)
    }
}
```

### Testing Strategy (Enhanced)

#### 1. Unit Tests with Dependency Injection

```swift
// Tests/AppCoreTests/RegulationFetchServiceTests.swift
class RegulationFetchServiceTests: XCTestCase {
    var container: TestDependencyContainer!
    var sut: RegulationFetchService!
    
    override func setUp() {
        container = TestDependencyContainer()
        sut = RegulationFetchService(dependencies: container)
    }
    
    func testStreamingWithMemoryPressure() async throws {
        // Simulate memory pressure
        container.memoryMonitor.simulateMemoryPressure(level: .critical)
        
        // Verify graceful degradation
        let stream = try await sut.streamRegulations(files: mockFiles)
        
        var count = 0
        for await regulation in stream {
            count += 1
            XCTAssertLessThan(regulation.memoryFootprint, 10_000_000)
        }
        
        XCTAssertEqual(count, mockFiles.count)
    }
    
    func testETagCaching() async throws {
        // Test conditional requests
        let manifest1 = try await sut.fetchRegulationManifest()
        let manifest2 = try await sut.fetchRegulationManifest()
        
        XCTAssertEqual(container.githubClient.requestCount, 1)
        XCTAssertTrue(container.githubClient.usedETag)
    }
}
```

#### 2. Performance Tests

```swift
// Tests/PerformanceTests/LaunchPerformanceTests.swift
class LaunchPerformanceTests: XCTestCase {
    func testLaunchTimeWithDeferredSetup() {
        let app = XCUIApplication()
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Verify launch completes in <400ms
            let launchTime = XCTApplicationLaunchMetric.applicationLaunch
            XCTAssertLessThan(launchTime, 0.4)
            
            // Verify regulation setup is deferred
            XCTAssertFalse(app.staticTexts["Setting up regulations"].exists)
        }
    }
    
    func testMemoryUsageOnA12Device() {
        // Device-specific test
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStart]
        
        measure(metrics: [XCTMemoryMetric()], options: options) {
            startMeasuring()
            
            // Process regulations
            processTestRegulations()
            
            let peakMemory = XCTMemoryMetric.current
            XCTAssertLessThan(peakMemory, 300_000_000) // 300MB
        }
    }
}
```

## Implementation Steps (Enhanced)

### Phase 1: Foundation with Security (Days 1-3)

1. **Dependency Injection Framework**
   - Implement DependencyContainer protocol
   - Create production and test containers
   - Wire up all services with DI
   - Add URLSessionProtocol for testing

2. **Secure GitHub Client**
   - Implement certificate pinning
   - Add SHA-256 verification
   - Create ETag caching system
   - Test with rate limit simulation

3. **Memory Monitoring Infrastructure**
   - Implement os_proc_available_memory checks
   - Create adaptive chunk sizing
   - Add memory pressure callbacks
   - Test on A12 simulator profiles

4. **Telemetry Foundation**
   - Integrate os_signpost logging
   - Create performance metrics collection
   - Add crash reporting hooks
   - Set up analytics dashboard

### Phase 2: Streaming Processing (Days 4-7)

5. **Streaming JSON Parser**
   - Implement inputStream decoder
   - Create incremental parsing
   - Add checkpoint support
   - Test with large datasets

6. **Deferred Processing Pipeline**
   - Implement post-launch deferral
   - Create background warm-up
   - Add progressive loading
   - Test launch time impact

7. **Pre-bundled Seed Data**
   - Create minimal regulation subset
   - Bundle with app (50 critical regulations)
   - Implement delta sync from seed
   - Test offline-first experience

8. **Lazy HNSW Indexing**
   - Defer index building to first search
   - Implement on-disk index storage
   - Create incremental index updates
   - Profile memory usage

### Phase 3: UI and UX (Days 8-10)

9. **Progressive Disclosure UI**
   - Create minimal setup prompt
   - Implement detailed progress view
   - Add skip-and-remind option
   - Test user flow variations

10. **Network Quality Detection**
    - Implement quality monitoring
    - Create adaptive strategies
    - Add user notifications
    - Test on various connections

11. **Feature Flag Integration**
    - Implement flag manager
    - Create rollout controls
    - Add A/B testing support
    - Test flag variations

### Phase 4: Hardening (Days 11-14)

12. **Comprehensive Error Recovery**
    - Implement all fallback paths
    - Add corruption recovery
    - Create offline modes
    - Test failure scenarios

13. **Performance Optimization**
    - Profile on all device types
    - Optimize critical paths
    - Reduce memory footprint
    - Validate launch time

14. **Security Audit**
    - Penetration testing
    - Supply chain analysis
    - Credential management review
    - Privacy compliance check

15. **Production Readiness**
    - Complete test coverage
    - Documentation review
    - App Store compliance
    - Rollout plan finalization

### Phase 5: Alternative Strategies (Days 15-16)

16. **CDN Infrastructure (Future)**
    - Design CDN architecture
    - Create mirror strategy
    - Plan migration path
    - Document as enhancement

17. **Server-Side Option (Future)**
    - Design API gateway
    - Plan backend processing
    - Create hybrid approach
    - Document trade-offs

## Risk Assessment (Enhanced)

### Critical Risks with Mitigation

1. **Memory Pressure on A12/A13 Devices**
   - **Mitigation**: Streaming JSON, adaptive chunks, pre-bundled seed data
   - **Monitoring**: Real-time memory telemetry
   - **Fallback**: Partial regulation sets for constrained devices

2. **GitHub API Rate Limiting**
   - **Mitigation**: ETag caching, exponential backoff, CDN fallback planning
   - **Monitoring**: Rate limit tracking with X-RateLimit headers
   - **Fallback**: Pre-computed regulation bundles

3. **App Store Launch Time Violation**
   - **Mitigation**: Complete deferral to post-launch background
   - **Monitoring**: Launch time metrics in TestFlight
   - **Fallback**: Feature flag to disable if needed

4. **Supply Chain Security**
   - **Mitigation**: SHA verification, certificate pinning, signature validation
   - **Monitoring**: Integrity check logging
   - **Fallback**: Trusted regulation snapshots

## Timeline Estimate (Refined)

### Development Timeline (16 Working Days)

- **Week 1 (Days 1-5)**: Security foundation and streaming infrastructure
- **Week 2 (Days 6-10)**: Deferred processing and progressive UI
- **Week 3 (Days 11-14)**: Hardening, optimization, and testing
- **Week 4 (Days 15-16)**: Future strategy documentation

### Critical Milestones

1. **Day 3**: Secure foundation operational
2. **Day 7**: Streaming pipeline complete
3. **Day 10**: UI integration with deferral
4. **Day 14**: Production-ready with <400ms launch
5. **Day 16**: Complete with future roadmap

## Success Metrics (Enhanced)

### Primary Metrics
- **Launch time**: <400ms (100% compliance)
- **Memory usage**: <300MB peak on A12 devices
- **Setup completion**: >95% within 24 hours
- **Crash rate**: <0.1% during processing

### Secondary Metrics
- **ETag cache hit rate**: >80% for updates
- **Network efficiency**: <100MB total download
- **User engagement**: >70% use regulation search within 7 days
- **Performance degradation**: <5% impact on existing features

### Technical Metrics
- **Test coverage**: >95% for critical paths
- **Swift 6 compliance**: 100% maintained
- **Build time impact**: <0.3 seconds increase
- **Feature flag adoption**: 50% rollout in first month

## Appendix: Consensus Synthesis

### Multi-Model Analysis Summary

**Models Consulted**: Gemini 2.5 Pro, O3, O3-mini, GPT-4.1, O4-mini
**Average Confidence**: 8.2/10
**Consensus Level**: High

### Key Areas of Agreement

1. **Architecture soundness**: Actor-based design validated by all models
2. **Memory constraints**: Streaming and deferral critical for A12/A13
3. **Security requirements**: SHA verification and certificate pinning essential
4. **Launch time protection**: Complete deferral to background required
5. **Testing strategy**: Dependency injection framework necessary

### Key Areas of Enhancement

1. **Streaming JSON parsing**: Critical for memory management (O3)
2. **Pre-bundled seed data**: Improves first-run experience (O4-mini)
3. **Deferred HNSW indexing**: Reduces launch complexity (O3)
4. **CDN alternative**: Future-proofs against GitHub limits (Multiple)
5. **Feature flags**: Enables safe staged rollout (GPT-4.1)

### Implementation Priorities

Based on consensus, the implementation prioritizes:
1. Launch time protection through complete deferral
2. Memory efficiency through streaming and chunking
3. Security through comprehensive validation
4. User experience through progressive disclosure
5. Risk mitigation through feature flags and monitoring

### Alternative Approaches Documented

1. **CDN Mirror Service**: Eliminates GitHub rate limits
2. **Server-Side Processing**: Reduces device load
3. **Hybrid Approach**: Combines local and cloud processing
4. **Progressive Web App**: Alternative architecture

These alternatives are documented for future consideration based on production metrics and user feedback.
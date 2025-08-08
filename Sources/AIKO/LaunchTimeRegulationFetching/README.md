# Launch-Time Regulation Fetching Module

## Purpose

The Launch-Time Regulation Fetching module provides automated download, processing, and embedding of official government regulations from the GSA acquisition.gov repository during app onboarding. This system ensures users have immediate access to comprehensive, semantically searchable regulatory content for intelligent form auto-population and compliance assistance.

## Architecture Notes

### Core Design Principles
- **Swift 6 Strict Concurrency**: All components are actor-based for thread safety
- **Memory-Efficient**: Streaming processing with <300MB peak usage constraint
- **Offline-First**: Complete local operation after initial setup
- **Security-Hardened**: Certificate pinning, data validation, and secure storage
- **Performance-Optimized**: <400ms launch constraint with background processing

### Component Architecture

```
LaunchTimeRegulationFetching/
├── RegulationFetchService.swift        # GitHub API integration
├── BackgroundRegulationProcessor.swift  # Processing pipeline
├── SecureGitHubClient.swift            # Secure networking
├── ObjectBoxSemanticIndex.swift        # Vector database
├── LFM2Service.swift                   # ML embeddings
├── StreamingRegulationChunk.swift      # Memory streaming
├── MemoryPressureManager.swift         # Memory management
├── LaunchTimeConfiguration.swift       # Configuration
├── LaunchTimeRegulationSupportingServices.swift # Supporting services
└── LaunchTimeRegulationTypes.swift     # Type definitions
```

## Public Interfaces

### RegulationFetchService

```swift
public actor RegulationFetchService {
    public init()
    
    /// Fetches regulation manifest using ETag caching for efficiency
    public func fetchRegulationManifest() async throws -> RegulationManifest
    
    /// Downloads individual regulation file with integrity verification
    public func downloadRegulationFile(_ file: RegulationFile) async throws -> Data
    
    /// Validates downloaded data against SHA256 hash
    public func validateDataIntegrity(_ data: Data, expectedHash: String) throws -> Bool
    
    /// Checks API rate limiting status
    public func checkRateLimit() async throws
}
```

### BackgroundRegulationProcessor

```swift
public actor BackgroundRegulationProcessor {
    public init()
    
    /// Processes regulations in background with progress reporting
    public func processRegulationsInBackground(
        manifest: RegulationManifest,
        progressHandler: @escaping (ProcessingProgress) -> Void
    ) async throws
    
    /// Manages memory usage during processing
    public func getMemoryUsage() async -> MemoryUsageInfo
    
    /// Handles processing interruption and resumption
    public func pauseProcessing() async
    public func resumeProcessing() async
}
```

### ObjectBoxSemanticIndex

```swift
public actor ObjectBoxSemanticIndex {
    public init()
    
    /// Stores regulation embedding in vector database
    public func storeEmbedding(_ embedding: RegulationEmbedding) async throws
    
    /// Performs similarity search across stored embeddings
    public func performSimilaritySearch(
        query: [Float],
        topK: Int = 10,
        threshold: Double = 0.7
    ) async throws -> [SearchResult]
    
    /// Gets database statistics
    public func getDatabaseStats() async -> DatabaseStats
}
```

### LFM2Service

```swift
public actor LFM2Service {
    public init()
    
    /// Generates embeddings for regulation text using LFM2 model
    public func generateEmbeddings(for text: String) async throws -> [Float]
    
    /// Validates embedding quality and dimensions
    public func validateEmbedding(_ embedding: [Float]) throws -> Bool
    
    /// Gets model information
    public func getModelInfo() async -> ModelInfo
}
```

## Usage Examples

### Basic Regulation Fetching

```swift
let fetchService = RegulationFetchService()
let processor = BackgroundRegulationProcessor()

// Fetch regulation manifest
let manifest = try await fetchService.fetchRegulationManifest()

// Process regulations in background
await processor.processRegulationsInBackground(manifest: manifest) { progress in
    print("Processing progress: \(progress.percentage)%")
}
```

### Semantic Search

```swift
let vectorDB = ObjectBoxSemanticIndex()
let lfm2 = LFM2Service()

// Generate query embedding
let queryEmbedding = try await lfm2.generateEmbeddings(for: "contract requirements")

// Search for similar regulations
let results = try await vectorDB.performSimilaritySearch(
    query: queryEmbedding,
    topK: 5,
    threshold: 0.75
)
```

### Memory Management

```swift
let memoryManager = MemoryPressureManager()

// Monitor memory during processing
await memoryManager.startMonitoring { pressure in
    switch pressure {
    case .warning:
        // Reduce processing batch size
        break
    case .critical:
        // Pause processing temporarily
        await processor.pauseProcessing()
    case .normal:
        // Resume normal processing
        await processor.resumeProcessing()
    }
}
```

## Error Handling

The module provides comprehensive error handling with specific error types:

### LaunchTimeRegulationError

```swift
public enum LaunchTimeRegulationError: Error {
    case networkError(underlying: Error)
    case rateLimit(retryAfter: TimeInterval)
    case invalidData(reason: String)
    case memoryPressure(level: MemoryPressureLevel)
    case processingInterrupted(resumeToken: String)
    case validationFailed(hash: String)
    case configurationError(key: String)
}
```

### Error Recovery Patterns

```swift
do {
    let manifest = try await fetchService.fetchRegulationManifest()
} catch LaunchTimeRegulationError.rateLimit(let retryAfter) {
    // Wait and retry
    try await Task.sleep(for: .seconds(retryAfter))
    // Retry operation
} catch LaunchTimeRegulationError.memoryPressure(let level) {
    // Reduce processing intensity
    await processor.adaptToMemoryPressure(level)
}
```

## Extension/Customization Hooks

### Custom Processing Strategies

```swift
protocol RegulationProcessingStrategy {
    func processRegulation(_ regulation: RegulationFile) async throws -> ProcessedRegulation
    func shouldSkipProcessing(_ regulation: RegulationFile) -> Bool
}

// Custom strategy implementation
struct HighPriorityProcessingStrategy: RegulationProcessingStrategy {
    func processRegulation(_ regulation: RegulationFile) async throws -> ProcessedRegulation {
        // Custom processing logic
    }
    
    func shouldSkipProcessing(_ regulation: RegulationFile) -> Bool {
        // Custom filtering logic
    }
}
```

### Configuration Customization

```swift
struct LaunchTimeRegulationConfig {
    var maxConcurrentDownloads: Int = 5
    var memoryPressureThreshold: Double = 0.8
    var retryAttempts: Int = 3
    var batchSize: Int = 100
    var enableEtagCaching: Bool = true
    var enableProgressReporting: Bool = true
}

// Apply custom configuration
let config = LaunchTimeRegulationConfig(
    maxConcurrentDownloads: 3,
    memoryPressureThreshold: 0.7
)
let processor = BackgroundRegulationProcessor(configuration: config)
```

### Progress Monitoring Hooks

```swift
protocol ProgressReporting {
    func reportProgress(_ progress: ProcessingProgress)
    func reportError(_ error: Error)
    func reportCompletion(stats: CompletionStats)
}

// Custom progress reporter
struct DetailedProgressReporter: ProgressReporting {
    func reportProgress(_ progress: ProcessingProgress) {
        print("Files processed: \(progress.filesProcessed)/\(progress.totalFiles)")
        print("Memory usage: \(progress.memoryUsage)MB")
        print("ETA: \(progress.estimatedTimeRemaining)")
    }
}
```

## Performance Characteristics

### Memory Usage
- **Peak Usage**: <300MB during regulation processing
- **Streaming Processing**: Processes large files without loading entirely in memory
- **Adaptive Batching**: Adjusts batch size based on available memory

### Processing Speed
- **Launch Constraint**: <400ms launch time maintained
- **Background Processing**: 1000+ regulations processed in background
- **Concurrent Downloads**: Up to 5 simultaneous downloads with rate limiting

### Network Efficiency
- **ETag Caching**: Prevents unnecessary re-downloads
- **Delta Updates**: Only downloads changed regulations
- **Compression**: Supports gzip compression for downloads
- **Rate Limiting**: Respects GitHub API limits (60 req/hr unauthenticated)

### Storage Optimization
- **Vector Compression**: Efficient storage of embeddings
- **Deduplication**: Prevents duplicate regulation storage
- **Incremental Updates**: Supports partial database updates

## Integration Points

### With AIKO Core Systems
- **OnboardingView**: Progress display during setup
- **ObjectBox Vector Database**: Regulation storage and search
- **ComplianceGuardian**: Real-time compliance validation
- **Document Auto-Population**: Intelligent form completion

### With External Services
- **GitHub API**: GSA regulation repository access
- **LFM2 Core ML**: On-device embedding generation
- **iOS BackgroundTasks**: Background processing support
- **Network Framework**: Connection monitoring

## Testing Strategy

The module includes comprehensive test coverage:
- **Actor Concurrency Tests**: Thread safety validation
- **Performance Tests**: Memory and speed benchmarks
- **Security Tests**: Certificate pinning and data validation
- **Edge Case Tests**: Network failures, memory pressure scenarios
- **Integration Tests**: End-to-end workflow validation

### Test Categories
- **Unit Tests**: Individual component functionality
- **Integration Tests**: Component interaction validation
- **Performance Tests**: Benchmarking under constraints
- **Security Tests**: Vulnerability assessment
- **Chaos Tests**: Failure scenario handling

## Production Deployment

### Requirements
- **iOS**: 17.0+ with Swift 6 runtime
- **macOS**: 14.0+ with Swift 6 runtime
- **Memory**: 300MB+ available for initial processing
- **Network**: Initial internet connection for regulation download
- **Storage**: ~150MB for regulation database

### Configuration
- Configure GitHub API credentials (optional, for higher rate limits)
- Set memory pressure thresholds based on device capabilities
- Enable background processing permissions
- Configure vector database backend (mock or ObjectBox)

### Monitoring
- Memory usage during processing
- Network request success/failure rates
- Processing time and throughput
- Vector database performance metrics

---

**Module Version**: 1.0  
**Last Updated**: August 7, 2025  
**TDD Status**: Production Ready ✅  
**Swift Version**: 6.0  
**Quality Assurance**: Zero SwiftLint violations, comprehensive test coverage
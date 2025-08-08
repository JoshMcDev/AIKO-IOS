# Testing Rubric: Launch-Time Regulation Fetching (DRAFT)

## Document Metadata
- Task: Implement Launch-Time Regulation Fetching
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-guardian
- Status: Draft - Awaiting zen:consensus validation

## Executive Summary

This testing rubric defines comprehensive Test-Driven Development (TDD) requirements for implementing Launch-Time Regulation Fetching in the AIKO iOS Government Contracting App. The feature enables automatic download, processing, and vector database population of official government regulations while maintaining strict performance constraints (<400ms launch time) through deferred background processing.

**Key Testing Priorities**:
1. Launch performance protection (<400ms constraint)
2. Memory management (<300MB peak usage)
3. Background processing reliability (stream processing)
4. Security validation (SHA-256, certificate pinning)
5. Error recovery and resilience patterns

## Test Categories

### 1. Unit Tests

#### Core Service Layer Tests
- **RegulationFetchService**: GitHub API integration, ETag caching, rate limiting
- **BackgroundRegulationProcessor**: Deferred processing, state management, checkpointing
- **SecureGitHubClient**: Certificate pinning, SHA-256 verification, integrity checks
- **StreamingRegulationChunk**: JSON parsing, incremental processing, memory efficiency
- **DependencyContainer**: Protocol conformance, mock/production wiring

#### Data Model Tests
- **RegulationEmbedding**: ObjectBox entity persistence, vector storage
- **ProcessingState**: State transitions, error conditions, persistence
- **FeatureFlags**: Configuration management, rollout percentages
- **StreamingModels**: Memory management, buffer handling

#### Actor Concurrency Tests
- **Swift 6 Compliance**: Actor isolation, Sendable conformance, data race prevention
- **Background Tasks**: BGProcessingTask integration, task coordination
- **Memory Monitoring**: Pressure detection, adaptive behavior

### 2. Integration Tests

#### GitHub API Integration
- **Authentication**: Rate limiting, backoff strategies, ETag optimization
- **Data Integrity**: Complete regulation manifest fetching, file validation
- **Network Resilience**: Connection interruption, retry mechanisms
- **Security**: Certificate pinning validation, MITM protection

#### ObjectBox Database Integration
- **Vector Storage**: RegulationEmbedding persistence, HNSW index building
- **Lazy Loading**: Deferred index creation, first-search triggers
- **Data Migration**: Schema updates, version compatibility
- **Performance**: Sub-second similarity search, memory efficiency

#### LFM2 Core ML Integration
- **Embedding Generation**: 768-dimensional vector creation, batch processing
- **Memory Management**: Tensor lifecycle, autoreleasepool usage
- **Performance**: <2s per 512-token chunk, <800MB peak memory
- **Accuracy**: >95% semantic similarity validation

#### Background Processing Integration
- **Launch Impact**: <400ms launch time with deferred setup
- **State Persistence**: Resume across app launches, checkpoint recovery
- **Progress Tracking**: 500ms UI updates, accurate ETA calculation
- **Error Recovery**: Network interruption, storage exhaustion, memory pressure

### 3. Security Tests

#### Data Integrity and Authenticity
- **SHA-256 Verification**: File corruption detection, tamper evidence
- **Certificate Pinning**: GitHub API connection validation, MITM prevention
- **Signature Validation**: Regulation authenticity, supply chain security
- **Secure Transport**: HTTPS enforcement, TLS validation

#### Privacy Protection
- **No PII Transmission**: Network monitoring, data isolation validation
- **Local Processing**: On-device embedding generation, zero external analytics
- **Keychain Security**: Secure credential storage, biometric protection
- **Data Retention**: User control, secure deletion patterns

### 4. Performance Tests

#### Launch Time Performance
- **Critical Constraint**: <400ms app launch to interactive UI
- **Background Initialization**: Non-blocking regulation setup trigger
- **Memory Footprint**: Launch process memory <50MB additional
- **Threading**: Main thread blocking prevention, async initialization

#### Processing Performance
- **Complete Setup**: <5 minutes full regulation database on WiFi
- **Memory Efficiency**: <300MB peak during processing (A12+ devices)
- **Streaming Performance**: Incremental JSON parsing without memory bloat
- **Batch Processing**: Optimal chunk sizes for memory/performance balance

#### Search Performance
- **Similarity Search**: <1s response for regulation queries
- **Index Building**: Lazy HNSW construction on first search
- **Memory Usage**: Efficient vector storage, cleanup after search
- **Concurrent Access**: Thread-safe search operations

### 5. Edge Cases and Error Scenarios

#### Network and Connectivity
- **Connection Interruption**: Resume from checkpoint, progress persistence
- **Rate Limiting**: Exponential backoff, ETag optimization
- **Cellular Data**: User warnings, download deferral options
- **Network Quality**: Adaptive strategies, degraded mode operation

#### Device Constraints
- **Memory Pressure**: Graceful degradation, chunk size adaptation
- **Storage Exhaustion**: Pre-flight checks, cleanup options
- **Older Devices**: A12/A13 specific constraints, performance profiling
- **Background Limits**: iOS task limits, Background App Refresh dependency

#### Data Integrity Issues
- **Corruption Detection**: SHA mismatch, database corruption recovery
- **Malformed Data**: Invalid JSON, parsing error recovery
- **Repository Changes**: GitHub structure changes, schema migration
- **Incomplete Downloads**: Partial file recovery, validation failure handling

#### User Experience Edge Cases
- **App Termination**: Mid-setup interruption, state recovery
- **User Cancellation**: Clean cancellation, partial data cleanup
- **Skip and Defer**: Later reminder, progressive setup options
- **Onboarding Flow**: Integration with existing onboarding, skip options

### 6. User Interface Tests

#### Onboarding Integration
- **Progressive Disclosure**: Minimal setup prompt, detailed progress option
- **Network Quality**: Connection type indication, data usage warnings
- **User Choice**: Skip/defer/download options, preference persistence
- **Accessibility**: VoiceOver support, keyboard navigation

#### Progress Tracking
- **Real-time Updates**: 500ms progress intervals, smooth UI updates
- **Detailed Information**: File counts, ETA calculations, current phase
- **Error Presentation**: User-friendly error messages, recovery options
- **State Persistence**: Progress retention across app sessions

## Success Criteria

### Functional Success Criteria
1. **Complete Integration**: All 1000+ GSA regulations successfully downloaded and indexed
2. **Search Functionality**: Semantic similarity search operational with <1s response
3. **Launch Performance**: 100% compliance with <400ms launch time constraint
4. **Error Recovery**: >95% success rate recovering from network interruptions
5. **Memory Compliance**: Never exceed 300MB peak memory usage
6. **Security Validation**: 100% file integrity and authenticity verification

### Quality Assurance Criteria
1. **Test Coverage**: >95% code coverage for all regulation processing components
2. **Swift 6 Compliance**: 100% strict concurrency compliance maintained
3. **SwiftLint Compliance**: Zero violations introduced by new components
4. **Build Performance**: <3s build time with regulation features
5. **Cross-Device Testing**: Validation across A12-A17 device generations

### User Experience Criteria
1. **Setup Completion**: >95% users successfully complete regulation setup
2. **User Control**: Clear progress indication with pause/resume/cancel options
3. **Accessibility**: Full VoiceOver navigation support
4. **Performance Impact**: <5% degradation to existing app features
5. **Data Efficiency**: Smart defaults for cellular vs WiFi usage

## Testing Infrastructure Requirements

### Mock Strategy
- **Dependency Injection**: Complete DI framework with TestDependencyContainer
- **Network Mocking**: GitHub API response simulation, rate limit testing
- **ObjectBox Mocking**: In-memory database testing, performance simulation
- **LFM2 Mocking**: Deterministic embedding generation, memory profiling

### Test Data
- **Regulation Samples**: Representative HTML files, various sizes/structures
- **Manifest Data**: GitHub API response samples, ETag scenarios
- **Error Conditions**: Network failures, malformed data, rate limits
- **Performance Baselines**: Memory usage patterns, timing benchmarks

### Test Environments
- **Device Matrix**: A12, A13, A14, A15, A16, A17 processors
- **Network Conditions**: WiFi, LTE, 3G, offline scenarios
- **iOS Versions**: 17.0, 17.1, 17.2, 17.3, 17.4+ compatibility
- **Memory Configurations**: 2GB, 4GB, 6GB, 8GB device variants

## Code Review Integration

### Critical Review Points
- **Actor Isolation**: Swift 6 concurrency compliance, data race prevention
- **Memory Management**: Tensor lifecycle, autoreleasepool usage
- **Error Handling**: Comprehensive error coverage, graceful degradation
- **Security Patterns**: SHA verification, certificate pinning implementation
- **Performance Optimization**: Launch time impact, background efficiency

### Zero-Tolerance Issues
- **Force Unwrapping**: No force unwraps in regulation processing
- **Main Thread Blocking**: Background work must not block UI
- **Memory Leaks**: Complete lifecycle management for Core ML tensors
- **Security Vulnerabilities**: Certificate validation, integrity verification
- **Launch Time Violation**: Any delay to <400ms launch requirement

## Implementation Timeline

### Phase 1: Foundation Testing (Days 1-3)
- Unit tests for core services and models
- Dependency injection framework validation
- Security layer testing (SHA-256, certificate pinning)
- Memory monitoring infrastructure

### Phase 2: Integration Testing (Days 4-7)
- GitHub API integration with mocking
- ObjectBox database integration testing
- LFM2 Core ML embedding generation tests
- Background processing validation

### Phase 3: Performance Testing (Days 8-10)
- Launch time performance validation
- Memory usage profiling across device types
- Streaming performance optimization
- Error recovery scenario testing

### Phase 4: End-to-End Testing (Days 11-14)
- Complete regulation setup workflow
- Cross-device compatibility validation
- User experience testing with accessibility
- Production readiness validation

<!-- /tdd guardian draft complete -->
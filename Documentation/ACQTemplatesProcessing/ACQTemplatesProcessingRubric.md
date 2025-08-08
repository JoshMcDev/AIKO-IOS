# Testing Rubric: ACQ Templates Processing

## Document Metadata
- Task: Implement Launch-Time ACQ Templates Processing and Embedding
- Version: Enhanced v1.0
- Date: 2025-08-08
- Author: tdd-guardian
- Consensus Method: Best practices synthesis applied (VanillaIce connectivity issues encountered)
- Research Integration: Based on Perplexity research findings for testing strategies

## Consensus Enhancement Summary
This testing rubric has been enhanced through best practices synthesis addressing critical testing gaps identified. Key enhancements include: security testing expansion, long-term stability validation, cross-platform compatibility verification, production load testing scenarios, and comprehensive monitoring integration.

## Executive Summary

This testing rubric establishes comprehensive test specifications for the ACQ Templates Processing implementation, focusing on the memory-constrained architecture with hybrid search capabilities. The system processes 256MB of acquisition templates using strict 50MB memory limits, implementing BM25 + vector reranking, sharded storage, and actor-based concurrency.

Critical testing areas include memory management validation (<50MB peak usage), search performance benchmarking (<10ms P50 latency), actor isolation verification, data integrity validation, integration testing with existing GraphRAG infrastructure, and enhanced security validation for government data handling.

## Test Categories

### 1. Memory Management Tests

#### Memory Permit System Tests
```swift
class MemoryPermitSystemTests: XCTestCase {
    func testStrictMemoryLimit() async throws
    func testMemoryPermitAcquisitionAndRelease() async throws
    func testMemoryPermitWaitingQueue() async throws
    func testMemoryOverrunPrevention() async throws
    func testMemoryPermitTimeouts() async throws
    func testConcurrentPermitRequests() async throws
    func testEmergencyMemoryRelease() async throws
}
```

**Critical Test Cases:**
1. **Strict 50MB Limit Enforcement**
   - Process 256MB dataset with continuous memory monitoring using Instruments
   - Assert peak memory never exceeds 50MB during processing
   - Verify memory pressure triggers proper backpressure mechanisms
   - Test emergency memory release functionality under extreme conditions
   - Validate memory accounting accuracy across all components

2. **Memory Permit Queue Management**
   - Test permit acquisition with multiple concurrent requests (100+ simultaneous)
   - Verify FIFO ordering for waiting permits with timeout handling
   - Test permit timeout scenarios and recovery mechanisms
   - Validate memory accounting accuracy across concurrent operations
   - Test permit system under thread contention scenarios

3. **Memory Pressure Response**
   - Trigger artificial memory pressure during processing using memory mapping
   - Verify graceful degradation (pause processing, reduce concurrency)
   - Test memory cleanup and garbage collection effectiveness
   - Validate recovery after memory pressure relief with resumption capability
   - Test memory fragmentation handling and defragmentation

#### Chunk Processing Memory Tests
```swift
class ChunkProcessingMemoryTests: XCTestCase {
    func testChunkSizeCompliance() async throws
    func testMemoryMappedStorageEfficiency() async throws
    func testStreamingProcessingMemoryBounds() async throws
    func testLargeDocumentMemoryUsage() async throws
    func testChunkOverlapMemoryManagement() async throws
    func testConcurrentChunkProcessingLimits() async throws
}
```

**Memory Constraint Validation:**
- 2-4MB chunk processing with real-time memory tracking
- Streaming text extraction without full document loading
- Memory-mapped file storage validation with mmap efficiency
- Peak memory measurement during full 256MB processing
- Chunk overlap memory efficiency (50-token overlap)
- Concurrent chunk processing memory limits (single chunk in flight)

### 2. Performance and Latency Tests

#### Search Performance Tests
```swift
class HybridSearchPerformanceTests: XCTestCase {
    func testSearchLatencyP50() async throws
    func testSearchLatencyP95() async throws
    func testSearchLatencyP99() async throws
    func testLexicalPrefilterSpeed() async throws
    func testVectorRerankingLatency() async throws
    func testConcurrentSearchPerformance() async throws
    func testColdVsWarmSearchPerformance() async throws
    func testLargeResultSetHandling() async throws
}
```

**Performance Targets:**
- Search P50 latency: <10ms (primary target)
- Search P95 latency: <20ms (secondary target)
- Search P99 latency: <50ms (stress target)  
- Lexical prefilter: <2ms (BM25 component)
- Vector reranking: <8ms (exact cosine similarity)
- Memory usage during search: <15MB additional peak
- Concurrent user capacity: 10+ simultaneous searches

**Benchmark Scenarios:**
1. **Cold Search Performance** (empty caches, no warm shards)
2. **Warm Search Performance** (loaded shards in memory)
3. **Concurrent User Simulation** (10+ simultaneous searches with latency tracking)
4. **Large Result Set Handling** (1000+ candidate reranking performance)
5. **Category-Specific Search** (single shard vs multi-shard queries)
6. **Cross-Platform Performance** (iOS vs macOS latency comparison)

#### Processing Performance Tests
```swift
class TemplateProcessingPerformanceTests: XCTestCase {
    func testEmbeddingGenerationSpeed() async throws
    func testBatchProcessingThroughput() async throws
    func testIndexingPerformance() async throws
    func testStartupLatency() async throws
    func testDimensionReductionPerformance() async throws
    func testSIMDOptimizationValidation() async throws
    func testCrossPlatformPerformanceConsistency() async throws
}
```

**Processing Benchmarks:**
- 384-dimensional embedding generation: <2s per 512-token chunk
- Template categorization: <100ms per template with >95% accuracy
- ObjectBox storage performance: <50ms per embedding write
- Full 256MB processing: <3 minutes total with progress tracking
- Dimension reduction (768→384): <10ms per embedding
- SIMD cosine similarity: <1ms per comparison on ARM64
- Startup to searchable: <3 minutes (user experience requirement)

### 3. Actor Concurrency and Thread Safety Tests

#### Swift 6 Concurrency Tests
```swift
@MainActor
class ActorConcurrencyTests: XCTestCase {
    func testMemoryConstrainedProcessorIsolation() async throws
    func testHybridSearchServiceMainActorCompliance() async throws
    func testShardedIndexActorSafety() async throws
    func testCrossActorDataSafety() async throws
    func testConcurrentPermitSystemAccess() async throws
    func testSendableComplianceValidation() async throws
    func testTaskIsolationBoundaries() async throws
}
```

**Concurrency Validation:**
1. **Actor Isolation Verification**
   - MemoryConstrainedTemplateProcessor actor boundaries with data isolation
   - HybridSearchService @MainActor compliance for UI updates
   - ShardedTemplateIndex actor safety with concurrent access
   - MemoryPermitSystem actor isolation with queue management

2. **Data Race Prevention**
   - Sendable conformance for all data types (TemplateMetadata, ProcessedTemplate, etc.)
   - Safe cross-actor data transfer with proper serialization
   - Task isolation boundaries with AsyncSequence handling
   - AsyncChannel/AsyncStream safety in streaming scenarios

3. **Deadlock Prevention**
   - Memory permit acquisition ordering to prevent deadlocks
   - Cross-actor dependency cycle detection and prevention
   - Resource contention scenarios with timeout mechanisms
   - Proper async/await usage throughout actor interactions

### 4. Data Integrity and Quality Tests

#### Template Processing Accuracy Tests
```swift
class TemplateProcessingAccuracyTests: XCTestCase {
    func testCategoryDetectionAccuracy() async throws
    func testChunkingQualityValidation() async throws
    func testMetadataExtractionCompleteness() async throws
    func testContentPreservationIntegrity() async throws
    func testEmbeddingConsistency() async throws
    func testSemanticBoundaryPreservation() async throws
    func testOverlapConsistencyValidation() async throws
}
```

**Quality Validation:**
1. **Template Categorization Accuracy** (>95% target)
   - Contract, SOW, Form, Clause, Guide classification with pattern matching
   - Edge case handling (ambiguous documents, mixed categories)
   - False positive/negative analysis with confusion matrix
   - Pattern matching robustness across document formats (PDF, DOCX, MD)

2. **Chunking Quality Assessment**
   - Semantic boundary preservation using character-based splitters
   - Overlap consistency (50 tokens) with content verification
   - Content completeness validation (zero data loss)
   - Chunk size compliance (400 tokens ±10% variance allowed)
   - Paragraph/section boundary respect in chunking

3. **Embedding Quality Validation**
   - Dimension reduction accuracy (768→384) with semantic preservation
   - L2 normalization verification for consistent vector space
   - Semantic similarity preservation before/after reduction
   - Embedding stability across multiple runs (consistency test)
   - Domain-specific optimization validation for government content

#### Search Result Quality Tests
```swift
class SearchResultQualityTests: XCTestCase {
    func testSearchRelevanceNDCG() async throws
    func testCategoryFilterAccuracy() async throws
    func testCrossReferenceIntegrity() async throws
    func testSearchResultRanking() async throws
    func testHybridSearchQualityComparison() async throws
    func testSemanticSimilarityAccuracy() async throws
}
```

**Search Quality Metrics:**
- NDCG@10 ≥ 0.8 for template search relevance (primary quality metric)
- Category filtering: 100% accuracy with proper boundary handling
- Cross-reference validation with existing regulations database
- Ranking consistency across multiple runs with same query
- Hybrid search quality vs pure vector/lexical approaches
- Semantic similarity accuracy with ground truth validation

### 5. Integration Tests

#### GraphRAG Infrastructure Integration Tests
```swift
class GraphRAGIntegrationTests: XCTestCase {
    func testLFM2ServiceIntegration() async throws
    func testObjectBoxSemanticIndexIntegration() async throws
    func testUnifiedSearchServiceIntegration() async throws
    func testRegulationProcessorCoordination() async throws
    func testFormAutoPopulationIntegration() async throws
    func testBackgroundProcessingCoordination() async throws
    func testCrossNamespaceSearchValidation() async throws
}
```

**Integration Scenarios:**
1. **LFM2Service Coordination**
   - Dimension reduction integration with existing regulation processing
   - Batch embedding generation coordination
   - Error handling coordination and failure propagation
   - Memory management alignment between services

2. **ObjectBox Vector Database**
   - Template embedding storage in separate namespace
   - Memory-mapped file integration with existing regulation storage
   - Multi-namespace coordination (regulations + templates)
   - Index optimization validation without conflicts

3. **Unified Search Integration**
   - Cross-domain search capability (templates + regulations)
   - Result ranking across namespaces with relevance scoring
   - Filter coordination and category alignment
   - Performance impact assessment on existing regulation search

#### End-to-End Workflow Tests  
```swift
class EndToEndWorkflowTests: XCTestCase {
    func testCompleteTemplateProcessingPipeline() async throws
    func testTemplateSearchToFormPopulation() async throws
    func testErrorRecoveryWorkflows() async throws
    func testProgressTrackingAccuracy() async throws
    func testCrossDeviceSyncValidation() async throws
    func testOfflineCapabilityValidation() async throws
}
```

**Complete Workflows:**
- Template discovery → processing → embedding → storage → search (full pipeline)
- Search query → hybrid results → form population suggestions → user acceptance
- Error scenarios → recovery → continuation with checkpoint restoration
- Progress tracking → user feedback → completion notification
- Cross-device synchronization with iCloud integration
- Offline capability with local processing validation

### 6. Security and Compliance Tests

#### Government Data Security Tests
```swift
class SecurityComplianceTests: XCTestCase {
    func testGovernmentDataEncryption() async throws
    func testAccessControlValidation() async throws
    func testDataLeakagePrevention() async throws
    func testSecureDataTransmission() async throws
    func testComplianceAuditTrail() async throws
    func testPIIDetectionAndRedaction() async throws
    func testSecureMemoryManagement() async throws
}
```

**Security Validation:**
1. **Government Template Security**
   - Encryption-at-rest for stored embeddings using iOS file protection
   - iOS file protection mechanism validation (Complete/Protected)
   - Secure keychain integration for sensitive metadata storage
   - Access control for template retrieval with user authentication
   - Certificate pinning for any external API connections

2. **Data Privacy Protection**
   - PII detection and redaction in template content processing
   - Secure deletion of temporary processing files with overwriting
   - Memory scrubbing after sensitive data processing
   - Audit trail generation for compliance and forensic analysis
   - Data retention policy enforcement with automatic cleanup

3. **Network Security**
   - Certificate pinning for external connections (if any)
   - Secure API authentication with token rotation
   - Data transmission encryption with TLS 1.3+
   - Rate limiting and abuse prevention mechanisms
   - Intrusion detection for unusual access patterns

### 7. Long-Term Stability Tests

#### Extended Operation Tests
```swift
class LongTermStabilityTests: XCTestCase {
    func testExtendedProcessingMemoryLeaks() async throws
    func testLongRunningSearchPerformance() async throws
    func testIndexGrowthValidation() async throws
    func testCacheEfficiencyOverTime() async throws
    func testBackgroundProcessingStability() async throws
    func test24HourContinuousOperation() async throws
    func testMemoryFragmentationHandling() async throws
}
```

**Stability Validation:**
- 24-hour continuous processing without memory leaks using Instruments
- Performance degradation monitoring over extended use (latency drift)
- Index size growth patterns and optimization effectiveness
- Cache hit ratio maintenance over time with LRU validation
- Background processing impact on user experience during extended operation
- Memory fragmentation handling and automatic defragmentation
- Resource cleanup validation after long-running operations

### 8. Error Handling and Recovery Tests

#### Failure Scenario Tests
```swift
class ErrorHandlingTests: XCTestCase {
    func testCorruptedTemplateHandling() async throws
    func testNetworkFailureRecovery() async throws
    func testMemoryPressureRecovery() async throws
    func testStorageFailureHandling() async throws
    func testPartialProcessingRecovery() async throws
    func testConcurrentFailureRecovery() async throws
    func testDiskSpaceExhaustionHandling() async throws
    func testProcessingTimeoutRecovery() async throws
}
```

**Error Recovery Validation:**
1. **Corrupted Data Handling**
   - Malformed PDF/DOCX files with proper error reporting
   - Invalid character encoding handling with fallback mechanisms
   - Incomplete template files with partial processing capability
   - Checksum validation failures with retry mechanisms

2. **Resource Exhaustion Scenarios**
   - Memory pressure during processing with graceful degradation
   - Disk space limitations with cleanup and user notification
   - Processing timeouts with checkpoint save/resume
   - Rate limiting responses with exponential backoff

3. **Recovery Mechanisms**
   - Checkpoint save/restore functionality with integrity validation
   - Partial processing continuation from last successful state
   - Graceful degradation modes (lexical-only search fallback)
   - User notification systems with actionable recovery options

## Success Criteria

### Performance Requirements
- **Memory Constraint**: Peak usage <50MB during 256MB processing (strict enforcement)
- **Search Latency**: P50 <10ms, P95 <20ms, P99 <50ms (user experience targets)
- **Processing Speed**: Complete 256MB dataset in <3 minutes (productivity requirement)
- **Startup Impact**: Templates searchable within 3 minutes of app launch
- **Concurrent Users**: Support 10+ simultaneous searches without degradation
- **Cross-Platform**: Consistent performance on iOS and macOS

### Quality Standards  
- **Build Status**: Zero errors, zero warnings with Swift 6 strict concurrency
- **SwiftLint Compliance**: Zero violations across all components
- **Test Coverage**: >90% for memory-critical paths, >85% overall
- **Search Quality**: NDCG@10 ≥ 0.8 for template relevance
- **Security Compliance**: Zero security vulnerabilities, complete data protection
- **Long-Term Stability**: Zero memory leaks over 24-hour continuous operation

### Integration Requirements
- **Seamless GraphRAG Integration**: No disruption to existing regulation search
- **Cross-Platform Support**: iOS/macOS compatibility with native experience
- **User Experience**: Intuitive search with clear memory usage indication
- **Error Resilience**: Graceful degradation under all failure scenarios
- **Security Compliance**: Government data protection standards met
- **Performance Consistency**: Stable latency across extended usage

## Code Review Integration

This testing rubric integrates with comprehensive code review processes to ensure production-ready quality:

### Review Focus Areas
1. **Memory Safety Patterns**: Strict permit system compliance
2. **Actor Isolation**: Swift 6 concurrency correctness
3. **Performance Critical Paths**: Search latency optimization
4. **Error Handling Completeness**: All failure modes covered
5. **Integration Boundaries**: Clean service interfaces
6. **Security Compliance**: Government data protection standards
7. **Long-Term Stability**: Memory leak prevention and performance sustainability

### Quality Gates
- Zero tolerance for memory constraint violations
- All search performance targets must be met consistently
- Complete actor isolation validation with Swift 6 compliance
- Comprehensive error scenario coverage with recovery validation
- Full integration test suite passing with existing GraphRAG infrastructure
- Security compliance validation for government data handling
- Long-term stability validation with extended operation testing

## Implementation Timeline

### Phase 1: Memory Infrastructure Tests (Week 1)
- Memory permit system validation with concurrent access testing
- Chunk processing memory bounds with real-time monitoring
- Performance baseline establishment with Instruments profiling

### Phase 2: Search Performance Tests (Week 2)  
- Hybrid search latency benchmarking with percentile analysis
- BM25 prefilter validation with 2ms target
- Vector reranking optimization with SIMD validation

### Phase 3: Integration Tests (Week 3)
- GraphRAG component coordination with existing services
- End-to-end workflow validation with error scenarios
- Cross-platform compatibility testing (iOS/macOS)

### Phase 4: Security and Quality Assurance (Week 4)
- Government data security validation with encryption testing
- Long-term stability testing with 24-hour continuous operation
- Error handling comprehensive testing with recovery validation

### Phase 5: Final Validation (Week 5)
- Full system integration testing with production load simulation
- User acceptance criteria validation with real-world scenarios
- Production deployment preparation with comprehensive documentation

## Research-Enhanced Testing Strategies

Based on research findings from `researchPerplexity_ACQTemplatesProcessing.md`:

### Chunking Strategy Validation
- **Character-based splitters** for semantic boundary preservation testing
- **Overlap consistency** testing for context retention across chunks
- **Chunk size optimization** balancing memory constraints vs semantic coherence
- **Streaming architecture validation** for memory efficiency during processing

### Performance Testing Patterns
- **Streaming architecture validation** for memory efficiency
- **Batch processing optimization** for embedding generation throughput
- **Incremental processing verification** for large document handling
- **Memory profiling** with Instruments for iOS-specific optimization

### Security Testing Integration
- **Government document security** handling validation
- **iOS file protection** mechanism testing
- **Encryption-at-rest** for stored embeddings
- **Access control** for template retrieval
- **PII detection and redaction** in template content
- **Secure memory management** with scrubbing
- **Compliance audit trail** generation and validation
- **Network security** with certificate pinning

## Appendix: Testing Infrastructure

### Mock Strategy
- **LFM2Service Mocking**: Deterministic embedding generation for consistent testing
- **ObjectBox Simulation**: Memory-backed testing without persistent storage interference
- **Network Mocking**: Controlled failure scenario simulation with various error conditions
- **Memory Pressure Simulation**: Artificial memory constraint testing with controllable limits

### Testing Environment Setup
- **iOS Simulator**: Memory profiling with Instruments for development testing
- **Physical Device Testing**: iPhone 12/13 memory constraint validation on target hardware
- **Continuous Integration**: Automated test suite execution with GitHub Actions
- **Performance Monitoring**: Real-time metric collection during tests with alerting
- **Cross-Platform Validation**: macOS testing for unified codebase verification

### Monitoring and Metrics
- **Real-time Memory Tracking**: Continuous monitoring during test execution
- **Performance Dashboards**: Latency and throughput metrics visualization
- **Error Rate Tracking**: Failure scenario frequency and recovery success rates
- **Quality Metrics**: NDCG scores and search relevance tracking over time
- **Security Audit Logs**: Comprehensive logging for compliance and forensic analysis

This comprehensive testing rubric ensures the ACQ Templates Processing implementation meets all critical requirements while maintaining the highest quality standards for production deployment with government data handling capabilities.

<!-- /tdd complete -->
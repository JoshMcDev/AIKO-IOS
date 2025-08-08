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
}
```

**Critical Test Cases:**
1. **Strict 50MB Limit Enforcement**
   - Process 256MB dataset with continuous memory monitoring
   - Assert peak memory never exceeds 50MB
   - Verify memory pressure triggers proper backpressure
   - Test emergency memory release functionality

2. **Memory Permit Queue Management**
   - Test permit acquisition with multiple concurrent requests
   - Verify FIFO ordering for waiting permits
   - Test permit timeout scenarios
   - Validate memory accounting accuracy

3. **Memory Pressure Response**
   - Trigger artificial memory pressure during processing
   - Verify graceful degradation (pause processing)
   - Test memory cleanup and garbage collection
   - Validate recovery after memory pressure relief

#### Chunk Processing Memory Tests
```swift
class ChunkProcessingMemoryTests: XCTestCase {
    func testChunkSizeCompliance() async throws
    func testMemoryMappedStorageEfficiency() async throws
    func testStreamingProcessingMemoryBounds() async throws
    func testLargeDocumentMemoryUsage() async throws
}
```

**Memory Constraint Validation:**
- 2-4MB chunk processing with memory tracking
- Streaming text extraction without full document loading
- Memory-mapped file storage validation
- Peak memory measurement during 256MB processing

### 2. Performance and Latency Tests

#### Search Performance Tests
```swift
class HybridSearchPerformanceTests: XCTestCase {
    func testSearchLatencyP50() async throws
    func testSearchLatencyP95() async throws
    func testLexicalPrefilterSpeed() async throws
    func testVectorRerankingLatency() async throws
    func testConcurrentSearchPerformance() async throws
}
```

**Performance Targets:**
- Search P50 latency: <10ms
- Search P95 latency: <20ms  
- Lexical prefilter: <2ms
- Vector reranking: <8ms
- Memory usage during search: <15MB additional

**Benchmark Scenarios:**
1. **Cold Search Performance** (empty caches)
2. **Warm Search Performance** (loaded shards)
3. **Concurrent User Simulation** (10+ simultaneous searches)
4. **Large Result Set Handling** (1000+ candidate reranking)

#### Processing Performance Tests
```swift
class TemplateProcessingPerformanceTests: XCTestCase {
    func testEmbeddingGenerationSpeed() async throws
    func testBatchProcessingThroughput() async throws
    func testIndexingPerformance() async throws
    func testStartupLatency() async throws
}
```

**Processing Benchmarks:**
- 384-dimensional embedding generation: <2s per 512-token chunk
- Template categorization: <100ms per template
- ObjectBox storage: <50ms per embedding
- Full 256MB processing: <3 minutes total

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
}
```

**Concurrency Validation:**
1. **Actor Isolation Verification**
   - MemoryConstrainedTemplateProcessor actor boundaries
   - HybridSearchService @MainActor compliance
   - ShardedTemplateIndex actor safety
   - MemoryPermitSystem concurrent access

2. **Data Race Prevention**
   - Sendable conformance for all data types
   - Safe cross-actor data transfer
   - Proper Task isolation boundaries
   - AsyncSequence/AsyncChannel safety

3. **Deadlock Prevention**
   - Memory permit acquisition ordering
   - Cross-actor dependency cycles
   - Resource contention scenarios
   - Timeout mechanisms

### 4. Data Integrity and Quality Tests

#### Template Processing Accuracy Tests
```swift
class TemplateProcessingAccuracyTests: XCTestCase {
    func testCategoryDetectionAccuracy() async throws
    func testChunkingQualityValidation() async throws
    func testMetadataExtractionCompleteness() async throws
    func testContentPreservationIntegrity() async throws
    func testEmbeddingConsistency() async throws
}
```

**Quality Validation:**
1. **Template Categorization Accuracy** (>95%)
   - Contract, SOW, Form, Clause, Guide classification
   - Pattern matching validation
   - Edge case handling (ambiguous documents)
   - False positive/negative analysis

2. **Chunking Quality Assessment**
   - Semantic boundary preservation
   - Overlap consistency (50 tokens)
   - Content completeness (no data loss)
   - Chunk size compliance (400 tokens ±10%)

3. **Embedding Quality Validation**
   - Dimension reduction accuracy (768→384)
   - L2 normalization verification  
   - Semantic similarity preservation
   - Embedding stability across runs

#### Search Result Quality Tests
```swift
class SearchResultQualityTests: XCTestCase {
    func testSearchRelevanceNDCG() async throws
    func testCategoryFilterAccuracy() async throws
    func testCrossReferenceIntegrity() async throws
    func testSearchResultRanking() async throws
}
```

**Search Quality Metrics:**
- NDCG@10 ≥ 0.8 for template search relevance
- Category filtering: 100% accuracy
- Cross-reference validation with regulations
- Ranking consistency across multiple runs

### 5. Integration Tests

#### GraphRAG Infrastructure Integration Tests
```swift
class GraphRAGIntegrationTests: XCTestCase {
    func testLFM2ServiceIntegration() async throws
    func testObjectBoxSemanticIndexIntegration() async throws
    func testUnifiedSearchServiceIntegration() async throws
    func testRegulationProcessorCoordination() async throws
    func testFormAutoPopulationIntegration() async throws
}
```

**Integration Scenarios:**
1. **LFM2Service Coordination**
   - Dimension reduction integration
   - Batch embedding generation
   - Error handling coordination
   - Memory management alignment

2. **ObjectBox Vector Database**
   - Template embedding storage
   - Memory-mapped file integration
   - Multi-namespace coordination (regulations + templates)
   - Index optimization validation

3. **Unified Search Integration**
   - Cross-domain search capability
   - Result ranking across namespaces
   - Filter coordination
   - Performance impact assessment

#### End-to-End Workflow Tests  
```swift
class EndToEndWorkflowTests: XCTestCase {
    func testCompleteTemplateProcessingPipeline() async throws
    func testTemplateSearchToFormPopulation() async throws
    func testErrorRecoveryWorkflows() async throws
    func testProgressTrackingAccuracy() async throws
}
```

**Complete Workflows:**
- Template discovery → processing → embedding → storage → search
- Search query → hybrid results → form population suggestions
- Error scenarios → recovery → continuation
- Progress tracking → user feedback → completion

### 6. Security and Compliance Tests

#### Government Data Security Tests
```swift
class SecurityComplianceTests: XCTestCase {
    func testGovernmentDataEncryption() async throws
    func testAccessControlValidation() async throws
    func testDataLeakagePrevention() async throws
    func testSecureDataTransmission() async throws
    func testComplianceAuditTrail() async throws
}
```

**Security Validation:**
1. **Government Template Security**
   - Encryption-at-rest for stored embeddings
   - iOS file protection mechanism validation
   - Secure keychain integration for sensitive metadata
   - Access control for template retrieval

2. **Data Privacy Protection**
   - PII detection and redaction in templates
   - Secure deletion of temporary processing files
   - Memory scrubbing after processing
   - Audit trail generation for compliance

3. **Network Security**
   - Certificate pinning for any external connections
   - Secure API authentication
   - Data transmission encryption
   - Rate limiting and abuse prevention

### 7. Long-Term Stability Tests

#### Extended Operation Tests
```swift
class LongTermStabilityTests: XCTestCase {
    func testExtendedProcessingMemoryLeaks() async throws
    func testLongRunningSearchPerformance() async throws
    func testIndexGrowthValidation() async throws
    func testCacheEfficiencyOverTime() async throws
    func testBackgroundProcessingStability() async throws
}
```

**Stability Validation:**
- 24-hour continuous processing without memory leaks
- Performance degradation monitoring over extended use
- Index size growth patterns and optimization
- Cache hit ratio maintenance over time
- Background processing impact on user experience

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
}
```

**Error Recovery Validation:**
1. **Corrupted Data Handling**
   - Malformed PDF/DOCX files
   - Invalid character encoding
   - Incomplete template files
   - Checksum validation failures

2. **Resource Exhaustion Scenarios**
   - Memory pressure during processing
   - Disk space limitations
   - Processing timeouts
   - Rate limiting responses

3. **Recovery Mechanisms**
   - Checkpoint save/restore
   - Partial processing continuation
   - Graceful degradation modes
   - User notification systems

## Success Criteria

### Performance Requirements
- **Memory Constraint**: Peak usage <50MB during 256MB processing
- **Search Latency**: P50 <10ms, P95 <20ms
- **Processing Speed**: Complete 256MB dataset in <3 minutes
- **Startup Impact**: Templates searchable within 3 minutes of app launch

### Quality Standards  
- **Build Status**: Zero errors, zero warnings with Swift 6 strict concurrency
- **SwiftLint Compliance**: Zero violations across all components
- **Test Coverage**: >90% for memory-critical paths, >85% overall
- **Search Quality**: NDCG@10 ≥ 0.8 for template relevance
- **Security Compliance**: Zero security vulnerabilities, complete data protection
- **Long-Term Stability**: Zero memory leaks over 24-hour continuous operation

### Integration Requirements
- **Seamless GraphRAG Integration**: No disruption to existing regulation search
- **Cross-Platform Support**: iOS/macOS compatibility
- **User Experience**: Intuitive search with clear memory usage indication
- **Error Resilience**: Graceful degradation under all failure scenarios

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
- All search performance targets must be met
- Complete actor isolation validation
- Comprehensive error scenario coverage
- Full integration test suite passing

## Implementation Timeline

### Phase 1: Memory Infrastructure Tests (Week 1)
- Memory permit system validation
- Chunk processing memory bounds
- Performance baseline establishment

### Phase 2: Search Performance Tests (Week 2)  
- Hybrid search latency benchmarking
- BM25 prefilter validation
- Vector reranking optimization

### Phase 3: Integration Tests (Week 3)
- GraphRAG component coordination
- End-to-end workflow validation
- Cross-platform compatibility

### Phase 4: Quality Assurance (Week 4)
- Error handling comprehensive testing
- Performance stress testing
- Production readiness validation

### Phase 5: Final Validation (Week 5)
- Full system integration testing
- User acceptance criteria validation
- Production deployment preparation

## Research-Enhanced Testing Strategies

Based on research findings from `researchPerplexity_ACQTemplatesProcessing.md`:

### Chunking Strategy Validation
- **Character-based splitters** for semantic boundary preservation
- **Overlap consistency** testing for context retention
- **Chunk size optimization** balancing memory vs semantic coherence

### Performance Testing Patterns
- **Streaming architecture validation** for memory efficiency
- **Batch processing optimization** for embedding generation
- **Incremental processing verification** for large document handling

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
- **LFM2Service Mocking**: Deterministic embedding generation for testing
- **ObjectBox Simulation**: Memory-backed testing without persistent storage
- **Network Mocking**: Controlled failure scenario simulation
- **Memory Pressure Simulation**: Artificial memory constraint testing

### Testing Environment Setup
- **iOS Simulator**: Memory profiling with Instruments
- **Physical Device Testing**: iPhone 12/13 memory constraint validation
- **Continuous Integration**: Automated test suite execution
- **Performance Monitoring**: Real-time metric collection during tests

This comprehensive testing rubric ensures the ACQ Templates Processing implementation meets all critical requirements while maintaining the highest quality standards for production deployment.
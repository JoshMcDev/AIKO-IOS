# Testing Rubric: ObjectBox Semantic Index Vector Database Implementation (DRAFT)

## Document Metadata
- Task: objectbox-semantic-index-vector-database
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-guardian
- Status: Initial draft awaiting consensus validation

## Executive Summary

This testing rubric defines comprehensive test requirements for implementing the ObjectBox Semantic Index Vector Database as the foundational vector storage layer for AIKO's GraphRAG intelligence system. Based on validated PRD requirements and detailed implementation design, this rubric ensures production-ready quality for semantic search capabilities across 1000+ federal acquisition regulations with strict performance, security, and compliance standards.

**Core Testing Strategy:**
- Performance-driven testing with concrete targets (<1s search, <100MB storage, ≤2% battery)
- Security-first approach with FIPS 140-2 compliance validation
- Mobile optimization focus with device matrix testing
- Integration validation with existing LFM2Service (768-dimensional vectors)
- Golden dataset evaluation using nDCG@10 methodology

## Test Categories

### Unit Tests

#### 1. RegulationEmbedding Entity Tests
**Test Class: RegulationEmbeddingTests**

**T-UNI-001: Entity Creation and Validation**
```swift
func testRegulationEmbeddingCreation() {
    // Test basic entity creation with all required fields
    // Validate 768-dimensional vector constraint
    // Verify schema version tracking
    // Assert checksum generation
}

func testEmbeddingDimensionValidation() {
    // Test vector dimension validation (must be exactly 768)
    // Verify rejection of incorrect dimensions
    // Test empty and nil vector handling
}

func testMetadataValidation() {
    // Test regulation ID uniqueness constraints
    // Validate effective date handling
    // Test category classification
    // Verify version string format
}
```

**T-UNI-002: HNSW Index Configuration**
```swift
func testHNSWIndexParameters() {
    // Validate HNSW annotation parsing
    // Test cosine distance configuration
    // Verify mobile-optimized parameters (neighborsPerNode=30, indexingSearchCount=200)
    // Test vector cache configuration (1048576 KB)
}

func testSchemaEvolution() {
    // Test schema version migration handling
    // Validate backward compatibility
    // Test field addition/removal scenarios
}
```

#### 2. VectorSearchService Tests
**Test Class: VectorSearchServiceTests**

**T-UNI-003: Service Initialization**
```swift
func testServiceInitialization() {
    // Test actor initialization with encryption setup
    // Validate ObjectBox store creation
    // Test database path security configuration
    // Verify performance monitor initialization
}

func testEncryptionInitialization() {
    // Test AES-256-GCM key generation
    // Validate iOS Data Protection integration
    // Test secure key storage in Keychain
    // Verify encryption compliance (FIPS 140-2)
}

func testFailureRecovery() {
    // Test initialization failure scenarios
    // Validate rollback mechanisms
    // Test corrupted database recovery
    // Verify graceful degradation
}
```

**T-UNI-004: CRUD Operations**
```swift
func testVectorStorage() {
    // Test individual embedding storage
    // Validate batch import operations
    // Test duplicate handling
    // Verify transaction integrity
}

func testVectorRetrieval() {
    // Test individual vector retrieval
    // Validate metadata filtering
    // Test not-found scenarios
    // Verify error handling
}

func testVectorUpdates() {
    // Test embedding updates
    // Validate HNSW index maintenance
    // Test version tracking
    // Verify conflict resolution
}

func testVectorDeletion() {
    // Test individual deletion
    // Validate batch deletion
    // Test HNSW index cleanup
    // Verify referential integrity
}
```

#### 3. Search Functionality Tests
**Test Class: SemanticSearchTests**

**T-UNI-005: Similarity Search**
```swift
func testNearestNeighborSearch() {
    // Test basic similarity search
    // Validate result ordering by distance
    // Test limit parameter handling
    // Verify score calculation accuracy
}

func testCosineSimilarityAccuracy() {
    // Test cosine distance calculations
    // Validate against manual calculations
    // Test normalized vector handling
    // Verify score range (0.0-2.0)
}

func testHybridSearch() {
    // Test combined vector + metadata search
    // Validate pre-filtering optimization
    // Test category-based filtering
    // Verify date range filtering
}
```

**T-UNI-006: Query Optimization**
```swift
func testPagination() {
    // Test offset/limit functionality
    // Validate memory-efficient implementation
    // Test large result sets
    // Verify consistency across pages
}

func testResultCaching() {
    // Test LRU cache implementation
    // Validate cache hit/miss scenarios
    // Test cache invalidation
    // Verify memory usage
}

func testQueryPerformanceOptimization() {
    // Test ef parameter optimization
    // Validate device-specific tuning
    // Test query complexity handling
    // Verify adaptive behavior
}
```

### Integration Tests

#### 1. LFM2Service Integration Tests
**Test Class: LFM2VectorIntegrationTests**

**T-INT-001: Embedding Pipeline Integration**
```swift
func testLFM2ToObjectBoxPipeline() {
    // Test end-to-end embedding generation and storage
    // Validate 768-dimensional vector compatibility
    // Test batch processing workflow
    // Verify error handling throughout pipeline
}

func testVectorNormalization() {
    // Test automatic vector normalization
    // Validate Accelerate framework integration
    // Test cosine optimization preparation
    // Verify numerical accuracy
}

func testEmbeddingConsistency() {
    // Test consistent embeddings for identical text
    // Validate reproducible results
    // Test numerical stability
    // Verify embedding quality metrics
}
```

**T-INT-002: Performance Integration**
```swift
func testPipelineLatency() {
    // Test complete generate->store->search latency
    // Validate <1s end-to-end performance
    // Test concurrent processing
    // Verify memory usage during integration
}

func testResourceSharing() {
    // Test memory sharing between services
    // Validate actor isolation boundaries
    // Test resource cleanup
    // Verify no memory leaks
}
```

#### 2. GraphRAG System Integration Tests
**Test Class: GraphRAGIntegrationTests**

**T-INT-003: UnifiedSearchService Integration**
```swift
func testUnifiedSearchIntegration() {
    // Test ObjectBox integration with UnifiedSearchService
    // Validate query routing
    // Test result aggregation
    // Verify cross-domain search
}

func testRegulationProcessorIntegration() {
    // Test regulation chunking and embedding pipeline
    // Validate metadata extraction
    // Test batch processing
    // Verify data consistency
}
```

### Performance Tests

#### 1. Search Performance Tests
**Test Class: SearchPerformanceTests**

**T-PERF-001: Search Latency Testing**
```swift
func testSearchLatencyTargets() {
    // Test <1s search latency (95th percentile)
    // Validate across 1000+ regulations
    // Test device matrix (iPhone 12-15, iPad variations)
    // Verify P95/P99 performance metrics
}

func testConcurrentSearchPerformance() {
    // Test 100+ concurrent searches
    // Validate actor isolation performance
    // Test memory usage under load
    // Verify no performance degradation
}

func testScalabilityPerformance() {
    // Test performance with 1K, 5K, 10K, 15K regulations
    // Validate linear performance characteristics
    // Test index build times
    // Verify memory usage scaling
}
```

**T-PERF-002: Resource Usage Testing**
```swift
func testMemoryUsage() {
    // Test <50MB peak memory usage
    // Validate memory pressure handling
    // Test garbage collection efficiency
    // Verify no memory leaks
}

func testStorageEfficiency() {
    // Test <100MB total database size
    // Validate >10 regulations per MB
    // Test compression effectiveness
    // Verify storage growth patterns
}

func testBatteryImpact() {
    // Test ≤2% battery per 10 minutes sustained querying
    // Validate CPU efficiency
    // Test thermal throttling adaptation
    // Verify power consumption metrics
}
```

#### 2. HNSW Performance Tests
**Test Class: HNSWPerformanceTests**

**T-PERF-003: HNSW Configuration Testing**
```swift
func testHNSWParameterOptimization() {
    // Test different neighborsPerNode values (16, 30, 64)
    // Validate indexingSearchCount impact
    // Test mobile-specific optimizations
    // Verify accuracy vs speed trade-offs
}

func testIndexBuildPerformance() {
    // Test HNSW index construction time
    // Validate incremental updates
    // Test memory usage during build
    // Verify index quality metrics
}

func testSearchAccuracy() {
    // Test nDCG@10 with golden dataset
    // Validate >0.85 relevance score
    // Test semantic similarity quality
    // Verify against manual relevance judgments
}
```

### Security Tests

#### 1. Encryption and Data Protection Tests
**Test Class: SecurityComplianceTests**

**T-SEC-001: Encryption Implementation**
```swift
func testAES256GCMEncryption() {
    // Test AES-256-GCM encryption at rest
    // Validate key generation and storage
    // Test iOS Data Protection integration
    // Verify secure key derivation
}

func testFIPS140Compliance() {
    // Test FIPS 140-2 cryptographic compliance
    // Validate approved algorithms usage
    // Test key management procedures
    // Verify compliance certification paths
}

func testTamperDetection() {
    // Test file integrity monitoring
    // Validate hash-based verification
    // Test corruption detection
    // Verify automated recovery
}
```

**T-SEC-002: Access Control and Privacy**
```swift
func testDataIsolation() {
    // Test app sandbox compliance
    // Validate data access restrictions
    // Test cross-app isolation
    // Verify iOS security model adherence
}

func testPrivacyCompliance() {
    // Test zero external data transmission
    // Validate on-device processing only
    // Test network monitoring compliance
    // Verify PII protection
}

func testSecureDataHandling() {
    // Test secure memory management
    // Validate sensitive data cleanup
    // Test secure deletion
    // Verify cryptographic erasure
}
```

### Edge Cases and Error Scenarios

#### 1. Data Corruption and Recovery Tests
**Test Class: DataIntegrityTests**

**T-EDGE-001: Corruption Scenarios**
```swift
func testDatabaseCorruptionRecovery() {
    // Test database file corruption
    // Validate automatic recovery
    // Test backup restoration
    // Verify data integrity preservation
}

func testIndexCorruptionHandling() {
    // Test HNSW index corruption
    // Validate rebuild procedures
    // Test search fallback mechanisms
    // Verify performance during recovery
}

func testSchemaVersionMismatch() {
    // Test version incompatibility handling
    // Validate migration procedures
    // Test rollback scenarios
    // Verify data preservation
}
```

**T-EDGE-002: Resource Constraint Scenarios**
```swift
func testLowMemoryConditions() {
    // Test operation under memory pressure
    // Validate graceful degradation
    // Test cleanup procedures
    // Verify essential functionality preservation
}

func testLowStorageConditions() {
    // Test operation with limited storage
    // Validate cleanup mechanisms
    // Test user notifications
    // Verify data preservation priorities
}

func testThermalThrottling() {
    // Test behavior under thermal constraints
    // Validate performance adaptation
    // Test parameter adjustment
    // Verify system stability
}
```

#### 2. Concurrency and Race Condition Tests
**Test Class: ConcurrencyTests**

**T-EDGE-003: Concurrent Access Scenarios**
```swift
func testConcurrentReadWrite() {
    // Test simultaneous read/write operations
    // Validate data consistency
    // Test actor isolation effectiveness
    // Verify no race conditions
}

func testHighConcurrencyLoad() {
    // Test 100+ concurrent operations
    // Validate queue management
    // Test backpressure handling
    // Verify system stability
}

func testActorIsolationValidation() {
    // Test Swift 6 strict concurrency compliance
    // Validate proper isolation boundaries
    // Test data race prevention
    // Verify sendable conformance
}
```

### Accessibility and Usability Tests

#### 1. Accessibility Compliance Tests
**Test Class: AccessibilityTests**

**T-ACCESS-001: VoiceOver Support**
```swift
func testVoiceOverCompatibility() {
    // Test screen reader support
    // Validate descriptive labels
    // Test navigation order
    // Verify semantic markup
}

func testKeyboardNavigation() {
    // Test full keyboard accessibility
    // Validate focus management
    // Test shortcut support
    // Verify no mouse dependencies
}
```

#### 2. Cross-Platform Compatibility Tests
**Test Class: CrossPlatformTests**

**T-COMPAT-001: iOS/macOS Compatibility**
```swift
func testiOSCompatibility() {
    // Test iPhone/iPad functionality
    // Validate size class adaptations
    // Test touch interface optimization
    // Verify iOS-specific features
}

func testmacOSCompatibility() {
    // Test native macOS performance
    // Validate Apple Silicon optimization
    // Test macOS-specific features
    // Verify cross-platform consistency
}
```

## Success Criteria

### Primary Success Metrics

**Performance Targets:**
- [ ] Search latency <1 second (95th percentile) across 1000+ regulations
- [ ] Database storage <100MB total with compression
- [ ] Memory usage <50MB during peak operations
- [ ] Battery consumption ≤2% per 10 minutes sustained querying

**Quality Targets:**
- [ ] Semantic relevance >0.85 nDCG@10 with golden dataset
- [ ] Zero data loss during normal operations
- [ ] <0.1% error rate across all operations
- [ ] Swift 6 strict concurrency compliance

**Security Targets:**
- [ ] FIPS 140-2 cryptographic compliance
- [ ] Zero external data transmission verified
- [ ] Complete on-device processing validation
- [ ] Comprehensive audit trail implementation

### Test Coverage Requirements

**Code Coverage:**
- [ ] >90% unit test coverage across all components
- [ ] >95% coverage for critical security functions
- [ ] 100% coverage for data handling operations
- [ ] Integration test coverage for all external interfaces

**Scenario Coverage:**
- [ ] All happy path scenarios validated
- [ ] All error conditions tested and handled
- [ ] All edge cases identified and covered
- [ ] All performance targets validated under load

**Device Matrix Coverage:**
- [ ] iPhone 12, 13, 14, 15 (all variants) tested
- [ ] iPad Air and Pro tested
- [ ] macOS Apple Silicon tested
- [ ] Cross-platform feature parity validated

## Test Implementation Guidelines

### Testing Frameworks and Tools

**Primary Testing Stack:**
- XCTest for unit and integration testing
- XCUITest for accessibility testing
- Instruments for performance profiling
- Network Link Conditioner for edge case testing

**Performance Testing Tools:**
- CFAbsoluteTimeGetCurrent() for latency measurement
- os_signpost for detailed performance tracing
- Instruments Memory Graph Debugger for leak detection
- Battery usage monitoring APIs

**Security Testing Tools:**
- CryptoKit validation utilities
- iOS Security framework testing
- Network monitoring for privacy validation
- File system security verification

### Continuous Integration Requirements

**Automated Testing Pipeline:**
- [ ] All unit tests run on every commit
- [ ] Integration tests run on merge requests
- [ ] Performance regression testing
- [ ] Security vulnerability scanning

**Quality Gates:**
- [ ] Zero test failures to merge
- [ ] Performance regression <5% acceptable
- [ ] Memory leak detection required
- [ ] Security compliance validation

### Golden Dataset Evaluation

**Semantic Relevance Validation:**
```swift
struct GoldenDatasetQuery {
    let query: String
    let expectedRelevantRegulations: [String]
    let relevanceScores: [Double]
}

// Example queries for nDCG@10 evaluation:
- "software procurement thresholds over $500K"
- "small business set-aside requirements"
- "federal acquisition regulation compliance"
- "emergency procurement procedures"
- "contract modification guidelines"
```

**Evaluation Methodology:**
- [ ] 100+ curated query/answer pairs
- [ ] Expert validation of relevance scores
- [ ] nDCG@10 calculation implementation
- [ ] Automated regression testing

## Risk Mitigation Testing

### High-Risk Areas Requiring Extra Testing

1. **Performance Degradation Risk**
   - Extensive device matrix testing
   - Memory pressure scenario validation
   - Thermal throttling adaptation testing

2. **Security Compliance Risk**
   - FIPS 140-2 compliance validation
   - Federal security standards testing
   - Penetration testing simulation

3. **Data Integrity Risk**
   - Corruption recovery testing
   - Backup/restore validation
   - Transaction integrity verification

4. **Integration Risk**
   - LFM2Service compatibility testing
   - GraphRAG pipeline validation
   - Cross-service error handling

## Testing Schedule and Phases

### Phase 1: Foundation Testing (Week 1)
- Unit tests for RegulationEmbedding entity
- VectorSearchService basic functionality
- Encryption and security implementation
- Basic performance baseline establishment

### Phase 2: Integration Testing (Week 2)
- LFM2Service pipeline integration
- GraphRAG system integration
- Performance optimization validation
- Cross-platform compatibility testing

### Phase 3: Advanced Testing (Week 3)
- Edge case and error scenario testing
- Concurrent access and load testing
- Security compliance validation
- Accessibility testing

### Phase 4: Production Validation (Week 4)
- Golden dataset evaluation
- Device matrix performance validation
- End-to-end system testing
- Documentation and deployment testing

This comprehensive testing rubric ensures the ObjectBox Semantic Index Vector Database implementation meets all performance, security, and quality requirements for production deployment in AIKO's GraphRAG intelligence system.
# Testing Rubric: Regulation Processing Pipeline with Smart Chunking - DRAFT

## Document Metadata
- Task: Build Regulation Processing Pipeline with Smart Chunking
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-guardian
- Status: Draft - Awaiting consensus validation

## Executive Summary

This comprehensive testing rubric defines the strategy, criteria, and quality gates for validating the regulation processing pipeline with structure-aware hierarchical chunking. The system transforms HTML regulations into searchable vector embeddings while maintaining regulatory context, operating within strict memory constraints (400MB), and providing complete durability guarantees.

### Core Testing Philosophy
- **TDD-First Approach**: Every production implementation preceded by failing tests
- **Memory-Constrained Testing**: Validate deterministic memory bounds under all conditions
- **Security-First Validation**: Zero-tolerance for security vulnerabilities or data exposure
- **Durability-Centric Testing**: Complete crash recovery and data integrity validation
- **Performance-Driven Quality**: Sub-second response times with 100+ docs/min throughput

## Test Categories

### Unit Tests

#### 1. Structure-Aware Chunking Engine Tests
**Test Coverage**: StructureAwareChunker actor and hierarchical processing

- **Boundary Detection Tests**
  - Verify accurate detection of h1, h2, h3, p, li HTML elements
  - Validate hierarchy path construction ["FAR 15.2", "Solicitation", "(a)"]
  - Test depth limiting (max 5 levels) with graceful degradation
  - Edge cases: Malformed HTML, nested structures, empty elements

- **Context Preservation Tests**
  - Validate 100-token overlap between adjacent chunks
  - Test parent-child relationship retention (95% target)
  - Verify contextual window generation (parent + current + preview)
  - Test coherence maintenance across chunk boundaries

- **Token Management Tests**
  - Accurate token counting with target 512 tokens per chunk
  - Min/max chunk size enforcement (100-1000 tokens)
  - Overflow handling for oversized content sections
  - Token-aware splitting at natural boundaries

- **Fallback Mechanism Tests**
  - SwiftSoup parsing failure → flat chunking mode
  - HTML structure detection failure → regex-based fallback
  - Depth overflow → flattening to maximum depth
  - Invalid hierarchy → linear sequence preservation

#### 2. Memory Management Tests
**Test Coverage**: MemoryOptimizedBatchProcessor and bounded resource usage

- **Deterministic Memory Bounds**
  - Validate 400MB hard limit under all processing scenarios
  - Test semaphore control (max 512 chunks in-flight)
  - Memory pressure response and dynamic batch resizing
  - Mmap buffer overflow handling and recovery

- **Predictive Sizing Tests**
  - DocumentSizePredictor accuracy validation (±10% target)
  - Batch size optimization based on available memory
  - Memory watermark tracking and alert thresholds
  - Autoreleasepool effectiveness measurement

- **Cleanup Validation Tests**
  - Verify aggressive memory cleanup between batches
  - Test garbage collection trigger effectiveness
  - Memory leak detection during sustained processing
  - Resource cleanup on processing cancellation

#### 3. Security Layer Tests
**Test Coverage**: RegulationSecurityService and comprehensive encryption

- **Encryption Correctness Tests**
  - AES-256-GCM encryption/decryption round-trip validation
  - Key derivation from iOS Keychain verification
  - Secure random IV generation uniqueness
  - Envelope encryption integrity validation

- **Key Management Tests**
  - Key rotation without service disruption
  - Secure enclave integration verification  
  - Emergency key recovery procedure validation
  - Dual-key support during rotation periods

- **Secure Deletion Tests**
  - Cryptographic erasure verification
  - Memory overwrite pattern validation
  - Failed processing data cleanup
  - Tamper detection and response

#### 4. Checkpoint and Durability Tests
**Test Coverage**: CheckpointManager, DeadLetterQueue, and recovery systems

- **Checkpoint Persistence Tests**
  - SQLite WAL checkpoint creation and restoration
  - Stage boundary checkpoint accuracy
  - Checkpoint serialization/deserialization integrity
  - Concurrent checkpoint access safety

- **Recovery Mechanism Tests**
  - Complete pipeline recovery from any stage failure
  - Dead letter queue processing and retry logic
  - Circuit breaker activation and recovery
  - Data consistency during crash recovery

### Integration Tests

#### 1. End-to-End Pipeline Tests
**Test Coverage**: Complete processing workflow validation

- **Pipeline Coordination Tests**
  - AsyncChannel stage coordination with back-pressure
  - TaskGroup management for concurrent processing
  - Memory pressure propagation through pipeline
  - Progress reporting accuracy and real-time updates

- **Actor Communication Tests**
  - Thread-safe communication between all actors
  - Bounded channel overflow handling
  - Message ordering preservation
  - Error propagation through pipeline stages

#### 2. LFM2Service Integration Tests
**Test Coverage**: Embedding generation and batch processing

- **Batch Processing Integration**
  - 400MB memory limit enforcement during embedding
  - Streaming embedding generation validation
  - Cooperative yielding effectiveness (every 100 ops)
  - Model loading and unloading efficiency

- **Core ML Model Integration**
  - 768-dimension embedding generation accuracy
  - Processing latency <2 seconds per chunk
  - Model quantization effectiveness
  - Memory usage during inference

#### 3. ObjectBox Storage Integration Tests
**Test Coverage**: HNSW indexing and vector storage

- **Vector Storage Tests**
  - RegulationChunkEntity schema validation
  - HNSW index configuration for regulation namespace
  - Incremental index updates during processing
  - Schema migration compatibility

- **Search Accuracy Tests**
  - Vector similarity search precision
  - Metadata filtering effectiveness
  - Search result ranking validation
  - Cross-regulation context retrieval

### Security Tests

#### 1. Encryption and Key Management
**Test Coverage**: Complete security validation

- **Cryptographic Security Tests**
  - AES-256-GCM implementation correctness
  - Key strength and randomness validation
  - Timing attack resistance verification
  - Side-channel attack prevention

- **Key Lifecycle Tests**
  - Key generation using secure random sources
  - Keychain storage and retrieval security
  - Key rotation schedule adherence (90-day default)
  - HSM integration for enterprise deployments

#### 2. Data Protection Tests
**Test Coverage**: Information security and privacy

- **Data Integrity Tests**
  - Checksum validation for processed content
  - Tamper detection during storage/retrieval
  - Data corruption recovery mechanisms
  - Audit trail completeness and integrity

- **Privacy Protection Tests**
  - On-device processing verification (no external transmission)
  - Secure wipe effectiveness validation
  - Memory forensic resistance
  - Compliance with government data handling requirements

### Performance Tests

#### 1. Throughput and Latency Tests
**Test Coverage**: Processing speed and responsiveness

- **Throughput Benchmarks**
  - 100+ documents/minute processing validation
  - Sustained processing performance over 1000+ docs
  - Memory usage stability during extended runs
  - CPU utilization optimization

- **Latency Requirements**
  - <2 seconds per chunk embedding generation
  - <100ms ObjectBox insertion time
  - P99 latency <5 seconds for complete pipeline
  - Real-time progress reporting <200ms updates

#### 2. Resource Utilization Tests
**Test Coverage**: System resource management

- **Memory Constraint Validation**
  - Deterministic 400MB peak memory enforcement
  - Memory pressure response testing
  - Resource cleanup effectiveness measurement
  - Memory fragmentation impact assessment

- **Concurrent Processing Tests**
  - 10-concurrent chunk processing validation
  - Thread safety under high concurrency
  - Actor isolation effectiveness
  - Deadlock and race condition prevention

### Edge Cases and Error Scenarios

#### 1. HTML Parsing Edge Cases
**Test Coverage**: Robust parsing under adverse conditions

- **Malformed HTML Tests**
  - Government document formatting inconsistencies
  - Missing or incorrect tag closures
  - Invalid character encoding handling
  - Extremely large document processing

- **Content Variation Tests**
  - Empty documents and sections
  - Documents with no hierarchical structure
  - Extremely deep nesting (>5 levels)
  - Mixed content types within documents

#### 2. System Failure Scenarios
**Test Coverage**: Graceful degradation and recovery

- **Resource Exhaustion Tests**
  - Memory exhaustion handling
  - Disk space limitations
  - Network connectivity issues
  - Battery power constraints on mobile

- **Concurrent Failure Tests**
  - Multiple simultaneous component failures
  - Cascading failure prevention
  - Recovery from partial processing states
  - Data consistency during system failures

### Chaos Engineering Tests

#### 1. Fault Injection Tests
**Test Coverage**: System resilience validation

- **Process Termination Tests**
  - Random process kills during processing
  - Checkpoint recovery validation
  - Data integrity after unexpected termination
  - Resume processing from last checkpoint

- **Resource Limitation Tests**
  - Memory pressure simulation
  - Disk I/O throttling
  - CPU resource constraints
  - Network partition handling

## Success Criteria

### Functional Requirements Validation
- ✓ Process FAR/DFARS HTML documents successfully
- ✓ Preserve 95% hierarchical relationships in chunks
- ✓ Generate accurate 768-dimension embeddings
- ✓ Store complete metadata in ObjectBox
- ✓ Recover from failures without data loss

### Performance Requirements Validation
- ✓ Achieve 100+ documents/minute throughput
- ✓ Maintain <400MB peak memory usage (deterministic)
- ✓ Complete chunk embedding in <2 seconds
- ✓ ObjectBox insertion in <100ms
- ✓ P99 latency <5 seconds

### Quality Requirements Validation
- ✓ Maintain 95% chunk coherence
- ✓ Achieve 90% search relevance
- ✓ Provide 95% error recovery rate
- ✓ Ensure 100% security compliance
- ✓ Guarantee 99.9% durability

### Operational Requirements Validation
- ✓ Complete observability with metrics
- ✓ Automated failure recovery
- ✓ Zero data loss on crash
- ✓ Key rotation without downtime

## Implementation Timeline

### Phase 1: Foundation Testing (Days 1-4)
- Unit tests for checkpoint infrastructure
- SwiftSoup integration validation
- Fallback mechanism verification
- Basic security layer testing

### Phase 2: Core Engine Testing (Days 5-7)
- Structure-aware chunking validation
- Memory management testing
- Boundary detection verification
- Token counting accuracy

### Phase 3: Integration Testing (Days 8-11)
- Pipeline coordination validation
- LFM2Service integration testing
- ObjectBox storage verification
- AsyncChannel communication testing

### Phase 4: Security and Performance Testing (Days 12-14)
- Comprehensive security audit
- Performance benchmarking
- Load testing and resource validation
- Key management testing

### Phase 5: Chaos and Edge Case Testing (Days 15-18)
- Fault injection testing
- Edge case validation
- Recovery scenario testing
- Production readiness validation

## Testing Tools and Framework

### Testing Infrastructure
- **XCTest Framework**: Core testing infrastructure
- **Swift Testing**: Modern async/await test patterns
- **Actor Testing**: Isolated actor behavior validation
- **Memory Profiling**: Instruments integration for memory validation
- **Performance Testing**: XCTMetric integration for benchmarking

### Mock and Stub Strategy
- **SwiftSoup Mocking**: Controlled HTML parsing scenarios
- **Core ML Mocking**: Deterministic embedding generation
- **ObjectBox Mocking**: Isolated storage behavior testing
- **Network Mocking**: Offline processing validation

### Continuous Integration
- **Automated Test Execution**: All tests run on every commit
- **Performance Regression Detection**: Benchmark comparison
- **Memory Leak Detection**: Automated memory analysis
- **Security Scan Integration**: Static analysis tooling

## Risk Mitigation Through Testing

### High-Risk Areas
1. **Memory Constraint Violations**: Comprehensive memory testing with deterministic validation
2. **HTML Parsing Failures**: Extensive malformed document testing with fallback validation
3. **Pipeline Durability**: Complete crash recovery testing with data integrity verification
4. **Security Vulnerabilities**: Comprehensive security audit with penetration testing
5. **Performance Degradation**: Continuous performance monitoring with regression detection

### Mitigation Strategies
- **Fuzz Testing**: Random HTML document generation for robustness
- **Property-Based Testing**: Automated edge case discovery
- **Load Testing**: Sustained processing validation
- **Security Auditing**: Third-party security review
- **Performance Profiling**: Continuous optimization validation

## Quality Gates

### Unit Test Gates
- 100% test passage required
- 95% code coverage minimum
- Zero memory leaks detected
- All security tests passing

### Integration Test Gates  
- End-to-end pipeline validation
- Performance benchmarks met
- Memory constraints validated
- Durability guarantees verified

### Production Readiness Gates
- Chaos engineering tests passing
- Security audit completed
- Performance validation successful
- Documentation complete

This draft testing rubric provides comprehensive coverage for the regulation processing pipeline implementation, ensuring robust validation of all critical functionality while maintaining the highest standards for security, performance, and reliability.
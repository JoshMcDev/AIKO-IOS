# Testing Rubric: Regulation Processing Pipeline with Smart Chunking

## Document Metadata
- Task: Build Regulation Processing Pipeline with Smart Chunking  
- Version: Enhanced v1.0
- Date: 2025-08-07
- Author: tdd-guardian
- Consensus Method: Multi-model validation synthesis applied

## Consensus Enhancement Summary

Based on comprehensive multi-model consensus validation (4 models consulted), this enhanced testing rubric incorporates critical improvements identified across all perspectives:
- **AsyncChannel back-pressure testing** elevated to highest priority as critical system risk
- **Long-term performance validation** with 24-48 hour soak tests for memory leak detection
- **Enhanced security scope** with side-channel analysis and cryptographic fuzzing
- **Real-world government HTML corpus** for comprehensive edge case validation
- **Strengthened chaos engineering** with multi-component failure scenarios
- **Improved test isolation** with injectable clocks and deterministic environments

## Executive Summary

This comprehensive testing rubric defines the strategy, criteria, and quality gates for validating the regulation processing pipeline with structure-aware hierarchical chunking. The system transforms HTML regulations into searchable vector embeddings while maintaining regulatory context, operating within strict memory constraints (400MB), and providing complete durability guarantees.

### Enhanced Testing Philosophy
- **TDD-First Approach**: Every production implementation preceded by failing tests with enforced Definition of Done
- **Memory-Constrained Validation**: Deterministic memory bounds validated under all conditions including adversarial scenarios
- **Security-First Validation**: Zero-tolerance for security vulnerabilities with comprehensive threat modeling
- **Durability-Centric Testing**: Complete crash recovery and data integrity validation with chaos engineering
- **Performance-Driven Quality**: Sub-second response times with sustained 100+ docs/min throughput validation

## Test Categories

### Unit Tests

#### 1. Structure-Aware Chunking Engine Tests
**Test Coverage**: StructureAwareChunker actor and hierarchical processing

- **Boundary Detection Tests**
  - Verify accurate detection of h1, h2, h3, p, li HTML elements
  - Validate hierarchy path construction ["FAR 15.2", "Solicitation", "(a)"]  
  - Test depth limiting (max 5 levels) with graceful degradation
  - **Enhanced**: Character encoding edge cases (Latin-1, UTF-16 BOM, mixed encodings)
  - Edge cases: Malformed HTML, nested structures, empty elements, extremely deep nesting

- **Context Preservation Tests**
  - Validate 100-token overlap between adjacent chunks
  - Test parent-child relationship retention (95% target)
  - Verify contextual window generation (parent + current + preview)
  - Test coherence maintenance across chunk boundaries
  - **Enhanced**: Golden master regression tests to pin expected hierarchical output over time

- **Token Management Tests**
  - Accurate token counting with target 512 tokens per chunk
  - Min/max chunk size enforcement (100-1000 tokens)
  - Overflow handling for oversized content sections
  - Token-aware splitting at natural boundaries
  - **Enhanced**: Multi-gigabyte single documents that exceed 400MB memory constraints

- **Fallback Mechanism Tests**
  - SwiftSoup parsing failure → flat chunking mode
  - HTML structure detection failure → regex-based fallback
  - Depth overflow → flattening to maximum depth
  - Invalid hierarchy → linear sequence preservation
  - **Enhanced**: Mixed content handling (PDF-in-HTML, embedded base64, JS-generated DOM)

#### 2. Memory Management Tests
**Test Coverage**: MemoryOptimizedBatchProcessor and bounded resource usage

- **Deterministic Memory Bounds**
  - Validate 400MB hard limit under all processing scenarios
  - Test semaphore control (max 512 chunks in-flight)
  - Memory pressure response and dynamic batch resizing
  - Mmap buffer overflow handling and recovery
  - **Enhanced**: OOM kill simulation before mmap overflow detection

- **Predictive Sizing Tests**
  - DocumentSizePredictor accuracy validation (±10% target)
  - Batch size optimization based on available memory
  - Memory watermark tracking and alert thresholds
  - Autoreleasepool effectiveness measurement
  - **Enhanced**: GC pause and allocator fragmentation analysis over multi-hour loads

- **Cleanup Validation Tests**
  - Verify aggressive memory cleanup between batches
  - Test garbage collection trigger effectiveness  
  - Memory leak detection during sustained processing
  - Resource cleanup on processing cancellation
  - **Enhanced**: Long-term memory leak detection (retain cycles in actors)

#### 3. Security Layer Tests
**Test Coverage**: RegulationSecurityService and comprehensive encryption

- **Encryption Correctness Tests**
  - AES-256-GCM encryption/decryption round-trip validation
  - Key derivation from iOS Keychain verification
  - Secure random IV generation uniqueness
  - Envelope encryption integrity validation
  - **Enhanced**: Cryptographic fuzzing for malformed key blobs and edge cases

- **Key Management Tests**
  - Key rotation without service disruption
  - Secure enclave integration verification
  - Emergency key recovery procedure validation
  - Dual-key support during rotation periods
  - **Enhanced**: Simultaneous key rotation + crash restart scenarios

- **Secure Deletion Tests**
  - Cryptographic erasure verification
  - Memory overwrite pattern validation
  - Failed processing data cleanup
  - Tamper detection and response
  - **Enhanced**: Property-based tests for constant-time comparators and side-channel analysis

- **Advanced Security Tests** (NEW)
  - Timing attack resistance verification with side-channel analysis
  - Mutation testing for secret leakage in logs/panic traces
  - Dependency vulnerability scanning for Swift Package Manager libraries
  - Threat model validation against OWASP Top 10
  - Penetration testing for inter-service communication surfaces

#### 4. Checkpoint and Durability Tests
**Test Coverage**: CheckpointManager, DeadLetterQueue, and recovery systems

- **Checkpoint Persistence Tests**
  - SQLite WAL checkpoint creation and restoration
  - Stage boundary checkpoint accuracy
  - Checkpoint serialization/deserialization integrity
  - Concurrent checkpoint access safety
  - **Enhanced**: Clock skew and leap-second issues affecting checkpoint timestamps

- **Recovery Mechanism Tests**
  - Complete pipeline recovery from any stage failure
  - Dead letter queue processing and retry logic
  - Circuit breaker activation and recovery
  - Data consistency during crash recovery
  - **Enhanced**: Actor cancellation mid-pipeline handling for half-processed document remnants

#### 5. Swift Concurrency and Actor Tests (NEW)
**Test Coverage**: Comprehensive concurrency validation

- **Actor Isolation Tests**
  - Actor re-entrancy and ordering bug detection
  - Thread-safe communication between all actors
  - Bounded message queue overflow handling
  - Message ordering preservation under load

- **Cancellation and Cleanup Tests**
  - Actor cancellation mid-pipeline scenarios
  - Resource cleanup during task cancellation
  - Cancellation token propagation through pipeline stages
  - Half-processed document state recovery

### Integration Tests

#### 1. End-to-End Pipeline Tests
**Test Coverage**: Complete processing workflow validation

- **Pipeline Coordination Tests**
  - AsyncChannel stage coordination with back-pressure
  - TaskGroup management for concurrent processing
  - Memory pressure propagation through pipeline
  - Progress reporting accuracy and real-time updates
  - **Enhanced**: Explicit AsyncChannel back-pressure simulation with slow consumers (CRITICAL PRIORITY)

- **Actor Communication Tests**
  - Thread-safe communication between all actors
  - Bounded channel overflow handling
  - Message ordering preservation
  - Error propagation through pipeline stages
  - **Enhanced**: Contract tests with LFM2Service mock enforcing real protocol versioning

- **Persistent Restart Tests** (NEW)
  - Stop pipeline mid-stream and reload continuation
  - Checkpoint-based recovery validation
  - State consistency across restart boundaries
  - Progress preservation and resumption

#### 2. LFM2Service Integration Tests
**Test Coverage**: Embedding generation and batch processing

- **Batch Processing Integration**
  - 400MB memory limit enforcement during embedding
  - Streaming embedding generation validation
  - Cooperative yielding effectiveness (every 100 ops)
  - Model loading and unloading efficiency
  - **Enhanced**: Cold-start vs warm-cache performance scenarios

- **Core ML Model Integration**
  - 768-dimension embedding generation accuracy
  - Processing latency <2 seconds per chunk
  - Model quantization effectiveness
  - Memory usage during inference
  - **Enhanced**: Scalability curves (docs/min as concurrency increases)

#### 3. ObjectBox Storage Integration Tests
**Test Coverage**: HNSW indexing and vector storage

- **Vector Storage Tests**
  - RegulationChunkEntity schema validation
  - HNSW index configuration for regulation namespace
  - Incremental index updates during processing
  - Schema migration compatibility
  - **Enhanced**: ObjectBox data corruption and schema migration path validation

- **Search Accuracy Tests**
  - Vector similarity search precision
  - Metadata filtering effectiveness
  - Search result ranking validation
  - Cross-regulation context retrieval
  - **Enhanced**: Duplicate document ID conflict resolution in ObjectBox

### Security Tests

#### 1. Comprehensive Security Validation
**Test Coverage**: Complete security framework validation

- **Cryptographic Security Tests**
  - AES-256-GCM implementation correctness
  - Key strength and randomness validation
  - Timing attack resistance verification
  - Side-channel attack prevention
  - **Enhanced**: Comprehensive cryptographic fuzzing with malformed inputs

- **Key Lifecycle Tests**
  - Key generation using secure random sources
  - Keychain storage and retrieval security
  - Key rotation schedule adherence (90-day default)
  - HSM integration for enterprise deployments
  - **Enhanced**: Key rotation under load and during system failures

#### 2. Advanced Threat Protection Tests (NEW)
**Test Coverage**: Protection against sophisticated attacks

- **Side-Channel Analysis**
  - Timing attack resistance for all cryptographic operations
  - Power analysis attack prevention
  - Cache timing attack mitigation
  - Constant-time algorithm validation

- **Supply Chain Security**
  - Dependency vulnerability scanning for all Swift Package Manager libraries
  - Third-party library risk assessment
  - Integrity validation of external dependencies
  - Security audit of package management processes

#### 3. Data Protection Tests
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
  - **Enhanced**: Data privacy compliance (GDPR data deletion) validation

### Performance Tests

#### 1. Throughput and Latency Tests
**Test Coverage**: Processing speed and responsiveness

- **Throughput Benchmarks**
  - 100+ documents/minute processing validation
  - Sustained processing performance over 1000+ docs
  - Memory usage stability during extended runs
  - CPU utilization optimization
  - **Enhanced**: Burst traffic pattern handling and load distribution

- **Latency Requirements**
  - <2 seconds per chunk embedding generation
  - <100ms ObjectBox insertion time
  - P99 latency <5 seconds for complete pipeline
  - Real-time progress reporting <200ms updates
  - **Enhanced**: Comprehensive variance analysis (p95, p99 latency across different document sizes)

#### 2. Long-Term Performance Validation Tests (NEW - CRITICAL)
**Test Coverage**: Sustained operation performance

- **Soak Tests**
  - 24-48 hour continuous processing validation
  - Memory leak detection over extended runs
  - Database connection pool exhaustion testing
  - File handle leak detection
  - Performance degradation tracking over time

- **Memory Drift Analysis**
  - Long-term memory usage pattern analysis
  - Fragmentation impact assessment
  - Resource accumulation detection
  - Performance decay curve measurement

#### 3. Resource Utilization Tests
**Test Coverage**: System resource management

- **Memory Constraint Validation**
  - Deterministic 400MB peak memory enforcement
  - Memory pressure response testing
  - Resource cleanup effectiveness measurement
  - Memory fragmentation impact assessment
  - **Enhanced**: Power/CPU throttling effects in containerized environments

- **Concurrent Processing Tests**
  - 10-concurrent chunk processing validation
  - Thread safety under high concurrency
  - Actor isolation effectiveness
  - Deadlock and race condition prevention

### Edge Cases and Error Scenarios

#### 1. Government HTML Document Variations (ENHANCED - HIGH PRIORITY)
**Test Coverage**: Comprehensive real-world document validation

- **Document Corpus Tests**
  - Curated corpus of diverse government HTML documents
  - Historical document format variations
  - Different government portal structures
  - Malformed and edge-case document handling
  - International regulation format variations

- **Content Complexity Tests**
  - Extremely large documents (multi-gigabyte processing)
  - Documents with no hierarchical structure
  - Mixed content types within documents
  - Embedded multimedia and binary data
  - Complex table and list structures

#### 2. HTML Parsing Edge Cases
**Test Coverage**: Robust parsing under adverse conditions

- **Malformed HTML Tests**
  - Government document formatting inconsistencies
  - Missing or incorrect tag closures
  - Invalid character encoding handling
  - Extremely large document processing
  - **Enhanced**: Character encoding variations (Latin-1, UTF-16 BOM, mixed encodings)

- **Content Variation Tests**
  - Empty documents and sections
  - Documents with no hierarchical structure
  - Extremely deep nesting (>5 levels)
  - Mixed content types within documents
  - **Enhanced**: PDF-in-HTML, embedded base64, JS-generated DOM content

#### 3. System Failure Scenarios
**Test Coverage**: Graceful degradation and recovery

- **Resource Exhaustion Tests**
  - Memory exhaustion handling
  - Disk space limitations
  - Network connectivity issues
  - Battery power constraints on mobile
  - **Enhanced**: External dependency failures (network latency spikes, TLS handshake issues)

- **Concurrent Failure Tests**
  - Multiple simultaneous component failures
  - Cascading failure prevention
  - Recovery from partial processing states
  - Data consistency during system failures

### Chaos Engineering Tests (ENHANCED)

#### 1. Advanced Fault Injection Tests
**Test Coverage**: Production-grade resilience validation

- **Multi-Component Failure Tests**
  - Simultaneous actor failure scenarios
  - Cascading failure chain validation
  - System-wide recovery capability testing
  - Data integrity under extreme conditions

- **Process Termination Tests**
  - Random process kills during processing
  - Checkpoint recovery validation
  - Data integrity after unexpected termination
  - Resume processing from last checkpoint

#### 2. Operational Resilience Tests (NEW)
**Test Coverage**: Real-world operational scenarios

- **Infrastructure Failure Simulation**
  - Disk full scenarios and recovery
  - Node reboot and restart procedures
  - Network partition handling
  - Database corruption recovery

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
- **Enhanced**: ✓ 24-48 hour sustained operation without performance degradation

### Quality Requirements Validation
- ✓ Maintain 95% chunk coherence
- ✓ Achieve 90% search relevance
- ✓ Provide 95% error recovery rate
- ✓ Ensure 100% security compliance
- ✓ Guarantee 99.9% durability
- **Enhanced**: ✓ Zero critical security vulnerabilities with comprehensive threat protection

### Operational Requirements Validation
- ✓ Complete observability with metrics
- ✓ Automated failure recovery
- ✓ Zero data loss on crash
- ✓ Key rotation without downtime
- **Enhanced**: ✓ Production-grade chaos engineering validation

## Code Review Integration

This testing rubric is integrated with comprehensive code review processes designed to enforce quality at every development phase.

### Review Criteria File
- **File**: `codeReview_regulation-processing-pipeline_guardian.md`
- **Coverage**: AST-grep patterns configured in `.claude/review-patterns.yml`
- **Integration**: All phases include progressive code quality validation
- **Standards**: Zero tolerance for critical security and quality issues

### Progressive Quality Gates
- **Dev Phase**: Focus on test creation and basic functionality
- **Green Phase**: Minimal passing implementation with security pattern validation
- **Refactor Phase**: Comprehensive code quality enforcement with zero-tolerance policy
- **QA Phase**: Production readiness validation with complete security audit

## Implementation Timeline

### Phase 1: Foundation Testing (Days 1-4)
- Unit tests for checkpoint infrastructure and durability
- SwiftSoup integration validation with fallback mechanisms
- Basic security layer testing with enhanced cryptographic validation
- **Enhanced**: Injectable clock implementation and test isolation infrastructure

### Phase 2: Core Engine Testing (Days 5-7)  
- Structure-aware chunking validation with government document corpus
- Memory management testing with long-term leak detection
- Boundary detection verification with encoding variations
- **Enhanced**: Actor concurrency testing with re-entrancy validation

### Phase 3: Integration Testing (Days 8-11)
- Pipeline coordination validation with explicit AsyncChannel back-pressure testing
- LFM2Service integration with contract validation
- ObjectBox storage verification with corruption recovery
- **Enhanced**: Persistent restart testing and protocol versioning validation

### Phase 4: Security and Performance Testing (Days 12-14)
- Comprehensive security audit with side-channel analysis
- Performance benchmarking with variance analysis
- Load testing with sustained operation validation  
- **Enhanced**: 24-48 hour soak tests and cryptographic fuzzing

### Phase 5: Chaos and Production Readiness Testing (Days 15-18)
- Advanced fault injection testing with multi-component failures
- Edge case validation with comprehensive document corpus
- Recovery scenario testing with operational resilience
- **Enhanced**: Production-grade chaos engineering with real-world failure simulation

## Testing Tools and Framework

### Enhanced Testing Infrastructure
- **XCTest Framework**: Core testing infrastructure with async/await patterns
- **Swift Testing**: Modern concurrency testing patterns  
- **Actor Testing**: Isolated actor behavior validation with re-entrancy detection
- **Memory Profiling**: Instruments integration for sustained memory validation
- **Performance Testing**: XCTMetric integration with p95/p99 analysis

### Enhanced Mock and Stub Strategy
- **SwiftSoup Mocking**: Controlled HTML parsing with encoding variation simulation
- **Core ML Mocking**: Deterministic embedding generation with performance profiling
- **ObjectBox Mocking**: Isolated storage behavior with corruption simulation
- **Injectable Clocks**: Deterministic time-based testing for checkpoint validation

### Production-Grade Continuous Integration
- **Automated Test Execution**: All tests run on every commit with coverage gates
- **Performance Regression Detection**: Automated benchmark comparison with alerting
- **Memory Leak Detection**: Sustained analysis with failure threshold enforcement  
- **Security Scan Integration**: Comprehensive static analysis with dependency scanning
- **Coverage Gates**: 90% differential coverage enforcement with automated failure

## Risk Mitigation Through Testing

### Critical Risk Areas (Enhanced Coverage)
1. **AsyncChannel Back-Pressure Failures**: Explicit slow consumer simulation and deadlock detection
2. **Long-Term Performance Degradation**: 24-48 hour soak testing with memory leak detection
3. **Government HTML Variations**: Comprehensive corpus-based validation with real-world documents
4. **Security Vulnerabilities**: Advanced threat protection with side-channel analysis
5. **System Resilience**: Production-grade chaos engineering with multi-component failures

### Enhanced Mitigation Strategies
- **Comprehensive Fuzzing**: Automated edge case discovery with cryptographic validation
- **Property-Based Testing**: Advanced invariant validation across all system components
- **Sustained Load Testing**: Extended operation validation with performance drift detection
- **Advanced Security Auditing**: Third-party penetration testing with threat modeling
- **Operational Resilience**: Real-world failure simulation with recovery validation

## Quality Gates

### Unit Test Gates
- 100% test passage required
- 95% code coverage minimum (enforced differentially)
- Zero memory leaks detected in sustained testing
- All security tests passing with zero vulnerabilities
- **Enhanced**: Zero actor re-entrancy bugs and concurrency issues

### Integration Test Gates
- End-to-end pipeline validation with AsyncChannel back-pressure testing
- Performance benchmarks met with p95/p99 latency validation
- Memory constraints validated under sustained load
- Durability guarantees verified with chaos engineering
- **Enhanced**: 24-48 hour sustained operation validation

### Production Readiness Gates
- Advanced chaos engineering tests passing with multi-component failures
- Comprehensive security audit completed with penetration testing
- Long-term performance validation successful with memory leak detection
- Complete documentation and operational runbooks validated
- **Enhanced**: Production-grade resilience certification with real-world failure simulation

## Appendix: Consensus Synthesis

### Key Improvements from Multi-Model Consensus

**Areas of Strong Agreement (100% consensus)**:
- AsyncChannel back-pressure testing identified as most critical gap requiring immediate attention
- Long-term performance degradation testing essential for production deployment
- Government HTML document corpus required for comprehensive edge case validation
- Chaos engineering depth insufficient without multi-component failure scenarios

**Critical Enhancements Applied**:
1. **Integration Testing**: AsyncChannel back-pressure simulation elevated to highest priority
2. **Performance**: 24-48 hour soak tests with p95/p99 latency analysis and memory drift detection  
3. **Security**: Side-channel analysis and cryptographic fuzzing for advanced threat protection
4. **Edge Cases**: Government document corpus and encoding variation comprehensive coverage
5. **Infrastructure**: Injectable clocks and deterministic test environments for reliable validation

**Consensus Confidence**: High (4/5 models successfully consulted)
- Gemini-2.5-Pro: 8/10 confidence (for stance)
- O3: 7/10 confidence (neutral stance)  
- O3-mini: 9/10 confidence (neutral stance)
- GPT-4.1: 8/10 confidence (for stance)

This enhanced testing rubric incorporates the collective expertise of multiple architectural perspectives, ensuring comprehensive validation coverage that addresses all identified critical gaps while maintaining production-ready quality standards.

---

**Document Status**: Enhanced through comprehensive multi-model consensus validation
**Next Steps**: Begin TDD implementation with `/dev` phase focusing on AsyncChannel back-pressure testing as highest priority

<!-- /tdd complete -->
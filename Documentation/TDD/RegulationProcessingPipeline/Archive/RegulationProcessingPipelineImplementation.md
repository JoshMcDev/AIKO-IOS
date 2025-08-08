# Implementation Plan: Regulation Processing Pipeline with Smart Chunking

## Document Metadata
- Task: Build Regulation Processing Pipeline with Smart Chunking
- Version: Enhanced v1.0
- Date: 2025-08-07
- Author: tdd-design-architect
- Consensus Method: Multi-model validation synthesis applied

## Consensus Enhancement Summary

Based on comprehensive multi-model consensus validation (5 models consulted), this enhanced implementation plan incorporates critical improvements identified across all perspectives:
- **Durability and persistence** between pipeline stages for crash recovery
- **Deterministic memory bounds** with semaphore control and mmap-backed buffers
- **Complete security implementation** with formal key management and rotation
- **Observability infrastructure** for production monitoring and debugging
- **Fallback mechanisms** for edge cases and graceful degradation

## Overview

This implementation plan provides a comprehensive technical design for the AIKO regulation processing pipeline that transforms HTML regulations into searchable vector embeddings. The system addresses the critical need for structure-aware chunking, memory-optimized batch processing, and secure on-device storage using Core ML and ObjectBox.

### Key Objectives
- Implement structure-aware hierarchical chunking preserving regulatory context
- Achieve <400MB memory footprint during batch processing with deterministic guarantees
- Process 100+ documents/minute on iPhone 14 Pro hardware
- Maintain 95% parent-child relationship retention in chunks
- Integrate seamlessly with existing LFM2Service and ObjectBox infrastructure
- Provide complete durability and observability for production deployment

## Architecture Impact

### Current State Analysis

The AIKO codebase currently has:
- **LFM2Service**: Actor-based embedding service with mock/real hybrid architecture (800MB memory management)
- **ObjectBoxSemanticIndex**: Vector database with HNSW indexing and dual-namespace support
- **RegulationProcessor**: Basic HTML processing with fixed-size chunking (512 tokens)
- **GraphRAGTypes**: Core type definitions for regulations and search domains
- **SwiftUI Architecture**: Observable patterns without TCA dependencies

### Proposed Changes

#### 1. Enhanced RegulationProcessor with Durability
Transform the existing basic processor into a structure-aware chunking engine with persistence:
- Replace regex-based HTML parsing with SwiftSoup integration
- Implement hierarchical element detection (h1, h2, h3, p, li)
- Add parent context preservation with 100-token overlap
- Create RegulationChunkHierarchy type for relationships
- **NEW**: Add checkpoint persistence between stages using SQLite WAL
- **NEW**: Implement dead-letter queue for failed chunks

#### 2. Pipeline Coordinator Actor with Back-Pressure
Create `RegulationPipelineCoordinator` actor for orchestration:
- AsyncChannel-based stage coordination with bounded buffers
- TaskGroup management for 10-concurrent chunk processing
- Memory pressure monitoring with dynamic batch sizing
- Progress reporting with pause/resume capability
- **NEW**: Semaphore-based memory bounds (max 512 chunks in-flight)
- **NEW**: Circuit breaker pattern for cascading failure prevention
- **NEW**: Distributed tracing integration for observability

#### 3. Memory-Optimized Batch Processing with Guarantees
Enhance LFM2Service batch processing with deterministic limits:
- Reduce memory target from 800MB to 400MB
- Implement streaming embedding generation
- Add cooperative yielding every 100 operations
- Create memory-bounded buffers with LRU eviction
- **NEW**: Mmap-backed ring buffers for memory overflow
- **NEW**: Predictive size estimation for batch planning
- **NEW**: Autoreleasepool usage for aggressive cleanup

#### 4. Security Layer Implementation with Key Management
Add `RegulationSecurityService` for comprehensive encryption:
- AES-256-GCM encryption for embeddings at rest
- iOS Keychain integration for key management
- Secure wipe protocols for failed processing
- Audit logging for compliance tracking
- **NEW**: Key rotation schedule (90-day default)
- **NEW**: HSM support for enterprise deployments
- **NEW**: Secure enclave usage for key operations
- **NEW**: Envelope encryption for multi-layer security

### Integration Points

1. **SwiftSoup Integration with Fallbacks**
   - New dependency in Package.swift
   - Platform-specific guards for iOS/macOS compatibility
   - Error handling for malformed HTML
   - **NEW**: Fallback flat-chunking mode for parse failures
   - **NEW**: Fuzz testing framework for HTML resilience

2. **AsyncChannel Coordination with Durability**
   - Import Swift Async Algorithms package
   - Create pipeline stages as AsyncSequence
   - Implement back-pressure mechanisms
   - **NEW**: Bounded channel buffers with overflow handling
   - **NEW**: Checkpoint persistence at stage boundaries

3. **ObjectBox Extensions with Migration**
   - Add RegulationChunkEntity with hierarchy metadata
   - Extend HNSW configuration for regulation namespace
   - Implement version tracking for updates
   - **NEW**: Schema migration framework
   - **NEW**: Backward compatibility layer

4. **LFM2Service Enhancements with Monitoring**
   - Add regulation-specific preprocessing
   - Optimize batch processing for 400MB limit
   - Implement incremental index updates
   - **NEW**: Memory watermark tracking
   - **NEW**: Performance metrics collection

## Implementation Details

### Components

#### 1. Structure-Aware Chunking Engine with Validation

```swift
actor StructureAwareChunker {
    struct ChunkingConfiguration {
        let targetTokenSize: Int = 512
        let overlapTokens: Int = 100
        let minChunkSize: Int = 100
        let maxChunkSize: Int = 1000
        let preserveHierarchy: Bool = true
        let fallbackToFlat: Bool = true // NEW: Enable fallback mode
        let maxDepth: Int = 5 // NEW: Depth limit for hierarchy
    }
    
    struct HierarchicalChunk {
        let id: UUID // NEW: Unique identifier for idempotency
        let content: String
        let chunkIndex: Int
        let hierarchyPath: [String] // ["FAR 15.2", "Solicitation", "(a)"]
        let parentHeading: String?
        let depth: Int
        let elementType: HTMLElementType
        let tokenCount: Int
        let checksum: String // NEW: For validation
    }
    
    func chunkDocument(html: String, config: ChunkingConfiguration) async throws -> [HierarchicalChunk]
    func validateChunkBoundaries(_ chunks: [HierarchicalChunk]) -> ChunkValidationResult // NEW
}
```

#### 2. Pipeline Coordinator with Durability

```swift
actor RegulationPipelineCoordinator {
    // Bounded channels with persistence
    private let htmlProcessor: AsyncChannel<HTMLDocument>
    private let chunker: AsyncChannel<RegulationChunk>
    private let embedder: AsyncChannel<ChunkWithEmbedding>
    private let storage: AsyncChannel<StorageResult>
    
    // NEW: Durability components
    private let checkpointManager: CheckpointManager
    private let deadLetterQueue: DeadLetterQueue
    private let circuitBreaker: CircuitBreaker
    
    // NEW: Memory control
    private let memorySemaphore = AsyncSemaphore(value: 512)
    
    func processRegulations(documents: [URL]) async throws -> ProcessingResult {
        // Four-stage pipeline with bounded buffers and checkpoints
        // Stage 1: HTML parsing with SwiftSoup
        // Stage 2: Structure-aware chunking with validation
        // Stage 3: Batch embedding generation with memory bounds
        // Stage 4: ObjectBox storage with HNSW indexing
        // Each stage persists progress for recovery
    }
    
    // NEW: Recovery methods
    func recoverFromCheckpoint(_ checkpoint: PipelineCheckpoint) async throws
    func handleDeadLetterItem(_ item: DeadLetterItem) async throws
}
```

#### 3. Memory Management Strategy with Guarantees

```swift
actor MemoryOptimizedBatchProcessor {
    private let memoryMonitor = MemoryMonitor()
    private let maxMemoryMB: Int64 = 400
    
    // NEW: Deterministic memory control
    private let mmapBuffer: MmapRingBuffer
    private let sizePredictor: DocumentSizePredictor
    
    func processBatchWithMemoryLimit(chunks: [RegulationChunk]) async throws -> [EmbeddingResult] {
        // Dynamic batch sizing based on available memory
        // Streaming processing with bounded buffers
        // Automatic cleanup and garbage collection
        // Memory pressure callbacks
        
        // NEW: Predictive sizing
        let estimatedSize = await sizePredictor.estimate(chunks)
        
        // NEW: Overflow to mmap if needed
        if estimatedSize > availableMemory {
            return try await processWithMmapBuffer(chunks)
        }
        
        // NEW: Aggressive cleanup
        return try await autoreleasepool {
            // Process batch with memory tracking
        }
    }
}
```

#### 4. Security Implementation with Complete Key Management

```swift
actor RegulationSecurityService {
    // NEW: Key management components
    private let keyRotationScheduler: KeyRotationScheduler
    private let secureEnclaveManager: SecureEnclaveManager
    private let auditLogger: SecurityAuditLogger
    
    func encryptEmbedding(_ embedding: [Float], regulationId: String) async throws -> EncryptedData {
        // AES-256-GCM encryption
        // Key derivation from iOS Keychain
        // Secure random IV generation
        
        // NEW: Envelope encryption
        let dataKey = try await generateDataKey()
        let encryptedData = try encrypt(embedding, with: dataKey)
        let encryptedKey = try await secureEnclaveManager.wrap(dataKey)
        
        // NEW: Audit logging
        await auditLogger.logEncryption(regulationId: regulationId)
        
        return EnvelopeEncryptedData(data: encryptedData, key: encryptedKey)
    }
    
    func secureWipe(data: inout Data) {
        // Cryptographic erasure
        // Memory overwrite patterns
        // Verification pass
    }
    
    // NEW: Key rotation
    func rotateKeys() async throws {
        // Rotate master keys
        // Re-encrypt data keys
        // Update keychain
    }
}
```

### Data Models

#### Enhanced Regulation Types with Durability

```swift
struct RegulationChunkHierarchy {
    let chunk: RegulationChunk
    let parent: RegulationChunk?
    let children: [RegulationChunk]
    let hierarchyLevel: Int
    let contextWindow: String // Combined parent + current + preview
    let processingState: ProcessingState // NEW: For checkpoint recovery
}

struct ProcessedRegulationDocument {
    let sourceURL: URL
    let chunks: [HierarchicalChunk]
    let metadata: EnhancedRegulationMetadata
    let processingStats: ProcessingStatistics
    let version: String
    let checksum: String
    let checkpoint: DocumentCheckpoint // NEW: Recovery information
}

// NEW: Checkpoint types
struct PipelineCheckpoint: Codable {
    let documentId: String
    let stage: PipelineStage
    let processedChunks: Set<UUID>
    let timestamp: Date
    let memorySnapshot: MemorySnapshot
}

struct DeadLetterItem: Codable {
    let chunkId: UUID
    let failureReason: String
    let retryCount: Int
    let originalContent: Data
}
```

### API Design

#### Public Interface with Observability

```swift
public protocol RegulationProcessingPipeline {
    func processHTMLRegulations(urls: [URL]) async throws -> ProcessingResult
    func pauseProcessing() async
    func resumeProcessing() async
    func cancelProcessing() async
    func getProgress() async -> ProcessingProgress
    
    // NEW: Recovery and monitoring
    func recoverFromFailure() async throws
    func getHealthStatus() async -> HealthStatus
    func getMetrics() async -> PipelineMetrics
}

public struct ProcessingProgress {
    let totalDocuments: Int
    let processedDocuments: Int
    let currentDocument: String?
    let chunksProcessed: Int
    let estimatedTimeRemaining: TimeInterval
    let memoryUsageMB: Double
    let checkpointState: CheckpointState // NEW
}

// NEW: Health and metrics
public struct HealthStatus {
    let isHealthy: Bool
    let circuitBreakerState: CircuitBreakerState
    let memoryPressure: MemoryPressureLevel
    let deadLetterQueueSize: Int
}

public struct PipelineMetrics {
    let throughput: Double // docs/minute
    let averageLatency: TimeInterval
    let p99Latency: TimeInterval
    let errorRate: Double
    let memoryHighWaterMark: Int64
}
```

### Testing Strategy

#### Comprehensive Test Coverage

1. **Unit Tests Required**
   - Hierarchy preservation validation
   - Boundary detection accuracy
   - Token counting precision
   - Edge case handling (malformed HTML, extreme sizes)
   - **NEW**: Checkpoint serialization/deserialization
   - **NEW**: Memory predictor accuracy
   - **NEW**: Key rotation correctness

2. **Integration Tests**
   - End-to-end pipeline with recovery
   - Verify chunk hierarchy in ObjectBox
   - Validate search accuracy
   - Measure performance metrics
   - **NEW**: Crash recovery scenarios
   - **NEW**: Circuit breaker activation
   - **NEW**: Dead letter processing

3. **Security Tests**
   - Encryption correctness
   - Key management security
   - Secure wipe verification
   - Audit log integrity
   - **NEW**: Key rotation during processing
   - **NEW**: Timing attack resistance
   - **NEW**: Tamper detection

4. **Performance Tests**
   - Peak memory validation (<400MB)
   - Cleanup effectiveness
   - Memory pressure response
   - Batch size adaptation
   - **NEW**: Mmap buffer performance
   - **NEW**: Sustained load testing
   - **NEW**: Long-tail latency analysis

5. **Chaos Engineering Tests** (NEW)
   - Random process kills
   - Memory exhaustion simulation
   - Network partition handling
   - Concurrent failure scenarios

## Implementation Steps

### Phase 1: Foundation with Durability (Days 1-4)
1. **SwiftSoup Integration with Fallbacks**
   - Add package dependency
   - Create HTMLProcessor implementation
   - Build element extraction logic
   - Add error handling
   - Implement fallback flat-chunking mode

2. **Checkpoint Infrastructure**
   - Design checkpoint schema
   - Implement SQLite WAL persistence
   - Create recovery manager
   - Add dead letter queue

### Phase 2: Chunking Engine with Validation (Days 5-7)
3. **Hierarchical Chunker**
   - Implement boundary detection
   - Add context preservation
   - Create overlap management
   - Build chunk validation
   - Add depth limiting

4. **Memory Optimization with Guarantees**
   - Implement memory monitoring
   - Add dynamic batch sizing
   - Create cleanup strategies
   - Build pressure response
   - Implement mmap buffers
   - Add size prediction

### Phase 3: Pipeline Integration with Observability (Days 8-11)
5. **AsyncChannel Pipeline with Durability**
   - Create stage coordination
   - Implement back-pressure
   - Add progress tracking
   - Build cancellation support
   - Add checkpoint persistence
   - Implement circuit breakers

6. **Batch Processing with Monitoring**
   - Integrate with LFM2Service
   - Optimize for 400MB limit
   - Add streaming support
   - Implement yielding
   - Add metrics collection
   - Create health checks

### Phase 4: Storage & Security with Key Management (Days 12-14)
7. **ObjectBox Integration with Migration**
   - Extend entity models
   - Configure HNSW indexing
   - Add version tracking
   - Implement incremental updates
   - Create migration framework

8. **Security Layer with Complete Implementation**
   - Implement AES-256-GCM
   - Add Keychain integration
   - Create secure wipe
   - Build audit logging
   - Implement key rotation
   - Add secure enclave support

### Phase 5: Testing & Production Hardening (Days 15-18)
9. **Comprehensive Testing**
   - Unit test coverage
   - Integration testing
   - Performance validation
   - Security audit
   - Chaos engineering
   - Fuzz testing

10. **Production Readiness**
    - Performance tuning
    - Observability setup
    - Documentation
    - Deployment automation
    - Monitoring dashboards
    - Alert configuration

## Risk Assessment

### Technical Risks

1. **Memory Constraint Challenge** (High)
   - Risk: 400MB limit with LFM2 model overhead
   - Mitigation: Streaming processing, model quantization, aggressive cleanup
   - **Enhanced**: Mmap buffers, predictive sizing, semaphore control
   - Contingency: Reduce batch size, implement model unloading

2. **HTML Parsing Complexity** (Medium)
   - Risk: Malformed government HTML breaking parser
   - Mitigation: SwiftSoup robustness, fallback strategies
   - **Enhanced**: Fuzz testing, flat-chunking fallback, depth limiting
   - Contingency: Manual validation, user feedback loop

3. **Pipeline Durability** (Medium) - NEW
   - Risk: Data loss on crash or failure
   - Mitigation: Checkpoint persistence, WAL, dead letter queue
   - Contingency: Manual recovery tools, replay capability

### Performance Risks

1. **Throughput Target** (Medium)
   - Risk: 100 docs/minute on iPhone 14 Pro
   - Mitigation: Batch optimization, parallel processing
   - **Enhanced**: Predictive batching, memory pre-allocation
   - Contingency: Adjust target, optimize further

2. **Latency Variability** (Low) - NEW
   - Risk: Long-tail latency affecting user experience
   - Mitigation: P99 monitoring, timeout controls
   - Contingency: Adaptive timeout adjustment

### Security Risks

1. **Key Management Complexity** (Medium) - NEW
   - Risk: Key rotation causing service disruption
   - Mitigation: Gradual rotation, dual-key support
   - Contingency: Emergency key recovery procedure

## Timeline Estimate

### Development Phases
- **Phase 1 (Foundation)**: 4 days
- **Phase 2 (Chunking)**: 3 days  
- **Phase 3 (Pipeline)**: 4 days
- **Phase 4 (Storage/Security)**: 3 days
- **Phase 5 (Testing/Hardening)**: 4 days

### Total Estimate: 18 days (3.5 weeks)

### Critical Path
1. Checkpoint infrastructure → Recovery capability
2. SwiftSoup integration → HTML processing
3. Structure detection → Hierarchical chunking
4. AsyncChannel setup → Pipeline coordination
5. Memory optimization → Batch processing
6. Security implementation → Production readiness

### Milestones
- Day 4: Durability infrastructure operational
- Day 7: Hierarchical chunking with validation complete
- Day 11: Pipeline processing with observability
- Day 14: Security and storage fully integrated
- Day 18: All tests passing, production ready

## Success Criteria

1. **Functional Requirements**
   - ✓ Process FAR/DFARS HTML documents
   - ✓ Preserve 95% hierarchical relationships
   - ✓ Generate 768-dim embeddings
   - ✓ Store in ObjectBox with metadata
   - ✓ Recover from failures without data loss

2. **Performance Requirements**
   - ✓ 100+ documents/minute throughput
   - ✓ <400MB peak memory usage (deterministic)
   - ✓ <2 seconds per chunk embedding
   - ✓ <100ms ObjectBox insertion
   - ✓ P99 latency <5 seconds

3. **Quality Requirements**
   - ✓ 95% chunk coherence
   - ✓ 90% search relevance
   - ✓ 95% error recovery rate
   - ✓ 100% security compliance
   - ✓ 99.9% durability guarantee

4. **Operational Requirements** (NEW)
   - ✓ Full observability with metrics
   - ✓ Automated failure recovery
   - ✓ Zero data loss on crash
   - ✓ Key rotation without downtime

## Dependencies and Prerequisites

1. **Required Packages**
   - SwiftSoup (HTML parsing)
   - Swift Async Algorithms (pipeline coordination)
   - SQLite (checkpoint persistence)
   - Existing: MLX Swift, ObjectBox

2. **Team Dependencies**
   - LFM2Service team for integration points
   - Security team for encryption review
   - QA team for test data preparation
   - DevOps team for monitoring setup

3. **Infrastructure**
   - Test devices (iPhone 14 Pro minimum)
   - Sample regulation documents
   - Performance profiling tools
   - Monitoring infrastructure

## Appendix: Consensus Synthesis

### Key Improvements from Multi-Model Consensus

**Areas of Strong Agreement (>90%)**:
- Actor-based architecture with AsyncChannel is sound
- 400MB memory constraint is the critical challenge
- Hierarchical chunking provides significant value
- Security implementation needs key management formalization

**Critical Enhancements Applied**:
1. **Durability**: Added checkpoint persistence, WAL, dead letter queue
2. **Memory**: Implemented deterministic bounds, mmap buffers, predictive sizing
3. **Security**: Formalized key rotation, HSM support, secure enclave
4. **Observability**: Added metrics, tracing, health checks
5. **Resilience**: Implemented circuit breakers, fallback modes, recovery

**Risk Mitigations Added**:
- Fuzz testing for HTML parser resilience
- Chaos engineering for production hardening
- Schema migration framework for compatibility
- Gradual key rotation for zero-downtime updates

This enhanced implementation plan incorporates the collective wisdom of multiple architectural perspectives, ensuring a robust, production-ready solution that addresses all identified risks while maintaining the original performance and quality objectives.

---

**Document Status**: Enhanced through comprehensive consensus validation
**Next Steps**: Begin Phase 1 implementation with durability infrastructure
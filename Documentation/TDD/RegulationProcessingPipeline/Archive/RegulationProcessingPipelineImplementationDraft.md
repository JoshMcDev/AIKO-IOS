# Implementation Plan: Regulation Processing Pipeline with Smart Chunking

## Document Metadata
- Task: Build Regulation Processing Pipeline with Smart Chunking
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-design-architect
- Status: Initial Draft (Pre-Consensus)

## Overview

This implementation plan provides a comprehensive technical design for the AIKO regulation processing pipeline that transforms HTML regulations into searchable vector embeddings. The system addresses the critical need for structure-aware chunking, memory-optimized batch processing, and secure on-device storage using Core ML and ObjectBox.

### Key Objectives
- Implement structure-aware hierarchical chunking preserving regulatory context
- Achieve <400MB memory footprint during batch processing
- Process 100+ documents/minute on iPhone 14 Pro hardware
- Maintain 95% parent-child relationship retention in chunks
- Integrate seamlessly with existing LFM2Service and ObjectBox infrastructure

## Architecture Impact

### Current State Analysis

The AIKO codebase currently has:
- **LFM2Service**: Actor-based embedding service with mock/real hybrid architecture (800MB memory management)
- **ObjectBoxSemanticIndex**: Vector database with HNSW indexing and dual-namespace support
- **RegulationProcessor**: Basic HTML processing with fixed-size chunking (512 tokens)
- **GraphRAGTypes**: Core type definitions for regulations and search domains
- **SwiftUI Architecture**: Observable patterns without TCA dependencies

### Proposed Changes

#### 1. Enhanced RegulationProcessor
Transform the existing basic processor into a structure-aware chunking engine:
- Replace regex-based HTML parsing with SwiftSoup integration
- Implement hierarchical element detection (h1, h2, h3, p, li)
- Add parent context preservation with 100-token overlap
- Create RegulationChunkHierarchy type for relationships

#### 2. New Pipeline Coordinator Actor
Create `RegulationPipelineCoordinator` actor for orchestration:
- AsyncChannel-based stage coordination
- TaskGroup management for 10-concurrent chunk processing
- Memory pressure monitoring with dynamic batch sizing
- Progress reporting with pause/resume capability

#### 3. Memory-Optimized Batch Processing
Enhance LFM2Service batch processing:
- Reduce memory target from 800MB to 400MB
- Implement streaming embedding generation
- Add cooperative yielding every 100 operations
- Create memory-bounded buffers with LRU eviction

#### 4. Security Layer Implementation
Add `RegulationSecurityService` for encryption:
- AES-256-GCM encryption for embeddings at rest
- iOS Keychain integration for key management
- Secure wipe protocols for failed processing
- Audit logging for compliance tracking

### Integration Points

1. **SwiftSoup Integration**
   - New dependency in Package.swift
   - Platform-specific guards for iOS/macOS compatibility
   - Error handling for malformed HTML

2. **AsyncChannel Coordination**
   - Import Swift Async Algorithms package
   - Create pipeline stages as AsyncSequence
   - Implement back-pressure mechanisms

3. **ObjectBox Extensions**
   - Add RegulationChunkEntity with hierarchy metadata
   - Extend HNSW configuration for regulation namespace
   - Implement version tracking for updates

4. **LFM2Service Enhancements**
   - Add regulation-specific preprocessing
   - Optimize batch processing for 400MB limit
   - Implement incremental index updates

## Implementation Details

### Components

#### 1. Structure-Aware Chunking Engine

```swift
actor StructureAwareChunker {
    struct ChunkingConfiguration {
        let targetTokenSize: Int = 512
        let overlapTokens: Int = 100
        let minChunkSize: Int = 100
        let maxChunkSize: Int = 1000
        let preserveHierarchy: Bool = true
    }
    
    struct HierarchicalChunk {
        let content: String
        let chunkIndex: Int
        let hierarchyPath: [String] // ["FAR 15.2", "Solicitation", "(a)"]
        let parentHeading: String?
        let depth: Int
        let elementType: HTMLElementType
        let tokenCount: Int
    }
    
    func chunkDocument(html: String, config: ChunkingConfiguration) async throws -> [HierarchicalChunk]
}
```

#### 2. Pipeline Coordinator

```swift
actor RegulationPipelineCoordinator {
    private let htmlProcessor: AsyncChannel<HTMLDocument>
    private let chunker: AsyncChannel<RegulationChunk>
    private let embedder: AsyncChannel<ChunkWithEmbedding>
    private let storage: AsyncChannel<StorageResult>
    
    func processRegulations(documents: [URL]) async throws -> ProcessingResult {
        // Three-stage pipeline with bounded buffers
        // Stage 1: HTML parsing with SwiftSoup
        // Stage 2: Structure-aware chunking
        // Stage 3: Batch embedding generation
        // Stage 4: ObjectBox storage with HNSW indexing
    }
}
```

#### 3. Memory Management Strategy

```swift
actor MemoryOptimizedBatchProcessor {
    private let memoryMonitor = MemoryMonitor()
    private let maxMemoryMB: Int64 = 400
    
    func processBatchWithMemoryLimit(chunks: [RegulationChunk]) async throws -> [EmbeddingResult] {
        // Dynamic batch sizing based on available memory
        // Streaming processing with bounded buffers
        // Automatic cleanup and garbage collection
        // Memory pressure callbacks
    }
}
```

#### 4. Security Implementation

```swift
actor RegulationSecurityService {
    func encryptEmbedding(_ embedding: [Float], regulationId: String) async throws -> EncryptedData {
        // AES-256-GCM encryption
        // Key derivation from iOS Keychain
        // Secure random IV generation
    }
    
    func secureWipe(data: inout Data) {
        // Cryptographic erasure
        // Memory overwrite patterns
        // Verification pass
    }
}
```

### Data Models

#### Enhanced Regulation Types

```swift
struct RegulationChunkHierarchy {
    let chunk: RegulationChunk
    let parent: RegulationChunk?
    let children: [RegulationChunk]
    let hierarchyLevel: Int
    let contextWindow: String // Combined parent + current + preview
}

struct ProcessedRegulationDocument {
    let sourceURL: URL
    let chunks: [HierarchicalChunk]
    let metadata: EnhancedRegulationMetadata
    let processingStats: ProcessingStatistics
    let version: String
    let checksum: String
}

struct EnhancedRegulationMetadata {
    let regulationNumber: String
    let title: String
    let subparts: [String]
    let effectiveDate: Date?
    let lastUpdated: Date
    let documentStructure: DocumentStructure
}
```

### API Design

#### Public Interface

```swift
public protocol RegulationProcessingPipeline {
    func processHTMLRegulations(urls: [URL]) async throws -> ProcessingResult
    func pauseProcessing() async
    func resumeProcessing() async
    func cancelProcessing() async
    func getProgress() async -> ProcessingProgress
}

public struct ProcessingProgress {
    let totalDocuments: Int
    let processedDocuments: Int
    let currentDocument: String?
    let chunksProcessed: Int
    let estimatedTimeRemaining: TimeInterval
    let memoryUsageMB: Double
}
```

#### Internal Protocols

```swift
protocol HTMLProcessor {
    func extractStructuredContent(from html: String) async throws -> StructuredDocument
}

protocol ChunkingStrategy {
    func chunk(document: StructuredDocument) async throws -> [HierarchicalChunk]
}

protocol EmbeddingBatchProcessor {
    func generateEmbeddings(for chunks: [RegulationChunk]) async throws -> [EmbeddingResult]
}
```

### Testing Strategy

#### Unit Tests Required

1. **Chunking Algorithm Tests**
   - Hierarchy preservation validation
   - Boundary detection accuracy
   - Token counting precision
   - Edge case handling (malformed HTML, extreme sizes)

2. **Memory Management Tests**
   - Peak memory validation (<400MB)
   - Cleanup effectiveness
   - Memory pressure response
   - Batch size adaptation

3. **Security Tests**
   - Encryption correctness
   - Key management security
   - Secure wipe verification
   - Audit log integrity

#### Integration Test Scenarios

1. **End-to-End Pipeline**
   - Process sample FAR documents
   - Verify chunk hierarchy in ObjectBox
   - Validate search accuracy
   - Measure performance metrics

2. **Concurrency Tests**
   - 10-concurrent chunk processing
   - Race condition detection
   - Deadlock prevention
   - Progress tracking accuracy

3. **Error Recovery Tests**
   - Network interruption handling
   - Malformed HTML recovery
   - Memory pressure response
   - Checkpoint restoration

#### Test Data Requirements

- Sample FAR/DFARS HTML documents (minimum 10)
- Malformed HTML test cases
- Large regulation documents (>1MB)
- Hierarchically complex documents
- Edge case documents (tables, lists, nested sections)

## Implementation Steps

### Phase 1: Foundation (Days 1-3)
1. **SwiftSoup Integration**
   - Add package dependency
   - Create HTMLProcessor implementation
   - Build element extraction logic
   - Add error handling

2. **Structure Detection**
   - Implement hierarchy analyzer
   - Create element type detection
   - Build parent-child mapping
   - Add depth calculation

### Phase 2: Chunking Engine (Days 4-6)
3. **Hierarchical Chunker**
   - Implement boundary detection
   - Add context preservation
   - Create overlap management
   - Build chunk validation

4. **Memory Optimization**
   - Implement memory monitoring
   - Add dynamic batch sizing
   - Create cleanup strategies
   - Build pressure response

### Phase 3: Pipeline Integration (Days 7-9)
5. **AsyncChannel Pipeline**
   - Create stage coordination
   - Implement back-pressure
   - Add progress tracking
   - Build cancellation support

6. **Batch Processing**
   - Integrate with LFM2Service
   - Optimize for 400MB limit
   - Add streaming support
   - Implement yielding

### Phase 4: Storage & Security (Days 10-12)
7. **ObjectBox Integration**
   - Extend entity models
   - Configure HNSW indexing
   - Add version tracking
   - Implement incremental updates

8. **Security Layer**
   - Implement AES-256-GCM
   - Add Keychain integration
   - Create secure wipe
   - Build audit logging

### Phase 5: Testing & Optimization (Days 13-15)
9. **Comprehensive Testing**
   - Unit test coverage
   - Integration testing
   - Performance validation
   - Security audit

10. **Performance Tuning**
    - Profile memory usage
    - Optimize bottlenecks
    - Tune batch sizes
    - Validate targets

## Risk Assessment

### Technical Risks

1. **Memory Constraint Challenge** (High)
   - Risk: 400MB limit with LFM2 model overhead
   - Mitigation: Streaming processing, model quantization, aggressive cleanup
   - Contingency: Reduce batch size, implement model unloading

2. **HTML Parsing Complexity** (Medium)
   - Risk: Malformed government HTML breaking parser
   - Mitigation: SwiftSoup robustness, fallback strategies
   - Contingency: Regex-based extraction for failures

3. **Hierarchical Chunking Accuracy** (Medium)
   - Risk: Context loss in complex regulatory structures
   - Mitigation: Extensive testing, adjustable overlap
   - Contingency: Manual validation, user feedback loop

### Performance Risks

1. **Throughput Target** (Medium)
   - Risk: 100 docs/minute on iPhone 14 Pro
   - Mitigation: Batch optimization, parallel processing
   - Contingency: Adjust target, optimize further

2. **Embedding Latency** (Low)
   - Risk: 2-second target per chunk
   - Mitigation: LFM2 optimizations already validated
   - Contingency: Reduce embedding dimensions

### Integration Risks

1. **ObjectBox Compatibility** (Low)
   - Risk: Vector storage performance
   - Mitigation: HNSW tuning, batch insertions
   - Contingency: Alternative index configuration

2. **SwiftSoup Platform Support** (Low)
   - Risk: iOS/macOS compatibility
   - Mitigation: Platform guards, testing
   - Contingency: Alternative HTML parser

## Timeline Estimate

### Development Phases
- **Phase 1 (Foundation)**: 3 days
- **Phase 2 (Chunking)**: 3 days  
- **Phase 3 (Pipeline)**: 3 days
- **Phase 4 (Storage/Security)**: 3 days
- **Phase 5 (Testing)**: 3 days

### Total Estimate: 15 days (3 weeks)

### Critical Path
1. SwiftSoup integration → HTML processing
2. Structure detection → Hierarchical chunking
3. AsyncChannel setup → Pipeline coordination
4. Memory optimization → Batch processing
5. Security implementation → Production readiness

### Milestones
- Day 3: HTML processing operational
- Day 6: Hierarchical chunking complete
- Day 9: Pipeline processing documents
- Day 12: Security and storage integrated
- Day 15: All tests passing, performance validated

## Success Criteria

1. **Functional Requirements**
   - ✓ Process FAR/DFARS HTML documents
   - ✓ Preserve 95% hierarchical relationships
   - ✓ Generate 768-dim embeddings
   - ✓ Store in ObjectBox with metadata

2. **Performance Requirements**
   - ✓ 100+ documents/minute throughput
   - ✓ <400MB peak memory usage
   - ✓ <2 seconds per chunk embedding
   - ✓ <100ms ObjectBox insertion

3. **Quality Requirements**
   - ✓ 95% chunk coherence
   - ✓ 90% search relevance
   - ✓ 95% error recovery rate
   - ✓ 100% security compliance

## Dependencies and Prerequisites

1. **Required Packages**
   - SwiftSoup (HTML parsing)
   - Swift Async Algorithms (pipeline coordination)
   - Existing: MLX Swift, ObjectBox

2. **Team Dependencies**
   - LFM2Service team for integration points
   - Security team for encryption review
   - QA team for test data preparation

3. **Infrastructure**
   - Test devices (iPhone 14 Pro minimum)
   - Sample regulation documents
   - Performance profiling tools

## Next Steps

1. Gather consensus feedback on this implementation plan
2. Refine based on multi-model perspectives
3. Create detailed technical specifications
4. Begin Phase 1 implementation
5. Establish testing framework

---

This implementation plan will be enhanced through consensus validation to ensure alignment with best practices and project requirements.
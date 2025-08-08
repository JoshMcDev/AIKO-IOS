# Implementation Plan: ACQ Templates Processing and Embedding

## Document Metadata
- Task: Implement Launch-Time ACQ Templates Processing and Embedding
- Version: Enhanced v1.0
- Date: 2025-08-08
- Author: tdd-design-architect
- Consensus Method: VanillaIce consensus synthesis applied
- Research Foundation: 5 comprehensive research documents integrated

## Consensus Enhancement Summary
This implementation plan has been enhanced through VanillaIce consensus validation (GPT-5) with critical improvements to memory management, search architecture, and risk mitigation. Key enhancements include: strict memory permit system, reduced chunk sizes (2-4MB), hybrid lexical+vector search approach, and phased implementation strategy to validate memory constraints early.

## Overview

This implementation plan translates the validated PRD requirements for ACQ Templates Processing into a detailed technical design that seamlessly integrates with AIKO's existing GraphRAG infrastructure. The system will process 256MB of acquisition templates using a memory-constrained chunked approach (2-4MB chunks), generate LFM2 embeddings, and store them in ObjectBox with optimized HNSW indexing for sub-10ms search response times.

The implementation leverages AIKO's production-ready foundation including LFM2Service, ObjectBoxSemanticIndex, and RegulationProcessor, extending them with template-specific capabilities while maintaining Swift 6 strict concurrency compliance and SwiftUI + @Observable patterns.

**Critical Constraint**: The 50MB peak memory limit is the primary architectural driver, requiring strict memory accounting, reduced concurrency, and hybrid search strategies.

## Architecture Impact

### Current State Analysis

AIKO v6.2 has established a robust GraphRAG foundation:
- **RegulationProcessor**: Structure-aware chunking with 512-token segments
- **LFM2Service**: Actor-based embedding generation with memory management
- **ObjectBoxSemanticIndex**: Mock-first vector database with production migration path
- **BackgroundRegulationProcessor**: Swift 6 concurrent processing pipeline
- **UnifiedSearchService**: Cross-domain search infrastructure

### Proposed Changes

1. **Memory-Constrained Pipeline**: Single-chunk-in-flight policy with global memory permits
2. **Hybrid Search Architecture**: BM25 prefilter + exact cosine reranking (avoiding full HNSW in memory)
3. **Reduced Embedding Dimensions**: 384-dimensional embeddings vs 768 to reduce memory footprint
4. **Sharded Index Strategy**: Category-based sharding with selective warm cache
5. **Strict Concurrency Control**: 1 reader, 1 embedder, 1 writer with backpressure

### Integration Points

- **LFM2Service**: Direct integration with dimension reduction strategy
- **ObjectBoxSemanticIndex**: Extension with memory-mapped template storage
- **BackgroundRegulationProcessor**: Shared patterns with stricter memory controls
- **UnifiedSearchService**: Enhanced with lexical prefilter stage
- **FormAutoPopulationService**: Integration for template-aware suggestions

## Implementation Details

### Components

#### New Components to Create

1. **MemoryConstrainedTemplateProcessor.swift**
```swift
import Foundation
import os.log

/// Memory-constrained template processor with strict accounting
actor MemoryConstrainedTemplateProcessor {
    // Reduced chunk size for memory constraints
    private let chunkSize = 400 // tokens (reduced from 800)
    private let overlapSize = 50 // tokens overlap (reduced from 100)
    private let logger = Logger(subsystem: "com.aiko.templates", category: "TemplateProcessor")
    
    // Strict memory management
    private let memoryPermitSystem = MemoryPermitSystem(limitBytes: 50 * 1024 * 1024)
    private let maxChunkSizeBytes = 4 * 1024 * 1024 // 4MB max chunk
    
    // Category detection patterns
    private let categoryPatterns: [TemplateCategory: [String]] = [
        .contract: ["contract", "agreement", "BPA", "IDIQ"],
        .statementOfWork: ["SOW", "PWS", "SOO", "statement of work"],
        .form: ["SF-1449", "form", "evaluation", "criteria"],
        .clause: ["clause", "provision", "terms", "conditions"],
        .guide: ["guide", "handbook", "manual", "procedures"]
    ]
    
    func processTemplate(
        content: Data,
        metadata: TemplateMetadata
    ) async throws -> ProcessedTemplate {
        // Acquire memory permit before processing
        let permit = try await memoryPermitSystem.acquire(bytes: min(content.count, maxChunkSizeBytes))
        defer { Task { await memoryPermitSystem.release(permit) } }
        
        // Stream process to avoid loading entire content
        let chunks = try await streamProcessContent(
            content: content,
            metadata: metadata,
            permit: permit
        )
        
        return ProcessedTemplate(
            chunks: chunks,
            category: detectCategory(metadata: metadata),
            metadata: metadata
        )
    }
    
    private func streamProcessContent(
        content: Data,
        metadata: TemplateMetadata,
        permit: MemoryPermit
    ) async throws -> [TemplateChunk] {
        var chunks: [TemplateChunk] = []
        var offset = 0
        
        while offset < content.count {
            // Process in 2-4MB windows
            let windowSize = min(maxChunkSizeBytes, content.count - offset)
            let window = content[offset..<offset + windowSize]
            
            // Extract text from window
            let text = try await extractTextFromWindow(window, type: metadata.fileType)
            
            // Create chunks with overlap
            let windowChunks = createChunksWithOverlap(
                text: text,
                startOffset: offset,
                chunkSize: chunkSize,
                overlapSize: overlapSize
            )
            
            chunks.append(contentsOf: windowChunks)
            offset += windowSize
            
            // Yield to prevent blocking
            await Task.yield()
        }
        
        return chunks
    }
}

/// Global memory permit system for strict accounting
actor MemoryPermitSystem {
    private let limitBytes: Int64
    private var usedBytes: Int64 = 0
    private var waitingRequests: [(Int64, CheckedContinuation<MemoryPermit, Error>)] = []
    
    init(limitBytes: Int64) {
        self.limitBytes = limitBytes
    }
    
    func acquire(bytes: Int64) async throws -> MemoryPermit {
        if usedBytes + bytes <= limitBytes {
            usedBytes += bytes
            return MemoryPermit(bytes: bytes)
        }
        
        // Wait for memory to be available
        return try await withCheckedThrowingContinuation { continuation in
            waitingRequests.append((bytes, continuation))
        }
    }
    
    func release(_ permit: MemoryPermit) {
        usedBytes -= permit.bytes
        
        // Process waiting requests
        var fulfilled: [Int] = []
        for (index, (bytes, continuation)) in waitingRequests.enumerated() {
            if usedBytes + bytes <= limitBytes {
                usedBytes += bytes
                continuation.resume(returning: MemoryPermit(bytes: bytes))
                fulfilled.append(index)
            }
        }
        
        // Remove fulfilled requests
        for index in fulfilled.reversed() {
            waitingRequests.remove(at: index)
        }
    }
}

struct MemoryPermit {
    let bytes: Int64
}
```

2. **HybridSearchService.swift**
```swift
import Foundation
import SwiftUI

/// Hybrid search service combining lexical and vector approaches
@MainActor
class HybridSearchService: ObservableObject {
    @Published var searchResults: [TemplateSearchResult] = []
    @Published var isSearching = false
    @Published var searchLatency: TimeInterval = 0
    
    private let lexicalIndex = BM25Index()
    private let objectBoxIndex = ObjectBoxSemanticIndex()
    private let lfm2Service = LFM2Service.shared
    
    // Performance targets
    private let prefilterTargetMs: TimeInterval = 2.0 / 1000 // 2ms
    private let rerankTargetMs: TimeInterval = 8.0 / 1000 // 8ms
    private let maxCandidates = 1000 // Limit candidates for reranking
    
    func hybridSearch(
        query: String,
        category: TemplateCategory? = nil,
        limit: Int = 10
    ) async {
        isSearching = true
        let startTime = Date()
        
        do {
            // Step 1: Lexical prefilter (BM25) - 2ms target
            let lexicalCandidates = try await performLexicalSearch(
                query: query,
                category: category,
                limit: maxCandidates
            )
            
            // Step 2: Generate query embedding (reduced dimensions)
            let queryEmbedding = try await lfm2Service.generateEmbedding(
                for: query,
                domain: .governmentContracting,
                dimensions: 384 // Reduced from 768
            )
            
            // Step 3: Exact cosine similarity reranking - 8ms target
            let rerankedResults = try await performExactReranking(
                candidates: lexicalCandidates,
                queryEmbedding: queryEmbedding,
                limit: limit
            )
            
            searchResults = rerankedResults
            searchLatency = Date().timeIntervalSince(startTime)
            
            // Log if we exceed target
            if searchLatency > 0.010 {
                logger.warning("Search exceeded 10ms target: \(searchLatency * 1000)ms")
            }
            
        } catch {
            logger.error("Hybrid search failed: \(error)")
        }
        
        isSearching = false
    }
    
    private func performLexicalSearch(
        query: String,
        category: TemplateCategory?,
        limit: Int
    ) async throws -> [LexicalCandidate] {
        let prefilterStart = Date()
        
        // Use BM25 for fast lexical matching
        let candidates = try await lexicalIndex.search(
            query: query,
            filter: category.map { .category($0) },
            limit: limit
        )
        
        let prefilterTime = Date().timeIntervalSince(prefilterStart)
        if prefilterTime > prefilterTargetMs {
            logger.warning("Lexical prefilter exceeded target: \(prefilterTime * 1000)ms")
        }
        
        return candidates
    }
    
    private func performExactReranking(
        candidates: [LexicalCandidate],
        queryEmbedding: [Float],
        limit: Int
    ) async throws -> [TemplateSearchResult] {
        let rerankStart = Date()
        
        // Fetch embeddings for candidates
        let candidateEmbeddings = try await objectBoxIndex.fetchEmbeddings(
            for: candidates.map(\.templateId)
        )
        
        // Calculate exact cosine similarity using SIMD
        let scores = candidateEmbeddings.map { candidate in
            calculateCosineSimilaritySIMD(
                queryEmbedding,
                candidate.embedding
            )
        }
        
        // Sort by score and take top K
        let rankedResults = zip(candidates, scores)
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { candidate, score in
                TemplateSearchResult(
                    template: candidate.metadata,
                    score: score,
                    snippet: candidate.snippet,
                    category: candidate.category,
                    crossReferences: []
                )
            }
        
        let rerankTime = Date().timeIntervalSince(rerankStart)
        if rerankTime > rerankTargetMs {
            logger.warning("Exact reranking exceeded target: \(rerankTime * 1000)ms")
        }
        
        return Array(rankedResults)
    }
    
    // SIMD-optimized cosine similarity
    private func calculateCosineSimilaritySIMD(_ a: [Float], _ b: [Float]) -> Float {
        #if arch(arm64)
        // Use NEON intrinsics for ARM64 (iOS devices)
        return simd_dot(simd_float4(a), simd_float4(b))
        #else
        // Fallback to standard calculation
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
        #endif
    }
}

/// BM25 index for lexical search
actor BM25Index {
    private var documents: [String: DocumentTerms] = [:]
    private var inverseDocumentFrequency: [String: Float] = [:]
    private let k1: Float = 1.2
    private let b: Float = 0.75
    
    func addDocument(_ id: String, content: String, metadata: TemplateMetadata) {
        let terms = tokenize(content)
        documents[id] = DocumentTerms(
            terms: terms,
            metadata: metadata,
            length: terms.count
        )
        updateIDF()
    }
    
    func search(
        query: String,
        filter: CategoryFilter? = nil,
        limit: Int
    ) async throws -> [LexicalCandidate] {
        let queryTerms = tokenize(query)
        var scores: [(String, Float, TemplateMetadata)] = []
        
        for (docId, doc) in documents {
            // Apply category filter if specified
            if let filter = filter, !filter.matches(doc.metadata.category) {
                continue
            }
            
            let score = calculateBM25Score(
                queryTerms: queryTerms,
                document: doc
            )
            
            scores.append((docId, score, doc.metadata))
        }
        
        // Sort by score and return top K
        return scores
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { id, score, metadata in
                LexicalCandidate(
                    templateId: id,
                    score: score,
                    metadata: metadata,
                    snippet: generateSnippet(for: id, query: query),
                    category: metadata.category ?? .guide
                )
            }
    }
    
    private func calculateBM25Score(
        queryTerms: [String],
        document: DocumentTerms
    ) -> Float {
        let avgDocLength = Float(documents.values.map(\.length).reduce(0, +)) / Float(documents.count)
        var score: Float = 0
        
        for term in queryTerms {
            guard let idf = inverseDocumentFrequency[term] else { continue }
            let tf = Float(document.terms.filter { $0 == term }.count)
            let docLength = Float(document.length)
            
            let numerator = tf * (k1 + 1)
            let denominator = tf + k1 * (1 - b + b * docLength / avgDocLength)
            
            score += idf * (numerator / denominator)
        }
        
        return score
    }
}
```

3. **ShardedTemplateIndex.swift**
```swift
import Foundation

/// Sharded index strategy for memory-efficient template storage
actor ShardedTemplateIndex {
    private let maxShardsInMemory = 3
    private var shards: [TemplateCategory: TemplateShard] = [:]
    private var shardAccessTime: [TemplateCategory: Date] = [:]
    
    // Shard templates by category to limit memory usage
    func addTemplate(
        _ template: ProcessedTemplate,
        embeddings: [[Float]]
    ) async throws {
        let shard = try await getOrCreateShard(for: template.category)
        try await shard.addTemplate(template, embeddings: embeddings)
    }
    
    func searchInCategory(
        _ category: TemplateCategory,
        queryEmbedding: [Float],
        limit: Int
    ) async throws -> [TemplateSearchResult] {
        let shard = try await getOrCreateShard(for: category)
        return try await shard.search(
            queryEmbedding: queryEmbedding,
            limit: limit
        )
    }
    
    private func getOrCreateShard(for category: TemplateCategory) async throws -> TemplateShard {
        // Update access time
        shardAccessTime[category] = Date()
        
        // Check if shard is already loaded
        if let shard = shards[category] {
            return shard
        }
        
        // Evict least recently used shard if at capacity
        if shards.count >= maxShardsInMemory {
            await evictLRUShard()
        }
        
        // Load or create shard
        let shard = try await TemplateShard.load(category: category)
        shards[category] = shard
        
        return shard
    }
    
    private func evictLRUShard() async {
        guard let lruCategory = shardAccessTime
            .sorted { $0.value < $1.value }
            .first?.key else { return }
        
        if let shard = shards[lruCategory] {
            await shard.persist()
            shards.removeValue(forKey: lruCategory)
        }
    }
}

/// Individual shard for a template category
actor TemplateShard {
    let category: TemplateCategory
    private var templates: [ProcessedTemplate] = []
    private var embeddings: [[Float]] = []
    private let persistencePath: URL
    
    init(category: TemplateCategory) {
        self.category = category
        self.persistencePath = Self.shardPath(for: category)
    }
    
    static func load(category: TemplateCategory) async throws -> TemplateShard {
        let shard = TemplateShard(category: category)
        
        // Load from disk if exists
        if FileManager.default.fileExists(atPath: shard.persistencePath.path) {
            let data = try Data(contentsOf: shard.persistencePath)
            // Deserialize templates and embeddings
            // ... implementation
        }
        
        return shard
    }
    
    func addTemplate(_ template: ProcessedTemplate, embeddings: [[Float]]) {
        templates.append(template)
        self.embeddings.append(contentsOf: embeddings)
    }
    
    func search(queryEmbedding: [Float], limit: Int) async throws -> [TemplateSearchResult] {
        // Perform exact cosine similarity search within shard
        var scores: [(Int, Float)] = []
        
        for (index, embedding) in embeddings.enumerated() {
            let score = cosineSimilarity(queryEmbedding, embedding)
            scores.append((index, score))
        }
        
        // Return top K results
        return scores
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .compactMap { index, score in
                guard index < templates.count else { return nil }
                // Convert to search result
                // ... implementation
            }
    }
    
    func persist() async {
        // Serialize and save to disk
        // ... implementation
    }
}
```

#### Existing Components to Modify

1. **LFM2Service.swift** - Add Dimension Reduction
```swift
extension LFM2Service {
    /// Generate reduced-dimension embeddings for memory efficiency
    func generateEmbedding(
        for text: String,
        domain: Domain,
        dimensions: Int = 384 // Reduced default
    ) async throws -> [Float] {
        // Generate full embedding
        let fullEmbedding = try await generateFullEmbedding(for: text, domain: domain)
        
        // Apply dimension reduction if needed
        if dimensions < fullEmbedding.count {
            return try reduceDimensions(
                embedding: fullEmbedding,
                targetDimensions: dimensions
            )
        }
        
        return fullEmbedding
    }
    
    private func reduceDimensions(
        embedding: [Float],
        targetDimensions: Int
    ) throws -> [Float] {
        // Use PCA or learned projection for dimension reduction
        // For now, simple truncation with L2 normalization
        let truncated = Array(embedding.prefix(targetDimensions))
        
        // L2 normalize
        let magnitude = sqrt(truncated.map { $0 * $0 }.reduce(0, +))
        guard magnitude > 0 else { return truncated }
        
        return truncated.map { $0 / magnitude }
    }
}
```

2. **ObjectBoxSemanticIndex.swift** - Memory-Mapped Storage
```swift
extension ObjectBoxSemanticIndex {
    /// Store embeddings with memory-mapped file backing
    func storeTemplateEmbedding(
        content: String,
        embedding: [Float],
        metadata: TemplateMetadata
    ) async throws {
        // Use memory-mapped storage for large datasets
        let mmapPath = documentsDirectory
            .appendingPathComponent("embeddings")
            .appendingPathComponent("\(metadata.templateId).emb")
        
        // Create memory-mapped file
        let embeddingData = embedding.withUnsafeBytes { Data($0) }
        
        // Write to memory-mapped file
        try embeddingData.write(to: mmapPath)
        
        // Store only metadata and path in ObjectBox
        let entity = TemplateEmbeddingMetadata(
            templateId: metadata.templateId,
            embeddingPath: mmapPath.path,
            category: metadata.category?.rawValue ?? "",
            dimension: embedding.count
        )
        
        try await store(entity)
    }
    
    /// Fetch embeddings using memory mapping
    func fetchEmbeddings(for ids: [String]) async throws -> [CandidateEmbedding] {
        var results: [CandidateEmbedding] = []
        
        for id in ids {
            let metadata = try await fetchMetadata(for: id)
            
            // Memory map the embedding file
            let url = URL(fileURLWithPath: metadata.embeddingPath)
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            
            // Convert to float array
            let embedding = data.withUnsafeBytes { bytes in
                let floatBuffer = bytes.bindMemory(to: Float.self)
                return Array(floatBuffer)
            }
            
            results.append(CandidateEmbedding(
                templateId: id,
                embedding: embedding,
                metadata: metadata
            ))
        }
        
        return results
    }
}
```

### Data Models

```swift
// MARK: - Template Types

enum TemplateCategory: String, CaseIterable, Codable {
    case contract = "Contract"
    case statementOfWork = "SOW"
    case form = "Form"
    case clause = "Clause"
    case guide = "Guide"
}

struct TemplateMetadata: Codable, Sendable {
    let templateId: String
    let fileName: String
    let fileType: String // PDF, DOCX, MD
    let category: TemplateCategory?
    let agency: String?
    let effectiveDate: Date?
    let lastModified: Date
    let fileSize: Int64
    let checksum: String
}

struct ProcessedTemplate: Sendable {
    let chunks: [TemplateChunk]
    let category: TemplateCategory
    let metadata: TemplateMetadata
}

struct TemplateChunk: Sendable {
    let content: String
    let chunkIndex: Int
    let overlap: String
    let metadata: ChunkMetadata
}

// MARK: - Search Types

struct LexicalCandidate {
    let templateId: String
    let score: Float
    let metadata: TemplateMetadata
    let snippet: String
    let category: TemplateCategory
}

struct CandidateEmbedding {
    let templateId: String
    let embedding: [Float]
    let metadata: TemplateEmbeddingMetadata
}

struct TemplateSearchResult: Identifiable {
    let id = UUID()
    let template: TemplateMetadata
    let score: Float
    let snippet: String
    let category: TemplateCategory
    let crossReferences: [RegulationReference]
    let searchLatency: TimeInterval?
}

// MARK: - Progress Tracking

struct TemplateProcessingProgress {
    let current: Int
    let total: Int
    let currentTemplate: String
    let estimatedTimeRemaining: TimeInterval?
    let memoryUsage: Int64
    let memoryLimit: Int64
    
    var percentComplete: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
    
    var memoryPercentUsed: Double {
        return Double(memoryUsage) / Double(memoryLimit) * 100
    }
    
    var displayText: String {
        "Processing templates... \(current)/\(total) (Memory: \(Int(memoryPercentUsed))%)"
    }
}
```

### API Design

#### Template Processing API with Memory Controls
```swift
protocol MemoryConstrainedProcessingAPI {
    /// Process templates with strict memory accounting
    func processTemplateDirectory(
        at path: URL,
        memoryLimit: Int64,
        progressHandler: @escaping (TemplateProcessingProgress) -> Void
    ) async throws
    
    /// Get current memory usage
    func getCurrentMemoryUsage() async -> Int64
    
    /// Pause processing to free memory
    func pauseProcessing() async
    
    /// Resume processing
    func resumeProcessing() async
    
    /// Emergency memory release
    func emergencyMemoryRelease() async
}
```

#### Hybrid Search API
```swift
protocol HybridSearchAPI {
    /// Perform hybrid lexical + vector search
    func hybridSearch(
        query: String,
        category: TemplateCategory?,
        searchMode: SearchMode,
        limit: Int
    ) async throws -> (results: [TemplateSearchResult], latency: SearchLatency)
    
    /// Warm up search indices
    func warmupIndices(categories: [TemplateCategory]) async
    
    /// Get search performance metrics
    func getSearchMetrics() async -> SearchPerformanceMetrics
}

enum SearchMode {
    case lexicalOnly      // BM25 only (fastest, <2ms)
    case hybridFast      // BM25 + small rerank set (target <5ms)
    case hybridAccurate  // BM25 + large rerank set (target <10ms)
}

struct SearchLatency {
    let lexicalMs: Double
    let embeddingMs: Double
    let rerankMs: Double
    let totalMs: Double
    
    var meetsTarget: Bool {
        totalMs < 10.0
    }
}
```

### Testing Strategy

#### Memory Constraint Tests
```swift
class MemoryConstraintTests: XCTestCase {
    func testStrictMemoryLimit() async throws {
        let processor = MemoryConstrainedTemplateProcessor()
        let memoryMonitor = MemoryMonitor()
        
        // Start monitoring
        await memoryMonitor.startMonitoring()
        
        // Process large dataset
        try await processor.processTemplateDirectory(
            at: testDataPath,
            memoryLimit: 50 * 1024 * 1024
        ) { progress in
            // Verify memory never exceeds limit
            XCTAssertLessThanOrEqual(progress.memoryUsage, progress.memoryLimit)
        }
        
        let peakMemory = await memoryMonitor.peakMemoryUsage
        XCTAssertLessThan(peakMemory, 50 * 1024 * 1024)
    }
    
    func testMemoryPermitSystem() async throws {
        let permitSystem = MemoryPermitSystem(limitBytes: 10 * 1024 * 1024)
        
        // Try to acquire more than limit
        let permit1 = try await permitSystem.acquire(bytes: 6 * 1024 * 1024)
        
        // This should wait
        let expectation = XCTestExpectation(description: "Waiting for memory")
        Task {
            _ = try await permitSystem.acquire(bytes: 6 * 1024 * 1024)
            expectation.fulfill()
        }
        
        // Release first permit
        await permitSystem.release(permit1)
        
        // Now second acquisition should complete
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
```

#### Hybrid Search Performance Tests
```swift
class HybridSearchPerformanceTests: XCTestCase {
    func testSearchLatencyP50() async throws {
        let searchService = HybridSearchService()
        var latencies: [TimeInterval] = []
        
        // Run 100 searches
        for _ in 0..<100 {
            let start = Date()
            _ = try await searchService.hybridSearch(
                query: "IT services contract",
                category: nil,
                limit: 10
            )
            latencies.append(Date().timeIntervalSince(start))
        }
        
        // Calculate P50
        let sortedLatencies = latencies.sorted()
        let p50 = sortedLatencies[49]
        
        XCTAssertLessThan(p50, 0.010) // <10ms P50
    }
    
    func testLexicalPrefilterSpeed() async throws {
        let bm25Index = BM25Index()
        
        // Add test documents
        for i in 0..<10000 {
            await bm25Index.addDocument(
                "doc\(i)",
                content: generateTestContent(),
                metadata: generateTestMetadata()
            )
        }
        
        // Test search speed
        let start = Date()
        let results = try await bm25Index.search(
            query: "contract services",
            limit: 1000
        )
        let elapsed = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(elapsed, 0.002) // <2ms
        XCTAssertEqual(results.count, 1000)
    }
}
```

## Implementation Steps

### Phase 1: Memory Infrastructure (Week 1)
1. **Day 1-2**: Implement MemoryPermitSystem and global memory accounting
2. **Day 2-3**: Create MemoryConstrainedTemplateProcessor with 2-4MB chunks
3. **Day 3-4**: Set up memory monitoring and profiling infrastructure
4. **Day 4-5**: Validate memory constraints with test data
5. **Day 5**: Memory stress testing and optimization

### Phase 2: Hybrid Search Foundation (Week 2)
1. **Day 1-2**: Implement BM25Index for lexical search
2. **Day 2-3**: Add dimension reduction to LFM2Service
3. **Day 3-4**: Create memory-mapped embedding storage
4. **Day 4-5**: Implement exact cosine reranking with SIMD
5. **Day 5**: Search latency benchmarking

### Phase 3: Sharded Processing (Week 3)
1. **Day 1-2**: Implement ShardedTemplateIndex with LRU eviction
2. **Day 2-3**: Add category-based sharding logic
3. **Day 3-4**: Create shard persistence and loading
4. **Day 4-5**: Integrate sharding with search pipeline
5. **Day 5**: Multi-shard query optimization

### Phase 4: Integration & UI (Week 4)
1. **Day 1-2**: Integrate with existing UnifiedSearchService
2. **Day 2-3**: Create SwiftUI progress tracking interface
3. **Day 3-4**: Add template browser with category filters
4. **Day 4-5**: Integrate with form auto-population
5. **Day 5**: End-to-end integration testing

### Phase 5: Optimization & Hardening (Week 5)
1. **Day 1-2**: Performance profiling and optimization
2. **Day 2-3**: Add crash recovery and checkpoint saves
3. **Day 3-4**: Implement metrics and monitoring
4. **Day 4-5**: Comprehensive testing and validation
5. **Day 5**: Production readiness review

## Risk Assessment

### Critical Risks

1. **Memory Constraint Violation (CRITICAL)**
   - **Risk**: 50MB limit insufficient for basic operation
   - **Mitigation**: 
     - Strict memory permit system
     - 2-4MB chunk processing
     - Dimension reduction to 384
     - Memory-mapped file storage
   - **Monitoring**: Continuous memory profiling with alerts
   - **Fallback**: Further reduce chunk size, implement disk-based processing

2. **Search Latency Target Miss (HIGH)**
   - **Risk**: Cannot achieve <10ms P95 latency
   - **Mitigation**:
     - Hybrid lexical+vector approach
     - SIMD optimization for reranking
     - Limit rerank candidates to 1000
     - Category-based sharding
   - **Monitoring**: Real-time latency tracking with percentiles
   - **Fallback**: Adjust SLA to P50<10ms, P95<20ms

3. **HNSW Memory Explosion (HIGH)**
   - **Risk**: ObjectBox HNSW requires full graph in memory
   - **Mitigation**:
     - Avoid full HNSW, use exact reranking instead
     - Shard indices by category
     - Memory-mapped embedding storage
   - **Validation**: Early prototype with realistic data volume

### Mitigation Strategies

1. **Phased Validation**
   - Week 1: Validate memory constraints with subset
   - Week 2: Validate search latency with hybrid approach
   - Week 3: Validate sharding effectiveness
   - Week 4: Full integration testing
   - Week 5: Production load testing

2. **Continuous Monitoring**
   - Memory usage tracking per component
   - Search latency percentiles (P50, P95, P99)
   - Index size growth monitoring
   - Background processing impact

3. **Graceful Degradation**
   - Fallback to lexical-only search if vector fails
   - Reduce chunk processing concurrency under pressure
   - Pause processing if memory critical

## Timeline Estimate

### Development Phases
- **Week 1**: Memory infrastructure and constraints validation
- **Week 2**: Hybrid search implementation and benchmarking
- **Week 3**: Sharded storage and processing
- **Week 4**: UI integration and user experience
- **Week 5**: Optimization, hardening, and production validation

### Critical Milestones
- **Day 5**: Memory constraint validation complete
- **Day 10**: Hybrid search achieving <10ms P50
- **Day 15**: Sharded processing operational
- **Day 20**: Full integration complete
- **Day 25**: Production readiness achieved

## Success Criteria

### Performance Metrics
- ✅ 256MB templates processed with <50MB peak memory
- ✅ <10ms search response time (P50), <20ms (P95)
- ✅ <2ms lexical prefilter latency
- ✅ <8ms exact reranking latency
- ✅ Memory permits preventing overruns

### Quality Standards
- ✅ Zero SwiftLint violations
- ✅ Swift 6 strict concurrency compliance
- ✅ >90% test coverage for memory-critical paths
- ✅ Clean build with zero warnings
- ✅ Comprehensive memory profiling validation

### User Experience
- ✅ Templates searchable within 3 minutes of app launch
- ✅ Clear memory usage indication during processing
- ✅ Graceful degradation under memory pressure
- ✅ Intuitive hybrid search with fast results

## Appendix: Consensus Synthesis

### Summary of VanillaIce Consensus Feedback and Decisions

**Model Consulted:** GPT-5 (comprehensive technical analysis)

**Key Improvements Applied:**
1. **Memory Permit System:** Global byte-based accounting preventing concurrent overruns
2. **Reduced Chunk Size:** 2-4MB chunks instead of 5-10MB for tighter control
3. **Dimension Reduction:** 384 dimensions instead of 768 to reduce memory by ~50%
4. **Hybrid Search:** BM25 prefilter + exact reranking avoiding full HNSW in memory
5. **Sharded Storage:** Category-based sharding with LRU eviction (max 3 shards warm)
6. **SIMD Optimization:** Hardware-accelerated cosine similarity for reranking
7. **Memory-Mapped Files:** Embeddings stored on disk with memory mapping
8. **Strict Concurrency:** Single reader-embedder-writer pipeline with backpressure

**Critical Insights:**
- 50MB memory constraint is the primary architectural driver
- HNSW at scale will violate memory limits - hybrid approach essential
- Lexical prefilter can achieve 90% of quality at 10% of memory cost
- Phased implementation crucial for early constraint validation

**Risk Mitigation Enhancements:**
- Early memory profiling on target hardware (iPhone 12/13)
- Multiple fallback strategies for each component
- Continuous monitoring with automated alerts
- Graceful degradation paths throughout system
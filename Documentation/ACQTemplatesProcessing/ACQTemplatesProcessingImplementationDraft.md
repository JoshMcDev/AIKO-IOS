# Implementation Plan: ACQ Templates Processing and Embedding

## Document Metadata
- Task: Implement Launch-Time ACQ Templates Processing and Embedding
- Version: Draft v1.0
- Date: 2025-08-08
- Author: tdd-design-architect
- Research Foundation: 5 comprehensive research documents integrated

## Overview

This implementation plan translates the validated PRD requirements for ACQ Templates Processing into a detailed technical design that seamlessly integrates with AIKO's existing GraphRAG infrastructure. The system will process 256MB of acquisition templates using a chunked approach (5-10MB chunks), generate LFM2 embeddings, and store them in ObjectBox with HNSW indexing for sub-10ms search response times.

The implementation leverages AIKO's production-ready foundation including LFM2Service, ObjectBoxSemanticIndex, and RegulationProcessor, extending them with template-specific capabilities while maintaining Swift 6 strict concurrency compliance and SwiftUI + @Observable patterns.

## Architecture Impact

### Current State Analysis

AIKO v6.2 has established a robust GraphRAG foundation:
- **RegulationProcessor**: Structure-aware chunking with 512-token segments
- **LFM2Service**: Actor-based embedding generation with memory management
- **ObjectBoxSemanticIndex**: Mock-first vector database with production migration path
- **BackgroundRegulationProcessor**: Swift 6 concurrent processing pipeline
- **UnifiedSearchService**: Cross-domain search infrastructure

### Proposed Changes

1. **New Template Namespace**: Extend ObjectBox with dedicated template entity models
2. **Template-Specific Processing**: Create TemplateProcessor actor parallel to RegulationProcessor
3. **Enhanced Search**: Extend UnifiedSearchService for triple-namespace queries
4. **Background Processing**: Leverage BGTaskScheduler for template processing
5. **Memory-Optimized Pipeline**: Implement chunked processing with <50MB peak usage

### Integration Points

- **LFM2Service**: Direct integration for embedding generation
- **ObjectBoxSemanticIndex**: Extension with TemplateEmbedding entity
- **BackgroundRegulationProcessor**: Shared patterns for background processing
- **UnifiedSearchService**: Enhanced for template + regulation cross-referencing
- **FormAutoPopulationService**: Integration for template-aware suggestions

## Implementation Details

### Components

#### New Components to Create

1. **TemplateProcessor.swift**
```swift
import Foundation
import os.log

/// Actor-based template processor with structure-aware chunking
actor TemplateProcessor {
    private let chunkSize = 800 // tokens (optimized for mobile)
    private let overlapSize = 100 // tokens overlap
    private let logger = Logger(subsystem: "com.aiko.templates", category: "TemplateProcessor")
    
    // Memory management
    private let memoryLimit: Int64 = 50 * 1024 * 1024 // 50MB
    private var currentMemoryUsage: Int64 = 0
    
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
        // Memory check
        guard await checkMemoryConstraints(content.count) else {
            throw TemplateProcessingError.memoryLimitExceeded
        }
        
        // Extract text content
        let text = try await extractText(from: content, type: metadata.fileType)
        
        // Categorize template
        let category = detectCategory(text: text, metadata: metadata)
        
        // Perform template-aware chunking
        let chunks = try await performTemplateChunking(
            text: text,
            category: category,
            metadata: metadata
        )
        
        // Update memory tracking
        await updateMemoryUsage(chunks.count * chunkSize)
        
        return ProcessedTemplate(
            chunks: chunks,
            category: category,
            metadata: metadata
        )
    }
    
    private func performTemplateChunking(
        text: String,
        category: TemplateCategory,
        metadata: TemplateMetadata
    ) async throws -> [TemplateChunk] {
        // Use category-specific chunking strategies
        switch category {
        case .form:
            return try await chunkFormTemplate(text, metadata)
        case .contract:
            return try await chunkContractTemplate(text, metadata)
        case .statementOfWork:
            return try await chunkSOWTemplate(text, metadata)
        default:
            return try await recursiveCharacterChunking(text, metadata)
        }
    }
}
```

2. **TemplateEmbeddingService.swift**
```swift
import Foundation
import BackgroundTasks

/// Service for generating and managing template embeddings
actor TemplateEmbeddingService {
    private let lfm2Service = LFM2Service.shared
    private let objectBoxIndex: ObjectBoxSemanticIndex
    private let batchSize = 10 // Process 10 templates at a time
    
    init() {
        self.objectBoxIndex = ObjectBoxSemanticIndex()
    }
    
    func processTemplateDirectory(
        path: URL,
        progressHandler: @escaping (TemplateProcessingProgress) -> Void
    ) async throws {
        let templates = try await discoverTemplates(at: path)
        let totalCount = templates.count
        var processedCount = 0
        
        // Process in batches for memory efficiency
        for batch in templates.chunked(into: batchSize) {
            try await processBatch(batch)
            
            processedCount += batch.count
            let progress = TemplateProcessingProgress(
                current: processedCount,
                total: totalCount,
                currentTemplate: batch.last?.name ?? ""
            )
            progressHandler(progress)
            
            // Allow system to reclaim memory between batches
            await Task.yield()
        }
    }
    
    private func processBatch(_ templates: [TemplateFile]) async throws {
        for template in templates {
            // Process template
            let processed = try await TemplateProcessor().processTemplate(
                content: template.data,
                metadata: template.metadata
            )
            
            // Generate embeddings for each chunk
            for chunk in processed.chunks {
                let embedding = try await lfm2Service.generateEmbedding(
                    for: chunk.content,
                    domain: .governmentContracting
                )
                
                // Store in ObjectBox
                try await objectBoxIndex.storeTemplateEmbedding(
                    content: chunk.content,
                    embedding: embedding,
                    metadata: chunk.metadata
                )
            }
        }
    }
}
```

3. **TemplateSearchService.swift**
```swift
import Foundation
import SwiftUI

/// Service for searching across templates with semantic similarity
@MainActor
class TemplateSearchService: ObservableObject {
    @Published var searchResults: [TemplateSearchResult] = []
    @Published var isSearching = false
    @Published var searchError: Error?
    
    private let objectBoxIndex = ObjectBoxSemanticIndex()
    private let lfm2Service = LFM2Service.shared
    
    func search(
        query: String,
        category: TemplateCategory? = nil,
        limit: Int = 10
    ) async {
        isSearching = true
        searchError = nil
        
        do {
            // Generate query embedding
            let queryEmbedding = try await lfm2Service.generateEmbedding(
                for: query,
                domain: .governmentContracting
            )
            
            // Search in ObjectBox
            let results = try await objectBoxIndex.searchTemplates(
                embedding: queryEmbedding,
                category: category,
                limit: limit
            )
            
            // Calculate confidence scores
            let scoredResults = results.map { result in
                TemplateSearchResult(
                    template: result.template,
                    score: calculateRelevanceScore(
                        query: queryEmbedding,
                        template: result.embedding
                    ),
                    snippet: generateSnippet(result.content, query: query)
                )
            }
            
            searchResults = scoredResults.sorted { $0.score > $1.score }
        } catch {
            searchError = error
        }
        
        isSearching = false
    }
    
    private func calculateRelevanceScore(
        query: [Float],
        template: [Float]
    ) -> Float {
        // Cosine similarity calculation
        let dotProduct = zip(query, template).map(*).reduce(0, +)
        let queryMagnitude = sqrt(query.map { $0 * $0 }.reduce(0, +))
        let templateMagnitude = sqrt(template.map { $0 * $0 }.reduce(0, +))
        
        guard queryMagnitude > 0 && templateMagnitude > 0 else { return 0 }
        return dotProduct / (queryMagnitude * templateMagnitude)
    }
}
```

#### Existing Components to Modify

1. **ObjectBoxSemanticIndex.swift** - Add Template Entity
```swift
// Add to existing file
#if canImport(ObjectBox)
// objectbox:Entity
class TemplateEmbedding {
    var id: Id
    var content: String
    var embedding: Data // [Float] as Data
    var templateId: String
    var templateName: String
    var category: String // Contract, SOW, Form, etc.
    var agency: String?
    var effectiveDate: Date?
    var chunkIndex: Int
    var chunkOverlap: String
    var timestamp: Date
    
    // objectbox:hnswIndex: dimensions=768, M=16, efConstruction=200
    var embeddingVector: [Float]?
    
    required init() {
        self.id = 0
        self.content = ""
        self.embedding = Data()
        self.templateId = UUID().uuidString
        self.templateName = ""
        self.category = ""
        self.chunkIndex = 0
        self.chunkOverlap = ""
        self.timestamp = Date()
    }
}
#endif

extension ObjectBoxSemanticIndex {
    func storeTemplateEmbedding(
        content: String,
        embedding: [Float],
        metadata: TemplateMetadata
    ) async throws {
        // Implementation for template storage
    }
    
    func searchTemplates(
        embedding: [Float],
        category: TemplateCategory?,
        limit: Int
    ) async throws -> [TemplateSearchResult] {
        // HNSW similarity search implementation
    }
}
```

2. **UnifiedSearchService.swift** - Enhance for Templates
```swift
extension UnifiedSearchService {
    func unifiedSearch(
        query: String,
        domains: Set<SearchDomain> = [.regulations, .templates],
        limit: Int = 20
    ) async throws -> UnifiedSearchResults {
        var results = UnifiedSearchResults()
        
        // Search regulations if requested
        if domains.contains(.regulations) {
            let regulationResults = try await searchRegulations(query, limit: limit/2)
            results.regulations = regulationResults
        }
        
        // Search templates if requested
        if domains.contains(.templates) {
            let templateResults = try await searchTemplates(query, limit: limit/2)
            results.templates = templateResults
        }
        
        // Cross-reference and rank
        results.crossReferences = try await findCrossReferences(
            regulations: results.regulations,
            templates: results.templates
        )
        
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

struct ChunkMetadata: Codable, Sendable {
    let startOffset: Int
    let endOffset: Int
    let tokenCount: Int
    let hasTable: Bool
    let hasForm: Bool
    let regulationReferences: [String]
}

// MARK: - Search Results

struct TemplateSearchResult: Identifiable {
    let id = UUID()
    let template: TemplateMetadata
    let score: Float
    let snippet: String
    let category: TemplateCategory
    let crossReferences: [RegulationReference]
}

struct UnifiedSearchResults {
    var regulations: [RegulationSearchResult] = []
    var templates: [TemplateSearchResult] = []
    var crossReferences: [CrossReference] = []
    
    var allResults: [any SearchResult] {
        regulations + templates
    }
}

// MARK: - Progress Tracking

struct TemplateProcessingProgress {
    let current: Int
    let total: Int
    let currentTemplate: String
    let estimatedTimeRemaining: TimeInterval?
    let memoryUsage: Int64
    
    var percentComplete: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
    
    var displayText: String {
        "Processing templates... \(current)/\(total)"
    }
}
```

### API Design

#### Template Processing API
```swift
protocol TemplateProcessingAPI {
    /// Process templates from a directory
    func processTemplateDirectory(
        at path: URL,
        progressHandler: @escaping (TemplateProcessingProgress) -> Void
    ) async throws
    
    /// Process a single template file
    func processTemplate(
        file: URL,
        metadata: TemplateMetadata?
    ) async throws -> ProcessedTemplate
    
    /// Cancel ongoing processing
    func cancelProcessing() async
    
    /// Get processing status
    func getProcessingStatus() async -> ProcessingStatus
}
```

#### Template Search API
```swift
protocol TemplateSearchAPI {
    /// Search templates with natural language query
    func searchTemplates(
        query: String,
        category: TemplateCategory?,
        limit: Int
    ) async throws -> [TemplateSearchResult]
    
    /// Get template by ID
    func getTemplate(id: String) async throws -> TemplateMetadata
    
    /// Get related templates
    func getRelatedTemplates(
        to templateId: String,
        limit: Int
    ) async throws -> [TemplateSearchResult]
}
```

#### Cross-Reference API
```swift
protocol CrossReferenceAPI {
    /// Find regulations related to a template
    func findRelatedRegulations(
        for templateId: String
    ) async throws -> [RegulationReference]
    
    /// Find templates related to a regulation
    func findRelatedTemplates(
        for regulationId: String
    ) async throws -> [TemplateReference]
    
    /// Get cross-reference confidence score
    func getCrossReferenceScore(
        templateId: String,
        regulationId: String
    ) async throws -> Float
}
```

### Testing Strategy

#### Unit Tests
```swift
class TemplateProcessorTests: XCTestCase {
    func testTemplateChunking() async throws {
        // Test chunking with overlap
        let processor = TemplateProcessor()
        let testContent = Data(repeating: 0x41, count: 10000) // 10KB test data
        let metadata = TemplateMetadata(/* test metadata */)
        
        let result = try await processor.processTemplate(
            content: testContent,
            metadata: metadata
        )
        
        XCTAssertGreaterThan(result.chunks.count, 0)
        XCTAssertEqual(result.chunks.first?.overlap, "")
        XCTAssertGreaterThan(result.chunks[1].overlap.count, 0)
    }
    
    func testMemoryConstraints() async throws {
        // Test 50MB memory limit
        let processor = TemplateProcessor()
        let largeContent = Data(repeating: 0x41, count: 60_000_000) // 60MB
        
        await XCTAssertThrowsError(
            try await processor.processTemplate(
                content: largeContent,
                metadata: TemplateMetadata(/* */)
            )
        ) { error in
            XCTAssertEqual(error as? TemplateProcessingError, .memoryLimitExceeded)
        }
    }
}
```

#### Integration Tests
```swift
class TemplateIntegrationTests: XCTestCase {
    func testEndToEndTemplateProcessing() async throws {
        // Test complete pipeline
        let service = TemplateEmbeddingService()
        let testPath = Bundle.main.url(forResource: "TestTemplates", withExtension: nil)!
        
        var progressUpdates: [TemplateProcessingProgress] = []
        
        try await service.processTemplateDirectory(path: testPath) { progress in
            progressUpdates.append(progress)
        }
        
        XCTAssertFalse(progressUpdates.isEmpty)
        XCTAssertEqual(progressUpdates.last?.percentComplete, 100)
    }
    
    func testSearchPerformance() async throws {
        // Test <10ms search response
        let searchService = TemplateSearchService()
        
        let startTime = Date()
        let results = try await searchService.search(
            query: "IT services contract",
            limit: 10
        )
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(elapsed, 0.01) // <10ms
        XCTAssertFalse(results.isEmpty)
    }
}
```

## Implementation Steps

### Phase 1: Core Infrastructure (Week 1)
1. Create TemplateProcessor actor with basic chunking
2. Extend ObjectBoxSemanticIndex with TemplateEmbedding entity
3. Implement TemplateEmbeddingService with batch processing
4. Create data models and error types
5. Set up test infrastructure

### Phase 2: Processing Pipeline (Week 2)
1. Implement template discovery and file handling
2. Add category detection logic
3. Implement memory-constrained batch processing
4. Add progress tracking with BackgroundTasks
5. Create processing status persistence

### Phase 3: Search Integration (Week 3)
1. Implement TemplateSearchService with HNSW indexing
2. Extend UnifiedSearchService for templates
3. Add cross-reference capabilities
4. Implement relevance scoring
5. Create search result ranking

### Phase 4: UI Integration (Week 4)
1. Create TemplatesBrowserView with SwiftUI
2. Add search interface with category filters
3. Implement progress tracking UI
4. Integrate with form auto-population
5. Add template detail views

### Phase 5: Testing & Optimization (Week 5)
1. Complete unit test suite
2. Integration testing with real templates
3. Performance optimization
4. Memory profiling and optimization
5. Search relevance tuning

## Risk Assessment

### Technical Risks

1. **Memory Constraints**
   - Risk: 256MB corpus may exceed 50MB processing limit
   - Mitigation: Implement streaming processing with 5-10MB chunks
   - Monitoring: MemoryPressureManager integration

2. **HNSW Index Scaling**
   - Risk: Index size grows super-linearly
   - Mitigation: M=16, efConstruction=200 parameters
   - Fallback: Reduce embedding dimensions if needed

3. **Search Latency**
   - Risk: May exceed 10ms target
   - Mitigation: Pre-compute and cache frequent queries
   - Optimization: Batch similarity calculations

### Mitigation Strategies

1. **Progressive Enhancement**
   - Start with basic chunking, add structure-awareness later
   - Implement basic search first, optimize relevance iteratively

2. **Memory Management**
   - Use autoreleasepool blocks
   - Process templates in 10-template batches
   - Monitor memory with os_proc_available_memory()

3. **Error Recovery**
   - Implement checkpoint saves every 10 templates
   - Allow resumable processing after interruption
   - Graceful degradation for corrupted templates

## Timeline Estimate

### Development Phases
- **Week 1**: Core infrastructure and data models
- **Week 2**: Processing pipeline implementation
- **Week 3**: Search and cross-reference features
- **Week 4**: UI integration and user experience
- **Week 5**: Testing, optimization, and polish

### Review Checkpoints
- **Day 3**: Architecture review after core infrastructure
- **Day 10**: Processing pipeline validation
- **Day 15**: Search performance benchmarking
- **Day 20**: UI/UX review
- **Day 25**: Final QA and production readiness

## Success Criteria

### Performance Metrics
- ✅ 256MB templates processed in <180 seconds
- ✅ <10ms search response time (95th percentile)
- ✅ <50MB peak memory usage during processing
- ✅ NDCG@10 ≥ 0.8 for search relevance

### Quality Standards
- ✅ Zero SwiftLint violations
- ✅ Swift 6 strict concurrency compliance
- ✅ >90% test coverage for core components
- ✅ Clean build with zero warnings

### User Experience
- ✅ Templates searchable within 3 minutes of app launch
- ✅ Seamless integration with existing regulation search
- ✅ Clear progress indication during processing
- ✅ Intuitive category filtering and result presentation
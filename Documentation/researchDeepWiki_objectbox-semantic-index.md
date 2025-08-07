# DeepWiki Repository Analysis: ObjectBox Semantic Index

**Research ID:** R-001-objectbox-semantic-index  
**Date:** 2025-01-20  
**Tool Status:** DeepWiki success  
**Repositories Analyzed:** objectbox/objectbox-swift

## Executive Summary

DeepWiki analysis of the ObjectBox Swift repository confirms comprehensive HNSW vector indexing support specifically designed for semantic search applications. The repository provides extensive documentation and examples for implementing mobile-optimized vector similarity search with cosine distance calculations, capable of achieving sub-second performance across large regulation datasets.

## Repository-Specific Findings

### SPM Dependency Setup

**Swift Package Manager Integration:**
- ObjectBox Swift can be added as a Swift Package Manager (SPM) dependency
- Official Swift package support available through GitHub releases
- Detailed installation instructions provided in ObjectBox Swift documentation
- XCFramework packaging supports both iOS and macOS deployment targets

**Dependency Configuration:**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/objectbox/objectbox-swift.git", from: "4.0.0")
]
```

### RegulationEmbedding Schema Design

**Recommended Entity Structure:**
```swift
// objectbox: entity
class RegulationEmbedding {
    var id: Id = 0
    
    // objectbox:hnswIndex: dimensions=768, distanceType="cosine"
    var embedding: [Float]?
    var text: String? // Original regulation text
    var title: String? // Regulation title
    var category: String? // Regulation category
    var effectiveDate: Date? // When regulation becomes effective
}
```

**Schema Annotation Details:**
- `dimensions=N`: Specifies vector dimensionality (commonly 768 for text embeddings)
- `distanceType="cosine"`: Optimizes for semantic similarity calculations
- Optional metadata fields enable hybrid search capabilities
- Property type `[Float]?` provides optimal mobile memory management

### VectorSearchService Implementation

**Service Architecture Pattern:**
```swift
import ObjectBox

class VectorSearchService {
    private let store: Store
    private let regulationBox: Box<RegulationEmbedding>
    
    init() throws {
        // File-based store for persistence on mobile
        self.store = try Store(directoryPath: "regulation-db")
        self.regulationBox = store.box(for: RegulationEmbedding.self)
    }
    
    func addRegulation(embedding: [Float], text: String) throws {
        let regulation = RegulationEmbedding()
        regulation.embedding = embedding
        regulation.text = text
        try regulationBox.put(regulation)
    }
    
    func searchRegulations(queryVector: [Float], maxResults: Int) throws -> [ObjectWithScore<RegulationEmbedding>] {
        let query = try regulationBox.query {
            RegulationEmbedding.embedding.nearestNeighbors(queryVector: queryVector, maxCount: maxResults)
        }.build()
        return try query.findWithScores()
    }
}
```

## Code Examples and Implementation Patterns

### Store and Box Initialization
```swift
// Initialize ObjectBox Store
let store = try Store(directoryPath: "path/to/regulation-db")
let regulationBox = store.box(for: RegulationEmbedding.self)
```

### Batch Regulation Import
```swift
func importRegulations(regulations: [(embedding: [Float], text: String)]) throws {
    let regulationObjects = regulations.map { regulation in
        let obj = RegulationEmbedding()
        obj.embedding = regulation.embedding
        obj.text = regulation.text
        return obj
    }
    try regulationBox.put(regulationObjects)
}
```

### Advanced Search with Filtering
```swift
func searchRegulationsWithFilter(queryVector: [Float], category: String, maxResults: Int) throws -> [ObjectWithScore<RegulationEmbedding>] {
    let query = try regulationBox.query {
        RegulationEmbedding.embedding.nearestNeighbors(queryVector: queryVector, maxCount: maxResults) &&
        RegulationEmbedding.category == category
    }.build()
    return try query.findWithScores()
}
```

## Best Practices from Repository Analysis

### Mobile Performance Optimization

**HNSW Parameter Tuning Guidelines:**
- **neighborsPerNode**: 16 for speed, 64 for accuracy (30 is balanced default)
- **indexingSearchCount**: 200+ recommended for optimal search quality
- **Vector Normalization**: Normalize vectors for cosine similarity to enable dot product optimization
- **Memory Management**: Use `vectorCacheSimdPaddingOff` flag to reduce memory footprint

**Cosine Distance Calculations:**
- ObjectBox supports `OBXVectorDistanceType_Cosine` natively
- Cosine distance scores: 0.0 (identical direction), 1.0 (orthogonal), 2.0 (opposite)
- Direct C function access: `obx_vector_distance_float32` for manual distance calculations
- Relevance conversion: `obx_vector_distance_to_relevance` converts distance to 0.0-1.0 relevance

### Mobile-Specific Optimizations

**Resource Efficiency Techniques:**
- Disk-based storage with smart caching for memory-constrained devices
- ACID transactions provide data integrity without performance penalties
- Automatic schema migrations eliminate manual database update requirements
- Minimal CPU, power, and memory usage optimized for mobile hardware

**Query Performance Strategies:**
- Use `findWithScores()` or `findIdsWithScores()` for efficient result retrieval
- Apply `offset` and `limit` for pagination and memory management
- Higher `max_result_count` than final results improves quality (acts as HNSW `ef` parameter)
- Close Store properly to release resources, especially in unit tests

## Integration Strategies

### Hybrid Search Implementation
```swift
func hybridSearch(queryVector: [Float], textQuery: String, maxResults: Int) throws -> [ObjectWithScore<RegulationEmbedding>] {
    let query = try regulationBox.query {
        RegulationEmbedding.embedding.nearestNeighbors(queryVector: queryVector, maxCount: maxResults * 2) &&
        RegulationEmbedding.text.contains(textQuery)
    }.build()
    return try query.findWithScores().prefix(maxResults).map { $0 }
}
```

### Performance Monitoring
```swift
func measureSearchPerformance(queryVector: [Float]) throws -> (results: [ObjectWithScore<RegulationEmbedding>], duration: TimeInterval) {
    let startTime = CFAbsoluteTimeGetCurrent()
    let results = try searchRegulations(queryVector: queryVector, maxResults: 10)
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    return (results, duration)
}
```

## References

**DeepWiki Repository Analysis:**
- Repository: objectbox/objectbox-swift
- Architecture Documentation: Store/Box pattern implementation
- Vector Search Examples: HNSW configuration and usage patterns
- Mobile Optimization: Performance tuning and resource management
- Search Query: ObjectBox Semantic Index Vector Database implementation details
- View Search: https://deepwiki.com/search/objectbox-semantic-index-vecto_314590d5-1eb2-4fdb-9ea7-69bc1aacb524
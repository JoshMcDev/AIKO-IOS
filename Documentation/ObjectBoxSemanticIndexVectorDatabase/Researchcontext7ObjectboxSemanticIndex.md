# Context7 Research Results: ObjectBox Semantic Index

**Research ID:** R-001-objectbox-semantic-index  
**Date:** 2025-01-20  
**Tool Status:** Context7 success  
**Libraries Analyzed:** objectbox-swift (/objectbox/objectbox-swift)

## Executive Summary

ObjectBox Swift 4.0+ provides native HNSW (Hierarchical Navigable Small World) vector indexing capability specifically designed for on-device semantic search applications. The library offers comprehensive vector database functionality with mobile-optimized performance, supporting cosine distance calculations and sub-second similarity search across large datasets.

## Library Documentation Analysis

### ObjectBox Swift Vector Database Features

**Core Components:**
- **Store**: Database entry point and source of Boxes
- **Box**: Main interface to persist objects and create queries  
- **Entity**: Protocol to mark types as persistable by ObjectBox
- **Id**: Identifies object instances in the database
- **Query**: Conditional fetching with vector similarity support

### HNSW Vector Indexing Implementation

**Schema Definition Pattern:**
```swift
// objectbox: entity
class RegulationEmbedding {
    var id: Id = 0
    var text: String?
    
    // objectbox:hnswIndex: dimensions=768, distanceType="cosine"
    var embedding: [Float]?
}
```

**Complete HNSW Parameter Syntax:**
```swift
// objectbox:hnswIndex: dimensions=2, neighborsPerNode=30, indexingSearchCount=100, 
// flags="debugLogs", distanceType="euclidean", reparationBacklinkProbability=0.95, 
// vectorCacheHintSizeKB=2097152
```

### Vector Property Schema Structure

**Property Configuration:**
- **Property Type**: `floatVector` for vector data storage
- **Swift Type**: `HnswIndexPropertyType` for HNSW-indexed properties
- **Unwrapped Type**: `[Float]` for vector arrays
- **Vector Type Flag**: `isScalarVectorType = true`

**Schema Parameters:**
- **dimensions**: Required - number of vector dimensions (e.g., 768 for embeddings)
- **neighborsPerNode**: Optional, default 30 - max connections per node
- **indexingSearchCount**: Optional, default 100 - neighbors searched during indexing
- **distanceType**: euclidean, geo, cosine, dotProduct, dotProductNonNormalized
- **vectorCacheHintSizeKB**: Optional, default 2097152 (2GB) - vector cache size hint

## Code Examples and Patterns

### Basic Entity Creation and Storage
```swift
let store = try Store(directoryPath: "regulation-db")
let box = store.box(for: RegulationEmbedding.self)

var regulation = RegulationEmbedding()
regulation.text = "Regulation content..."
regulation.embedding = [/* embedding vector */]
let id = try box.put(regulation)
```

### Vector Similarity Search
```swift
let queryVector = [/* query embedding */]
let query = try box.query {
    RegulationEmbedding.embedding.nearestNeighbors(
        queryVector: queryVector, 
        maxCount: 10
    )
}.build()

let results = try query.findWithScores()
for result in results {
    print("Regulation: \(result.object.text), distance: \(result.score)")
}
```

### Advanced HNSW Configuration Example
```swift
// High-performance configuration for mobile
// objectbox:hnswIndex: dimensions=768, neighborsPerNode=16, 
// indexingSearchCount=200, distanceType="cosine", 
// flags="vectorCacheSimdPaddingOff"
var embedding: [Float]?
```

## Version-Specific Information

**ObjectBox Swift 4.0+ Requirements:**
- Built with Xcode 15.0.1 and Swift 5.9
- Minimum iOS 12.0 and macOS 10.15
- Vector search support introduced in version 4.0
- HNSW algorithm implementation for approximate nearest neighbor search

**Distance Type Support:**
- **Cosine**: `OBXVectorDistanceType_Cosine` - semantic similarity
- **Euclidean**: Default geometric distance  
- **Geo**: Geographic/haversine distance
- **Dot Product**: Vector dot product calculation
- **Dot Product Non-Normalized**: Raw dot product without normalization

## Implementation Recommendations

### Mobile Performance Optimization

**HNSW Parameter Tuning:**
- **Fast Search**: `neighborsPerNode=16` for faster but less accurate results
- **Accurate Search**: `neighborsPerNode=64` for higher accuracy with more resources
- **Index Quality**: `indexingSearchCount=200+` for improved search quality
- **Memory Optimization**: `vectorCacheSimdPaddingOff` flag to reduce memory usage

### Storage Optimization
- Use cosine distance with normalized vectors for best mobile performance
- Configure appropriate vector cache size based on available device memory
- Leverage disk-based storage for datasets exceeding memory capacity
- ACID transactions ensure data integrity without performance penalties

### Query Performance
- Use `findWithScores()` for distance-aware results ordering
- Apply `offset` and `limit` for pagination and result limiting
- Combine vector search with traditional property filters for hybrid queries
- Cache frequently accessed embeddings in memory for faster retrieval

## References

**Context7 Library Information:**
- Library ID: `/objectbox/objectbox-swift`
- Description: Swift database - fast, simple and lightweight (iOS, macOS)
- Code Snippets: 59 examples available
- Trust Score: 7.9/10
- Documentation: Comprehensive schema examples with HNSW parameters
- API Reference: Complete vector search query syntax and configuration options
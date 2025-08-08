# Context7 Research Results: ACQ Templates Processing

**Research ID:** R-001-ACQTemplatesProcessing
**Date:** 2025-08-07
**Tool Status:** Context7 success
**Libraries Analyzed:** ObjectBox Swift (/objectbox/objectbox-swift)

## Executive Summary
ObjectBox Swift provides a powerful, superfast NoSQL database for iOS with specialized support for vector embeddings through HNSW (Hierarchical Navigable Small World) indexing. The library offers efficient on-device data persistence with vector search capabilities, making it ideal for processing and storing government acquisition template embeddings.

## Library Documentation Analysis

### ObjectBox Core Capabilities
ObjectBox Swift is designed as a high-performance, on-device database with the following key features:
- **Store**: Database entry point and source of Boxes
- **Box**: Main interface to persist objects and create Queries
- **Entity**: Protocol to mark types as persistable by ObjectBox
- **Id**: Identifies object instances in the database
- **Query**: Conditional fetching of objects of a certain type

### Vector Embedding Support

#### HNSW Index Configuration
ObjectBox supports sophisticated vector indexing with configurable HNSW parameters:

```swift
// objectbox: entity
class CityAllProperties {
    // objectbox:hnswIndex: dimensions=2
    var coordinates: [Float]?
    
    // HNSW Parameters available:
    // - dimensions: Vector dimensions (e.g., 2 for geo, 384+ for embeddings)
    // - neighborsPerNode: Optional(30) - connections per node
    // - indexingSearchCount: Optional(100) - search breadth during indexing
    // - flags: Debug options and optimization flags
    // - distanceType: HnswDistanceType.euclidean, .cosine, .dotProduct, .geo
    // - reparationBacklinkProbability: Optional(0.95)
    // - vectorCacheHintSizeKB: Optional(2097152) - 2GB cache hint
}
```

#### Vector Search Operations
```swift
// Perform nearest neighbor search
let query = try box.query {
    nearestNeighbors(queryVector: embeddings, maxCount: 10)
}.build()

// Get results with similarity scores
let resultsWithScores = try query.findWithScores()
// Returns ObjectWithScore instances with distances

// C API for advanced control
obx_qb_nearest_neighbors_f32(queryBuilder, propertyId, queryVector, maxResults)
```

## Code Examples and Patterns

### Basic CRUD Operations with Embeddings
```swift
// Define template entity with embeddings
// objectbox: entity
class ACQTemplate {
    var id: Id = 0
    var templateName: String = ""
    var category: String = ""
    var content: String = ""
    
    // objectbox:hnswIndex: dimensions=768
    var embeddings: [Float]?
    
    init() {}
    
    init(id: Id = 0, templateName: String, category: String, content: String, embeddings: [Float]?) {
        self.id = id
        self.templateName = templateName
        self.category = category
        self.content = content
        self.embeddings = embeddings
    }
}

// Initialize store and box
let store = try Store(directoryPath: "acq-templates-db")
let box = store.box(for: ACQTemplate.self)

// Store template with embeddings
var template = ACQTemplate(
    templateName: "Contract Template",
    category: "Procurement",
    content: "Template content...",
    embeddings: generatedEmbeddings
)
let id = try box.put(template)

// Query similar templates
let query = try box.query {
    nearestNeighbors(queryVector: searchEmbeddings, maxCount: 5)
}.build()
let similarTemplates = try query.findWithScores()
```

### Store Configuration for Large Datasets
```swift
// Configure store for 256MB+ datasets
let storeConfig = Store.Config()
storeConfig.maxDbSizeInKByte = 1048576 // 1GB limit
storeConfig.maxReaders = 126 // Increased for concurrent reads

let store = try Store(
    directoryPath: "acq-templates-db",
    configuration: storeConfig
)
```

### Efficient Batch Processing
```swift
// Process templates in batches to manage memory
func processTemplatesInBatches(templates: [RawTemplate], batchSize: Int = 100) {
    for batch in templates.chunked(into: batchSize) {
        autoreleasepool {
            let processedTemplates = batch.map { rawTemplate in
                ACQTemplate(
                    templateName: rawTemplate.name,
                    category: categorizeTemplate(rawTemplate),
                    content: rawTemplate.content,
                    embeddings: generateEmbeddings(rawTemplate.content)
                )
            }
            try? box.put(processedTemplates)
        }
    }
}
```

## Version-Specific Information
- ObjectBox Swift uses Apache License 2.0
- Supports iOS, macOS platforms
- Requires Swift 5.0+
- HNSW indexing available in latest versions
- Vector dimensions can range from 2 (geo) to thousands (embeddings)

## Implementation Recommendations

### 1. Schema Design for ACQ Templates
```swift
// objectbox: entity
class ACQTemplate {
    var id: Id = 0
    var templateId: String = ""  // Government template ID
    var templateType: String = "" // Contract, SOW, Form, etc.
    var category: String = ""     // Categorization
    var subcategory: String = ""  
    var content: String = ""      // Full template content
    var metadata: Data?           // JSON metadata
    var lastUpdated: Date = Date()
    
    // objectbox:hnswIndex: dimensions=768
    var contentEmbeddings: [Float]? // LFM2 embeddings
    
    // Additional indexes for filtering
    // objectbox:index
    var templateTypeIndex: String { templateType }
    
    // objectbox:index
    var categoryIndex: String { category }
}
```

### 2. Vector Search Configuration
- Use HnswDistanceType.cosine for semantic similarity
- Set neighborsPerNode to 30-50 for balanced performance
- Configure vectorCacheHintSizeKB based on available memory
- Enable HNSW flags for debugging during development

### 3. Performance Optimization
- Use streaming reads with obx_query_visit_with_score for large result sets
- Implement pagination for UI display
- Cache frequently accessed templates
- Use in-memory mode for testing (OBX_IN_MEMORY=true)

## References
- ObjectBox Swift GitHub: /objectbox/objectbox-swift
- Context7 Library ID: /objectbox/objectbox-swift
- Code Snippets Available: 59
- Trust Score: 7.9
# Implementation Plan: ObjectBox Semantic Index Vector Database (DRAFT)

## Document Metadata
- Task: objectbox-semantic-index-vector-database
- Version: Draft v1.0
- Date: 2025-08-07
- Author: tdd-design-architect
- Basis: Validated PRD (objectbox-semantic-index-vector-database_prd.md)

## Overview

This implementation plan provides comprehensive technical specifications for implementing the ObjectBox Semantic Index Vector Database as the foundational vector storage and retrieval layer for AIKO's GraphRAG intelligence system. The design integrates seamlessly with the existing production-ready LFM2Service (1,705 lines) while providing sub-second semantic search across 1000+ federal acquisition regulations with complete offline functionality.

## Architecture Impact Analysis

### Current State Analysis

**Existing Infrastructure:**
- **LFM2Service**: Production-ready with 768-dimensional embedding generation (LFM2-700M-GGUF Q6_K)
- **ObjectBoxSemanticIndex**: In-memory placeholder implementation awaiting real ObjectBox integration
- **GraphRAG Architecture**: Scaffolded with RegulationProcessor, UnifiedSearchService, and UserWorkflowTracker
- **Performance Requirements**: <1s search latency, <100MB storage, Swift 6 compliance

**Integration Context:**
- Actor-based architecture with @globalActor patterns established
- Helper actor classes for specialized concerns (LFM2TextPreprocessor, LFM2MemoryManager, LFM2DomainOptimizer)
- Performance tracking and memory management patterns
- Environmental deployment modes (mock vs production)

### Proposed Changes

**Core Implementation Components:**
1. **RegulationEmbedding Entity**: ObjectBox entity with HNSW-indexed vector storage
2. **VectorSearchService**: Main coordinator actor following established patterns
3. **Helper Actors**: Specialized actors for indexing, compression, encryption, and performance monitoring
4. **Security Layer**: AES-256-GCM encryption with iOS Data Protection integration
5. **Integration Pipeline**: Seamless connection with LFM2Service embedding generation

### Integration Points

**LFM2Service Integration:**
- Direct pipeline from LFM2Service.generateEmbedding() to VectorSearchService.storeEmbedding()
- Vector normalization for optimal cosine similarity computation
- Batch processing for efficient regulation imports
- Comprehensive error handling and recovery strategies

**GraphRAG System Integration:**
- Enhanced UnifiedSearchService with ObjectBox-powered semantic search
- RegulationProcessor integration for regulation chunking and embedding
- UserWorkflowTracker integration for privacy-preserving user data indexing

## Implementation Details

### Components

#### 1. RegulationEmbedding Entity (RegulationEmbedding.swift)

```swift
import ObjectBox

/// ObjectBox entity for storing regulation embeddings with HNSW indexing
/// Optimized for 768-dimensional vectors from LFM2-700M-GGUF model
@Entity 
public class RegulationEmbedding {
    public var id: Id = 0
    
    /// Regulation content text
    public var content: String = ""
    
    /// Regulation title for metadata
    public var title: String = ""
    
    /// Unique regulation identifier (indexed for efficient removal)
    @Index
    public var regulationId: String = ""
    
    /// 768-dimensional embedding vector with HNSW index for semantic search
    /// Configuration optimized for mobile performance with cosine distance
    // objectbox:hnswIndex: dimensions=768, neighborsPerNode=30, indexingSearchCount=200, distanceType="cosine", vectorCacheHintSizeKB=1048576
    public var embedding: [Float] = []
    
    /// Regulation category for metadata filtering
    public var category: String = ""
    
    /// Effective date for temporal filtering
    public var effectiveDate: Date = Date()
    
    /// Version tracking for updates
    public var version: String = ""
    
    /// Checksum for data integrity validation
    public var checksum: String = ""
    
    public init() {}
    
    public init(
        regulationId: String,
        content: String,
        title: String,
        embedding: [Float],
        category: String,
        effectiveDate: Date,
        version: String = "1.0",
        checksum: String
    ) {
        self.regulationId = regulationId
        self.content = content
        self.title = title
        self.embedding = embedding
        self.category = category
        self.effectiveDate = effectiveDate
        self.version = version
        self.checksum = checksum
    }
}
```

#### 2. VectorSearchService Actor (VectorSearchService.swift)

```swift
import Foundation
import ObjectBox
import os.log
import CryptoKit

/// Actor-based service for ObjectBox vector database operations
/// Provides thread-safe access to regulation embeddings with HNSW indexing
@globalActor
public actor VectorSearchService {
    public static let shared = VectorSearchService()
    
    // MARK: - Properties
    
    private var store: Store?
    private var regulationBox: Box<RegulationEmbedding>?
    private var isInitialized = false
    
    private let logger = Logger(subsystem: "com.aiko.graphrag", category: "VectorSearchService")
    
    // Helper actors following LFM2Service patterns
    private let indexManager: VectorIndexManager
    private let encryptionManager: VectorEncryptionManager
    private let compressionManager: VectorCompressionManager
    private let performanceMonitor: VectorPerformanceMonitor
    
    // Performance constants aligned with PRD requirements
    private enum Constants {
        static let maxStorageMB: UInt64 = 100 * 1024 // 100MB storage limit
        static let maxMemoryMB: UInt64 = 50 * 1024 * 1024 // 50MB memory limit
        static let searchTargetMs: TimeInterval = 1000 // <1s search target
        static let batchSize = 50 // Batch processing size
    }
    
    private init() {
        indexManager = VectorIndexManager(logger: logger)
        encryptionManager = VectorEncryptionManager(logger: logger)
        compressionManager = VectorCompressionManager(logger: logger)
        performanceMonitor = VectorPerformanceMonitor(logger: logger)
    }
    
    // MARK: - Initialization
    
    public func initialize() async throws {
        logger.info("🚀 VectorSearchService initializing...")
        
        // Initialize encryption and get database key
        try await encryptionManager.initialize()
        let encryptionKey = try await encryptionManager.getDatabaseKey()
        
        // Setup ObjectBox store with encryption
        let dbPath = try getDatabasePath()
        store = try Store(
            directoryPath: dbPath,
            maxDbSizeInKiloByte: Constants.maxStorageMB,
            encryptionKey: encryptionKey
        )
        
        // Initialize box for regulation embeddings
        regulationBox = store?.box(for: RegulationEmbedding.self)
        
        // Initialize helper actors
        try await indexManager.initialize(store: store)
        try await performanceMonitor.initialize()
        
        isInitialized = true
        logger.info("✅ VectorSearchService initialized successfully")
    }
    
    // MARK: - Core Operations
    
    public func storeRegulationEmbeddings(
        embeddings: [String: [Float]],
        metadata: [String: RegulationMetadata]
    ) async throws {
        guard isInitialized, let box = regulationBox else {
            throw VectorSearchError.notInitialized
        }
        
        let startTime = Date()
        
        let regulations = embeddings.compactMap { (regulationId, embedding) -> RegulationEmbedding? in
            guard let meta = metadata[regulationId] else { return nil }
            
            // Normalize vector for optimal cosine similarity
            let normalizedEmbedding = await compressionManager.normalizeVector(embedding)
            
            return RegulationEmbedding(
                regulationId: regulationId,
                content: meta.content,
                title: meta.title,
                embedding: normalizedEmbedding,
                category: meta.category,
                effectiveDate: meta.effectiveDate,
                checksum: meta.checksum
            )
        }
        
        try box.put(regulations)
        
        let duration = Date().timeIntervalSince(startTime)
        await performanceMonitor.recordStorageOperation(
            count: regulations.count,
            duration: duration
        )
        
        logger.info("📥 Stored \(regulations.count) regulation embeddings in \(duration)s")
    }
    
    public func searchSimilarRegulations(
        queryEmbedding: [Float],
        limit: Int = 10,
        threshold: Float = 0.7
    ) async throws -> [RegulationSearchResult] {
        guard isInitialized, let box = regulationBox else {
            throw VectorSearchError.notInitialized
        }
        
        let startTime = Date()
        
        // Normalize query vector
        let normalizedQuery = await compressionManager.normalizeVector(queryEmbedding)
        
        // Perform HNSW nearest neighbors search
        let query = try box.query {
            RegulationEmbedding.embedding.nearestNeighbors(
                to: normalizedQuery,
                count: UInt(limit)
            )
        }.build()
        
        let neighbors = try query.findNeighbors()
        
        // Filter by threshold and convert to results
        let results = neighbors
            .filter { $0.distance >= threshold }
            .map { neighbor in
                RegulationSearchResult(
                    content: neighbor.object.content,
                    domain: .regulations,
                    regulationNumber: neighbor.object.regulationId,
                    embedding: neighbor.object.embedding,
                    similarity: neighbor.distance,
                    metadata: RegulationMetadata(
                        regulationNumber: neighbor.object.regulationId,
                        title: neighbor.object.title,
                        category: neighbor.object.category,
                        effectiveDate: neighbor.object.effectiveDate,
                        content: neighbor.object.content,
                        checksum: neighbor.object.checksum
                    )
                )
            }
        
        let duration = Date().timeIntervalSince(startTime)
        await performanceMonitor.recordSearchOperation(
            resultCount: results.count,
            duration: duration
        )
        
        logger.info("🔍 Found \(results.count) similar regulations in \(duration)s")
        
        return results
    }
    
    public func removeRegulations(regulationIds: [String]) async throws {
        guard isInitialized, let box = regulationBox else {
            throw VectorSearchError.notInitialized
        }
        
        let query = try box.query(RegulationEmbedding.regulationId.isIn(regulationIds)).build()
        let objectIds = try query.findIds()
        try box.remove(ids: objectIds)
        
        logger.info("🗑️ Removed \(objectIds.count) regulations")
    }
    
    public func getStorageStats() async throws -> VectorStorageStats {
        guard isInitialized, let box = regulationBox else {
            throw VectorSearchError.notInitialized
        }
        
        let count = try box.count()
        let dbSize = store?.sizeInBytes() ?? 0
        let memoryUsage = await performanceMonitor.getCurrentMemoryUsage()
        
        return VectorStorageStats(
            regulationCount: Int(count),
            totalStorageBytes: Int(dbSize),
            memoryUsageBytes: memoryUsage,
            isWithinLimits: dbSize < Constants.maxStorageMB * 1024 && memoryUsage < Constants.maxMemoryMB
        )
    }
    
    // MARK: - Helper Methods
    
    private func getDatabasePath() throws -> String {
        let fileManager = FileManager.default
        let appSupportDir = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupportDir.appendingPathComponent("vector-database").path
    }
}

// MARK: - Supporting Types

public struct RegulationSearchResult {
    public let content: String
    public let domain: SearchDomain
    public let regulationNumber: String
    public let embedding: [Float]
    public let similarity: Float
    public let metadata: RegulationMetadata
}

public struct VectorStorageStats {
    public let regulationCount: Int
    public let totalStorageBytes: Int
    public let memoryUsageBytes: Int
    public let isWithinLimits: Bool
}

public struct RegulationMetadata {
    public let regulationNumber: String
    public let title: String
    public let category: String
    public let effectiveDate: Date
    public let content: String
    public let checksum: String
}

public enum VectorSearchError: Error {
    case notInitialized
    case encryptionFailed
    case storageExceeded
    case searchTimeout
    case invalidVector
}
```

#### 3. Helper Actors

**VectorEncryptionManager (VectorEncryptionManager.swift):**
```swift
import Foundation
import Security
import CryptoKit

/// Actor for managing vector database encryption and security
public actor VectorEncryptionManager {
    private let logger: Logger
    private var encryptionKey: SymmetricKey?
    private let keyTag = "com.aiko.vectordb.key"
    
    public init(logger: Logger) {
        self.logger = logger
    }
    
    public func initialize() async throws {
        encryptionKey = try await getOrCreateEncryptionKey()
        logger.info("🔐 Encryption manager initialized")
    }
    
    public func getDatabaseKey() async throws -> Data {
        guard let key = encryptionKey else {
            throw VectorSearchError.encryptionFailed
        }
        return key.withUnsafeBytes { Data($0) }
    }
    
    private func getOrCreateEncryptionKey() async throws -> SymmetricKey {
        // Try to retrieve existing key from Keychain
        if let existingKey = try? getKeyFromKeychain() {
            return existingKey
        }
        
        // Generate new key and store securely
        let newKey = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(newKey)
        return newKey
    }
    
    private func getKeyFromKeychain() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let keyData = result as? Data else {
            throw VectorSearchError.encryptionFailed
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func storeKeyInKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw VectorSearchError.encryptionFailed
        }
    }
}
```

## Testing Strategy

### Comprehensive Test Coverage

1. **Unit Tests**
   - RegulationEmbedding entity validation
   - VectorSearchService operations
   - Encryption and security components
   - Performance monitoring accuracy

2. **Integration Tests**
   - LFM2Service -> VectorSearchService pipeline
   - ObjectBox HNSW search accuracy
   - End-to-end regulation processing
   - Memory and storage compliance

3. **Performance Tests**
   - Search latency under 1s validation
   - Memory usage under 50MB validation
   - Storage efficiency under 100MB validation
   - Battery impact measurement

4. **Security Tests**
   - Encryption at rest validation
   - iOS Data Protection compliance
   - FIPS 140-2 cryptographic validation
   - Key management security

## Implementation Steps

### Phase 1: Foundation (Week 1-2)
1. Implement RegulationEmbedding entity with HNSW configuration
2. Create VectorSearchService basic structure and initialization
3. Implement VectorEncryptionManager with iOS Data Protection
4. Establish LFM2Service integration pipeline

### Phase 2: Core Functionality (Week 2-3)
1. Implement vector storage and retrieval operations
2. Add HNSW search with mobile optimization
3. Create helper actors for compression and performance monitoring
4. Implement comprehensive error handling

### Phase 3: Optimization and Testing (Week 3-4)
1. Optimize HNSW parameters for mobile performance
2. Implement device-specific performance profiles
3. Add comprehensive test suite with golden dataset
4. Validate performance targets and security compliance

### Phase 4: Integration and Validation (Week 4-5)
1. Complete GraphRAG pipeline integration
2. Implement regulation update and lifecycle management
3. Validate federal compliance requirements
4. Performance optimization and production readiness

## Risk Assessment

### Technical Risks

1. **FIPS 140-2 Compliance (HIGH)**: Validate ObjectBox encryption meets federal standards
2. **Mobile Performance (MEDIUM)**: HNSW parameter optimization for <1s search
3. **Memory Management (LOW)**: Actor isolation ensures proper memory handling
4. **Integration Complexity (LOW)**: Established patterns reduce implementation risk

### Mitigation Strategies

1. **Early compliance validation** with security experts
2. **Device-specific optimization** profiles and continuous benchmarking
3. **Comprehensive testing** across device matrix
4. **Incremental rollout** with feature flags and monitoring

## Timeline Estimate

- **Total Duration**: 5 weeks
- **Development**: 3-4 weeks
- **Testing & Optimization**: 1-2 weeks
- **Integration & Validation**: Ongoing

This implementation plan provides a comprehensive foundation for the ObjectBox Semantic Index Vector Database while maintaining architectural consistency and meeting all performance, security, and functional requirements.
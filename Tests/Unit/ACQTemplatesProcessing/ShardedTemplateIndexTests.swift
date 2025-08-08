import XCTest
@testable import GraphRAG
import Foundation

/// Sharded Template Index Test Suite - TDD RED Phase
/// Tests designed to FAIL initially, implementing memory-efficient category-based sharding with LRU eviction
/// Critical: Max 3 shards in memory, category-based sharding, memory-mapped persistence
@available(iOS 17.0, *)
final class ShardedTemplateIndexTests: XCTestCase {

    private var shardedIndex: ShardedTemplateIndex?
    private var memoryMonitor: ShardedTemplateIndexTests.MemoryMonitor?
    private var persistenceManager: ShardPersistenceManager?

    // Critical constraints from rubric
    private let maxShardsInMemory = 3
    private let maxShardSizeBytes: Int64 = 15 * 1024 * 1024  // 15MB per shard
    private let memoryLimitBytes: Int64 = 50 * 1024 * 1024   // 50MB total limit

    override func setUpWithError() throws {
        // These will fail due to unimplemented components - RED phase intended behavior
        shardedIndex = ShardedTemplateIndex()
        memoryMonitor = ShardedTemplateIndexTests.MemoryMonitor()
        persistenceManager = ShardPersistenceManager()

        // Clean up any existing shard files
        try cleanupShardFiles()
    }

    override func tearDownWithError() throws {
        try cleanupShardFiles()
        shardedIndex = nil
        memoryMonitor = nil
        persistenceManager = nil
    }

    // MARK: - Shard Creation and Management Tests

    /// Test category-based shard creation with memory constraints
    /// CRITICAL: This test MUST FAIL initially until ShardedTemplateIndex is implemented
    
    func testCategoryBasedShardCreation() async throws {
        let shardedIndex = try unwrapService(shardedIndex)
        let memoryMonitor: ShardedTemplateIndexTests.MemoryMonitor = try unwrapService(self.memoryMonitor)

        await memoryMonitor.startMonitoring()

        // Create templates for different categories
        let contractTemplates = createTemplatesForCategory(.contract, count: 100)
        let sowTemplates = createTemplatesForCategory(.statementOfWork, count: 75)
        let formTemplates = createTemplatesForCategory(.form, count: 50)

        // Add templates and verify shard creation
        for template in contractTemplates {
            try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
        }

        // Verify contract shard was created
        let contractShard = try await shardedIndex.getShard(for: .contract)
        XCTAssertNotNil(contractShard, "Contract shard should be created")
        let contractTemplateCount = await contractShard.templateCount
        XCTAssertEqual(contractTemplateCount, 100, "Contract shard should contain all contract templates")

        // Add SOW templates
        for template in sowTemplates {
            try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
        }

        // Verify separate SOW shard was created
        let sowShard = try await shardedIndex.getShard(for: .statementOfWork)
        XCTAssertNotNil(sowShard, "SOW shard should be created")
        let sowTemplateCount = await sowShard.templateCount
        XCTAssertEqual(sowTemplateCount, 75, "SOW shard should contain all SOW templates")

        // Verify shards are isolated by category
        let contractTemplateIds = await contractShard.getAllTemplateIds()
        let sowTemplateIds = await sowShard.getAllTemplateIds()

        XCTAssertTrue(Set(contractTemplateIds).isDisjoint(with: Set(sowTemplateIds)),
                     "Shards should not share templates across categories")

        // Verify memory usage stays within limits
        let peakMemory = await memoryMonitor.peakMemoryUsage
        XCTAssertLessThanOrEqual(peakMemory, memoryLimitBytes,
                                "Shard creation should not exceed memory limit: \(peakMemory)")
    }

    /// Test maximum shards in memory constraint with LRU eviction
    /// This test WILL FAIL until LRU eviction mechanism is implemented
    
    func testLRUEvictionWithMaxShards() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        // Create templates for all 5 categories to force eviction
        let categories = TemplateCategory.allCases

        for category in categories {
            let templates = createTemplatesForCategory(category, count: 50)

            for template in templates {
                try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
            }

            // Access the shard to update LRU
            _ = try await shardedIndex.searchInCategory(
                category,
                queryEmbedding: generateTestEmbedding(dimensions: 384),
                limit: 5
            )
        }

        // Verify only maxShardsInMemory shards are loaded
        let loadedShardCount = await shardedIndex.getLoadedShardCount()
        XCTAssertLessThanOrEqual(loadedShardCount, maxShardsInMemory,
                                "Should not exceed max shards in memory: \(loadedShardCount)")

        // Access contract shard (should be LRU if evicted)
        let contractResults = try await shardedIndex.searchInCategory(
            .contract,
            queryEmbedding: generateTestEmbedding(dimensions: 384),
            limit: 5
        )

        XCTAssertGreaterThan(contractResults.count, 0, "Should load evicted shard from persistence")

        // Verify access time updates
        let mostRecentShard = await shardedIndex.getMostRecentlyAccessedShard()
        XCTAssertEqual(mostRecentShard, .contract, "Contract should be most recently accessed")
    }

    /// Test shard memory usage per category with size limits
    /// This test WILL FAIL until shard memory management is implemented
    
    func testShardMemorySizeLimits() async throws {
        let shardedIndex = try unwrapService(shardedIndex)
        let memoryMonitor: ShardedTemplateIndexTests.MemoryMonitor = try unwrapService(self.memoryMonitor)

        await memoryMonitor.startMonitoring()

        // Create large number of contract templates to test size limits
        let largeTemplateSet = createLargeTemplatesForCategory(.contract, count: 500)

        var addedCount = 0
        for template in largeTemplateSet {
            try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
            addedCount += 1

            // Check shard size periodically
            if addedCount % 50 == 0 {
                let contractShard = try await shardedIndex.getShard(for: .contract)
                let shardMemoryUsage = await contractShard.getMemoryUsage()

                // Shard should not exceed individual shard size limit
                XCTAssertLessThanOrEqual(shardMemoryUsage, maxShardSizeBytes,
                                        "Shard exceeded size limit: \(shardMemoryUsage) > \(maxShardSizeBytes)")
            }
        }

        // Verify total memory usage across all shards
        let totalMemoryUsage = await shardedIndex.getTotalMemoryUsage()
        XCTAssertLessThanOrEqual(totalMemoryUsage, memoryLimitBytes,
                                "Total shard memory exceeded limit: \(totalMemoryUsage)")
    }

    // MARK: - Shard Persistence Tests

    /// Test shard persistence and loading from disk
    /// This test WILL FAIL until persistence mechanism is implemented
    
    func testShardPersistenceAndLoading() async throws {
        let shardedIndex = try unwrapService(shardedIndex)
        _ = try unwrapService(persistenceManager)

        // Create and populate a shard
        let templates = createTemplatesForCategory(.guide, count: 100)
        let templateEmbeddings = templates.map { createEmbeddingsForTemplate($0) }

        for (template, embeddings) in zip(templates, templateEmbeddings) {
            try await shardedIndex.addTemplate(template, embeddings: embeddings)
        }

        let guideShard = try await shardedIndex.getShard(for: .guide)
        let originalTemplateCount = await guideShard.templateCount
        let originalTemplateIds = await guideShard.getAllTemplateIds()

        // Force shard to persist
        try await shardedIndex.persistShard(category: .guide)

        // Verify persistence file exists
        let shardPath = ShardedTemplateIndex.getShardPath(for: .guide)
        XCTAssertTrue(FileManager.default.fileExists(atPath: shardPath.path),
                     "Shard persistence file should exist")

        // Evict shard from memory
        await shardedIndex.evictShard(category: .guide)

        // Verify shard is no longer loaded
        let isGuideShardLoaded = await shardedIndex.isShardLoaded(.guide)
        XCTAssertFalse(isGuideShardLoaded, "Shard should be evicted from memory")

        // Load shard again - should restore from persistence
        let reloadedShard = try await shardedIndex.getShard(for: .guide)
        let reloadedTemplateCount = await reloadedShard.templateCount
        let reloadedTemplateIds = await reloadedShard.getAllTemplateIds()

        // Verify data integrity after reload
        XCTAssertEqual(reloadedTemplateCount, originalTemplateCount,
                      "Template count should match after reload")
        XCTAssertEqual(Set(reloadedTemplateIds), Set(originalTemplateIds),
                      "Template IDs should match after reload")
    }

    /// Test memory-mapped file storage for large shards
    /// This test WILL FAIL until memory-mapped storage is implemented
    
    func testMemoryMappedFileStorage() async throws {
        let shardedIndex = try unwrapService(shardedIndex)
        let memoryMonitor: ShardedTemplateIndexTests.MemoryMonitor = try unwrapService(self.memoryMonitor)

        await memoryMonitor.startMonitoring()

        // Create very large shard that should use memory mapping
        let largeTemplates = createLargeTemplatesForCategory(.contract, count: 200)

        for template in largeTemplates {
            try await shardedIndex.addTemplate(template, embeddings: createLargeEmbeddingsForTemplate(template))
        }

        let contractShard = try await shardedIndex.getShard(for: .contract)

        // Verify shard uses memory mapping
        let isMemoryMapped = await contractShard.isMemoryMapped
        XCTAssertTrue(isMemoryMapped, "Large shard should use memory mapping")

        // Verify memory usage is reasonable despite large data size
        let memoryUsage = await memoryMonitor.currentMemoryUsage
        let shardDataSize = await contractShard.getDataSize()

        // Memory usage should be much less than total data size due to memory mapping
        XCTAssertLessThan(memoryUsage, shardDataSize / 4,
                         "Memory usage should be much less than data size with memory mapping")

        // Verify search still works with memory-mapped storage
        let searchResults = try await shardedIndex.searchInCategory(
            .contract,
            queryEmbedding: generateTestEmbedding(dimensions: 384),
            limit: 10
        )

        XCTAssertGreaterThan(searchResults.count, 0, "Search should work with memory-mapped storage")
    }

    // MARK: - Search Performance Tests

    /// Test single-shard search performance
    /// This test WILL FAIL until optimized shard search is implemented
    
    func testSingleShardSearchPerformance() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        // Populate single shard with comprehensive data
        let templates = createTemplatesForCategory(.contract, count: 1000)

        for template in templates {
            try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
        }

        let queryEmbedding = generateTestEmbedding(dimensions: 384)
        var searchTimes: [TimeInterval] = []

        // Run multiple searches to measure performance
        for _ in 0..<20 {
            let startTime = Date()

            let results = try await shardedIndex.searchInCategory(
                .contract,
                queryEmbedding: queryEmbedding,
                limit: 10
            )

            let searchTime = Date().timeIntervalSince(startTime) * 1000  // Convert to ms
            searchTimes.append(searchTime)

            XCTAssertGreaterThan(results.count, 0, "Search should return results")
        }

        let averageSearchTime = searchTimes.reduce(0, +) / Double(searchTimes.count)
        let maxSearchTime = searchTimes.max() ?? 0

        // Single shard search should be very fast
        XCTAssertLessThan(averageSearchTime, 5.0, "Average shard search should be <5ms")
        XCTAssertLessThan(maxSearchTime, 10.0, "Max shard search should be <10ms")
    }

    /// Test multi-shard search coordination
    /// This test WILL FAIL until multi-shard search coordination is implemented
    
    func testMultiShardSearchCoordination() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        // Populate multiple shards
        for category in TemplateCategory.allCases {
            let templates = createTemplatesForCategory(category, count: 200)

            for template in templates {
                try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
            }
        }

        let queryEmbedding = generateTestEmbedding(dimensions: 384)

        let startTime = Date()

        // Search across all categories (multi-shard)
        let results = try await shardedIndex.searchAcrossAllShards(
            queryEmbedding: queryEmbedding,
            limit: 20
        )

        let searchTime = Date().timeIntervalSince(startTime) * 1000

        XCTAssertGreaterThan(results.count, 0, "Multi-shard search should return results")
        XCTAssertLessThanOrEqual(results.count, 20, "Should respect limit across shards")

        // Multi-shard search should still be reasonably fast
        XCTAssertLessThan(searchTime, 25.0, "Multi-shard search should be <25ms")

        // Results should be properly merged and ranked
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].score, results[i + 1].score,
                                       "Multi-shard results should be sorted by score")
        }

        // Results should come from different categories
        let categoriesInResults = Set(results.map { $0.category })
        XCTAssertGreaterThan(categoriesInResults.count, 1,
                           "Multi-shard search should return results from multiple categories")
    }

    /// Test shard warming and caching strategies
    /// This test WILL FAIL until shard warming is implemented
    
    func testShardWarmingAndCaching() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        // Create shards for all categories but evict them
        for category in TemplateCategory.allCases {
            let templates = createTemplatesForCategory(category, count: 100)

            for template in templates {
                try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
            }
        }

        // Force eviction of all shards to cold state
        await shardedIndex.evictAllShards()

        // Warm up specific categories
        let categoriesToWarm: [TemplateCategory] = [.contract, .statementOfWork]

        let warmupStartTime = Date()
        try await shardedIndex.warmupShards(categories: categoriesToWarm)
        let warmupTime = Date().timeIntervalSince(warmupStartTime) * 1000

        // Warmup should be reasonably fast
        XCTAssertLessThan(warmupTime, 100.0, "Shard warmup should be <100ms")

        // Verify warmed shards are loaded
        for category in categoriesToWarm {
            let isShardLoaded = await shardedIndex.isShardLoaded(category)
            XCTAssertTrue(isShardLoaded,
                         "Category \(category) should be warmed and loaded")
        }

        // Search warmed vs cold shards and compare performance
        let queryEmbedding = generateTestEmbedding(dimensions: 384)

        // Search warm shard
        let warmStart = Date()
        _ = try await shardedIndex.searchInCategory(.contract, queryEmbedding: queryEmbedding, limit: 10)
        let warmTime = Date().timeIntervalSince(warmStart) * 1000

        // Search cold shard
        let coldStart = Date()
        _ = try await shardedIndex.searchInCategory(.form, queryEmbedding: queryEmbedding, limit: 10)
        let coldTime = Date().timeIntervalSince(coldStart) * 1000

        // Warm search should be significantly faster
        XCTAssertLessThan(warmTime, coldTime * 0.5, "Warm search should be much faster than cold")
    }

    // MARK: - Data Integrity Tests

    /// Test template addition and retrieval integrity across shards
    /// This test WILL FAIL until data integrity mechanisms are implemented
    
    func testTemplateIntegrityAcrossShards() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        var allTemplates: [ProcessedTemplate] = []
        var allEmbeddings: [[Float]] = []

        // Add templates to different shards
        for category in TemplateCategory.allCases {
            let templates = createTemplatesForCategory(category, count: 50)
            let embeddings = templates.map { createEmbeddingsForTemplate($0) }

            allTemplates.append(contentsOf: templates)
            allEmbeddings.append(contentsOf: embeddings)

            for (template, embedding) in zip(templates, embeddings) {
                try await shardedIndex.addTemplate(template, embeddings: embedding)
            }
        }

        // Verify all templates can be found in their respective shards
        for template in allTemplates {
            let category = template.category

            let shard = try await shardedIndex.getShard(for: category)
            let templateExists = await shard.containsTemplate(template.metadata.templateId)

            XCTAssertTrue(templateExists, "Template \(template.metadata.templateId) not found in \(category) shard")
        }

        // Verify templates are not duplicated across shards
        var allTemplateIds: Set<String> = []

        for category in TemplateCategory.allCases {
            if await shardedIndex.isShardLoaded(category) {
                let shard = try await shardedIndex.getShard(for: category)
                let templateIds = await shard.getAllTemplateIds()

                for templateId in templateIds {
                    XCTAssertFalse(allTemplateIds.contains(templateId),
                                  "Template \(templateId) duplicated across shards")
                    allTemplateIds.insert(templateId)
                }
            }
        }

        XCTAssertEqual(allTemplateIds.count, allTemplates.count,
                      "Total templates in shards should match added templates")
    }

    // MARK: - Concurrent Access Tests

    /// Test concurrent shard access with thread safety
    /// This test WILL FAIL until thread-safe shard access is implemented
    
    func testConcurrentShardAccess() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        // Populate shards
        for category in TemplateCategory.allCases {
            let templates = createTemplatesForCategory(category, count: 100)

            for template in templates {
                try await shardedIndex.addTemplate(template, embeddings: createEmbeddingsForTemplate(template))
            }
        }

        let queryEmbedding = generateTestEmbedding(dimensions: 384)
        let concurrentOperations = 20

        // Execute concurrent searches across different shards
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentOperations {
                group.addTask { [shardedIndex, queryEmbedding] in
                    let category = TemplateCategory.allCases[i % TemplateCategory.allCases.count]

                    do {
                        let results = try await shardedIndex.searchInCategory(
                            category,
                            queryEmbedding: queryEmbedding,
                            limit: 5
                        )

                        XCTAssertGreaterThan(results.count, 0, "Concurrent search should return results")
                    } catch {
                        XCTFail("Concurrent search failed: \(error)")
                    }
                }
            }
        }

        // Verify shard integrity after concurrent access
        for category in TemplateCategory.allCases {
            let shard = try await shardedIndex.getShard(for: category)
            let isCorrupted = await shard.checkIntegrity()
            XCTAssertFalse(isCorrupted, "Shard \(category) should not be corrupted after concurrent access")
        }
    }

    // MARK: - Test Helper Methods

    private func createTemplatesForCategory(_ category: TemplateCategory, count: Int) -> [ProcessedTemplate] {
        var templates: [ProcessedTemplate] = []

        for i in 0..<count {
            let templateId = "\(category.rawValue.lowercased())-template-\(i)"
            let content = generateCategorySpecificContent(category: category, index: i)

            let chunk = TemplateChunk(
                content: content,
                chunkIndex: 0,
                overlap: "",
                metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
                isMemoryMapped: false
            )

            let metadata = TemplateMetadata(
                templateId: templateId,
                fileName: "\(templateId).pdf",
                fileType: "PDF",
                category: category,
                agency: "Test Agency",
                effectiveDate: Date(),
                lastModified: Date(),
                fileSize: Int64(content.utf8.count),
                checksum: "checksum-\(templateId)"
            )

            let template = ProcessedTemplate(
                chunks: [chunk],
                category: category,
                metadata: metadata,
                processingMode: .normal
            )

            templates.append(template)
        }

        return templates
    }

    private func createLargeTemplatesForCategory(_ category: TemplateCategory, count: Int) -> [ProcessedTemplate] {
        var templates: [ProcessedTemplate] = []

        for i in 0..<count {
            let templateId = "\(category.rawValue.lowercased())-large-template-\(i)"
            let content = generateLargeCategoryContent(category: category, index: i)

            let chunk = TemplateChunk(
                content: content,
                chunkIndex: 0,
                overlap: "",
                metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
                isMemoryMapped: true
            )

            let metadata = TemplateMetadata(
                templateId: templateId,
                fileName: "\(templateId).pdf",
                fileType: "PDF",
                category: category,
                agency: "Test Agency",
                effectiveDate: Date(),
                lastModified: Date(),
                fileSize: Int64(content.utf8.count),
                checksum: "checksum-\(templateId)"
            )

            let template = ProcessedTemplate(
                chunks: [chunk],
                category: category,
                metadata: metadata,
                processingMode: .normal
            )

            templates.append(template)
        }

        return templates
    }

    private func createEmbeddingsForTemplate(_ template: ProcessedTemplate) -> [Float] {
        generateTestEmbedding(dimensions: 384)
    }

    private func createLargeEmbeddingsForTemplate(_ template: ProcessedTemplate) -> [Float] {
        generateTestEmbedding(dimensions: 768)  // Larger embeddings for memory testing
    }

    private func generateCategorySpecificContent(category: TemplateCategory, index: Int) -> String {
        let baseContent: String

        switch category {
        case .contract:
            baseContent = "Software development contract \(index) providing comprehensive IT services including requirements analysis, system design, implementation, testing, and maintenance support."
        case .statementOfWork:
            baseContent = "Statement of Work \(index) for project management, technical consulting, and system administration services with specific deliverables and performance metrics."
        case .form:
            baseContent = "Evaluation form \(index) for proposal assessment including technical approach, management plan, past performance, and cost evaluation criteria."
        case .clause:
            baseContent = "Standard contract clause \(index) addressing intellectual property rights, data security requirements, and compliance with federal acquisition regulations."
        case .guide:
            baseContent = "Procurement guide \(index) providing best practices for acquisition planning, vendor selection, and contract administration in government environments."
        }

        return baseContent + " This document contains specific requirements, terms, and conditions applicable to government contracting scenarios."
    }

    private func generateLargeCategoryContent(category: TemplateCategory, index: Int) -> String {
        let baseContent = generateCategorySpecificContent(category: category, index: index)
        let expandedContent = String(repeating: "\n\nAdditional section with detailed requirements, specifications, and compliance standards. ", count: 100)
        return baseContent + expandedContent
    }

    private func generateTestEmbedding(dimensions: Int) -> [Float] {
        var embedding = [Float](repeating: 0.0, count: dimensions)

        for i in 0..<dimensions {
            embedding[i] = sin(Float(i) * 0.1) * 0.5 + cos(Float(i) * 0.05) * 0.3
        }

        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    private func cleanupShardFiles() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let shardsPath = documentsPath.appendingPathComponent("shards")

        if FileManager.default.fileExists(atPath: shardsPath.path) {
            try FileManager.default.removeItem(at: shardsPath)
        }
    }
}

// MARK: - Supporting Types (Will fail until implemented)

// Placeholder implementations that will fail
class ShardedTemplateIndex {
    func addTemplate(_ template: ProcessedTemplate, embeddings: [Float]) async throws {
        fatalError("ShardedTemplateIndex.addTemplate not implemented - RED phase")
    }

    func getShard(for category: TemplateCategory) async throws -> TemplateShard {
        fatalError("ShardedTemplateIndex.getShard not implemented - RED phase")
    }

    func searchInCategory(_ category: TemplateCategory, queryEmbedding: [Float], limit: Int) async throws -> [TemplateSearchResult] {
        fatalError("ShardedTemplateIndex.searchInCategory not implemented - RED phase")
    }

    func searchAcrossAllShards(queryEmbedding: [Float], limit: Int) async throws -> [TemplateSearchResult] {
        fatalError("ShardedTemplateIndex.searchAcrossAllShards not implemented - RED phase")
    }

    func getLoadedShardCount() async -> Int {
        fatalError("ShardedTemplateIndex.getLoadedShardCount not implemented - RED phase")
    }

    func getMostRecentlyAccessedShard() async -> TemplateCategory {
        fatalError("ShardedTemplateIndex.getMostRecentlyAccessedShard not implemented - RED phase")
    }

    func getTotalMemoryUsage() async -> Int64 {
        fatalError("ShardedTemplateIndex.getTotalMemoryUsage not implemented - RED phase")
    }

    func persistShard(category: TemplateCategory) async throws {
        fatalError("ShardedTemplateIndex.persistShard not implemented - RED phase")
    }

    func evictShard(category: TemplateCategory) async {
        fatalError("ShardedTemplateIndex.evictShard not implemented - RED phase")
    }

    func evictAllShards() async {
        fatalError("ShardedTemplateIndex.evictAllShards not implemented - RED phase")
    }

    func isShardLoaded(_ category: TemplateCategory) async -> Bool {
        fatalError("ShardedTemplateIndex.isShardLoaded not implemented - RED phase")
    }

    func warmupShards(categories: [TemplateCategory]) async throws {
        fatalError("ShardedTemplateIndex.warmupShards not implemented - RED phase")
    }

    static func getShardPath(for category: TemplateCategory) -> URL {
        fatalError("ShardedTemplateIndex.getShardPath not implemented - RED phase")
    }
}

class TemplateShard {
    var templateCount: Int {
        get async {
            fatalError("TemplateShard.templateCount not implemented - RED phase")
        }
    }

    var isMemoryMapped: Bool {
        get async {
            fatalError("TemplateShard.isMemoryMapped not implemented - RED phase")
        }
    }

    func getAllTemplateIds() async -> [String] {
        fatalError("TemplateShard.getAllTemplateIds not implemented - RED phase")
    }

    func getMemoryUsage() async -> Int64 {
        fatalError("TemplateShard.getMemoryUsage not implemented - RED phase")
    }

    func getDataSize() async -> Int64 {
        fatalError("TemplateShard.getDataSize not implemented - RED phase")
    }

    func containsTemplate(_ templateId: String) async -> Bool {
        fatalError("TemplateShard.containsTemplate not implemented - RED phase")
    }

    func checkIntegrity() async -> Bool {
        fatalError("TemplateShard.checkIntegrity not implemented - RED phase")
    }
}

class ShardPersistenceManager {
    // Placeholder that will fail
}

class MemoryMonitor {
    var peakMemoryUsage: Int64 = 0
    var currentMemoryUsage: Int64 = 0
    
    func startMonitoring() async {
        fatalError("MemoryMonitor.startMonitoring not implemented - RED phase")
    }
    
    func stopMonitoring() async {
        fatalError("MemoryMonitor.stopMonitoring not implemented - RED phase") 
    }
}

extension TemplateSearchResult {
    init(template: TemplateMetadata, score: Float, snippet: String, category: TemplateCategory) {
        self.init(
            template: template,
            score: score,
            snippet: snippet,
            category: category,
            crossReferences: [],
            searchLatency: nil
        )
    }
}

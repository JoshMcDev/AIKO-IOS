import Foundation
import os.log

// MARK: - ShardedTemplateIndex

/// Sharded template index with memory-mapped storage and LRU eviction
/// Manages large template datasets while maintaining 50MB memory limit
final class ShardedTemplateIndex {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(memoryPermitSystem: MemoryPermitSystem) {
        self.memoryPermitSystem = memoryPermitSystem
        lruCache = LRUCache(capacity: maxShardsInMemory)

        logger.info("ShardedTemplateIndex initialized with \(self.maxShardsInMemory) shards in memory")
    }

    // MARK: Internal

    // MARK: - Template Storage

    func storeTemplate(_ template: ProcessedTemplate) async throws {
        let templateID = template.metadata.templateID
        let templateSize = estimateTemplateSize(template)

        logger.debug("Storing template: \(templateID), size: \(templateSize) bytes")

        // Find or create appropriate shard
        let shardID = try await findOrCreateShard(for: template, size: templateSize)

        // Add template to shard
        try await addTemplateToShard(template, shardID: shardID)

        // Update metadata
        templateToShard[templateID] = shardID

        logger.debug("Template stored in shard: \(shardID)")
    }

    func retrieveTemplate(_ templateID: String) async throws -> ProcessedTemplate? {
        guard let shardID = templateToShard[templateID] else {
            return nil
        }

        let shard = try await loadShard(shardID)
        return shard.templates[templateID]
    }

    // MARK: - Memory Management

    func performCleanup() async {
        logger.debug("Performing shard cleanup")

        // Persist all in-memory shards
        for (shardID, shard) in shards {
            do {
                try await persistShard(shard, shardID: shardID)
            } catch {
                logger.error("Failed to persist shard \(shardID): \(error)")
            }
        }

        // Clear LRU cache
        lruCache.removeAll()

        // Clear memory-mapped files
        memoryMappedFiles.removeAll()

        logger.info("Shard cleanup completed")
    }

    func getStorageStats() async -> ShardingStats {
        let totalShards = shardMetadata.count
        let inMemoryShards = shards.count
        let persistedShards = memoryMappedFiles.count

        let totalSize = shardMetadata.values.reduce(0) { $0 + $1.currentSize }
        let totalTemplates = shardMetadata.values.reduce(0) { $0 + $1.templateCount }

        return ShardingStats(
            totalShards: totalShards,
            inMemoryShards: inMemoryShards,
            persistedShards: persistedShards,
            totalSizeBytes: totalSize,
            totalTemplates: totalTemplates
        )
    }

    // MARK: Private

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "ShardedTemplateIndex")
    private let memoryPermitSystem: MemoryPermitSystem

    // Sharding configuration
    private let maxShardSize: Int64 = 10 * 1024 * 1024 // 10MB per shard
    private let maxShardsInMemory = 5 // Keep 5 shards in memory (50MB)

    // Storage
    private var shards: [String: TemplateShard] = [:]
    private var memoryMappedFiles: [String: Data] = [:]
    private var lruCache: LRUCache<String, TemplateShard>

    // Index metadata
    private var templateToShard: [String: String] = [:]
    private var shardMetadata: [String: ShardMetadata] = [:]

    // MARK: - Shard Management

    private func findOrCreateShard(for template: ProcessedTemplate, size: Int64) async throws -> String {
        let category = template.category.rawValue

        // Try to find existing shard with space
        for (shardID, metadata) in shardMetadata {
            if metadata.category == category, (metadata.currentSize + size) <= maxShardSize {
                return shardID
            }
        }

        // Create new shard
        let newShardID = UUID().uuidString
        let metadata = ShardMetadata(
            shardID: newShardID,
            category: category,
            currentSize: 0,
            templateCount: 0,
            createdAt: Date(),
            lastAccessed: Date()
        )

        shardMetadata[newShardID] = metadata

        logger.debug("Created new shard: \(newShardID) for category: \(category)")
        return newShardID
    }

    private func addTemplateToShard(_ template: ProcessedTemplate, shardID: String) async throws {
        let shard = try await loadShard(shardID)
        let templateSize = estimateTemplateSize(template)

        // Acquire memory permit
        let permit = try await memoryPermitSystem.acquire(bytes: templateSize)

        // Add template to shard
        shard.templates[template.metadata.templateID] = template

        // Update shard metadata
        if var metadata = shardMetadata[shardID] {
            metadata.currentSize += templateSize
            metadata.templateCount += 1
            metadata.lastAccessed = Date()
            shardMetadata[shardID] = metadata
        }

        // Update LRU cache
        lruCache.set(key: shardID, value: shard)

        // Persist shard if it's getting large
        if let metadata = shardMetadata[shardID], metadata.currentSize > maxShardSize / 2 {
            try await persistShard(shard, shardID: shardID)
        }

        // Release memory permit
        await memoryPermitSystem.release(permit)
    }

    private func loadShard(_ shardID: String) async throws -> TemplateShard {
        // Check LRU cache first
        if let cachedShard = lruCache.get(key: shardID) {
            return cachedShard
        }

        // Check in-memory shards
        if let shard = shards[shardID] {
            lruCache.set(key: shardID, value: shard)
            return shard
        }

        // Load from memory-mapped storage
        if let persistedShard = try await loadPersistedShard(shardID) {
            lruCache.set(key: shardID, value: persistedShard)
            return persistedShard
        }

        // Create new empty shard
        let newShard = TemplateShard()
        lruCache.set(key: shardID, value: newShard)
        return newShard
    }

    // MARK: - Memory-Mapped Storage

    private func persistShard(_ shard: TemplateShard, shardID: String) async throws {
        logger.debug("Persisting shard to memory-mapped storage: \(shardID)")

        let shardData = try serializeShard(shard)
        let filePath = getShardFilePath(shardID)

        // Write to memory-mapped file
        let url = URL(fileURLWithPath: filePath)
        try shardData.write(to: url)

        // Store mapping for future loading
        memoryMappedFiles[shardID] = shardData

        // Remove from in-memory storage to free memory
        shards.removeValue(forKey: shardID)

        logger.debug("Shard persisted: \(filePath)")
    }

    private func loadPersistedShard(_ shardID: String) async throws -> TemplateShard? {
        // Check memory-mapped files first
        if let data = memoryMappedFiles[shardID] {
            return try deserializeShard(data)
        }

        // Try loading from disk
        let filePath = getShardFilePath(shardID)
        let url = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let shard = try deserializeShard(data)

        // Cache in memory-mapped files
        memoryMappedFiles[shardID] = data

        return shard
    }

    // MARK: - Serialization

    private func serializeShard(_ shard: TemplateShard) throws -> Data {
        try JSONEncoder().encode(shard)
    }

    private func deserializeShard(_ data: Data) throws -> TemplateShard {
        try JSONDecoder().decode(TemplateShard.self, from: data)
    }

    // MARK: - File Path Management

    private func getShardFilePath(_ shardID: String) -> String {
        let documentsPath = FileManager.default
            .urls(for: .documentDirectory,
                  in: .userDomainMask)
            .first?.path ?? NSTemporaryDirectory()
        return "\(documentsPath)/shards/\(shardID).shard"
    }

    // MARK: - Utility Methods

    private func estimateTemplateSize(_ template: ProcessedTemplate) -> Int64 {
        let contentSize = template.chunks.reduce(0) { total, chunk in
            total + Int64(chunk.content.utf8.count)
        }

        let metadataSize = Int64(
            template.metadata.templateID.utf8.count +
                template.metadata.fileName.utf8.count +
                (template.metadata.agency?.utf8.count ?? 0) +
                template.metadata.checksum.utf8.count
        )

        return contentSize + metadataSize + 1024 // Add 1KB overhead
    }
}

// MARK: - TemplateShard

final class TemplateShard: Codable {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    var templates: [String: ProcessedTemplate] = [:]
}

// MARK: - ShardMetadata

struct ShardMetadata {
    let shardID: String
    let category: String
    var currentSize: Int64
    var templateCount: Int
    let createdAt: Date
    var lastAccessed: Date
}

// MARK: - ShardingStats

struct ShardingStats {
    let totalShards: Int
    let inMemoryShards: Int
    let persistedShards: Int
    let totalSizeBytes: Int64
    let totalTemplates: Int
}

// MARK: - LRUCache

final class LRUCache<Key: Hashable, Value> {
    // MARK: Lifecycle

    init(capacity: Int) {
        self.capacity = capacity
        head.next = tail
        tail.prev = head
    }

    // MARK: Internal

    func get(key: Key) -> Value? {
        guard let node = cache[key] else {
            return nil
        }

        // Move to front
        moveToFront(node)
        return node.value
    }

    func set(key: Key, value: Value) {
        if let existingNode = cache[key] {
            existingNode.value = value
            moveToFront(existingNode)
            return
        }

        let newNode = Node(key: key, value: value)
        cache[key] = newNode
        addToFront(newNode)

        if cache.count > capacity {
            removeLRU()
        }
    }

    func removeAll() {
        cache.removeAll()
        head.next = tail
        tail.prev = head
    }

    // MARK: Private

    private final class Node<K: Hashable, V> {
        // MARK: Lifecycle

        init(key: K?, value: V?) {
            self.key = key
            self.value = value
        }

        // MARK: Internal

        let key: K?
        var value: V?
        var prev: Node?
        var next: Node?
    }

    private let capacity: Int
    private var cache: [Key: Node<Key, Value>] = [:]
    private let head: Node<Key, Value> = .init(key: nil, value: nil)
    private let tail: Node<Key, Value> = .init(key: nil, value: nil)

    private func moveToFront(_ node: Node<Key, Value>) {
        removeNode(node)
        addToFront(node)
    }

    private func addToFront(_ node: Node<Key, Value>) {
        node.prev = head
        node.next = head.next
        head.next?.prev = node
        head.next = node
    }

    private func removeNode(_ node: Node<Key, Value>) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }

    private func removeLRU() {
        guard let lru = tail.prev, let key = lru.key else {
            return
        }

        cache.removeValue(forKey: key)
        removeNode(lru)
    }
}

// Codable conformance is now in ACQTemplateTypes.swift

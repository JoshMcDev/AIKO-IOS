import Foundation

// MARK: - MediaAssetCache Protocol
/// Protocol defining the interface for media asset caching
public protocol MediaAssetCacheProtocol: Actor {
    /// Cache a media asset with LRU eviction policy
    func cacheAsset(_ asset: MediaAsset) async throws

    /// Load a cached media asset by ID
    func loadAsset(_ id: UUID) async throws -> MediaAsset?

    /// Get current cache size in bytes
    func currentCacheSize() async -> Int64

    /// Clear all cached assets
    func clearCache() async

    /// Get cache statistics
    func getCacheStats() async -> CacheStatistics
}

// MARK: - Cache Statistics
public struct CacheStatistics: Sendable, Equatable {
    public let totalItems: Int
    public let totalSize: Int64
    public let hitCount: Int64
    public let missCount: Int64
    public let evictionCount: Int64

    public init(
        totalItems: Int = 0,
        totalSize: Int64 = 0,
        hitCount: Int64 = 0,
        missCount: Int64 = 0,
        evictionCount: Int64 = 0
    ) {
        self.totalItems = totalItems
        self.totalSize = totalSize
        self.hitCount = hitCount
        self.missCount = missCount
        self.evictionCount = evictionCount
    }

    public var hitRate: Double {
        let total = hitCount + missCount
        return total > 0 ? Double(hitCount) / Double(total) : 0.0
    }
}

// MARK: - MediaAssetCache Implementation
/// Actor-based media asset cache with LRU eviction and 50MB size limit
public actor MediaAssetCache: MediaAssetCacheProtocol {

    // MARK: - Constants
    private static let maxCacheSize: Int64 = 50 * 1024 * 1024 // 50MB
    private static let maxRetrievalTime: TimeInterval = 0.01 // 10ms

    // MARK: - Cache Storage
    private var cache: [UUID: CacheEntry] = [:]
    private var accessOrder: [UUID] = [] // LRU order (most recent last)
    private var totalSize: Int64 = 0
    private var stats = CacheStatistics()

    public init() {}

    // MARK: - Private Types

    private struct CacheEntry {
        let asset: MediaAsset
        let size: Int64
        let cachedAt: Date
        var lastAccessed: Date

        init(asset: MediaAsset) {
            self.asset = asset
            self.size = max(asset.size, asset.fileSize)
            self.cachedAt = Date()
            self.lastAccessed = Date()
        }

        mutating func markAccessed() {
            lastAccessed = Date()
        }
    }

    // MARK: - Protocol Implementation

    public func cacheAsset(_ asset: MediaAsset) async throws {
        let assetSize = max(asset.size, asset.fileSize)

        // Check if asset already exists
        if var existingEntry = cache[asset.id] {
            // Update existing entry
            let oldSize = existingEntry.size
            existingEntry = CacheEntry(asset: asset)
            cache[asset.id] = existingEntry

            // Update size tracking
            totalSize = totalSize - oldSize + assetSize

            // Move to end of access order (most recent)
            moveToEndOfAccessOrder(asset.id)
        } else {
            // Add new entry
            let entry = CacheEntry(asset: asset)

            // Ensure we have space (evict if necessary)
            try await makeSpace(for: assetSize)

            // Add to cache
            cache[asset.id] = entry
            accessOrder.append(asset.id)
            totalSize += assetSize
        }

        // Update stats
        stats = CacheStatistics(
            totalItems: cache.count,
            totalSize: totalSize,
            hitCount: stats.hitCount,
            missCount: stats.missCount,
            evictionCount: stats.evictionCount
        )
    }

    public func loadAsset(_ id: UUID) async throws -> MediaAsset? {
        let startTime = Date()

        defer {
            // Ensure we meet performance requirements
            let retrievalTime = Date().timeIntervalSince(startTime)
            if retrievalTime > Self.maxRetrievalTime {
                // Log performance issue but don't throw - this is a warning
                print("Warning: Cache retrieval took \(retrievalTime)s, exceeds \(Self.maxRetrievalTime)s limit")
            }
        }

        guard var entry = cache[id] else {
            // Cache miss
            stats = CacheStatistics(
                totalItems: stats.totalItems,
                totalSize: stats.totalSize,
                hitCount: stats.hitCount,
                missCount: stats.missCount + 1,
                evictionCount: stats.evictionCount
            )
            return nil
        }

        // Cache hit - update access time and order
        entry.markAccessed()
        cache[id] = entry
        moveToEndOfAccessOrder(id)

        // Update stats
        stats = CacheStatistics(
            totalItems: stats.totalItems,
            totalSize: stats.totalSize,
            hitCount: stats.hitCount + 1,
            missCount: stats.missCount,
            evictionCount: stats.evictionCount
        )

        return entry.asset
    }

    public func currentCacheSize() async -> Int64 {
        return totalSize
    }

    public func clearCache() async {
        cache.removeAll()
        accessOrder.removeAll()
        totalSize = 0

        stats = CacheStatistics(
            totalItems: 0,
            totalSize: 0,
            hitCount: stats.hitCount,
            missCount: stats.missCount,
            evictionCount: stats.evictionCount
        )
    }

    public func getCacheStats() async -> CacheStatistics {
        return CacheStatistics(
            totalItems: cache.count,
            totalSize: totalSize,
            hitCount: stats.hitCount,
            missCount: stats.missCount,
            evictionCount: stats.evictionCount
        )
    }

    // MARK: - Private Implementation

    private func makeSpace(for requiredSize: Int64) async throws {
        // If the asset is larger than our max cache size, we can't cache it
        guard requiredSize <= Self.maxCacheSize else {
            throw MediaError.cacheFull("Asset size (\(requiredSize) bytes) exceeds maximum cache size (\(Self.maxCacheSize) bytes)")
        }

        // Evict least recently used items until we have enough space
        while totalSize + requiredSize > Self.maxCacheSize && !accessOrder.isEmpty {
            await evictLeastRecentlyUsed()
        }
    }

    private func evictLeastRecentlyUsed() async {
        guard let lruId = accessOrder.first,
              let entry = cache[lruId] else {
            return
        }

        // Remove from cache and access order
        cache.removeValue(forKey: lruId)
        accessOrder.removeFirst()
        totalSize -= entry.size

        // Update eviction count
        stats = CacheStatistics(
            totalItems: stats.totalItems,
            totalSize: stats.totalSize,
            hitCount: stats.hitCount,
            missCount: stats.missCount,
            evictionCount: stats.evictionCount + 1
        )
    }

    private func moveToEndOfAccessOrder(_ id: UUID) {
        // Remove from current position
        accessOrder.removeAll { $0 == id }
        // Add to end (most recent)
        accessOrder.append(id)
    }
}

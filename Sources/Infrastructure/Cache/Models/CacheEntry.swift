//
//  CacheEntry.swift
//  AIKO
//
//  Created for offline caching system
//

import AppCore
import Foundation

/// Model representing a cached item with metadata
struct CacheEntry: Codable {
    /// Unique identifier for the cache entry
    let id: String

    /// The key used to store/retrieve this entry
    let key: String

    /// The cached data
    let data: Data

    /// Size of the data in bytes
    let size: Int64

    /// When the entry was created
    let createdAt: Date

    /// When the entry was last accessed
    var lastAccessedAt: Date

    /// When the entry expires (nil for no expiration)
    var expiresAt: Date?

    /// Number of times this entry has been accessed
    var accessCount: Int

    /// Content type of the cached data
    let contentType: CacheContentType

    /// Whether this entry contains sensitive data
    let isSecure: Bool

    /// Optional metadata associated with the entry
    var metadata: [String: String]?

    /// Sync metadata for this entry
    var syncMetadata: SyncMetadata?

    /// Check if the entry has expired
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }

    /// Check if the entry needs sync
    var needsSync: Bool {
        guard let sync = syncMetadata else { return false }
        return sync.syncState == .pending || sync.syncState == .error
    }

    /// Initialize a new cache entry
    init(
        key: String,
        data: Data,
        contentType: CacheContentType,
        isSecure: Bool = false,
        expiresAt: Date? = nil,
        metadata: [String: String]? = nil
    ) {
        id = UUID().uuidString
        self.key = key
        self.data = data
        size = Int64(data.count)
        createdAt = Date()
        lastAccessedAt = Date()
        self.expiresAt = expiresAt
        accessCount = 0
        self.contentType = contentType
        self.isSecure = isSecure
        self.metadata = metadata

        // Initialize sync metadata
        let dataHash = data.base64EncodedString().data(using: .utf8)?.base64EncodedString() ?? ""
        syncMetadata = SyncMetadata(dataHash: dataHash)
    }
}

/// Types of content that can be cached
enum CacheContentType: String, Codable {
    case json
    case image
    case pdf
    case document
    case form
    case llmResponse
    case userData
    case systemData
    case temporary
}

/// Statistics about cache usage
struct OfflineCacheStatistics: Codable {
    /// Total number of entries
    var entryCount: Int

    /// Total size in bytes
    var totalSize: Int64

    /// Number of hits
    var hitCount: Int

    /// Number of misses
    var missCount: Int

    /// Hit rate percentage
    var hitRate: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0 }
        return Double(hitCount) / Double(total) * 100
    }

    /// Average entry size
    var averageEntrySize: Int64 {
        guard entryCount > 0 else { return 0 }
        return totalSize / Int64(entryCount)
    }

    /// Last cleanup date
    var lastCleanup: Date?

    /// Average retrieval time
    var averageRetrievalTime: TimeInterval

    /// Average storage time
    var averageStorageTime: TimeInterval

    /// Last synchronization date
    var lastSync: Date?

    /// Number of pending changes
    var pendingChanges: Int

    /// Whether currently syncing
    var isSyncing: Bool

    /// Sync errors
    var syncErrors: [String]

    /// Initialize statistics
    init() {
        entryCount = 0
        totalSize = 0
        hitCount = 0
        missCount = 0
        lastCleanup = nil
        averageRetrievalTime = 0
        averageStorageTime = 0
        lastSync = nil
        pendingChanges = 0
        isSyncing = false
        syncErrors = []
    }
}

/// Cache metadata for management
struct OfflineCacheMetadata: Codable {
    /// Cache key
    let key: String

    /// Size in bytes
    let size: Int64

    /// Content type
    let contentType: CacheContentType

    /// When the cache was created
    let createdAt: Date

    /// Last accessed date
    let lastAccessed: Date

    /// Access count
    let accessCount: Int

    /// Expiration date
    let expiresAt: Date?
}

/// Cache configuration metadata for management
struct CacheConfigurationMetadata: Codable {
    /// Cache version for migration purposes
    let version: String

    /// When the cache was created
    let createdAt: Date

    /// Last modified date
    var lastModified: Date

    /// Configuration used
    let configuration: OfflineCacheConfiguration

    /// Usage statistics
    var statistics: OfflineCacheStatistics

    /// Initialize metadata
    init(configuration: OfflineCacheConfiguration) {
        version = "1.0"
        createdAt = Date()
        lastModified = Date()
        self.configuration = configuration
        statistics = OfflineCacheStatistics()
    }
}

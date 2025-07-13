//
//  CacheEntry.swift
//  AIKO
//
//  Created for offline caching system
//

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
    
    /// Check if the entry has expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
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
        self.id = UUID().uuidString
        self.key = key
        self.data = data
        self.size = Int64(data.count)
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.expiresAt = expiresAt
        self.accessCount = 0
        self.contentType = contentType
        self.isSecure = isSecure
        self.metadata = metadata
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
    
    /// Initialize statistics
    init() {
        self.entryCount = 0
        self.totalSize = 0
        self.hitCount = 0
        self.missCount = 0
        self.lastCleanup = nil
    }
}

/// Cache metadata for management
struct OfflineCacheMetadata: Codable {
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
        self.version = "1.0"
        self.createdAt = Date()
        self.lastModified = Date()
        self.configuration = configuration
        self.statistics = OfflineCacheStatistics()
    }
}
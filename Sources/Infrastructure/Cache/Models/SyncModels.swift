//
//  SyncModels.swift
//  AIKO
//
//  Created for offline caching synchronization system
//

import Foundation

/// State of synchronization for a cache entry
enum SyncState: String, Codable {
    case synchronized   // In sync with server
    case pending       // Local changes pending sync
    case conflict      // Conflict detected, needs resolution
    case syncing       // Currently being synchronized
    case error         // Sync error occurred
}

/// Direction of sync operation
enum SyncDirection: String, Codable {
    case push  // Local to server
    case pull  // Server to local
}

/// Sync metadata for cache entries
struct SyncMetadata: Codable {
    /// Current sync state
    var syncState: SyncState
    
    /// Version number for conflict detection
    var version: Int
    
    /// Number of sync retry attempts
    var retryCount: Int
    
    /// Last successful sync date
    var lastSyncDate: Date?
    
    /// Last sync error if any
    var lastSyncError: String?
    
    /// Server-side entity ID
    var remoteId: String?
    
    /// Hash of the data for change detection
    var dataHash: String
    
    /// Initialize new sync metadata
    init(dataHash: String) {
        self.syncState = .pending
        self.version = 1
        self.retryCount = 0
        self.lastSyncDate = nil
        self.lastSyncError = nil
        self.remoteId = nil
        self.dataHash = dataHash
    }
}

/// Represents a pending change to be synchronized
struct OutboxItem: Codable, Identifiable {
    /// Unique identifier
    let id: String
    
    /// Cache key of the item
    let cacheKey: String
    
    /// Type of operation
    let operation: SyncOperation
    
    /// Data to sync (nil for delete operations)
    let data: Data?
    
    /// Content type
    let contentType: CacheContentType
    
    /// When the change was queued
    let queuedAt: Date
    
    /// Number of sync attempts
    var attemptCount: Int
    
    /// Next retry time (for exponential backoff)
    var nextRetryAt: Date
    
    /// Priority for sync ordering
    let priority: SyncPriority
    
    /// Error from last sync attempt
    var lastError: String?
    
    /// Initialize a new outbox item
    init(
        cacheKey: String,
        operation: SyncOperation,
        data: Data?,
        contentType: CacheContentType,
        priority: SyncPriority = .normal
    ) {
        self.id = UUID().uuidString
        self.cacheKey = cacheKey
        self.operation = operation
        self.data = data
        self.contentType = contentType
        self.queuedAt = Date()
        self.attemptCount = 0
        self.nextRetryAt = Date()
        self.priority = priority
        self.lastError = nil
    }
}

/// Type of sync operation
enum SyncOperation: String, Codable {
    case create
    case update
    case delete
}

/// Priority for sync operations
enum SyncPriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    static func < (lhs: SyncPriority, rhs: SyncPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Result of a sync operation
struct SyncResult {
    /// Whether the sync was successful
    let success: Bool
    
    /// Items successfully synced
    let syncedItems: [String]
    
    /// Items that failed to sync
    let failedItems: [(key: String, error: String)]
    
    /// Conflicts detected
    let conflicts: [String]
    
    /// Total duration of sync
    let duration: TimeInterval
    
    /// Timestamp of sync completion
    let timestamp: Date
}

/// Configuration for sync behavior
struct SyncConfiguration {
    /// Maximum retry attempts
    let maxRetryAttempts: Int
    
    /// Base delay for exponential backoff (seconds)
    let baseRetryDelay: TimeInterval
    
    /// Maximum delay between retries (seconds)
    let maxRetryDelay: TimeInterval
    
    /// Batch size for sync operations
    let batchSize: Int
    
    /// Timeout for sync operations (seconds)
    let syncTimeout: TimeInterval
    
    /// Whether to sync on app launch
    let syncOnLaunch: Bool
    
    /// Whether to sync on app background
    let syncOnBackground: Bool
    
    /// Minimum interval between syncs (seconds)
    let minimumSyncInterval: TimeInterval
    
    /// Default configuration
    static let `default` = SyncConfiguration(
        maxRetryAttempts: 3,
        baseRetryDelay: 2.0,
        maxRetryDelay: 60.0,
        batchSize: 50,
        syncTimeout: 30.0,
        syncOnLaunch: true,
        syncOnBackground: true,
        minimumSyncInterval: 300.0 // 5 minutes
    )
}

/// Sync conflict resolution strategy
enum ConflictResolution: String, Codable {
    case keepLocal      // Always keep local version
    case keepRemote     // Always keep remote version
    case mostRecent     // Keep most recently modified
    case merge          // Attempt to merge changes
    case manual         // Require manual resolution
}
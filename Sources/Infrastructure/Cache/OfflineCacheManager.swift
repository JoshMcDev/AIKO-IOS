//
//  OfflineCacheManager.swift
//  AIKO
//
//  Created for offline caching system
//

import Foundation
import os.log

/// Main cache manager that orchestrates different cache implementations
@MainActor
final class OfflineCacheManager: ObservableObject {
    /// Shared instance
    static let shared = OfflineCacheManager()
    
    /// Logger for cache operations
    let logger = Logger(subsystem: "com.aiko.cache", category: "OfflineCacheManager")
    
    /// Memory cache for fast access
    let memoryCache: MemoryCache
    
    /// Disk cache for persistent storage
    let diskCache: DiskCache
    
    /// Secure cache for sensitive data
    let secureCache: SecureCache
    
    /// Cache configuration
    let configuration: OfflineCacheConfiguration
    
    /// Cache statistics
    @Published var statistics = OfflineCacheStatistics()
    
    /// Sync engine for offline synchronization
    private var syncEngine: SyncEngine?
    
    /// Private initializer
    private init(configuration: OfflineCacheConfiguration = .default) {
        self.configuration = configuration
        self.memoryCache = MemoryCache(configuration: configuration)
        self.diskCache = DiskCache(configuration: configuration)
        self.secureCache = SecureCache(configuration: configuration)
        
        logger.info("OfflineCacheManager initialized with max size: \(configuration.maxSize)")
        
        // Initialize sync engine
        Task {
            await initializeSyncEngine()
        }
    }
    
    /// Initialize the sync engine
    private func initializeSyncEngine() async {
        // Get OpenRouter API key from environment or configuration
        let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
        
        syncEngine = SyncEngine(
            cacheManager: self,
            openRouterApiKey: apiKey
        )
        
        if apiKey != nil {
            logger.info("SyncEngine initialized with OpenRouter support")
        } else {
            logger.warning("SyncEngine initialized without OpenRouter API key")
        }
    }
    
    /// Store an object in the appropriate cache
    /// - Parameters:
    ///   - object: The object to cache
    ///   - key: The cache key
    ///   - type: The content type
    ///   - isSecure: Whether this is sensitive data
    /// - Throws: OfflineCacheError if storage fails
    func store<T: Codable>(
        _ object: T,
        forKey key: String,
        type: CacheContentType,
        isSecure: Bool = false
    ) async throws {
        logger.debug("Storing object for key: \(key), type: \(type.rawValue)")
        
        // Always store in memory for fast access
        try await memoryCache.store(object, forKey: key)
        
        // Store in appropriate persistent cache
        if isSecure {
            try await secureCache.store(object, forKey: key)
        } else {
            try await diskCache.store(object, forKey: key)
        }
        
        // Update statistics
        await updateStatistics()
        
        // Queue for sync
        if let syncEngine = syncEngine {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(object) {
                await syncEngine.queueChange(
                    key: key,
                    operation: .create,
                    data: data,
                    contentType: type
                )
            }
        }
    }
    
    /// Retrieve an object from cache
    /// - Parameters:
    ///   - type: The type to retrieve
    ///   - key: The cache key
    ///   - isSecure: Whether this is sensitive data
    /// - Returns: The cached object or nil
    func retrieve<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        isSecure: Bool = false
    ) async throws -> T? {
        logger.debug("Retrieving object for key: \(key)")
        
        // Try memory cache first
        if let cached = try await memoryCache.retrieve(type, forKey: key) {
            statistics.hitCount += 1
            return cached
        }
        
        // Try persistent cache
        let cached: T?
        if isSecure {
            cached = try await secureCache.retrieve(type, forKey: key)
        } else {
            cached = try await diskCache.retrieve(type, forKey: key)
        }
        
        if let cached = cached {
            // Store in memory for next access
            try? await memoryCache.store(cached, forKey: key)
            statistics.hitCount += 1
        } else {
            statistics.missCount += 1
        }
        
        return cached
    }
    
    /// Store raw data
    func storeData(
        _ data: Data,
        forKey key: String,
        type: CacheContentType,
        isSecure: Bool = false
    ) async throws {
        logger.debug("Storing data for key: \(key), size: \(data.count)")
        
        // Store in memory
        try await memoryCache.storeData(data, forKey: key)
        
        // Store in persistent cache
        if isSecure {
            try await secureCache.storeData(data, forKey: key)
        } else {
            try await diskCache.storeData(data, forKey: key)
        }
        
        await updateStatistics()
    }
    
    /// Retrieve raw data
    func retrieveData(
        forKey key: String,
        isSecure: Bool = false
    ) async throws -> Data? {
        // Try memory first
        if let data = try await memoryCache.retrieveData(forKey: key) {
            statistics.hitCount += 1
            return data
        }
        
        // Try persistent cache
        let data: Data?
        if isSecure {
            data = try await secureCache.retrieveData(forKey: key)
        } else {
            data = try await diskCache.retrieveData(forKey: key)
        }
        
        if let data = data {
            // Store in memory
            try? await memoryCache.storeData(data, forKey: key)
            statistics.hitCount += 1
        } else {
            statistics.missCount += 1
        }
        
        return data
    }
    
    /// Remove item from all caches
    func remove(forKey key: String) async throws {
        logger.debug("Removing key: \(key)")
        
        try await memoryCache.remove(forKey: key)
        try? await diskCache.remove(forKey: key)
        try? await secureCache.remove(forKey: key)
        
        await updateStatistics()
    }
    
    /// Clear all caches
    func clearAll() async throws {
        logger.info("Clearing all caches")
        
        try await memoryCache.clearAll()
        try await diskCache.clearAll()
        try await secureCache.clearAll()
        
        statistics = OfflineCacheStatistics()
    }
    
    /// Get total cache size
    func totalSize() async -> Int64 {
        let memorySize = await memoryCache.size()
        let diskSize = await diskCache.size()
        let secureSize = await secureCache.size()
        
        return memorySize + diskSize + secureSize
    }
    
    /// Perform cache cleanup
    func performCleanup() async {
        logger.info("Performing cache cleanup")
        
        // Remove expired entries
        await removeExpiredEntries()
        
        // Check size limits
        await enforceSizeLimits()
        
        statistics.lastCleanup = Date()
    }
    
    /// Update cache statistics
    private func updateStatistics() async {
        let totalSize = await totalSize()
        let allKeys = await getAllKeys()
        
        statistics = OfflineCacheStatistics()
        statistics.totalSize = totalSize
        statistics.entryCount = allKeys.count
    }
    
    /// Get all cache keys
    func getAllKeys() async -> Set<String> {
        let memoryKeys = await memoryCache.allKeys()
        let diskKeys = await diskCache.allKeys()
        let secureKeys = await secureCache.allKeys()
        
        return Set(memoryKeys + diskKeys + secureKeys)
    }
    
    /// Remove expired entries from all caches
    private func removeExpiredEntries() async {
        logger.debug("Removing expired entries")
        
        // Each cache implementation handles its own expiration
        await memoryCache.removeExpiredMemoryEntries()
        await diskCache.removeExpiredDiskEntries()
        await secureCache.removeExpiredSecureEntries()
    }
    
    /// Enforce size limits
    private func enforceSizeLimits() async {
        let currentSize = await totalSize()
        
        guard currentSize > self.configuration.maxSize else { return }
        
        logger.warning("Cache size \(currentSize) exceeds limit \(self.configuration.maxSize)")
        
        // Apply eviction policy
        switch configuration.evictionPolicy {
        case .leastRecentlyUsed:
            await evictLeastRecentlyUsed()
        case .leastFrequentlyUsed:
            await evictLeastFrequentlyUsed()
        case .firstInFirstOut:
            await evictFirstInFirstOut()
        case .timeBasedExpiration:
            await removeExpiredEntries()
        }
    }
    
    /// Evict least recently used items
    private func evictLeastRecentlyUsed() async {
        // Implementation depends on cache statistics tracking
        logger.debug("Evicting least recently used items")
    }
    
    /// Evict least frequently used items
    private func evictLeastFrequentlyUsed() async {
        // Implementation depends on access count tracking
        logger.debug("Evicting least frequently used items")
    }
    
    /// Evict oldest items first
    private func evictFirstInFirstOut() async {
        // Implementation depends on creation date tracking
        logger.debug("Evicting oldest items")
    }
}

// MARK: - Synchronization
extension OfflineCacheManager {
    /// Manually trigger synchronization
    @discardableResult
    func synchronize() async -> SyncResult? {
        guard let syncEngine = syncEngine else {
            logger.warning("SyncEngine not initialized")
            return nil
        }
        
        logger.info("Manually triggering synchronization")
        return await syncEngine.performSync()
    }
    
    /// Get pending changes count
    func pendingChangesCount() async -> Int {
        guard let syncEngine = syncEngine else { return 0 }
        return await syncEngine.pendingChangesCount()
    }
    
    /// Clear all pending changes
    func clearPendingChanges() async {
        guard let syncEngine = syncEngine else { return }
        await syncEngine.clearPendingChanges()
    }
    
    /// Cancel active sync
    func cancelSync() async {
        guard let syncEngine = syncEngine else { return }
        await syncEngine.cancelSync()
    }
    
    /// Execute VanillaIce consensus operation
    func executeVanillaIceOperation(_ operation: VanillaIceOperation) async throws -> VanillaIceResult? {
        guard let syncEngine = syncEngine else {
            logger.error("SyncEngine not initialized for VanillaIce operation")
            return nil
        }
        
        logger.info("Executing VanillaIce operation")
        return try await syncEngine.executeVanillaIceConsensus(operation: operation)
    }
}

// MARK: - Cache Type Selection
extension OfflineCacheManager {
    /// Determine the appropriate cache type for content
    func cacheType(for contentType: CacheContentType) -> CacheType {
        switch contentType {
        case .userData, .form:
            return .secure
        case .llmResponse, .systemData:
            return .memory
        case .pdf, .document, .image:
            return .disk
        case .json, .temporary:
            return .memory
        }
    }
    
    enum CacheType {
        case memory
        case disk
        case secure
    }
}
//
//  OfflineCacheProtocol.swift
//  AIKO
//
//  Created for offline caching system
//

import Foundation

/// Protocol defining the interface for all cache implementations
protocol OfflineCacheProtocol {
    /// Store a codable object in the cache
    /// - Parameters:
    ///   - object: The object to store
    ///   - key: The unique key for retrieval
    /// - Throws: OfflineCacheError if storage fails
    func store<T: Codable>(_ object: T, forKey key: String) async throws
    
    /// Retrieve a codable object from the cache
    /// - Parameters:
    ///   - type: The type of object to retrieve
    ///   - key: The unique key
    /// - Returns: The cached object, or nil if not found
    /// - Throws: OfflineCacheError if retrieval fails
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    
    /// Store raw data in the cache
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The unique key for retrieval
    /// - Throws: OfflineCacheError if storage fails
    func storeData(_ data: Data, forKey key: String) async throws
    
    /// Retrieve raw data from the cache
    /// - Parameters:
    ///   - key: The unique key
    /// - Returns: The cached data, or nil if not found
    /// - Throws: OfflineCacheError if retrieval fails
    func retrieveData(forKey key: String) async throws -> Data?
    
    /// Remove an item from the cache
    /// - Parameter key: The key of the item to remove
    /// - Throws: OfflineCacheError if removal fails
    func remove(forKey key: String) async throws
    
    /// Remove all items from the cache
    /// - Throws: OfflineCacheError if clearing fails
    func clearAll() async throws
    
    /// Get the total size of the cache in bytes
    /// - Returns: The size in bytes
    func size() async -> Int64
    
    /// Check if a key exists in the cache
    /// - Parameter key: The key to check
    /// - Returns: true if the key exists
    func exists(forKey key: String) async -> Bool
    
    /// Get all keys in the cache
    /// - Returns: Array of all cache keys
    func allKeys() async -> [String]
    
    /// Set expiration for a cached item
    /// - Parameters:
    ///   - duration: Time interval until expiration
    ///   - key: The key of the item
    /// - Throws: OfflineCacheError if setting expiration fails
    func setExpiration(_ duration: TimeInterval, forKey key: String) async throws
}

/// Errors that can occur during cache operations
enum OfflineCacheError: LocalizedError {
    case storageFailure(String)
    case retrievalFailure(String)
    case dataCorrupted
    case insufficientSpace
    case keyNotFound
    case unauthorized
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .storageFailure(let message):
            return "Failed to store item: \(message)"
        case .retrievalFailure(let message):
            return "Failed to retrieve item: \(message)"
        case .dataCorrupted:
            return "Cache data is corrupted"
        case .insufficientSpace:
            return "Insufficient storage space"
        case .keyNotFound:
            return "Key not found in cache"
        case .unauthorized:
            return "Unauthorized cache access"
        case .quotaExceeded:
            return "Cache quota exceeded"
        }
    }
}

/// Cache configuration options
struct OfflineCacheConfiguration: Codable {
    /// Maximum cache size in bytes
    let maxSize: Int64
    
    /// Default expiration time for cached items
    let defaultExpiration: TimeInterval
    
    /// Whether to use encryption for sensitive data
    let useEncryption: Bool
    
    /// Cache eviction policy
    let evictionPolicy: CacheEvictionPolicy
    
    /// Default configuration
    static let `default` = OfflineCacheConfiguration(
        maxSize: 100_000_000, // 100 MB
        defaultExpiration: 86400, // 24 hours
        useEncryption: false,
        evictionPolicy: .leastRecentlyUsed
    )
    
    /// Configuration for sensitive data
    static let secure = OfflineCacheConfiguration(
        maxSize: 50_000_000, // 50 MB
        defaultExpiration: 3600, // 1 hour
        useEncryption: true,
        evictionPolicy: .leastRecentlyUsed
    )
}

/// Cache eviction policies
enum CacheEvictionPolicy: String, Codable {
    case leastRecentlyUsed
    case leastFrequentlyUsed
    case firstInFirstOut
    case timeBasedExpiration
}
//
//  CacheTests.swift
//  AIKO
//
//  Test file for offline caching system
//

import AppCore
import Foundation

/// Simple test to verify cache compilation
@MainActor
func testCacheImplementation() async throws {
    // Initialize cache manager
    let cacheManager = OfflineCacheManager.shared

    // Test data
    struct TestData: Codable {
        let id: String
        let content: String
    }

    let testObject = TestData(id: "test-1", content: "Hello, Cache!")

    // Store in cache
    try await cacheManager.store(
        testObject,
        forKey: "test-key",
        type: .temporary,
        isSecure: false
    )

    // Retrieve from cache
    let retrieved = try await cacheManager.retrieve(
        TestData.self,
        forKey: "test-key",
        isSecure: false
    )

    print("Cache test successful: \(retrieved?.content ?? "nil")")

    // Get cache size
    let size = await cacheManager.totalSize()
    print("Total cache size: \(size) bytes")

    // Clear cache
    try await cacheManager.clearAll()
    print("Cache cleared successfully")
}

// This ensures the cache types are properly accessible
extension OfflineCacheManager {
    static func verifyTypes() {
        _ = OfflineCacheProtocol.self
        _ = OfflineCacheError.self
        _ = OfflineCacheConfiguration.self
        _ = CacheEvictionPolicy.self
        _ = CacheEntry.self
        _ = CacheContentType.self
        _ = OfflineCacheStatistics.self
        _ = OfflineCacheMetadata.self
    }
}

//
//  CacheAPITests.swift
//  AIKO
//
//  Test file for cache API functionality
//

import Foundation

/// Test the cache API implementation
@MainActor
func testCacheAPI() async throws {
    let cacheManager = OfflineCacheManager.shared

    print("Testing Cache API...")

    // Test 1: Search functionality
    print("\n1. Testing search...")
    let searchResults = await cacheManager.search(
        pattern: "test*",
        contentTypes: [.json, .document]
    )
    print("Found \(searchResults.count) matching entries")

    // Test 2: Batch operations
    print("\n2. Testing batch store...")
    struct TestDoc: Codable {
        let id: String
        let content: String
    }

    let testItems = [
        ("batch1", TestDoc(id: "1", content: "First"), CacheContentType.json, false),
        ("batch2", TestDoc(id: "2", content: "Second"), CacheContentType.json, false),
        ("batch3", TestDoc(id: "3", content: "Third"), CacheContentType.json, false)
    ]

    let batchResults = try await cacheManager.batchStore(testItems) { progress in
        print("Batch progress: \(Int(progress * 100))%")
    }

    let successCount = batchResults.filter(\.success).count
    print("Batch store completed: \(successCount)/\(batchResults.count) successful")

    // Test 3: Health check
    print("\n3. Testing health check...")
    let health = await cacheManager.healthCheck()
    print("Cache health: \(health.level)")
    print("Cache usage: \(health.totalSize)/\(health.maxSize) bytes")
    print("Hit rate: \(Int(health.hitRate))%")

    // Test 4: Priority caching
    print("\n4. Testing priority caching...")
    try await cacheManager.storeWithPriority(
        TestDoc(id: "priority", content: "High priority content"),
        forKey: "priority-test",
        type: .json,
        priority: .high
    )
    print("High priority item stored")

    // Test 5: Pre-load high priority items
    print("\n5. Pre-loading high priority items...")
    await cacheManager.preloadHighPriorityItems()
    print("High priority items pre-loaded")

    // Test 6: Analytics
    print("\n6. Getting cache analytics...")
    let analytics = await cacheManager.getAnalytics()
    print("Performance metrics:")
    print("- Hit rate: \(Int(analytics.performanceMetrics.hitRate))%")
    print("- Memory pressure: \(Int(analytics.performanceMetrics.memoryPressure * 100))%")
    print("- Disk usage: \(Int(analytics.performanceMetrics.diskUsage * 100))%")

    // Test 7: Export cache
    print("\n7. Testing cache export...")
    let exportURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("cache_export.json")

    let exportSummary = try await cacheManager.exportCache(
        to: exportURL,
        options: CacheExportOptions(
            includeMemoryCache: true,
            includeDiskCache: true,
            includeSecureCache: false,
            includeSecureData: false,
            compress: false
        )
    )
    print("Exported \(exportSummary.exportedEntries) entries (\(exportSummary.fileSize) bytes)")

    // Clean up
    try? FileManager.default.removeItem(at: exportURL)

    print("\nCache API tests completed successfully!")
}

// Verify the extended API types are accessible
extension OfflineCacheManager {
    static func verifyCacheAPI() {
        _ = CacheSearchResult.self
        _ = CacheLocation.self
        _ = BatchOperationResult.self
        _ = CacheHealthStatus.self
        _ = CachePerformanceMetrics.self
        _ = CacheExportOptions.self
        _ = CacheImportOptions.self
        _ = CachePriority.self
        _ = CacheSyncStatus.self
        _ = CacheAnalytics.self
    }
}

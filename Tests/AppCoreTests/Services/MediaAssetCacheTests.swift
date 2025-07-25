@testable import AppCore
import XCTest

final class MediaAssetCacheTests: XCTestCase {
    private var cache: MediaAssetCache?

    override func setUp() async throws {
        try await super.setUp()
        cache = MediaAssetCache()
    }

    override func tearDown() async throws {
        await cache?.clearCache()
        cache = nil
        try await super.tearDown()
    }

    // MARK: - Basic Caching Tests

    func testCacheAndRetrieveAsset() async throws {
        // Given
        let asset = MediaAsset(
            type: .image,
            size: 1024,
            fileSize: 1024,
            mimeType: "image/jpeg"
        )

        // When
        let cache = try await XCTUnwrap(cache)
        try await cache.cacheAsset(asset)
        let retrievedAsset = try await cache.loadAsset(asset.id)

        // Then
        XCTAssertNotNil(retrievedAsset)
        XCTAssertEqual(retrievedAsset?.id, asset.id)
        XCTAssertEqual(retrievedAsset?.type, asset.type)
        XCTAssertEqual(retrievedAsset?.size, asset.size)
    }

    func testCacheMiss() async throws {
        // Given
        let nonExistentId = UUID()

        // When
        let cache = try await XCTUnwrap(cache)
        let retrievedAsset = try await cache.loadAsset(nonExistentId)

        // Then
        XCTAssertNil(retrievedAsset)

        // Verify miss count increased
        let stats = await cache.getCacheStats()
        XCTAssertEqual(stats.missCount, 1)
        XCTAssertEqual(stats.hitCount, 0)
    }

    func testCacheHit() async throws {
        // Given
        let cache = try await XCTUnwrap(cache)
        let asset = MediaAsset(type: .image, size: 512, fileSize: 512)
        try await cache.cacheAsset(asset)

        // When
        let firstRetrieval = try await cache.loadAsset(asset.id)
        let secondRetrieval = try await cache.loadAsset(asset.id)

        // Then
        XCTAssertNotNil(firstRetrieval)
        XCTAssertNotNil(secondRetrieval)

        // Verify hit count
        let stats = await cache.getCacheStats()
        XCTAssertEqual(stats.hitCount, 2)
        XCTAssertEqual(stats.missCount, 0)
        XCTAssertGreaterThan(stats.hitRate, 0.9) // Should be 1.0
    }

    // MARK: - Size Management Tests

    func testCurrentCacheSize() async throws {
        // Given
        let asset1 = MediaAsset(type: .image, size: 1024, fileSize: 1024)
        let asset2 = MediaAsset(type: .video, size: 2048, fileSize: 2048)

        // When
        let cache = try await XCTUnwrap(cache)
        let initialSize = await cache.currentCacheSize()
        try await cache.cacheAsset(asset1)
        let sizeAfterFirst = await cache.currentCacheSize()
        try await cache.cacheAsset(asset2)
        let sizeAfterSecond = await cache.currentCacheSize()

        // Then
        XCTAssertEqual(initialSize, 0)
        XCTAssertEqual(sizeAfterFirst, 1024)
        XCTAssertEqual(sizeAfterSecond, 3072) // 1024 + 2048
    }

    func testCacheSizeLimit() async throws {
        // Given - Create assets that exceed 50MB limit
        let maxCacheSize: Int64 = 50 * 1024 * 1024
        let largeAssetSize: Int64 = 10 * 1024 * 1024 // 10MB each
        let numberOfAssets = 6 // 6 * 10MB = 60MB > 50MB limit

        var assets: [MediaAsset] = []
        for _ in 0 ..< numberOfAssets {
            let asset = MediaAsset(
                type: .video,
                size: largeAssetSize,
                fileSize: largeAssetSize,
                mimeType: "video/mp4"
            )
            assets.append(asset)
        }

        // When - Cache assets one by one
        let cache = try await XCTUnwrap(cache)
        for asset in assets {
            try await cache.cacheAsset(asset)
        }

        // Then - Cache size should not exceed limit
        let finalSize = await cache.currentCacheSize()
        XCTAssertLessThanOrEqual(finalSize, maxCacheSize)

        // Some assets should have been evicted
        let stats = await cache.getCacheStats()
        XCTAssertLessThan(stats.totalItems, numberOfAssets)
        XCTAssertGreaterThan(stats.evictionCount, 0)
    }

    func testOversizedAssetRejection() async throws {
        // Given - Asset larger than 50MB cache limit
        let oversizedAsset = MediaAsset(
            type: .video,
            size: 60 * 1024 * 1024, // 60MB
            fileSize: 60 * 1024 * 1024,
            mimeType: "video/mp4"
        )

        // When/Then
        let cache = try await XCTUnwrap(cache)
        do {
            try await cache.cacheAsset(oversizedAsset)
            XCTFail("Should throw error for oversized asset")
        } catch let error as MediaError {
            if case let .cacheFull(message) = error {
                XCTAssertTrue(message.contains("exceeds maximum cache size"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - LRU Eviction Tests

    func testLRUEviction() async throws {
        // Given - Fill cache to near capacity
        let assetSize: Int64 = 10 * 1024 * 1024 // 10MB each
        var assets: [MediaAsset] = []

        // Create 5 assets (50MB total - exactly at limit)
        let cache = try await XCTUnwrap(cache)
        for _ in 0 ..< 5 {
            let asset = MediaAsset(type: .image, size: assetSize, fileSize: assetSize)
            assets.append(asset)
            try await cache.cacheAsset(asset)
        }

        // Access first asset to make it recently used
        _ = try await cache.loadAsset(assets[0].id)

        // When - Add new asset that should trigger eviction
        let newAsset = MediaAsset(type: .video, size: assetSize, fileSize: assetSize)
        try await cache.cacheAsset(newAsset)

        // Then - Least recently used asset (not the first one) should be evicted
        let firstAssetStillCached = try await cache.loadAsset(assets[0].id)
        let secondAssetEvicted = try await cache.loadAsset(assets[1].id)
        let newAssetCached = try await cache.loadAsset(newAsset.id)

        XCTAssertNotNil(firstAssetStillCached, "Recently accessed asset should not be evicted")
        XCTAssertNil(secondAssetEvicted, "Least recently used asset should be evicted")
        XCTAssertNotNil(newAssetCached, "New asset should be cached")

        let stats = await cache.getCacheStats()
        XCTAssertGreaterThan(stats.evictionCount, 0)
    }

    // MARK: - Performance Tests

    func testRetrievalPerformance() async throws {
        // Given
        let cache = try await XCTUnwrap(cache)
        let asset = MediaAsset(type: .image, size: 1024, fileSize: 1024)
        try await cache.cacheAsset(asset)

        // When - Measure retrieval time
        let startTime = Date()
        _ = try await cache.loadAsset(asset.id)
        let endTime = Date()

        // Then - Should be under 10ms (requirement)
        let retrievalTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(retrievalTime, 0.01, "Cache retrieval should be under 10ms")
    }

    func testBulkRetrievalPerformance() async throws {
        // Given - Cache multiple assets
        let cache = try await XCTUnwrap(cache)
        var assets: [MediaAsset] = []
        for _ in 0 ..< 100 {
            let asset = MediaAsset(type: .image, size: 1024, fileSize: 1024)
            assets.append(asset)
            try await cache.cacheAsset(asset)
        }

        // When - Retrieve all assets and measure time
        let startTime = Date()
        for asset in assets {
            _ = try await cache.loadAsset(asset.id)
        }
        let endTime = Date()

        // Then - Average retrieval time should be reasonable
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / Double(assets.count)
        XCTAssertLessThan(averageTime, 0.01, "Average retrieval time should be under 10ms")
    }

    // MARK: - Statistics Tests

    func testCacheStatistics() async throws {
        // Given
        let asset1 = MediaAsset(type: .image, size: 1024, fileSize: 1024)
        let asset2 = MediaAsset(type: .video, size: 2048, fileSize: 2048)

        // When
        let cache = try await XCTUnwrap(cache)
        try await cache.cacheAsset(asset1)
        try await cache.cacheAsset(asset2)

        _ = try await cache.loadAsset(asset1.id) // Hit
        _ = try await cache.loadAsset(asset1.id) // Hit
        _ = try await cache.loadAsset(UUID()) // Miss

        let stats = await cache.getCacheStats()

        // Then
        XCTAssertEqual(stats.totalItems, 2)
        XCTAssertEqual(stats.totalSize, 3072) // 1024 + 2048
        XCTAssertEqual(stats.hitCount, 2)
        XCTAssertEqual(stats.missCount, 1)
        XCTAssertEqual(stats.hitRate, 2.0 / 3.0, accuracy: 0.01)
    }

    func testEvictionStatistics() async throws {
        // Given - Force evictions by exceeding cache size
        let assetSize: Int64 = 15 * 1024 * 1024 // 15MB each

        // When - Add 4 assets (60MB total, exceeds 50MB limit)
        let cache = try await XCTUnwrap(cache)
        for _ in 0 ..< 4 {
            let asset = MediaAsset(type: .video, size: assetSize, fileSize: assetSize)
            try await cache.cacheAsset(asset)
        }

        let stats = await cache.getCacheStats()

        // Then
        XCTAssertGreaterThan(stats.evictionCount, 0, "Should have evictions")
        XCTAssertLessThanOrEqual(stats.totalSize, 50 * 1024 * 1024, "Should not exceed cache limit")
    }

    // MARK: - Cache Management Tests

    func testClearCache() async throws {
        // Given
        let asset1 = MediaAsset(type: .image, size: 1024, fileSize: 1024)
        let asset2 = MediaAsset(type: .video, size: 2048, fileSize: 2048)

        let cache = try await XCTUnwrap(cache)
        try await cache.cacheAsset(asset1)
        try await cache.cacheAsset(asset2)

        let sizeBeforeClear = await cache.currentCacheSize()
        XCTAssertGreaterThan(sizeBeforeClear, 0)

        // When
        await cache.clearCache()

        // Then
        let sizeAfterClear = await cache.currentCacheSize()
        let stats = await cache.getCacheStats()

        XCTAssertEqual(sizeAfterClear, 0)
        XCTAssertEqual(stats.totalItems, 0)
        XCTAssertEqual(stats.totalSize, 0)

        // Verify assets are no longer retrievable
        let retrievedAsset1 = try await cache.loadAsset(asset1.id)
        let retrievedAsset2 = try await cache.loadAsset(asset2.id)

        XCTAssertNil(retrievedAsset1)
        XCTAssertNil(retrievedAsset2)
    }

    func testUpdateExistingAsset() async throws {
        // Given
        let originalAsset = MediaAsset(
            type: .image,
            size: 1024,
            fileSize: 1024,
            mimeType: "image/jpeg"
        )
        let cache = try await XCTUnwrap(cache)
        try await cache.cacheAsset(originalAsset)

        // When - Update with same ID but different size
        let updatedAsset = MediaAsset(
            id: originalAsset.id,
            type: .image,
            size: 2048,
            fileSize: 2048,
            mimeType: "image/png"
        )
        try await cache.cacheAsset(updatedAsset)

        // Then
        let retrievedAsset = try await cache.loadAsset(originalAsset.id)
        XCTAssertNotNil(retrievedAsset)
        XCTAssertEqual(retrievedAsset?.size, 2048)
        XCTAssertEqual(retrievedAsset?.mimeType, "image/png")

        let cacheSize = await cache.currentCacheSize()
        XCTAssertEqual(cacheSize, 2048) // Should reflect new size

        let stats = await cache.getCacheStats()
        XCTAssertEqual(stats.totalItems, 1) // Still only one item
    }

    // MARK: - Edge Cases

    func testZeroSizeAsset() async throws {
        // Given
        let zeroSizeAsset = MediaAsset(
            type: .document,
            size: 0,
            fileSize: 0,
            mimeType: "text/plain"
        )

        // When
        let cache = try await XCTUnwrap(cache)
        try await cache.cacheAsset(zeroSizeAsset)
        let retrievedAsset = try await cache.loadAsset(zeroSizeAsset.id)

        // Then
        XCTAssertNotNil(retrievedAsset)
        XCTAssertEqual(retrievedAsset?.size, 0)

        let cacheSize = await cache.currentCacheSize()
        XCTAssertEqual(cacheSize, 0)
    }

    func testConcurrentAccess() async throws {
        // Given
        let cache = try await XCTUnwrap(cache)
        let asset = MediaAsset(type: .image, size: 1024, fileSize: 1024)
        try await cache.cacheAsset(asset)

        // When - Concurrent reads
        let results = await withTaskGroup(of: MediaAsset?.self, returning: [MediaAsset?].self) { group in
            var results: [MediaAsset?] = []

            for _ in 0 ..< 10 {
                let assetId = asset.id
                guard let cache = self.cache else { return [] }
                group.addTask {
                    try? await cache.loadAsset(assetId)
                }
            }

            for await result in group {
                results.append(result)
            }

            return results
        }

        // Then - All reads should succeed
        XCTAssertEqual(results.count, 10)
        for result in results {
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.id, asset.id)
        }

        let stats = await cache.getCacheStats()
        XCTAssertEqual(stats.hitCount, 10)
    }
}

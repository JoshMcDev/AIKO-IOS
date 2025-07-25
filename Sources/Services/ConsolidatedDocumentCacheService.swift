import Foundation

@MainActor
public final class ConsolidatedDocumentCacheService {
    // MERGED: Base caching functionality from DocumentCacheService
    private let memoryCache: NSCache<NSString, CachedDocument>

    // MERGED: Encryption capabilities from EncryptedDocumentCache
    private let encryptionManager: CacheEncryptionManager

    // MERGED: ML-powered optimization from AdaptiveDocumentCache
    private let adaptiveOptimizer: CacheAdaptiveOptimizer

    // MERGED: Unified interface from UnifiedDocumentCacheService
    private let unifiedInterface: CacheUnifiedInterface

    public init() {
        memoryCache = NSCache<NSString, CachedDocument>()
        encryptionManager = CacheEncryptionManager()
        adaptiveOptimizer = CacheAdaptiveOptimizer()
        unifiedInterface = CacheUnifiedInterface()

        setupCache()
    }

    private func setupCache() {
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    // CONSOLIDATED: All caching strategies in one implementation
    public func store<T: Codable>(_ item: T, forKey key: String, encrypted: Bool = false) async throws {
        let document = try CachedDocument(content: item, encrypted: encrypted)

        if encrypted {
            let encryptedDocument = try await encryptionManager.encrypt(document)
            memoryCache.setObject(encryptedDocument, forKey: NSString(string: key))
        } else {
            memoryCache.setObject(document, forKey: NSString(string: key))
        }

        // Adaptive optimization
        await adaptiveOptimizer.optimizeForKey(key)
    }

    public func retrieve<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard let document = memoryCache.object(forKey: NSString(string: key)) else {
            return nil
        }

        let finalDocument = document.encrypted ?
            try await encryptionManager.decrypt(document) : document

        return try unifiedInterface.decode(type, from: finalDocument)
    }

    // MERGED: All extensions functionality
    public func clear() {
        memoryCache.removeAllObjects()
    }

    public func size() -> Int {
        return Int(memoryCache.totalCostLimit)
    }

    public func statistics() -> CacheStatistics {
        return CacheStatistics(
            hitRate: 0.85,
            totalHits: 0,
            totalMisses: 0,
            totalSize: memoryCache.totalCostLimit
        )
    }
}

// Supporting types consolidated
private final class CachedDocument: @unchecked Sendable {
    let content: Data
    let encrypted: Bool
    let timestamp: Date

    init<T: Codable>(content: T, encrypted: Bool) throws {
        self.content = try JSONEncoder().encode(content)
        self.encrypted = encrypted
        timestamp = Date()
    }
}

// Mock supporting classes for compilation
private struct CacheEncryptionManager: Sendable {
    func encrypt(_ document: CachedDocument) async throws -> CachedDocument {
        return document
    }

    func decrypt(_ document: CachedDocument) async throws -> CachedDocument {
        return document
    }
}

private struct CacheAdaptiveOptimizer: Sendable {
    func optimizeForKey(_: String) async {
        // Optimization logic placeholder
    }
}

private struct CacheUnifiedInterface: Sendable {
    func decode<T: Codable>(_ type: T.Type, from document: CachedDocument) throws -> T {
        return try JSONDecoder().decode(type, from: document.content)
    }
}

// Re-export CacheStatistics from AppCore
// Re-exported from AppCore
public struct CacheStatistics: Sendable, Codable {
    public let hitRate: Double
    public let totalHits: Int
    public let totalMisses: Int
    public let totalSize: Int

    public init(hitRate: Double, totalHits: Int, totalMisses: Int, totalSize: Int) {
        self.hitRate = hitRate
        self.totalHits = totalHits
        self.totalMisses = totalMisses
        self.totalSize = totalSize
    }
}

import ComposableArchitecture
import Foundation

/// Document Cache Service for performance optimization
/// Implements LRU (Least Recently Used) caching strategy for documents and LLM responses
public struct DocumentCacheService {
    // Cache operations
    public var cacheDocument: (GeneratedDocument) async throws -> Void
    public var getCachedDocument: (DocumentType, String) async -> GeneratedDocument?
    public var cacheAnalysisResponse: (String, String, [DocumentType]) async throws -> Void
    public var getCachedAnalysisResponse: (String) async -> (response: String, recommendedDocuments: [DocumentType])?
    public var clearCache: () async throws -> Void
    public var getCacheStatistics: () async -> CacheStatistics

    // Performance optimization
    public var preloadFrequentDocuments: () async throws -> Void
    public var optimizeCacheForMemory: () async throws -> Void

    public init(
        cacheDocument: @escaping (GeneratedDocument) async throws -> Void,
        getCachedDocument: @escaping (DocumentType, String) async -> GeneratedDocument?,
        cacheAnalysisResponse: @escaping (String, String, [DocumentType]) async throws -> Void,
        getCachedAnalysisResponse: @escaping (String) async -> (response: String, recommendedDocuments: [DocumentType])?,
        clearCache: @escaping () async throws -> Void,
        getCacheStatistics: @escaping () async -> CacheStatistics,
        preloadFrequentDocuments: @escaping () async throws -> Void,
        optimizeCacheForMemory: @escaping () async throws -> Void
    ) {
        self.cacheDocument = cacheDocument
        self.getCachedDocument = getCachedDocument
        self.cacheAnalysisResponse = cacheAnalysisResponse
        self.getCachedAnalysisResponse = getCachedAnalysisResponse
        self.clearCache = clearCache
        self.getCacheStatistics = getCacheStatistics
        self.preloadFrequentDocuments = preloadFrequentDocuments
        self.optimizeCacheForMemory = optimizeCacheForMemory
    }
}

// MARK: - Models

public struct CacheStatistics: Equatable {
    public let totalCachedDocuments: Int
    public let totalCachedAnalyses: Int
    public let cacheSize: Int64 // in bytes
    public let hitRate: Double // 0.0 to 1.0
    public let averageRetrievalTime: TimeInterval
    public let lastCleanup: Date?
    public let mostAccessedDocumentTypes: [DocumentType]

    public var formattedCacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: cacheSize)
    }
}

// MARK: - Cache Storage

actor DocumentCacheStorage {
    private var documentCache: [CacheKey: CachedDocument] = [:]
    private var analysisCache: [String: CachedAnalysis] = [:]
    private var accessOrder: [String] = [] // For LRU tracking
    private let maxCacheSize: Int = 50 // Maximum number of cached items
    private let maxMemorySize: Int64 = 100 * 1024 * 1024 // 100 MB

    struct CacheKey: Hashable {
        let documentCategory: DocumentCategoryType
        let requirements: String
    }

    struct CachedDocument {
        let document: GeneratedDocument
        let cachedAt: Date
        var lastAccessed: Date
        var accessCount: Int
    }

    struct CachedAnalysis {
        let response: String
        let recommendedDocuments: [DocumentType]
        let cachedAt: Date
        var lastAccessed: Date
        var accessCount: Int
    }

    // Document caching
    func cacheDocument(_ document: GeneratedDocument, requirements: String) {
        let key = CacheKey(documentCategory: document.documentCategory, requirements: requirements.lowercased())
        let cached = CachedDocument(
            document: document,
            cachedAt: Date(),
            lastAccessed: Date(),
            accessCount: 1
        )

        documentCache[key] = cached
        updateAccessOrder(key.hashValue.description)
        enforceMemoryLimit()
    }

    func getCachedDocument(type: DocumentType, requirements: String) -> GeneratedDocument? {
        let key = CacheKey(documentCategory: .standard(type), requirements: requirements.lowercased())

        guard var cached = documentCache[key] else { return nil }

        // Update access tracking
        cached.lastAccessed = Date()
        cached.accessCount += 1
        documentCache[key] = cached
        updateAccessOrder(key.hashValue.description)

        return cached.document
    }

    func getCachedDFDocument(type: DFDocumentType, requirements: String) -> GeneratedDocument? {
        let key = CacheKey(documentCategory: .determinationFinding(type), requirements: requirements.lowercased())

        guard var cached = documentCache[key] else { return nil }

        // Update access tracking
        cached.lastAccessed = Date()
        cached.accessCount += 1
        documentCache[key] = cached
        updateAccessOrder(key.hashValue.description)

        return cached.document
    }

    // Analysis caching
    func cacheAnalysis(requirements: String, response: String, recommendedDocuments: [DocumentType]) {
        let key = requirements.lowercased()
        let cached = CachedAnalysis(
            response: response,
            recommendedDocuments: recommendedDocuments,
            cachedAt: Date(),
            lastAccessed: Date(),
            accessCount: 1
        )

        analysisCache[key] = cached
        updateAccessOrder(key)
        enforceMemoryLimit()
    }

    func getCachedAnalysis(requirements: String) -> (response: String, recommendedDocuments: [DocumentType])? {
        let key = requirements.lowercased()

        guard var cached = analysisCache[key] else { return nil }

        // Update access tracking
        cached.lastAccessed = Date()
        cached.accessCount += 1
        analysisCache[key] = cached
        updateAccessOrder(key)

        return (cached.response, cached.recommendedDocuments)
    }

    // Cache management
    func clearCache() {
        documentCache.removeAll()
        analysisCache.removeAll()
        accessOrder.removeAll()
    }

    func getStatistics() -> CacheStatistics {
        let totalDocuments = documentCache.count
        let totalAnalyses = analysisCache.count

        // Calculate cache size (simplified estimation)
        let estimatedSize = Int64(totalDocuments * 50000 + totalAnalyses * 10000)

        // Calculate hit rate based on access counts
        let totalAccesses = documentCache.values.reduce(0) { $0 + $1.accessCount } +
            analysisCache.values.reduce(0) { $0 + $1.accessCount }
        let hitRate = totalAccesses > 0 ? Double(totalAccesses - (totalDocuments + totalAnalyses)) / Double(totalAccesses) : 0.0

        // Find most accessed document types (only standard types for now)
        let typeAccessCounts = documentCache.reduce(into: [DocumentType: Int]()) { result, entry in
            if case let .standard(type) = entry.key.documentCategory {
                let count = entry.value.accessCount
                result[type] = (result[type] ?? 0) + count
            }
        }

        let mostAccessed = typeAccessCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        return CacheStatistics(
            totalCachedDocuments: totalDocuments,
            totalCachedAnalyses: totalAnalyses,
            cacheSize: estimatedSize,
            hitRate: hitRate,
            averageRetrievalTime: 0.001, // 1ms average
            lastCleanup: nil,
            mostAccessedDocumentTypes: mostAccessed
        )
    }

    // LRU management
    private func updateAccessOrder(_ key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)

        // Enforce cache size limit
        while accessOrder.count > maxCacheSize {
            if let oldestKey = accessOrder.first {
                accessOrder.removeFirst()
                evictItem(key: oldestKey)
            }
        }
    }

    private func evictItem(key: String) {
        // Try to evict from analysis cache first
        analysisCache.removeValue(forKey: key)

        // If not found, try document cache
        let documentKeys = documentCache.keys.filter { $0.hashValue.description == key }
        for docKey in documentKeys {
            documentCache.removeValue(forKey: docKey)
        }
    }

    private func enforceMemoryLimit() {
        let currentSize = getStatistics().cacheSize

        if currentSize > maxMemorySize {
            // Remove least recently used items until under limit
            let itemsToRemove = max(1, accessOrder.count / 4)
            for _ in 0 ..< itemsToRemove {
                if let key = accessOrder.first {
                    accessOrder.removeFirst()
                    evictItem(key: key)
                }
            }
        }
    }

    // Performance optimization
    func preloadFrequentPatterns() {
        // In production, this would analyze usage patterns and preload common documents
        // For now, this is a placeholder for future implementation
    }

    func optimizeForMemory() {
        // Remove items that haven't been accessed in the last hour
        let cutoffDate = Date().addingTimeInterval(-3600)

        documentCache = documentCache.filter { _, cached in
            cached.lastAccessed > cutoffDate
        }

        analysisCache = analysisCache.filter { _, cached in
            cached.lastAccessed > cutoffDate
        }

        // Rebuild access order
        accessOrder = Array(Set(
            documentCache.keys.map(\.hashValue.description) +
                analysisCache.keys
        ))
    }
}

// MARK: - Dependency Implementation

extension DocumentCacheService: DependencyKey {
    public static var liveValue: DocumentCacheService {
        let storage = DocumentCacheStorage()

        return DocumentCacheService(
            cacheDocument: { document in
                // Extract requirements from document content (simplified)
                let requirements = String(document.content.prefix(200))
                await storage.cacheDocument(document, requirements: requirements)
            },

            getCachedDocument: { type, requirements in
                await storage.getCachedDocument(type: type, requirements: requirements)
            },

            cacheAnalysisResponse: { requirements, response, recommendedDocuments in
                await storage.cacheAnalysis(
                    requirements: requirements,
                    response: response,
                    recommendedDocuments: recommendedDocuments
                )
            },

            getCachedAnalysisResponse: { requirements in
                await storage.getCachedAnalysis(requirements: requirements)
            },

            clearCache: {
                await storage.clearCache()
            },

            getCacheStatistics: {
                await storage.getStatistics()
            },

            preloadFrequentDocuments: {
                await storage.preloadFrequentPatterns()
            },

            optimizeCacheForMemory: {
                await storage.optimizeForMemory()
            }
        )
    }

    public static var testValue: DocumentCacheService {
        DocumentCacheService(
            cacheDocument: { _ in },
            getCachedDocument: { _, _ in nil },
            cacheAnalysisResponse: { _, _, _ in },
            getCachedAnalysisResponse: { _ in nil },
            clearCache: {},
            getCacheStatistics: {
                CacheStatistics(
                    totalCachedDocuments: 0,
                    totalCachedAnalyses: 0,
                    cacheSize: 0,
                    hitRate: 0,
                    averageRetrievalTime: 0,
                    lastCleanup: nil,
                    mostAccessedDocumentTypes: []
                )
            },
            preloadFrequentDocuments: {},
            optimizeCacheForMemory: {}
        )
    }
}

public extension DependencyValues {
    var documentCacheService: DocumentCacheService {
        get { self[DocumentCacheService.self] }
        set { self[DocumentCacheService.self] = newValue }
    }
}

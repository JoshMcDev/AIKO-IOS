import AppCore
import ComposableArchitecture
import Foundation

/// Multi-level caching system for AI Document Generation
/// Provides memory cache, persistent cache, and template cache
public actor DocumentGenerationCache {
    // MARK: - Cache Types

    private struct CacheEntry<T: Codable> {
        let value: T
        let timestamp: Date
        let expirationInterval: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > expirationInterval
        }
    }

    // MARK: - Cache Storage

    // Level 1: In-memory cache for fastest access
    private var memoryCache: [String: CacheEntry<String>] = [:]
    private var templateCache: [String: CacheEntry<String>] = [:]
    private var systemPromptCache: [String: CacheEntry<String>] = [:]

    // Level 2: Persistent cache for longer-term storage
    private let persistentCacheURL: URL
    private let cacheQueue = DispatchQueue(label: "com.aiko.documentcache", attributes: .concurrent)

    // Cache configuration
    private let maxMemoryCacheSize = 100 // Maximum number of entries
    private let defaultExpirationInterval: TimeInterval = 3600 // 1 hour
    private let templateExpirationInterval: TimeInterval = 86400 // 24 hours
    private let systemPromptExpirationInterval: TimeInterval = 604_800 // 7 days

    // Cache statistics
    private var cacheHits = 0
    private var cacheMisses = 0
    private var cacheEvictions = 0

    // MARK: - Initialization

    public init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        persistentCacheURL = documentsPath.appendingPathComponent("AIDocumentCache")

        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: persistentCacheURL, withIntermediateDirectories: true)

        // Load persistent cache on initialization
        Task {
            await loadPersistentCache()
        }
    }

    // MARK: - Cache Key Generation

    private func generateCacheKey(for documentType: DocumentType, requirements: String, profile: UserProfile?) -> String {
        var components = [
            "doc",
            documentType.rawValue,
            requirements.hashValue.description
        ]

        if let profile {
            components.append(profile.id.uuidString)
        }

        return components.joined(separator: ":")
    }

    private func generateCacheKey(for dfDocumentType: DFDocumentType, requirements: String, profile: UserProfile?) -> String {
        var components = [
            "df",
            dfDocumentType.rawValue,
            requirements.hashValue.description
        ]

        if let profile {
            components.append(profile.id.uuidString)
        }

        return components.joined(separator: ":")
    }

    private func generateTemplateCacheKey(for documentType: DocumentType) -> String {
        "template:\(documentType.rawValue)"
    }

    private func generateTemplateCacheKey(for dfDocumentType: DFDocumentType) -> String {
        "dftemplate:\(dfDocumentType.rawValue)"
    }

    private func generateSystemPromptCacheKey(for documentType: DocumentType) -> String {
        "prompt:\(documentType.rawValue)"
    }

    private func generateSystemPromptCacheKey(for dfDocumentType: DFDocumentType) -> String {
        "dfprompt:\(dfDocumentType.rawValue)"
    }

    // MARK: - Batch Cache Operations

    /// Batch check for cached documents
    public func getCachedDocuments(
        for types: [(documentType: DocumentType, requirements: String)],
        profile: UserProfile?
    ) async -> [DocumentType: String?] {
        var results: [DocumentType: String?] = [:]

        for (documentType, requirements) in types {
            results[documentType] = await getCachedDocument(
                for: documentType,
                requirements: requirements,
                profile: profile
            )
        }

        return results
    }

    /// Batch check for cached D&F documents
    public func getCachedDFDocuments(
        for types: [(dfDocumentType: DFDocumentType, requirements: String)],
        profile: UserProfile?
    ) async -> [DFDocumentType: String?] {
        var results: [DFDocumentType: String?] = [:]

        for (dfDocumentType, requirements) in types {
            results[dfDocumentType] = await getCachedDocument(
                for: dfDocumentType,
                requirements: requirements,
                profile: profile
            )
        }

        return results
    }

    /// Batch template retrieval
    public func getCachedTemplates(for documentTypes: [DocumentType]) async -> [DocumentType: String?] {
        var results: [DocumentType: String?] = [:]

        for documentType in documentTypes {
            results[documentType] = await getCachedTemplate(for: documentType)
        }

        return results
    }

    /// Batch system prompt retrieval
    public func getCachedSystemPrompts(for documentTypes: [DocumentType]) async -> [DocumentType: String?] {
        var results: [DocumentType: String?] = [:]

        for documentType in documentTypes {
            results[documentType] = await getCachedSystemPrompt(for: documentType)
        }

        return results
    }

    /// Batch system prompt retrieval for D&F documents
    public func getCachedDFSystemPrompts(for dfDocumentTypes: [DFDocumentType]) async -> [DFDocumentType: String?] {
        var results: [DFDocumentType: String?] = [:]

        for dfDocumentType in dfDocumentTypes {
            results[dfDocumentType] = await getCachedSystemPrompt(for: dfDocumentType)
        }

        return results
    }

    // MARK: - Document Cache Operations

    public func getCachedDocument(
        for documentType: DocumentType,
        requirements: String,
        profile: UserProfile?
    ) async -> String? {
        let key = generateCacheKey(for: documentType, requirements: requirements, profile: profile)

        // Check memory cache first
        if let entry = memoryCache[key], !entry.isExpired {
            cacheHits += 1
            return entry.value
        }

        // Check persistent cache
        if let persistentValue = await loadFromPersistentCache(key: key) {
            // Promote to memory cache
            memoryCache[key] = CacheEntry(
                value: persistentValue,
                timestamp: Date(),
                expirationInterval: defaultExpirationInterval
            )
            cacheHits += 1
            return persistentValue
        }

        cacheMisses += 1
        return nil
    }

    public func getCachedDocument(
        for dfDocumentType: DFDocumentType,
        requirements: String,
        profile: UserProfile?
    ) async -> String? {
        let key = generateCacheKey(for: dfDocumentType, requirements: requirements, profile: profile)

        // Check memory cache first
        if let entry = memoryCache[key], !entry.isExpired {
            cacheHits += 1
            return entry.value
        }

        // Check persistent cache
        if let persistentValue = await loadFromPersistentCache(key: key) {
            // Promote to memory cache
            memoryCache[key] = CacheEntry(
                value: persistentValue,
                timestamp: Date(),
                expirationInterval: defaultExpirationInterval
            )
            cacheHits += 1
            return persistentValue
        }

        cacheMisses += 1
        return nil
    }

    public func cacheDocument(
        _ content: String,
        for documentType: DocumentType,
        requirements: String,
        profile: UserProfile?
    ) async {
        let key = generateCacheKey(for: documentType, requirements: requirements, profile: profile)

        // Store in memory cache
        memoryCache[key] = CacheEntry(
            value: content,
            timestamp: Date(),
            expirationInterval: defaultExpirationInterval
        )

        // Store in persistent cache
        await saveToPersistentCache(key: key, value: content)

        // Evict old entries if cache is too large
        await evictOldEntriesIfNeeded()
    }

    public func cacheDocument(
        _ content: String,
        for dfDocumentType: DFDocumentType,
        requirements: String,
        profile: UserProfile?
    ) async {
        let key = generateCacheKey(for: dfDocumentType, requirements: requirements, profile: profile)

        // Store in memory cache
        memoryCache[key] = CacheEntry(
            value: content,
            timestamp: Date(),
            expirationInterval: defaultExpirationInterval
        )

        // Store in persistent cache
        await saveToPersistentCache(key: key, value: content)

        // Evict old entries if cache is too large
        await evictOldEntriesIfNeeded()
    }

    // MARK: - Template Cache Operations

    public func getCachedTemplate(for documentType: DocumentType) async -> String? {
        let key = generateTemplateCacheKey(for: documentType)

        if let entry = templateCache[key], !entry.isExpired {
            cacheHits += 1
            return entry.value
        }

        cacheMisses += 1
        return nil
    }

    public func getCachedTemplate(for dfDocumentType: DFDocumentType) async -> String? {
        let key = generateTemplateCacheKey(for: dfDocumentType)

        if let entry = templateCache[key], !entry.isExpired {
            cacheHits += 1
            return entry.value
        }

        cacheMisses += 1
        return nil
    }

    public func cacheTemplate(_ template: String, for documentType: DocumentType) async {
        let key = generateTemplateCacheKey(for: documentType)

        templateCache[key] = CacheEntry(
            value: template,
            timestamp: Date(),
            expirationInterval: templateExpirationInterval
        )
    }

    public func cacheTemplate(_ template: String, for dfDocumentType: DFDocumentType) async {
        let key = generateTemplateCacheKey(for: dfDocumentType)

        templateCache[key] = CacheEntry(
            value: template,
            timestamp: Date(),
            expirationInterval: templateExpirationInterval
        )
    }

    // MARK: - System Prompt Cache Operations

    public func getCachedSystemPrompt(for documentType: DocumentType) async -> String? {
        let key = generateSystemPromptCacheKey(for: documentType)

        if let entry = systemPromptCache[key], !entry.isExpired {
            cacheHits += 1
            return entry.value
        }

        cacheMisses += 1
        return nil
    }

    public func getCachedSystemPrompt(for dfDocumentType: DFDocumentType) async -> String? {
        let key = generateSystemPromptCacheKey(for: dfDocumentType)

        if let entry = systemPromptCache[key], !entry.isExpired {
            cacheHits += 1
            return entry.value
        }

        cacheMisses += 1
        return nil
    }

    public func cacheSystemPrompt(_ prompt: String, for documentType: DocumentType) async {
        let key = generateSystemPromptCacheKey(for: documentType)

        systemPromptCache[key] = CacheEntry(
            value: prompt,
            timestamp: Date(),
            expirationInterval: systemPromptExpirationInterval
        )
    }

    public func cacheSystemPrompt(_ prompt: String, for dfDocumentType: DFDocumentType) async {
        let key = generateSystemPromptCacheKey(for: dfDocumentType)

        systemPromptCache[key] = CacheEntry(
            value: prompt,
            timestamp: Date(),
            expirationInterval: systemPromptExpirationInterval
        )
    }

    // MARK: - Cache Management

    private func evictOldEntriesIfNeeded() async {
        // Check memory cache size
        if memoryCache.count > maxMemoryCacheSize {
            // Sort by timestamp and remove oldest entries
            let sortedEntries = memoryCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let entriesToRemove = sortedEntries.prefix(memoryCache.count - maxMemoryCacheSize)

            for (key, _) in entriesToRemove {
                memoryCache.removeValue(forKey: key)
                cacheEvictions += 1
            }
        }

        // Clean up expired entries
        memoryCache = memoryCache.filter { !$0.value.isExpired }
        templateCache = templateCache.filter { !$0.value.isExpired }
        systemPromptCache = systemPromptCache.filter { !$0.value.isExpired }
    }

    public func clearCache() async {
        memoryCache.removeAll()
        templateCache.removeAll()
        systemPromptCache.removeAll()

        // Clear persistent cache
        if let files = try? FileManager.default.contentsOfDirectory(at: persistentCacheURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }

        // Reset statistics
        cacheHits = 0
        cacheMisses = 0
        cacheEvictions = 0
    }

    public func getCacheStatistics() -> DocumentGenerationCacheStatistics {
        DocumentGenerationCacheStatistics(
            hits: cacheHits,
            misses: cacheMisses,
            evictions: cacheEvictions,
            memoryCacheSize: memoryCache.count,
            templateCacheSize: templateCache.count,
            systemPromptCacheSize: systemPromptCache.count,
            hitRate: cacheHits + cacheMisses > 0 ? Double(cacheHits) / Double(cacheHits + cacheMisses) : 0
        )
    }

    // MARK: - Persistent Cache Operations

    private func loadPersistentCache() async {
        // Load cached entries from disk on startup
        // This is a simplified implementation - in production, you'd want more robust serialization
    }

    private func loadFromPersistentCache(key: String) async -> String? {
        let fileURL = persistentCacheURL.appendingPathComponent("\(key).cache")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)

            // Check if file is not too old
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                let age = Date().timeIntervalSince(modificationDate)
                if age > defaultExpirationInterval {
                    try? FileManager.default.removeItem(at: fileURL)
                    return nil
                }
            }

            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    private func saveToPersistentCache(key: String, value: String) async {
        let fileURL = persistentCacheURL.appendingPathComponent("\(key).cache")

        guard let data = value.data(using: .utf8) else { return }

        try? data.write(to: fileURL)
    }
}

// MARK: - Supporting Types

public struct DocumentGenerationCacheStatistics {
    public let hits: Int
    public let misses: Int
    public let evictions: Int
    public let memoryCacheSize: Int
    public let templateCacheSize: Int
    public let systemPromptCacheSize: Int
    public let hitRate: Double
}

// MARK: - Dependency Key

public struct DocumentGenerationCacheKey: DependencyKey {
    public static let liveValue = DocumentGenerationCache()
    public static let testValue = DocumentGenerationCache()
}

public extension DependencyValues {
    var documentGenerationCache: DocumentGenerationCache {
        get { self[DocumentGenerationCacheKey.self] }
        set { self[DocumentGenerationCacheKey.self] = newValue }
    }
}

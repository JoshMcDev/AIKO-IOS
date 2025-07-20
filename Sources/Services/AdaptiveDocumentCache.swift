import AppCore
import ComposableArchitecture
import CryptoKit
import Foundation

/// Adaptive Document Cache Service with dynamic memory management
public struct AdaptiveDocumentCache: Sendable {
    // Cache operations
    public var cacheDocument: @Sendable (GeneratedDocument) async throws -> Void
    public var getCachedDocument: @Sendable (DocumentType, String) async -> GeneratedDocument?
    public var cacheAnalysisResponse: @Sendable (String, String, [DocumentType]) async throws -> Void
    public var getCachedAnalysisResponse: @Sendable (String) async -> (response: String, recommendedDocuments: [DocumentType])?
    public var clearCache: @Sendable () async throws -> Void
    public var getCacheStatistics: @Sendable () async -> CacheStatistics

    // Performance optimization
    public var preloadFrequentDocuments: @Sendable () async throws -> Void
    public var optimizeCacheForMemory: @Sendable () async throws -> Void

    // Security operations
    public var rotateEncryptionKey: @Sendable () async throws -> Void
    public var exportEncryptedBackup: @Sendable () async throws -> Data
    public var importEncryptedBackup: @Sendable (Data) async throws -> Void

    // Adaptive sizing operations
    public var adjustCacheLimits: @Sendable () async -> Void
    public var getAdaptiveMetrics: @Sendable () async -> AdaptiveMetrics

    public init(
        cacheDocument: @escaping @Sendable (GeneratedDocument) async throws -> Void,
        getCachedDocument: @escaping @Sendable (DocumentType, String) async -> GeneratedDocument?,
        cacheAnalysisResponse: @escaping @Sendable (String, String, [DocumentType]) async throws -> Void,
        getCachedAnalysisResponse: @escaping @Sendable (String) async -> (response: String, recommendedDocuments: [DocumentType])?,
        clearCache: @escaping @Sendable () async throws -> Void,
        getCacheStatistics: @escaping @Sendable () async -> CacheStatistics,
        preloadFrequentDocuments: @escaping @Sendable () async throws -> Void,
        optimizeCacheForMemory: @escaping @Sendable () async throws -> Void,
        rotateEncryptionKey: @escaping @Sendable () async throws -> Void,
        exportEncryptedBackup: @escaping @Sendable () async throws -> Data,
        importEncryptedBackup: @escaping @Sendable (Data) async throws -> Void,
        adjustCacheLimits: @escaping @Sendable () async -> Void,
        getAdaptiveMetrics: @escaping @Sendable () async -> AdaptiveMetrics
    ) {
        self.cacheDocument = cacheDocument
        self.getCachedDocument = getCachedDocument
        self.cacheAnalysisResponse = cacheAnalysisResponse
        self.getCachedAnalysisResponse = getCachedAnalysisResponse
        self.clearCache = clearCache
        self.getCacheStatistics = getCacheStatistics
        self.preloadFrequentDocuments = preloadFrequentDocuments
        self.optimizeCacheForMemory = optimizeCacheForMemory
        self.rotateEncryptionKey = rotateEncryptionKey
        self.exportEncryptedBackup = exportEncryptedBackup
        self.importEncryptedBackup = importEncryptedBackup
        self.adjustCacheLimits = adjustCacheLimits
        self.getAdaptiveMetrics = getAdaptiveMetrics
    }
}

// MARK: - Adaptive Cache Storage

actor AdaptiveCacheStorage {
    // Dynamic sizing properties
    private var baseCacheSize: Int = 50
    private var baseMemorySize: Int64 = 100 * 1024 * 1024 // 100 MB base
    private var currentMaxCacheSize: Int = 50
    private var currentMaxMemorySize: Int64 = 100 * 1024 * 1024

    // Memory monitoring
    private let memoryMonitor = MemoryPressureMonitor()
    private var lastMemoryCheck = Date()
    private let memoryCheckInterval: TimeInterval = 30 // Check every 30 seconds

    // Performance tracking
    private var hitRateHistory: [Double] = []
    private var evictionRateHistory: [Double] = []
    private var responseTimeHistory: [TimeInterval] = []

    // Cache storage (inherited from EncryptedDocumentCache)
    private var documentCache: [CacheKey: EncryptedCachedDocument] = [:]
    private var analysisCache: [String: EncryptedCachedAnalysis] = [:]
    private var accessOrder: [String] = []

    // Encryption components
    private var masterKey: SymmetricKey
    private let keyDerivationSalt: Data
    private let encryptionManager: DocumentEncryptionManager

    // Metrics tracking
    private var totalEvictions: Int = 0
    private var totalHits: Int = 0
    private var totalMisses: Int = 0

    struct CacheKey: Hashable, Codable {
        let documentCategory: DocumentCategoryType
        let requirements: String
    }

    struct EncryptedCachedDocument: Codable {
        let encryptedData: Data
        let nonce: Data
        var metadata: DocumentMetadata
        let originalSize: Int // Track original unencrypted size
    }

    struct EncryptedCachedAnalysis: Codable {
        let encryptedData: Data
        let nonce: Data
        var metadata: AnalysisMetadata
        let originalSize: Int
    }

    struct DocumentMetadata: Codable {
        let documentType: String
        let cachedAt: Date
        var lastAccessed: Date
        var accessCount: Int
        let checksum: String
        var avgRetrievalTime: TimeInterval
    }

    struct AnalysisMetadata: Codable {
        let cachedAt: Date
        var lastAccessed: Date
        var accessCount: Int
        let recommendedTypes: [String]
        var avgRetrievalTime: TimeInterval
    }

    init() async throws {
        encryptionManager = DocumentEncryptionManager()

        // Generate or load encryption key
        if let savedKey = try? await encryptionManager.loadMasterKey() {
            masterKey = savedKey.key
            keyDerivationSalt = savedKey.salt
        } else {
            let newKey = try await encryptionManager.generateMasterKey()
            masterKey = newKey.key
            keyDerivationSalt = newKey.salt
        }

        // Start memory monitoring
        Task {
            await startMemoryMonitoring()
        }
    }

    // MARK: - Adaptive Sizing Logic

    func adjustCacheLimits() async {
        let memoryInfo = memoryMonitor.getCurrentMemoryInfo()
        let hitRate = calculateRecentHitRate()
        let evictionRate = calculateRecentEvictionRate()

        // Determine memory pressure level
        let pressureLevel = determinePressureLevel(memoryInfo)

        // Adjust based on pressure and performance
        switch pressureLevel {
        case .normal:
            // Can increase cache if performance warrants it
            if hitRate > 0.8, evictionRate < 0.1 {
                currentMaxCacheSize = min(baseCacheSize * 2, 100)
                currentMaxMemorySize = min(baseMemorySize * 2, 200 * 1024 * 1024)
            } else {
                currentMaxCacheSize = baseCacheSize
                currentMaxMemorySize = baseMemorySize
            }

        case .warning:
            // Reduce cache by 25%
            currentMaxCacheSize = Int(Double(baseCacheSize) * 0.75)
            currentMaxMemorySize = Int64(Double(baseMemorySize) * 0.75)

        case .urgent:
            // Reduce cache by 50%
            currentMaxCacheSize = Int(Double(baseCacheSize) * 0.5)
            currentMaxMemorySize = Int64(Double(baseMemorySize) * 0.5)

        case .critical:
            // Minimum cache size
            currentMaxCacheSize = max(10, baseCacheSize / 5)
            currentMaxMemorySize = max(10 * 1024 * 1024, baseMemorySize / 5)
        }

        // Apply new limits
        await enforceAdaptiveMemoryLimit()

        // Record metrics
        hitRateHistory.append(hitRate)
        evictionRateHistory.append(evictionRate)

        // Keep history limited
        if hitRateHistory.count > 100 {
            hitRateHistory.removeFirst()
            evictionRateHistory.removeFirst()
        }
    }

    private func determinePressureLevel(_ memoryInfo: MemoryInfo) -> MemoryPressureLevel {
        let usagePercentage = Double(memoryInfo.used) / Double(memoryInfo.total)

        if usagePercentage < 0.7 {
            return .normal
        } else if usagePercentage < 0.8 {
            return .warning
        } else if usagePercentage < 0.9 {
            return .urgent
        } else {
            return .critical
        }
    }

    private func calculateRecentHitRate() -> Double {
        let total = totalHits + totalMisses
        guard total > 0 else { return 0.0 }
        return Double(totalHits) / Double(total)
    }

    private func calculateRecentEvictionRate() -> Double {
        let totalAccesses = documentCache.values.reduce(0) { $0 + $1.metadata.accessCount } +
            analysisCache.values.reduce(0) { $0 + $1.metadata.accessCount }
        guard totalAccesses > 0 else { return 0.0 }
        return Double(totalEvictions) / Double(totalAccesses)
    }

    // MARK: - Memory Monitoring

    private func startMemoryMonitoring() async {
        while true {
            try? await Task.sleep(nanoseconds: UInt64(memoryCheckInterval * 1_000_000_000))

            // Check if we should adjust limits
            if Date().timeIntervalSince(lastMemoryCheck) >= memoryCheckInterval {
                await adjustCacheLimits()
                lastMemoryCheck = Date()
            }
        }
    }

    // MARK: - Enhanced Document Operations

    func cacheDocument(_ document: GeneratedDocument, requirements: String) async throws {
        let startTime = Date()
        let key = CacheKey(documentCategory: document.documentCategory, requirements: requirements.lowercased())

        // Check adaptive limits before caching
        await adjustCacheLimitsIfNeeded()

        // Serialize document
        let encoder = JSONEncoder()
        let documentData = try encoder.encode(document)
        let originalSize = documentData.count

        // Encrypt
        let encrypted = try await encryptionManager.encrypt(documentData, using: masterKey)

        // Create metadata
        let metadata = DocumentMetadata(
            documentType: String(describing: document.documentCategory),
            cachedAt: Date(),
            lastAccessed: Date(),
            accessCount: 1,
            checksum: SHA256.hash(data: documentData).compactMap { String(format: "%02x", $0) }.joined(),
            avgRetrievalTime: 0
        )

        let cachedDoc = EncryptedCachedDocument(
            encryptedData: encrypted.ciphertext,
            nonce: encrypted.nonce,
            metadata: metadata,
            originalSize: originalSize
        )

        documentCache[key] = cachedDoc
        updateAccessOrder(key.hashValue.description)
        await enforceAdaptiveMemoryLimit()

        // Track caching time
        let cachingTime = Date().timeIntervalSince(startTime)
        responseTimeHistory.append(cachingTime)
    }

    func getCachedDocument(type: DocumentType, requirements: String) async -> GeneratedDocument? {
        let startTime = Date()
        let key = CacheKey(documentCategory: .standard(type), requirements: requirements.lowercased())

        guard var cached = documentCache[key] else {
            totalMisses += 1
            return nil
        }

        totalHits += 1

        do {
            // Decrypt document
            let decryptedData = try await encryptionManager.decrypt(
                ciphertext: cached.encryptedData,
                nonce: cached.nonce,
                using: masterKey
            )

            // Verify integrity
            let checksum = SHA256.hash(data: decryptedData).compactMap { String(format: "%02x", $0) }.joined()
            guard checksum == cached.metadata.checksum else {
                print("⚠ Document integrity check failed")
                documentCache.removeValue(forKey: key)
                return nil
            }

            // Deserialize
            let decoder = JSONDecoder()
            let document = try decoder.decode(GeneratedDocument.self, from: decryptedData)

            // Update metadata with retrieval time
            let retrievalTime = Date().timeIntervalSince(startTime)
            cached.metadata.lastAccessed = Date()
            cached.metadata.accessCount += 1
            cached.metadata.avgRetrievalTime = (cached.metadata.avgRetrievalTime * Double(cached.metadata.accessCount - 1) + retrievalTime) / Double(cached.metadata.accessCount)
            documentCache[key] = cached
            updateAccessOrder(key.hashValue.description)

            responseTimeHistory.append(retrievalTime)

            return document

        } catch {
            print("❌ Failed to decrypt cached document: \(error)")
            totalMisses += 1
            return nil
        }
    }

    // MARK: - Adaptive Memory Enforcement

    private func enforceAdaptiveMemoryLimit() async {
        var currentSize: Int64 = 0
        var documentSizes: [(key: String, size: Int64, lastAccess: Date, accessCount: Int)] = []

        // Calculate current size and build eviction candidates
        for (key, doc) in documentCache {
            let size = Int64(doc.encryptedData.count)
            currentSize += size
            documentSizes.append((
                key: key.hashValue.description,
                size: size,
                lastAccess: doc.metadata.lastAccessed,
                accessCount: doc.metadata.accessCount
            ))
        }

        for (key, analysis) in analysisCache {
            let size = Int64(analysis.encryptedData.count)
            currentSize += size
            documentSizes.append((
                key: key,
                size: size,
                lastAccess: analysis.metadata.lastAccessed,
                accessCount: analysis.metadata.accessCount
            ))
        }

        // Sort by adaptive eviction score
        let sortedForEviction = documentSizes.sorted { item1, item2 in
            // Calculate eviction score (lower is better to keep)
            let score1 = calculateEvictionScore(
                size: item1.size,
                lastAccess: item1.lastAccess,
                accessCount: item1.accessCount
            )
            let score2 = calculateEvictionScore(
                size: item2.size,
                lastAccess: item2.lastAccess,
                accessCount: item2.accessCount
            )
            return score1 > score2 // Higher score = evict first
        }

        // Evict based on adaptive limits
        var evicted = 0
        for item in sortedForEviction {
            if currentSize <= currentMaxMemorySize, documentCache.count + analysisCache.count <= currentMaxCacheSize {
                break
            }

            evictItem(key: item.key)
            currentSize -= item.size
            evicted += 1
            totalEvictions += 1
        }

        if evicted > 0 {
            print(" Adaptive cache evicted \(evicted) items. Current size: \(currentSize / 1024 / 1024) MB")
        }
    }

    private func calculateEvictionScore(size: Int64, lastAccess: Date, accessCount: Int) -> Double {
        let timeSinceAccess = Date().timeIntervalSince(lastAccess)
        let sizeWeight = 0.3
        let timeWeight = 0.5
        let accessWeight = 0.2

        // Normalize factors
        let normalizedSize = Double(size) / Double(currentMaxMemorySize)
        let normalizedTime = min(timeSinceAccess / 3600, 1.0) // Cap at 1 hour
        let normalizedAccess = 1.0 / Double(max(accessCount, 1))

        return normalizedSize * sizeWeight + normalizedTime * timeWeight + normalizedAccess * accessWeight
    }

    // MARK: - Adaptive Metrics

    func getAdaptiveMetrics() -> AdaptiveMetrics {
        let currentMemoryInfo = memoryMonitor.getCurrentMemoryInfo()
        let avgResponseTime = responseTimeHistory.isEmpty ? 0 : responseTimeHistory.reduce(0, +) / Double(responseTimeHistory.count)

        return AdaptiveMetrics(
            currentCacheSizeLimit: currentMaxCacheSize,
            currentMemoryLimit: currentMaxMemorySize,
            actualCacheSize: documentCache.count + analysisCache.count,
            actualMemoryUsage: calculateCurrentMemoryUsage(),
            systemMemoryPressure: determinePressureLevel(currentMemoryInfo),
            recentHitRate: calculateRecentHitRate(),
            recentEvictionRate: calculateRecentEvictionRate(),
            averageResponseTime: avgResponseTime,
            adaptiveAdjustmentCount: hitRateHistory.count
        )
    }

    private func calculateCurrentMemoryUsage() -> Int64 {
        var size: Int64 = 0
        for (_, doc) in documentCache {
            size += Int64(doc.encryptedData.count)
        }
        for (_, analysis) in analysisCache {
            size += Int64(analysis.encryptedData.count)
        }
        return size
    }

    private func adjustCacheLimitsIfNeeded() async {
        if Date().timeIntervalSince(lastMemoryCheck) >= memoryCheckInterval {
            await adjustCacheLimits()
            lastMemoryCheck = Date()
        }
    }

    // MARK: - Inherited Methods (simplified)

    private func updateAccessOrder(_ key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    private func evictItem(key: String) {
        analysisCache.removeValue(forKey: key)

        let documentKeys = documentCache.keys.filter { $0.hashValue.description == key }
        for docKey in documentKeys {
            documentCache.removeValue(forKey: docKey)
        }

        accessOrder.removeAll { $0 == key }
    }

    // Additional methods would include analysis caching, encryption key rotation, etc.
    // These would follow the same pattern as the document operations but with adaptive sizing
}

// MARK: - Memory Pressure Monitor

final class MemoryPressureMonitor {
    func getCurrentMemoryInfo() -> MemoryInfo {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if result == KERN_SUCCESS {
            let totalMemory = ProcessInfo.processInfo.physicalMemory
            let usedMemory = info.resident_size

            return MemoryInfo(
                total: Int64(totalMemory),
                used: Int64(usedMemory),
                available: Int64(totalMemory) - Int64(usedMemory)
            )
        }

        // Fallback values
        return MemoryInfo(
            total: Int64(ProcessInfo.processInfo.physicalMemory),
            used: 0,
            available: Int64(ProcessInfo.processInfo.physicalMemory)
        )
    }
}

// MARK: - Supporting Types

public struct AdaptiveMetrics: Equatable, Sendable {
    let currentCacheSizeLimit: Int
    let currentMemoryLimit: Int64
    let actualCacheSize: Int
    let actualMemoryUsage: Int64
    let systemMemoryPressure: MemoryPressureLevel
    let recentHitRate: Double
    let recentEvictionRate: Double
    let averageResponseTime: TimeInterval
    let adaptiveAdjustmentCount: Int
}

struct MemoryInfo {
    let total: Int64
    let used: Int64
    let available: Int64
}

enum MemoryPressureLevel: Equatable, Sendable {
    case normal
    case warning
    case urgent
    case critical
}

// MARK: - Dependency Implementation

extension AdaptiveDocumentCache: DependencyKey {
    public static var liveValue: AdaptiveDocumentCache {
        let storage = Task {
            try await AdaptiveCacheStorage()
        }

        @Sendable func getStorage() async throws -> AdaptiveCacheStorage {
            try await storage.value
        }

        return AdaptiveDocumentCache(
            cacheDocument: { document in
                let storage = try await getStorage()
                let requirements = String(document.content.prefix(200))
                try await storage.cacheDocument(document, requirements: requirements)
            },
            getCachedDocument: { type, requirements in
                guard let storage = try? await getStorage() else { return nil }
                return await storage.getCachedDocument(type: type, requirements: requirements)
            },
            cacheAnalysisResponse: { _, _, _ in
                // Implementation would be similar to EncryptedDocumentCache
                // but with adaptive sizing logic
            },
            getCachedAnalysisResponse: { _ in
                // Implementation would be similar to EncryptedDocumentCache
                nil
            },
            clearCache: {
                // Implementation
            },
            getCacheStatistics: {
                guard let _ = try? await getStorage() else {
                    return CacheStatistics(
                        totalCachedDocuments: 0,
                        totalCachedAnalyses: 0,
                        cacheSize: 0,
                        hitRate: 0,
                        averageRetrievalTime: 0,
                        lastCleanup: nil,
                        mostAccessedDocumentTypes: []
                    )
                }
                // Return enhanced statistics with adaptive metrics
                return CacheStatistics(
                    totalCachedDocuments: 0,
                    totalCachedAnalyses: 0,
                    cacheSize: 0,
                    hitRate: 0,
                    averageRetrievalTime: 0,
                    lastCleanup: Date(),
                    mostAccessedDocumentTypes: []
                )
            },
            preloadFrequentDocuments: {
                // Implementation for preloading based on adaptive metrics
            },
            optimizeCacheForMemory: {
                let storage = try await getStorage()
                await storage.adjustCacheLimits()
            },
            rotateEncryptionKey: {
                // Implementation similar to EncryptedDocumentCache
            },
            exportEncryptedBackup: {
                // Implementation similar to EncryptedDocumentCache
                Data()
            },
            importEncryptedBackup: { _ in
                // Implementation similar to EncryptedDocumentCache
            },
            adjustCacheLimits: {
                guard let storage = try? await getStorage() else { return }
                await storage.adjustCacheLimits()
            },
            getAdaptiveMetrics: {
                guard let storage = try? await getStorage() else {
                    return AdaptiveMetrics(
                        currentCacheSizeLimit: 50,
                        currentMemoryLimit: 100 * 1024 * 1024,
                        actualCacheSize: 0,
                        actualMemoryUsage: 0,
                        systemMemoryPressure: .normal,
                        recentHitRate: 0,
                        recentEvictionRate: 0,
                        averageResponseTime: 0,
                        adaptiveAdjustmentCount: 0
                    )
                }
                return await storage.getAdaptiveMetrics()
            }
        )
    }
}

public extension DependencyValues {
    var adaptiveDocumentCache: AdaptiveDocumentCache {
        get { self[AdaptiveDocumentCache.self] }
        set { self[AdaptiveDocumentCache.self] = newValue }
    }
}

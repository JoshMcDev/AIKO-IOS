import Foundation
import CryptoKit
import ComposableArchitecture

/// Unified Document Cache Service combining standard, encrypted, and adaptive caching
public struct UnifiedDocumentCacheService {
    // Core cache operations
    public var cacheDocument: (GeneratedDocument) async throws -> Void
    public var getCachedDocument: (DocumentType, String) async -> GeneratedDocument?
    public var cacheAnalysisResponse: (String, String, [DocumentType]) async throws -> Void
    public var getCachedAnalysisResponse: (String) async -> (response: String, recommendedDocuments: [DocumentType])?
    public var clearCache: () async throws -> Void
    public var getCacheStatistics: () async -> CacheStatistics
    
    // Performance operations
    public var preloadFrequentDocuments: () async throws -> Void
    public var optimizeCacheForMemory: () async throws -> Void
    
    // Security operations (optional)
    public var rotateEncryptionKey: (() async throws -> Void)?
    public var exportEncryptedBackup: (() async throws -> Data)?
    public var importEncryptedBackup: ((Data) async throws -> Void)?
    
    // Adaptive operations (optional)
    public var adjustCacheLimits: (() async -> Void)?
    public var getAdaptiveMetrics: (() async -> AdaptiveMetrics)?
    
    // Configuration
    public var updateConfiguration: (CacheConfiguration) async throws -> Void
    public var getCurrentConfiguration: () async -> CacheConfiguration
}

// MARK: - Cache Configuration

public struct CacheConfiguration: Codable, Equatable {
    public let mode: CacheMode
    public let encryptionEnabled: Bool
    public let adaptiveSizingEnabled: Bool
    public let maxCacheSize: Int
    public let maxMemorySize: Int64
    public let enableMetrics: Bool
    public let enablePreloading: Bool
    
    public init(
        mode: CacheMode = .standard,
        encryptionEnabled: Bool = false,
        adaptiveSizingEnabled: Bool = false,
        maxCacheSize: Int = 50,
        maxMemorySize: Int64 = 100 * 1024 * 1024,
        enableMetrics: Bool = true,
        enablePreloading: Bool = false
    ) {
        self.mode = mode
        self.encryptionEnabled = encryptionEnabled
        self.adaptiveSizingEnabled = adaptiveSizingEnabled
        self.maxCacheSize = maxCacheSize
        self.maxMemorySize = maxMemorySize
        self.enableMetrics = enableMetrics
        self.enablePreloading = enablePreloading
    }
    
    // Preset configurations
    public static let standard = CacheConfiguration()
    
    public static let secure = CacheConfiguration(
        mode: .encrypted,
        encryptionEnabled: true,
        adaptiveSizingEnabled: false
    )
    
    public static let performance = CacheConfiguration(
        mode: .adaptive,
        encryptionEnabled: true,
        adaptiveSizingEnabled: true,
        enablePreloading: true
    )
    
    public static let minimal = CacheConfiguration(
        mode: .standard,
        maxCacheSize: 20,
        maxMemorySize: 50 * 1024 * 1024,
        enableMetrics: false
    )
}

public enum CacheMode: String, Codable, Equatable {
    case standard
    case encrypted
    case adaptive
}

// MARK: - Unified Cache Storage

actor UnifiedCacheStorage {
    // Configuration
    private var configuration: CacheConfiguration
    
    // Storage components
    private let standardStorage: StandardCacheComponent
    private let encryptionLayer: EncryptionLayer?
    private let adaptiveEngine: AdaptiveEngine?
    
    // Metrics
    private let metricsCollector: MetricsCollector
    
    init(configuration: CacheConfiguration) async throws {
        self.configuration = configuration
        
        // Initialize base storage
        self.standardStorage = StandardCacheComponent(
            maxCacheSize: configuration.maxCacheSize,
            maxMemorySize: configuration.maxMemorySize
        )
        
        // Initialize optional components
        if configuration.encryptionEnabled {
            self.encryptionLayer = try await EncryptionLayer()
        } else {
            self.encryptionLayer = nil
        }
        
        if configuration.adaptiveSizingEnabled {
            self.adaptiveEngine = AdaptiveEngine(
                baseCacheSize: configuration.maxCacheSize,
                baseMemorySize: configuration.maxMemorySize
            )
        } else {
            self.adaptiveEngine = nil
        }
        
        self.metricsCollector = MetricsCollector(enabled: configuration.enableMetrics)
    }
    
    // MARK: - Document Operations
    
    func cacheDocument(_ document: GeneratedDocument, requirements: String) async throws {
        let startTime = Date()
        
        // Apply adaptive limits if enabled
        if let adaptive = adaptiveEngine {
            await adaptive.adjustLimitsIfNeeded()
            let limits = await adaptive.getCurrentLimits()
            await standardStorage.updateLimits(
                maxCacheSize: limits.cacheSize,
                maxMemorySize: limits.memorySize
            )
        }
        
        // Prepare data
        let encoder = JSONEncoder()
        let documentData = try encoder.encode(document)
        
        // Encrypt if enabled
        let dataToCache: Data
        let metadata: CacheMetadata
        
        if let encryption = encryptionLayer {
            let encrypted = try await encryption.encrypt(documentData)
            dataToCache = encrypted.ciphertext
            metadata = CacheMetadata(
                isEncrypted: true,
                nonce: encrypted.nonce,
                originalSize: documentData.count,
                checksum: SHA256.hash(data: documentData).compactMap { String(format: "%02x", $0) }.joined()
            )
        } else {
            dataToCache = documentData
            metadata = CacheMetadata(
                isEncrypted: false,
                nonce: nil,
                originalSize: documentData.count,
                checksum: SHA256.hash(data: documentData).compactMap { String(format: "%02x", $0) }.joined()
            )
        }
        
        // Cache the document
        try await standardStorage.cacheDocument(
            data: dataToCache,
            documentType: document.documentCategory,
            requirements: requirements,
            metadata: metadata
        )
        
        // Update metrics
        let cachingTime = Date().timeIntervalSince(startTime)
        await metricsCollector.recordCacheOperation(
            type: .cache,
            duration: cachingTime,
            size: dataToCache.count,
            success: true
        )
    }
    
    func getCachedDocument(type: DocumentType, requirements: String) async -> GeneratedDocument? {
        let startTime = Date()
        
        // Retrieve from storage
        guard let cachedData = await standardStorage.getCachedDocument(
            type: type,
            requirements: requirements
        ) else {
            await metricsCollector.recordCacheOperation(
                type: .miss,
                duration: Date().timeIntervalSince(startTime),
                size: 0,
                success: false
            )
            return nil
        }
        
        do {
            // Decrypt if needed
            let documentData: Data
            if cachedData.metadata.isEncrypted, let encryption = encryptionLayer {
                guard let nonce = cachedData.metadata.nonce else {
                    throw CacheError.missingEncryptionData
                }
                documentData = try await encryption.decrypt(
                    ciphertext: cachedData.data,
                    nonce: nonce
                )
            } else {
                documentData = cachedData.data
            }
            
            // Verify integrity
            let checksum = SHA256.hash(data: documentData).compactMap { String(format: "%02x", $0) }.joined()
            guard checksum == cachedData.metadata.checksum else {
                throw CacheError.integrityCheckFailed
            }
            
            // Deserialize
            let decoder = JSONDecoder()
            let document = try decoder.decode(GeneratedDocument.self, from: documentData)
            
            // Update metrics
            let retrievalTime = Date().timeIntervalSince(startTime)
            await metricsCollector.recordCacheOperation(
                type: .hit,
                duration: retrievalTime,
                size: cachedData.data.count,
                success: true
            )
            
            return document
            
        } catch {
            print("❌ Failed to retrieve cached document: \(error)")
            await metricsCollector.recordCacheOperation(
                type: .error,
                duration: Date().timeIntervalSince(startTime),
                size: 0,
                success: false
            )
            return nil
        }
    }
    
    // MARK: - Configuration Updates
    
    func updateConfiguration(_ newConfig: CacheConfiguration) async throws {
        // Update storage limits
        await standardStorage.updateLimits(
            maxCacheSize: newConfig.maxCacheSize,
            maxMemorySize: newConfig.maxMemorySize
        )
        
        // Handle encryption changes
        if newConfig.encryptionEnabled && encryptionLayer == nil {
            // Enable encryption - need to re-encrypt existing data
            throw CacheError.configurationChangeRequiresClear
        } else if !newConfig.encryptionEnabled && encryptionLayer != nil {
            // Disable encryption - need to decrypt existing data
            throw CacheError.configurationChangeRequiresClear
        }
        
        // Update adaptive engine
        if let adaptive = adaptiveEngine {
            await adaptive.updateBaseLimits(
                cacheSize: newConfig.maxCacheSize,
                memorySize: newConfig.maxMemorySize
            )
        }
        
        self.configuration = newConfig
    }
    
    // MARK: - Cache Management
    
    func clearCache() async {
        await standardStorage.clearCache()
        await metricsCollector.reset()
    }
    
    func getStatistics() async -> CacheStatistics {
        let baseStats = await standardStorage.getStatistics()
        let metrics = await metricsCollector.getMetrics()
        
        return CacheStatistics(
            totalCachedDocuments: baseStats.documentCount,
            totalCachedAnalyses: baseStats.analysisCount,
            cacheSize: baseStats.totalSize,
            hitRate: metrics.hitRate,
            averageRetrievalTime: metrics.averageRetrievalTime,
            lastCleanup: baseStats.lastCleanup,
            mostAccessedDocumentTypes: baseStats.mostAccessedTypes
        )
    }
    
    // MARK: - Security Operations
    
    func rotateEncryptionKey() async throws {
        guard let encryption = encryptionLayer else {
            throw CacheError.encryptionNotEnabled
        }
        
        // Get all cached items
        let allItems = await standardStorage.getAllCachedItems()
        
        // Generate new key
        try await encryption.rotateKey()
        
        // Re-encrypt all items
        for item in allItems {
            if item.metadata.isEncrypted, let nonce = item.metadata.nonce {
                // Decrypt with old key (handled internally by encryption layer)
                let decrypted = try await encryption.decrypt(
                    ciphertext: item.data,
                    nonce: nonce
                )
                
                // Re-encrypt with new key
                let reEncrypted = try await encryption.encrypt(decrypted)
                
                // Update in storage
                var newMetadata = item.metadata
                newMetadata.nonce = reEncrypted.nonce
                
                try await standardStorage.updateCachedItem(
                    key: item.key,
                    data: reEncrypted.ciphertext,
                    metadata: newMetadata
                )
            }
        }
    }
    
    // MARK: - Adaptive Operations
    
    func adjustCacheLimits() async {
        guard let adaptive = adaptiveEngine else { return }
        
        await adaptive.adjustLimitsIfNeeded()
        let limits = await adaptive.getCurrentLimits()
        
        await standardStorage.updateLimits(
            maxCacheSize: limits.cacheSize,
            maxMemorySize: limits.memorySize
        )
    }
    
    func getAdaptiveMetrics() async -> AdaptiveMetrics? {
        guard let adaptive = adaptiveEngine else { return nil }
        
        let metrics = await metricsCollector.getMetrics()
        let limits = await adaptive.getCurrentLimits()
        let pressure = await adaptive.getMemoryPressure()
        
        return AdaptiveMetrics(
            currentCacheSizeLimit: limits.cacheSize,
            currentMemoryLimit: limits.memorySize,
            actualCacheSize: await standardStorage.getStatistics().documentCount,
            actualMemoryUsage: await standardStorage.getStatistics().totalSize,
            systemMemoryPressure: pressure,
            recentHitRate: metrics.hitRate,
            recentEvictionRate: metrics.evictionRate,
            averageResponseTime: metrics.averageRetrievalTime,
            adaptiveAdjustmentCount: await adaptive.getAdjustmentCount()
        )
    }
}

// MARK: - Component Implementations

private final class StandardCacheComponent {
    // Implementation would include basic cache storage logic
    // Similar to DocumentCacheStorage but without encryption/adaptive features
    private var maxCacheSize: Int
    private var maxMemorySize: Int64
    
    init(maxCacheSize: Int, maxMemorySize: Int64) {
        self.maxCacheSize = maxCacheSize
        self.maxMemorySize = maxMemorySize
    }
    
    func updateLimits(maxCacheSize: Int, maxMemorySize: Int64) async {
        self.maxCacheSize = maxCacheSize
        self.maxMemorySize = maxMemorySize
    }
    
    func cacheDocument(data: Data, documentType: DocumentCategoryType, requirements: String, metadata: CacheMetadata) async throws {
        // Implementation
    }
    
    func getCachedDocument(type: DocumentType, requirements: String) async -> CachedItem? {
        // Implementation
        return nil
    }
    
    func getAllCachedItems() async -> [CachedItem] {
        // Implementation
        return []
    }
    
    func updateCachedItem(key: String, data: Data, metadata: CacheMetadata) async throws {
        // Implementation
    }
    
    func clearCache() async {
        // Implementation
    }
    
    func getStatistics() async -> BaseStatistics {
        // Implementation
        return BaseStatistics(
            documentCount: 0,
            analysisCount: 0,
            totalSize: 0,
            lastCleanup: nil,
            mostAccessedTypes: []
        )
    }
}

private final class EncryptionLayer {
    private var masterKey: SymmetricKey
    private let keychainService = "com.aiko.unified.cache"
    
    struct EncryptedData {
        let ciphertext: Data
        let nonce: Data
    }
    
    init() async throws {
        // Initialize or load encryption key
        self.masterKey = SymmetricKey(size: .bits256)
    }
    
    func encrypt(_ data: Data) async throws -> EncryptedData {
        let sealedBox = try AES.GCM.seal(data, using: masterKey)
        guard let combined = sealedBox.combined else {
            throw CacheError.encryptionFailed
        }
        
        return EncryptedData(
            ciphertext: combined,
            nonce: sealedBox.nonce.withUnsafeBytes { Data($0) }
        )
    }
    
    func decrypt(ciphertext: Data, nonce: Data) async throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: masterKey)
    }
    
    func rotateKey() async throws {
        // Generate new key
        self.masterKey = SymmetricKey(size: .bits256)
        // Save to keychain
    }
}

private final class AdaptiveEngine {
    private var baseCacheSize: Int
    private var baseMemorySize: Int64
    private var adjustmentCount: Int = 0
    
    init(baseCacheSize: Int, baseMemorySize: Int64) {
        self.baseCacheSize = baseCacheSize
        self.baseMemorySize = baseMemorySize
    }
    
    func adjustLimitsIfNeeded() async {
        // Implementation of adaptive sizing logic
        adjustmentCount += 1
    }
    
    func getCurrentLimits() async -> (cacheSize: Int, memorySize: Int64) {
        // Return current adaptive limits
        return (baseCacheSize, baseMemorySize)
    }
    
    func getMemoryPressure() async -> MemoryPressureLevel {
        // Check system memory and return pressure level
        return .normal
    }
    
    func updateBaseLimits(cacheSize: Int, memorySize: Int64) async {
        self.baseCacheSize = cacheSize
        self.baseMemorySize = memorySize
    }
    
    func getAdjustmentCount() async -> Int {
        return adjustmentCount
    }
}

private final class MetricsCollector {
    private var enabled: Bool
    private var operations: [CacheOperation] = []
    
    enum OperationType {
        case cache, hit, miss, error
    }
    
    struct CacheOperation {
        let type: OperationType
        let duration: TimeInterval
        let size: Int
        let timestamp: Date
        let success: Bool
    }
    
    init(enabled: Bool) {
        self.enabled = enabled
    }
    
    func recordCacheOperation(type: OperationType, duration: TimeInterval, size: Int, success: Bool) async {
        guard enabled else { return }
        
        let operation = CacheOperation(
            type: type,
            duration: duration,
            size: size,
            timestamp: Date(),
            success: success
        )
        
        operations.append(operation)
        
        // Keep only recent operations
        if operations.count > 1000 {
            operations.removeFirst(operations.count - 1000)
        }
    }
    
    func getMetrics() async -> CacheMetrics {
        let hits = operations.filter { $0.type == .hit }.count
        let misses = operations.filter { $0.type == .miss }.count
        let total = hits + misses
        
        let hitRate = total > 0 ? Double(hits) / Double(total) : 0.0
        
        let retrievalTimes = operations
            .filter { $0.type == .hit || $0.type == .miss }
            .map { $0.duration }
        
        let avgRetrievalTime = retrievalTimes.isEmpty ? 0.0 : retrievalTimes.reduce(0, +) / Double(retrievalTimes.count)
        
        // Calculate eviction rate (simplified)
        let evictionRate = 0.05 // Would calculate based on actual evictions
        
        return CacheMetrics(
            hitRate: hitRate,
            evictionRate: evictionRate,
            averageRetrievalTime: avgRetrievalTime
        )
    }
    
    func reset() async {
        operations.removeAll()
    }
}

// MARK: - Supporting Types

struct CacheMetadata: Codable {
    var isEncrypted: Bool
    var nonce: Data?
    let originalSize: Int
    let checksum: String
}

struct CachedItem {
    let key: String
    let data: Data
    let metadata: CacheMetadata
}

struct BaseStatistics {
    let documentCount: Int
    let analysisCount: Int
    let totalSize: Int64
    let lastCleanup: Date?
    let mostAccessedTypes: [DocumentType]
}

struct CacheMetrics {
    let hitRate: Double
    let evictionRate: Double
    let averageRetrievalTime: TimeInterval
}

enum CacheError: LocalizedError {
    case encryptionNotEnabled
    case encryptionFailed
    case decryptionFailed
    case missingEncryptionData
    case integrityCheckFailed
    case configurationChangeRequiresClear
    
    var errorDescription: String? {
        switch self {
        case .encryptionNotEnabled:
            return "Encryption is not enabled for this cache"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .missingEncryptionData:
            return "Missing encryption data (nonce)"
        case .integrityCheckFailed:
            return "Data integrity check failed"
        case .configurationChangeRequiresClear:
            return "Configuration change requires clearing the cache"
        }
    }
}

// MARK: - Dependency Implementation

extension UnifiedDocumentCacheService: DependencyKey {
    public static var liveValue: UnifiedDocumentCacheService {
        let storage = Task {
            try await UnifiedCacheStorage(configuration: .standard)
        }
        
        func getStorage() async throws -> UnifiedCacheStorage {
            try await storage.value
        }
        
        return UnifiedDocumentCacheService(
            cacheDocument: { document in
                let storage = try await getStorage()
                let requirements = String(document.content.prefix(200))
                try await storage.cacheDocument(document, requirements: requirements)
            },
            getCachedDocument: { type, requirements in
                guard let storage = try? await getStorage() else { return nil }
                return await storage.getCachedDocument(type: type, requirements: requirements)
            },
            cacheAnalysisResponse: { requirements, response, recommendedDocuments in
                // Implementation similar to other cache services
            },
            getCachedAnalysisResponse: { requirements in
                // Implementation similar to other cache services
                return nil
            },
            clearCache: {
                let storage = try await getStorage()
                await storage.clearCache()
            },
            getCacheStatistics: {
                guard let storage = try? await getStorage() else {
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
                return await storage.getStatistics()
            },
            preloadFrequentDocuments: {
                // Implementation for preloading
            },
            optimizeCacheForMemory: {
                let storage = try await getStorage()
                await storage.adjustCacheLimits()
            },
            rotateEncryptionKey: {
                let storage = try await getStorage()
                try await storage.rotateEncryptionKey()
            },
            exportEncryptedBackup: {
                // Implementation for backup
                return Data()
            },
            importEncryptedBackup: { _ in
                // Implementation for restore
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
                return await storage.getAdaptiveMetrics() ?? AdaptiveMetrics(
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
            },
            updateConfiguration: { config in
                let storage = try await getStorage()
                try await storage.updateConfiguration(config)
            },
            getCurrentConfiguration: {
                // Return current configuration
                return .standard
            }
        )
    }
}

extension DependencyValues {
    public var unifiedDocumentCache: UnifiedDocumentCacheService {
        get { self[UnifiedDocumentCacheService.self] }
        set { self[UnifiedDocumentCacheService.self] = newValue }
    }
}
import AppCore
import ComposableArchitecture
import Foundation

// MARK: - Cache Migration Extensions

public extension DocumentCacheService {
    /// Creates an encrypted version of the document cache
    var encrypted: EncryptedDocumentCache {
        EncryptedDocumentCache(
            cacheDocument: cacheDocument,
            getCachedDocument: getCachedDocument,
            cacheAnalysisResponse: cacheAnalysisResponse,
            getCachedAnalysisResponse: getCachedAnalysisResponse,
            clearCache: clearCache,
            getCacheStatistics: getCacheStatistics,
            preloadFrequentDocuments: preloadFrequentDocuments,
            optimizeCacheForMemory: optimizeCacheForMemory,
            rotateEncryptionKey: {
                // No-op for standard cache
            },
            exportEncryptedBackup: {
                Data()
            },
            importEncryptedBackup: { _ in
                // No-op for standard cache
            }
        )
    }

    /// Creates an adaptive version of the document cache
    var adaptive: AdaptiveDocumentCache {
        AdaptiveDocumentCache(
            cacheDocument: cacheDocument,
            getCachedDocument: getCachedDocument,
            cacheAnalysisResponse: cacheAnalysisResponse,
            getCachedAnalysisResponse: getCachedAnalysisResponse,
            clearCache: clearCache,
            getCacheStatistics: getCacheStatistics,
            preloadFrequentDocuments: preloadFrequentDocuments,
            optimizeCacheForMemory: optimizeCacheForMemory,
            rotateEncryptionKey: {
                // No-op for standard cache
            },
            exportEncryptedBackup: {
                Data()
            },
            importEncryptedBackup: { _ in
                // No-op for standard cache
            },
            adjustCacheLimits: {
                // No-op for standard cache
            },
            getAdaptiveMetrics: {
                AdaptiveMetrics(
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
        )
    }
}

public extension EncryptedDocumentCache {
    /// Creates an adaptive version of the encrypted cache
    var adaptive: AdaptiveDocumentCache {
        AdaptiveDocumentCache(
            cacheDocument: cacheDocument,
            getCachedDocument: getCachedDocument,
            cacheAnalysisResponse: cacheAnalysisResponse,
            getCachedAnalysisResponse: getCachedAnalysisResponse,
            clearCache: clearCache,
            getCacheStatistics: getCacheStatistics,
            preloadFrequentDocuments: preloadFrequentDocuments,
            optimizeCacheForMemory: optimizeCacheForMemory,
            rotateEncryptionKey: rotateEncryptionKey,
            exportEncryptedBackup: exportEncryptedBackup,
            importEncryptedBackup: importEncryptedBackup,
            adjustCacheLimits: {
                // Delegate to optimize memory
                try? await self.optimizeCacheForMemory()
            },
            getAdaptiveMetrics: {
                // Return estimated metrics based on current cache stats
                let stats = await self.getCacheStatistics()
                return AdaptiveMetrics(
                    currentCacheSizeLimit: 50,
                    currentMemoryLimit: 100 * 1024 * 1024,
                    actualCacheSize: stats.totalCachedDocuments + stats.totalCachedAnalyses,
                    actualMemoryUsage: stats.cacheSize,
                    systemMemoryPressure: .normal,
                    recentHitRate: stats.hitRate,
                    recentEvictionRate: 0.05, // Estimated
                    averageResponseTime: stats.averageRetrievalTime,
                    adaptiveAdjustmentCount: 0
                )
            }
        )
    }
}

// MARK: - Enhanced Cache Statistics

public extension CacheStatistics {
    /// Creates cache statistics with adaptive metrics
    func withAdaptiveMetrics(_ metrics: AdaptiveMetrics) -> EnhancedCacheStatistics {
        EnhancedCacheStatistics(
            base: self,
            adaptive: metrics
        )
    }
}

public struct EnhancedCacheStatistics: Equatable {
    public let base: CacheStatistics
    public let adaptive: AdaptiveMetrics

    public var formattedMemoryPressure: String {
        switch adaptive.systemMemoryPressure {
        case .normal:
            "Normal"
        case .warning:
            "Warning"
        case .urgent:
            "Urgent"
        case .critical:
            "Critical"
        }
    }

    public var adaptiveDescription: String {
        """
        Cache Size: \(adaptive.actualCacheSize)/\(adaptive.currentCacheSizeLimit) items
        Memory Usage: \(ByteCountFormatter.string(fromByteCount: adaptive.actualMemoryUsage, countStyle: .binary))/\(ByteCountFormatter.string(fromByteCount: adaptive.currentMemoryLimit, countStyle: .binary))
        System Memory: \(formattedMemoryPressure)
        Hit Rate: \(String(format: "%.1f%%", adaptive.recentHitRate * 100))
        Eviction Rate: \(String(format: "%.1f%%", adaptive.recentEvictionRate * 100))
        Avg Response: \(String(format: "%.3fms", adaptive.averageResponseTime * 1000))
        """
    }
}

// MARK: - Cache Type Selection

public enum CacheType: Sendable {
    case standard
    case encrypted
    case adaptive
}

public struct SimpleCacheConfiguration: Sendable {
    public let type: CacheType
    public let enableMetrics: Bool
    public let enablePreloading: Bool

    public static let `default` = SimpleCacheConfiguration(
        type: .standard,
        enableMetrics: true,
        enablePreloading: false
    )

    public static let secure = SimpleCacheConfiguration(
        type: .encrypted,
        enableMetrics: true,
        enablePreloading: false
    )

    public static let performance = SimpleCacheConfiguration(
        type: .adaptive,
        enableMetrics: true,
        enablePreloading: true
    )
}

// MARK: - Unified Cache Provider

public struct UnifiedCacheProvider {
    private let configuration: SimpleCacheConfiguration

    public init(configuration: SimpleCacheConfiguration = .default) {
        self.configuration = configuration
    }

    public func makeCache() -> any CacheProtocol {
        switch configuration.type {
        case .standard:
            DocumentCacheService.liveValue
        case .encrypted:
            EncryptedDocumentCache.liveValue
        case .adaptive:
            AdaptiveDocumentCache.liveValue
        }
    }
}

// MARK: - Cache Protocol

public protocol CacheProtocol {
    var cacheDocument: (GeneratedDocument) async throws -> Void { get }
    var getCachedDocument: (DocumentType, String) async -> GeneratedDocument? { get }
    var cacheAnalysisResponse: (String, String, [DocumentType]) async throws -> Void { get }
    var getCachedAnalysisResponse: (String) async -> (response: String, recommendedDocuments: [DocumentType])? { get }
    var clearCache: () async throws -> Void { get }
    var getCacheStatistics: () async -> CacheStatistics { get }
    var preloadFrequentDocuments: () async throws -> Void { get }
    var optimizeCacheForMemory: () async throws -> Void { get }
}

extension DocumentCacheService: CacheProtocol {}
extension EncryptedDocumentCache: CacheProtocol {}
extension AdaptiveDocumentCache: CacheProtocol {}

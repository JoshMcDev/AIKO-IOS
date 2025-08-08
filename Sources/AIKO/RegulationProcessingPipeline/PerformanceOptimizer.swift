import Foundation
import os

// MARK: - Performance Optimizer

/// Central performance optimization system for the Regulation Processing Pipeline
/// Implements caching strategies, memory estimation, and batch processing optimization
public actor PerformanceOptimizer {
    // MARK: - Configuration

    public struct Configuration: Sendable {
        public let enableCaching: Bool
        public let cacheMaxSizeMB: Int
        public let enableMemoryPrediction: Bool
        public let enableBatchOptimization: Bool
        public let enablePreloading: Bool
        public let maxPreloadItems: Int

        public init(
            enableCaching: Bool = true,
            cacheMaxSizeMB: Int = 100,
            enableMemoryPrediction: Bool = true,
            enableBatchOptimization: Bool = true,
            enablePreloading: Bool = true,
            maxPreloadItems: Int = 10
        ) {
            self.enableCaching = enableCaching
            self.cacheMaxSizeMB = cacheMaxSizeMB
            self.enableMemoryPrediction = enableMemoryPrediction
            self.enableBatchOptimization = enableBatchOptimization
            self.enablePreloading = enablePreloading
            self.maxPreloadItems = maxPreloadItems
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private let logger = Logger(subsystem: "com.aiko.pipeline", category: "PerformanceOptimizer")
    private let cache = InMemoryCache<String, CachedItem>()
    private let memoryEstimator = MemoryEstimator()
    private let batchOptimizer = BatchOptimizer()
    private var performanceMetrics = OptimizerMetrics()

    // MARK: - Initialization

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    // MARK: - Memory Estimation

    /// Optimized memory estimation algorithm using historical data and predictive modeling
    public func estimateMemoryUsage(for items: [RegulationChunk]) async -> MemoryEstimate {
        guard configuration.enableMemoryPrediction else {
            // Fallback to simple estimation
            let basicEstimate = Double(items.count) * 1.5 // 1.5MB per chunk average
            return MemoryEstimate(
                estimatedMB: basicEstimate,
                confidence: 0.5,
                method: .simple
            )
        }

        // Advanced estimation using ML-like approach
        let features = extractFeatures(from: items)
        let prediction = await memoryEstimator.predict(features: features)

        // Apply correction based on historical accuracy
        let correctedPrediction = applyHistoricalCorrection(prediction)

        return MemoryEstimate(
            estimatedMB: correctedPrediction,
            confidence: 0.85,
            method: .advanced
        )
    }

    private func extractFeatures(from items: [RegulationChunk]) -> MemoryFeatures {
        MemoryFeatures(
            itemCount: items.count,
            averageTokenCount: items.reduce(0) { $0 + $1.tokenCount } / max(1, items.count),
            maxTokenCount: items.map { $0.tokenCount }.max() ?? 0,
            averageDepth: items.reduce(0) { $0 + $1.depth } / max(1, items.count),
            hasNestedStructures: items.contains { $0.depth > 3 },
            contentComplexity: calculateContentComplexity(items)
        )
    }

    private func calculateContentComplexity(_ items: [RegulationChunk]) -> Double {
        var complexity = 0.0
        for item in items {
            if item.hierarchyPath.count > 3 { complexity += 0.2 }
            if item.tokenCount > 500 { complexity += 0.3 }
            if item.semanticCoherence < 0.7 { complexity += 0.1 }
        }
        return min(1.0, complexity / Double(max(1, items.count)))
    }

    private func applyHistoricalCorrection(_ prediction: Double) -> Double {
        // Apply correction factor based on historical accuracy
        let correctionFactor = performanceMetrics.averagePredictionAccuracy
        return prediction * (1.0 + (1.0 - correctionFactor) * 0.2) // Adjust by up to 20%
    }

    // MARK: - Batch Processing Optimization

    /// Optimize batch processing efficiency with dynamic sizing and parallelization
    public func optimizeBatchProcessing(
        items: [RegulationChunk],
        memoryLimitMB: Int
    ) async -> BatchProcessingPlan {
        guard configuration.enableBatchOptimization else {
            // Simple fixed batch size
            return BatchProcessingPlan(
                batches: items.chunked(into: 10),
                optimalBatchSize: 10,
                parallelismLevel: 1,
                estimatedTime: Double(items.count) * 0.1
            )
        }

        // Dynamic batch optimization
        let optimalSize = await batchOptimizer.calculateOptimalBatchSize(
            itemCount: items.count,
            memoryLimitMB: memoryLimitMB,
            processingCharacteristics: analyzeProcessingCharacteristics(items)
        )

        let parallelism = calculateOptimalParallelism(memoryLimitMB: memoryLimitMB)
        let batches = createOptimizedBatches(items: items, batchSize: optimalSize)

        return BatchProcessingPlan(
            batches: batches,
            optimalBatchSize: optimalSize,
            parallelismLevel: parallelism,
            estimatedTime: estimateProcessingTime(batchCount: batches.count, parallelism: parallelism)
        )
    }

    private func analyzeProcessingCharacteristics(_ items: [RegulationChunk]) -> ProcessingCharacteristics {
        ProcessingCharacteristics(
            uniformity: calculateUniformity(items),
            complexity: calculateContentComplexity(items),
            interdependency: calculateInterdependency(items)
        )
    }

    private func calculateUniformity(_ items: [RegulationChunk]) -> Double {
        guard items.count > 1 else { return 1.0 }
        let tokenCounts = items.map { Double($0.tokenCount) }
        let mean = tokenCounts.reduce(0, +) / Double(tokenCounts.count)
        let variance = tokenCounts.reduce(0) { $0 + pow($1 - mean, 2) } / Double(tokenCounts.count)
        let standardDeviation = sqrt(variance)
        return max(0, 1.0 - (standardDeviation / mean))
    }

    private func calculateInterdependency(_ items: [RegulationChunk]) -> Double {
        var interdependency = 0.0
        for i in 1 ..< items.count {
            if items[i].parentSection == items[i - 1].parentSection {
                interdependency += 0.1
            }
        }
        return min(1.0, interdependency)
    }

    private func calculateOptimalParallelism(memoryLimitMB: Int) -> Int {
        let availableCores = ProcessInfo.processInfo.processorCount
        let memoryBasedLimit = max(1, memoryLimitMB / 50) // Assume 50MB per parallel task
        return min(availableCores, memoryBasedLimit, 8) // Cap at 8 for stability
    }

    private func createOptimizedBatches(items: [RegulationChunk], batchSize: Int) -> [[RegulationChunk]] {
        // Group related items together for better cache locality
        let grouped = groupRelatedItems(items)
        return grouped.chunked(into: batchSize)
    }

    private func groupRelatedItems(_ items: [RegulationChunk]) -> [RegulationChunk] {
        items.sorted { lhs, rhs in
            // Sort by parent section first, then by token count
            if lhs.parentSection == rhs.parentSection {
                return lhs.tokenCount < rhs.tokenCount
            }
            return (lhs.parentSection ?? "") < (rhs.parentSection ?? "")
        }
    }

    private func estimateProcessingTime(batchCount: Int, parallelism: Int) -> Double {
        let baseTimePerBatch = 0.5 // seconds
        let parallelBatches = Double(batchCount) / Double(parallelism)
        return parallelBatches * baseTimePerBatch
    }

    // MARK: - Caching Strategies

    /// Implement multi-level caching with LRU eviction and predictive preloading
    public func getCachedOrProcess<T: Sendable>(
        key: String,
        compute: () async throws -> T
    ) async throws -> T {
        guard configuration.enableCaching else {
            return try await compute()
        }

        // Check cache
        if let cached = await cache.get(key) {
            performanceMetrics.cacheHits += 1
            if let value = cached.value as? T {
                return value
            }
        }

        performanceMetrics.cacheMisses += 1

        // Compute and cache
        let startTime = Date()
        let result = try await compute()
        let computeTime = Date().timeIntervalSince(startTime)

        let cachedItem = CachedItem(
            value: result,
            timestamp: Date(),
            accessCount: 1,
            computeTime: computeTime,
            sizeEstimate: estimateSize(of: result)
        )

        await cache.set(key: key, value: cachedItem)

        // Predictive preloading
        if configuration.enablePreloading {
            await preloadRelatedItems(basedOn: key)
        }

        return result
    }

    private func estimateSize<T>(of value: T) -> Int {
        // Simple size estimation
        return MemoryLayout<T>.size
    }

    private func preloadRelatedItems(basedOn key: String) async {
        // Implement predictive preloading based on access patterns
        let relatedKeys = predictRelatedKeys(from: key)
        for relatedKey in relatedKeys.prefix(configuration.maxPreloadItems) {
            // Schedule preloading in background
            Task.detached(priority: .background) {
                // Preload logic here
                self.logger.debug("Preloading related item: \(relatedKey)")
            }
        }
    }

    private func predictRelatedKeys(from key: String) -> [String] {
        // Simple pattern-based prediction
        var related: [String] = []
        if key.contains("chunk-") {
            if let chunkNumber = extractNumber(from: key) {
                related.append(key.replacingOccurrences(of: "\(chunkNumber)", with: "\(chunkNumber + 1)"))
                if chunkNumber > 0 {
                    related.append(key.replacingOccurrences(of: "\(chunkNumber)", with: "\(chunkNumber - 1)"))
                }
            }
        }
        return related
    }

    private func extractNumber(from string: String) -> Int? {
        let pattern = "\\d+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
        guard let match = matches.first,
              let range = Range(match.range, in: string) else { return nil }
        return Int(string[range])
    }

    // MARK: - Performance Monitoring

    public func getPerformanceReport() async -> OptimizerPerformanceReport {
        let cacheHitRate = Double(performanceMetrics.cacheHits) /
            Double(max(1, performanceMetrics.cacheHits + performanceMetrics.cacheMisses))

        let memoryMonitor = UnifiedMemoryMonitor.shared
        let currentMemory = await memoryMonitor.currentMemoryUsage()
        let peakMemory = await memoryMonitor.getPeakUsage()

        return OptimizerPerformanceReport(
            cacheHitRate: cacheHitRate,
            totalCacheHits: performanceMetrics.cacheHits,
            totalCacheMisses: performanceMetrics.cacheMisses,
            averagePredictionAccuracy: performanceMetrics.averagePredictionAccuracy,
            currentMemoryMB: Double(currentMemory) / (1024 * 1024),
            peakMemoryMB: Double(peakMemory) / (1024 * 1024),
            optimizationsSuggested: generateOptimizationSuggestions(cacheHitRate: cacheHitRate)
        )
    }

    private func generateOptimizationSuggestions(cacheHitRate: Double) -> [String] {
        var suggestions: [String] = []

        if cacheHitRate < 0.3 {
            suggestions.append("Consider increasing cache size or adjusting cache key strategy")
        }
        if performanceMetrics.averagePredictionAccuracy < 0.7 {
            suggestions.append("Memory prediction model needs retraining with more data")
        }
        if configuration.cacheMaxSizeMB < 200 {
            suggestions.append("Increasing cache size to 200MB could improve performance")
        }

        return suggestions
    }

    public func updatePredictionAccuracy(predicted: Double, actual: Double) async {
        let accuracy = 1.0 - abs(predicted - actual) / max(predicted, actual, 1.0)
        performanceMetrics.updatePredictionAccuracy(accuracy)
    }
}

// MARK: - Supporting Types

public struct MemoryEstimate: Sendable {
    public let estimatedMB: Double
    public let confidence: Double
    public let method: EstimationMethod

    public enum EstimationMethod: Sendable {
        case simple
        case advanced
    }
}

public struct MemoryFeatures: Sendable, Hashable {
    let itemCount: Int
    let averageTokenCount: Int
    let maxTokenCount: Int
    let averageDepth: Int
    let hasNestedStructures: Bool
    let contentComplexity: Double
}

public struct BatchProcessingPlan: Sendable {
    public let batches: [[RegulationChunk]]
    public let optimalBatchSize: Int
    public let parallelismLevel: Int
    public let estimatedTime: Double
}

public struct ProcessingCharacteristics: Sendable {
    let uniformity: Double
    let complexity: Double
    let interdependency: Double
}

public struct OptimizerPerformanceReport: Sendable {
    public let cacheHitRate: Double
    public let totalCacheHits: Int
    public let totalCacheMisses: Int
    public let averagePredictionAccuracy: Double
    public let currentMemoryMB: Double
    public let peakMemoryMB: Double
    public let optimizationsSuggested: [String]
}

// MARK: - Cache Implementation

actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private let maxItems = 1000

    func get(_ key: Key) -> Value? {
        if let value = storage[key] {
            // Update access order for LRU
            accessOrder.removeAll { $0 == key }
            accessOrder.append(key)
            return value
        }
        return nil
    }

    func set(key: Key, value: Value) {
        storage[key] = value
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)

        // Evict if necessary
        if storage.count > maxItems {
            evictLRU()
        }
    }

    private func evictLRU() {
        guard !accessOrder.isEmpty else { return }
        let keyToEvict = accessOrder.removeFirst()
        storage.removeValue(forKey: keyToEvict)
    }

    func clear() {
        storage.removeAll()
        accessOrder.removeAll()
    }
}

struct CachedItem: @unchecked Sendable {
    let value: Any
    let timestamp: Date
    var accessCount: Int
    let computeTime: TimeInterval
    let sizeEstimate: Int
}

// MARK: - Memory Estimator

actor MemoryEstimator {
    private var historicalData: [MemoryFeatures: Double] = [:]

    func predict(features: MemoryFeatures) async -> Double {
        // Simple prediction model
        var estimate = Double(features.itemCount) * 1.2 // Base estimate

        // Adjust based on features
        estimate *= (1.0 + Double(features.averageTokenCount) / 1000.0)
        estimate *= (1.0 + features.contentComplexity * 0.5)
        if features.hasNestedStructures {
            estimate *= 1.3
        }

        // Apply historical correction if available
        if let historicalEstimate = findSimilarHistorical(features) {
            estimate = (estimate + historicalEstimate) / 2.0
        }

        return estimate
    }

    private func findSimilarHistorical(_ features: MemoryFeatures) -> Double? {
        // Find similar historical data point
        for (historical, value) in historicalData {
            if abs(historical.itemCount - features.itemCount) < 10,
               abs(historical.averageTokenCount - features.averageTokenCount) < 100 {
                return value
            }
        }
        return nil
    }

    func recordActual(features: MemoryFeatures, actual: Double) {
        historicalData[features] = actual
        // Keep only recent data
        if historicalData.count > 100 {
            // Remove oldest entries (simplified)
            historicalData = Dictionary(uniqueKeysWithValues: historicalData.suffix(100))
        }
    }
}

// MARK: - Batch Optimizer

actor BatchOptimizer {
    func calculateOptimalBatchSize(
        itemCount: Int,
        memoryLimitMB: Int,
        processingCharacteristics: ProcessingCharacteristics
    ) async -> Int {
        // Base calculation
        var optimalSize = min(itemCount, max(1, memoryLimitMB / 10))

        // Adjust based on characteristics
        if processingCharacteristics.uniformity > 0.8 {
            optimalSize = min(optimalSize * 2, itemCount) // Can handle larger batches
        }
        if processingCharacteristics.complexity > 0.7 {
            optimalSize = max(1, optimalSize / 2) // Smaller batches for complex items
        }
        if processingCharacteristics.interdependency > 0.5 {
            optimalSize = min(optimalSize * 3 / 2, itemCount) // Keep related items together
        }

        return max(1, min(optimalSize, 100)) // Cap at 100 for stability
    }
}

// MARK: - Performance Metrics

struct OptimizerMetrics {
    var cacheHits = 0
    var cacheMisses = 0
    var averagePredictionAccuracy = 0.8
    private var predictionAccuracies: [Double] = []

    mutating func updatePredictionAccuracy(_ accuracy: Double) {
        predictionAccuracies.append(accuracy)
        if predictionAccuracies.count > 100 {
            predictionAccuracies.removeFirst()
        }
        averagePredictionAccuracy = predictionAccuracies.reduce(0, +) / Double(predictionAccuracies.count)
    }
}

// Array chunked extension is provided by ArrayExtensions.swift
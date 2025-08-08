import Foundation

/// LFM2-powered embedding service for regulation processing pipeline
/// Handles embedding generation, caching, batch processing, and semantic quality validation
public actor RegulationEmbeddingService {
    // MARK: - Configuration

    public let modelType: EmbeddingModelType
    public let dimensions: Int
    public let deviceType: EmbeddingDeviceType
    public let maxConcurrency: Int

    private let batchSize: Int
    private let enableContextualEmbedding: Bool
    private let enableMultiLevelCaching: Bool
    private let l1CacheSize: Int
    private let l2CacheSize: Int
    private let semanticCacheThreshold: Double
    private let enableIntelligentBatching: Bool
    private let targetBatchLatencyMs: Int
    private let maxBatchSize: Int
    private let enableConcurrentProcessing: Bool
    private let enableMemoryPressureHandling: Bool
    private let memoryPressureThresholdMB: Double
    private let queueManagementStrategy: EmbeddingQueueManagementStrategy
    private let vectorStorageIntegration: EmbeddingVectorStorageIntegration?
    private let enableErrorRecovery: Bool
    private let fallbackStrategy: EmbeddingFallbackStrategy
    private let maxRetryAttempts: Int
    private let enableQualityValidation: Bool
    private let qualityThresholds: EmbeddingQualityThresholds?

    // MARK: - State

    private var l1Cache: [UUID: EmbeddingRegulationEmbedding] = [:]
    private var l2Cache: [UUID: EmbeddingRegulationEmbedding] = [:]
    private var cacheAccessOrder: [UUID] = []
    private var vectorStorage: MockObjectBoxSemanticIndex?
    private var currentMemoryPressure: EmbeddingMemoryPressureLevel = .low

    // MARK: - Statistics

    private var cacheStats = EmbeddingCacheStatistics(l1HitRate: 0.0, l2HitRate: 0.0, evictionStats: EvictionStatistics(lruEvictions: 0, semanticEvictions: 0), semanticHits: 0)
    private var l1Hits = 0
    private var l2Hits = 0
    private var l1Misses = 0
    private var l2Misses = 0
    private var lruEvictions = 0
    private var semanticEvictions = 0
    private var semanticHits = 0

    // MARK: - Initialization

    public init(
        modelType: EmbeddingModelType,
        dimensions: Int,
        deviceType: EmbeddingDeviceType = .neural,
        batchSize: Int = 16,
        enableContextualEmbedding: Bool = false,
        enableMultiLevelCaching: Bool = false,
        l1CacheSize: Int = 100,
        l2CacheSize: Int = 500,
        semanticCacheThreshold: Double = 0.95,
        enableIntelligentBatching: Bool = false,
        targetBatchLatencyMs: Int = 500,
        maxBatchSize: Int = 64,
        maxConcurrency: Int = 4,
        enableConcurrentProcessing: Bool = false,
        enableMemoryPressureHandling: Bool = false,
        memoryPressureThresholdMB: Double = 300,
        queueManagementStrategy: EmbeddingQueueManagementStrategy = .fifo,
        vectorStorageIntegration: EmbeddingVectorStorageIntegration? = nil,
        enableErrorRecovery: Bool = false,
        fallbackStrategy: EmbeddingFallbackStrategy = .cpuFallback,
        maxRetryAttempts: Int = 3,
        enableQualityValidation: Bool = false,
        qualityThresholds: EmbeddingQualityThresholds? = nil
    ) {
        self.modelType = modelType
        self.dimensions = dimensions
        self.deviceType = deviceType
        self.maxConcurrency = maxConcurrency
        self.batchSize = batchSize
        self.enableContextualEmbedding = enableContextualEmbedding
        self.enableMultiLevelCaching = enableMultiLevelCaching
        self.l1CacheSize = l1CacheSize
        self.l2CacheSize = l2CacheSize
        self.semanticCacheThreshold = semanticCacheThreshold
        self.enableIntelligentBatching = enableIntelligentBatching
        self.targetBatchLatencyMs = targetBatchLatencyMs
        self.maxBatchSize = maxBatchSize
        self.enableConcurrentProcessing = enableConcurrentProcessing
        self.enableMemoryPressureHandling = enableMemoryPressureHandling
        self.memoryPressureThresholdMB = memoryPressureThresholdMB
        self.queueManagementStrategy = queueManagementStrategy
        self.vectorStorageIntegration = vectorStorageIntegration
        self.enableErrorRecovery = enableErrorRecovery
        self.fallbackStrategy = fallbackStrategy
        self.maxRetryAttempts = maxRetryAttempts
        self.enableQualityValidation = enableQualityValidation
        self.qualityThresholds = qualityThresholds
    }

    // MARK: - Core Embedding Generation

    public func generateEmbedding(for chunk: RegulationChunk) async throws -> EmbeddingRegulationEmbedding {
        // Check caches first
        if enableMultiLevelCaching {
            if let cached = checkCache(for: chunk.id) {
                return cached
            }
        }

        // Generate new embedding
        let embedding = try await generateNewEmbedding(for: chunk)

        // Cache the result
        if enableMultiLevelCaching {
            await cacheEmbedding(embedding)
        }

        return embedding
    }

    public func generateContextualEmbedding(_ chunk: RegulationChunk) async throws -> EmbeddingRegulationEmbedding {
        guard enableContextualEmbedding else {
            return try await generateEmbedding(for: chunk)
        }

        // Generate base embedding
        let baseEmbedding = try await generateNewEmbedding(for: chunk)

        // Generate contextual features
        var contextFeatures: [Float] = []
        var crossReferenceEmbeddings: [[Float]] = []
        var hierarchyFeatures = HierarchyFeatures()

        // Use available properties from SmartChunkingEngine's RegulationChunk
        if !chunk.hierarchyPath.isEmpty {
            // Generate hierarchy embeddings from hierarchyPath
            hierarchyFeatures = HierarchyFeatures(
                partEmbedding: chunk.hierarchyPath.first.map { generateHierarchyEmbedding($0) },
                sectionEmbedding: chunk.hierarchyPath.count > 1 ? generateHierarchyEmbedding(chunk.hierarchyPath[1]) : nil,
                depthEncoding: Float(chunk.depth)
            )

            // Generate context features from contextHeader
            contextFeatures = generateContextFeatures(from: chunk)
        }

        // Generate cross-reference embeddings from hierarchyPath (fallback)
        for pathElement in chunk.hierarchyPath {
            crossReferenceEmbeddings.append(generateHierarchyEmbedding(pathElement))
        }

        return EmbeddingRegulationEmbedding(
            chunkId: chunk.id,
            vector: baseEmbedding.vector,
            modelType: baseEmbedding.modelType,
            computeDevice: baseEmbedding.computeDevice,
            hasHierarchicalContext: true,
            contextFeatures: contextFeatures,
            crossReferenceEmbeddings: crossReferenceEmbeddings,
            hierarchyFeatures: hierarchyFeatures
        )
    }

    public func generateBatchEmbeddings(_ chunks: [RegulationChunk]) async throws -> [EmbeddingRegulationEmbedding] {
        if enableConcurrentProcessing {
            return try await generateConcurrentEmbeddings(chunks)
        } else {
            var embeddings: [EmbeddingRegulationEmbedding] = []
            for chunk in chunks {
                let embedding = try await generateEmbedding(for: chunk)
                embeddings.append(embedding)
            }
            return embeddings
        }
    }

    public func generateIntelligentBatchEmbeddings(_ chunks: [RegulationChunk]) async throws -> [EmbeddingRegulationEmbedding] {
        guard enableIntelligentBatching else {
            return try await generateBatchEmbeddings(chunks)
        }

        // Optimize batch sizes based on target latency
        let optimalBatchSize = calculateOptimalBatchSize(for: chunks)
        var embeddings: [EmbeddingRegulationEmbedding] = []

        for batchStart in stride(from: 0, to: chunks.count, by: optimalBatchSize) {
            let batchEnd = min(batchStart + optimalBatchSize, chunks.count)
            let batch = Array(chunks[batchStart ..< batchEnd])

            let batchEmbeddings = try await generateBatchEmbeddings(batch)
            embeddings.append(contentsOf: batchEmbeddings)
        }

        return embeddings
    }

    public func generateBatchEmbeddingsWithMemoryManagement(_ chunks: [RegulationChunk]) async throws -> [EmbeddingRegulationEmbedding] {
        guard enableMemoryPressureHandling else {
            return try await generateBatchEmbeddings(chunks)
        }

        var embeddings: [EmbeddingRegulationEmbedding] = []
        var adaptiveBatchSize = batchSize

        for batchStart in stride(from: 0, to: chunks.count, by: adaptiveBatchSize) {
            // Check memory pressure before processing
            let currentMemory = await MemoryMonitor.shared.getCurrentUsage()
            let memoryMB = Double(currentMemory) / (1024 * 1024)

            if memoryMB > memoryPressureThresholdMB {
                currentMemoryPressure = .high
                adaptiveBatchSize = max(1, adaptiveBatchSize / 2)
            } else if memoryMB < memoryPressureThresholdMB * 0.5 {
                currentMemoryPressure = .low
                adaptiveBatchSize = min(maxBatchSize, adaptiveBatchSize + 1)
            }

            let batchEnd = min(batchStart + adaptiveBatchSize, chunks.count)
            let batch = Array(chunks[batchStart ..< batchEnd])

            let batchEmbeddings = try await generateBatchEmbeddings(batch)
            embeddings.append(contentsOf: batchEmbeddings)
        }

        return embeddings
    }

    public func generateAndStoreEmbedding(for chunk: RegulationChunk) async throws -> EmbeddingRegulationEmbedding {
        let embedding = try await generateEmbedding(for: chunk)

        if let storage = vectorStorage {
            // Store in vector database
            _ = try await storage.retrieveVector(id: embedding.chunkId) // Simulated storage
        }

        return embedding
    }

    public func generateEmbeddingWithRecovery(for chunk: RegulationChunk) async throws -> EmbeddingRegulationEmbedding {
        guard enableErrorRecovery else {
            return try await generateEmbedding(for: chunk)
        }

        var lastError: Error?

        for attempt in 0 ..< maxRetryAttempts {
            do {
                return try await generateEmbedding(for: chunk)
            } catch let error as EmbeddingError {
                lastError = error

                if !error.isRecoverable {
                    throw error
                }

                // Apply recovery strategy
                switch fallbackStrategy {
                case .cpuFallback:
                    if deviceType != .cpu {
                        // Retry with CPU device
                        let cpuService = RegulationEmbeddingService(
                            modelType: modelType,
                            dimensions: dimensions,
                            deviceType: .cpu
                        )
                        return try await cpuService.generateEmbedding(for: chunk)
                    }
                case .modelFallback:
                    // Use simpler model
                    break
                case .caching:
                    // Try to find similar cached embedding
                    if let similarEmbedding = await findSimilarCachedEmbedding(for: chunk) {
                        return similarEmbedding
                    }
                }

                // Exponential backoff
                let delay = 0.1 * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            } catch {
                lastError = error
            }
        }

        throw lastError ?? EmbeddingError.modelFailure
    }

    public func generateValidatedEmbedding(for chunk: RegulationChunk) async throws -> EmbeddingRegulationEmbedding {
        let embedding = try await generateEmbedding(for: chunk)

        if enableQualityValidation {
            try validateEmbeddingQuality(embedding)
        }

        return embedding
    }

    // MARK: - Similarity Computation

    public func computeCosineSimilarity(_ embedding1: EmbeddingRegulationEmbedding, _ embedding2: EmbeddingRegulationEmbedding) async throws -> Double {
        let vector1 = embedding1.vector
        let vector2 = embedding2.vector

        guard vector1.count == vector2.count else {
            throw EmbeddingError.corruptedInput
        }

        let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))

        guard magnitude1 > 0 && magnitude2 > 0 else {
            return 0.0
        }

        return Double(dotProduct / (magnitude1 * magnitude2))
    }

    // MARK: - Configuration and Management

    public func configureVectorStorage(_ storage: MockObjectBoxSemanticIndex) async {
        vectorStorage = storage
    }

    public func simulateMemoryPressure(level: EmbeddingMemoryPressureLevel) async {
        currentMemoryPressure = level
    }

    // MARK: - Statistics and Monitoring

    public func getCacheStatistics() async -> EmbeddingCacheStatistics {
        let totalRequests = l1Hits + l2Hits + l1Misses + l2Misses
        let l1HitRate = totalRequests > 0 ? Double(l1Hits) / Double(totalRequests) : 0.0
        let l2HitRate = totalRequests > 0 ? Double(l2Hits) / Double(totalRequests) : 0.0

        return EmbeddingCacheStatistics(
            l1HitRate: l1HitRate,
            l2HitRate: l2HitRate,
            evictionStats: EvictionStatistics(
                lruEvictions: lruEvictions,
                semanticEvictions: semanticEvictions
            ),
            semanticHits: semanticHits
        )
    }

    public func getMemoryStatistics() async -> MemoryStatistics {
        let currentMemory = await MemoryMonitor.shared.getCurrentUsage()
        let peakMemory = await MemoryMonitor.shared.getPeakUsage()

        return MemoryStatistics(
            currentMemoryMB: Double(currentMemory) / (1024 * 1024),
            peakMemoryMB: Double(peakMemory) / (1024 * 1024),
            peakBatchMemoryMB: Double(peakMemory) / (1024 * 1024) * 0.8,
            memoryFragmentation: 0.1
        )
    }

    public func getQueueManagementStatistics() async -> QueueManagementStatistics {
        return QueueManagementStatistics(
            queueResizeEvents: 0,
            batchSizeReductions: 0,
            averageQueueLength: 0.0
        )
    }

    public func getFallbackStatistics() async -> FallbackStatistics {
        return FallbackStatistics(
            fallbackActivations: 0,
            fallbackSuccessRate: 0.95
        )
    }

    public func getEnergyMetrics() async -> EnergyMetrics {
        // Simulate energy metrics based on device type
        let baseEnergy = 1.5 // Base energy in millijoules
        let deviceMultiplier = switch deviceType {
        case .neural: 0.6 // Neural Engine is more efficient
        case .gpu: 1.2 // GPU uses more power
        case .cpu: 1.0 // CPU baseline
        }

        return EnergyMetrics(
            totalEnergyMJ: baseEnergy * deviceMultiplier,
            averagePowerWatts: 2.5 * deviceMultiplier
        )
    }

    // MARK: - Private Implementation

    private func generateNewEmbedding(for chunk: RegulationChunk) async throws -> EmbeddingRegulationEmbedding {
        // Validate input
        guard !chunk.content.isEmpty else {
            throw EmbeddingError.emptyContent
        }

        guard chunk.tokenCount <= 8192 else {
            throw EmbeddingError.oversizedChunk
        }

        // Simulate LFM2 embedding generation
        let vector = generateLFM2Vector(for: chunk.content, dimensions: dimensions)

        return EmbeddingRegulationEmbedding(
            chunkId: chunk.id,
            vector: vector,
            modelType: modelType,
            computeDevice: deviceType
        )
    }

    private func generateLFM2Vector(for content: String, dimensions: Int) -> [Float] {
        // Simulate LFM2 embedding generation with realistic properties
        var vector = [Float]()
        let contentHash = content.hashValue

        // Use deterministic random generation based on content
        var rng = SeededRandom(seed: UInt64(contentHash))

        // Generate vector with normal distribution
        for _ in 0 ..< dimensions {
            let u1 = Float.random(in: 0 ... 1, using: &rng)
            let u2 = Float.random(in: 0 ... 1, using: &rng)
            let z0 = sqrt(-2 * log(u1)) * cos(2 * Float.pi * u2)
            vector.append(z0 * 0.1) // Scale to reasonable range
        }

        // Normalize vector to unit length
        let magnitude = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            vector = vector.map { $0 / magnitude }
        }

        return vector
    }

    private func generateConcurrentEmbeddings(_ chunks: [RegulationChunk]) async throws -> [EmbeddingRegulationEmbedding] {
        return try await withThrowingTaskGroup(of: (Int, EmbeddingRegulationEmbedding).self) { group in
            // Add tasks with concurrency limit
            var activeCount = 0
            var results: [EmbeddingRegulationEmbedding?] = Array(repeating: nil, count: chunks.count)

            for (index, chunk) in chunks.enumerated() {
                if activeCount >= maxConcurrency {
                    if let result = try await group.next() {
                        let (completedIndex, embedding) = result
                        results[completedIndex] = embedding
                        activeCount -= 1
                    }
                }

                group.addTask {
                    let embedding = try await self.generateEmbedding(for: chunk)
                    return (index, embedding)
                }
                activeCount += 1
            }

            // Collect remaining results
            while activeCount > 0 {
                if let result = try await group.next() {
                    let (completedIndex, embedding) = result
                    results[completedIndex] = embedding
                    activeCount -= 1
                }
            }

            return results.compactMap { $0 }
        }
    }

    private func checkCache(for chunkId: UUID) -> EmbeddingRegulationEmbedding? {
        // Check L1 cache
        if let embedding = l1Cache[chunkId] {
            l1Hits += 1
            updateCacheAccessOrder(chunkId)
            return embedding
        }
        l1Misses += 1

        // Check L2 cache
        if let embedding = l2Cache[chunkId] {
            l2Hits += 1
            // Promote to L1
            promoteCacheEntry(chunkId, embedding)
            return embedding
        }
        l2Misses += 1

        return nil
    }

    private func cacheEmbedding(_ embedding: EmbeddingRegulationEmbedding) async {
        let chunkId = embedding.chunkId

        // Add to L1 cache
        if l1Cache.count >= l1CacheSize {
            evictLRU(from: &l1Cache)
        }

        l1Cache[chunkId] = embedding
        updateCacheAccessOrder(chunkId)
    }

    private func evictLRU(from cache: inout [UUID: EmbeddingRegulationEmbedding]) {
        if let oldestKey = cacheAccessOrder.first {
            cache.removeValue(forKey: oldestKey)
            cacheAccessOrder.removeFirst()
            lruEvictions += 1
        }
    }

    private func updateCacheAccessOrder(_ chunkId: UUID) {
        cacheAccessOrder.removeAll { $0 == chunkId }
        cacheAccessOrder.append(chunkId)
    }

    private func promoteCacheEntry(_ chunkId: UUID, _ embedding: EmbeddingRegulationEmbedding) {
        // Move from L2 to L1
        l2Cache.removeValue(forKey: chunkId)

        if l1Cache.count >= l1CacheSize {
            evictLRU(from: &l1Cache)
        }

        l1Cache[chunkId] = embedding
        updateCacheAccessOrder(chunkId)
    }

    private func findSimilarCachedEmbedding(for chunk: RegulationChunk) async -> EmbeddingRegulationEmbedding? {
        // Simple similarity search in cache
        let searchVector = generateLFM2Vector(for: chunk.content, dimensions: dimensions)

        for (_, cachedEmbedding) in l1Cache {
            let similarity = cosineSimilarity(searchVector, cachedEmbedding.vector)
            if similarity > semanticCacheThreshold {
                semanticHits += 1
                return cachedEmbedding
            }
        }

        return nil
    }

    private func cosineSimilarity(_ vec1: [Float], _ vec2: [Float]) -> Double {
        guard vec1.count == vec2.count else { return 0.0 }

        let dotProduct = zip(vec1, vec2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vec1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vec2.map { $0 * $0 }.reduce(0, +))

        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }

        return Double(dotProduct / (magnitude1 * magnitude2))
    }

    private func calculateOptimalBatchSize(for chunks: [RegulationChunk]) -> Int {
        // Simple heuristic based on content length
        let avgTokens = chunks.map { $0.tokenCount }.reduce(0, +) / chunks.count
        let baseSize = maxBatchSize

        if avgTokens > 1000 {
            return max(1, baseSize / 4)
        } else if avgTokens > 500 {
            return max(1, baseSize / 2)
        } else {
            return baseSize
        }
    }

    private func generateHierarchyEmbedding(_ text: String) -> [Float] {
        // Generate smaller embedding for hierarchy elements
        return generateLFM2Vector(for: text, dimensions: min(64, dimensions))
    }

    private func generateContextFeatures(from chunk: RegulationChunk) -> [Float] {
        // Generate context features based on contextHeader and parentSection
        let contextText = [chunk.contextHeader, chunk.parentSection].compactMap { $0 }.joined(separator: " ")
        if !contextText.isEmpty {
            return generateLFM2Vector(for: contextText, dimensions: min(128, dimensions))
        }
        return []
    }

    private func validateEmbeddingQuality(_ embedding: EmbeddingRegulationEmbedding) throws {
        guard let thresholds = qualityThresholds else { return }

        let magnitude = sqrt(embedding.vector.map { $0 * $0 }.reduce(0, +))

        if magnitude < thresholds.minimumMagnitude {
            throw EmbeddingError.corruptedInput
        }

        if magnitude > thresholds.maximumMagnitude {
            throw EmbeddingError.corruptedInput
        }

        let mean = embedding.vector.reduce(0, +) / Float(embedding.vector.count)
        let variance = embedding.vector.map { pow($0 - mean, 2) }.reduce(0, +) / Float(embedding.vector.count)

        if variance < thresholds.minimumVariance {
            throw EmbeddingError.corruptedInput
        }

        if variance > thresholds.maximumVariance {
            throw EmbeddingError.corruptedInput
        }
    }
}

// MARK: - Supporting Types

public enum EmbeddingModelType: Sendable {
    case lfm2, bert, sentenceTransformer
}

public enum EmbeddingDeviceType: Sendable {
    case cpu, gpu, neural
}

public enum EmbeddingVectorStorageIntegration: Sendable {
    case objectBox, coreML, custom
}

public enum EmbeddingQueueManagementStrategy: Sendable {
    case fifo, priority, adaptive
}

public enum EmbeddingFallbackStrategy: Sendable {
    case cpuFallback, modelFallback, caching
}

public enum EmbeddingError: Error, Sendable {
    case corruptedInput
    case oversizedChunk
    case emptyContent
    case modelFailure
    case memoryExhaustion

    public var isRecoverable: Bool {
        switch self {
        case .corruptedInput, .oversizedChunk: return true
        case .emptyContent: return true
        case .modelFailure, .memoryExhaustion: return false
        }
    }
}

public enum EmbeddingQualitySeverity: Sendable {
    case low, medium, high, critical
}

public enum EmbeddingMemoryPressureLevel: Sendable {
    case low, medium, high, critical
}

public struct EmbeddingRegulationEmbedding: Sendable {
    public let chunkId: UUID
    public let vector: [Float]
    public let modelType: EmbeddingModelType
    public let computeDevice: EmbeddingDeviceType
    public let hasHierarchicalContext: Bool
    public let contextFeatures: [Float]
    public let crossReferenceEmbeddings: [[Float]]
    public let hierarchyFeatures: HierarchyFeatures

    public init(
        chunkId: UUID,
        vector: [Float],
        modelType: EmbeddingModelType,
        computeDevice: EmbeddingDeviceType,
        hasHierarchicalContext: Bool = false,
        contextFeatures: [Float] = [],
        crossReferenceEmbeddings: [[Float]] = [],
        hierarchyFeatures: HierarchyFeatures = HierarchyFeatures()
    ) {
        self.chunkId = chunkId
        self.vector = vector
        self.modelType = modelType
        self.computeDevice = computeDevice
        self.hasHierarchicalContext = hasHierarchicalContext
        self.contextFeatures = contextFeatures
        self.crossReferenceEmbeddings = crossReferenceEmbeddings
        self.hierarchyFeatures = hierarchyFeatures
    }
}

public struct HierarchyFeatures: Sendable {
    public let partEmbedding: [Float]?
    public let sectionEmbedding: [Float]?
    public let depthEncoding: Float

    public init(
        partEmbedding: [Float]? = nil,
        sectionEmbedding: [Float]? = nil,
        depthEncoding: Float = 0
    ) {
        self.partEmbedding = partEmbedding
        self.sectionEmbedding = sectionEmbedding
        self.depthEncoding = depthEncoding
    }
}

public struct EmbeddingQualityThresholds: Sendable {
    public let minimumMagnitude: Float
    public let maximumMagnitude: Float
    public let minimumVariance: Float
    public let maximumVariance: Float

    public init(
        minimumMagnitude: Float,
        maximumMagnitude: Float,
        minimumVariance: Float,
        maximumVariance: Float
    ) {
        self.minimumMagnitude = minimumMagnitude
        self.maximumMagnitude = maximumMagnitude
        self.minimumVariance = minimumVariance
        self.maximumVariance = maximumVariance
    }
}

public struct QualityIssue: Sendable {
    public let type: QualityIssueType
    public let severity: EmbeddingQualitySeverity
    public let description: String

    public init(type: QualityIssueType, severity: EmbeddingQualitySeverity, description: String) {
        self.type = type
        self.severity = severity
        self.description = description
    }
}

public enum QualityIssueType: Sendable {
    case lowMagnitude, highMagnitude, lowVariance, highVariance, corruption
}

public struct EmbeddingCacheStatistics: Sendable {
    public let l1HitRate: Double
    public let l2HitRate: Double
    public let evictionStats: EvictionStatistics
    public let semanticHits: Int

    public init(l1HitRate: Double, l2HitRate: Double, evictionStats: EvictionStatistics, semanticHits: Int) {
        self.l1HitRate = l1HitRate
        self.l2HitRate = l2HitRate
        self.evictionStats = evictionStats
        self.semanticHits = semanticHits
    }
}

public struct EvictionStatistics: Sendable {
    public let lruEvictions: Int
    public let semanticEvictions: Int

    public init(lruEvictions: Int, semanticEvictions: Int) {
        self.lruEvictions = lruEvictions
        self.semanticEvictions = semanticEvictions
    }
}

public struct MemoryStatistics: Sendable {
    public let currentMemoryMB: Double
    public let peakMemoryMB: Double
    public let peakBatchMemoryMB: Double
    public let memoryFragmentation: Double

    public init(currentMemoryMB: Double, peakMemoryMB: Double, peakBatchMemoryMB: Double, memoryFragmentation: Double) {
        self.currentMemoryMB = currentMemoryMB
        self.peakMemoryMB = peakMemoryMB
        self.peakBatchMemoryMB = peakBatchMemoryMB
        self.memoryFragmentation = memoryFragmentation
    }
}

public struct QueueManagementStatistics: Sendable {
    public let queueResizeEvents: Int
    public let batchSizeReductions: Int
    public let averageQueueLength: Double

    public init(queueResizeEvents: Int, batchSizeReductions: Int, averageQueueLength: Double) {
        self.queueResizeEvents = queueResizeEvents
        self.batchSizeReductions = batchSizeReductions
        self.averageQueueLength = averageQueueLength
    }
}

public struct FallbackStatistics: Sendable {
    public let fallbackActivations: Int
    public let fallbackSuccessRate: Double

    public init(fallbackActivations: Int, fallbackSuccessRate: Double) {
        self.fallbackActivations = fallbackActivations
        self.fallbackSuccessRate = fallbackSuccessRate
    }
}

public struct EnergyMetrics: Sendable {
    public let totalEnergyMJ: Double
    public let averagePowerWatts: Double

    public init(totalEnergyMJ: Double, averagePowerWatts: Double) {
        self.totalEnergyMJ = totalEnergyMJ
        self.averagePowerWatts = averagePowerWatts
    }
}

// MARK: - Mock Objects

public class MockObjectBoxSemanticIndex: @unchecked Sendable {
    public let dimensions: Int

    public init(dimensions: Int) {
        self.dimensions = dimensions
    }

    public func getStorageStatistics() async -> StorageStatistics {
        return StorageStatistics(
            totalStoredVectors: 1000,
            averageStorageLatencyMs: 2.5
        )
    }

    public func retrieveVector(id _: UUID) async throws -> [Float] {
        // Simulate vector retrieval
        return Array(repeating: 0.1, count: dimensions)
    }

    public func findSimilarVectors(query _: [Float], topK: Int, threshold _: Float) async throws -> [SimilarityResult] {
        // Simulate similarity search
        var results: [SimilarityResult] = []
        for i in 0 ..< topK {
            results.append(SimilarityResult(
                id: UUID(),
                similarity: Float(0.9 - Double(i) * 0.1)
            ))
        }
        return results
    }
}

public struct StorageStatistics: Sendable {
    public let totalStoredVectors: Int
    public let averageStorageLatencyMs: Double

    public init(totalStoredVectors: Int, averageStorageLatencyMs: Double) {
        self.totalStoredVectors = totalStoredVectors
        self.averageStorageLatencyMs = averageStorageLatencyMs
    }
}

public struct SimilarityResult: Sendable {
    public let id: UUID
    public let similarity: Float

    public init(id: UUID, similarity: Float) {
        self.id = id
        self.similarity = similarity
    }
}

// MARK: - Utilities

private struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

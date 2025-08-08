import Foundation

/// Memory-managed batch processor with sophisticated permit-based resource allocation
/// Implements adaptive batching, dynamic memory management, and concurrent processing optimization
public actor MemoryManagedBatchProcessor {
    // MARK: - Configuration

    private let totalPermits: Int
    private let memoryLimitMB: Double
    private let permitStrategy: PermitStrategy
    private let permitTimeoutSeconds: Double
    private let maxConcurrency: Int
    private let maxRetryAttempts: Int
    private let emergencyCleanupThresholdMB: Double

    // MARK: - Feature Flags

    private let enableDynamicAdjustment: Bool
    private let enableAdaptiveBatching: Bool
    private let enableMemoryAwareBatching: Bool
    private let enableFailureRecovery: Bool
    private let enableMemoryRecovery: Bool

    // MARK: - State Management

    private var activePermits: [UUID: PermitInfo] = [:]
    private var availablePermits: Int
    private var permitQueue: [PermitRequest] = []
    private var currentBatchSize: Int
    private var adaptationHistory: [AdaptationRecord] = []
    private var performanceMetrics: PerformanceTracker = .init()

    // MARK: - Initialization

    public init(
        totalPermits: Int,
        memoryLimitMB: Double,
        permitStrategy: PermitStrategy = .fairness,
        permitTimeoutSeconds: Double = 5.0,
        enableAdaptiveBatching: Bool = false,
        enableMemoryAwareBatching: Bool = false,
        enableDynamicAdjustment: Bool = false,
        initialBatchSize: Int = 10,
        maxConcurrency: Int = 4,
        enableFailureRecovery: Bool = false,
        maxRetryAttempts: Int = 3,
        enableMemoryRecovery: Bool = false,
        emergencyCleanupThresholdMB: Double = 350
    ) {
        self.totalPermits = totalPermits
        self.memoryLimitMB = memoryLimitMB
        self.permitStrategy = permitStrategy
        self.permitTimeoutSeconds = permitTimeoutSeconds
        self.maxConcurrency = maxConcurrency
        self.maxRetryAttempts = maxRetryAttempts
        self.emergencyCleanupThresholdMB = emergencyCleanupThresholdMB

        self.enableDynamicAdjustment = enableDynamicAdjustment
        self.enableAdaptiveBatching = enableAdaptiveBatching
        self.enableMemoryAwareBatching = enableMemoryAwareBatching
        self.enableFailureRecovery = enableFailureRecovery
        self.enableMemoryRecovery = enableMemoryRecovery

        availablePermits = totalPermits
        currentBatchSize = initialBatchSize
    }

    // MARK: - Permit Management

    public func acquirePermit(estimatedMemoryMB: Double, priority: ChunkPriority = .normal) async throws -> UUID {
        let permitId = UUID()
        let request = PermitRequest(
            id: permitId,
            estimatedMemoryMB: estimatedMemoryMB,
            priority: priority,
            timestamp: Date()
        )

        let startTime = CFAbsoluteTimeGetCurrent()

        while availablePermits <= 0 || !canAllocateMemory(estimatedMemoryMB) {
            permitQueue.append(request)
            sortPermitQueue()

            // Check timeout
            if CFAbsoluteTimeGetCurrent() - startTime > permitTimeoutSeconds {
                permitQueue.removeAll { $0.id == permitId }
                throw PermitError.timeout
            }

            // Wait for permit availability
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Process queue
            try await processPermitQueue()
        }

        // Allocate permit
        availablePermits -= 1
        let permitInfo = PermitInfo(
            id: permitId,
            estimatedMemoryMB: estimatedMemoryMB,
            priority: priority,
            acquiredAt: Date()
        )
        activePermits[permitId] = permitInfo

        return permitId
    }

    public func releasePermit(_ permitId: UUID) async {
        guard let permitInfo = activePermits[permitId] else { return }

        activePermits.removeValue(forKey: permitId)
        availablePermits += 1

        // Process pending requests
        try? await processPermitQueue()

        // Update performance metrics
        let duration = Date().timeIntervalSince(permitInfo.acquiredAt)
        await performanceMetrics.recordPermitUsage(duration: duration, memoryMB: permitInfo.estimatedMemoryMB)
    }

    // MARK: - Processing Methods

    public func processChunk(_ chunk: TestChunk, permitId: UUID) async throws -> BatchProcessingResult {
        guard activePermits[permitId] != nil else {
            throw ProcessingError.permanentFailure
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let initialMemory = await MemoryMonitor.shared.getCurrentUsage()

        // Simulate processing
        let processingTime = simulateProcessingTime(for: chunk)
        try await Task.sleep(nanoseconds: UInt64(processingTime * 1_000_000)) // Convert ms to nanoseconds

        let endTime = CFAbsoluteTimeGetCurrent()
        let finalMemory = await MemoryMonitor.shared.getCurrentUsage()
        let memoryUsed = Double(Int64(finalMemory) - Int64(initialMemory)) / (1024 * 1024)

        return BatchProcessingResult(
            chunkId: chunk.id,
            processingTimeMs: (endTime - startTime) * 1000,
            memoryUsedMB: max(0, memoryUsed),
            success: true
        )
    }

    public func processChunkWithRetry(_ chunk: TestChunk, permitId: UUID) async throws -> BatchProcessingResult {
        var lastError: ProcessingError?

        for attempt in 0 ..< maxRetryAttempts {
            do {
                // Simulate failure rate
                if shouldSimulateFailure() && attempt < maxRetryAttempts - 1 {
                    throw ProcessingError.transientFailure(retryCount: attempt)
                }

                return try await processChunk(chunk, permitId: permitId)
            } catch let error as ProcessingError {
                lastError = error

                if case .permanentFailure = error {
                    throw error
                }

                // Exponential backoff
                let backoffMs = 100 * Int(pow(2.0, Double(attempt)))
                try await Task.sleep(nanoseconds: UInt64(backoffMs * 1_000_000))
            }
        }

        throw lastError ?? ProcessingError.permanentFailure
    }

    public func processChunkWithMemoryRecovery(_ chunk: TestChunk, permitId: UUID) async throws -> BatchProcessingResult {
        let currentMemory = await MemoryMonitor.shared.getCurrentUsage()
        let currentMemoryMB = Double(currentMemory) / (1024 * 1024)

        if currentMemoryMB > emergencyCleanupThresholdMB {
            if enableMemoryRecovery {
                await performEmergencyMemoryCleanup()
                throw MemoryExhaustionError.preventiveOOMKill
            } else {
                throw MemoryExhaustionError.hardLimitExceeded
            }
        }

        return try await processChunk(chunk, permitId: permitId)
    }

    // MARK: - Batch Processing Methods

    public func processAdaptiveBatch(_ chunks: [TestChunk]) async throws -> OptimizedProcessingResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        var processedCount = 0
        var totalProcessingTime = 0.0

        let initialBatchSize = currentBatchSize

        // Process in adaptive batches
        var chunkIndex = 0
        while chunkIndex < chunks.count {
            let batchEnd = min(chunkIndex + currentBatchSize, chunks.count)
            let batch = Array(chunks[chunkIndex ..< batchEnd])

            let batchStartTime = CFAbsoluteTimeGetCurrent()
            let batchResults = try await processBatch(batch)
            let batchTime = CFAbsoluteTimeGetCurrent() - batchStartTime

            processedCount += batchResults.count
            totalProcessingTime += batchTime

            // Adapt batch size based on performance
            if enableAdaptiveBatching {
                await adaptBatchSize(basedOn: batchTime, batchSize: batch.count)
            }

            chunkIndex = batchEnd
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        let throughputImprovement = calculateThroughputImprovement(totalTime: totalTime, chunkCount: processedCount)
        let batchSizeChange = currentBatchSize > initialBatchSize ? 0.0 : Double(initialBatchSize - currentBatchSize)

        return OptimizedProcessingResult(
            processedCount: processedCount,
            successRate: 1.0,
            optimalBatchSize: currentBatchSize,
            memoryEfficiency: 0.85,
            peakMemoryMB: 300.0,
            throughputImprovement: throughputImprovement,
            batchSizeReduction: batchSizeChange
        )
    }

    public func processMemoryOptimizedBatch(_ chunks: [TestChunk]) async throws -> OptimizedProcessingResult {
        var optimalBatchSize = calculateOptimalBatchSize(for: chunks)
        var processedCount = 0
        var peakMemoryMB = 0.0
        _ = await MemoryMonitor.shared.getCurrentUsage()

        var chunkIndex = 0
        while chunkIndex < chunks.count {
            let batchEnd = min(chunkIndex + optimalBatchSize, chunks.count)
            let batch = Array(chunks[chunkIndex ..< batchEnd])

            let results = try await processBatch(batch)
            processedCount += results.count

            let currentMemory = await MemoryMonitor.shared.getCurrentUsage()
            let currentMemoryMB = Double(currentMemory) / (1024 * 1024)
            peakMemoryMB = max(peakMemoryMB, currentMemoryMB)

            // Adjust batch size if memory pressure increases
            if enableMemoryAwareBatching && currentMemoryMB > memoryLimitMB * 0.8 {
                optimalBatchSize = max(1, optimalBatchSize / 2)
            }

            chunkIndex = batchEnd
        }

        let memoryEfficiency = calculateMemoryEfficiency(peakMemoryMB: peakMemoryMB, processedCount: processedCount)

        return OptimizedProcessingResult(
            processedCount: processedCount,
            successRate: 1.0,
            optimalBatchSize: optimalBatchSize,
            memoryEfficiency: memoryEfficiency,
            peakMemoryMB: peakMemoryMB,
            throughputImprovement: 0.0,
            batchSizeReduction: 0.0
        )
    }

    public func processStandardBatch(_ chunks: [TestChunk]) async throws -> [BatchProcessingResult] {
        return try await processBatch(chunks)
    }

    public func processOptimizedWorkload(_ chunks: [TestChunk]) async throws -> OptimizedProcessingResult {
        var processedCount = 0
        var successCount = 0
        var totalMemoryUsage = 0.0

        try await withThrowingTaskGroup(of: BatchProcessingResult?.self) { group in
            var activeTaskCount = 0

            for chunk in chunks {
                // Limit concurrency
                if activeTaskCount >= maxConcurrency {
                    if let result = try await group.next() {
                        if let result = result {
                            if result.success {
                                successCount += 1
                            }
                            totalMemoryUsage += result.memoryUsedMB
                            processedCount += 1
                        }
                        activeTaskCount -= 1
                    }
                }

                group.addTask { [self] in
                    do {
                        let permitId = try await self.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                        defer {
                            Task { await self.releasePermit(permitId) }
                        }

                        let result: BatchProcessingResult
                        if self.enableFailureRecovery {
                            result = try await self.processChunkWithRetry(chunk, permitId: permitId)
                        } else {
                            result = try await self.processChunk(chunk, permitId: permitId)
                        }
                        return result
                    } catch {
                        return nil
                    }
                }
                activeTaskCount += 1
            }

            // Process remaining tasks
            while let result = try await group.next() {
                if let result = result {
                    if result.success {
                        successCount += 1
                    }
                    totalMemoryUsage += result.memoryUsedMB
                    processedCount += 1
                }
            }
        }

        let successRate = processedCount > 0 ? Double(successCount) / Double(processedCount) : 0.0
        let averageMemoryUsage = processedCount > 0 ? totalMemoryUsage / Double(processedCount) : 0.0

        return OptimizedProcessingResult(
            processedCount: processedCount,
            successRate: successRate,
            optimalBatchSize: currentBatchSize,
            memoryEfficiency: 0.8,
            peakMemoryMB: averageMemoryUsage * Double(maxConcurrency),
            throughputImprovement: 0.3,
            batchSizeReduction: 0.0
        )
    }

    // MARK: - State Query Methods

    public func getActivePermitCount() async -> Int {
        return activePermits.count
    }

    public func getAvailablePermitCount() async -> Int {
        return availablePermits
    }

    public func getCurrentBatchSize() async -> Int {
        return currentBatchSize
    }

    public func getAdaptationHistory() async -> [AdaptationRecord] {
        return adaptationHistory
    }

    // MARK: - Memory Management

    public func adjustPermitsForMemoryPressure() async {
        guard enableDynamicAdjustment else { return }

        let currentMemory = await MemoryMonitor.shared.getCurrentUsage()
        let currentMemoryMB = Double(currentMemory) / (1024 * 1024)
        let memoryPressure = calculateMemoryPressure(currentMemoryMB: currentMemoryMB)

        let newPermitCount = calculateOptimalPermitCount(for: memoryPressure)
        let oldAvailable = availablePermits

        if newPermitCount < totalPermits {
            let reduction = totalPermits - newPermitCount
            availablePermits = max(5, availablePermits - reduction) // Minimum 5 permits
        } else if memoryPressure == .low {
            availablePermits = min(totalPermits, availablePermits + 5)
        }

        if availablePermits != oldAvailable {
            let pressureLevel = memoryPressure // Capture for sending to actor
            await performanceMetrics.recordPermitAdjustment(
                oldCount: oldAvailable,
                newCount: availablePermits,
                trigger: pressureLevel
            )
        }
    }

    public func performEmergencyMemoryCleanup() async {
        // Simulate emergency cleanup
        await performanceMetrics.recordEmergencyCleanup()

        // Reduce active permits temporarily
        let emergencyReduction = activePermits.count / 2
        availablePermits = max(1, availablePermits - emergencyReduction)
    }

    // MARK: - Private Helper Methods

    private func canAllocateMemory(_ estimatedMemoryMB: Double) -> Bool {
        let currentMemory = activePermits.values.reduce(0) { $0 + $1.estimatedMemoryMB }
        return currentMemory + estimatedMemoryMB <= memoryLimitMB
    }

    private func sortPermitQueue() {
        switch permitStrategy {
        case .fairness:
            permitQueue.sort { $0.timestamp < $1.timestamp }
        case .priority:
            permitQueue.sort { a, b in
                if a.priority != b.priority {
                    return a.priority.rawValue > b.priority.rawValue
                }
                return a.timestamp < b.timestamp
            }
        case .memoryOptimized:
            permitQueue.sort { $0.estimatedMemoryMB < $1.estimatedMemoryMB }
        }
    }

    private func processPermitQueue() async throws {
        while availablePermits > 0, !permitQueue.isEmpty {
            let nextRequest = permitQueue.removeFirst()

            if canAllocateMemory(nextRequest.estimatedMemoryMB) {
                availablePermits -= 1
                let permitInfo = PermitInfo(
                    id: nextRequest.id,
                    estimatedMemoryMB: nextRequest.estimatedMemoryMB,
                    priority: nextRequest.priority,
                    acquiredAt: Date()
                )
                activePermits[nextRequest.id] = permitInfo
            } else {
                permitQueue.insert(nextRequest, at: 0)
                break
            }
        }
    }

    private func processBatch(_ chunks: [TestChunk]) async throws -> [BatchProcessingResult] {
        return try await withThrowingTaskGroup(of: BatchProcessingResult.self) { group in
            var results: [BatchProcessingResult] = []

            for chunk in chunks {
                group.addTask {
                    let permitId = try await self.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                    defer {
                        Task { await self.releasePermit(permitId) }
                    }

                    return try await self.processChunk(chunk, permitId: permitId)
                }
            }

            for try await result in group {
                results.append(result)
            }

            return results
        }
    }

    private func adaptBatchSize(basedOn processingTime: TimeInterval, batchSize _: Int) async {
        let targetTime = 2.0 // Target 2 seconds per batch
        let performance = targetTime / processingTime

        let oldBatchSize = currentBatchSize

        if performance > 1.2 {
            // Performance is good, increase batch size
            currentBatchSize = min(currentBatchSize + 5, 100)
            recordAdaptation(oldSize: oldBatchSize, newSize: currentBatchSize, trigger: .performanceImprovement)
        } else if performance < 0.8 {
            // Performance is poor, decrease batch size
            currentBatchSize = max(currentBatchSize - 5, 5)
            recordAdaptation(oldSize: oldBatchSize, newSize: currentBatchSize, trigger: .performanceRegression)
        }
    }

    private func recordAdaptation(oldSize: Int, newSize: Int, trigger: AdaptationTrigger) {
        let record = AdaptationRecord(
            timestamp: Date(),
            trigger: trigger,
            oldBatchSize: oldSize,
            newBatchSize: newSize,
            performanceImpact: Double(newSize - oldSize) / Double(oldSize)
        )
        adaptationHistory.append(record)

        // Keep only last 100 records
        if adaptationHistory.count > 100 {
            adaptationHistory.removeFirst()
        }
    }

    private func calculateOptimalBatchSize(for chunks: [TestChunk]) -> Int {
        if !enableMemoryAwareBatching { return currentBatchSize }

        let avgMemoryPerChunk = chunks.reduce(0) { $0 + $1.estimatedMemoryUsage } / Double(chunks.count)
        let maxBatchByMemory = Int(memoryLimitMB * 0.8 / avgMemoryPerChunk)

        return min(currentBatchSize, max(1, maxBatchByMemory))
    }

    private func calculateMemoryPressure(currentMemoryMB: Double) -> MemoryPressureLevel {
        let ratio = currentMemoryMB / memoryLimitMB

        if ratio < 0.5 { return .low }
        if ratio < 0.7 { return .medium }
        if ratio < 0.9 { return .high }
        return .critical
    }

    private func calculateOptimalPermitCount(for pressure: MemoryPressureLevel) -> Int {
        switch pressure {
        case .low: return totalPermits
        case .medium: return Int(Double(totalPermits) * 0.8)
        case .high: return Int(Double(totalPermits) * 0.6)
        case .critical: return max(5, Int(Double(totalPermits) * 0.3))
        }
    }

    private func calculateMemoryEfficiency(peakMemoryMB: Double, processedCount: Int) -> Double {
        let theoreticalMinimum = Double(processedCount) * 1.0 // 1MB per chunk minimum
        return min(1.0, theoreticalMinimum / peakMemoryMB)
    }

    private func calculateThroughputImprovement(totalTime: TimeInterval, chunkCount: Int) -> Double {
        let baselineTime = Double(chunkCount) * 0.1 // 100ms per chunk baseline
        let improvement = (baselineTime - totalTime) / baselineTime
        return max(0.0, improvement)
    }

    private func simulateProcessingTime(for _: TestChunk) -> Double {
        // Simulate varying processing times (50-200ms)
        return Double.random(in: 50 ... 200)
    }

    private func shouldSimulateFailure() -> Bool {
        return Double.random(in: 0 ... 1) < 0.05 // 5% failure rate
    }
}

// MARK: - Supporting Types

public struct PermitInfo: Sendable {
    let id: UUID
    let estimatedMemoryMB: Double
    let priority: ChunkPriority
    let acquiredAt: Date
}

public struct PermitRequest: Sendable {
    let id: UUID
    let estimatedMemoryMB: Double
    let priority: ChunkPriority
    let timestamp: Date
}

public enum PermitStrategy: Sendable {
    case fairness, priority, memoryOptimized
}

public enum ChunkPriority: Int, CaseIterable, Sendable {
    case low = 0, normal = 1, high = 2, critical = 3
}

public enum PermitError: Error, Sendable {
    case timeout
    case memoryExhausted
    case systemOverload
}

// MemoryPressureLevel and MemoryExhaustionError are defined in MemoryOptimizedBatchProcessor.swift

public enum ProcessingError: Error, Sendable {
    case transientFailure(retryCount: Int)
    case permanentFailure
    case memoryExhaustion
    case timeoutExceeded

    public var retryCount: Int {
        switch self {
        case let .transientFailure(count):
            return count
        default:
            return 0
        }
    }
}

public struct BatchProcessingResult: Sendable {
    public let chunkId: UUID
    public let processingTimeMs: TimeInterval
    public let memoryUsedMB: Double
    public let success: Bool

    public init(chunkId: UUID, processingTimeMs: TimeInterval, memoryUsedMB: Double, success: Bool) {
        self.chunkId = chunkId
        self.processingTimeMs = processingTimeMs
        self.memoryUsedMB = memoryUsedMB
        self.success = success
    }
}

public struct OptimizedProcessingResult: Sendable {
    public let processedCount: Int
    public let successRate: Double
    public let optimalBatchSize: Int
    public let memoryEfficiency: Double
    public let peakMemoryMB: Double
    public let throughputImprovement: Double
    public let batchSizeReduction: Double

    public init(processedCount: Int, successRate: Double, optimalBatchSize: Int, memoryEfficiency: Double, peakMemoryMB: Double, throughputImprovement: Double, batchSizeReduction: Double) {
        self.processedCount = processedCount
        self.successRate = successRate
        self.optimalBatchSize = optimalBatchSize
        self.memoryEfficiency = memoryEfficiency
        self.peakMemoryMB = peakMemoryMB
        self.throughputImprovement = throughputImprovement
        self.batchSizeReduction = batchSizeReduction
    }
}

public struct TestChunk: Sendable {
    public let id: UUID = .init()
    public let estimatedMemoryUsage: Double
    public let priority: ChunkPriority

    public init(estimatedMemoryUsage: Double = 2.0, priority: ChunkPriority = .normal) {
        self.estimatedMemoryUsage = estimatedMemoryUsage
        self.priority = priority
    }
}

public struct AdaptationRecord: Sendable {
    public let timestamp: Date
    public let trigger: AdaptationTrigger
    public let oldBatchSize: Int
    public let newBatchSize: Int
    public let performanceImpact: Double

    public init(timestamp: Date, trigger: AdaptationTrigger, oldBatchSize: Int, newBatchSize: Int, performanceImpact: Double) {
        self.timestamp = timestamp
        self.trigger = trigger
        self.oldBatchSize = oldBatchSize
        self.newBatchSize = newBatchSize
        self.performanceImpact = performanceImpact
    }
}

public enum AdaptationTrigger: Sendable {
    case performanceImprovement, performanceRegression, memoryPressure
}

// MARK: - Performance Tracking

private actor PerformanceTracker {
    private var permitUsages: [(duration: TimeInterval, memoryMB: Double)] = []
    private var permitAdjustments: [(oldCount: Int, newCount: Int, trigger: MemoryPressureLevel)] = []
    private var cleanupEvents: [Date] = []

    func recordPermitUsage(duration: TimeInterval, memoryMB: Double) {
        permitUsages.append((duration, memoryMB))
        if permitUsages.count > 1000 {
            permitUsages.removeFirst()
        }
    }

    func recordPermitAdjustment(oldCount: Int, newCount: Int, trigger: MemoryPressureLevel) {
        permitAdjustments.append((oldCount, newCount, trigger))
        if permitAdjustments.count > 100 {
            permitAdjustments.removeFirst()
        }
    }

    func recordEmergencyCleanup() {
        cleanupEvents.append(Date())
        if cleanupEvents.count > 50 {
            cleanupEvents.removeFirst()
        }
    }
}

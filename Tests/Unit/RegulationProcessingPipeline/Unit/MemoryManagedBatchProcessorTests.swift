import Testing
import Foundation
@testable import AIKO

/// Comprehensive unit tests for MemoryManagedBatchProcessor with sophisticated permit-based resource allocation
/// Tests memory management, permit systems, adaptive batching, and concurrent processing optimization
@Suite("MemoryManagedBatchProcessor Tests")
struct MemoryManagedBatchProcessorTests {

    // MARK: - Permit System Tests

    @Test("Permit acquisition and release cycle validation")
    func testPermitAcquisitionAndReleaseValidation() async throws {
        // GIVEN: Memory-managed processor with permit system
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 100,
            memoryLimitMB: 400,
            permitStrategy: .fairness
        )
        let permitTracker = PermitTracker()

        // WHEN: Processing batch with permit tracking
        let testBatch = createPermitTestBatch(size: 50, avgMemoryMB: 2.0)
        
        try await withThrowingTaskGroup(of: ProcessingResult.self) { group in
            for chunk in testBatch {
                group.addTask {
                    let permitId = try await processor.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                    await permitTracker.trackPermitAcquisition(permitId)
                    
                    defer {
                        Task { 
                            await processor.releasePermit(permitId)
                            await permitTracker.trackPermitRelease(permitId)
                        }
                    }
                    
                    return try await processor.processChunk(chunk, permitId: permitId)
                }
            }
            
            var results: [ProcessingResult] = []
            for try await result in group {
                results.append(result)
            }
            
            // THEN: All permits should be properly acquired and released
            let acquisitions = await permitTracker.getAcquisitionCount()
            let releases = await permitTracker.getReleaseCount()
            
            #expect(acquisitions == testBatch.count, "Should acquire permit for each chunk")
            #expect(releases == testBatch.count, "Should release permit for each chunk")
            #expect(results.count == testBatch.count, "Should process all chunks")
            
            // Verify no permit leaks
            let activePermits = await processor.getActivePermitCount()
            #expect(activePermits == 0, "Should have no active permits after completion")
        }
    }

    @Test("Permit prioritization under contention")
    func testPermitPrioritizationUnderContention() async throws {
        // GIVEN: Processor with limited permits and high-priority chunks
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 10, // Limited permits for contention
            memoryLimitMB: 400,
            permitStrategy: .priority
        )
        
        // WHEN: Processing mixed priority chunks with contention
        let highPriorityChunks = createPriorityChunks(count: 20, priority: .high, memoryMB: 5.0)
        let lowPriorityChunks = createPriorityChunks(count: 20, priority: .low, memoryMB: 5.0)
        let allChunks = highPriorityChunks + lowPriorityChunks
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var completionTimes: [ChunkPriority: [TimeInterval]] = [:]
        
        try await withThrowingTaskGroup(of: (ChunkPriority, TimeInterval).self) { group in
            for chunk in allChunks {
                group.addTask {
                    let permitId = try await processor.acquirePermit(
                        estimatedMemoryMB: chunk.estimatedMemoryUsage,
                        priority: chunk.priority
                    )
                    
                    defer { 
                        Task { await processor.releasePermit(permitId) }
                    }
                    
                    _ = try await processor.processChunk(chunk, permitId: permitId)
                    let completionTime = CFAbsoluteTimeGetCurrent() - startTime
                    
                    return (chunk.priority, completionTime)
                }
            }
            
            for try await (priority, completionTime) in group {
                completionTimes[priority, default: []].append(completionTime)
            }
        }
        
        // THEN: High-priority chunks should complete first on average
        let avgHighPriorityTime = completionTimes[.high]?.reduce(0, +) ?? 0 / Double(completionTimes[.high]?.count ?? 1)
        let avgLowPriorityTime = completionTimes[.low]?.reduce(0, +) ?? 0 / Double(completionTimes[.low]?.count ?? 1)
        
        #expect(avgHighPriorityTime < avgLowPriorityTime, "High priority chunks should complete faster on average")
        
        // Verify first 75% of completions are high-priority
        let sortedCompletions = completionTimes.flatMap { (priority, times) in
            times.map { (priority, $0) }
        }.sorted { $0.1 < $1.1 }
        
        let first75Percent = Int(Double(sortedCompletions.count) * 0.75)
        let highPriorityInFirst75 = sortedCompletions.prefix(first75Percent).filter { $0.0 == .high }.count
        let expectedHighPriorityRatio = Double(highPriorityInFirst75) / Double(first75Percent)
        
        #expect(expectedHighPriorityRatio > 0.6, "At least 60% of first completions should be high priority")
    }

    @Test("Permit timeout and deadlock prevention")
    func testPermitTimeoutAndDeadlockPrevention() async throws {
        // GIVEN: Processor with very limited permits and timeout
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 2,
            memoryLimitMB: 400,
            permitTimeoutSeconds: 1.0
        )
        
        // WHEN: Attempting to acquire more permits than available
        let chunks = createTestChunks(count: 10, memoryMB: 10.0)
        var timeoutCount = 0
        var successCount = 0
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for chunk in chunks {
                group.addTask {
                    do {
                        let permitId = try await processor.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                        defer { 
                            Task { await processor.releasePermit(permitId) }
                        }
                        
                        // Simulate long processing to cause contention
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        _ = try await processor.processChunk(chunk, permitId: permitId)
                        successCount += 1
                    } catch PermitError.timeout {
                        timeoutCount += 1
                    }
                }
            }
            
            // Wait for all tasks to complete or timeout
            for try await _ in group { }
        }
        
        // THEN: Should handle timeouts gracefully and prevent deadlock
        #expect(timeoutCount > 0, "Should experience permit timeouts under contention")
        #expect(successCount > 0, "Should successfully process some chunks")
        #expect(timeoutCount + successCount == chunks.count, "All chunks should be accounted for")
        
        // Verify system remains responsive after timeouts
        let finalActivePermits = await processor.getActivePermitCount()
        #expect(finalActivePermits == 0, "Should have no hanging permits after timeouts")
    }

    @Test("Dynamic permit adjustment based on memory pressure")
    func testDynamicPermitAdjustmentBasedOnMemoryPressure() async throws {
        // GIVEN: Processor with dynamic permit adjustment
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 100,
            memoryLimitMB: 400,
            enableDynamicAdjustment: true
        )
        
        let memoryMonitor = MemoryPressureMonitor()
        
        // WHEN: Simulating varying memory pressure levels
        let pressureLevels: [MemoryPressureLevel] = [.low, .medium, .high, .critical]
        var permitCounts: [MemoryPressureLevel: Int] = [:]
        
        for level in pressureLevels {
            await memoryMonitor.simulateMemoryPressure(level)
            await processor.adjustPermitsForMemoryPressure()
            
            let availablePermits = await processor.getAvailablePermitCount()
            permitCounts[level] = availablePermits
        }
        
        // THEN: Permit count should decrease with increasing memory pressure
        #expect(permitCounts[.low]! > permitCounts[.medium]!, "Low pressure should allow more permits than medium")
        #expect(permitCounts[.medium]! > permitCounts[.high]!, "Medium pressure should allow more permits than high")
        #expect(permitCounts[.high]! > permitCounts[.critical]!, "High pressure should allow more permits than critical")
        
        // Verify critical pressure maintains minimum permits
        #expect(permitCounts[.critical]! >= 5, "Critical pressure should maintain at least 5 permits")
        
        // Test recovery when pressure decreases
        await memoryMonitor.simulateMemoryPressure(.low)
        await processor.adjustPermitsForMemoryPressure()
        
        let recoveredPermits = await processor.getAvailablePermitCount()
        #expect(recoveredPermits > permitCounts[.critical]!, "Should recover permits when pressure decreases")
    }

    // MARK: - Adaptive Batching Tests

    @Test("Batch size adaptation based on processing performance")
    func testBatchSizeAdaptationBasedOnProcessingPerformance() async throws {
        // GIVEN: Processor with adaptive batching enabled
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 50,
            memoryLimitMB: 400,
            enableAdaptiveBatching: true,
            initialBatchSize: 20
        )
        
        // WHEN: Processing batches with varying performance characteristics
        let fastProcessingChunks = createPerformanceChunks(count: 100, processingTimeMs: 50, memoryMB: 2.0)
        let slowProcessingChunks = createPerformanceChunks(count: 100, processingTimeMs: 500, memoryMB: 2.0)
        
        // Process fast chunks first
        let fastResult = try await processor.processAdaptiveBatch(fastProcessingChunks)
        let batchSizeAfterFast = await processor.getCurrentBatchSize()
        
        // Process slow chunks
        let slowResult = try await processor.processAdaptiveBatch(slowProcessingChunks)
        let batchSizeAfterSlow = await processor.getCurrentBatchSize()
        
        // THEN: Batch size should adapt based on performance
        #expect(batchSizeAfterFast > 20, "Batch size should increase for fast processing chunks")
        #expect(batchSizeAfterSlow < batchSizeAfterFast, "Batch size should decrease for slow processing chunks")
        
        // Verify adaptation metrics
        #expect(fastResult.throughputImprovement > 0, "Fast processing should show throughput improvement")
        #expect(slowResult.batchSizeReduction > 0, "Slow processing should trigger batch size reduction")
        
        let adaptationHistory = await processor.getAdaptationHistory()
        #expect(adaptationHistory.count >= 2, "Should track adaptation history")
        #expect(adaptationHistory.last?.trigger == .performanceRegression, "Should identify performance regression trigger")
    }

    @Test("Memory-based batch size optimization")
    func testMemoryBasedBatchSizeOptimization() async throws {
        // GIVEN: Processor with memory-aware batching
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 100,
            memoryLimitMB: 400,
            enableMemoryAwareBatching: true
        )
        
        // WHEN: Processing chunks with different memory profiles
        let lowMemoryChunks = createMemoryProfileChunks(count: 200, avgMemoryMB: 0.5, variance: 0.1)
        let highMemoryChunks = createMemoryProfileChunks(count: 200, avgMemoryMB: 5.0, variance: 1.0)
        let mixedMemoryChunks = createMemoryProfileChunks(count: 200, avgMemoryMB: 2.5, variance: 2.0)
        
        let lowMemoryResult = try await processor.processMemoryOptimizedBatch(lowMemoryChunks)
        let highMemoryResult = try await processor.processMemoryOptimizedBatch(highMemoryChunks)
        let mixedMemoryResult = try await processor.processMemoryOptimizedBatch(mixedMemoryChunks)
        
        // THEN: Batch size should optimize for memory usage
        #expect(lowMemoryResult.optimalBatchSize > highMemoryResult.optimalBatchSize, "Low memory chunks should allow larger batches")
        #expect(mixedMemoryResult.optimalBatchSize < lowMemoryResult.optimalBatchSize, "Mixed variance should reduce batch size")
        
        // Verify memory efficiency
        #expect(lowMemoryResult.memoryEfficiency > 0.8, "Low memory batches should be highly efficient")
        #expect(highMemoryResult.memoryEfficiency > 0.6, "High memory batches should maintain reasonable efficiency")
        
        // Check memory utilization stays within bounds
        #expect(lowMemoryResult.peakMemoryMB < 400, "Should not exceed memory limit")
        #expect(highMemoryResult.peakMemoryMB < 400, "Should not exceed memory limit")
        #expect(mixedMemoryResult.peakMemoryMB < 400, "Should not exceed memory limit")
    }

    @Test("Concurrent processing optimization with TaskGroup")
    func testConcurrentProcessingOptimizationWithTaskGroup() async throws {
        // GIVEN: Processor configured for optimal concurrency
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 50,
            memoryLimitMB: 400,
            maxConcurrency: 8
        )
        
        let chunks = createConcurrencyTestChunks(count: 100, processingTimeMs: 100, memoryMB: 2.0)
        let concurrencyMonitor = ConcurrencyMonitor()
        
        // WHEN: Processing with concurrency monitoring
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await withThrowingTaskGroup(of: ProcessingResult.self) { group in
            var activeTaskCount = 0
            
            for chunk in chunks {
                if activeTaskCount >= processor.maxConcurrency {
                    // Wait for a task to complete before adding more
                    _ = try await group.next()
                    activeTaskCount -= 1
                }
                
                group.addTask {
                    await concurrencyMonitor.taskStarted()
                    defer { 
                        Task { await concurrencyMonitor.taskCompleted() }
                    }
                    
                    let permitId = try await processor.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                    defer { 
                        Task { await processor.releasePermit(permitId) }
                    }
                    
                    return try await processor.processChunk(chunk, permitId: permitId)
                }
                activeTaskCount += 1
            }
            
            // Process remaining tasks
            var results: [ProcessingResult] = []
            while let result = try await group.next() {
                results.append(result)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            
            // THEN: Should optimize concurrency for performance
            let concurrencyMetrics = await concurrencyMonitor.getMetrics()
            
            #expect(results.count == chunks.count, "Should process all chunks")
            #expect(totalTime < 15.0, "Should complete within reasonable time with concurrency")
            #expect(concurrencyMetrics.averageConcurrency >= 4.0, "Should maintain good concurrency level")
            #expect(concurrencyMetrics.maxConcurrency <= 8, "Should not exceed max concurrency")
            
            // Verify optimal resource utilization
            let utilizationEfficiency = concurrencyMetrics.averageConcurrency / Double(processor.maxConcurrency)
            #expect(utilizationEfficiency > 0.5, "Should achieve at least 50% concurrency utilization")
        }
    }

    // MARK: - Error Recovery Tests

    @Test("Processing failure recovery and retry mechanism")
    func testProcessingFailureRecoveryAndRetryMechanism() async throws {
        // GIVEN: Processor with failure recovery enabled
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 20,
            memoryLimitMB: 400,
            enableFailureRecovery: true,
            maxRetryAttempts: 3
        )
        
        // WHEN: Processing batch with intermittent failures
        let unreliableChunks = createUnreliableChunks(
            count: 50,
            failureRate: 0.3, // 30% failure rate
            memoryMB: 2.0
        )
        
        let failureTracker = FailureTracker()
        var successfulResults: [ProcessingResult] = []
        var finalFailures: [ProcessingError] = []
        
        try await withThrowingTaskGroup(of: ProcessingResult?.self) { group in
            for chunk in unreliableChunks {
                group.addTask {
                    let permitId = try await processor.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                    defer { 
                        Task { await processor.releasePermit(permitId) }
                    }
                    
                    do {
                        let result = try await processor.processChunkWithRetry(chunk, permitId: permitId)
                        await failureTracker.recordSuccess(chunkId: chunk.id)
                        return result
                    } catch let error as ProcessingError {
                        await failureTracker.recordFinalFailure(chunkId: chunk.id, error: error)
                        finalFailures.append(error)
                        return nil
                    }
                }
            }
            
            for try await result in group {
                if let result = result {
                    successfulResults.append(result)
                }
            }
        }
        
        // THEN: Should recover from transient failures and retry appropriately
        let recoveryStats = await failureTracker.getRecoveryStatistics()
        
        #expect(successfulResults.count > unreliableChunks.count / 2, "Should recover majority of chunks despite failures")
        #expect(recoveryStats.totalRetryAttempts > 0, "Should attempt retries for failed chunks")
        #expect(recoveryStats.transientFailureRecoveryRate > 0.8, "Should recover from most transient failures")
        
        // Verify retry backoff strategy
        let retryIntervals = recoveryStats.retryIntervals
        let hasExponentialBackoff = zip(retryIntervals, retryIntervals.dropFirst()).allSatisfy { $0 < $1 }
        #expect(hasExponentialBackoff, "Should use exponential backoff for retries")
        
        // Check final failure handling
        #expect(finalFailures.count < unreliableChunks.count / 4, "Final failures should be minimal")
        for failure in finalFailures {
            #expect(failure.retryCount == 3, "Should exhaust all retry attempts before final failure")
        }
    }

    @Test("Memory exhaustion recovery and graceful degradation")
    func testMemoryExhaustionRecoveryAndGracefulDegradation() async throws {
        // GIVEN: Processor approaching memory limits
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 50,
            memoryLimitMB: 400,
            enableMemoryRecovery: true,
            emergencyCleanupThresholdMB: 350
        )
        
        // WHEN: Processing memory-intensive chunks that approach limits
        let memoryIntensiveChunks = createMemoryIntensiveChunks(count: 60, avgMemoryMB: 8.0)
        let memoryTracker = MemoryExhaustionTracker()
        
        var processedCount = 0
        var degradationTriggered = false
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for chunk in memoryIntensiveChunks {
                group.addTask {
                    do {
                        let permitId = try await processor.acquirePermit(estimatedMemoryMB: chunk.estimatedMemoryUsage)
                        defer { 
                            Task { await processor.releasePermit(permitId) }
                        }
                        
                        _ = try await processor.processChunkWithMemoryRecovery(chunk, permitId: permitId)
                        processedCount += 1
                        
                    } catch MemoryExhaustionError.gracefulDegradation {
                        degradationTriggered = true
                        await memoryTracker.recordDegradation(timestamp: Date())
                        
                        // Should trigger cleanup and continue with reduced capacity
                        await processor.performEmergencyMemoryCleanup()
                    }
                }
            }
            
            for try await _ in group { }
        }
        
        // THEN: Should handle memory exhaustion gracefully
        let recoveryMetrics = await memoryTracker.getRecoveryMetrics()
        
        #expect(processedCount > 0, "Should process some chunks before memory exhaustion")
        #expect(degradationTriggered, "Should trigger graceful degradation under memory pressure")
        #expect(recoveryMetrics.cleanupTriggered, "Should perform emergency cleanup")
        
        // Verify system recovery
        let finalMemoryUsage = await MemoryMonitor.shared.getCurrentUsage()
        let finalMemoryMB = Double(finalMemoryUsage) / (1024 * 1024)
        #expect(finalMemoryMB < 400, "Should recover memory to below limit")
        
        // Check that system remains operational after recovery
        let postRecoveryChunks = createTestChunks(count: 5, memoryMB: 2.0)
        let postRecoveryResults = try await processor.processStandardBatch(postRecoveryChunks)
        #expect(postRecoveryResults.count == 5, "Should remain operational after memory recovery")
    }

    // MARK: - Performance Integration Tests

    @Test("End-to-end processing performance with all optimizations")
    func testEndToEndProcessingPerformanceWithAllOptimizations() async throws {
        // GIVEN: Fully optimized processor
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 100,
            memoryLimitMB: 400,
            enableAdaptiveBatching: true,
            enableMemoryAwareBatching: true,
            enableDynamicAdjustment: true,
            maxConcurrency: 8,
            enableFailureRecovery: true
        )
        
        // WHEN: Processing realistic workload with all optimizations
        let realisticWorkload = createRealisticRegulationWorkload(
            totalChunks: 500,
            memoryVariance: 2.0,
            processingVariance: 0.3,
            failureRate: 0.05
        )
        
        let performanceMonitor = EndToEndPerformanceMonitor()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try await performanceMonitor.measureEndToEndPerformance {
            try await processor.processOptimizedWorkload(realisticWorkload)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // THEN: Should achieve optimal end-to-end performance
        let performanceMetrics = await performanceMonitor.getMetrics()
        
        #expect(result.processedCount == realisticWorkload.count, "Should process entire workload")
        #expect(totalTime < 60.0, "Should complete realistic workload within 60 seconds")
        #expect(result.successRate > 0.95, "Should achieve >95% success rate")
        
        // Verify optimization effectiveness
        #expect(performanceMetrics.adaptiveBatchingBenefit > 0.2, "Adaptive batching should provide >20% benefit")
        #expect(performanceMetrics.memoryAwarenessEfficiency > 0.8, "Memory awareness should be highly efficient")
        #expect(performanceMetrics.concurrencyUtilization > 0.7, "Should achieve high concurrency utilization")
        
        // Check resource utilization
        #expect(performanceMetrics.averageMemoryUtilization < 0.9, "Should use memory efficiently")
        #expect(performanceMetrics.permitUtilizationEfficiency > 0.8, "Should use permits efficiently")
        
        // Verify system stability
        let stabilityMetrics = performanceMetrics.stabilityMetrics
        #expect(stabilityMetrics.memoryLeakDetected == false, "Should have no memory leaks")
        #expect(stabilityMetrics.permitLeakDetected == false, "Should have no permit leaks")
        #expect(stabilityMetrics.performanceVariance < 0.3, "Should maintain stable performance")
    }

    // MARK: - Helper Methods

    private func createPermitTestBatch(size: Int, avgMemoryMB: Double) -> [TestChunk] {
        (0..<size).map { _ in
            TestChunk(estimatedMemoryUsage: avgMemoryMB, priority: .normal)
        }
    }
    
    private func createPriorityChunks(count: Int, priority: ChunkPriority, memoryMB: Double) -> [TestChunk] {
        (0..<count).map { _ in
            TestChunk(estimatedMemoryUsage: memoryMB, priority: priority)
        }
    }
    
    private func createTestChunks(count: Int, memoryMB: Double) -> [TestChunk] {
        (0..<count).map { _ in
            TestChunk(estimatedMemoryUsage: memoryMB, priority: .normal)
        }
    }
    
    private func createPerformanceChunks(count: Int, processingTimeMs: Int, memoryMB: Double) -> [TestChunk] {
        (0..<count).map { _ in
            TestChunk(estimatedMemoryUsage: memoryMB, priority: .normal)
        }
    }
    
    private func createMemoryProfileChunks(count: Int, avgMemoryMB: Double, variance: Double) -> [TestChunk] {
        (0..<count).map { _ in
            let memoryUsage = avgMemoryMB + (Double.random(in: -variance...variance))
            return TestChunk(estimatedMemoryUsage: max(0.1, memoryUsage), priority: .normal)
        }
    }
    
    private func createConcurrencyTestChunks(count: Int, processingTimeMs: Int, memoryMB: Double) -> [TestChunk] {
        (0..<count).map { _ in
            TestChunk(estimatedMemoryUsage: memoryMB, priority: .normal)
        }
    }
    
    private func createUnreliableChunks(count: Int, failureRate: Double, memoryMB: Double) -> [TestChunk] {
        (0..<count).map { _ in
            TestChunk(estimatedMemoryUsage: memoryMB, priority: .normal)
        }
    }
    
    private func createMemoryIntensiveChunks(count: Int, avgMemoryMB: Double) -> [TestChunk] {
        (0..<count).map { _ in
            TestChunk(estimatedMemoryUsage: avgMemoryMB, priority: .high)
        }
    }
    
    private func createRealisticRegulationWorkload(totalChunks: Int, memoryVariance: Double, processingVariance: Double, failureRate: Double) -> [TestChunk] {
        (0..<totalChunks).map { _ in
            let memoryUsage = 2.0 + (Double.random(in: -memoryVariance...memoryVariance))
            let priority: ChunkPriority = Double.random(in: 0...1) < 0.2 ? .high : .normal
            return TestChunk(estimatedMemoryUsage: max(0.1, memoryUsage), priority: priority)
        }
    }
}

// MARK: - Type Aliases for Compatibility with Implementation

// Use actual types from AIKO module
typealias ProcessingResult = BatchProcessingResult

// These enums are already defined in the implementation, create local copies for test compatibility

// Test-specific TestChunk that maps to our actual TestChunk type
struct TestChunk {
    let id: UUID = UUID()
    let estimatedMemoryUsage: Double
    let priority: ChunkPriority
    
    init(estimatedMemoryUsage: Double = 2.0, priority: ChunkPriority = .normal) {
        self.estimatedMemoryUsage = estimatedMemoryUsage
        self.priority = priority
    }
}

// Note: Using actual MemoryManagedBatchProcessor implementation from AIKO module

// Note: Using actual implementations from AIKO module and MemoryManagementSupport.swift
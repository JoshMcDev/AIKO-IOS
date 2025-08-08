import Testing
import Foundation
@testable import AIKO

/// Comprehensive unit tests for RegulationEmbeddingService with LFM2 integration
/// Tests embedding generation, caching, batch processing, and semantic quality validation
@Suite("RegulationEmbeddingService Tests")
struct RegulationEmbeddingServiceTests {

    // MARK: - LFM2 Integration Tests

    @Test("LFM2 768-dimensional embedding generation")
    func testLFM2EmbeddingGeneration() async throws {
        // GIVEN: Embedding service configured with LFM2
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            deviceType: .neural
        )

        let testChunks = createRegulationChunks(count: 10, avgTokens: 512)

        // WHEN: Generating embeddings with LFM2
        var generatedEmbeddings: [RegulationEmbedding] = []

        for chunk in testChunks {
            let embedding = try await embeddingService.generateEmbedding(for: chunk)
            generatedEmbeddings.append(embedding)
        }

        // THEN: Should generate 768-dimensional LFM2 embeddings
        #expect(generatedEmbeddings.count == testChunks.count, "Should generate embedding for each chunk")

        for embedding in generatedEmbeddings {
            #expect(embedding.embedding.count == 768, "Should generate 768-dimensional vectors")

            // Verify vector properties
            #expect(!embedding.embedding.allSatisfy { $0 == 0 }, "Vector should not be all zeros")
            let magnitude = sqrt(embedding.embedding.map { $0 * $0 }.reduce(0, +))
            #expect(magnitude > 0.1, "Vector should have reasonable magnitude")
            #expect(magnitude < 100.0, "Vector should not have extreme magnitude")

            // Check for reasonable value distribution
            let vectorMean = embedding.embedding.reduce(0, +) / Float(embedding.embedding.count)
            let vectorStd = sqrt(embedding.embedding.map { pow($0 - vectorMean, 2) }.reduce(0, +) / Float(embedding.embedding.count))
            #expect(vectorStd > 0.01, "Vector should have reasonable variance")
        }
    }

    @Test("Semantic similarity validation between related regulation chunks")
    func testSemanticSimilarityValidation() async throws {
        // GIVEN: Embedding service and semantically related chunks
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768
        )

        let relatedChunks = [
            createRegulationChunk(content: "15.201 Exchanges with industry before receipt of proposals. This section establishes the policy for pre-solicitation exchanges.", section: "15.201"),
            createRegulationChunk(content: "15.202 Advisory multi-step process. This section describes the advisory process for complex acquisitions.", section: "15.202"),
            createRegulationChunk(content: "13.501 Special documentation requirements. This section outlines special documentation needed for simplified acquisitions.", section: "13.501")
        ]

        let unrelatedChunk = createRegulationChunk(content: "52.215-1 Instructions to offerors—competitive acquisition. This clause provides instructions to offerors.", section: "52.215-1")

        // WHEN: Computing semantic similarities
        let relatedEmbeddings = try await embeddingService.generateBatchEmbeddings(relatedChunks)
        let unrelatedEmbedding = try await embeddingService.generateEmbedding(for: unrelatedChunk)

        // THEN: Related chunks should have higher similarity than unrelated chunks
        let similarity_15_201_to_15_202 = try await embeddingService.computeCosineSimilarity(
            relatedEmbeddings[0], relatedEmbeddings[1]
        )
        let similarity_15_201_to_13_501 = try await embeddingService.computeCosineSimilarity(
            relatedEmbeddings[0], relatedEmbeddings[2]
        )
        let similarity_15_201_to_52_215 = try await embeddingService.computeCosineSimilarity(
            relatedEmbeddings[0], unrelatedEmbedding
        )

        #expect(similarity_15_201_to_15_202 > 0.7, "Adjacent sections should have high similarity")
        #expect(similarity_15_201_to_13_501 > 0.4, "Related FAR sections should have moderate similarity")
        #expect(similarity_15_201_to_52_215 < 0.6, "Unrelated sections should have lower similarity")

        // Verify hierarchical similarity pattern
        #expect(similarity_15_201_to_15_202 > similarity_15_201_to_13_501, "Adjacent sections should be more similar than distant ones")
        #expect(similarity_15_201_to_13_501 > similarity_15_201_to_52_215, "Same regulation should be more similar than different regulation")
    }

    @Test("Context-aware embedding with regulation hierarchy")
    func testContextAwareEmbeddingWithRegulationHierarchy() async throws {
        // GIVEN: Embedding service with context awareness enabled
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            enableContextualEmbedding: true
        )

        // WHEN: Generating embeddings with hierarchical context
        let contextualChunk = RegulationChunk(
            id: UUID(),
            content: "Market research activities may include one-on-one meetings with potential offerors prior to the issuance of the solicitation.",
            tokenCount: 25,
            hierarchy: RegulationHierarchy(
                part: "PART 15",
                subpart: "Subpart 15.2",
                section: "15.201",
                subsection: "(a)",
                paragraph: "(1)"
            ),
            parentContext: "15.201 Exchanges with industry before receipt of proposals. This section establishes the policy for pre-solicitation exchanges.",
            crossReferences: ["13.501", "15.202", "52.215-1"]
        )

        let nonContextualChunk = RegulationChunk(
            id: UUID().uuidString,
            content: "Market research activities may include one-on-one meetings with potential offerors prior to the issuance of the solicitation.",
            tokenCount: 25
        )

        let contextualEmbedding = try await embeddingService.generateContextualEmbedding(contextualChunk)
        let nonContextualEmbedding = try await embeddingService.generateEmbedding(for: nonContextualChunk)

        // THEN: Contextual embedding should capture hierarchical information
        #expect(contextualEmbedding.hasHierarchicalContext, "Should include hierarchical context")
        #expect(!contextualEmbedding.contextFeatures.isEmpty, "Should have context features")
        #expect(contextualEmbedding.crossReferenceEmbeddings.count == 3, "Should embed cross-references")

        // Verify contextual richness
        let contextSimilarity = try await embeddingService.computeCosineSimilarity(contextualEmbedding, nonContextualEmbedding)
        #expect(contextSimilarity < 0.95, "Contextual embedding should differ from non-contextual")

        // Check hierarchical features
        let hierarchyFeatures = contextualEmbedding.hierarchyFeatures
        #expect(hierarchyFeatures.partEmbedding != nil, "Should embed part information")
        #expect(hierarchyFeatures.sectionEmbedding != nil, "Should embed section information")
        #expect(hierarchyFeatures.depthEncoding > 0, "Should encode hierarchy depth")
    }

    @Test("Neural Engine performance optimization validation")
    func testNeuralEnginePerformanceOptimization() async throws {
        // GIVEN: Embedding service with Neural Engine optimization
        let neuralService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            deviceType: .neural,
            batchSize: 32
        )

        let cpuService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            deviceType: .cpu,
            batchSize: 32
        )

        let testChunks = createRegulationChunks(count: 100, avgTokens: 512)

        // WHEN: Comparing Neural Engine vs CPU performance
        let neuralStartTime = CFAbsoluteTimeGetCurrent()
        let neuralEmbeddings = try await neuralService.generateBatchEmbeddings(testChunks)
        let neuralEndTime = CFAbsoluteTimeGetCurrent()

        let cpuStartTime = CFAbsoluteTimeGetCurrent()
        let cpuEmbeddings = try await cpuService.generateBatchEmbeddings(testChunks)
        let cpuEndTime = CFAbsoluteTimeGetCurrent()

        let neuralTime = neuralEndTime - neuralStartTime
        let cpuTime = cpuEndTime - cpuStartTime

        // THEN: Neural Engine should provide performance benefits
        #expect(neuralEmbeddings.count == testChunks.count, "Neural Engine should process all chunks")
        #expect(cpuEmbeddings.count == testChunks.count, "CPU should process all chunks")

        // Performance comparison (Neural Engine should be faster or comparable)
        let speedupRatio = cpuTime / neuralTime
        #expect(speedupRatio >= 0.8, "Neural Engine should be at least 80% as fast as CPU")

        // Quality comparison (embeddings should be equivalent)
        let qualityCorrelation = try await computeEmbeddingQualityCorrelation(neuralEmbeddings, cpuEmbeddings)
        #expect(qualityCorrelation > 0.95, "Neural Engine and CPU embeddings should be highly correlated")

        // Energy efficiency (Neural Engine should use less power)
        let neuralEnergyUsage = await neuralService.getEnergyMetrics()
        let cpuEnergyUsage = await cpuService.getEnergyMetrics()

        let energyEfficiencyRatio = cpuEnergyUsage.totalEnergyMJ / neuralEnergyUsage.totalEnergyMJ
        #expect(energyEfficiencyRatio >= 1.2, "Neural Engine should be more energy efficient")
    }

    // MARK: - Caching and Performance Tests

    @Test("Multi-level caching with LRU and semantic similarity")
    func testMultiLevelCachingWithLRUAndSemanticSimilarity() async throws {
        // GIVEN: Embedding service with sophisticated caching
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            enableMultiLevelCaching: true,
            l1CacheSize: 100,
            l2CacheSize: 500,
            semanticCacheThreshold: 0.95
        )

        let testChunks = createRegulationChunks(count: 150, avgTokens: 512)
        let cacheMonitor = EmbeddingCacheMonitor()

        // WHEN: Processing chunks to test caching behavior
        var firstPassEmbeddings: [RegulationEmbedding] = []
        let firstPassStart = CFAbsoluteTimeGetCurrent()

        for chunk in testChunks {
            let embedding = try await embeddingService.generateEmbedding(for: chunk)
            firstPassEmbeddings.append(embedding)
            await cacheMonitor.recordCacheAccess(chunkId: chunk.id, hit: false)
        }
        let firstPassTime = CFAbsoluteTimeGetCurrent() - firstPassStart

        // Process same chunks again
        var secondPassEmbeddings: [RegulationEmbedding] = []
        let secondPassStart = CFAbsoluteTimeGetCurrent()

        for chunk in testChunks.prefix(100) { // Process first 100 again
            let embedding = try await embeddingService.generateEmbedding(for: chunk)
            secondPassEmbeddings.append(embedding)
            await cacheMonitor.recordCacheAccess(chunkId: chunk.id, hit: true)
        }
        let secondPassTime = CFAbsoluteTimeGetCurrent() - secondPassStart

        // THEN: Caching should improve performance
        let cacheStats = await embeddingService.getCacheStatistics()

        #expect(secondPassTime < firstPassTime * 0.3, "Cached access should be much faster")
        #expect(cacheStats.l1HitRate > 0.8, "L1 cache should have high hit rate for recent chunks")
        #expect(cacheStats.l2HitRate > 0.6, "L2 cache should have decent hit rate")

        // Verify cache eviction behavior (LRU)
        let cacheEvictionStats = cacheStats.evictionStats
        #expect(cacheEvictionStats.lruEvictions > 0, "Should have LRU evictions for large dataset")
        #expect(cacheEvictionStats.semanticEvictions >= 0, "May have semantic-based evictions")

        // Test semantic similarity cache hits
        let similarChunk = createSimilarRegulationChunk(to: testChunks.first!)
        let semanticStart = CFAbsoluteTimeGetCurrent()
        let semanticEmbedding = try await embeddingService.generateEmbedding(for: similarChunk)
        let semanticTime = CFAbsoluteTimeGetCurrent() - semanticStart

        #expect(semanticTime < firstPassTime / Float(testChunks.count) * 0.5, "Semantic similarity should enable cache hits")

        let finalCacheStats = await embeddingService.getCacheStatistics()
        #expect(finalCacheStats.semanticHits > 0, "Should have semantic cache hits")
    }

    @Test("Batch processing optimization with intelligent batching")
    func testBatchProcessingOptimizationWithIntelligentBatching() async throws {
        // GIVEN: Embedding service with intelligent batching
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            enableIntelligentBatching: true,
            targetBatchLatencyMs: 500,
            maxBatchSize: 64
        )

        let mixedSizeChunks = createMixedSizeChunks(
            smallChunks: 50, mediumChunks: 50, largeChunks: 25
        )

        let batchingMonitor = BatchProcessingMonitor()

        // WHEN: Processing with intelligent batching
        let startTime = CFAbsoluteTimeGetCurrent()
        let embeddings = try await batchingMonitor.monitorBatchProcessing {
            try await embeddingService.generateIntelligentBatchEmbeddings(mixedSizeChunks)
        }
        let endTime = CFAbsoluteTimeGetCurrent()

        let totalTime = endTime - startTime

        // THEN: Should optimize batch composition for performance
        let batchingStats = await batchingMonitor.getBatchingStatistics()

        #expect(embeddings.count == mixedSizeChunks.count, "Should process all chunks")
        #expect(totalTime < 10.0, "Should complete batch processing efficiently")

        // Verify intelligent batching behavior
        #expect(batchingStats.averageBatchSize > 8, "Should use reasonably sized batches")
        #expect(batchingStats.averageBatchLatency < 0.6, "Should meet target latency")
        #expect(batchingStats.batchSizeVariation < 0.5, "Should have consistent batch sizes")

        // Check batch composition optimization
        let compositionStats = batchingStats.compositionOptimization
        #expect(compositionStats.homogeneousTokenSizeBatches > 0.7, "Should group similar-sized chunks")
        #expect(compositionStats.loadBalancingEffectiveness > 0.8, "Should balance batch loads effectively")

        // Verify memory efficiency
        let memoryStats = await embeddingService.getMemoryStatistics()
        #expect(memoryStats.peakBatchMemoryMB < 100, "Should use memory efficiently during batching")
        #expect(memoryStats.memoryFragmentation < 0.2, "Should minimize memory fragmentation")
    }

    @Test("Concurrent embedding generation with TaskGroup")
    func testConcurrentEmbeddingGenerationWithTaskGroup() async throws {
        // GIVEN: Embedding service configured for concurrency
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            maxConcurrency: 4,
            enableConcurrentProcessing: true
        )

        let testChunks = createRegulationChunks(count: 80, avgTokens: 512)
        let concurrencyMonitor = EmbeddingConcurrencyMonitor()

        // WHEN: Processing concurrently with TaskGroup
        try await withThrowingTaskGroup(of: RegulationEmbedding.self) { group in
            let startTime = CFAbsoluteTimeGetCurrent()
            var activeTasks = 0

            for chunk in testChunks {
                if activeTasks >= embeddingService.maxConcurrency {
                    // Wait for a task to complete
                    let embedding = try await group.next()!
                    await concurrencyMonitor.recordCompletion(embedding: embedding)
                    activeTasks -= 1
                }

                group.addTask {
                    await concurrencyMonitor.recordTaskStart(chunkId: chunk.id)
                    let embedding = try await embeddingService.generateEmbedding(for: chunk)
                    await concurrencyMonitor.recordTaskCompletion(chunkId: chunk.id)
                    return embedding
                }
                activeTasks += 1
            }

            // Process remaining embeddings
            var allEmbeddings: [RegulationEmbedding] = []
            while let embedding = try await group.next() {
                allEmbeddings.append(embedding)
                await concurrencyMonitor.recordCompletion(embedding: embedding)
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime

            // THEN: Should achieve efficient concurrent processing
            let concurrencyStats = await concurrencyMonitor.getConcurrencyStatistics()

            #expect(allEmbeddings.count == testChunks.count, "Should process all chunks concurrently")
            #expect(totalTime < 25.0, "Should complete faster with concurrency")
            #expect(concurrencyStats.averageConcurrency >= 2.0, "Should maintain good concurrency level")
            #expect(concurrencyStats.concurrencyUtilization > 0.7, "Should utilize concurrency effectively")

            // Verify no race conditions or data corruption
            let uniqueEmbeddings = Set(allEmbeddings.map { $0.chunkId })
            #expect(uniqueEmbeddings.count == testChunks.count, "Should have unique embeddings for each chunk")

            // Check for consistent quality across concurrent processing
            let qualityVariance = computeEmbeddingQualityVariance(allEmbeddings)
            #expect(qualityVariance < 0.1, "Concurrent processing should maintain consistent quality")
        }
    }

    @Test("Memory pressure handling with embedding queue management")
    func testMemoryPressureHandlingWithEmbeddingQueueManagement() async throws {
        // GIVEN: Embedding service with memory pressure monitoring
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            enableMemoryPressureHandling: true,
            memoryPressureThresholdMB: 300,
            queueManagementStrategy: .adaptive
        )

        let memoryIntensiveChunks = createLargeRegulationChunks(count: 200, avgTokens: 1024)
        let memoryMonitor = EmbeddingMemoryMonitor()

        // WHEN: Processing under simulated memory pressure
        await embeddingService.simulateMemoryPressure(level: MemoryPressureLevel(rawValue: 3) ?? .critical)

        let results = try await memoryMonitor.monitorMemoryDuringEmbedding {
            try await embeddingService.generateBatchEmbeddingsWithMemoryManagement(memoryIntensiveChunks)
        }

        // THEN: Should handle memory pressure gracefully
        let memoryMetrics = await memoryMonitor.getMemoryMetrics()

        #expect(results.count == memoryIntensiveChunks.count, "Should process all chunks despite memory pressure")
        #expect(memoryMetrics.peakMemoryUsageMB < 400, "Should stay within memory limits")
        #expect(memoryMetrics.memoryPressureEvents > 0, "Should detect memory pressure events")

        // Verify queue management effectiveness
        let queueStats = await embeddingService.getQueueManagementStatistics()
        #expect(queueStats.queueResizeEvents > 0, "Should dynamically resize queues under pressure")
        #expect(queueStats.batchSizeReductions > 0, "Should reduce batch sizes under memory pressure")
        #expect(queueStats.averageQueueLength < 50, "Should maintain reasonable queue lengths")

        // Check graceful degradation
        let degradationMetrics = memoryMetrics.degradationMetrics
        #expect(degradationMetrics.qualityMaintained > 0.9, "Should maintain embedding quality during pressure")
        #expect(degradationMetrics.throughputImpact < 0.5, "Throughput impact should be reasonable")
    }

    // MARK: - Integration and Error Handling Tests

    @Test("Integration with ObjectBoxSemanticIndex for vector storage")
    func testIntegrationWithObjectBoxSemanticIndexForVectorStorage() async throws {
        // GIVEN: Embedding service with ObjectBox integration
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            vectorStorageIntegration: .objectBox
        )

        let objectBoxStorage = MockObjectBoxSemanticIndex()
        await embeddingService.configureVectorStorage(objectBoxStorage)

        let testChunks = createRegulationChunks(count: 50, avgTokens: 512)

        // WHEN: Generating embeddings with automatic storage
        var storedEmbeddings: [RegulationEmbedding] = []

        for chunk in testChunks {
            let embedding = try await embeddingService.generateAndStoreEmbedding(for: chunk)
            storedEmbeddings.append(embedding)
        }

        // THEN: Embeddings should be stored in ObjectBox
        let storageStats = await objectBoxStorage.getStorageStatistics()

        #expect(storedEmbeddings.count == testChunks.count, "Should generate all embeddings")
        #expect(storageStats.totalStoredVectors == testChunks.count, "Should store all embeddings in ObjectBox")
        #expect(storageStats.averageStorageLatencyMs < 10, "Storage latency should be minimal")

        // Verify vector retrieval integration
        for embedding in storedEmbeddings {
            let retrievedVector = try await objectBoxStorage.retrieveVector(id: UUID(uuidString: embedding.id) ?? UUID())
            #expect(retrievedVector.count == 768, "Should retrieve correct vector dimensions")

            let vectorSimilarity = cosineSimilarity(embedding.embedding, retrievedVector)
            #expect(vectorSimilarity > 0.999, "Retrieved vector should match original")
        }

        // Test semantic search integration
        let queryEmbedding = storedEmbeddings.first!
        let similarResults = try await objectBoxStorage.findSimilarVectors(
            query: queryEmbedding.embedding,
            topK: 10,
            threshold: 0.7
        )

        #expect(!similarResults.isEmpty, "Should find similar vectors")
        #expect(similarResults.count <= 10, "Should respect topK limit")
        #expect(similarResults.allSatisfy { $0.similarity >= 0.7 }, "Should respect similarity threshold")
    }

    @Test("Error recovery and fallback mechanisms")
    func testErrorRecoveryAndFallbackMechanisms() async throws {
        // GIVEN: Embedding service with error recovery
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            enableErrorRecovery: true,
            fallbackStrategy: .cpuFallback,
            maxRetryAttempts: 3
        )

        let problematicChunks = createProblematicRegulationChunks(
            corruptedCount: 10,
            oversizedCount: 10,
            emptyCount: 5,
            normalCount: 25
        )

        let errorTracker = EmbeddingErrorTracker()

        // WHEN: Processing chunks with various error conditions
        var successfulEmbeddings: [RPPRegulationEmbedding] = []
        var recoveredErrors: [EmbeddingError] = []
        var finalFailures: [EmbeddingError] = []

        for chunk in problematicChunks {
            do {
                let embedding = try await embeddingService.generateEmbeddingWithRecovery(for: chunk)
                successfulEmbeddings.append(embedding)
                await errorTracker.recordSuccess(chunkId: chunk.id)
            } catch let error as EmbeddingError {
                if error.isRecoverable {
                    recoveredErrors.append(error)
                    await errorTracker.recordRecovery(chunkId: chunk.id, error: error)
                } else {
                    finalFailures.append(error)
                    await errorTracker.recordFailure(chunkId: chunk.id, error: error)
                }
            }
        }

        // THEN: Should handle errors gracefully with appropriate recovery
        let errorStats = await errorTracker.getErrorStatistics()

        #expect(successfulEmbeddings.count >= 40, "Should successfully process most chunks")
        #expect(errorStats.recoveryRate > 0.8, "Should recover from most recoverable errors")
        #expect(finalFailures.count < 10, "Final failures should be minimal")

        // Verify error type handling
        let errorByType = errorStats.errorsByType
        #expect(errorByType[.corruptedInput]?.recoveryAttempts ?? 0 > 0, "Should attempt recovery for corrupted input")
        #expect(errorByType[.oversizedChunk]?.fallbackUsed == true, "Should use fallback for oversized chunks")
        #expect(errorByType[.emptyContent]?.handled == true, "Should handle empty content gracefully")

        // Check fallback mechanism effectiveness
        let fallbackStats = await embeddingService.getFallbackStatistics()
        #expect(fallbackStats.fallbackActivations > 0, "Should activate fallback mechanisms")
        #expect(fallbackStats.fallbackSuccessRate > 0.7, "Fallback should be mostly successful")

        // Verify retry logic
        let retryStats = errorStats.retryStatistics
        #expect(retryStats.averageRetryAttempts < 2.0, "Should not require excessive retries")
        #expect(retryStats.exponentialBackoffUsed, "Should use exponential backoff for retries")
    }

    @Test("Embedding quality validation and consistency checks")
    func testEmbeddingQualityValidationAndConsistencyChecks() async throws {
        // GIVEN: Embedding service with quality validation
        let embeddingService = RegulationEmbeddingService(
            modelType: .lfm2,
            dimensions: 768,
            enableQualityValidation: true,
            qualityThresholds: EmbeddingQualityThresholds(
                minimumMagnitude: 0.1,
                maximumMagnitude: 100.0,
                minimumVariance: 0.001,
                maximumVariance: 10.0
            )
        )

        let testChunks = createRegulationChunks(count: 100, avgTokens: 512)
        let qualityValidator = EmbeddingQualityValidator()

        // WHEN: Generating embeddings with quality validation
        var validatedEmbeddings: [RPPRegulationEmbedding] = []
        var qualityIssues: [QualityIssue] = []

        for chunk in testChunks {
            let embedding = try await embeddingService.generateValidatedEmbedding(for: chunk)
            validatedEmbeddings.append(embedding)

            let qualityReport = await qualityValidator.validateEmbedding(embedding)
            qualityIssues.append(contentsOf: qualityReport.issues)
        }

        // THEN: Should maintain high embedding quality
        let qualityStats = await qualityValidator.getQualityStatistics()

        #expect(validatedEmbeddings.count == testChunks.count, "Should generate all embeddings with quality validation")
        #expect(qualityStats.overallQualityScore > 0.9, "Should maintain high overall quality")
        #expect(qualityIssues.filter { $0.severity == .critical }.isEmpty, "Should have no critical quality issues")

        // Verify specific quality metrics
        for embedding in validatedEmbeddings {
            let magnitude = sqrt(embedding.vector.map { $0 * $0 }.reduce(0, +))
            #expect(magnitude >= 0.1 && magnitude <= 100.0, "Vector magnitude should be within acceptable range")

            let mean = embedding.vector.reduce(0, +) / Float(embedding.vector.count)
            let squaredDifferences = embedding.vector.map { pow($0 - mean, 2) }
            let variance = squaredDifferences.reduce(0, +) / Float(embedding.vector.count)
            #expect(variance >= 0.001 && variance <= 10.0, "Vector variance should be reasonable")
        }

        // Test consistency across multiple generations
        let consistencyTestChunk = testChunks.first!
        var consistencyEmbeddings: [RPPRegulationEmbedding] = []

        for _ in 0..<5 {
            let embedding = try await embeddingService.generateEmbedding(for: consistencyTestChunk)
            consistencyEmbeddings.append(embedding)
        }

        // Verify embedding consistency (should be identical for same input)
        let baseEmbedding = consistencyEmbeddings.first!
        for embedding in consistencyEmbeddings.dropFirst() {
            let similarity = cosineSimilarity(baseEmbedding.vector, embedding.vector)
            #expect(similarity > 0.999, "Embeddings should be consistent across generations")
        }
    }

    // MARK: - Helper Methods

    private func createRegulationChunks(count: Int, avgTokens: Int) -> [RegulationChunk] {
        return (1...count).map { index in
            RegulationChunk(
                id: "chunk-\(index)",
                content: "This is regulation chunk \(index) with approximately \(avgTokens) tokens of content to simulate real regulation text processing requirements.",
                tokenCount: avgTokens,
                hierarchyPath: "Part \((index - 1) / 10 + 1).Section \(index)",
                parentContext: "Parent context for chunk \(index)",
                crossReferences: ["ref-\(index)", "ref-\(index + 1)"]
            )
        }
    }

    private func createRegulationChunk(content: String, section: String) -> RegulationChunk {
        return RegulationChunk(
            id: "chunk-\(section)",
            content: content,
            tokenCount: content.components(separatedBy: .whitespaces).count,
            hierarchyPath: section,
            parentContext: "Context for \(section)",
            crossReferences: []
        )
    }

    private func createSimilarRegulationChunk(to chunk: RegulationChunk) -> RegulationChunk {
        return RegulationChunk(
            id: chunk.id + "-similar",
            content: chunk.content + " Similar regulation text to simulate semantic similarity.",
            tokenCount: chunk.tokenCount + 10,
            hierarchyPath: chunk.hierarchyPath,
            parentContext: chunk.parentContext,
            crossReferences: chunk.crossReferences
        )
    }

    private func createMixedSizeChunks(smallChunks: Int, mediumChunks: Int, largeChunks: Int) -> [RegulationChunk] {
        var chunks: [RegulationChunk] = []

        // Small chunks (128 tokens)
        chunks.append(contentsOf: createRegulationChunks(count: smallChunks, avgTokens: 128))

        // Medium chunks (512 tokens)
        chunks.append(contentsOf: createRegulationChunks(count: mediumChunks, avgTokens: 512).map { chunk in
            RegulationChunk(
                id: "medium-\(chunk.id)",
                content: chunk.content,
                tokenCount: 512,
                hierarchyPath: chunk.hierarchyPath,
                parentContext: chunk.parentContext,
                crossReferences: chunk.crossReferences
            )
        })

        // Large chunks (1024 tokens)
        chunks.append(contentsOf: createRegulationChunks(count: largeChunks, avgTokens: 1024).map { chunk in
            RegulationChunk(
                id: "large-\(chunk.id)",
                content: chunk.content,
                tokenCount: 1024,
                hierarchyPath: chunk.hierarchyPath,
                parentContext: chunk.parentContext,
                crossReferences: chunk.crossReferences
            )
        })

        return chunks
    }

    private func createLargeRegulationChunks(count: Int, avgTokens: Int) -> [RegulationChunk] {
        return createRegulationChunks(count: count, avgTokens: avgTokens).map { chunk in
            RegulationChunk(
                id: "large-\(chunk.id)",
                content: String(repeating: chunk.content + " ", count: 3), // Make content larger
                tokenCount: avgTokens,
                hierarchyPath: chunk.hierarchyPath,
                parentContext: chunk.parentContext,
                crossReferences: chunk.crossReferences
            )
        }
    }

    private func createProblematicRegulationChunks(corruptedCount: Int, oversizedCount: Int, emptyCount: Int, normalCount: Int) -> [RegulationChunk] {
        var chunks: [RegulationChunk] = []

        // Corrupted chunks (with invalid characters/malformed content)
        for i in 1...corruptedCount {
            chunks.append(RegulationChunk(
                id: "corrupted-\(i)",
                content: "Invalid content with corrupted characters",
                tokenCount: 50,
                hierarchyPath: "Error.Section.\(i)",
                parentContext: "Corrupted context",
                crossReferences: []
            ))
        }

        // Oversized chunks (exceeding normal token limits)
        for i in 1...oversizedCount {
            let largeContent = String(repeating: "This is an extremely long regulation chunk that exceeds normal processing limits. ", count: 100)
            chunks.append(RegulationChunk(
                id: "oversized-\(i)",
                content: largeContent,
                tokenCount: 5000,
                hierarchyPath: "Oversized.Section.\(i)",
                parentContext: "Oversized context",
                crossReferences: []
            ))
        }

        // Empty chunks (minimal or no content)
        for i in 1...emptyCount {
            chunks.append(RegulationChunk(
                id: "empty-\(i)",
                content: "",
                tokenCount: 0,
                hierarchyPath: "Empty.Section.\(i)",
                parentContext: "",
                crossReferences: []
            ))
        }

        // Normal chunks for comparison
        chunks.append(contentsOf: createRegulationChunks(count: normalCount, avgTokens: 512))

        return chunks
    }

    private func computeEmbeddingQualityCorrelation(_ embeddings1: [RegulationEmbedding], _ embeddings2: [RegulationEmbedding]) async throws -> Double {
        guard embeddings1.count == embeddings2.count && !embeddings1.isEmpty else { return 0.0 }

        // Compute correlation between corresponding embeddings
        var totalCorrelation = 0.0

        for (embed1, embed2) in zip(embeddings1, embeddings2) {
            let similarity = cosineSimilarity(embed1.embedding, embed2.embedding)
            totalCorrelation += Double(similarity)
        }

        return totalCorrelation / Double(embeddings1.count)
    }

    private func computeEmbeddingQualityVariance(_ embeddings: [RegulationEmbedding]) -> Double {
        guard !embeddings.isEmpty else { return 0.0 }

        // Compute variance in embedding magnitudes as a quality metric
        let magnitudes = embeddings.map { embedding in
            Double(sqrt(embedding.embedding.map { $0 * $0 }.reduce(0, +)))
        }

        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let variance = magnitudes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(magnitudes.count)

        return variance
    }

    private func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitude1 * magnitude2)
    }
}

// MARK: - Supporting Types (Will fail until implemented)

enum ModelType {
    case lfm2, bert, sentenceTransformer
}

enum DeviceType {
    case cpu, gpu, neural
}

enum VectorStorageIntegration {
    case objectBox, coreML, custom
}

enum QueueManagementStrategy {
    case fifo, priority, adaptive
}

enum FallbackStrategy {
    case cpuFallback, modelFallback, caching
}

enum EmbeddingError: Error {
    case corruptedInput
    case oversizedChunk
    case emptyContent
    case modelFailure
    case memoryExhaustion

    var isRecoverable: Bool {
        switch self {
        case .corruptedInput, .oversizedChunk: return true
        case .emptyContent: return true
        case .modelFailure, .memoryExhaustion: return false
        }
    }
}

enum QualitySeverity {
    case low, medium, high, critical
}

struct RPPRegulationEmbedding {
    let chunkId: UUID
    let vector: [Float]
    let modelType: ModelType
    let computeDevice: DeviceType
    let hasHierarchicalContext: Bool = false
    let contextFeatures: [Float] = []
    let crossReferenceEmbeddings: [[Float]] = []
    let hierarchyFeatures: HierarchyFeatures = HierarchyFeatures()
}

struct HierarchyFeatures {
    let partEmbedding: [Float]? = nil
    let sectionEmbedding: [Float]? = nil
    let depthEncoding: Float = 0
}

struct RegulationChunk {
    let id: UUID
    let content: String
    let tokenCount: Int
    let hierarchy: RegulationHierarchy? = nil
    let parentContext: String? = nil
    let crossReferences: [String] = []
}

struct RegulationHierarchy {
    let part: String?
    let subpart: String?
    let section: String?
    let subsection: String?
    let paragraph: String?
}

struct EmbeddingQualityThresholds {
    let minimumMagnitude: Float
    let maximumMagnitude: Float
    let minimumVariance: Float
    let maximumVariance: Float
}

struct QualityIssue {
    let type: QualityIssueType
    let severity: QualitySeverity
    let description: String
}

enum QualityIssueType {
    case lowMagnitude, highMagnitude, lowVariance, highVariance, corruption
}

struct CacheStatistics {
    let l1HitRate: Double
    let l2HitRate: Double
    let evictionStats: EvictionStatistics
    let semanticHits: Int
}

struct EvictionStatistics {
    let lruEvictions: Int
    let semanticEvictions: Int
    let totalEvictions: Int
}

struct BatchingStatistics {
    let averageBatchSize: Double
    let averageBatchLatency: Double
    let batchSizeVariation: Double
    let compositionOptimization: CompositionOptimization
}

struct CompositionOptimization {
    let homogeneousTokenSizeBatches: Double
    let loadBalancingEffectiveness: Double
}

struct MemoryStatistics {
    let peakBatchMemoryMB: Double
    let memoryFragmentation: Double
}

struct ConcurrencyStatistics {
    let averageConcurrency: Double
    let concurrencyUtilization: Double
}

struct MemoryMetrics {
    let peakMemoryUsageMB: Double
    let memoryPressureEvents: Int
    let degradationMetrics: DegradationMetrics
}

struct DegradationMetrics {
    let qualityMaintained: Double
    let throughputImpact: Double
}

struct QueueManagementStatistics {
    let queueResizeEvents: Int
    let batchSizeReductions: Int
    let averageQueueLength: Double
}

struct StorageStatistics {
    let totalStoredVectors: Int
    let averageStorageLatencyMs: Double
}

struct SimilarityResult {
    let id: UUID
    let similarity: Float
}

struct ErrorStatistics {
    let recoveryRate: Double
    let errorsByType: [EmbeddingError: ErrorTypeStats]
    let retryStatistics: RetryStatistics
}

struct ErrorTypeStats {
    let recoveryAttempts: Int
    let fallbackUsed: Bool
    let handled: Bool
}

struct RetryStatistics {
    let averageRetryAttempts: Double
    let exponentialBackoffUsed: Bool
}

struct FallbackStatistics {
    let fallbackActivations: Int
    let fallbackSuccessRate: Double
}

struct QualityStatistics {
    let overallQualityScore: Double
}

struct QualityReport {
    let issues: [QualityIssue]
    let overallScore: Double
}

struct EnergyMetrics {
    let totalEnergyMJ: Double
    let averagePowerWatts: Double
}

// Classes that will fail until implemented
class RegulationEmbeddingService {
    let modelType: ModelType
    let dimensions: Int
    let deviceType: DeviceType
    let maxConcurrency: Int

    init(
        modelType: ModelType,
        dimensions: Int,
        deviceType: DeviceType = .neural,
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
        queueManagementStrategy: QueueManagementStrategy = .fifo,
        vectorStorageIntegration: VectorStorageIntegration? = nil,
        enableErrorRecovery: Bool = false,
        fallbackStrategy: FallbackStrategy = .cpuFallback,
        maxRetryAttempts: Int = 3,
        enableQualityValidation: Bool = false,
        qualityThresholds: EmbeddingQualityThresholds? = nil
    ) {
        self.modelType = modelType
        self.dimensions = dimensions
        self.deviceType = deviceType
        self.maxConcurrency = maxConcurrency
        fatalError("RegulationEmbeddingService not yet implemented")
    }

    func generateEmbedding(for chunk: RegulationChunk) async throws -> RegulationEmbedding {
        let mockVector = Array(0..<768).map { _ in Float.random(in: -1...1) }
        return RegulationEmbedding(
            id: chunk.id,
            title: "Regulation Chunk",
            content: chunk.content,
            embedding: mockVector
        )
    }

    func generateContextualEmbedding(_ chunk: RegulationChunk) async throws -> RegulationEmbedding {
        let mockVector = Array(0..<768).map { _ in Float.random(in: -1...1) }
        return RegulationEmbedding(
            id: chunk.id,
            title: "Contextual Regulation Chunk",
            content: chunk.content,
            embedding: mockVector
        )
    }

    func generateBatchEmbeddings(_ chunks: [RegulationChunk]) async throws -> [RegulationEmbedding] {
        return try await withThrowingTaskGroup(of: RegulationEmbedding.self) { group in
            var embeddings: [RegulationEmbedding] = []
            for chunk in chunks {
                group.addTask {
                    try await self.generateEmbedding(for: chunk)
                }
            }
            for try await embedding in group {
                embeddings.append(embedding)
            }
            return embeddings
        }
    }

    func generateIntelligentBatchEmbeddings(_ chunks: [RegulationChunk]) async throws -> [RegulationEmbedding] {
        return try await generateBatchEmbeddings(chunks)
    }

    func generateBatchEmbeddingsWithMemoryManagement(_ chunks: [RegulationChunk]) async throws -> [RegulationEmbedding] {
        return try await generateBatchEmbeddings(chunks)
    }

    func generateAndStoreEmbedding(for chunk: RegulationChunk) async throws -> RegulationEmbedding {
        return try await generateEmbedding(for: chunk)
    }

    func generateEmbeddingWithRecovery(for chunk: RegulationChunk) async throws -> RegulationEmbedding {
        return try await generateEmbedding(for: chunk)
    }

    func generateValidatedEmbedding(for chunk: RegulationChunk) async throws -> RegulationEmbedding {
        return try await generateEmbedding(for: chunk)
    }

    func computeCosineSimilarity(_ embedding1: RegulationEmbedding, _ embedding2: RegulationEmbedding) async throws -> Double {
        fatalError("RegulationEmbeddingService.computeCosineSimilarity not yet implemented")
    }

    func configureVectorStorage(_ storage: MockObjectBoxSemanticIndex) async {
        fatalError("RegulationEmbeddingService.configureVectorStorage not yet implemented")
    }

    func simulateMemoryPressure(level: MemoryPressureLevel) async {
        fatalError("RegulationEmbeddingService.simulateMemoryPressure not yet implemented")
    }

    func getCacheStatistics() async -> CacheStatistics {
        fatalError("RegulationEmbeddingService.getCacheStatistics not yet implemented")
    }

    func getMemoryStatistics() async -> MemoryStatistics {
        fatalError("RegulationEmbeddingService.getMemoryStatistics not yet implemented")
    }

    func getQueueManagementStatistics() async -> QueueManagementStatistics {
        fatalError("RegulationEmbeddingService.getQueueManagementStatistics not yet implemented")
    }

    func getFallbackStatistics() async -> FallbackStatistics {
        fatalError("RegulationEmbeddingService.getFallbackStatistics not yet implemented")
    }

    func getEnergyMetrics() async -> EnergyMetrics {
        fatalError("RegulationEmbeddingService.getEnergyMetrics not yet implemented")
    }
}

class MockObjectBoxSemanticIndex {
    let dimensions: Int
    private var storedVectors: [UUID: [Float]] = [:]

    init(dimensions: Int) {
        self.dimensions = dimensions
    }

    func storeVector(_ vector: [Float], id: UUID) async throws {
        storedVectors[id] = vector
    }

    func getStorageStatistics() async -> StorageStatistics {
        return StorageStatistics(
            totalVectors: storedVectors.count,
            totalStorageSize: storedVectors.count * dimensions * 4, // 4 bytes per float
            averageVectorSize: dimensions * 4,
            indexingEfficiency: 0.95
        )
    }

    func retrieveVector(id: UUID) async throws -> [Float] {
        guard let vector = storedVectors[id] else {
            throw StorageError.vectorNotFound
        }
        return vector
    }

    func findSimilarVectors(query: [Float], topK: Int, threshold: Float = 0.5) async throws -> [SimilarityResult] {
        let results = storedVectors.compactMap { (id, vector) in
            let similarity = cosineSimilarity(query, vector)
            return similarity >= threshold ? SimilarityResult(id: id, similarity: similarity) : nil
        }.sorted { $0.similarity > $1.similarity }.prefix(topK)

        return Array(results)
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (normA * normB)
    }
}

struct StorageStatistics {
    let totalVectors: Int
    let totalStorageSize: Int
    let averageVectorSize: Int
    let indexingEfficiency: Float
}

struct SimilarityResult {
    let id: UUID
    let similarity: Float
}

enum StorageError: Error {
    case vectorNotFound
}

class EmbeddingCacheMonitor {
    func recordCacheAccess(chunkId: UUID, hit: Bool) async {
        fatalError("EmbeddingCacheMonitor.recordCacheAccess not yet implemented")
    }
}

class BatchProcessingMonitor {
    func monitorBatchProcessing<T>(_ operation: () async throws -> T) async rethrows -> T {
        fatalError("BatchProcessingMonitor.monitorBatchProcessing not yet implemented")
    }

    func getBatchingStatistics() async -> BatchingStatistics {
        fatalError("BatchProcessingMonitor.getBatchingStatistics not yet implemented")
    }
}

class EmbeddingConcurrencyMonitor {
    func recordTaskStart(chunkId: UUID) async {
        fatalError("EmbeddingConcurrencyMonitor.recordTaskStart not yet implemented")
    }

    func recordTaskCompletion(chunkId: UUID) async {
        fatalError("EmbeddingConcurrencyMonitor.recordTaskCompletion not yet implemented")
    }

    func recordCompletion(embedding: RegulationEmbedding) async {
        fatalError("EmbeddingConcurrencyMonitor.recordCompletion not yet implemented")
    }

    func getConcurrencyStatistics() async -> ConcurrencyStatistics {
        fatalError("EmbeddingConcurrencyMonitor.getConcurrencyStatistics not yet implemented")
    }
}

class EmbeddingMemoryMonitor {
    func monitorMemoryDuringEmbedding<T>(_ operation: () async throws -> T) async rethrows -> T {
        fatalError("EmbeddingMemoryMonitor.monitorMemoryDuringEmbedding not yet implemented")
    }

    func getMemoryMetrics() async -> MemoryMetrics {
        fatalError("EmbeddingMemoryMonitor.getMemoryMetrics not yet implemented")
    }
}

class EmbeddingErrorTracker {
    func recordSuccess(chunkId: UUID) async {
        fatalError("EmbeddingErrorTracker.recordSuccess not yet implemented")
    }

    func recordRecovery(chunkId: UUID, error: EmbeddingError) async {
        fatalError("EmbeddingErrorTracker.recordRecovery not yet implemented")
    }

    func recordFailure(chunkId: UUID, error: EmbeddingError) async {
        fatalError("EmbeddingErrorTracker.recordFailure not yet implemented")
    }

    func getErrorStatistics() async -> ErrorStatistics {
        fatalError("EmbeddingErrorTracker.getErrorStatistics not yet implemented")
    }
}

class EmbeddingQualityValidator {
    func validateEmbedding(_ embedding: RegulationEmbedding) async -> QualityReport {
        fatalError("EmbeddingQualityValidator.validateEmbedding not yet implemented")
    }

    func getQualityStatistics() async -> QualityStatistics {
        fatalError("EmbeddingQualityValidator.getQualityStatistics not yet implemented")
    }
}

// MemoryPressureLevel is imported from AIKO module
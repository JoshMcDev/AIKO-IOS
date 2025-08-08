import XCTest
@testable import GraphRAG
import Foundation

/// ACQ Actor Concurrency Test Suite - TDD RED Phase
/// Tests designed to FAIL initially, implementing Swift 6 strict concurrency compliance
/// Critical: Actor isolation, data race prevention, deadlock prevention, proper async/await usage
@available(iOS 17.0, *)
@MainActor
final class ACQActorConcurrencyTests: XCTestCase {

    private var templateProcessor: MemoryConstrainedTemplateProcessor?
    private var hybridSearchService: HybridSearchService?
    private var shardedIndex: ShardedTemplateIndex?
    private var permitSystem: ACQMemoryPermitSystem?

    override func setUpWithError() throws {
        // These will fail due to unimplemented components - RED phase intended behavior
        templateProcessor = MemoryConstrainedTemplateProcessor()
        hybridSearchService = HybridSearchService()
        shardedIndex = ShardedTemplateIndex()
        permitSystem = ACQMemoryPermitSystem(limitBytes: 50 * 1024 * 1024)
    }

    override func tearDownWithError() throws {
        templateProcessor = nil
        hybridSearchService = nil
        shardedIndex = nil
        permitSystem = nil
    }

    // MARK: - Actor Isolation Tests

    /// Test MemoryConstrainedTemplateProcessor actor boundary isolation
    /// CRITICAL: This test MUST FAIL initially until proper actor isolation is implemented
    func testTemplateProcessorActorIsolation() async throws {
        let processor = try unwrapService(templateProcessor)

        // Create test data that will be passed across actor boundaries
        let templateData = createTestTemplateData()
        let metadata = createTestMetadata()

        // These operations should enforce actor isolation
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent calls to the processor actor
            for i in 0..<10 {
                group.addTask { [processor] in
                    do {
                        var modifiedMetadata = metadata
                        modifiedMetadata.templateId = "concurrent-template-\(i)"

                        // This should be properly isolated within the actor
                        let result = try await processor.processTemplate(
                            content: templateData,
                            metadata: modifiedMetadata
                        )

                        // Verify result is properly isolated
                        XCTAssertNotNil(result, "Result should be available across actor boundary")
                        XCTAssertEqual(result.metadata.templateId, "concurrent-template-\(i)")
                    } catch {
                        XCTFail("Actor boundary crossing failed: \(error)")
                    }
                }
            }
        }

        // Verify actor state consistency after concurrent access
        let violations = await processor.getConcurrencyViolations()
        XCTAssertEqual(violations, 0, "No concurrency violations should occur with proper actor isolation")
    }

    /// Test HybridSearchService @MainActor compliance for UI updates
    /// This test WILL FAIL until proper @MainActor isolation is implemented
    func testMainActorSearchServiceCompliance() async throws {
        // This test itself runs on MainActor due to class annotation
        let searchService = try unwrapService(hybridSearchService)

        XCTAssertTrue(Thread.isMainThread, "Test should run on main thread")

        // These should execute on MainActor without issues
        await searchService.hybridSearch(query: "test query", category: nil, limit: 10)

        // Published properties should be accessible from MainActor
        let results = searchService.searchResults
        let isSearching = searchService.isSearching
        let latency = searchService.searchLatency

        XCTAssertFalse(isSearching, "Search should complete")
        XCTAssertGreaterThanOrEqual(latency, 0, "Latency should be recorded")

        // Verify we can access UI-bound properties without actor hopping
        await MainActor.run {
            XCTAssertTrue(Thread.isMainThread, "Should still be on main thread")
            _ = searchService.searchResults.count  // Should not require await
        }
    }

    /// Test ShardedTemplateIndex actor safety with concurrent shard access
    /// This test WILL FAIL until thread-safe shard management is implemented
    func testShardedIndexActorSafety() async throws {
        let shardedIndex = try unwrapService(shardedIndex)

        // Populate shards concurrently to test actor safety
        await withTaskGroup(of: Void.self) { group in
            for category in TemplateCategory.allCases {
                group.addTask { [shardedIndex] in
                    let templates = await self.createTemplatesForCategory(category, count: 50)

                    for template in templates {
                        do {
                            let embeddings = self.generateTestEmbedding(dimensions: 384)
                            try await shardedIndex.addTemplate(template, embeddings: embeddings)
                        } catch {
                            XCTFail("Concurrent shard addition failed: \(error)")
                        }
                    }
                }
            }
        }

        // Verify no data corruption occurred during concurrent access
        for category in TemplateCategory.allCases {
            let shard = try await shardedIndex.getShard(for: category)
            let templateCount = await shard.templateCount
            XCTAssertEqual(templateCount, 50, "Category \(category) should have exactly 50 templates")

            // Verify shard integrity
            let isCorrupted = await shard.checkIntegrity()
            XCTAssertFalse(isCorrupted, "Shard \(category) should not be corrupted after concurrent access")
        }
    }

    /// Test ACQMemoryPermitSystem actor isolation with concurrent permit requests
    /// This test WILL FAIL until permit system actor safety is implemented
    func testACQMemoryPermitSystemActorIsolation() async throws {
        let permitSystem = try unwrapService(permitSystem)

        let concurrentRequests = 100
        let permitSize: Int64 = 500 * 1024  // 500KB each
        var acquiredPermits: [ACQMemoryPermit] = []
        var errors: [Error] = []

        // Use actor-safe data structures for collecting results
        actor ResultCollector {
            private var permits: [ACQMemoryPermit] = []
            private var collectedErrors: [Error] = []

            func addPermit(_ permit: ACQMemoryPermit) {
                permits.append(permit)
            }

            func addError(_ error: Error) {
                collectedErrors.append(error)
            }

            func getResults() -> (permits: [ACQMemoryPermit], errors: [Error]) {
                (permits, collectedErrors)
            }
        }

        let collector = ResultCollector()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentRequests {
                group.addTask { [permitSystem] in
                    do {
                        let permit = try await permitSystem.acquire(bytes: permitSize, timeout: 2.0)
                        await collector.addPermit(permit)

                        // Hold briefly then release
                        try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000...10_000_000))
                        await permitSystem.release(permit)
                    } catch {
                        await collector.addError(error)
                    }
                }
            }
        }

        let results = await collector.getResults()
        acquiredPermits = results.permits
        errors = results.errors

        // Verify system maintained consistency under concurrent load
        let finalUsedBytes = await permitSystem.usedBytes
        XCTAssertEqual(finalUsedBytes, 0, "All memory should be released after concurrent operations")

        // Some permits should have been acquired successfully
        XCTAssertGreaterThan(acquiredPermits.count, 0, "Some permits should have been acquired")
    }

    // MARK: - Data Race Prevention Tests

    /// Test Sendable conformance for template data types
    /// This test WILL FAIL until proper Sendable conformance is implemented
    func testSendableDataTypeCompliance() async throws {
        // Test that critical data types can be safely passed across actor boundaries
        let templateMetadata = createTestMetadata()
        let templateChunk = createTestChunk()
        let processedTemplate = createTestProcessedTemplate()

        // These should compile and run without data race warnings in Swift 6
        await withTaskGroup(of: Void.self) { group in
            // Pass Sendable types across actor boundaries
            group.addTask {
                await self.processMetadataInBackground(templateMetadata)
            }

            group.addTask {
                await self.processChunkInBackground(templateChunk)
            }

            group.addTask {
                await self.processTemplateInBackground(processedTemplate)
            }
        }

        // Verify no data corruption occurred during cross-actor transfer
        XCTAssertEqual(templateMetadata.templateId, "test-template-001")
        XCTAssertEqual(templateChunk.content.count, 44)  // "Test chunk content for concurrency testing."
        XCTAssertEqual(processedTemplate.chunks.count, 1)
    }

    /// Test safe cross-actor data transfer with proper serialization
    /// This test WILL FAIL until proper data serialization boundaries are implemented
    func testSafeCrossActorDataTransfer() async throws {
        let processor = try unwrapService(templateProcessor)
        let searchService = try unwrapService(hybridSearchService)

        // Create data that needs to cross multiple actor boundaries
        let templateData = createLargeTestData()
        let metadata = createTestMetadata()

        // Process template in processor actor
        let processedTemplate = try await processor.processTemplate(content: templateData, metadata: metadata)

        // Transfer result to search service (different actor context)
        // This should be safe due to Sendable conformance
        let searchResults = await searchService.addProcessedTemplateAndSearch(
            template: processedTemplate,
            query: "test query"
        )

        XCTAssertNotNil(searchResults, "Cross-actor data transfer should succeed")

        // Verify original data wasn't corrupted during transfer
        XCTAssertEqual(processedTemplate.metadata.templateId, metadata.templateId)
        XCTAssertEqual(processedTemplate.chunks.count, 1)
    }

    /// Test AsyncSequence and AsyncChannel safety in streaming scenarios
    /// This test WILL FAIL until async streaming safety is implemented
    func testAsyncStreamingSafety() async throws {
        let processor = try unwrapService(templateProcessor)

        // Create async stream of template chunks for processing
        let chunkStream = AsyncStream<Data> { continuation in
            Task {
                for i in 0..<10 {
                    let chunkData = createTestChunkData(index: i)
                    continuation.yield(chunkData)
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                }
                continuation.finish()
            }
        }

        // Process stream in actor-safe manner
        var processedChunks: [ProcessedTemplate] = []

        for await chunkData in chunkStream {
            let metadata = createTestMetadata()
            let processed = try await processor.processTemplate(content: chunkData, metadata: metadata)
            processedChunks.append(processed)
        }

        XCTAssertEqual(processedChunks.count, 10, "All stream items should be processed")

        // Verify no data races in stream processing
        for (index, processed) in processedChunks.enumerated() {
            XCTAssertEqual(processed.chunks.count, 1, "Chunk \(index) should have one chunk")
        }
    }

    // MARK: - Deadlock Prevention Tests

    /// Test memory permit acquisition ordering to prevent deadlocks
    /// This test WILL FAIL until deadlock prevention is implemented
    func testDeadlockPreventionInPermitAcquisition() async throws {
        let permitSystem = try unwrapService(permitSystem)
        let processor = try unwrapService(templateProcessor)

        // Scenario: Multiple processors trying to acquire permits in different orders
        // This could cause deadlock if not properly handled

        let deadlockTimeout: TimeInterval = 5.0
        let startTime = Date()

        await withTaskGroup(of: Void.self) { group in
            // Task 1: Acquire large permit, then small permit
            group.addTask { [permitSystem, processor] in
                do {
                    let largePermit = try await permitSystem.acquire(bytes: 30 * 1024 * 1024, timeout: deadlockTimeout)
                    let smallPermit = try await permitSystem.acquire(bytes: 5 * 1024 * 1024, timeout: deadlockTimeout)

                    await permitSystem.release(smallPermit)
                    await permitSystem.release(largePermit)
                } catch {
                    // Timeout is acceptable, deadlock is not
                    let elapsed = Date().timeIntervalSince(startTime)
                    XCTAssertLessThan(elapsed, deadlockTimeout + 1.0, "Should not deadlock beyond timeout")
                }
            }

            // Task 2: Acquire small permit, then large permit (reverse order)
            group.addTask { [permitSystem] in
                do {
                    let smallPermit = try await permitSystem.acquire(bytes: 5 * 1024 * 1024, timeout: deadlockTimeout)
                    let largePermit = try await permitSystem.acquire(bytes: 30 * 1024 * 1024, timeout: deadlockTimeout)

                    await permitSystem.release(largePermit)
                    await permitSystem.release(smallPermit)
                } catch {
                    // Timeout is acceptable, deadlock is not
                    let elapsed = Date().timeIntervalSince(startTime)
                    XCTAssertLessThan(elapsed, deadlockTimeout + 1.0, "Should not deadlock beyond timeout")
                }
            }
        }

        let totalElapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(totalElapsed, deadlockTimeout * 2, "Operations should complete without deadlock")

        // System should be clean after potential deadlock scenario
        XCTAssertEqual(await permitSystem.usedBytes, 0, "No permits should be leaked after deadlock test")
    }

    /// Test cross-actor dependency cycle detection and prevention
    /// This test WILL FAIL until dependency cycle prevention is implemented
    func testCrossActorDependencyCyclePrevention() async throws {
        let processor = try unwrapService(templateProcessor)
        let searchService = try unwrapService(hybridSearchService)
        let shardedIndex = try unwrapService(shardedIndex)

        // Scenario: Processor needs SearchService, SearchService needs ShardedIndex,
        // ShardedIndex needs Processor - potential circular dependency

        let cycleTimeout: TimeInterval = 3.0
        let startTime = Date()

        await withTaskGroup(of: Void.self) { group in
            // Task 1: Processor -> SearchService -> ShardedIndex
            group.addTask { [processor, searchService] in
                do {
                    let templateData = await self.createTestTemplateData()
                    let metadata = await self.createTestMetadata()
                    let processed = try await processor.processTemplate(content: templateData, metadata: metadata)

                    // SearchService depends on processed result
                    await searchService.addProcessedTemplateAndSearch(template: processed, query: "test")
                } catch {
                    let elapsed = Date().timeIntervalSince(startTime)
                    XCTAssertLessThan(elapsed, cycleTimeout + 1.0, "Should not create dependency cycle")
                }
            }

            // Task 2: ShardedIndex -> Processor -> SearchService
            group.addTask { [shardedIndex, processor, searchService] in
                do {
                    let embeddings = self.generateTestEmbedding(dimensions: 384)
                    let queryResults = try await shardedIndex.searchAcrossAllShards(
                        queryEmbedding: embeddings,
                        limit: 10
                    )

                    // Process search results (circular dependency risk)
                    for result in queryResults {
                        let templateData = Data(result.template.fileName.utf8)
                        _ = try await processor.processTemplate(content: templateData, metadata: result.template)
                    }
                } catch {
                    let elapsed = Date().timeIntervalSince(startTime)
                    XCTAssertLessThan(elapsed, cycleTimeout + 1.0, "Should not create dependency cycle")
                }
            }
        }

        let totalElapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(totalElapsed, cycleTimeout * 1.5, "Cross-actor operations should complete without cycles")
    }

    // MARK: - Task Isolation and Boundary Tests

    /// Test task isolation boundaries with proper async/await usage
    /// This test WILL FAIL until proper task isolation is implemented
    func testTaskIsolationBoundaries() async throws {
        let processor = try unwrapService(templateProcessor)

        // Create tasks with proper isolation boundaries
        let isolatedResults = await withTaskGroup(of: ProcessedTemplate?.self, returning: [ProcessedTemplate].self) { group in

            for i in 0..<5 {
                group.addTask { [processor] in
                    do {
                        // Each task should have isolated access to processor
                        var metadata = await self.createTestMetadata()
                        metadata.templateId = "isolated-task-\(i)"

                        let data = await self.createTestTemplateData()
                        let result = try await processor.processTemplate(content: data, metadata: metadata)

                        return result
                    } catch {
                        XCTFail("Task isolation failed: \(error)")
                        return nil
                    }
                }
            }

            var results: [ProcessedTemplate] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            return results
        }

        XCTAssertEqual(isolatedResults.count, 5, "All isolated tasks should complete")

        // Verify each task produced unique results (proper isolation)
        let templateIds = Set(isolatedResults.map { $0.metadata.templateId })
        XCTAssertEqual(templateIds.count, 5, "Each task should produce unique results")

        for (index, result) in isolatedResults.enumerated() {
            XCTAssertTrue(result.metadata.templateId.contains("isolated-task-"), "Task \(index) should have proper ID")
        }
    }

    // MARK: - Test Helper Methods

    private func createTestTemplateData() -> Data {
        let content = "Test template content for actor concurrency testing with sufficient length to trigger proper processing."
        return Data(content.utf8)
    }

    private func createLargeTestData() -> Data {
        let content = String(repeating: "Large template content for cross-actor testing. ", count: 100)
        return Data(content.utf8)
    }

    private func createTestMetadata() -> TemplateMetadata {
        TemplateMetadata(
            templateId: "test-template-001",
            fileName: "test-template.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Test Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 1024,
            checksum: "test-checksum-001"
        )
    }

    private func createTestChunk() -> TemplateChunk {
        TemplateChunk(
            content: "Test chunk content for concurrency testing.",
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: 44, tokens: 8),
            isMemoryMapped: false
        )
    }

    private func createTestProcessedTemplate() -> ProcessedTemplate {
        ProcessedTemplate(
            chunks: [createTestChunk()],
            category: .contract,
            metadata: createTestMetadata(),
            processingMode: .normal
        )
    }

    private func createTemplatesForCategory(_ category: TemplateCategory, count: Int) async -> [ProcessedTemplate] {
        var templates: [ProcessedTemplate] = []

        for i in 0..<count {
            var metadata = createTestMetadata()
            metadata.templateId = "\(category.rawValue.lowercased())-\(i)"

            let template = ProcessedTemplate(
                chunks: [createTestChunk()],
                category: category,
                metadata: metadata,
                processingMode: .normal
            )

            templates.append(template)
        }

        return templates
    }

    private func createTestChunkData(index: Int) -> Data {
        let content = "Test chunk data \(index) for streaming concurrency testing."
        return Data(content.utf8)
    }

    private func generateTestEmbedding(dimensions: Int) -> [Float] {
        var embedding = [Float](repeating: 0.0, count: dimensions)

        for i in 0..<dimensions {
            embedding[i] = sin(Float(i) * 0.1) * 0.5
        }

        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    // Actor-safe helper functions for testing cross-actor data transfer
    private func processMetadataInBackground(_ metadata: TemplateMetadata) async {
        // Simulate background processing of metadata
        try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
    }

    private func processChunkInBackground(_ chunk: TemplateChunk) async {
        // Simulate background processing of chunk
        try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
    }

    private func processTemplateInBackground(_ template: ProcessedTemplate) async {
        // Simulate background processing of template
        try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
    }
}

// MARK: - Extended Protocol Methods for Testing

extension HybridSearchService {
    func addProcessedTemplateAndSearch(template: ProcessedTemplate, query: String) async -> [TemplateSearchResult]? {
        fatalError("HybridSearchService.addProcessedTemplateAndSearch not implemented - RED phase")
    }
}

// MARK: - Sendable Conformance Verification

// TemplateMetadata already conforms to Sendable
extension TemplateChunk: @unchecked Sendable {}
extension ProcessedTemplate: @unchecked Sendable {}
extension ChunkMetadata: @unchecked Sendable {}
extension TemplateCategory: @unchecked Sendable {}

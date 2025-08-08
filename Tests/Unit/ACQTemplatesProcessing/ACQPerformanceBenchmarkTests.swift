import XCTest
@testable import GraphRAG
import Foundation

/// ACQ Performance Benchmark Test Suite - TDD RED Phase
/// Tests designed to FAIL initially, implementing comprehensive performance validation
/// Critical targets: <10ms P50 search, <3min processing, <50MB memory usage
@available(iOS 17.0, *)
final class ACQPerformanceBenchmarkTests: XCTestCase {

    private var templateProcessor: MemoryConstrainedTemplateProcessor?
    private var hybridSearchService: HybridSearchService?
    private var lfm2Service: LFM2Service?
    private var objectBoxIndex: ObjectBoxSemanticIndex?
    private var performanceMonitor: PerformanceMonitor?

    // Critical performance targets from rubric
    private let searchP50TargetMs: Double = 10.0
    private let searchP95TargetMs: Double = 20.0
    private let searchP99TargetMs: Double = 50.0
    private let processingTimeTargetMinutes: Double = 3.0
    private let embeddingGenerationTargetSeconds: Double = 2.0
    private let memoryLimitBytes: Int64 = 50 * 1024 * 1024
    private let datasetSizeBytes: Int64 = 256 * 1024 * 1024

    override func setUpWithError() throws {
        // These will fail due to unimplemented components - RED phase intended behavior
        templateProcessor = MemoryConstrainedTemplateProcessor()
        hybridSearchService = HybridSearchService()
        lfm2Service = LFM2Service.shared
        objectBoxIndex = ObjectBoxSemanticIndex.shared
        performanceMonitor = PerformanceMonitor()
    }

    override func tearDownWithError() throws {
        performanceMonitor = nil
        objectBoxIndex = nil
        lfm2Service = nil
        hybridSearchService = nil
        templateProcessor = nil
    }

    // MARK: - Search Performance Benchmarks

    /// Benchmark P50 search latency must be <10ms under realistic load
    /// CRITICAL: This test MUST FAIL initially until search optimization is implemented
    
    func testSearchP50LatencyBenchmark() async throws {
        let searchService = try unwrapService(hybridSearchService)
        let monitor = try unwrapService(performanceMonitor)

        // Setup realistic search index
        try await populateRealisticSearchIndex(templateCount: 5000)

        // Warm up search system
        await searchService.hybridSearch(query: "warmup query", category: nil, limit: 5)

        await monitor.startBenchmark("search_p50_latency")

        var searchLatencies: [TimeInterval] = []
        let benchmarkQueries = generateBenchmarkQueries()

        // Execute benchmark searches with realistic patterns
        for query in benchmarkQueries {
            let startTime = CFAbsoluteTimeGetCurrent()

            await searchService.hybridSearch(
                query: query,
                category: randomCategory(),
                limit: 10
            )

            let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000  // Convert to ms
            searchLatencies.append(latency)
        }

        let benchmarkResults = await monitor.stopBenchmark("search_p50_latency")

        // Calculate performance percentiles
        let sortedLatencies = searchLatencies.sorted()
        let p50Index = sortedLatencies.count / 2
        let p50Latency = sortedLatencies[p50Index]

        let p95Index = Int(Double(sortedLatencies.count) * 0.95)
        let p95Latency = sortedLatencies[p95Index]

        let p99Index = Int(Double(sortedLatencies.count) * 0.99)
        let p99Latency = sortedLatencies[p99Index]

        // Record detailed metrics
        await monitor.recordMetrics([
            "p50_latency_ms": p50Latency,
            "p95_latency_ms": p95Latency,
            "p99_latency_ms": p99Latency,
            "avg_latency_ms": searchLatencies.reduce(0, +) / Double(searchLatencies.count),
            "max_latency_ms": searchLatencies.max() ?? 0
        ])

        // Assert performance targets
        XCTAssertLessThan(p50Latency, searchP50TargetMs,
                         "P50 search latency exceeded target: \(p50Latency)ms > \(searchP50TargetMs)ms")
        XCTAssertLessThan(p95Latency, searchP95TargetMs,
                         "P95 search latency exceeded target: \(p95Latency)ms > \(searchP95TargetMs)ms")
        XCTAssertLessThan(p99Latency, searchP99TargetMs,
                         "P99 search latency exceeded target: \(p99Latency)ms > \(searchP99TargetMs)ms")
    }

    /// Benchmark concurrent search performance with 10+ simultaneous users
    /// This test WILL FAIL until optimized concurrent search is implemented
    
    func testConcurrentSearchThroughputBenchmark() async throws {
        let searchService = try unwrapService(hybridSearchService)
        let monitor = try unwrapService(performanceMonitor)

        try await populateRealisticSearchIndex(templateCount: 10000)

        let concurrentUsers = 15
        let queriesPerUser = 10

        await monitor.startBenchmark("concurrent_search_throughput")
        let benchmarkStartTime = CFAbsoluteTimeGetCurrent()

        await withTaskGroup(of: [TimeInterval].self) { group in
            for userId in 0..<concurrentUsers {
                group.addTask { [searchService] in
                    var userLatencies: [TimeInterval] = []

                    for queryIndex in 0..<queriesPerUser {
                        let query = "concurrent user \(userId) query \(queryIndex)"
                        let startTime = CFAbsoluteTimeGetCurrent()

                        await searchService.hybridSearch(
                            query: query,
                            category: nil,
                            limit: 10
                        )

                        let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                        userLatencies.append(latency)
                    }

                    return userLatencies
                }
            }

            var allLatencies: [TimeInterval] = []
            for await userLatencies in group {
                allLatencies.append(contentsOf: userLatencies)
            }

            let totalBenchmarkTime = CFAbsoluteTimeGetCurrent() - benchmarkStartTime
            let totalQueries = concurrentUsers * queriesPerUser
            let throughput = Double(totalQueries) / totalBenchmarkTime  // Queries per second

            await monitor.recordMetrics([
                "concurrent_users": Double(concurrentUsers),
                "total_queries": Double(totalQueries),
                "benchmark_duration_s": totalBenchmarkTime,
                "throughput_qps": throughput,
                "avg_concurrent_latency_ms": allLatencies.reduce(0, +) / Double(allLatencies.count)
            ])

            // Performance assertions for concurrent load
            XCTAssertGreaterThan(throughput, 50.0, "Concurrent throughput should exceed 50 QPS")

            let avgLatency = allLatencies.reduce(0, +) / Double(allLatencies.count)
            XCTAssertLessThan(avgLatency, searchP50TargetMs * 2,
                             "Average concurrent latency should be reasonable: \(avgLatency)ms")
        }

        await monitor.stopBenchmark("concurrent_search_throughput")
    }

    // MARK: - Template Processing Performance Benchmarks

    /// Benchmark complete 256MB dataset processing in <3 minutes
    /// This test WILL FAIL until optimized processing pipeline is implemented
    
    func testFullDatasetProcessingBenchmark() async throws {
        let processor = try unwrapService(templateProcessor)
        let monitor = try unwrapService(performanceMonitor)

        await monitor.startBenchmark("full_dataset_processing")
        let processingStartTime = CFAbsoluteTimeGetCurrent()

        // Generate 256MB dataset with realistic templates
        let largeDataset = generateLargeRealisticDataset(targetSize: datasetSizeBytes)
        let totalTemplates = largeDataset.count

        var processedCount = 0
        var totalChunks = 0
        var processingTimes: [TimeInterval] = []

        // Process each template with memory monitoring
        for template in largeDataset {
            let templateStartTime = CFAbsoluteTimeGetCurrent()

            let result = try await processor.processTemplate(
                content: template.data,
                metadata: template.metadata
            )

            let templateTime = CFAbsoluteTimeGetCurrent() - templateStartTime
            processingTimes.append(templateTime)

            processedCount += 1
            totalChunks += result.chunks.count

            // Periodic progress and memory checks
            if processedCount % 10 == 0 {
                let memoryUsage = await monitor.getCurrentMemoryUsage()
                XCTAssertLessThanOrEqual(memoryUsage, memoryLimitBytes,
                                        "Memory limit exceeded during processing: \(memoryUsage)")

                await monitor.recordMetrics([
                    "processed_templates": Double(processedCount),
                    "current_memory_mb": Double(memoryUsage) / (1024 * 1024),
                    "avg_template_time_s": processingTimes.reduce(0, +) / Double(processingTimes.count)
                ])
            }
        }

        let totalProcessingTime = CFAbsoluteTimeGetCurrent() - processingStartTime
        let processingTimeMinutes = totalProcessingTime / 60.0

        await monitor.recordMetrics([
            "total_processing_time_minutes": processingTimeMinutes,
            "templates_processed": Double(totalTemplates),
            "chunks_generated": Double(totalChunks),
            "avg_template_processing_s": processingTimes.reduce(0, +) / Double(processingTimes.count),
            "processing_throughput_templates_per_minute": Double(totalTemplates) / processingTimeMinutes
        ])

        await monitor.stopBenchmark("full_dataset_processing")

        // Assert processing time target
        XCTAssertLessThan(processingTimeMinutes, processingTimeTargetMinutes,
                         "Processing time exceeded target: \(processingTimeMinutes) minutes > \(processingTimeTargetMinutes) minutes")

        // Verify processing quality
        XCTAssertEqual(processedCount, totalTemplates, "All templates should be processed")
        XCTAssertGreaterThan(totalChunks, totalTemplates, "Should generate multiple chunks for large templates")
    }

    /// Benchmark embedding generation performance with LFM2Service
    /// This test WILL FAIL until optimized embedding generation is implemented
    
    func testEmbeddingGenerationSpeedBenchmark() async throws {
        let lfm2Service = try unwrapService(lfm2Service)
        let monitor = try unwrapService(performanceMonitor)

        await monitor.startBenchmark("embedding_generation_speed")

        // Test with various chunk sizes typical of templates
        let testChunks = [
            createChunkContent(tokenCount: 128),   // Small chunk
            createChunkContent(tokenCount: 256),   // Medium chunk
            createChunkContent(tokenCount: 512),   // Large chunk (target size)
            createChunkContent(tokenCount: 1024)   // Extra large chunk
        ]

        var embeddingTimes: [String: [TimeInterval]] = [:]

        for (index, chunk) in testChunks.enumerated() {
            let chunkSize = "chunk_\(chunk.split(separator: " ").count)_tokens"
            embeddingTimes[chunkSize] = []

            // Generate embeddings multiple times for statistical significance
            for iteration in 0..<10 {
                let startTime = CFAbsoluteTimeGetCurrent()

                let embedding = try await lfm2Service.generateEmbedding(for: chunk)

                let generationTime = CFAbsoluteTimeGetCurrent() - startTime
                embeddingTimes[chunkSize]?.append(generationTime)

                // Verify embedding quality
                XCTAssertEqual(embedding.count, 384, "Should generate 384-dimensional embeddings")
                XCTAssertTrue(isEmbeddingNormalized(embedding), "Embedding should be L2 normalized")
            }
        }

        // Calculate and record metrics for each chunk size
        for (chunkSize, times) in embeddingTimes {
            let avgTime = times.reduce(0, +) / Double(times.count)
            let maxTime = times.max() ?? 0

            await monitor.recordMetrics([
                "\(chunkSize)_avg_time_s": avgTime,
                "\(chunkSize)_max_time_s": maxTime,
                "\(chunkSize)_throughput_per_minute": 60.0 / avgTime
            ])

            // Assert performance target for 512-token chunks (typical size)
            if chunkSize.contains("512") {
                XCTAssertLessThan(avgTime, embeddingGenerationTargetSeconds,
                                 "Embedding generation too slow for 512-token chunks: \(avgTime)s > \(embeddingGenerationTargetSeconds)s")
            }
        }

        await monitor.stopBenchmark("embedding_generation_speed")
    }

    /// Benchmark ObjectBox storage and retrieval performance
    /// This test WILL FAIL until optimized ObjectBox operations are implemented
    
    func testObjectBoxStoragePerformanceBenchmark() async throws {
        let objectBoxIndex = try unwrapService(objectBoxIndex)
        let monitor = try unwrapService(performanceMonitor)

        await monitor.startBenchmark("objectbox_storage_performance")

        let embeddingCount = 1000
        let embeddingDimensions = 384
        let batchSizes = [1, 10, 50, 100]

        // Test different batch sizes for optimal performance
        for batchSize in batchSizes {
            let batchMetrics = "batch_size_\(batchSize)"
            var storeTimes: [TimeInterval] = []
            var retrieveTimes: [TimeInterval] = []

            let batches = embeddingCount / batchSize

            for batchIndex in 0..<batches {
                var embeddings: [(String, [Float], TemplateMetadata)] = []

                // Prepare batch
                for i in 0..<batchSize {
                    let embeddingId = "batch_\(batchSize)_item_\(batchIndex * batchSize + i)"
                    let embedding = generateRealisticEmbedding(dimensions: embeddingDimensions)
                    let metadata = createBenchmarkMetadata(id: embeddingId)

                    embeddings.append((embeddingId, embedding, metadata))
                }

                // Benchmark storage
                let storeStartTime = CFAbsoluteTimeGetCurrent()

                for (id, embedding, metadata) in embeddings {
                    try await objectBoxIndex.storeTemplateEmbedding(
                        content: "Benchmark content for \(id)",
                        embedding: embedding,
                        metadata: metadata
                    )
                }

                let storeTime = CFAbsoluteTimeGetCurrent() - storeStartTime
                storeTimes.append(storeTime)

                // Benchmark retrieval
                let retrieveStartTime = CFAbsoluteTimeGetCurrent()

                for (id, _, _) in embeddings {
                    _ = try await objectBoxIndex.findSimilar(
                        to: generateRealisticEmbedding(dimensions: embeddingDimensions),
                        limit: 5,
                        namespace: "templates"
                    )
                }

                let retrieveTime = CFAbsoluteTimeGetCurrent() - retrieveStartTime
                retrieveTimes.append(retrieveTime)
            }

            // Calculate metrics for this batch size
            let avgStoreTime = storeTimes.reduce(0, +) / Double(storeTimes.count)
            let avgRetrieveTime = retrieveTimes.reduce(0, +) / Double(retrieveTimes.count)

            await monitor.recordMetrics([
                "\(batchMetrics)_avg_store_time_s": avgStoreTime,
                "\(batchMetrics)_avg_retrieve_time_s": avgRetrieveTime,
                "\(batchMetrics)_store_throughput_per_s": Double(batchSize) / avgStoreTime,
                "\(batchMetrics)_retrieve_throughput_per_s": Double(batchSize) / avgRetrieveTime
            ])

            // Assert storage performance targets
            let storeLatencyPerItem = avgStoreTime / Double(batchSize)
            XCTAssertLessThan(storeLatencyPerItem, 0.05, "Storage per item should be <50ms")
        }

        await monitor.stopBenchmark("objectbox_storage_performance")
    }

    // MARK: - Memory Usage Benchmarks

    /// Benchmark memory usage patterns during full processing pipeline
    /// This test WILL FAIL until memory-efficient processing is implemented
    
    func testMemoryUsagePatternBenchmark() async throws {
        let processor = try unwrapService(templateProcessor)
        let searchService = try unwrapService(hybridSearchService)
        let monitor = try unwrapService(performanceMonitor)

        await monitor.startBenchmark("memory_usage_patterns")
        await monitor.startMemoryMonitoring(interval: 0.1)  // Sample every 100ms

        // Baseline memory usage
        let baselineMemory = await monitor.getCurrentMemoryUsage()

        // Phase 1: Template processing
        let testDataset = generateMemoryTestDataset(templateCount: 100)

        for (index, template) in testDataset.enumerated() {
            _ = try await processor.processTemplate(content: template.data, metadata: template.metadata)

            if index % 10 == 0 {
                let currentMemory = await monitor.getCurrentMemoryUsage()
                await monitor.recordMetric("processing_memory_mb_at_\(index)", Double(currentMemory) / (1024 * 1024))
            }
        }

        let postProcessingMemory = await monitor.getCurrentMemoryUsage()

        // Phase 2: Search operations
        for i in 0..<50 {
            await searchService.hybridSearch(query: "memory test query \(i)", category: nil, limit: 10)

            if i % 10 == 0 {
                let currentMemory = await monitor.getCurrentMemoryUsage()
                await monitor.recordMetric("search_memory_mb_at_\(i)", Double(currentMemory) / (1024 * 1024))
            }
        }

        let postSearchMemory = await monitor.getCurrentMemoryUsage()

        // Cleanup phase
        await processor.performMemoryCleanup()
        await searchService.clearAllCaches()

        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool {
                _ = Data(count: 1024 * 1024)  // Trigger GC
            }
        }

        try await Task.sleep(nanoseconds: 500_000_000)  // 500ms for cleanup

        let postCleanupMemory = await monitor.getCurrentMemoryUsage()
        let memoryPattern = await monitor.stopMemoryMonitoring()

        await monitor.recordMetrics([
            "baseline_memory_mb": Double(baselineMemory) / (1024 * 1024),
            "post_processing_memory_mb": Double(postProcessingMemory) / (1024 * 1024),
            "post_search_memory_mb": Double(postSearchMemory) / (1024 * 1024),
            "post_cleanup_memory_mb": Double(postCleanupMemory) / (1024 * 1024),
            "peak_memory_mb": Double(memoryPattern.peakUsage) / (1024 * 1024),
            "memory_growth_mb": Double(postSearchMemory - baselineMemory) / (1024 * 1024),
            "cleanup_efficiency_pct": Double(postSearchMemory - postCleanupMemory) / Double(postSearchMemory) * 100
        ])

        await monitor.stopBenchmark("memory_usage_patterns")

        // Assert memory usage targets
        XCTAssertLessThanOrEqual(memoryPattern.peakUsage, memoryLimitBytes,
                                "Peak memory should not exceed limit: \(memoryPattern.peakUsage)")

        let memoryGrowth = postSearchMemory - baselineMemory
        XCTAssertLessThan(memoryGrowth, 30 * 1024 * 1024,
                         "Memory growth should be reasonable: \(memoryGrowth) bytes")

        let cleanupEfficiency = Double(postSearchMemory - postCleanupMemory) / Double(postSearchMemory)
        XCTAssertGreaterThan(cleanupEfficiency, 0.8,
                           "Cleanup should be efficient: \(cleanupEfficiency * 100)%")
    }

    // MARK: - Cross-Platform Performance Benchmarks

    /// Benchmark performance consistency between iOS and macOS
    /// This test WILL FAIL until cross-platform optimization is implemented
    
    func testCrossPlatformConsistencyBenchmark() async throws {
        let searchService = try unwrapService(hybridSearchService)
        let lfm2Service = try unwrapService(lfm2Service)
        let monitor = try unwrapService(performanceMonitor)

        await monitor.startBenchmark("cross_platform_consistency")

        let platformInfo = await monitor.getPlatformInfo()

        // Benchmark search performance
        try await populateRealisticSearchIndex(templateCount: 1000)

        var searchLatencies: [TimeInterval] = []
        let testQueries = generateBenchmarkQueries().prefix(20)

        for query in testQueries {
            let startTime = CFAbsoluteTimeGetCurrent()
            await searchService.hybridSearch(query: query, category: nil, limit: 10)
            let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            searchLatencies.append(latency)
        }

        let avgSearchLatency = searchLatencies.reduce(0, +) / Double(searchLatencies.count)

        // Benchmark embedding generation
        var embeddingLatencies: [TimeInterval] = []
        let testContent = createChunkContent(tokenCount: 512)

        for _ in 0..<10 {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await lfm2Service.generateEmbedding(for: testContent)
            let latency = CFAbsoluteTimeGetCurrent() - startTime
            embeddingLatencies.append(latency)
        }

        let avgEmbeddingLatency = embeddingLatencies.reduce(0, +) / Double(embeddingLatencies.count)

        await monitor.recordMetrics([
            "platform": platformInfo.platform,
            "cpu_architecture": platformInfo.architecture,
            "avg_search_latency_ms": avgSearchLatency,
            "avg_embedding_latency_s": avgEmbeddingLatency,
            "search_p95_latency_ms": searchLatencies.sorted()[Int(Double(searchLatencies.count) * 0.95)],
            "embedding_throughput_per_minute": 60.0 / avgEmbeddingLatency
        ])

        await monitor.stopBenchmark("cross_platform_consistency")

        // Platform-specific performance expectations
        #if os(macOS)
        XCTAssertLessThan(avgSearchLatency, searchP50TargetMs * 0.8, "macOS should have faster search")
        XCTAssertLessThan(avgEmbeddingLatency, embeddingGenerationTargetSeconds * 0.7, "macOS should have faster embedding generation")
        #else
        XCTAssertLessThan(avgSearchLatency, searchP50TargetMs, "iOS should meet search targets")
        XCTAssertLessThan(avgEmbeddingLatency, embeddingGenerationTargetSeconds, "iOS should meet embedding targets")
        #endif
    }

    // MARK: - Test Helper Methods

    private func populateRealisticSearchIndex(templateCount: Int) async throws {
        let searchService = try unwrapService(hybridSearchService)
        let templates = generateRealisticTemplates(count: templateCount)

        for template in templates {
            try await searchService.addTemplate(template)
        }
    }

    private func generateBenchmarkQueries() -> [String] {
        [
            "software development contract requirements",
            "IT services statement of work deliverables",
            "cybersecurity compliance standards",
            "cloud infrastructure management services",
            "data analytics platform development",
            "enterprise system integration project",
            "professional consulting services agreement",
            "technical support maintenance contract",
            "project management methodology framework",
            "quality assurance testing procedures"
        ]
    }

    private func generateRealisticTemplates(count: Int) -> [ProcessedTemplate] {
        var templates: [ProcessedTemplate] = []

        for i in 0..<count {
            let category = TemplateCategory.allCases[i % TemplateCategory.allCases.count]
            let content = generateRealisticTemplateContent(category: category, index: i)

            let chunk = TemplateChunk(
                content: content,
                chunkIndex: 0,
                overlap: "",
                metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
                isMemoryMapped: false
            )

            let metadata = TemplateMetadata(
                templateId: "benchmark-template-\(i)",
                fileName: "benchmark-\(i).pdf",
                fileType: "PDF",
                category: category,
                agency: "Benchmark Agency",
                effectiveDate: Date(),
                lastModified: Date(),
                fileSize: Int64(content.utf8.count),
                checksum: "benchmark-checksum-\(i)"
            )

            let template = ProcessedTemplate(
                chunks: [chunk],
                category: category,
                metadata: metadata,
                processingMode: .normal
            )

            templates.append(template)
        }

        return templates
    }

    private func generateRealisticTemplateContent(category: TemplateCategory, index: Int) -> String {
        let baseContent: String

        switch category {
        case .contract:
            baseContent = "COMPREHENSIVE SOFTWARE DEVELOPMENT CONTRACT for Enterprise-Grade Systems. This agreement establishes the terms and conditions for professional software development services including requirements analysis, system architecture design, implementation using modern frameworks, comprehensive testing procedures, and ongoing maintenance support. The contractor shall provide qualified personnel with appropriate security clearances and technical expertise in cloud computing, artificial intelligence, machine learning, and cybersecurity domains."

        case .statementOfWork:
            baseContent = "STATEMENT OF WORK for IT Infrastructure Modernization Project. This SOW defines specific deliverables, timelines, and performance metrics for modernizing legacy systems, implementing cloud-native architectures, establishing DevOps pipelines, and ensuring seamless data migration. Key components include microservices architecture, containerization strategies, automated testing frameworks, monitoring and logging systems, and comprehensive documentation."

        case .form:
            baseContent = "TECHNICAL EVALUATION FORM for Vendor Assessment and Selection. This form provides structured criteria for evaluating technical proposals including solution architecture, development methodology, team qualifications, past performance metrics, security compliance, scalability considerations, and cost-effectiveness. Evaluation factors include innovation index, risk assessment, implementation timeline feasibility, and long-term maintenance capabilities."

        case .clause:
            baseContent = "STANDARD CONTRACT CLAUSE addressing Intellectual Property Rights, Data Security Requirements, and Federal Acquisition Regulation Compliance. This clause establishes ownership rights for developed software, source code, documentation, and derivative works. Security provisions include data encryption standards, access control mechanisms, audit trail requirements, and incident response procedures compliant with government security frameworks."

        case .guide:
            baseContent = "PROCUREMENT BEST PRACTICES GUIDE for Government Technology Acquisitions. This comprehensive guide covers acquisition planning strategies, market research methodologies, vendor evaluation criteria, contract negotiation techniques, and performance management frameworks. Topics include Agile development practices, cloud security considerations, API integration standards, and emerging technology assessment procedures."
        }

        let technicalDetails = [
            "Implementation shall utilize modern programming languages including Swift, Python, Java, and JavaScript with emphasis on scalable architecture patterns.",
            "System requirements include compatibility with iOS 17+, macOS 14+, cloud deployment capabilities, and enterprise security standards.",
            "Performance specifications mandate sub-second response times, 99.9% uptime availability, and horizontal scaling to support 10,000+ concurrent users.",
            "Integration capabilities must support RESTful APIs, GraphQL endpoints, message queuing systems, and real-time data streaming protocols.",
            "Security framework requires end-to-end encryption, multi-factor authentication, role-based access controls, and comprehensive audit logging.",
            "Testing procedures include unit testing with 90%+ coverage, integration testing, performance testing, and security vulnerability assessments.",
            "Documentation requirements encompass technical specifications, user manuals, API documentation, and system administration guides.",
            "Compliance standards include SOC 2 Type II certification, FISMA authorization, and adherence to NIST cybersecurity framework.",
            "Data management protocols specify encryption at rest and in transit, data retention policies, backup procedures, and disaster recovery plans.",
            "Quality assurance measures include automated testing pipelines, code review processes, security scanning, and performance monitoring systems."
        ]

        let selectedDetails = technicalDetails.shuffled().prefix(3).joined(separator: " ")

        return "\(baseContent) \(selectedDetails) Document reference: BENCHMARK-\(category.rawValue.uppercased())-\(String(format: "%04d", index))"
    }

    private func generateLargeRealisticDataset(targetSize: Int64) -> [(data: Data, metadata: TemplateMetadata)] {
        var dataset: [(Data, TemplateMetadata)] = []
        var currentSize: Int64 = 0
        var templateIndex = 0

        while currentSize < targetSize {
            let category = TemplateCategory.allCases[templateIndex % TemplateCategory.allCases.count]
            let content = generateRealisticTemplateContent(category: category, index: templateIndex)

            // Add additional content to reach realistic document sizes
            let expandedContent = content + String(repeating: "\n\nAdditional technical specifications and requirements. Detailed implementation guidelines and compliance standards. Comprehensive quality assurance procedures and testing methodologies. ", count: 50)

            let data = Data(expandedContent.utf8)
            let metadata = TemplateMetadata(
                templateId: "large-dataset-template-\(templateIndex)",
                fileName: "large-template-\(templateIndex).pdf",
                fileType: "PDF",
                category: category,
                agency: "Large Dataset Agency",
                effectiveDate: Date(),
                lastModified: Date(),
                fileSize: Int64(data.count),
                checksum: "large-checksum-\(templateIndex)"
            )

            dataset.append((data, metadata))
            currentSize += Int64(data.count)
            templateIndex += 1
        }

        return dataset
    }

    private func generateMemoryTestDataset(templateCount: Int) -> [(data: Data, metadata: TemplateMetadata)] {
        var dataset: [(Data, TemplateMetadata)] = []

        for i in 0..<templateCount {
            let content = "Memory test template \(i) with substantial content to trigger memory management. " +
                         String(repeating: "Additional content for memory testing purposes. ", count: 100)

            let data = Data(content.utf8)
            let metadata = TemplateMetadata(
                templateId: "memory-test-\(i)",
                fileName: "memory-test-\(i).pdf",
                fileType: "PDF",
                category: .contract,
                agency: "Memory Test Agency",
                effectiveDate: Date(),
                lastModified: Date(),
                fileSize: Int64(data.count),
                checksum: "memory-checksum-\(i)"
            )

            dataset.append((data, metadata))
        }

        return dataset
    }

    private func createChunkContent(tokenCount: Int) -> String {
        let words = ["software", "development", "contract", "requirements", "implementation", "testing", "deployment", "maintenance", "security", "compliance", "performance", "scalability", "architecture", "integration", "documentation", "quality", "standards", "procedures", "guidelines", "specifications"]

        var content = ""
        for i in 0..<tokenCount {
            content += words[i % words.count]
            if i < tokenCount - 1 {
                content += " "
            }
        }

        return content
    }

    private func generateRealisticEmbedding(dimensions: Int) -> [Float] {
        var embedding = [Float](repeating: 0.0, count: dimensions)

        for i in 0..<dimensions {
            embedding[i] = Float.random(in: -1.0...1.0) * 0.1
        }

        // L2 normalize
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    private func createBenchmarkMetadata(id: String) -> TemplateMetadata {
        TemplateMetadata(
            templateId: id,
            fileName: "\(id).pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Benchmark Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 1024,
            checksum: "benchmark-\(id)"
        )
    }

    private func isEmbeddingNormalized(_ embedding: [Float]) -> Bool {
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        return abs(magnitude - 1.0) < 0.001
    }

    private func randomCategory() -> TemplateCategory? {
        Int.random(in: 0...5) == 0 ? nil : TemplateCategory.allCases.randomElement()
    }
}

// MARK: - Supporting Types (Will fail until implemented)

struct PlatformInfo {
    let platform: String
    let architecture: String
    let processorCount: Int
    let memorySize: Int64
}

struct MemoryPattern {
    let peakUsage: Int64
    let averageUsage: Int64
    let samplesCount: Int
    let patterns: [MemorySample]
}

struct MemorySample {
    let timestamp: Date
    let usage: Int64
    let phase: String
}

// Performance monitoring infrastructure - will fail until implemented
class PerformanceMonitor {
    private var benchmarks: [String: BenchmarkSession] = [:]
    private var metrics: [String: Double] = [:]

    func startBenchmark(_ name: String) async {
        fatalError("PerformanceMonitor.startBenchmark not implemented - RED phase")
    }

    func stopBenchmark(_ name: String) async -> BenchmarkResults {
        fatalError("PerformanceMonitor.stopBenchmark not implemented - RED phase")
    }

    func recordMetrics(_ metrics: [String: Double]) async {
        fatalError("PerformanceMonitor.recordMetrics not implemented - RED phase")
    }

    func recordMetric(_ name: String, _ value: Double) async {
        fatalError("PerformanceMonitor.recordMetric not implemented - RED phase")
    }

    func getCurrentMemoryUsage() async -> Int64 {
        fatalError("PerformanceMonitor.getCurrentMemoryUsage not implemented - RED phase")
    }

    func startMemoryMonitoring(interval: TimeInterval) async {
        fatalError("PerformanceMonitor.startMemoryMonitoring not implemented - RED phase")
    }

    func stopMemoryMonitoring() async -> MemoryPattern {
        fatalError("PerformanceMonitor.stopMemoryMonitoring not implemented - RED phase")
    }

    func getPlatformInfo() async -> PlatformInfo {
        fatalError("PerformanceMonitor.getPlatformInfo not implemented - RED phase")
    }
}

struct BenchmarkSession {
    let name: String
    let startTime: Date
    var endTime: Date?
    var metrics: [String: Double] = [:]
}

struct BenchmarkResults {
    let duration: TimeInterval
    let metrics: [String: Double]
    let success: Bool
}

// Extension to LFM2Service for testing
extension LFM2Service {
    func generateEmbedding(for content: String) async throws -> [Float] {
        fatalError("LFM2Service.generateEmbedding not implemented - RED phase")
    }
}

extension ObjectBoxSemanticIndex {
    func storeTemplateEmbedding(content: String, embedding: [Float], metadata: TemplateMetadata) async throws {
        fatalError("ObjectBoxSemanticIndex.storeTemplateEmbedding not implemented - RED phase")
    }

    func findSimilar(to embedding: [Float], limit: Int, namespace: String) async throws -> [TemplateSearchResult] {
        fatalError("ObjectBoxSemanticIndex.findSimilar not implemented - RED phase")
    }
}

import XCTest
@testable import GraphRAG
import Foundation

/// Hybrid Search Service Test Suite - TDD RED Phase
/// Tests designed to FAIL initially, implementing BM25 + vector reranking with strict latency targets
/// Performance targets: P50 <10ms, P95 <20ms, P99 <50ms
@available(iOS 17.0, *)
@MainActor
final class HybridSearchServiceTests: XCTestCase {

    private var hybridSearchService: HybridSearchService?
    private var bm25Index: BM25Index?
    private var objectBoxIndex: ObjectBoxSemanticIndex?
    private var lfm2Service: LFM2Service?
    private var performanceMonitor: SearchPerformanceMonitor?

    // Critical performance targets from rubric
    private let p50LatencyTargetMs: Double = 10.0
    private let p95LatencyTargetMs: Double = 20.0
    private let p99LatencyTargetMs: Double = 50.0
    private let lexicalPrefilterTargetMs: Double = 2.0
    private let vectorRerankingTargetMs: Double = 8.0

    override func setUpWithError() throws {
        // These will fail due to unimplemented components - RED phase intended behavior
        hybridSearchService = HybridSearchService()
        bm25Index = BM25Index()
        objectBoxIndex = ObjectBoxSemanticIndex.shared
        lfm2Service = LFM2Service.shared
        performanceMonitor = SearchPerformanceMonitor()
    }

    override func tearDownWithError() throws {
        hybridSearchService = nil
        bm25Index = nil
        objectBoxIndex = nil
        lfm2Service = nil
        performanceMonitor = nil
    }

    // MARK: - Search Performance Tests

    /// Test P50 search latency must be <10ms
    /// CRITICAL: This test MUST FAIL initially until hybrid search optimization is implemented
    
    func testSearchLatencyP50() async throws {
        let searchService = try unwrapService(hybridSearchService)
        let monitor = try unwrapService(performanceMonitor)

        // Populate index with test data for realistic search
        try await populateSearchIndex(templateCount: 1000)

        var latencies: [TimeInterval] = []
        let testQueries = generateTestQueries()

        // Run 100 searches to calculate P50
        for query in testQueries {
            let startTime = Date()

            await searchService.hybridSearch(
                query: query,
                category: nil,
                limit: 10
            )

            let latency = Date().timeIntervalSince(startTime) * 1000  // Convert to ms
            latencies.append(latency)
        }

        let sortedLatencies = latencies.sorted()
        let p50Index = latencies.count / 2
        let p50Latency = sortedLatencies[p50Index]

        // Record performance metrics
        await monitor.recordLatencyMetrics(latencies)

        XCTAssertLessThan(p50Latency, p50LatencyTargetMs,
                         "P50 search latency exceeded target: \(p50Latency)ms > \(p50LatencyTargetMs)ms")

        // Verify search returns relevant results
        await searchService.hybridSearch(query: "IT services contract", category: nil, limit: 10)
        XCTAssertGreaterThan(searchService.searchResults.count, 0, "Search should return results")
    }

    /// Test P95 search latency must be <20ms
    /// This test WILL FAIL until advanced optimization is implemented
    
    func testSearchLatencyP95() async throws {
        let searchService = try unwrapService(hybridSearchService)

        // Use larger dataset for more realistic P95 testing
        try await populateSearchIndex(templateCount: 5000)

        var latencies: [TimeInterval] = []
        let stressQueries = generateStressTestQueries()

        // Run stress test queries
        for query in stressQueries {
            let startTime = Date()

            await searchService.hybridSearch(
                query: query,
                category: .contract,
                limit: 20
            )

            let latency = Date().timeIntervalSince(startTime) * 1000
            latencies.append(latency)
        }

        let sortedLatencies = latencies.sorted()
        let p95Index = Int(Double(latencies.count) * 0.95)
        let p95Latency = sortedLatencies[p95Index]

        XCTAssertLessThan(p95Latency, p95LatencyTargetMs,
                         "P95 search latency exceeded target: \(p95Latency)ms > \(p95LatencyTargetMs)ms")
    }

    /// Test P99 search latency must be <50ms for worst-case scenarios
    /// This test WILL FAIL until comprehensive optimization is implemented
    
    func testSearchLatencyP99() async throws {
        let searchService = try unwrapService(hybridSearchService)

        // Maximum dataset size for P99 testing
        try await populateSearchIndex(templateCount: 10000)

        var latencies: [TimeInterval] = []
        let worstCaseQueries = generateWorstCaseQueries()

        // Run worst-case scenario queries
        for query in worstCaseQueries {
            let startTime = Date()

            await searchService.hybridSearch(
                query: query,
                category: nil,  // No category filter for worst case
                limit: 100  // Large result set
            )

            let latency = Date().timeIntervalSince(startTime) * 1000
            latencies.append(latency)
        }

        let sortedLatencies = latencies.sorted()
        let p99Index = Int(Double(latencies.count) * 0.99)
        let p99Latency = sortedLatencies[p99Index]

        XCTAssertLessThan(p99Latency, p99LatencyTargetMs,
                         "P99 search latency exceeded target: \(p99Latency)ms > \(p99LatencyTargetMs)ms")
    }

    /// Test lexical prefilter performance must be <2ms
    /// This test WILL FAIL until BM25 optimization is implemented
    
    func testLexicalPrefilterSpeed() async throws {
        let bm25Index = try unwrapService(bm25Index)

        // Populate BM25 index with comprehensive data
        try await populateBM25Index(documentCount: 10000)

        let testQueries = [
            "software development contract",
            "IT services statement of work",
            "cybersecurity requirements form",
            "cloud computing procurement guide",
            "small business set aside clause"
        ]

        var prefilterTimes: [TimeInterval] = []

        for query in testQueries {
            let startTime = Date()

            let candidates = try await bm25Index.search(
                query: query,
                filter: nil,
                limit: 1000
            )

            let prefilterTime = Date().timeIntervalSince(startTime) * 1000
            prefilterTimes.append(prefilterTime)

            XCTAssertGreaterThan(candidates.count, 0, "Prefilter should return candidates")
        }

        let averagePrefilterTime = prefilterTimes.reduce(0, +) / Double(prefilterTimes.count)

        XCTAssertLessThan(averagePrefilterTime, lexicalPrefilterTargetMs,
                         "Lexical prefilter exceeded target: \(averagePrefilterTime)ms > \(lexicalPrefilterTargetMs)ms")
    }

    /// Test vector reranking performance must be <8ms
    /// This test WILL FAIL until SIMD cosine similarity optimization is implemented
    
    func testVectorRerankingLatency() async throws {
        let searchService = try unwrapService(hybridSearchService)
        let objectBox = try unwrapService(objectBoxIndex)

        // Setup test embeddings
        let queryEmbedding = generateTestEmbedding(dimensions: 384)
        let candidateEmbeddings = generateCandidateEmbeddings(count: 1000, dimensions: 384)

        // Store candidate embeddings
        for (index, embedding) in candidateEmbeddings.enumerated() {
            try await objectBox.storeTemplateEmbedding(
                content: "Test template content \(index)",
                embedding: embedding,
                metadata: createTemplateMetadata(id: "template-\(index)")
            )
        }

        let startTime = Date()

        // Perform exact cosine similarity reranking
        let rankedResults = try await searchService.performExactReranking(
            candidates: createLexicalCandidates(count: 1000),
            queryEmbedding: queryEmbedding,
            limit: 10
        )

        let rerankTime = Date().timeIntervalSince(startTime) * 1000

        XCTAssertLessThan(rerankTime, vectorRerankingTargetMs,
                         "Vector reranking exceeded target: \(rerankTime)ms > \(vectorRerankingTargetMs)ms")
        XCTAssertEqual(rankedResults.count, 10, "Should return requested number of results")
    }

    /// Test concurrent search performance with 10+ simultaneous operations
    /// This test WILL FAIL until thread-safe concurrent search is implemented
    
    func testConcurrentSearchPerformance() async throws {
        let searchService = try unwrapService(hybridSearchService)

        try await populateSearchIndex(templateCount: 5000)

        let concurrentSearches = 15
        let queries = generateConcurrentTestQueries(count: concurrentSearches)

        let startTime = Date()

        // Execute concurrent searches
        await withTaskGroup(of: TimeInterval.self) { group in
            for query in queries {
                group.addTask { [searchService] in
                    let queryStart = Date()

                    await searchService.hybridSearch(
                        query: query,
                        category: nil,
                        limit: 10
                    )

                    return Date().timeIntervalSince(queryStart)
                }
            }

            var individualLatencies: [TimeInterval] = []
            for await latency in group {
                individualLatencies.append(latency * 1000)  // Convert to ms
            }

            // All individual searches should meet P50 target even under concurrency
            let maxConcurrentLatency = individualLatencies.max() ?? 0
            XCTAssertLessThan(maxConcurrentLatency, p50LatencyTargetMs * 2,
                             "Concurrent search degraded too much: \(maxConcurrentLatency)ms")
        }

        let totalTime = Date().timeIntervalSince(startTime)

        // Total time should show concurrency benefit
        let sequentialEstimate = Double(concurrentSearches) * (p50LatencyTargetMs / 1000)
        XCTAssertLessThan(totalTime, sequentialEstimate * 0.5,
                         "Concurrent execution should be faster than sequential")
    }

    // MARK: - Search Quality Tests

    /// Test hybrid search quality comparison against pure approaches
    /// This test WILL FAIL until hybrid ranking algorithm is implemented
    
    func testHybridSearchQualityComparison() async throws {
        let searchService = try unwrapService(hybridSearchService)
        let bm25Index = try unwrapService(bm25Index)

        try await populateSearchIndex(templateCount: 1000)

        let testQuery = "software development contract requirements"

        // Get hybrid results
        await searchService.hybridSearch(query: testQuery, category: nil, limit: 10)
        let hybridResults = searchService.searchResults

        // Get lexical-only results
        let lexicalResults = try await bm25Index.search(query: testQuery, limit: 10)

        // Calculate relevance scores using NDCG@10
        let hybridNDCG = calculateNDCG(results: hybridResults, query: testQuery, k: 10)
        let lexicalNDCG = calculateNDCG(results: lexicalResults.map { convertToTemplateResult($0) },
                                       query: testQuery, k: 10)

        // Hybrid should outperform lexical-only
        XCTAssertGreaterThan(hybridNDCG, lexicalNDCG,
                           "Hybrid search should outperform lexical-only: \(hybridNDCG) vs \(lexicalNDCG)")

        // Both should meet minimum quality threshold
        XCTAssertGreaterThan(hybridNDCG, 0.8, "Hybrid NDCG@10 should be ≥ 0.8")
    }

    /// Test category filtering accuracy with boundary cases
    /// This test WILL FAIL until category filtering is implemented
    
    func testCategoryFilterAccuracy() async throws {
        let searchService = try unwrapService(hybridSearchService)

        // Populate with diverse template categories
        try await populateSearchIndexWithCategories()

        let categoryQueries = [
            (.contract, "service agreement terms"),
            (.statementOfWork, "project requirements specification"),
            (.form, "evaluation criteria checklist"),
            (.guide, "procurement best practices")
        ]

        for (category, query) in categoryQueries {
            await searchService.hybridSearch(
                query: query,
                category: category,
                limit: 20
            )

            let results = searchService.searchResults
            XCTAssertGreaterThan(results.count, 0, "Should return results for category \(category)")

            // All results should match the specified category
            let correctCategoryCount = results.filter { $0.category == category }.count
            let accuracy = Double(correctCategoryCount) / Double(results.count)

            XCTAssertEqual(accuracy, 1.0, "Category filtering should be 100% accurate for \(category)")
        }
    }

    /// Test semantic similarity accuracy with ground truth validation
    /// This test WILL FAIL until semantic similarity is properly calibrated
    
    func testSemanticSimilarityAccuracy() async throws {
        let searchService = try unwrapService(hybridSearchService)

        // Create ground truth semantic pairs
        let groundTruthPairs = createSemanticGroundTruth()
        try await storeGroundTruthTemplates(pairs: groundTruthPairs)

        for pair in groundTruthPairs {
            await searchService.hybridSearch(
                query: pair.query,
                category: nil,
                limit: 5
            )

            let results = searchService.searchResults

            // Check if expected template is in top results
            let expectedFound = results.contains { result in
                result.template.templateId == pair.expectedTemplateId
            }

            XCTAssertTrue(expectedFound,
                         "Expected template \(pair.expectedTemplateId) not found for query: \(pair.query)")

            // Check relevance score of expected result
            if let expectedResult = results.first(where: { $0.template.templateId == pair.expectedTemplateId }) {
                XCTAssertGreaterThan(expectedResult.score, 0.8,
                                   "Semantic similarity score too low: \(expectedResult.score)")
            }
        }
    }

    // MARK: - Cold vs Warm Performance Tests

    /// Test cold search performance without warm caches
    /// This test WILL FAIL until cold start optimization is implemented
    
    func testColdSearchPerformance() async throws {
        let searchService = try unwrapService(hybridSearchService)

        // Clear all caches to simulate cold start
        await searchService.clearAllCaches()

        try await populateSearchIndex(templateCount: 1000)

        // First search after cache clear (cold)
        let startTime = Date()
        await searchService.hybridSearch(query: "IT services contract", category: nil, limit: 10)
        let coldLatency = Date().timeIntervalSince(startTime) * 1000

        // Second identical search (warm)
        let warmStart = Date()
        await searchService.hybridSearch(query: "IT services contract", category: nil, limit: 10)
        let warmLatency = Date().timeIntervalSince(warmStart) * 1000

        // Cold start should still meet reasonable performance targets
        XCTAssertLessThan(coldLatency, p50LatencyTargetMs * 3,
                         "Cold search exceeded acceptable limit: \(coldLatency)ms")

        // Warm should be significantly faster
        XCTAssertLessThan(warmLatency, coldLatency * 0.8,
                         "Warm search should be faster than cold: \(warmLatency)ms vs \(coldLatency)ms")
    }

    // MARK: - Large Result Set Handling

    /// Test performance with large result sets requiring extensive reranking
    /// This test WILL FAIL until efficient large set reranking is implemented
    
    func testLargeResultSetHandling() async throws {
        let searchService = try unwrapService(hybridSearchService)

        // Populate with maximum dataset
        try await populateSearchIndex(templateCount: 15000)

        // Query that will match many templates
        let broadQuery = "contract requirements"

        let startTime = Date()

        await searchService.hybridSearch(
            query: broadQuery,
            category: nil,
            limit: 100  // Large result set
        )

        let latency = Date().timeIntervalSince(startTime) * 1000

        XCTAssertLessThan(latency, p95LatencyTargetMs,
                         "Large result set search exceeded P95 target: \(latency)ms")

        let results = searchService.searchResults
        XCTAssertEqual(results.count, 100, "Should return requested number of results")

        // Results should be properly ranked
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(results[i].score, results[i + 1].score,
                                       "Results should be sorted by score descending")
        }
    }

    // MARK: - Test Data Generation and Helper Methods

    private func populateSearchIndex(templateCount: Int) async throws {
        let searchService = try unwrapService(hybridSearchService)
        let templates = generateTestTemplates(count: templateCount)

        for template in templates {
            try await searchService.addTemplate(template)
        }
    }

    private func populateBM25Index(documentCount: Int) async throws {
        let bm25Index = try unwrapService(bm25Index)

        for i in 0..<documentCount {
            let content = generateTemplateContent(index: i)
            let metadata = createTemplateMetadata(id: "doc-\(i)")
            await bm25Index.addDocument("doc-\(i)", content: content, metadata: metadata)
        }
    }

    private func generateTestQueries() -> [String] {
        [
            "software development contract",
            "IT services statement of work",
            "cybersecurity requirements",
            "cloud computing procurement",
            "data management agreement",
            "system integration services",
            "maintenance support contract",
            "professional services SOW",
            "consulting agreement terms",
            "technical support services"
        ]
    }

    private func generateStressTestQueries() -> [String] {
        [
            "comprehensive software development lifecycle management services",
            "enterprise-wide cybersecurity implementation and monitoring",
            "multi-phase system integration with legacy compatibility",
            "artificial intelligence machine learning development platform",
            "cloud infrastructure migration and optimization services"
        ]
    }

    private func generateWorstCaseQueries() -> [String] {
        [
            "the",  // Single common word
            "a services system software development implementation",  // Many common words
            "xyzabc123notfound",  // Non-existent terms
            String(repeating: "software development ", count: 20),  // Very long query
            ""  // Empty query
        ]
    }

    private func generateConcurrentTestQueries(count: Int) -> [String] {
        var queries: [String] = []
        let baseQueries = generateTestQueries()

        for i in 0..<count {
            let baseIndex = i % baseQueries.count
            queries.append("\(baseQueries[baseIndex]) \(i)")
        }

        return queries
    }

    private func generateTestTemplates(count: Int) -> [ProcessedTemplate] {
        var templates: [ProcessedTemplate] = []

        for i in 0..<count {
            let content = generateTemplateContent(index: i)
            let chunks = [TemplateChunk(
                content: content,
                chunkIndex: 0,
                overlap: "",
                metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
                isMemoryMapped: false
            )]

            let template = ProcessedTemplate(
                chunks: chunks,
                category: TemplateCategory.allCases[i % TemplateCategory.allCases.count],
                metadata: createTemplateMetadata(id: "template-\(i)"),
                processingMode: .normal
            )

            templates.append(template)
        }

        return templates
    }

    private func generateTemplateContent(index: Int) -> String {
        let contentTemplates = [
            "Software development contract for enterprise applications including requirements analysis, design, implementation, and testing services.",
            "Statement of Work for IT infrastructure modernization including cloud migration, security implementation, and performance optimization.",
            "Cybersecurity services agreement covering threat assessment, vulnerability testing, and incident response planning.",
            "Data management and analytics platform development including data integration, processing pipelines, and reporting capabilities.",
            "Professional services contract for project management, technical consulting, and system administration support."
        ]

        let base = contentTemplates[index % contentTemplates.count]
        return "\(base) Document \(index) with additional specific requirements and compliance standards."
    }

    private func createTemplateMetadata(id: String) -> TemplateMetadata {
        TemplateMetadata(
            templateId: id,
            fileName: "\(id).pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Test Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 1024,
            checksum: "checksum-\(id)"
        )
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

    private func generateCandidateEmbeddings(count: Int, dimensions: Int) -> [[Float]] {
        var embeddings: [[Float]] = []

        for i in 0..<count {
            var embedding = [Float](repeating: 0.0, count: dimensions)

            for j in 0..<dimensions {
                embedding[j] = sin(Float(i + j) * 0.1) * 0.5 + cos(Float(i) * 0.05) * 0.3
            }

            let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
            if magnitude > 0 {
                embedding = embedding.map { $0 / magnitude }
            }

            embeddings.append(embedding)
        }

        return embeddings
    }

    private func createLexicalCandidates(count: Int) -> [LexicalCandidate] {
        var candidates: [LexicalCandidate] = []

        for i in 0..<count {
            let candidate = LexicalCandidate(
                templateId: "template-\(i)",
                score: Float.random(in: 0.5...1.0),
                metadata: createTemplateMetadata(id: "template-\(i)"),
                snippet: "Test snippet for template \(i)",
                category: .contract
            )
            candidates.append(candidate)
        }

        return candidates
    }

    private func calculateNDCG(results: [TemplateSearchResult], query: String, k: Int) -> Double {
        // Simplified NDCG calculation for testing
        // In real implementation, this would use ground truth relevance scores
        guard !results.isEmpty else { return 0.0 }

        let relevanceScores = results.prefix(k).map { Double($0.score) }
        let dcg = relevanceScores.enumerated().map { index, score in
            score / log2(Double(index + 2))
        }.reduce(0, +)

        let idealScores = relevanceScores.sorted(by: >)
        let idcg = idealScores.enumerated().map { index, score in
            score / log2(Double(index + 2))
        }.reduce(0, +)

        return idcg > 0 ? dcg / idcg : 0.0
    }

    private func convertToTemplateResult(_ lexicalResult: LexicalCandidate) -> TemplateSearchResult {
        TemplateSearchResult(
            template: lexicalResult.metadata,
            score: lexicalResult.score,
            snippet: lexicalResult.snippet,
            category: lexicalResult.category,
            crossReferences: [],
            searchLatency: nil
        )
    }

    private func populateSearchIndexWithCategories() async throws {
        // Implementation would populate index with templates of all categories
        // This will fail until implemented
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not implemented - RED phase"])
    }

    private func createSemanticGroundTruth() -> [(query: String, expectedTemplateId: String)] {
        [
            ("software development contract", "template-sdc-001"),
            ("IT services agreement", "template-ita-002"),
            ("cybersecurity requirements", "template-csr-003"),
            ("cloud computing procurement", "template-ccp-004"),
            ("data management services", "template-dms-005")
        ]
    }

    private func storeGroundTruthTemplates(pairs: [(query: String, expectedTemplateId: String)]) async throws {
        // Implementation would store templates with known semantic relationships
        // This will fail until implemented
        throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not implemented - RED phase"])
    }
}

// MARK: - Supporting Types (Will fail until implemented)

struct TemplateSearchResult: Identifiable {
    let id = UUID()
    let template: TemplateMetadata
    let score: Float
    let snippet: String
    let category: TemplateCategory
    let crossReferences: [RegulationReference]
    let searchLatency: TimeInterval?
}

struct LexicalCandidate {
    let templateId: String
    let score: Float
    let metadata: TemplateMetadata
    let snippet: String
    let category: TemplateCategory
}

struct RegulationReference {
    let regulationId: String
    let section: String
    let confidence: Float
}

// Performance monitoring
class SearchPerformanceMonitor {
    func recordLatencyMetrics(_ latencies: [TimeInterval]) async {
        fatalError("SearchPerformanceMonitor.recordLatencyMetrics not implemented - RED phase")
    }
}

// Placeholder implementations that will fail
@MainActor
class HybridSearchService: ObservableObject {
    @Published var searchResults: [TemplateSearchResult] = []
    @Published var isSearching = false
    @Published var searchLatency: TimeInterval = 0

    func hybridSearch(query: String, category: TemplateCategory?, limit: Int) async {
        fatalError("HybridSearchService.hybridSearch not implemented - RED phase")
    }

    func performExactReranking(candidates: [LexicalCandidate], queryEmbedding: [Float], limit: Int) async throws -> [TemplateSearchResult] {
        fatalError("HybridSearchService.performExactReranking not implemented - RED phase")
    }

    func addTemplate(_ template: ProcessedTemplate) async throws {
        fatalError("HybridSearchService.addTemplate not implemented - RED phase")
    }

    func clearAllCaches() async {
        fatalError("HybridSearchService.clearAllCaches not implemented - RED phase")
    }
}

class BM25Index {
    func search(query: String, filter: CategoryFilter? = nil, limit: Int) async throws -> [LexicalCandidate] {
        fatalError("BM25Index.search not implemented - RED phase")
    }

    func addDocument(_ id: String, content: String, metadata: TemplateMetadata) async {
        fatalError("BM25Index.addDocument not implemented - RED phase")
    }
}

enum CategoryFilter {
    case category(TemplateCategory)

    func matches(_ category: TemplateCategory?) -> Bool {
        fatalError("CategoryFilter.matches not implemented - RED phase")
    }
}

extension ObjectBoxSemanticIndex {
    func storeTemplateEmbedding(content: String, embedding: [Float], metadata: TemplateMetadata) async throws {
        fatalError("ObjectBoxSemanticIndex.storeTemplateEmbedding not implemented - RED phase")
    }
}

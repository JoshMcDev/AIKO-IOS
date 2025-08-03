import XCTest
@testable import GraphRAG

/// Debug test to understand why UnifiedSearchServiceTests returns empty results
final class DebugSemanticIndexTest: XCTestCase {

    func testSemanticIndexDataFlow() async throws {
        let semanticIndex = ObjectBoxSemanticIndex.shared

        // Clear any existing data
        try await semanticIndex.clearAllData()

        // Create test embedding
        let testEmbedding = createTestEmbedding(dimensions: 768)
        let testMetadata = RegulationMetadata(
            regulationNumber: "DEBUG-TEST-1",
            title: "Debug Test Regulation",
            subpart: "Debug",
            supplement: nil
        )

        print("🔍 Debug: About to store regulation embedding...")

        // Store data
        try await semanticIndex.storeRegulationEmbedding(
            content: "Debug test regulation content for testing purposes",
            embedding: testEmbedding,
            metadata: testMetadata
        )

        // Verify storage
        let stats = await semanticIndex.getStorageStats()
        print("🔍 Debug: Storage stats - regulations: \(stats.regulationCount), workflows: \(stats.userWorkflowCount)")
        XCTAssertEqual(stats.regulationCount, 1, "Should have 1 regulation stored")

        // Create query embedding (exactly the same for testing)
        let queryEmbedding = testEmbedding

        print("🔍 Debug: About to search with threshold 0.1...")

        // Search with very low threshold
        let results = try await semanticIndex.findSimilarRegulations(
            queryEmbedding: queryEmbedding,
            limit: 10,
            threshold: 0.1  // Very low threshold
        )

        print("🔍 Debug: Search returned \(results.count) results")

        // Should definitely find the exact same embedding
        XCTAssertGreaterThan(results.count, 0, "Should find at least 1 result with identical embedding")

        if !results.isEmpty {
            print("🔍 Debug: First result content: \(results[0].content)")
        }
    }

    func testLFM2ServiceEmbeddingGeneration() async throws {
        let lfm2Service = LFM2Service.shared

        print("🔍 Debug: Testing LFM2Service embedding generation...")

        let embedding = try await lfm2Service.generateEmbedding(
            text: "test content",
            domain: .regulations
        )

        print("🔍 Debug: LFM2Service generated embedding with \(embedding.count) dimensions")
        print("🔍 Debug: First 5 values: \(Array(embedding.prefix(5)))")

        XCTAssertEqual(embedding.count, 768, "LFM2Service should generate 768-dimensional embeddings")
    }

    func testEmbeddingSimilarity() {
        let embedding1 = createTestEmbedding(dimensions: 768)
        let embedding2 = createTestEmbedding(dimensions: 768)

        // Test identical embeddings
        let identicalSimilarity = cosineSimilarity(embedding1, embedding1)
        print("🔍 Debug: Identical embedding similarity: \(identicalSimilarity)")
        XCTAssertEqual(identicalSimilarity, 1.0, accuracy: 0.01, "Identical embeddings should have similarity = 1.0")

        // Test different but deterministic embeddings
        let differentSimilarity = cosineSimilarity(embedding1, embedding2)
        print("🔍 Debug: Different embedding similarity: \(differentSimilarity)")

        // Since both use the same pattern, they should be identical
        XCTAssertEqual(differentSimilarity, 1.0, accuracy: 0.01, "Same pattern embeddings should be identical")
    }

    private func createTestEmbedding(dimensions: Int) -> [Float] {
        var embedding = [Float](repeating: 0.0, count: dimensions)

        for i in 0..<dimensions {
            let value = sin(Float(i) * 0.1) * 0.5
            embedding[i] = value
        }

        // Normalize to unit vector
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }
}

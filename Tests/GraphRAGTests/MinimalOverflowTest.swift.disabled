@testable import GraphRAG
import XCTest

/// Minimal test to isolate the integer overflow issue
final class MinimalOverflowTest: XCTestCase {
    func testBasicStringHash() throws {
        // Test the djb2hash function directly
        let testString = "hello world"
        let hash = testString.djb2hash
        print("Hash value: \(hash)")
        XCTAssertGreaterThan(hash, 0)
    }

    func testTokenGeneration() throws {
        // Test token ID generation
        let service = LFM2Service.shared
        let tokenIds = service.createPlaceholderTokenIds(from: "test string")
        print("Token IDs: \(tokenIds)")
        XCTAssertFalse(tokenIds.isEmpty)
    }

    func testSimpleEmbedding() async throws {
        // Test the simplest possible embedding generation
        let service = LFM2Service.shared
        let embedding = try await service.generateEmbedding(text: "test", domain: .regulations)
        print("Embedding dimensions: \(embedding.count)")
        XCTAssertEqual(embedding.count, 768)
    }
}

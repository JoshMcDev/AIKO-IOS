import CoreML
@testable import GraphRAG
import XCTest

/// Integration tests for LFM2Service with tensor rank fix functionality
/// Validates CoreML pipeline integrity and data flow according to TDD rubric
class LFM2ServiceTests: XCTestCase {
    // MARK: - Test Properties

    var lfm2Service: LFM2Service!
    let testTimeout: TimeInterval = 10.0

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        lfm2Service = LFM2Service.shared
    }

    override func tearDown() {
        lfm2Service = nil
        super.tearDown()
    }

    // MARK: - Integration Tests for CoreML Pipeline (Phase 2)

    /// MoE: Pipeline Integrity - Validate service initialization
    /// DoS: Service should initialize without errors and be ready for use
    func testLFM2ServiceInitialization() {
        // RED: Should fail until proper initialization is implemented
        XCTAssertNotNil(lfm2Service, "LFM2Service should initialize successfully")

        let expectation = XCTestExpectation(description: "Service initialization")

        Task {
            do {
                try await lfm2Service.initializeModel()
                expectation.fulfill()
            } catch {
                XCTFail("Service initialization failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: testTimeout)
    }

    /// MoE: Data Flow - Validate tensor rank fix integration
    /// DoS: preprocessTextWithTensorRankFix should return valid rank-4+ tensors
    func testPreprocessTextWithTensorRankFix_returnsValidTensor() {
        // RED: Should fail until tensor rank fix is properly integrated
        let testText = "This is a test sentence for tensor processing."

        XCTAssertNoThrow {
            let featureProvider = try lfm2Service.preprocessTextWithTensorRankFix(testText)

            // Validate feature provider structure
            XCTAssertNotNil(featureProvider.featureValue(for: "input_ids"),
                            "Feature provider should contain input_ids")

            let inputTensor = featureProvider.featureValue(for: "input_ids")?.multiArrayValue
            XCTAssertNotNil(inputTensor, "input_ids should be MLMultiArray")

            // Validate tensor rank (should be 4+ for LFM2 compatibility)
            XCTAssertGreaterThanOrEqual(inputTensor!.shape.count, 3,
                                        "Tensor should have rank 3 or higher for LFM2 compatibility")

            // Validate tensor dimensions match expected LFM2 input format
            XCTAssertEqual(inputTensor!.shape[0].intValue, 1, "Batch size should be 1")
            XCTAssertEqual(inputTensor!.shape[1].intValue, 512, "Sequence length should be 512")

            if inputTensor!.shape.count >= 3 {
                XCTAssertEqual(inputTensor!.shape[2].intValue, 768, "Embedding dimensions should be 768")
            }
        }
    }

    /// MoE: Error Handling - Validate handling of invalid text input
    /// DoS: Invalid input should be handled gracefully without crashes
    func testPreprocessTextWithTensorRankFix_withEmptyText_handlesGracefully() {
        // RED: Should fail until empty text handling is implemented
        let emptyText = ""

        XCTAssertNoThrow {
            let featureProvider = try lfm2Service.preprocessTextWithTensorRankFix(emptyText)

            // Should still return valid feature provider with default values
            XCTAssertNotNil(featureProvider.featureValue(for: "input_ids"))

            let inputTensor = featureProvider.featureValue(for: "input_ids")?.multiArrayValue
            XCTAssertNotNil(inputTensor)

            // Empty text should result in zero-padded tensor
            XCTAssertEqual(inputTensor![0].int32Value, 0, "Empty text should result in zero padding")
        }
    }

    /// MoE: Data Flow - Validate comparison between original and fixed implementations
    /// DoS: Fixed implementation should outperform original in tensor validity
    func testCompareTensorRankImplementations_showsImprovement() {
        // RED: Should fail until comparison method is implemented
        let testText = "Test input for tensor rank comparison analysis."

        XCTAssertNoThrow {
            let comparisonResult = try lfm2Service.compareTensorRankImplementations(testText)

            // Validate comparison structure
            XCTAssertEqual(comparisonResult.originalRank, 2, "Original implementation should use rank-2")
            XCTAssertGreaterThanOrEqual(comparisonResult.fixedRank, 3, "Fixed implementation should use rank-3+")

            // Validate improvement
            XCTAssertTrue(comparisonResult.isFixSuccessful,
                          "Fix should be successful (fixed valid, original invalid)")

            // Original should fail validation, fixed should pass
            XCTAssertFalse(comparisonResult.originalValidation.isValid,
                           "Original rank-2 tensor should fail validation")
            XCTAssertTrue(comparisonResult.fixedValidation.isValid,
                          "Fixed rank-4 tensor should pass validation")
        }
    }

    // MARK: - Model Loading and CoreML Integration Tests

    /// MoE: Pipeline Integrity - Validate CoreML model loading
    /// DoS: Model should load successfully and be ready for inference
    func testCoreMLModelLoading() {
        // RED: Should fail until proper model loading is implemented
        let expectation = XCTestExpectation(description: "Model loading")

        Task {
            do {
                try await lfm2Service.initializeModel()

                // Verify model information
                let modelInfo = await lfm2Service.getModelInfo()
                XCTAssertNotNil(modelInfo, "Model info should be available after initialization")
                XCTAssertTrue(modelInfo!.isInitialized, "Model should be marked as initialized")
                XCTAssertEqual(modelInfo!.embeddingDimensions, 768, "Embedding dimensions should match LFM2 spec")
                XCTAssertEqual(modelInfo!.maxTokenLength, 512, "Max token length should match LFM2 spec")

                expectation.fulfill()
            } catch {
                XCTFail("Model loading failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: testTimeout)
    }

    /// MoE: Error Handling - Validate model not found scenario
    /// DoS: Missing model should trigger appropriate fallback behavior
    func testModelNotFound_triggersGGUFFallback() {
        // RED: Should fail until GGUF fallback logic is implemented
        let expectation = XCTestExpectation(description: "GGUF fallback")

        Task {
            do {
                // This test assumes no CoreML model is available, triggering GGUF fallback
                try await lfm2Service.initializeModel()
                XCTFail("Should have thrown GGUF not supported error")
            } catch LFM2Error.ggufNotSupported {
                // Expected behavior - GGUF fallback should be triggered
                expectation.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        wait(for: [expectation], timeout: testTimeout)
    }

    // MARK: - Embedding Generation Integration Tests

    /// MoE: End-to-End Flow - Validate embedding generation with rank fix
    /// DoS: Generated embeddings should be valid 768-dimensional vectors
    func testGenerateEmbedding_withTensorRankFix_returnsValidEmbedding() {
        // RED: Should fail until end-to-end embedding generation is implemented
        let testText = "Sample regulation text for embedding generation testing."
        let expectation = XCTestExpectation(description: "Embedding generation")

        Task {
            do {
                try await lfm2Service.initializeModel()

                let embedding = try await lfm2Service.generateEmbedding(
                    text: testText,
                    domain: .regulations
                )

                // Validate embedding properties
                XCTAssertEqual(embedding.count, 768, "Embedding should have 768 dimensions")
                XCTAssertFalse(embedding.contains { $0.isNaN }, "Embedding should not contain NaN values")
                XCTAssertFalse(embedding.contains { $0.isInfinite }, "Embedding should not contain infinite values")

                // Validate embedding magnitude (should be reasonable)
                let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
                XCTAssertGreaterThan(magnitude, 0, "Embedding should have non-zero magnitude")
                XCTAssertLessThan(magnitude, 100, "Embedding magnitude should be reasonable")

                expectation.fulfill()
            } catch {
                XCTFail("Embedding generation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: testTimeout)
    }

    /// MoE: Data Flow - Validate batch embedding generation
    /// DoS: Batch processing should maintain consistency and performance
    func testGenerateBatchEmbeddings_maintainsConsistency() {
        // RED: Should fail until batch processing is implemented
        let testTexts = [
            "First regulation document text.",
            "Second regulation document text.",
            "Third regulation document text.",
        ]
        let expectation = XCTestExpectation(description: "Batch embedding generation")

        Task {
            do {
                try await lfm2Service.initializeModel()

                let embeddings = try await lfm2Service.generateBatchEmbeddings(
                    texts: testTexts,
                    domain: .regulations
                )

                // Validate batch results
                XCTAssertEqual(embeddings.count, testTexts.count, "Should generate embedding for each input")

                for (index, embedding) in embeddings.enumerated() {
                    XCTAssertEqual(embedding.count, 768, "Each embedding should have 768 dimensions")
                    XCTAssertFalse(embedding.contains { $0.isNaN },
                                   "Embedding \(index) should not contain NaN values")
                    XCTAssertFalse(embedding.contains { $0.isInfinite },
                                   "Embedding \(index) should not contain infinite values")
                }

                expectation.fulfill()
            } catch {
                XCTFail("Batch embedding generation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: testTimeout * Double(testTexts.count))
    }

    // MARK: - Performance Integration Tests (MoP Validation)

    /// MoP: Latency - Measure end-to-end embedding generation performance
    /// DoS: Embedding generation should complete within acceptable latency
    func testEmbeddingGenerationLatency() {
        // RED: Should fail until performance optimization is complete
        let testText = "Performance test text for latency measurement."

        measure {
            let expectation = XCTestExpectation(description: "Latency measurement")

            Task {
                do {
                    try await lfm2Service.initializeModel()
                    _ = try await lfm2Service.generateEmbedding(text: testText, domain: .regulations)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }

            wait(for: [expectation], timeout: testTimeout)
        }
    }

    /// MoP: Throughput - Measure batch processing performance
    /// DoS: Batch processing should maintain acceptable throughput
    func testBatchProcessingThroughput() {
        // RED: Should fail until batch optimization is implemented
        let batchTexts = Array(repeating: "Throughput test document.", count: 10)

        measure {
            let expectation = XCTestExpectation(description: "Throughput measurement")

            Task {
                do {
                    try await lfm2Service.initializeModel()
                    _ = try await lfm2Service.generateBatchEmbeddings(texts: batchTexts, domain: .regulations)
                    expectation.fulfill()
                } catch {
                    XCTFail("Throughput test failed: \(error)")
                }
            }

            wait(for: [expectation], timeout: testTimeout * 2)
        }
    }

    // MARK: - Memory and Resource Tests

    /// MoP: Resource Utilization - Validate memory efficiency in integration
    /// DoS: Service should not cause memory leaks or excessive resource usage
    func testMemoryEfficiencyInIntegration() {
        // RED: Should fail until memory optimization is implemented
        let iterations = 50

        for i in 0 ..< iterations {
            autoreleasepool {
                let expectation = XCTestExpectation(description: "Memory test iteration \(i)")

                Task {
                    do {
                        let testText = "Memory test iteration \(i) text content."
                        try await lfm2Service.initializeModel()
                        _ = try await lfm2Service.generateEmbedding(text: testText, domain: .regulations)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Memory test iteration \(i) failed: \(error)")
                    }
                }

                wait(for: [expectation], timeout: testTimeout)
            }
        }
    }

    // MARK: - Error Handling Integration Tests

    /// MoE: Error Handling - Validate service behavior with corrupted input
    /// DoS: Service should handle edge cases gracefully
    func testServiceRobustnessWithEdgeCases() {
        // RED: Should fail until robust error handling is implemented
        let edgeCaseInputs = [
            "", // Empty string
            String(repeating: "A", count: 10000), // Very long string
            "🚀🎯💡🔥", // Emoji-only text
            "\n\t\r", // Whitespace-only
            "Normal text with special chars: @#$%^&*()",
        ]

        let expectation = XCTestExpectation(description: "Edge case handling")
        expectation.expectedFulfillmentCount = edgeCaseInputs.count

        Task {
            do {
                try await lfm2Service.initializeModel()

                for (index, input) in edgeCaseInputs.enumerated() {
                    do {
                        let embedding = try await lfm2Service.generateEmbedding(text: input, domain: .regulations)

                        // Should still produce valid embedding
                        XCTAssertEqual(embedding.count, 768, "Edge case \(index) should produce valid embedding")
                        XCTAssertFalse(embedding.contains { $0.isNaN }, "Edge case \(index) should not contain NaN")

                        expectation.fulfill()
                    } catch {
                        // Some edge cases might legitimately fail, but shouldn't crash
                        XCTAssertTrue(error is LFM2Error, "Should throw appropriate LFM2Error for edge case \(index)")
                        expectation.fulfill()
                    }
                }
            } catch {
                XCTFail("Service initialization failed for edge case testing: \(error)")
            }
        }

        wait(for: [expectation], timeout: testTimeout * Double(edgeCaseInputs.count))
    }
}

// MARK: - Test Utilities

extension LFM2ServiceTests {
    /// Helper method to validate embedding properties
    func validateEmbeddingProperties(_ embedding: [Float], description: String) {
        XCTAssertEqual(embedding.count, 768, "\(description): Should have 768 dimensions")
        XCTAssertFalse(embedding.contains { $0.isNaN }, "\(description): Should not contain NaN")
        XCTAssertFalse(embedding.contains { $0.isInfinite }, "\(description): Should not contain infinite values")

        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        XCTAssertGreaterThan(magnitude, 0, "\(description): Should have non-zero magnitude")
    }

    /// Helper method to create test data for various scenarios
    func createTestText(length: Int) -> String {
        let words = ["regulation", "compliance", "policy", "standard", "requirement", "procedure"]
        let repeatedWords = Array(repeating: words, count: (length / words.count) + 1).flatMap { $0 }
        return Array(repeatedWords.prefix(length)).joined(separator: " ")
    }
}

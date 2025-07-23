import XCTest
import CoreML
@testable import GraphRAG

/// Performance benchmarks and end-to-end validation tests for tensor operations
/// Implements MoP (Measures of Performance) criteria from TDD rubric
@MainActor
class TensorOperationsTests: XCTestCase {

    // MARK: - Test Configuration

    let performanceTestIterations = 100
    let benchmarkTimeout: TimeInterval = 30.0
    let expectedTensorCreationTimeThreshold: TimeInterval = 0.001 // 1ms
    let expectedConversionTimeThreshold: TimeInterval = 0.002 // 2ms

    // MARK: - Performance Benchmarks (Phase 3)

    /// MoP: Throughput - Measure tensor creation operations per second
    /// DoS: Should achieve minimum throughput for production use
    func testTensorCreationThroughput() {
        // RED: Should fail until throughput optimization is implemented
        let tokenIds = Array<Int32>(1...512)
        var createdTensors: [MLMultiArray] = []

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for _ in 0..<performanceTestIterations {
                do {
                    let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
                    createdTensors.append(tensor)
                } catch {
                    XCTFail("Tensor creation failed in throughput test: \(error)")
                }
            }
        }

        // Validate all tensors were created successfully
        XCTAssertEqual(createdTensors.count, performanceTestIterations,
                      "All tensors should be created successfully")
    }

    /// MoP: Latency - Measure individual tensor operation latency
    /// DoS: Individual operations should complete within acceptable time
    func testTensorOperationLatency() {
        // RED: Should fail until latency optimization is implemented
        let tokenIds = Array<Int32>(1...256)

        // Test rank-4 tensor creation latency
        measure(metrics: [XCTClockMetric()]) {
            do {
                _ = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
            } catch {
                XCTFail("Latency test failed: \(error)")
            }
        }

        // Test rank-2 to rank-4 conversion latency
        measure(metrics: [XCTClockMetric()]) {
            do {
                let rank2Tensor = try LFM2TensorRankFix.createRank2TokenTensor(tokenIds: tokenIds)
                _ = try LFM2TensorRankFix.convertRank2ToRank4(rank2Tensor)
            } catch {
                XCTFail("Conversion latency test failed: \(error)")
            }
        }

        // Test tensor validation latency
        measure(metrics: [XCTClockMetric()]) {
            do {
                let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
                _ = LFM2TensorRankFix.validateTensorRank(tensor)
            } catch {
                XCTFail("Validation latency test failed: \(error)")
            }
        }
    }

    /// MoP: Resource Utilization - Monitor CPU and memory usage during operations
    /// DoS: Operations should not cause excessive resource consumption
    func testResourceUtilizationEfficiency() {
        // RED: Should fail until resource optimization is implemented
        let largeBatch = Array(repeating: Array<Int32>(1...512), count: 50)

        measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
            for tokenIds in largeBatch {
                autoreleasepool {
                    do {
                        let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
                        let validation = LFM2TensorRankFix.validateTensorRank(tensor)
                        XCTAssertTrue(validation.isValid)
                    } catch {
                        XCTFail("Resource utilization test failed: \(error)")
                    }
                }
            }
        }
    }

    /// MoP: Scalability - Test performance under varying loads
    /// DoS: Performance should scale appropriately with input size
    func testScalabilityWithVaryingInputSizes() {
        // RED: Should fail until scalability optimization is implemented
        let inputSizes = [10, 50, 100, 256, 512]
        var results: [Int: TimeInterval] = [:]

        for size in inputSizes {
            let tokenIds = Array<Int32>(1...Int32(size))
            let startTime = CFAbsoluteTimeGetCurrent()

            do {
                _ = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
                let endTime = CFAbsoluteTimeGetCurrent()
                results[size] = endTime - startTime

                // Performance should not degrade exponentially
                XCTAssertLessThan(endTime - startTime, expectedTensorCreationTimeThreshold * Double(size) / 10.0,
                                 "Performance should scale reasonably for size \(size)")
            } catch {
                XCTFail("Scalability test failed for size \(size): \(error)")
            }
        }

        // Log performance characteristics for analysis
        for (size, time) in results.sorted(by: { $0.key < $1.key }) {
            print("Size \(size): \(String(format: "%.4f", time))s")
        }
    }

    // MARK: - End-to-End GraphRAG Validation (Phase 4)

    /// MoE: End-to-End Flow - Validate complete GraphRAG pipeline with tensor fix
    /// DoS: Full pipeline should produce valid, consistent results
    func testEndToEndGraphRAGPipelineValidation() {
        // RED: Should fail until end-to-end integration is complete
        let testDocuments = [
            "Federal regulation requiring compliance with data protection standards.",
            "State policy mandating environmental impact assessments for new projects.",
            "Municipal ordinance establishing noise control measures in residential areas.",
            "Industry standard for cybersecurity protocols in financial institutions.",
            "International treaty on intellectual property rights protection."
        ]

        let expectation = XCTestExpectation(description: "End-to-end pipeline validation")
        expectation.expectedFulfillmentCount = testDocuments.count

        Task {
            let service = LFM2Service.shared

            do {
                try await service.initializeModel()

                var allEmbeddings: [[Float]] = []

                for (index, document) in testDocuments.enumerated() {
                    do {
                        // Test the complete flow: text → tensor rank fix → CoreML → embedding
                        let embedding = try await service.generateEmbedding(
                            text: document,
                            domain: .regulations
                        )

                        // Validate embedding quality
                        self.validateEmbeddingQuality(embedding, documentIndex: index)
                        allEmbeddings.append(embedding)

                        expectation.fulfill()
                    } catch {
                        XCTFail("End-to-end test failed for document \(index): \(error)")
                    }
                }

                // Test embedding consistency and distinctiveness
                self.validateEmbeddingConsistency(allEmbeddings)

            } catch {
                XCTFail("End-to-end pipeline initialization failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: benchmarkTimeout)
    }

    /// MoE: Accuracy - Validate mathematical correctness of tensor operations
    /// DoS: Operations should maintain numerical precision and correctness
    func testTensorMathematicalCorrectness() {
        // RED: Should fail until mathematical validation is implemented
        let testCases = [
            (tokenIds: Array<Int32>(1...5), expectedFirstValue: Int32(1)),
            (tokenIds: Array<Int32>(10...15), expectedFirstValue: Int32(10)),
            (tokenIds: Array<Int32>([42, 24, 12, 6]), expectedFirstValue: Int32(42))
        ]

        for (caseIndex, testCase) in testCases.enumerated() {
            do {
                // Test mathematical consistency across different tensor operations
                let rank2Tensor = try LFM2TensorRankFix.createRank2TokenTensor(tokenIds: testCase.tokenIds)
                let rank3Tensor = try LFM2TensorRankFix.createRank3TokenTensor(tokenIds: testCase.tokenIds)
                let rank4Tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: testCase.tokenIds)

                // Validate data preservation across different representations
                XCTAssertEqual(rank2Tensor[0].int32Value, testCase.expectedFirstValue,
                              "Case \(caseIndex): Rank-2 should preserve first token")

                // For rank-3 and rank-4, the first token should be at the appropriate flat index
                let rank3FirstTokenIndex = 0 * 768 // embedding_dim offset
                let rank4FirstTokenIndex = 0 * 768 * 1 // embedding_dim * feature_depth offset

                XCTAssertEqual(rank3Tensor[rank3FirstTokenIndex].int32Value, testCase.expectedFirstValue,
                              "Case \(caseIndex): Rank-3 should preserve first token at correct index")
                XCTAssertEqual(rank4Tensor[rank4FirstTokenIndex].int32Value, testCase.expectedFirstValue,
                              "Case \(caseIndex): Rank-4 should preserve first token at correct index")

                // Test conversion correctness
                let convertedTensor = try LFM2TensorRankFix.convertRank2ToRank4(rank2Tensor)
                XCTAssertEqual(convertedTensor[rank4FirstTokenIndex].int32Value, testCase.expectedFirstValue,
                              "Case \(caseIndex): Conversion should preserve data correctly")

            } catch {
                XCTFail("Mathematical correctness test case \(caseIndex) failed: \(error)")
            }
        }
    }

    /// MoE: Robustness - Test system behavior under stress conditions
    /// DoS: System should handle edge cases and stress conditions gracefully
    func testSystemRobustnessUnderStress() {
        // RED: Should fail until robustness measures are implemented
        let stressTestScenarios = [
            // Large batch processing
            Array(repeating: Array<Int32>(1...512), count: 100),
            // Rapid repeated operations
            Array(repeating: Array<Int32>(1...10), count: 1000),
            // Mixed sizes
            (1...50).map { Array<Int32>(1...Int32($0 * 10)) }
        ]

        for (scenarioIndex, scenario) in stressTestScenarios.enumerated() {
            autoreleasepool {
                var successCount = 0
                let startTime = CFAbsoluteTimeGetCurrent()

                for tokenIds in scenario {
                    do {
                        let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: tokenIds)
                        let validation = LFM2TensorRankFix.validateTensorRank(tensor)

                        if validation.isValid {
                            successCount += 1
                        }
                    } catch {
                        // Count failures but don't fail the test immediately
                        print("Stress test scenario \(scenarioIndex) operation failed: \(error)")
                    }
                }

                let endTime = CFAbsoluteTimeGetCurrent()
                let successRate = Double(successCount) / Double(scenario.count)

                // Should maintain high success rate even under stress
                XCTAssertGreaterThanOrEqual(successRate, 0.95,
                                          "Scenario \(scenarioIndex): Should maintain 95%+ success rate under stress")

                print("Stress scenario \(scenarioIndex): \(successCount)/\(scenario.count) operations succeeded in \(String(format: "%.2f", endTime - startTime))s")
            }
        }
    }

    // MARK: - Consistency and Reliability Tests

    /// MoE: Consistency - Validate deterministic behavior
    /// DoS: Same inputs should produce identical outputs across runs
    func testDeterministicBehavior() {
        // RED: Should fail until deterministic behavior is ensured
        let testTokenIds = Array<Int32>(1...100)
        let numRuns = 10
        var tensorHashes: Set<String> = []

        for run in 0..<numRuns {
            do {
                let tensor = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: testTokenIds)

                // Create a hash of the tensor data for comparison
                let tensorData = (0..<min(100, tensor.count)).map { tensor[$0].int32Value }
                let tensorHash = String(describing: tensorData)
                tensorHashes.insert(tensorHash)

            } catch {
                XCTFail("Deterministic test run \(run) failed: \(error)")
            }
        }

        // All runs should produce identical results
        XCTAssertEqual(tensorHashes.count, 1,
                      "All runs should produce identical tensors (deterministic behavior)")
    }

    /// MoP: Baseline Comparison - Compare with previous implementation
    /// DoS: New implementation should meet or exceed baseline performance
    func testPerformanceRegressionPrevention() {
        // RED: Should fail until baseline comparison is implemented
        let testTokenIds = Array<Int32>(1...256)
        let iterations = 50

        // Measure new rank-4 implementation
        var newImplementationTimes: [TimeInterval] = []
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            do {
                _ = try LFM2TensorRankFix.createRank4TokenTensor(tokenIds: testTokenIds)
            } catch {
                XCTFail("New implementation test failed: \(error)")
            }
            let endTime = CFAbsoluteTimeGetCurrent()
            newImplementationTimes.append(endTime - startTime)
        }

        // Measure legacy rank-2 implementation (for comparison)
        var legacyImplementationTimes: [TimeInterval] = []
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            do {
                _ = try LFM2TensorRankFix.createRank2TokenTensor(tokenIds: testTokenIds)
            } catch {
                XCTFail("Legacy implementation test failed: \(error)")
            }
            let endTime = CFAbsoluteTimeGetCurrent()
            legacyImplementationTimes.append(endTime - startTime)
        }

        let newAverage = newImplementationTimes.reduce(0, +) / Double(iterations)
        let legacyAverage = legacyImplementationTimes.reduce(0, +) / Double(iterations)

        // New implementation should not be significantly slower than legacy
        // Allow for reasonable overhead due to increased functionality
        let acceptableOverhead = 3.0 // 3x overhead is acceptable for the additional functionality
        XCTAssertLessThan(newAverage, legacyAverage * acceptableOverhead,
                         "New implementation should not exceed \(acceptableOverhead)x legacy performance")

        print("Performance comparison - Legacy: \(String(format: "%.4f", legacyAverage))s, New: \(String(format: "%.4f", newAverage))s")
    }
}

// MARK: - Test Validation Helpers

extension TensorOperationsTests {

    /// Validate the quality and properties of generated embeddings
    func validateEmbeddingQuality(_ embedding: [Float], documentIndex: Int) {
        // Basic quality checks
        XCTAssertEqual(embedding.count, 768, "Document \(documentIndex): Should have 768 dimensions")
        XCTAssertFalse(embedding.contains { $0.isNaN }, "Document \(documentIndex): Should not contain NaN")
        XCTAssertFalse(embedding.contains { $0.isInfinite }, "Document \(documentIndex): Should not contain infinite values")

        // Statistical quality checks
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        XCTAssertGreaterThan(magnitude, 0.1, "Document \(documentIndex): Should have reasonable magnitude")
        XCTAssertLessThan(magnitude, 100.0, "Document \(documentIndex): Should not have excessive magnitude")

        // Check for reasonable distribution (not all zeros or ones)
        let nonZeroCount = embedding.filter { $0 != 0 }.count
        XCTAssertGreaterThan(nonZeroCount, 100, "Document \(documentIndex): Should have sufficient non-zero values")
    }

    /// Validate consistency and distinctiveness across multiple embeddings
    func validateEmbeddingConsistency(_ embeddings: [[Float]]) {
        guard embeddings.count > 1 else { return }

        // Check that embeddings are distinct (not identical)
        for i in 0..<embeddings.count {
            for j in (i+1)..<embeddings.count {
                let similarity = cosineSimilarity(embeddings[i], embeddings[j])

                // Embeddings should be distinct but not completely unrelated
                XCTAssertLessThan(similarity, 0.99, "Embeddings \(i) and \(j) should be distinct")
                XCTAssertGreaterThan(similarity, 0.1, "Embeddings \(i) and \(j) should have some relatedness")
            }
        }
    }

    /// Calculate cosine similarity between two vectors
    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    /// Create test data with specific characteristics for stress testing
    func createStressTestData(count: Int, maxTokenLength: Int) -> [[Int32]] {
        return (0..<count).map { index in
            let length = (index % maxTokenLength) + 1
            return Array<Int32>(1...Int32(length))
        }
    }
}
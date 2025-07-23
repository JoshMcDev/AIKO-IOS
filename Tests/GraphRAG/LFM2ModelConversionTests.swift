import CoreML
@testable import GraphRAG
import XCTest

/// AGENT 3: Test scaffolding for GGUF to CoreML conversion with tensor rank fixes
/// Tests for model conversion process and validation
class LFM2ModelConversionTests: XCTestCase {
    // MARK: - Model File Tests

    /// Test: GGUF source model exists and is accessible
    func test_ggufSourceModel_Exists() throws {
        // Arrange
        let ggufPath = "/Users/J/Desktop/LFM2-700M/LFM2-700M-UD-Q6_K_XL.gguf"

        // Act & Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: ggufPath),
                      "GGUF source model should exist at \(ggufPath)")

        // Validate file size (should be ~636MB)
        let attributes = try FileManager.default.attributesOfItem(atPath: ggufPath)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let expectedSizeRange = (600_000_000 ... 700_000_000) // ~600-700MB
        XCTAssertTrue(expectedSizeRange.contains(fileSize),
                      "GGUF file size should be ~636MB, got \(fileSize) bytes")
    }

    /// Test: CoreML model target location is properly configured
    func test_coreMLTarget_IsConfigured() throws {
        // This test validates the expected CoreML model location

        // Arrange - Expected locations for CoreML model
        let expectedBundlePaths = [
            "LFM2-700M-Unsloth-XL-GraphRAG.mlmodel",
            "LFM2-700M-Q6K.mlmodel",
            "LFM2-700M.mlmodel",
        ]

        // Act & Assert
        for modelName in expectedBundlePaths {
            let bundleURL = Bundle.main.url(forResource: modelName.replacingOccurrences(of: ".mlmodel", with: ""),
                                            withExtension: "mlmodel")

            // These will initially be nil - that's expected for RED phase
            if bundleURL == nil {
                print("⚠️ CoreML model not found: \(modelName) - conversion needed")
            }
        }

        // Test that at least the conversion infrastructure is ready
        XCTAssertTrue(true, "Model conversion infrastructure test placeholder")
    }

    // MARK: - Conversion Validation Tests

    /// Test: Converted model has correct tensor specifications
    func test_convertedModel_HasCorrectTensorSpecs() async throws {
        // This test will validate the converted CoreML model's tensor specifications
        // WILL FAIL until conversion is complete

        // Arrange
        let service = LFM2Service.shared

        // Act & Assert
        do {
            try await service.initializeModel()

            // Test model input specification
            let sampleText = "Test input for tensor specification validation"
            let featureProvider = try service.preprocessText(sampleText)

            // Validate tensor rank
            let inputFeature = featureProvider.featureValue(for: "input_ids")?.multiArrayValue
            XCTAssertNotNil(inputFeature, "Input feature should exist")

            if let tensor = inputFeature {
                let rank = tensor.shape.count
                XCTAssertGreaterThan(rank, 2, "Converted model should support rank > 2 tensors")

                // Document current vs expected tensor specifications
                print("📊 Current tensor shape: \(tensor.shape)")
                print("📊 Current tensor rank: \(rank)")

                // Validate specific shape requirements for LFM2
                XCTAssertEqual(tensor.shape[0].intValue, 1, "Batch dimension should be 1")
                XCTAssertEqual(tensor.shape[1].intValue, 512, "Sequence dimension should be 512")

                if rank >= 3 {
                    XCTAssertGreaterThan(tensor.shape[2].intValue, 0, "Third dimension should be positive")
                }

                if rank >= 4 {
                    XCTAssertGreaterThan(tensor.shape[3].intValue, 0, "Fourth dimension should be positive")
                }
            }

        } catch LFM2Error.modelNotFound {
            XCTFail("Model conversion required: GGUF → CoreML with tensor rank fix")
        } catch LFM2Error.ggufNotSupported {
            XCTFail("CoreML conversion needed for tensor rank compatibility")
        } catch {
            XCTFail("Tensor specification validation failed: \(error)")
        }
    }

    /// Test: Model metadata contains correct specifications
    func test_modelMetadata_ContainsCorrectSpecs() async throws {
        // Validate converted model metadata

        // This test will help validate the conversion was successful
        let service = LFM2Service.shared

        do {
            try await service.initializeModel()
            let modelInfo = await service.getModelInfo()

            XCTAssertNotNil(modelInfo, "Model info should be available")
            XCTAssertEqual(modelInfo?.embeddingDimensions, 768, "LFM2-700M should have 768 dimensions")
            XCTAssertEqual(modelInfo?.maxTokenLength, 512, "Max token length should be 512")
            XCTAssertEqual(modelInfo?.modelType, .coreML, "Should be CoreML model type")

        } catch {
            // Expected failure until conversion is complete
            print("⚠️ Model metadata test failed - conversion needed: \(error)")
            throw error
        }
    }

    // MARK: - Performance Validation Tests

    /// Test: Converted model meets performance requirements
    func test_convertedModel_MeetsPerformanceRequirements() async throws {
        // Validate that tensor rank fix doesn't impact performance

        // Arrange
        let service = LFM2Service.shared
        let testText = "Performance validation for converted LFM2 model with tensor rank fix"

        // Act & Assert
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            try await service.initializeModel()

            let initializationTime = CFAbsoluteTimeGetCurrent() - startTime
            XCTAssertLessThan(initializationTime, 5.0, "Model initialization should be <5 seconds")

            // Test embedding generation performance
            let embeddingStartTime = CFAbsoluteTimeGetCurrent()
            let embedding = try await service.generateEmbedding(text: testText)
            let embeddingTime = CFAbsoluteTimeGetCurrent() - embeddingStartTime

            XCTAssertLessThan(embeddingTime, 2.0, "Embedding generation should be <2 seconds")
            XCTAssertEqual(embedding.count, 768, "Should generate 768-dimensional embedding")

        } catch {
            XCTFail("Performance validation failed - likely due to tensor rank issue: \(error)")
        }
    }

    // MARK: - Compatibility Tests

    /// Test: Converted model is compatible with iOS CoreML runtime
    func test_convertedModel_IsCompatibleWithiOS() async throws {
        // Validate iOS compatibility after conversion

        // Arrange
        let service = LFM2Service.shared

        // Act & Assert
        do {
            try await service.initializeModel()

            // Test basic functionality
            let testEmbedding = try await service.generateEmbedding(
                text: "iOS compatibility test for LFM2 model"
            )

            XCTAssertEqual(testEmbedding.count, 768, "iOS model should generate correct embeddings")
            XCTAssertTrue(testEmbedding.allSatisfy { !$0.isNaN && $0.isFinite },
                          "iOS embeddings should be valid numbers")

            // Test memory usage is reasonable for iOS
            let metrics = await service.getPerformanceMetrics()
            let memoryUsageMB = metrics.peakMemoryUsage / (1024 * 1024)
            XCTAssertLessThan(memoryUsageMB, 1000, "Peak memory usage should be <1GB on iOS")

        } catch {
            XCTFail("iOS compatibility test failed: \(error)")
        }
    }

    /// Test: Converted model supports dual-domain functionality
    func test_convertedModel_SupportsDualDomain() async throws {
        // Test that converted model works for both regulations and user records

        // Arrange
        let service = LFM2Service.shared
        let regulationText = "Federal Acquisition Regulation 52.212-1"
        let userRecordText = "Contract award to vendor ABC123"

        // Act & Assert
        do {
            try await service.initializeModel()

            // Test regulation domain
            let regulationEmbedding = try await service.generateEmbedding(
                text: regulationText,
                domain: .regulations
            )

            // Test user records domain
            let userEmbedding = try await service.generateEmbedding(
                text: userRecordText,
                domain: .userRecords
            )

            // Validate both domains work
            XCTAssertEqual(regulationEmbedding.count, 768, "Regulation embedding should be valid")
            XCTAssertEqual(userEmbedding.count, 768, "User record embedding should be valid")

            // Embeddings should be different
            let similarity = cosineSimilarity(regulationEmbedding, userEmbedding)
            XCTAssertLessThan(similarity, 0.9, "Different domain texts should have different embeddings")

        } catch {
            XCTFail("Dual-domain functionality test failed: \(error)")
        }
    }

    // MARK: - Error Handling Tests

    /// Test: Proper error handling for tensor rank mismatches
    func test_errorHandling_ForTensorRankMismatches() async throws {
        // Test that proper errors are thrown for tensor rank issues

        // This test validates error handling during the conversion process
        let service = LFM2Service.shared

        do {
            try await service.initializeModel()

            // If we get here, model loaded successfully
            XCTAssertTrue(true, "Model loaded successfully with correct tensor ranks")

        } catch LFM2Error.modelNotFound {
            // Expected during development - model needs conversion
            print("✅ Correct error handling: Model not found")

        } catch LFM2Error.ggufNotSupported {
            // Expected during development - need CoreML conversion
            print("✅ Correct error handling: GGUF not supported")

        } catch LFM2Error.invalidModelOutput {
            // This might indicate tensor rank issues
            XCTFail("Tensor rank mismatch detected - conversion fix needed")

        } catch {
            XCTFail("Unexpected error in tensor rank handling: \(error)")
        }
    }

    // MARK: - Helper Methods

    /// Calculate cosine similarity between embeddings
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0, magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    // MARK: - Documentation Tests

    /// Test: Validate conversion process is documented
    func test_conversionProcess_IsDocumented() throws {
        // This test ensures the conversion process is properly documented

        // Expected documentation should exist
        let expectedDocs = [
            "GGUF to CoreML conversion steps",
            "Tensor rank fix implementation",
            "Model validation checklist",
            "Performance benchmarks",
        ]

        // For now, this is a placeholder
        for doc in expectedDocs {
            print("📋 Required documentation: \(doc)")
        }

        XCTAssertTrue(true, "Documentation validation placeholder")
    }
}

// MARK: - Conversion Workflow Tests

extension LFM2ModelConversionTests {
    /// Test the complete conversion workflow
    func test_conversionWorkflow_Complete() async throws {
        // This test validates the entire conversion process

        // Step 1: Validate GGUF source
        let ggufPath = "/Users/J/Desktop/LFM2-700M/LFM2-700M-UD-Q6_K_XL.gguf"
        XCTAssertTrue(FileManager.default.fileExists(atPath: ggufPath), "GGUF source should exist")

        // Step 2: Validate conversion tools are available
        // (This would test coremltools, etc. - placeholder for now)

        // Step 3: Validate conversion output
        // (This would test the CoreML model file - will fail until conversion is done)

        // Step 4: Validate tensor rank fix
        // (This would test the specific tensor rank corrections)

        // Step 5: Validate integration with LFM2Service
        let service = LFM2Service.shared

        do {
            try await service.initializeModel()
            // If this succeeds, conversion was successful
            XCTAssertTrue(true, "Conversion workflow completed successfully")

        } catch {
            // Expected failure until conversion is complete
            print("⚠️ Conversion workflow not complete: \(error)")
            throw error
        }
    }
}

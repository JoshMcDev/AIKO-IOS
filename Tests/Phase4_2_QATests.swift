@testable import AppCore
import XCTest

/// QA Tests for Phase 4.2: Professional Document Scanner Implementation
/// Tests platform-agnostic components without cross-platform dependencies
final class Phase4_2_QATests: XCTestCase {
    func testDocumentImageProcessorAvailability() {
        // Test that DocumentImageProcessor dependency is available
        withDependencies {
            $0.documentImageProcessor = DocumentImageProcessor.testValue
        } operation: {
            @Dependency(\.documentImageProcessor) var processor

            // Test basic availability
            XCTAssertTrue(processor.isProcessingModeAvailable(.basic))
            XCTAssertTrue(processor.isProcessingModeAvailable(.enhanced))
            XCTAssertTrue(processor.isProcessingModeAvailable(.documentScanner))
        }
    }

    func testDocumentImageProcessorBasicProcessing() async throws {
        withDependencies {
            $0.documentImageProcessor = DocumentImageProcessor.testValue
        } operation: {
            @Dependency(\.documentImageProcessor) var processor

            // Create test image data
            let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header

            let result = try await processor.processImage(
                testImageData,
                .basic,
                ProcessingOptions()
            )

            // Verify result structure
            XCTAssertFalse(result.processedImageData.isEmpty)
            XCTAssertGreaterThan(result.qualityMetrics.overallConfidence, 0.0)
            XCTAssertLessThanOrEqual(result.qualityMetrics.overallConfidence, 1.0)
            XCTAssertGreaterThan(result.processingTime, 0.0)
            XCTAssertFalse(result.appliedFilters.isEmpty)
            XCTAssertTrue(result.qualityMetrics.recommendedForOCR)
        }
    }

    func testDocumentImageProcessorEnhancedProcessing() async throws {
        withDependencies {
            $0.documentImageProcessor = DocumentImageProcessor.testValue
        } operation: {
            @Dependency(\.documentImageProcessor) var processor

            let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header

            let result = try await processor.processImage(
                testImageData,
                .enhanced,
                ProcessingOptions(qualityTarget: .quality, optimizeForOCR: true)
            )

            // Enhanced mode should have higher quality metrics
            XCTAssertGreaterThan(result.qualityMetrics.overallConfidence, 0.7)
            XCTAssertGreaterThan(result.qualityMetrics.sharpnessScore, 0.0)
            XCTAssertGreaterThan(result.qualityMetrics.contrastScore, 0.0)
            XCTAssertLessThan(result.qualityMetrics.noiseLevel, 1.0)
            XCTAssertGreaterThan(result.qualityMetrics.textClarity, 0.0)
        }
    }

    func testDocumentImageProcessorProgressCallback() async throws {
        var progressUpdates: [ProcessingProgress] = []

        withDependencies {
            $0.documentImageProcessor = DocumentImageProcessor.testValue
        } operation: {
            @Dependency(\.documentImageProcessor) var processor

            let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])

            let options = ProcessingOptions(
                progressCallback: { progress in
                    progressUpdates.append(progress)
                },
                qualityTarget: .balanced
            )

            let _ = try await processor.processImage(testImageData, .enhanced, options)

            // Verify progress callback was called
            XCTAssertFalse(progressUpdates.isEmpty)

            if let lastProgress = progressUpdates.last {
                XCTAssertGreaterThanOrEqual(lastProgress.overallProgress, 0.0)
                XCTAssertLessThanOrEqual(lastProgress.overallProgress, 1.0)
                XCTAssertGreaterThanOrEqual(lastProgress.stepProgress, 0.0)
                XCTAssertLessThanOrEqual(lastProgress.stepProgress, 1.0)
            }
        }
    }

    func testProcessingTimeEstimation() async throws {
        withDependencies {
            $0.documentImageProcessor = DocumentImageProcessor.testValue
        } operation: {
            @Dependency(\.documentImageProcessor) var processor

            let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])

            let basicTime = try await processor.estimateProcessingTime(testImageData, .basic)
            let enhancedTime = try await processor.estimateProcessingTime(testImageData, .enhanced)

            // Enhanced mode should take longer than basic
            XCTAssertGreaterThan(enhancedTime, basicTime)
            XCTAssertGreaterThan(basicTime, 0.0)
        }
    }

    func testQualityMetricsValidation() {
        // Test QualityMetrics initialization and validation
        let metrics = QualityMetrics(
            overallConfidence: 0.85,
            sharpnessScore: 0.9,
            contrastScore: 0.8,
            noiseLevel: 0.2,
            textClarity: 0.85,
            edgeDetectionConfidence: 0.7,
            perspectiveCorrectionAccuracy: 0.9,
            recommendedForOCR: true
        )

        XCTAssertEqual(metrics.overallConfidence, 0.85)
        XCTAssertEqual(metrics.sharpnessScore, 0.9)
        XCTAssertEqual(metrics.contrastScore, 0.8)
        XCTAssertEqual(metrics.noiseLevel, 0.2)
        XCTAssertEqual(metrics.textClarity, 0.85)
        XCTAssertEqual(metrics.edgeDetectionConfidence, 0.7)
        XCTAssertEqual(metrics.perspectiveCorrectionAccuracy, 0.9)
        XCTAssertTrue(metrics.recommendedForOCR)
    }

    func testProcessingOptionsEquality() {
        let options1 = ProcessingOptions(
            qualityTarget: .balanced,
            preserveColors: true,
            optimizeForOCR: true
        )

        let options2 = ProcessingOptions(
            qualityTarget: .balanced,
            preserveColors: true,
            optimizeForOCR: true
        )

        let options3 = ProcessingOptions(
            qualityTarget: .quality,
            preserveColors: false,
            optimizeForOCR: false
        )

        // Test equality (ignoring progressCallback)
        XCTAssertEqual(options1, options2)
        XCTAssertNotEqual(options1, options3)
    }

    func testProcessingModeDisplayNames() {
        XCTAssertEqual(ProcessingMode.basic.displayName, "Basic Enhancement")
        XCTAssertEqual(ProcessingMode.enhanced.displayName, "Advanced Enhancement")
        XCTAssertEqual(ProcessingMode.documentScanner.displayName, "Document Scanner")
    }

    func testQualityTargetDisplayNames() {
        XCTAssertEqual(QualityTarget.speed.displayName, "Fast")
        XCTAssertEqual(QualityTarget.balanced.displayName, "Balanced")
        XCTAssertEqual(QualityTarget.quality.displayName, "High Quality")
    }

    func testProcessingStepDisplayNames() {
        XCTAssertEqual(ProcessingStep.preprocessing.displayName, "Preprocessing")
        XCTAssertEqual(ProcessingStep.edgeDetection.displayName, "Detecting Edges")
        XCTAssertEqual(ProcessingStep.perspectiveCorrection.displayName, "Correcting Perspective")
        XCTAssertEqual(ProcessingStep.enhancement.displayName, "Enhancing")
        XCTAssertEqual(ProcessingStep.denoising.displayName, "Removing Noise")
        XCTAssertEqual(ProcessingStep.sharpening.displayName, "Sharpening")
        XCTAssertEqual(ProcessingStep.optimization.displayName, "Optimizing")
        XCTAssertEqual(ProcessingStep.qualityAnalysis.displayName, "Analyzing Quality")
    }
}

import XCTest
import AppCore
import ComposableArchitecture

#if os(iOS)
import AIKOiOS
#endif

@MainActor
final class DocumentImageProcessorTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        #if os(iOS)
        // Register iOS dependencies for testing
        await iOSDependencyRegistration.configureForLaunch()
        #endif
    }
    
    // MARK: - Basic Functionality Tests
    
    func testProcessingModeAvailability() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        // Test that both processing modes are available
        XCTAssertTrue(processor.isProcessingModeAvailable(.basic))
        XCTAssertTrue(processor.isProcessingModeAvailable(.enhanced))
    }
    
    func testTimeEstimation() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let sampleData = createSampleImageData()
        
        // Test time estimation for both modes
        let basicTime = try await processor.estimateProcessingTime(sampleData, .basic)
        let enhancedTime = try await processor.estimateProcessingTime(sampleData, .enhanced)
        
        // Enhanced mode should take longer
        XCTAssertGreaterThan(enhancedTime, basicTime)
        
        // Times should be reasonable (not negative, not excessive)
        XCTAssertGreaterThan(basicTime, 0)
        XCTAssertLessThan(basicTime, 10) // Should be under 10 seconds
        XCTAssertLessThan(enhancedTime, 30) // Enhanced should be under 30 seconds
    }
    
    func testBasicProcessing() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let imageData = createSampleImageData()
        let options = ProcessingOptions(qualityTarget: .speed)
        
        let result = try await processor.processImage(imageData, .basic, options)
        
        // Verify result structure
        XCTAssertFalse(result.processedImageData.isEmpty)
        XCTAssertGreaterThan(result.processingTime, 0)
        XCTAssertFalse(result.appliedFilters.isEmpty)
        
        // Verify quality metrics
        let metrics = result.qualityMetrics
        XCTAssertGreaterThanOrEqual(metrics.overallConfidence, 0.0)
        XCTAssertLessThanOrEqual(metrics.overallConfidence, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.sharpnessScore, 0.0)
        XCTAssertLessThanOrEqual(metrics.sharpnessScore, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.contrastScore, 0.0)
        XCTAssertLessThanOrEqual(metrics.contrastScore, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.noiseLevel, 0.0)
        XCTAssertLessThanOrEqual(metrics.noiseLevel, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.textClarity, 0.0)
        XCTAssertLessThanOrEqual(metrics.textClarity, 1.0)
    }
    
    func testEnhancedProcessing() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let imageData = createSampleImageData()
        let options = ProcessingOptions(qualityTarget: .quality)
        
        let result = try await processor.processImage(imageData, .enhanced, options)
        
        // Verify result structure
        XCTAssertFalse(result.processedImageData.isEmpty)
        XCTAssertGreaterThan(result.processingTime, 0)
        XCTAssertFalse(result.appliedFilters.isEmpty)
        
        // Enhanced mode should apply more filters
        XCTAssertGreaterThanOrEqual(result.appliedFilters.count, 3)
        
        // Verify quality metrics
        let metrics = result.qualityMetrics
        XCTAssertGreaterThanOrEqual(metrics.overallConfidence, 0.0)
        XCTAssertLessThanOrEqual(metrics.overallConfidence, 1.0)
    }
    
    func testProgressReporting() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let imageData = createSampleImageData()
        var progressUpdates: [ProcessingProgress] = []
        
        let options = ProcessingOptions(
            progressCallback: { progress in
                progressUpdates.append(progress)
            },
            qualityTarget: .balanced
        )
        
        let result = try await processor.processImage(imageData, .enhanced, options)
        
        // Verify progress was reported
        XCTAssertFalse(progressUpdates.isEmpty)
        
        // Verify progress values are valid
        for progress in progressUpdates {
            XCTAssertGreaterThanOrEqual(progress.stepProgress, 0.0)
            XCTAssertLessThanOrEqual(progress.stepProgress, 1.0)
            XCTAssertGreaterThanOrEqual(progress.overallProgress, 0.0)
            XCTAssertLessThanOrEqual(progress.overallProgress, 1.0)
        }
        
        // Verify final progress is complete
        if let lastProgress = progressUpdates.last {
            XCTAssertEqual(lastProgress.overallProgress, 1.0, accuracy: 0.01)
        }
        
        XCTAssertFalse(result.processedImageData.isEmpty)
    }
    
    // MARK: - Quality Comparison Tests
    
    func testQualityComparison() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let imageData = createSampleImageData()
        
        // Process with both modes
        let basicResult = try await processor.processImage(
            imageData,
            .basic,
            ProcessingOptions(qualityTarget: .speed)
        )
        
        let enhancedResult = try await processor.processImage(
            imageData,
            .enhanced,
            ProcessingOptions(qualityTarget: .quality)
        )
        
        // Enhanced mode should generally produce better quality
        // (though this may not always be true for all images)
        XCTAssertGreaterThanOrEqual(
            enhancedResult.qualityMetrics.overallConfidence,
            basicResult.qualityMetrics.overallConfidence - 0.1 // Allow some tolerance
        )
        
        // Enhanced mode should take longer
        XCTAssertGreaterThan(enhancedResult.processingTime, basicResult.processingTime)
        
        // Enhanced mode should apply more filters
        XCTAssertGreaterThanOrEqual(
            enhancedResult.appliedFilters.count,
            basicResult.appliedFilters.count
        )
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidImageData() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let invalidData = Data("invalid image data".utf8)
        let options = ProcessingOptions()
        
        do {
            _ = try await processor.processImage(invalidData, .basic, options)
            XCTFail("Should have thrown an error for invalid image data")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is ProcessingError)
        }
    }
    
    func testEmptyImageData() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let emptyData = Data()
        let options = ProcessingOptions()
        
        do {
            _ = try await processor.processImage(emptyData, .basic, options)
            XCTFail("Should have thrown an error for empty image data")
        } catch {
            // Expected to throw an error
            XCTAssertTrue(error is ProcessingError)
        }
    }
    
    // MARK: - Integration Tests
    
    func testDocumentScannerIntegration() async throws {
        @Dependency(\.documentScanner) var scanner
        
        let imageData = createSampleImageData()
        
        // Test backward compatibility - basic enhanceImage method
        let basicEnhanced = try await scanner.enhanceImage(imageData)
        XCTAssertFalse(basicEnhanced.isEmpty)
        
        // Test new advanced method
        let advancedResult = try await scanner.enhanceImageAdvanced(
            imageData,
            .enhanced,
            ProcessingOptions(qualityTarget: .quality)
        )
        
        XCTAssertFalse(advancedResult.processedImageData.isEmpty)
        XCTAssertGreaterThan(advancedResult.processingTime, 0)
        XCTAssertFalse(advancedResult.appliedFilters.isEmpty)
        
        // Test time estimation
        let estimatedTime = try await scanner.estimateProcessingTime(imageData, .enhanced)
        XCTAssertGreaterThan(estimatedTime, 0)
        
        // Test mode availability
        XCTAssertTrue(scanner.isProcessingModeAvailable(.basic))
        XCTAssertTrue(scanner.isProcessingModeAvailable(.enhanced))
    }
    
    func testScannedPageIntegration() async throws {
        @Dependency(\.documentScanner) var scanner
        
        let imageData = createSampleImageData()
        
        // Create a scanned page
        var page = ScannedPage(
            imageData: imageData,
            pageNumber: 1,
            processingState: .pending
        )
        
        // Process the page
        let result = try await scanner.enhanceImageAdvanced(
            page.imageData,
            .enhanced,
            ProcessingOptions(qualityTarget: .balanced)
        )
        
        // Update page with results
        page.enhancedImageData = result.processedImageData
        page.qualityMetrics = result.qualityMetrics
        page.processingMode = .enhanced
        page.processingResult = result
        page.enhancementApplied = true
        page.processingState = .completed
        
        // Verify page state
        XCTAssertTrue(page.enhancementApplied)
        XCTAssertEqual(page.processingMode, .enhanced)
        XCTAssertEqual(page.processingState, .completed)
        XCTAssertNotNil(page.qualityMetrics)
        XCTAssertNotNil(page.processingResult)
        XCTAssertNotNil(page.enhancedImageData)
    }
    
    // MARK: - Performance Tests
    
    func testProcessingPerformance() async throws {
        @Dependency(\.documentImageProcessor) var processor
        
        let imageData = createSampleImageData()
        let options = ProcessingOptions(qualityTarget: .speed)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await processor.processImage(imageData, .basic, options)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let actualTime = endTime - startTime
        
        // Processing should complete within reasonable time
        XCTAssertLessThan(actualTime, 5.0) // 5 seconds max for basic mode
        
        // Reported time should be close to actual time
        XCTAssertLessThan(abs(result.processingTime - actualTime), 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleImageData() -> Data {
        let size = CGSize(width: 400, height: 300)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return Data()
        }
        
        // Create a simple test image
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 50, y: 50, width: 300, height: 200))
        
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 60, y: 60, width: 280, height: 180))
        
        // Add some text-like patterns
        context.setFillColor(UIColor.black.cgColor)
        for i in 0..<8 {
            let y = 70 + (i * 20)
            context.fill(CGRect(x: 70, y: y, width: 200, height: 10))
        }
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.jpegData(compressionQuality: 0.8) else {
            return Data()
        }
        
        return data
    }
}
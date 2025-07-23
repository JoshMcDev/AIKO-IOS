import AppCore
import ComposableArchitecture
import XCTest

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

    // MARK: - OCR Tests (RED Phase - Failing Tests)

    func testOCRAvailability() async throws {
        @Dependency(\.documentImageProcessor) var processor

        // Test OCR availability - this should pass
        XCTAssertTrue(processor.isOCRAvailable(), "OCR should be available on iOS 13.0+")
    }

    func testBasicTextExtraction() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleImageWithText()
        let options = DocumentImageProcessor.OCROptions(
            language: .english,
            recognitionLevel: .accurate
        )

        // This test will FAIL initially because the actual OCR implementation
        // needs to be connected to the live implementation
        let result = try await processor.extractText(imageData, options)

        // Verify OCR result structure
        XCTAssertFalse(result.extractedText.isEmpty, "Should extract at least some text")
        XCTAssertFalse(result.fullText.isEmpty, "Full text should not be empty")
        XCTAssertGreaterThan(result.confidence, 0.0, "Confidence should be greater than 0")
        XCTAssertLessThanOrEqual(result.confidence, 1.0, "Confidence should not exceed 1.0")
        XCTAssertGreaterThan(result.processingTime, 0.0, "Processing time should be recorded")
        XCTAssertFalse(result.detectedLanguages.isEmpty, "Should detect at least one language")

        // Verify extracted text elements
        for extractedText in result.extractedText {
            XCTAssertFalse(extractedText.text.isEmpty, "Extracted text should not be empty")
            XCTAssertGreaterThan(extractedText.confidence, 0.0, "Text confidence should be greater than 0")
            XCTAssertLessThanOrEqual(extractedText.confidence, 1.0, "Text confidence should not exceed 1.0")

            // Verify bounding box is valid
            XCTAssertGreaterThan(extractedText.boundingBox.width, 0, "Bounding box width should be positive")
            XCTAssertGreaterThan(extractedText.boundingBox.height, 0, "Bounding box height should be positive")
        }
    }

    func testOCRProgressReporting() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleImageWithText()
        var progressUpdates: [OCRProgress] = []

        let options = DocumentImageProcessor.OCROptions(
            progressCallback: { progress in
                progressUpdates.append(progress)
            },
            recognitionLevel: .accurate
        )

        // This test will FAIL initially - OCR progress reporting needs implementation
        let result = try await processor.extractText(imageData, options)

        // Verify progress was reported
        XCTAssertFalse(progressUpdates.isEmpty, "Progress updates should be reported")

        // Verify progress sequence includes expected steps
        let reportedSteps = Set(progressUpdates.map(\.currentStep))
        XCTAssertTrue(reportedSteps.contains(.preprocessing), "Should report preprocessing step")
        XCTAssertTrue(reportedSteps.contains(.textRecognition), "Should report text recognition step")

        // Verify progress values are valid
        for progress in progressUpdates {
            XCTAssertGreaterThanOrEqual(progress.stepProgress, 0.0, "Step progress should be >= 0")
            XCTAssertLessThanOrEqual(progress.stepProgress, 1.0, "Step progress should be <= 1")
            XCTAssertGreaterThanOrEqual(progress.overallProgress, 0.0, "Overall progress should be >= 0")
            XCTAssertLessThanOrEqual(progress.overallProgress, 1.0, "Overall progress should be <= 1")
            XCTAssertGreaterThanOrEqual(progress.recognizedTextCount, 0, "Recognized text count should be >= 0")
        }

        // Verify final progress shows completion
        if let lastProgress = progressUpdates.last {
            XCTAssertEqual(lastProgress.overallProgress, 1.0, accuracy: 0.01, "Final progress should be 100%")
        }

        XCTAssertFalse(result.processedImageData.isEmpty)
    }

    func testLanguageDetection() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleImageWithText()
        let options = DocumentImageProcessor.OCROptions(
            automaticLanguageDetection: true,
            language: .automatic
        )

        // This test will FAIL initially - language detection needs proper implementation
        let result = try await processor.extractText(imageData, options)

        // Verify language detection
        XCTAssertFalse(result.detectedLanguages.isEmpty, "Should detect at least one language")

        // For English text, should detect English
        if result.fullText.contains("Sample") || result.fullText.contains("text") {
            XCTAssertTrue(result.detectedLanguages.contains(.english), "Should detect English language")
        }
    }

    func testStructuredDataExtractionInvoice() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleInvoiceImage()
        let options = DocumentImageProcessor.OCROptions(
            language: .english,
            recognitionLevel: .accurate
        )

        // This test will FAIL initially - structured data extraction needs implementation
        let result = try await processor.extractStructuredData(imageData, .invoice, options)

        // Verify structured result
        XCTAssertEqual(result.documentType, .invoice, "Document type should be invoice")
        XCTAssertGreaterThan(result.structureConfidence, 0.0, "Structure confidence should be > 0")
        XCTAssertLessThanOrEqual(result.structureConfidence, 1.0, "Structure confidence should be <= 1")

        // Verify OCR result is included
        XCTAssertFalse(result.ocrResult.fullText.isEmpty, "OCR result should contain text")

        // Verify invoice-specific fields are extracted
        let fields = result.extractedFields
        XCTAssertFalse(fields.isEmpty, "Should extract some structured fields")

        // Look for typical invoice fields
        let expectedFields = ["invoice_number", "date", "total_amount", "total", "amount"]
        let hasExpectedField = expectedFields.contains { fields.keys.contains($0) }
        XCTAssertTrue(hasExpectedField, "Should extract at least one expected invoice field")
    }

    func testStructuredDataExtractionReceipt() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleReceiptImage()
        let options = DocumentImageProcessor.OCROptions(
            language: .english,
            recognitionLevel: .fast
        )

        // This test will FAIL initially - receipt extraction needs implementation
        let result = try await processor.extractStructuredData(imageData, .receipt, options)

        // Verify structured result
        XCTAssertEqual(result.documentType, .receipt, "Document type should be receipt")
        XCTAssertGreaterThan(result.structureConfidence, 0.0, "Structure confidence should be > 0")

        // Verify receipt-specific fields
        let fields = result.extractedFields
        let expectedFields = ["store_name", "total", "amount", "date"]
        let hasExpectedField = expectedFields.contains { fields.keys.contains($0) }
        XCTAssertTrue(hasExpectedField, "Should extract at least one expected receipt field")
    }

    func testStructuredDataExtractionBusinessCard() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleBusinessCardImage()
        let options = DocumentImageProcessor.OCROptions(
            language: .english,
            recognitionLevel: .accurate
        )

        // This test will FAIL initially - business card extraction needs implementation
        let result = try await processor.extractStructuredData(imageData, .businessCard, options)

        // Verify structured result
        XCTAssertEqual(result.documentType, .businessCard, "Document type should be business card")

        // Verify business card specific fields
        let fields = result.extractedFields
        let expectedFields = ["name", "company", "phone", "email", "title"]
        let hasExpectedField = expectedFields.contains { fields.keys.contains($0) }
        XCTAssertTrue(hasExpectedField, "Should extract at least one expected business card field")
    }

    func testOCRWithDifferentLanguages() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleImageWithText()

        // Test different language settings
        let languages: [DocumentImageProcessor.OCRLanguage] = [.english, .spanish, .french]

        for language in languages {
            let options = DocumentImageProcessor.OCROptions(
                language: language,
                automaticLanguageDetection: false
            )

            // This test will FAIL initially - language-specific OCR needs implementation
            let result = try await processor.extractText(imageData, options)

            XCTAssertFalse(result.fullText.isEmpty, "Should extract text for language: \(language.displayName)")
            XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence > 0 for language: \(language.displayName)")
        }
    }

    func testOCRWithDifferentRecognitionLevels() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleImageWithText()

        // Test both recognition levels
        let fastOptions = DocumentImageProcessor.OCROptions(recognitionLevel: .fast)
        let accurateOptions = DocumentImageProcessor.OCROptions(recognitionLevel: .accurate)

        // This test will FAIL initially - recognition level handling needs implementation
        let fastResult = try await processor.extractText(imageData, fastOptions)
        let accurateResult = try await processor.extractText(imageData, accurateOptions)

        // Both should produce results
        XCTAssertFalse(fastResult.fullText.isEmpty, "Fast recognition should extract text")
        XCTAssertFalse(accurateResult.fullText.isEmpty, "Accurate recognition should extract text")

        // Accurate mode might take longer (though not guaranteed)
        XCTAssertGreaterThan(fastResult.processingTime, 0, "Fast mode should record processing time")
        XCTAssertGreaterThan(accurateResult.processingTime, 0, "Accurate mode should record processing time")
    }

    func testOCRErrorHandling() async throws {
        @Dependency(\.documentImageProcessor) var processor

        // Test with invalid image data
        let invalidData = Data("invalid image data".utf8)
        let options = DocumentImageProcessor.OCROptions()

        do {
            // This test will FAIL initially - error handling needs implementation
            _ = try await processor.extractText(invalidData, options)
            XCTFail("Should throw error for invalid image data")
        } catch {
            XCTAssertTrue(error is ProcessingError, "Should throw ProcessingError")
            if let processingError = error as? ProcessingError {
                switch processingError {
                case .invalidImageData, .ocrFailed, .textDetectionFailed:
                    break // Expected errors
                default:
                    XCTFail("Unexpected error type: \(processingError)")
                }
            }
        }

        // Test with empty image data
        let emptyData = Data()
        do {
            _ = try await processor.extractText(emptyData, options)
            XCTFail("Should throw error for empty image data")
        } catch {
            XCTAssertTrue(error is ProcessingError, "Should throw ProcessingError for empty data")
        }
    }

    func testOCRCustomWords() async throws {
        @Dependency(\.documentImageProcessor) var processor

        let imageData = createSampleImageWithText()
        let options = DocumentImageProcessor.OCROptions(
            customWords: ["CustomWord", "SpecialTerm", "BrandName"]
        )

        // This test will FAIL initially - custom words handling needs implementation
        let result = try await processor.extractText(imageData, options)

        // Should complete without error even with custom words
        XCTAssertFalse(result.fullText.isEmpty, "Should extract text with custom words")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence with custom words")
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
        for i in 0 ..< 8 {
            let y = 70 + (i * 20)
            context.fill(CGRect(x: 70, y: y, width: 200, height: 10))
        }

        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.jpegData(compressionQuality: 0.8)
        else {
            return Data()
        }

        return data
    }

    private func createSampleImageWithText() -> Data {
        let size = CGSize(width: 400, height: 300)

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return Data()
        }

        // Create white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Add text using Core Graphics
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.black,
        ]

        let lines = [
            "Sample Document Text",
            "This is a test document",
            "For OCR processing tests",
            "Line 4 with numbers: 123.45",
            "Contact: test@example.com",
        ]

        var yPosition: CGFloat = 50
        for line in lines {
            let textSize = line.size(withAttributes: textAttributes)
            line.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: textAttributes)
            yPosition += textSize.height + 10
        }

        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.jpegData(compressionQuality: 0.9)
        else {
            return Data()
        }

        return data
    }

    private func createSampleInvoiceImage() -> Data {
        let size = CGSize(width: 400, height: 500)

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return Data()
        }

        // Create white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black,
        ]

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
        ]

        let invoiceLines = [
            ("INVOICE", titleAttributes),
            ("", textAttributes),
            ("Invoice #: INV-2024-001", textAttributes),
            ("Date: 2024-01-15", textAttributes),
            ("", textAttributes),
            ("Bill To:", textAttributes),
            ("John Doe", textAttributes),
            ("123 Main St", textAttributes),
            ("City, State 12345", textAttributes),
            ("", textAttributes),
            ("Description: Consulting Services", textAttributes),
            ("Amount: $1,250.00", textAttributes),
            ("Tax: $125.00", textAttributes),
            ("Total: $1,375.00", textAttributes),
        ]

        var yPosition: CGFloat = 30
        for (line, attributes) in invoiceLines {
            if !line.isEmpty {
                let textSize = line.size(withAttributes: attributes)
                line.draw(at: CGPoint(x: 30, y: yPosition), withAttributes: attributes)
                yPosition += textSize.height + 8
            } else {
                yPosition += 10
            }
        }

        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.jpegData(compressionQuality: 0.9)
        else {
            return Data()
        }

        return data
    }

    private func createSampleReceiptImage() -> Data {
        let size = CGSize(width: 300, height: 400)

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return Data()
        }

        // Create white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black,
        ]

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black,
        ]

        let receiptLines = [
            ("GROCERY STORE", titleAttributes),
            ("123 Shopping Plaza", textAttributes),
            ("City, State 12345", textAttributes),
            ("Phone: (555) 123-4567", textAttributes),
            ("", textAttributes),
            ("Date: 01/15/2024", textAttributes),
            ("Time: 14:32", textAttributes),
            ("", textAttributes),
            ("Apples        $3.99", textAttributes),
            ("Bread         $2.49", textAttributes),
            ("Milk          $4.29", textAttributes),
            ("", textAttributes),
            ("Subtotal:    $10.77", textAttributes),
            ("Tax:          $0.86", textAttributes),
            ("Total:       $11.63", textAttributes),
        ]

        var yPosition: CGFloat = 20
        for (line, attributes) in receiptLines {
            if !line.isEmpty {
                let textSize = line.size(withAttributes: attributes)
                let xPosition: CGFloat = line.contains("GROCERY STORE") ? 50 : 20
                line.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: attributes)
                yPosition += textSize.height + 6
            } else {
                yPosition += 8
            }
        }

        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.jpegData(compressionQuality: 0.9)
        else {
            return Data()
        }

        return data
    }

    private func createSampleBusinessCardImage() -> Data {
        let size = CGSize(width: 350, height: 200)

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return Data()
        }

        // Create white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Add border
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(2)
        context.stroke(CGRect(x: 5, y: 5, width: size.width - 10, height: size.height - 10))

        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
        ]

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray,
        ]

        let contactAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black,
        ]

        let cardInfo = [
            ("John Smith", nameAttributes),
            ("Senior Software Engineer", titleAttributes),
            ("", contactAttributes),
            ("Tech Solutions Inc.", contactAttributes),
            ("john.smith@techsolutions.com", contactAttributes),
            ("(555) 987-6543", contactAttributes),
            ("www.techsolutions.com", contactAttributes),
        ]

        var yPosition: CGFloat = 30
        for (line, attributes) in cardInfo {
            if !line.isEmpty {
                let textSize = line.size(withAttributes: attributes)
                line.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: attributes)
                yPosition += textSize.height + 8
            } else {
                yPosition += 10
            }
        }

        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.jpegData(compressionQuality: 0.9)
        else {
            return Data()
        }

        return data
    }
}

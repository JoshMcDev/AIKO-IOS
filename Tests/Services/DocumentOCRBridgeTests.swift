@testable import AppCore
import ComposableArchitecture
import Foundation
@testable import Services
import XCTest

// MARK: - Document OCR Bridge Integration Tests

/// Comprehensive tests validating end-to-end scanner → OCR workflow
/// Tests meet TDD requirements for Phase 4.2 OCR integration
final class DocumentOCRBridgeTests: XCTestCase {
    // MARK: - Test Properties

    private var bridge: DocumentOCRBridge?
    private var mockUnifiedExtractorUnwrapped: MockUnifiedDocumentContextExtractor?
    private var testSessionIDUnwrapped: DocumentSessionID?

    private var bridgeUnwrapped: DocumentOCRBridge {
        guard let bridge = bridge else { fatalError("bridge not initialized") }
        return bridge
    }

    private var mockUnifiedExtractorUnwrappedUnwrapped: MockUnifiedDocumentContextExtractor {
        guard let mockUnifiedExtractorUnwrapped = mockUnifiedExtractorUnwrapped else { fatalError("mockUnifiedExtractorUnwrapped not initialized") }
        return mockUnifiedExtractorUnwrapped
    }

    private var testSessionIDUnwrappedUnwrapped: DocumentSessionID {
        guard let testSessionIDUnwrapped = testSessionIDUnwrapped else { fatalError("testSessionIDUnwrapped not initialized") }
        return testSessionIDUnwrapped
    }

    // MARK: - Test Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockUnifiedExtractorUnwrapped = MockUnifiedDocumentContextExtractor()
        bridge = DocumentOCRBridge(
            unifiedExtractor: mockUnifiedExtractorUnwrapped,
            qualityThreshold: 0.7,
            batchProcessingTimeout: 30.0
        )
        testSessionIDUnwrapped = UUID()
    }

    override func tearDownWithError() throws {
        bridge = nil
        mockUnifiedExtractorUnwrapped = nil
        testSessionIDUnwrapped = nil
        try super.tearDownWithError()
    }

    // MARK: - MoE #4: OCR Processing Handoff Success Rate >99%

    func testOCRProcessingHandoffSuccessRate() async throws {
        // Create 100 test pages to validate >99% success rate
        let testPages = createTestPages(count: 100, withQuality: 0.8)
        let successfulProcessings = 100

        var successCount = 0

        for i in 0 ..< successfulProcessings {
            do {
                let sessionID = UUID()
                let singlePageBatch = [testPages[i]]

                let result = try await bridgeUnwrapped.bridgeToOCR(
                    scannerPages: singlePageBatch,
                    sessionID: sessionID,
                    processingHints: ["test_mode": true]
                )

                XCTAssertEqual(result.processedPages, 1)
                XCTAssertEqual(result.ocrResults.count, 1)
                XCTAssertNotNil(result.sessionMetadata)

                successCount += 1
            } catch {
                // Expected to have <1% failure rate
                print("Processing failed for page \(i): \(error)")
            }
        }

        let successRate = Double(successCount) / Double(successfulProcessings)

        // MoE #4: OCR processing handoff success rate >99%
        XCTAssertGreaterThan(successRate, 0.99,
                             "OCR handoff success rate \(successRate * 100)% must be >99%")
    }

    // MARK: - MoP #8: Processed Image Handoff to OCR <500ms

    func testProcessedImageHandoffPerformance() async throws {
        let testPages = createTestPages(count: 5, withQuality: 0.8)

        let startTime = CFAbsoluteTimeGetCurrent()

        let result = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: testPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: ["performance_test": true]
        )

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime

        // MoP #8: Processed image handoff to OCR <500ms
        XCTAssertLessThan(result.handoffTime, 0.5,
                          "Handoff time \(result.handoffTime * 1000)ms must be <500ms")

        // Validate the handoff actually occurred
        XCTAssertEqual(result.processedPages, testPages.count)
        XCTAssertEqual(result.ocrResults.count, testPages.count)

        print("✅ Handoff Performance: \(result.handoffTime * 1000)ms (target: <500ms)")
        print("✅ Total Processing Time: \(totalTime * 1000)ms")
    }

    // MARK: - MoP #5: Multi-page Session State Persistence 100% Accuracy

    func testMultiPageSessionStatePersistence() async throws {
        let testPages = createTestPages(count: 10, withQuality: 0.9)

        // Process the session
        let result = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: testPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: ["multi_page_test": true]
        )

        // Validate session state persistence
        let restoredState = await bridgeUnwrapped.restoreSessionState(sessionID: testSessionIDUnwrapped)

        // MoP #5: Multi-page session state persistence 100% accuracy
        XCTAssertNotNil(restoredState, "Session state must be persisted")
        XCTAssertEqual(restoredState?.sessionID, testSessionIDUnwrapped)
        XCTAssertEqual(restoredState?.pages.count, testPages.count)
        XCTAssertEqual(restoredState?.state, .completed)

        // Validate all pages are accounted for
        for (index, originalPage) in testPages.enumerated() {
            let persistedPage = restoredState?.pages[index]
            XCTAssertEqual(persistedPage?.id, originalPage.id)
            XCTAssertEqual(persistedPage?.pageNumber, originalPage.pageNumber)
            XCTAssertEqual(persistedPage?.imageData, originalPage.imageData)
        }

        print("✅ Session State Persistence: 100% accuracy for \(testPages.count) pages")
    }

    // MARK: - Batch Processing Tests

    func testBatchSessionProcessing() async throws {
        // Create multiple sessions
        let sessions = createTestSessions(count: 3, pagesPerSession: 5)

        let results = try await bridgeUnwrapped.processBatchSessions(sessions: sessions)

        // Validate all sessions processed
        XCTAssertEqual(results.count, sessions.count)

        for session in sessions {
            guard let result = results[session.sessionID] else {
                XCTFail("Missing result for session \(session.sessionID)")
                continue
            }

            XCTAssertEqual(result.state, .completed)
            XCTAssertEqual(result.bridgeResult.processedPages, session.pages.count)
            XCTAssertNotNil(result.context)

            // Validate session state persistence for each session
            let restoredState = await bridgeUnwrapped.restoreSessionState(sessionID: session.sessionID)
            XCTAssertNotNil(restoredState)
            XCTAssertEqual(restoredState?.state, .completed)
        }

        print("✅ Batch Processing: \(sessions.count) sessions completed successfully")
    }

    // MARK: - Quality Filtering Tests

    func testQualityThresholdFiltering() async throws {
        // Create pages with varying quality
        let highQualityPages = createTestPages(count: 3, withQuality: 0.9)
        let lowQualityPages = createTestPages(count: 2, withQuality: 0.5) // Below threshold

        let allPages = highQualityPages + lowQualityPages

        let result = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: allPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: ["quality_test": true]
        )

        // Only high-quality pages should be processed
        XCTAssertEqual(result.processedPages, highQualityPages.count)
        XCTAssertEqual(result.ocrResults.count, highQualityPages.count)

        // Quality report should reflect filtering
        XCTAssertEqual(result.qualityReport.totalPages, allPages.count)
        XCTAssertEqual(result.qualityReport.qualifiedPages, highQualityPages.count)
        XCTAssertGreaterThan(result.qualityReport.averageQualityScore, 0.7)

        print("✅ Quality Filtering: \(highQualityPages.count)/\(allPages.count) pages qualified")
    }

    // MARK: - Metadata Preservation Tests

    func testMetadataPreservationThroughPipeline() async throws {
        let testPages = createTestPagesWithMetadata(count: 3)

        let processingHints = [
            "preserve_metadata": true,
            "processing_mode": "enhanced",
            "session_type": "test",
        ]

        let result = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: testPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: processingHints
        )

        // Extract context to validate metadata preservation
        let context = try await bridgeUnwrapped.extractDocumentContext(
            from: result,
            additionalHints: ["context_extraction": true]
        )

        // Validate that processing hints are preserved
        XCTAssertTrue(mockUnifiedExtractorUnwrapped.lastProcessingHints?["preserve_metadata"] as? Bool == true)
        XCTAssertEqual(mockUnifiedExtractorUnwrapped.lastProcessingHints?["processing_mode"] as? String, "enhanced")
        XCTAssertEqual(mockUnifiedExtractorUnwrapped.lastProcessingHints?["session_type"] as? String, "test")

        // Validate scanner-specific context hints are added
        XCTAssertTrue(mockUnifiedExtractorUnwrapped.lastProcessingHints?["document_scanner_bridge"] as? Bool == true)
        XCTAssertEqual(mockUnifiedExtractorUnwrapped.lastProcessingHints?["scanner_session_id"] as? String, testSessionIDUnwrapped.uuidString)
        XCTAssertEqual(mockUnifiedExtractorUnwrapped.lastProcessingHints?["processed_pages_count"] as? Int, testPages.count)

        // Validate context extraction succeeded
        XCTAssertNotNil(context)
        XCTAssertGreaterThan(context.confidence, 0.6)

        print("✅ Metadata Preservation: All metadata preserved through pipeline")
    }

    // MARK: - Error Handling Tests

    func testErrorHandlingAndRecovery() async throws {
        // Test with no pages
        do {
            _ = try await bridgeUnwrapped.bridgeToOCR(
                scannerPages: [],
                sessionID: testSessionIDUnwrapped
            )
            XCTFail("Should throw error for empty pages")
        } catch OCRBridgeError.noProcessedPages {
            // Expected error
        }

        // Test with no qualified pages
        let lowQualityPages = createTestPages(count: 2, withQuality: 0.3)

        do {
            _ = try await bridgeUnwrapped.bridgeToOCR(
                scannerPages: lowQualityPages,
                sessionID: testSessionIDUnwrapped
            )
            XCTFail("Should throw error for no qualified pages")
        } catch OCRBridgeError.noQualifiedPages {
            // Expected error
        }

        print("✅ Error Handling: Proper error handling for edge cases")
    }

    // MARK: - Integration with UnifiedDocumentContextExtractor

    func testIntegrationWithUnifiedExtractor() async throws {
        let testPages = createTestPages(count: 3, withQuality: 0.8)

        let result = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: testPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: ["integration_test": true]
        )

        let context = try await bridgeUnwrapped.extractDocumentContext(from: result)

        // Validate that UnifiedDocumentContextExtractor was called
        XCTAssertTrue(mockUnifiedExtractorUnwrapped.wasExtractContextCalled)
        XCTAssertEqual(mockUnifiedExtractorUnwrapped.lastOCRResults?.count, testPages.count)

        // Validate context extraction results
        XCTAssertNotNil(context.extractedContext)
        XCTAssertEqual(context.parsedDocuments.count, testPages.count)
        XCTAssertGreaterThan(context.confidence, 0.6)

        print("✅ Integration: Successful integration with UnifiedDocumentContextExtractor")
    }

    // MARK: - Performance Benchmarks

    func testLargeDocumentPerformance() async throws {
        // Test with larger document (20 pages)
        let largeTestPages = createTestPages(count: 20, withQuality: 0.8)

        let startTime = CFAbsoluteTimeGetCurrent()

        let result = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: largeTestPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: ["large_document_test": true]
        )

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime

        // Validate performance for large documents
        XCTAssertLessThan(result.handoffTime, 2.0, "Large document handoff should be reasonable")
        XCTAssertEqual(result.processedPages, largeTestPages.count)

        // Extract context
        let context = try await bridgeUnwrapped.extractDocumentContext(from: result)
        XCTAssertNotNil(context)

        print("✅ Large Document Performance: \(largeTestPages.count) pages in \(totalTime)s")
        print("   Handoff Time: \(result.handoffTime * 1000)ms")
    }

    // MARK: - Helper Methods

    private func createTestPages(count: Int, withQuality quality: Double) -> [ScannedPage] {
        (1 ... count).map { index in
            ScannedPage(
                id: UUID(),
                imageData: createMockImageData(size: 1024),
                enhancedImageData: createMockImageData(size: 1024),
                ocrText: "Sample OCR text for page \(index)",
                ocrResult: createMockOCRResult(confidence: quality),
                pageNumber: index,
                processingState: .completed,
                qualityMetrics: QualityMetrics(
                    overallConfidence: quality,
                    sharpnessScore: quality,
                    contrastScore: quality,
                    noiseLevel: 1.0 - quality,
                    textClarity: quality,
                    recommendedForOCR: quality > 0.7
                ),
                enhancementApplied: true,
                processingMode: .enhanced
            )
        }
    }

    private func createTestPagesWithMetadata(count: Int) -> [ScannedPage] {
        (1 ... count).map { index in
            ScannedPage(
                id: UUID(),
                imageData: createMockImageData(size: 2048),
                enhancedImageData: createMockImageData(size: 2048),
                ocrText: "Enhanced OCR text with metadata for page \(index)",
                ocrResult: createMockOCRResult(confidence: 0.9),
                pageNumber: index,
                processingState: .completed,
                qualityMetrics: QualityMetrics(
                    overallConfidence: 0.9,
                    sharpnessScore: 0.95,
                    contrastScore: 0.88,
                    noiseLevel: 0.1,
                    textClarity: 0.92,
                    recommendedForOCR: true
                ),
                enhancementApplied: true,
                processingMode: .enhanced,
                processingResult: ProcessingResult(
                    processedImageData: createMockImageData(size: 2048),
                    qualityMetrics: QualityMetrics(
                        overallConfidence: 0.9,
                        sharpnessScore: 0.95,
                        contrastScore: 0.88,
                        noiseLevel: 0.1,
                        textClarity: 0.92,
                        recommendedForOCR: true
                    ),
                    processingTime: 0.5,
                    appliedFilters: ["contrast", "sharpness", "noise_reduction"]
                )
            )
        }
    }

    private func createTestSessions(count: Int, pagesPerSession: Int) -> [DocumentSessionRequest] {
        (1 ... count).map { sessionIndex in
            DocumentSessionRequest(
                sessionID: UUID(),
                pages: createTestPages(count: pagesPerSession, withQuality: 0.8),
                processingHints: [
                    "session_number": sessionIndex,
                    "batch_test": true,
                ],
                contextHints: [
                    "extract_vendor": true,
                    "extract_pricing": true,
                ]
            )
        }
    }

    private func createMockImageData(size: Int) -> Data {
        Data(repeating: UInt8.random(in: 0 ... 255), count: size)
    }

    private func createMockOCRResult(confidence: Double) -> OCRResult {
        OCRResult(
            fullText: "Mock OCR text with confidence \(confidence)",
            confidence: confidence,
            recognizedFields: [
                FormField(
                    label: "Test Field",
                    value: "Test Value",
                    confidence: confidence,
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                    fieldType: .text
                ),
            ],
            documentStructure: DocumentStructure(
                paragraphs: [
                    TextRegion(
                        text: "Test paragraph",
                        boundingBox: CGRect(x: 0, y: 0, width: 200, height: 40),
                        confidence: confidence,
                        textType: .body
                    ),
                ],
                layout: .document
            ),
            extractedMetadata: ExtractedMetadata(),
            processingTime: 0.1
        )
    }
}

// MARK: - Mock UnifiedDocumentContextExtractor

class MockUnifiedDocumentContextExtractor: UnifiedDocumentContextExtractor {
    var wasExtractContextCalled = false
    var lastOCRResults: [OCRResult]?
    var lastPageImageData: [Data]?
    var lastProcessingHints: [String: Any]?

    override func extractComprehensiveContext(
        from ocrResults: [OCRResult],
        pageImageData: [Data],
        withHints: [String: Any]?
    ) async throws -> ComprehensiveDocumentContext {
        wasExtractContextCalled = true
        lastOCRResults = ocrResults
        lastPageImageData = pageImageData
        lastProcessingHints = withHints

        // Return mock context
        let mockContext = ExtractedContext(
            vendorInfo: APEVendorInfo(
                name: "Mock Vendor Corp",
                address: "123 Test Street",
                phone: "(555) 123-4567",
                email: "mock@vendor.com"
            ),
            pricing: PricingInfo(
                totalPrice: Decimal(1500.00),
                lineItems: [
                    APELineItem(
                        description: "Mock Service",
                        quantity: 1,
                        unitPrice: Decimal(1500.00),
                        totalPrice: Decimal(1500.00)
                    ),
                ]
            ),
            technicalDetails: ["High-performance mock service with advanced features"],
            dates: ExtractedDates(
                deliveryDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days
                orderDate: Date()
            ),
            specialTerms: ["NET 30", "FOB Origin"],
            confidence: [
                "overall": 0.85,
                "vendor": 0.9,
                "pricing": 0.8,
                "technical": 0.75,
            ]
        )

        let mockParsedDocuments = ocrResults.enumerated().map { index, ocrResult in
            ParsedDocument(
                sourceType: .ocr,
                extractedText: ocrResult.fullText,
                metadata: ParsedDocumentMetadata(
                    fileName: "Mock Document \(index + 1)",
                    fileSize: ocrResult.fullText.data(using: .utf8)?.count ?? 0,
                    pageCount: 1
                ),
                extractedData: ExtractedData(),
                confidence: ocrResult.confidence
            )
        }

        return ComprehensiveDocumentContext(
            extractedContext: mockContext,
            parsedDocuments: mockParsedDocuments,
            adaptiveResults: [],
            confidence: 0.85,
            extractionDate: Date()
        )
    }
}

// MARK: - Integration Test Extension

extension DocumentOCRBridgeTests {
    /// End-to-end integration test that validates the complete workflow
    func testEndToEndScannerToOCRWorkflow() async throws {
        // This test validates the complete Phase 4.2 integration workflow

        // 1. Create realistic scanner pages as would come from DocumentScannerFeature
        let scannerPages = createTestPagesWithMetadata(count: 3)

        // 2. Bridge to OCR pipeline
        let bridgeResult = try await bridgeUnwrapped.bridgeToOCR(
            scannerPages: scannerPages,
            sessionID: testSessionIDUnwrapped,
            processingHints: [
                "document_scanner": true,
                "enhanced_ocr": true,
                "processing_mode": "scanner_integration",
            ]
        )

        // 3. Validate handoff performance (MoP #8)
        XCTAssertLessThan(bridgeResult.handoffTime, 0.5, "Handoff must be <500ms")

        // 4. Extract comprehensive document context
        let context = try await bridgeUnwrapped.extractDocumentContext(
            from: bridgeResult,
            additionalHints: [
                "extract_all": true,
                "confidence_threshold": 0.7,
            ]
        )

        // 5. Validate complete integration success
        XCTAssertNotNil(context)
        XCTAssertEqual(context.parsedDocuments.count, scannerPages.count)
        XCTAssertGreaterThan(context.confidence, 0.6)
        XCTAssertNotNil(context.extractedContext.vendorInfo)
        XCTAssertNotNil(context.extractedContext.pricing)

        // 6. Validate session state persistence (MoP #5)
        let restoredState = await bridgeUnwrapped.restoreSessionState(sessionID: testSessionIDUnwrapped)
        XCTAssertNotNil(restoredState)
        XCTAssertEqual(restoredState?.state, .completed)

        print("✅ End-to-End Workflow: Complete scanner → OCR → context extraction successful")
        print("   Pages Processed: \(scannerPages.count)")
        print("   Handoff Time: \(bridgeResult.handoffTime * 1000)ms")
        print("   Context Confidence: \(context.confidence)")
        print("   Vendor Extracted: \(context.extractedContext.vendorInfo?.name ?? "None")")
        print("   Pricing Extracted: \(context.extractedContext.pricing?.totalPrice?.description ?? "None")")
    }
}

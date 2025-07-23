@testable import AppCore
import ComposableArchitecture
import XCTest

@MainActor
final class FormAutoPopulationEngineTests: XCTestCase {
    private var mockDocumentProcessor: DocumentImageProcessor!
    private var mockSmartDefaults: SmartDefaultsEngine!
    private var formAutoPopulationEngine: FormAutoPopulationEngine!

    override func setUp() {
        super.setUp()
        mockDocumentProcessor = DocumentImageProcessor.testValue
        mockSmartDefaults = SmartDefaultsEngine.testValue

        // This will fail until we implement FormAutoPopulationEngine
        formAutoPopulationEngine = FormAutoPopulationEngine(
            documentProcessor: mockDocumentProcessor,
            smartDefaults: mockSmartDefaults
        )
    }

    override func tearDown() {
        formAutoPopulationEngine = nil
        mockSmartDefaults = nil
        mockDocumentProcessor = nil
        super.tearDown()
    }

    // MARK: - MoE Tests: Field Extraction Accuracy

    func test_extractSF30Fields_highConfidence_achieves95PercentAccuracy() async throws {
        // Given: Sample SF-30 form image data
        let sf30ImageData = createMockSF30ImageData()

        // When: Extract form data
        let result = try await formAutoPopulationEngine.extractFormData(from: sf30ImageData, formType: .sf30)

        // Then: High confidence fields should have ≥95% accuracy
        let highConfidenceFields = result.fields.filter { $0.confidence.value >= 0.85 }
        let accurateFields = highConfidenceFields.filter(\.isAccurate)
        let accuracy = Double(accurateFields.count) / Double(highConfidenceFields.count)

        XCTAssertGreaterThanOrEqual(accuracy, 0.95, "High-confidence SF-30 field extraction should achieve ≥95% accuracy")
        XCTAssertFalse(result.fields.isEmpty, "Should extract at least some fields from SF-30")
    }

    func test_extractSF1449Fields_mediumConfidence_achieves85PercentAccuracy() async throws {
        // Given: Sample SF-1449 form image data
        let sf1449ImageData = createMockSF1449ImageData()

        // When: Extract form data
        let result = try await formAutoPopulationEngine.extractFormData(from: sf1449ImageData, formType: .sf1449)

        // Then: Medium confidence fields should have ≥85% accuracy
        let mediumConfidenceFields = result.fields.filter { $0.confidence.value >= 0.65 && $0.confidence.value < 0.85 }
        let accurateFields = mediumConfidenceFields.filter(\.isAccurate)
        let accuracy = Double(accurateFields.count) / Double(mediumConfidenceFields.count)

        XCTAssertGreaterThanOrEqual(accuracy, 0.85, "Medium-confidence SF-1449 field extraction should achieve ≥85% accuracy")
    }

    func test_criticalFieldDetection_identifiesAllCriticalFields() async throws {
        // Given: Form with critical fields (estimated value, funding source, etc.)
        let formImageData = createMockFormWithCriticalFields()

        // When: Extract form data
        let result = try await formAutoPopulationEngine.extractFormData(from: formImageData, formType: .sf30)

        // Then: All critical fields should be identified (100% detection)
        let criticalFields = result.fields.filter(\.isCritical)
        let expectedCriticalFieldCount = 5 // Based on PRD: estimated value, funding source, contract type, vendor UEI, vendor CAGE

        XCTAssertEqual(criticalFields.count, expectedCriticalFieldCount, "Should identify all critical fields")
        XCTAssertTrue(criticalFields.allSatisfy(\.requiresManualReview), "Critical fields should require manual review")
    }

    // MARK: - Helper Methods (These will fail until we implement the classes)

    private func createMockSF30ImageData() -> Data {
        Data("mock-sf30-image".utf8)
    }

    private func createMockSF1449ImageData() -> Data {
        Data("mock-sf1449-image".utf8)
    }

    private func createMockFormWithCriticalFields() -> Data {
        Data("mock-critical-fields-form".utf8)
    }
}

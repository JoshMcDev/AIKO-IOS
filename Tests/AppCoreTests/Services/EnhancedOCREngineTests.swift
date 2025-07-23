@testable import AppCore
import Foundation
import XCTest

@MainActor
final class EnhancedOCREngineTests: XCTestCase {
    // MARK: - Properties

    private var engine: EnhancedOCREngine!
    private var testImageData: Data!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        engine = EnhancedOCREngine(confidenceThreshold: 0.8)
        testImageData = createTestImageData()
    }

    override func tearDown() async throws {
        engine = nil
        testImageData = nil
        try await super.tearDown()
    }

    // MARK: - Government Form Recognition Tests

    func testGovernmentFormRecognition_SF298_Success() async throws {
        // GIVEN: A scanned SF-298 form
        let sf298ImageData = createTestImageData(formType: "SF-298")

        // WHEN: Processing the form
        let result = try await engine.recognizeGovernmentForm(from: sf298ImageData)

        // THEN: Should identify SF-298 form type
        XCTAssertEqual(result.formType, .sf298)
        XCTAssertGreaterThan(result.confidence, 0.8)
        XCTAssertGreaterThan(result.extractedFields.count, 5, "SF-298 should extract multiple fields")

        // Verify specific SF-298 fields
        let titleField = result.extractedFields.first { $0.fieldId == "document_title" }
        XCTAssertNotNil(titleField, "Should extract document title field")
        XCTAssertGreaterThan(titleField?.confidence ?? 0, 0.7)

        // Performance requirement: Processing time should be under 5 seconds
        XCTAssertLessThan(result.processingTime, 5.0, "OCR processing should complete within 5 seconds")
    }

    func testGovernmentFormRecognition_SF1449_Success() async throws {
        // GIVEN: A scanned SF-1449 solicitation form
        let sf1449ImageData = createTestImageData(formType: "SF-1449")

        // WHEN: Processing the form
        let result = try await engine.recognizeGovernmentForm(from: sf1449ImageData)

        // THEN: Should identify SF-1449 form type
        XCTAssertEqual(result.formType, .sf1449)
        XCTAssertGreaterThan(result.confidence, 0.8)
        XCTAssertGreaterThan(result.extractedFields.count, 10, "SF-1449 should extract many fields")

        // Verify critical procurement fields
        let solicitationNumberField = result.extractedFields.first { $0.fieldId == "solicitation_number" }
        XCTAssertNotNil(solicitationNumberField, "Should extract solicitation number")

        let issuedByField = result.extractedFields.first { $0.fieldId == "issued_by" }
        XCTAssertNotNil(issuedByField, "Should extract issuing office")
    }

    func testGovernmentFormRecognition_DD254_Success() async throws {
        // GIVEN: A scanned DD-254 security classification form
        let dd254ImageData = createTestImageData(formType: "DD-254")

        // WHEN: Processing the form
        let result = try await engine.recognizeGovernmentForm(from: dd254ImageData)

        // THEN: Should identify DD-254 form type
        XCTAssertEqual(result.formType, .dd254)
        XCTAssertGreaterThan(result.confidence, 0.8)

        // Verify security classification fields
        let classificationField = result.extractedFields.first { $0.fieldId == "classification_level" }
        XCTAssertNotNil(classificationField, "Should extract classification level")
        XCTAssertGreaterThan(classificationField?.confidence ?? 0, 0.9, "Security fields require high confidence")
    }

    func testGovernmentFormRecognition_UnknownForm() async throws {
        // GIVEN: An unknown document type
        let unknownImageData = createTestImageData(formType: "unknown")

        // WHEN: Processing the form
        let result = try await engine.recognizeGovernmentForm(from: unknownImageData)

        // THEN: Should classify as unknown but still extract text
        XCTAssertEqual(result.formType, .unknown)
        XCTAssertLessThan(result.confidence, 0.8, "Unknown forms should have lower confidence")

        // Should still attempt field extraction
        XCTAssertGreaterThanOrEqual(result.extractedFields.count, 0)
    }

    func testGovernmentFormRecognition_InvalidImageData() async throws {
        // GIVEN: Invalid image data
        let invalidData = Data("not-an-image".utf8)

        // WHEN/THEN: Should throw unsupported format error
        do {
            _ = try await engine.recognizeGovernmentForm(from: invalidData)
            XCTFail("Expected error to be thrown")
        } catch {
            guard let ocrError = error as? OCRError else {
                XCTFail("Expected OCRError")
                return
            }
            XCTAssertEqual(ocrError, .unsupportedImageFormat)
        }
    }

    // MARK: - Confidence Scoring Tests

    func testConfidenceScoring_HighQualityFields() async throws {
        // GIVEN: High-quality extracted fields
        let highQualityFields = createTestGovernmentFormFields(confidence: 0.95)

        // WHEN: Calculating confidence score
        let confidenceScore = await engine.calculateConfidenceScore(for: highQualityFields)

        // THEN: Should return high confidence
        XCTAssertGreaterThan(confidenceScore, 0.9, "High-quality fields should yield high confidence")
        XCTAssertLessThanOrEqual(confidenceScore, 1.0, "Confidence should not exceed 100%")
    }

    func testConfidenceScoring_LowQualityFields() async throws {
        // GIVEN: Low-quality extracted fields
        let lowQualityFields = createTestGovernmentFormFields(confidence: 0.4)

        // WHEN: Calculating confidence score
        let confidenceScore = await engine.calculateConfidenceScore(for: lowQualityFields)

        // THEN: Should return low confidence
        XCTAssertLessThan(confidenceScore, 0.6, "Low-quality fields should yield low confidence")
        XCTAssertGreaterThanOrEqual(confidenceScore, 0.0, "Confidence should not be negative")
    }

    func testConfidenceScoring_EmptyFields() async throws {
        // GIVEN: Empty field list
        let emptyFields: [EnhancedOCREngine.GovernmentFormField] = []

        // WHEN: Calculating confidence score
        let confidenceScore = await engine.calculateConfidenceScore(for: emptyFields)

        // THEN: Should return zero confidence
        XCTAssertEqual(confidenceScore, 0.0, "Empty fields should yield zero confidence")
    }

    func testConfidenceScoring_MixedQualityFields() async throws {
        // GIVEN: Mixed-quality fields
        let mixedFields = [
            createTestGovernmentFormField(confidence: 0.9),
            createTestGovernmentFormField(confidence: 0.5),
            createTestGovernmentFormField(confidence: 0.8),
        ]

        // WHEN: Calculating confidence score
        let confidenceScore = await engine.calculateConfidenceScore(for: mixedFields)

        // THEN: Should return weighted average
        let expectedAverage = (0.9 + 0.5 + 0.8) / 3.0
        XCTAssertEqual(confidenceScore, expectedAverage, accuracy: 0.01,
                       "Mixed fields should yield weighted confidence")
    }

    // MARK: - Field Mapping Tests

    func testFieldMappingAccuracy_SF298_RequiredFields() async throws {
        // GIVEN: OCR result for SF-298 form
        let ocrResult = createTestOCRResult(formType: .sf298)

        // WHEN: Mapping fields to government form
        let mappedFields = try await engine.mapFieldsToGovernmentForm(
            ocrResult: ocrResult,
            formType: .sf298
        )

        // THEN: Should map all required SF-298 fields
        let requiredFieldIds = ["document_title", "contract_number", "contractor_name", "poc_name", "classification"]

        for fieldId in requiredFieldIds {
            let field = mappedFields.first { $0.fieldId == fieldId }
            XCTAssertNotNil(field, "Should map required field: \(fieldId)")
            XCTAssertGreaterThan(field?.confidence ?? 0, 0.5, "Mapped field should have reasonable confidence")
        }

        // Verify field types are correctly identified
        let titleField = mappedFields.first { $0.fieldId == "document_title" }
        XCTAssertEqual(titleField?.fieldType, .text, "Title should be text field")

        let contractField = mappedFields.first { $0.fieldId == "contract_number" }
        XCTAssertEqual(contractField?.fieldType, .text, "Contract number should be text field")
    }

    func testFieldMappingAccuracy_SF1449_ProcurementFields() async throws {
        // GIVEN: OCR result for SF-1449 form
        let ocrResult = createTestOCRResult(formType: .sf1449)

        // WHEN: Mapping fields to government form
        let mappedFields = try await engine.mapFieldsToGovernmentForm(
            ocrResult: ocrResult,
            formType: .sf1449
        )

        // THEN: Should map procurement-specific fields
        let procurementFieldIds = ["solicitation_number", "issued_by", "naics_code", "place_of_performance"]

        for fieldId in procurementFieldIds {
            let field = mappedFields.first { $0.fieldId == fieldId }
            XCTAssertNotNil(field, "Should map procurement field: \(fieldId)")
        }

        // Verify NAICS code is recognized as number
        let naicsField = mappedFields.first { $0.fieldId == "naics_code" }
        XCTAssertEqual(naicsField?.fieldType, .number, "NAICS code should be number field")
    }

    func testFieldMappingAccuracy_BoundingBoxes() async throws {
        // GIVEN: OCR result with bounding box data
        let ocrResult = createTestOCRResultWithBoundingBoxes()

        // WHEN: Mapping fields
        let mappedFields = try await engine.mapFieldsToGovernmentForm(
            ocrResult: ocrResult,
            formType: .sf298
        )

        // THEN: Should preserve accurate bounding boxes
        for field in mappedFields {
            XCTAssertNotEqual(field.boundingBox, .zero, "Field should have valid bounding box")
            XCTAssertGreaterThan(field.boundingBox.width, 0, "Bounding box should have width")
            XCTAssertGreaterThan(field.boundingBox.height, 0, "Bounding box should have height")
        }
    }

    func testFieldMappingAccuracy_UnsupportedFormType() async throws {
        // GIVEN: OCR result for unsupported form type
        let ocrResult = createTestOCRResult(formType: .unknown)

        // WHEN: Mapping fields to unknown form type
        let mappedFields = try await engine.mapFieldsToGovernmentForm(
            ocrResult: ocrResult,
            formType: .unknown
        )

        // THEN: Should return empty or generic field mapping
        XCTAssertLessThanOrEqual(mappedFields.count, 3, "Unknown forms should have minimal field mapping")
    }

    // MARK: - Performance Tests

    func testConcurrentRecognition_MultipleForms() async throws {
        // GIVEN: Multiple form images
        let form1Data = createTestImageData(formType: "SF-298")
        let form2Data = createTestImageData(formType: "SF-1449")
        let form3Data = createTestImageData(formType: "DD-254")

        // WHEN: Processing forms concurrently
        let startTime = Date()

        async let result1 = engine.recognizeGovernmentForm(from: form1Data)
        async let result2 = engine.recognizeGovernmentForm(from: form2Data)
        async let result3 = engine.recognizeGovernmentForm(from: form3Data)

        let results = try await [result1, result2, result3]
        let processingTime = Date().timeIntervalSince(startTime)

        // THEN: Should handle concurrent processing efficiently
        XCTAssertEqual(results.count, 3, "Should process all forms")
        XCTAssertLessThan(processingTime, 10.0, "Concurrent processing should be efficient")

        // Each result should be valid
        for result in results {
            XCTAssertGreaterThan(result.confidence, 0.0)
            XCTAssertGreaterThan(result.extractedFields.count, 0)
        }
    }

    // MARK: - Helper Methods

    private func createTestImageData(formType: String = "generic") -> Data {
        // Create minimal test image data
        "test-image-data-\(formType)".data(using: .utf8) ?? Data()
    }

    private func createTestGovernmentFormFields(confidence: Double) -> [EnhancedOCREngine.GovernmentFormField] {
        [
            createTestGovernmentFormField(fieldId: "field1", confidence: confidence),
            createTestGovernmentFormField(fieldId: "field2", confidence: confidence),
            createTestGovernmentFormField(fieldId: "field3", confidence: confidence),
        ]
    }

    private func createTestGovernmentFormField(
        fieldId: String = "test_field",
        confidence: Double = 0.8
    ) -> EnhancedOCREngine.GovernmentFormField {
        EnhancedOCREngine.GovernmentFormField(
            fieldId: fieldId,
            label: "Test Field",
            value: "Test Value",
            confidence: confidence,
            boundingBox: CGRect(x: 10, y: 10, width: 100, height: 20),
            fieldType: .text
        )
    }

    private func createTestOCRResult(formType: EnhancedOCREngine.GovernmentFormType) -> OCRResult {
        let formFields: [DocumentFormField] = switch formType {
        case .sf298:
            [
                DocumentFormField(label: "Document Title", value: "Test Contract", confidence: 0.9, boundingBox: CGRect(x: 0, y: 0, width: 200, height: 30)),
                DocumentFormField(label: "Contract Number", value: "ABC123", confidence: 0.85, boundingBox: CGRect(x: 0, y: 40, width: 150, height: 20)),
                DocumentFormField(label: "Contractor", value: "Test Corp", confidence: 0.8, boundingBox: CGRect(x: 0, y: 70, width: 180, height: 20)),
            ]
        case .sf1449:
            [
                DocumentFormField(label: "Solicitation Number", value: "SOL-2024-001", confidence: 0.9, boundingBox: CGRect(x: 0, y: 0, width: 200, height: 20)),
                DocumentFormField(label: "Issued By", value: "DoD", confidence: 0.85, boundingBox: CGRect(x: 0, y: 30, width: 100, height: 20)),
                DocumentFormField(label: "NAICS Code", value: "541511", confidence: 0.8, boundingBox: CGRect(x: 0, y: 60, width: 80, height: 20)),
            ]
        case .dd254:
            [
                DocumentFormField(label: "Classification", value: "UNCLASSIFIED", confidence: 0.95, boundingBox: CGRect(x: 0, y: 0, width: 150, height: 20)),
            ]
        case .unknown, .contractModification:
            []
        }

        return OCRResult(
            fullText: "Test OCR Text",
            confidence: 0.8,
            recognizedFields: formFields,
            processingTime: 0.5
        )
    }

    private func createTestOCRResultWithBoundingBoxes() -> OCRResult {
        let fieldsWithBounds = [
            DocumentFormField(
                label: "Field 1",
                value: "Value 1",
                confidence: 0.9,
                boundingBox: CGRect(x: 10, y: 10, width: 100, height: 25)
            ),
            DocumentFormField(
                label: "Field 2",
                value: "Value 2",
                confidence: 0.85,
                boundingBox: CGRect(x: 10, y: 40, width: 120, height: 25)
            ),
        ]

        return OCRResult(
            fullText: "Test text with bounding boxes",
            confidence: 0.85,
            recognizedFields: fieldsWithBounds,
            processingTime: 0.3
        )
    }
}

@testable import AppCore
import CoreGraphics
import XCTest

// MARK: - Government Form OCR Models Tests

// Phase 4.2 - Professional Document Scanner
// Smart Form Auto-Population Components - RED PHASE

final class GovernmentFormOCRModelsTests: XCTestCase {
    // MARK: - JSON Parsing Tests

    func test_sf1449OCRData_jsonParsing_validData_succeeds() throws {
        // Test will fail initially - needs implementation
        let jsonData = createSF1449TestJSON()

        let decoder = JSONDecoder()
        let result = try decoder.decode(GovernmentFormOCRModels.SF1449OCRData.self, from: jsonData)

        XCTAssertNotNil(result.solicitationNumber)
        XCTAssertEqual(result.solicitationNumber?.processedText, "W52P1J-23-R-0001")
        XCTAssertGreaterThan(result.solicitationNumber?.confidence ?? 0, 0.85)
        XCTAssertEqual(result.vendorInfo?.cage?.processedText, "1ABC5")
        XCTAssertTrue(result.contractInfo?.totalAmount?.isHighConfidence ?? false)
    }

    func test_sf30OCRData_jsonParsing_validData_succeeds() throws {
        // Test will fail initially - needs implementation
        let jsonData = createSF30TestJSON()

        let decoder = JSONDecoder()
        let result = try decoder.decode(GovernmentFormOCRModels.SF30OCRData.self, from: jsonData)

        XCTAssertNotNil(result.amendmentNumber)
        XCTAssertEqual(result.amendmentNumber?.processedText, "0001")
        XCTAssertGreaterThan(result.amendmentNumber?.confidence ?? 0, 0.85)
        XCTAssertEqual(result.contractorInfo?.cage?.processedText, "2DEF7")
        XCTAssertTrue(result.priceChanges?.isMediumConfidence ?? false)
    }

    func test_dd1155OCRData_jsonParsing_validData_succeeds() throws {
        // Test will fail initially - needs implementation
        let jsonData = createDD1155TestJSON()

        let decoder = JSONDecoder()
        let result = try decoder.decode(GovernmentFormOCRModels.DD1155OCRData.self, from: jsonData)

        XCTAssertNotNil(result.requestNumber)
        XCTAssertEqual(result.requestNumber?.processedText, "TDY-2025-001")
        XCTAssertGreaterThan(result.requestNumber?.confidence ?? 0, 0.85)
        XCTAssertEqual(result.travelerInfo?.name?.processedText, "Smith, John A.")
        XCTAssertTrue(result.costEstimate?.totalEstimate?.isAutoFillReady ?? false)
    }

    // MARK: - Field Validation Tests

    func test_ocrFieldExtraction_confidenceValidation_highConfidence_returnsTrue() {
        // Test will fail initially - needs validation logic
        let field = OCRFieldExtraction(
            rawText: "1ABC5",
            processedText: "1ABC5",
            confidence: 0.92,
            boundingBox: CGRect(x: 100, y: 200, width: 80, height: 20),
            validationStatus: .valid,
            fieldType: .cageCode
        )

        XCTAssertTrue(field.isHighConfidence)
        XCTAssertTrue(field.isAutoFillReady)
        XCTAssertFalse(field.isMediumConfidence)
    }

    func test_ocrFieldExtraction_confidenceValidation_mediumConfidence_returnsTrue() {
        // Test will fail initially - needs validation logic
        let field = OCRFieldExtraction(
            rawText: "W52P1J-23-R-0001",
            processedText: "W52P1J-23-R-0001",
            confidence: 0.75,
            boundingBox: CGRect(x: 200, y: 150, width: 150, height: 20),
            validationStatus: .requiresReview,
            fieldType: .solicitationNumber
        )

        XCTAssertFalse(field.isHighConfidence)
        XCTAssertTrue(field.isMediumConfidence)
        XCTAssertFalse(field.isAutoFillReady)
    }

    func test_ocrFieldExtraction_confidenceValidation_lowConfidence_returnsFalse() {
        // Test will fail initially - needs validation logic
        let field = OCRFieldExtraction(
            rawText: "unclear text",
            processedText: "unclear text",
            confidence: 0.45,
            boundingBox: CGRect(x: 50, y: 300, width: 200, height: 20),
            validationStatus: .invalid,
            fieldType: .unknown
        )

        XCTAssertFalse(field.isHighConfidence)
        XCTAssertFalse(field.isMediumConfidence)
        XCTAssertFalse(field.isAutoFillReady)
    }

    // MARK: - Validation Patterns Tests

    func test_validationPatterns_cageCode_validFormat_passes() {
        // Test will fail initially - needs regex validation
        let validCages = ["1ABC5", "2DEF7", "9XYZ0", "A1B2C"]
        let pattern = ValidationPatterns.cageCode

        for cage in validCages {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for pattern: \(pattern)")
                return
            }
            let range = NSRange(location: 0, length: cage.utf16.count)
            let match = regex.firstMatch(in: cage, options: [], range: range)

            XCTAssertNotNil(match, "CAGE code '\(cage)' should be valid")
        }
    }

    func test_validationPatterns_cageCode_invalidFormat_fails() {
        // Test will fail initially - needs regex validation
        let invalidCages = ["123", "ABCDEF", "1AB-5", "1AB 5", ""]
        let pattern = ValidationPatterns.cageCode

        for cage in invalidCages {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for pattern: \(pattern)")
                return
            }
            let range = NSRange(location: 0, length: cage.utf16.count)
            let match = regex.firstMatch(in: cage, options: [], range: range)

            XCTAssertNil(match, "CAGE code '\(cage)' should be invalid")
        }
    }

    func test_validationPatterns_uei_validFormat_passes() {
        // Test will fail initially - needs regex validation
        let validUEIs = ["ABC123DEF456", "123456789012", "ABCDEFGHIJ12"]
        let pattern = ValidationPatterns.uei

        for uei in validUEIs {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for UEI pattern: \(pattern)")
                return
            }
            let range = NSRange(location: 0, length: uei.utf16.count)
            let match = regex.firstMatch(in: uei, options: [], range: range)

            XCTAssertNotNil(match, "UEI '\(uei)' should be valid")
        }
    }

    func test_validationPatterns_uei_invalidFormat_fails() {
        // Test will fail initially - needs regex validation
        let invalidUEIs = ["12345678901", "ABCDEFGHIJK12", "ABC-123-DEF-456", ""]
        let pattern = ValidationPatterns.uei

        for uei in invalidUEIs {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for UEI pattern: \(pattern)")
                return
            }
            let range = NSRange(location: 0, length: uei.utf16.count)
            let match = regex.firstMatch(in: uei, options: [], range: range)

            XCTAssertNil(match, "UEI '\(uei)' should be invalid")
        }
    }

    func test_validationPatterns_currency_validFormat_passes() {
        // Test will fail initially - needs regex validation
        let validCurrencies = ["$1,234.56", "1234.56", "$1000", "999.99", "$1,000,000.00"]
        let pattern = ValidationPatterns.currency

        for currency in validCurrencies {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for currency pattern: \(pattern)")
                return
            }
            let range = NSRange(location: 0, length: currency.utf16.count)
            let match = regex.firstMatch(in: currency, options: [], range: range)

            XCTAssertNotNil(match, "Currency '\(currency)' should be valid")
        }
    }

    func test_validationPatterns_date_validFormat_passes() {
        // Test will fail initially - needs regex validation
        let validDates = ["01/15/2025", "12-31-2024", "3/5/2025", "10/10/2025"]
        let pattern = ValidationPatterns.date

        for date in validDates {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for date pattern: \(pattern)")
                return
            }
            let range = NSRange(location: 0, length: date.utf16.count)
            let match = regex.firstMatch(in: date, options: [], range: range)

            XCTAssertNotNil(match, "Date '\(date)' should be valid")
        }
    }

    // MARK: - Form Detection Tests

    func test_detectedFormType_sf1449_highConfidence_identifiesCorrectly() {
        // Test will fail initially - needs form detection logic
        let indicators = [
            FormIndicator(type: .title, value: "SOLICITATION/CONTRACT/ORDER FOR COMMERCIAL ITEMS", weight: 0.9),
            FormIndicator(type: .formNumber, value: "SF 1449", weight: 0.95),
            FormIndicator(type: .fieldLabel, value: "SOLICITATION NO.", weight: 0.7),
        ]

        let detectedForm = DetectedFormType(
            formType: .sf1449,
            confidence: 0.92,
            indicators: indicators
        )

        XCTAssertEqual(detectedForm.formType, .sf1449)
        XCTAssertGreaterThan(detectedForm.confidence, 0.85)
        XCTAssertEqual(detectedForm.indicators.count, 3)
        XCTAssertTrue(detectedForm.indicators.contains { $0.type == .formNumber })
    }

    func test_detectedFormType_sf30_highConfidence_identifiesCorrectly() {
        // Test will fail initially - needs form detection logic
        let indicators = [
            FormIndicator(type: .title, value: "AMENDMENT OF SOLICITATION/MODIFICATION OF CONTRACT", weight: 0.9),
            FormIndicator(type: .formNumber, value: "SF 30", weight: 0.95),
            FormIndicator(type: .fieldLabel, value: "AMENDMENT NO.", weight: 0.8),
        ]

        let detectedForm = DetectedFormType(
            formType: .sf30,
            confidence: 0.89,
            indicators: indicators
        )

        XCTAssertEqual(detectedForm.formType, .sf30)
        XCTAssertGreaterThan(detectedForm.confidence, 0.85)
        XCTAssertEqual(detectedForm.indicators.count, 3)
        XCTAssertTrue(detectedForm.indicators.contains { $0.type == .title })
    }

    func test_detectedFormType_dd1155_highConfidence_identifiesCorrectly() {
        // Test will fail initially - needs form detection logic
        let indicators = [
            FormIndicator(type: .title, value: "REQUEST AND AUTHORIZATION FOR TDY TRAVEL", weight: 0.85),
            FormIndicator(type: .formNumber, value: "DD 1155", weight: 0.95),
            FormIndicator(type: .fieldLabel, value: "NAME (Last, First, MI)", weight: 0.75),
        ]

        let detectedForm = DetectedFormType(
            formType: .dd1155,
            confidence: 0.87,
            indicators: indicators
        )

        XCTAssertEqual(detectedForm.formType, .dd1155)
        XCTAssertGreaterThan(detectedForm.confidence, 0.85)
        XCTAssertEqual(detectedForm.indicators.count, 3)
        XCTAssertTrue(detectedForm.indicators.contains { $0.value.contains("DD 1155") })
    }

    // MARK: - Field Mapping Tests

    func test_fieldMappingConfiguration_sf1449_requiredFields_configuredCorrectly() {
        // Test will fail initially - needs configuration setup
        let configuration = createSF1449FieldMappingConfiguration()

        XCTAssertEqual(configuration.formType, .sf1449)
        XCTAssertTrue(configuration.requiredFields.contains("solicitationNumber"))
        XCTAssertTrue(configuration.requiredFields.contains("vendorName"))
        XCTAssertTrue(configuration.criticalFields.contains("totalAmount"))
        XCTAssertTrue(configuration.criticalFields.contains("cage"))
        XCTAssertGreaterThan(configuration.fieldMappings.count, 10)
    }

    func test_fieldMapping_transformationRules_appliedCorrectly() {
        // Test will fail initially - needs transformation logic
        let rules = [
            TransformationRule(type: .trimWhitespace),
            TransformationRule(type: .upperCase),
            TransformationRule(type: .removeNonAlphanumeric),
        ]

        let mapping = FieldMapping(
            targetField: "cageCode",
            validationPattern: ValidationPatterns.cageCode,
            confidenceThreshold: 0.85,
            isCritical: true,
            transformationRules: rules
        )

        XCTAssertEqual(mapping.targetField, "cageCode")
        XCTAssertEqual(mapping.confidenceThreshold, 0.85)
        XCTAssertTrue(mapping.isCritical)
        XCTAssertEqual(mapping.transformationRules.count, 3)
        XCTAssertTrue(mapping.transformationRules.contains { $0.type == .upperCase })
    }

    // MARK: - Performance Tests

    func test_jsonParsing_largeDocument_completesWithinTimeLimit() {
        // Test will fail initially - needs performance optimization
        let startTime = Date()
        let jsonData = createLargeFormTestJSON()

        measure {
            do {
                let decoder = JSONDecoder()
                _ = try decoder.decode(GovernmentFormOCRModels.SF1449OCRData.self, from: jsonData)
            } catch {
                XCTFail("JSON parsing failed: \(error)")
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(processingTime, 0.1, "JSON parsing should complete within 100ms")
    }

    func test_validationPatterns_batchValidation_completesWithinTimeLimit() {
        // Test will fail initially - needs batch optimization
        let testData = createBatchValidationTestData()
        let startTime = Date()

        measure {
            for data in testData {
                guard let regex = try? NSRegularExpression(pattern: data.pattern) else {
                    XCTFail("Failed to create NSRegularExpression for pattern: \(data.pattern)")
                    continue
                }
                let range = NSRange(location: 0, length: data.value.utf16.count)
                _ = regex.firstMatch(in: data.value, options: [], range: range)
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(processingTime, 0.05, "Batch validation should complete within 50ms")
    }

    // MARK: - Edge Cases Tests

    func test_ocrFieldExtraction_emptyText_handlesGracefully() {
        // Test will fail initially - needs edge case handling
        let field = OCRFieldExtraction(
            rawText: "",
            processedText: "",
            confidence: 0.0,
            boundingBox: CGRect.zero,
            validationStatus: .invalid,
            fieldType: .unknown
        )

        XCTAssertFalse(field.isHighConfidence)
        XCTAssertFalse(field.isMediumConfidence)
        XCTAssertFalse(field.isAutoFillReady)
        XCTAssertEqual(field.rawText, "")
        XCTAssertEqual(field.processedText, "")
    }

    func test_jsonParsing_malformedData_throwsAppropriateError() {
        // Test will fail initially - needs error handling
        let malformedJSON = Data("{ \"invalid\": json }".utf8)

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(GovernmentFormOCRModels.SF1449OCRData.self, from: malformedJSON)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func test_validationPatterns_specialCharacters_handledCorrectly() {
        // Test will fail initially - needs special character handling
        let specialCases = [
            ("W52P1J-23-R-0001", ValidationPatterns.solicitationNumber, true),
            ("Contract.Number.123", ValidationPatterns.contractNumber, true),
            ("$1,234,567.89", ValidationPatterns.currency, true),
            ("(555) 123-4567", ValidationPatterns.phoneNumber, true),
        ]

        for (value, pattern, shouldMatch) in specialCases {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                XCTFail("Failed to create NSRegularExpression for pattern: \(pattern)")
                continue
            }
            let range = NSRange(location: 0, length: value.utf16.count)
            let match = regex.firstMatch(in: value, options: [], range: range)

            if shouldMatch {
                XCTAssertNotNil(match, "Value '\(value)' should match pattern")
            } else {
                XCTAssertNil(match, "Value '\(value)' should not match pattern")
            }
        }
    }

    // MARK: - Helper Methods

    private func createSF1449TestJSON() -> Data {
        let json = """
        {
            "solicitationNumber": {
                "rawText": "W52P1J-23-R-0001",
                "processedText": "W52P1J-23-R-0001",
                "confidence": 0.92,
                "boundingBox": {"x": 100, "y": 150, "width": 200, "height": 20},
                "validationStatus": "valid",
                "fieldType": "solicitation_number",
                "metadata": {}
            },
            "vendorInfo": {
                "cage": {
                    "rawText": "1ABC5",
                    "processedText": "1ABC5",
                    "confidence": 0.88,
                    "boundingBox": {"x": 50, "y": 200, "width": 80, "height": 20},
                    "validationStatus": "valid",
                    "fieldType": "cage_code",
                    "metadata": {}
                }
            },
            "contractInfo": {
                "totalAmount": {
                    "rawText": "$1,234,567.89",
                    "processedText": "$1,234,567.89",
                    "confidence": 0.95,
                    "boundingBox": {"x": 300, "y": 400, "width": 120, "height": 20},
                    "validationStatus": "valid",
                    "fieldType": "currency",
                    "metadata": {}
                }
            }
        }
        """
        guard let jsonData = json.data(using: .utf8) else {
            XCTFail("Failed to convert SF1449 test JSON string to Data")
            return Data()
        }
        return jsonData
    }

    private func createSF30TestJSON() -> Data {
        let json = """
        {
            "amendmentNumber": {
                "rawText": "0001",
                "processedText": "0001",
                "confidence": 0.91,
                "boundingBox": {"x": 150, "y": 100, "width": 60, "height": 20},
                "validationStatus": "valid",
                "fieldType": "code",
                "metadata": {}
            },
            "contractorInfo": {
                "cage": {
                    "rawText": "2DEF7",
                    "processedText": "2DEF7",
                    "confidence": 0.89,
                    "boundingBox": {"x": 75, "y": 250, "width": 80, "height": 20},
                    "validationStatus": "valid",
                    "fieldType": "cage_code",
                    "metadata": {}
                }
            },
            "priceChanges": {
                "rawText": "Increase $50,000.00",
                "processedText": "Increase $50,000.00",
                "confidence": 0.76,
                "boundingBox": {"x": 200, "y": 350, "width": 180, "height": 20},
                "validationStatus": "requires_review",
                "fieldType": "currency",
                "metadata": {}
            }
        }
        """
        guard let jsonData = json.data(using: .utf8) else {
            XCTFail("Failed to convert SF30 test JSON string to Data")
            return Data()
        }
        return jsonData
    }

    private func createDD1155TestJSON() -> Data {
        let json = """
        {
            "requestNumber": {
                "rawText": "TDY-2025-001",
                "processedText": "TDY-2025-001",
                "confidence": 0.93,
                "boundingBox": {"x": 120, "y": 80, "width": 140, "height": 20},
                "validationStatus": "valid",
                "fieldType": "code",
                "metadata": {}
            },
            "travelerInfo": {
                "name": {
                    "rawText": "Smith, John A.",
                    "processedText": "Smith, John A.",
                    "confidence": 0.87,
                    "boundingBox": {"x": 100, "y": 150, "width": 160, "height": 20},
                    "validationStatus": "valid",
                    "fieldType": "name",
                    "metadata": {}
                }
            },
            "costEstimate": {
                "totalEstimate": {
                    "rawText": "$2,450.00",
                    "processedText": "$2,450.00",
                    "confidence": 0.94,
                    "boundingBox": {"x": 250, "y": 400, "width": 100, "height": 20},
                    "validationStatus": "valid",
                    "fieldType": "currency",
                    "metadata": {}
                }
            }
        }
        """
        guard let jsonData = json.data(using: .utf8) else {
            XCTFail("Failed to convert DD1155 test JSON string to Data")
            return Data()
        }
        return jsonData
    }

    private func createLargeFormTestJSON() -> Data {
        // Create a large JSON with many fields for performance testing
        let baseJSON = createSF1449TestJSON()
        // In real implementation, this would be much larger
        return baseJSON
    }

    private func createBatchValidationTestData() -> [(pattern: String, value: String)] {
        return [
            (ValidationPatterns.cageCode, "1ABC5"),
            (ValidationPatterns.uei, "ABC123DEF456"),
            (ValidationPatterns.duns, "123456789"),
            (ValidationPatterns.contractNumber, "W52P1J-23-R-0001"),
            (ValidationPatterns.currency, "$1,234.56"),
            (ValidationPatterns.date, "01/15/2025"),
            (ValidationPatterns.phoneNumber, "(555) 123-4567"),
            (ValidationPatterns.email, "contractor@company.com"),
        ]
    }

    private func createSF1449FieldMappingConfiguration() -> FieldMappingConfiguration {
        let fieldMappings: [String: FieldMapping] = [
            "solicitationNumber": FieldMapping(
                targetField: "solicitationNumber",
                validationPattern: ValidationPatterns.solicitationNumber,
                confidenceThreshold: 0.85,
                isCritical: false
            ),
            "vendorName": FieldMapping(
                targetField: "vendorName",
                validationPattern: nil,
                confidenceThreshold: 0.75,
                isCritical: false
            ),
            "cage": FieldMapping(
                targetField: "cage",
                validationPattern: ValidationPatterns.cageCode,
                confidenceThreshold: 0.9,
                isCritical: true
            ),
            "totalAmount": FieldMapping(
                targetField: "totalAmount",
                validationPattern: ValidationPatterns.currency,
                confidenceThreshold: 0.95,
                isCritical: true
            ),
        ]

        return FieldMappingConfiguration(
            formType: .sf1449,
            fieldMappings: fieldMappings,
            requiredFields: ["solicitationNumber", "vendorName", "cage"],
            criticalFields: ["totalAmount", "cage"]
        )
    }
}

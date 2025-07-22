@testable import AppCore
import CoreGraphics
import XCTest

// MARK: - Form Auto-Population Engine Tests

// Phase 4.2 - Professional Document Scanner
// Smart Form Auto-Population Components - RED PHASE

final class FormAutoPopulationEngineTests: XCTestCase {
    // MARK: - SF-1449 Form Mapping Tests

    func test_sf1449FormMapping_highConfidenceFields_achieves95PercentAccuracy() async throws {
        // Test will fail initially - needs SF-1449 template implementation
        let ocrData = createHighConfidenceSF1449OCRData()

        let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(ocrData)

        // Validate >95% accuracy for high-confidence extractions (TDD rubric)
        let highConfidenceFields = result.populatedFields.filter { $0.confidence >= 0.85 }
        XCTAssertGreaterThanOrEqual(highConfidenceFields.count, 4, "Should have at least 4 high-confidence fields")

        let averageConfidence = highConfidenceFields.map { $0.confidence }.reduce(0, +) / Double(highConfidenceFields.count)
        XCTAssertGreaterThanOrEqual(averageConfidence, 0.95, "High-confidence fields should achieve ≥95% accuracy")

        // Validate specific field extractions
        XCTAssertEqual(result.suggestedFormType, .sf1449)
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Solicitation Number" })
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "CAGE Code" })
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Total Amount" })
    }

    func test_sf1449FormMapping_mediumConfidenceFields_achieves85PercentAccuracy() async throws {
        // Test will fail initially - needs medium confidence handling
        let ocrData = createMediumConfidenceSF1449OCRData()

        let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(ocrData)

        // Validate ≥85% accuracy for medium-confidence extractions (TDD rubric)
        let mediumConfidenceFields = result.populatedFields.filter { $0.confidence >= 0.65 && $0.confidence < 0.85 }
        XCTAssertGreaterThanOrEqual(mediumConfidenceFields.count, 2, "Should have at least 2 medium-confidence fields")

        let averageConfidence = mediumConfidenceFields.map { $0.confidence }.reduce(0, +) / Double(mediumConfidenceFields.count)
        XCTAssertGreaterThanOrEqual(averageConfidence, 0.85, "Medium-confidence fields should achieve ≥85% accuracy")

        // Validate processing time meets performance target
        XCTAssertLessThan(result.processingTime, 0.1, "Field mapping should complete within 100ms")
    }

    func test_sf1449FormMapping_criticalFieldDetection_identifies100Percent() async throws {
        // Test will fail initially - needs critical field logic
        let ocrData = createSF1449OCRDataWithCriticalFields()

        let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(ocrData)

        // Critical fields must be 100% identified (may require manual review)
        let criticalFieldNames = ["CAGE Code", "Total Amount", "Vendor Name", "Solicitation Number"]
        for criticalField in criticalFieldNames {
            let foundField = result.populatedFields.first { $0.fieldName == criticalField }
            XCTAssertNotNil(foundField, "Critical field '\(criticalField)' must be identified")
        }

        // Validate critical field accuracy
        let criticalFields = result.populatedFields.filter { criticalFieldNames.contains($0.fieldName) }
        let criticalAccuracy = criticalFields.map { $0.confidence }.reduce(0, +) / Double(criticalFields.count)
        XCTAssertGreaterThanOrEqual(criticalAccuracy, 0.85, "Critical fields should achieve ≥85% accuracy")
    }

    func test_sf1449FormMapping_falsePositiveRate_below5Percent() async throws {
        // Test will fail initially - needs false positive detection
        let ocrData = createSF1449OCRDataWithNoise()

        let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(ocrData)

        // Validate false positive rate <5% for field detection
        let totalFieldsDetected = result.populatedFields.count
        let lowConfidenceFields = result.populatedFields.filter { $0.confidence < 0.5 }.count
        let falsePositiveRate = Double(lowConfidenceFields) / Double(totalFieldsDetected)

        XCTAssertLessThan(falsePositiveRate, 0.05, "False positive rate should be below 5%")

        // Check for appropriate warnings
        XCTAssertFalse(result.warnings.isEmpty, "Should generate warnings for questionable extractions")
    }

    // MARK: - SF-30 Form Mapping Tests

    func test_sf30FormMapping_highConfidenceFields_achieves95PercentAccuracy() async throws {
        // Test will fail initially - needs SF-30 template implementation
        let ocrData = createHighConfidenceSF30OCRData()

        let result = try await FormAutoPopulationEngine.mapSF30ToTemplate(ocrData)

        // Validate >95% accuracy for high-confidence extractions
        let highConfidenceFields = result.populatedFields.filter { $0.confidence >= 0.85 }
        XCTAssertGreaterThanOrEqual(highConfidenceFields.count, 3, "Should have at least 3 high-confidence fields")

        let averageConfidence = highConfidenceFields.map { $0.confidence }.reduce(0, +) / Double(highConfidenceFields.count)
        XCTAssertGreaterThanOrEqual(averageConfidence, 0.95, "High-confidence fields should achieve ≥95% accuracy")

        // Validate SF-30 specific fields
        XCTAssertEqual(result.suggestedFormType, .sf30)
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Amendment Number" })
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Contract Number" })
    }

    func test_sf30FormMapping_mediumConfidenceFields_achieves85PercentAccuracy() async throws {
        // Test will fail initially - needs medium confidence handling
        let ocrData = createMediumConfidenceSF30OCRData()

        let result = try await FormAutoPopulationEngine.mapSF30ToTemplate(ocrData)

        // Validate ≥85% accuracy for medium-confidence extractions
        let mediumConfidenceFields = result.populatedFields.filter { $0.confidence >= 0.65 && $0.confidence < 0.85 }
        let averageConfidence = mediumConfidenceFields.isEmpty ? 0 : mediumConfidenceFields.map { $0.confidence }.reduce(0, +) / Double(mediumConfidenceFields.count)

        if !mediumConfidenceFields.isEmpty {
            XCTAssertGreaterThanOrEqual(averageConfidence, 0.85, "Medium-confidence fields should achieve ≥85% accuracy")
        }

        // Validate processing performance
        XCTAssertLessThan(result.processingTime, 0.1, "Field mapping should complete within 100ms")
    }

    // MARK: - DD-1155 Form Mapping Tests

    func test_dd1155FormMapping_highConfidenceFields_achieves95PercentAccuracy() async throws {
        // Test will fail initially - needs DD-1155 template implementation
        let ocrData = createHighConfidenceDD1155OCRData()

        let result = try await FormAutoPopulationEngine.mapDD1155ToTemplate(ocrData)

        // Validate >95% accuracy for high-confidence extractions
        let highConfidenceFields = result.populatedFields.filter { $0.confidence >= 0.85 }
        XCTAssertGreaterThanOrEqual(highConfidenceFields.count, 3, "Should have at least 3 high-confidence fields")

        let averageConfidence = highConfidenceFields.map { $0.confidence }.reduce(0, +) / Double(highConfidenceFields.count)
        XCTAssertGreaterThanOrEqual(averageConfidence, 0.95, "High-confidence fields should achieve ≥95% accuracy")

        // Validate DD-1155 specific fields
        XCTAssertEqual(result.suggestedFormType, .dd1155)
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Request Number" })
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Traveler Name" })
        XCTAssertTrue(result.populatedFields.contains { $0.fieldName == "Total Estimate" })
    }

    func test_dd1155FormMapping_criticalFields_flaggedForReview() async throws {
        // Test will fail initially - needs critical field flagging
        let ocrData = createDD1155OCRDataWithCriticalFields()

        let result = try await FormAutoPopulationEngine.mapDD1155ToTemplate(ocrData)

        // Critical fields should be properly flagged for manual review
        let totalEstimateField = result.populatedFields.first { $0.fieldName == "Total Estimate" }
        XCTAssertNotNil(totalEstimateField, "Total Estimate is a critical field and must be identified")

        if let field = totalEstimateField {
            // High-value financial fields should have warnings
            if field.extractedValue.contains("$") {
                let currencyValue = field.extractedValue.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                if let value = Double(currencyValue), value > 1000 {
                    XCTAssertFalse(result.warnings.isEmpty, "High-value financial fields should generate warnings for manual review")
                }
            }
        }
    }

    // MARK: - Government Form Validation Tests

    func test_governmentFormValidation_highConfidence_meetsAccuracyTargets() async throws {
        // Test will fail initially - needs validation implementation
        let fields = createHighConfidencePopulatedFields()

        let validationResult = try await FormAutoPopulationEngine.validateGovernmentFormAccuracy(
            formType: .sf1449,
            populatedFields: fields
        )

        // Should meet ≥95% accuracy target for high-confidence fields
        XCTAssertTrue(validationResult.meetsAccuracyTarget, "Should meet 95% accuracy target")
        XCTAssertGreaterThanOrEqual(validationResult.overallAccuracy, 0.95, "Overall accuracy should be ≥95%")
        XCTAssertTrue(validationResult.meetsAllTargets, "Should meet all accuracy targets")

        // Critical fields should meet ≥85% target
        XCTAssertTrue(validationResult.meetsCriticalFieldTarget, "Should meet critical field accuracy target")
        XCTAssertGreaterThanOrEqual(validationResult.criticalFieldsAccuracy, 0.85, "Critical fields accuracy should be ≥85%")
    }

    func test_governmentFormValidation_cageCodeValidation_correctFormat() async throws {
        // Test will fail initially - needs CAGE code validation
        let fields = createPopulatedFieldsWithCAGECode()

        let validationResult = try await FormAutoPopulationEngine.validateGovernmentFormAccuracy(
            formType: .sf1449,
            populatedFields: fields
        )

        // CAGE code validation should be 100% correct format (5-char alphanumeric)
        let cageField = validationResult.fieldResults.first { $0.fieldName.contains("CAGE") }
        XCTAssertNotNil(cageField, "CAGE field should be validated")

        if let field = cageField {
            XCTAssertEqual(field.validationStatus, .passed, "Valid CAGE code should pass validation")
            XCTAssertGreaterThanOrEqual(field.accuracy, 0.9, "CAGE code accuracy should be high")
        }
    }

    func test_governmentFormValidation_currencyFormatting_usDollarCompliance() async throws {
        // Test will fail initially - needs currency validation
        let fields = createPopulatedFieldsWithCurrency()

        let validationResult = try await FormAutoPopulationEngine.validateGovernmentFormAccuracy(
            formType: .sf1449,
            populatedFields: fields
        )

        // Currency formatting should be 100% US dollar compliance
        let currencyFields = validationResult.fieldResults.filter { $0.fieldName.contains("Amount") || $0.fieldName.contains("Estimate") }
        XCTAssertFalse(currencyFields.isEmpty, "Should have currency fields to validate")

        for field in currencyFields {
            XCTAssertEqual(field.validationStatus, .passed, "Valid currency should pass validation")
        }
    }

    // MARK: - Performance Tests

    func test_ocrProcessing_completesWithin2Seconds() async throws {
        // Test will fail initially - needs performance optimization
        let startTime = Date()
        let ocrData = createLargeFormOCRData()

        let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(ocrData)

        let processingTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(processingTime, 2.0, "OCR processing should complete within 2 seconds")
        XCTAssertLessThan(result.processingTime, 0.1, "Field mapping should complete within 100ms")
    }

    func test_fieldMapping_completesWithin100Milliseconds() async throws {
        // Test will fail initially - needs performance optimization
        let ocrData = createStandardSF1449OCRData()

        measure {
            Task {
                let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(ocrData)
                XCTAssertLessThan(result.processingTime, 0.1, "Field mapping should complete within 100ms")
            }
        }
    }

    func test_confidenceCalculation_completesWithin50Milliseconds() async throws {
        // Test will fail initially - needs confidence calculation optimization
        let fields = createPopulatedFieldsForConfidenceTest()

        let startTime = Date()
        let validationResult = try await FormAutoPopulationEngine.validateGovernmentFormAccuracy(
            formType: .sf1449,
            populatedFields: fields
        )
        let processingTime = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(processingTime, 0.05, "Confidence calculation should complete within 50ms")
        XCTAssertNotNil(validationResult.overallAccuracy, "Should calculate overall accuracy")
    }

    // MARK: - Form Detection Tests

    func test_formDetection_sf1449_identifiesCorrectly() async throws {
        // Test will fail initially - needs form detection implementation
        let document = createSF1449TestDocument()

        let detectedForm = try await FormAutoPopulationEngine.detectFormTypeFromOCR(document)

        XCTAssertEqual(detectedForm.formType, .sf1449, "Should correctly identify SF-1449 form")
        XCTAssertGreaterThanOrEqual(detectedForm.confidence, 0.85, "Should have high confidence in detection")

        // Should have appropriate indicators
        XCTAssertTrue(detectedForm.indicators.contains { $0.type == .formNumber }, "Should detect form number indicator")
        XCTAssertTrue(detectedForm.indicators.contains { $0.type == .title }, "Should detect title indicator")
    }

    func test_formDetection_sf30_identifiesCorrectly() async throws {
        // Test will fail initially - needs form detection implementation
        let document = createSF30TestDocument()

        let detectedForm = try await FormAutoPopulationEngine.detectFormTypeFromOCR(document)

        XCTAssertEqual(detectedForm.formType, .sf30, "Should correctly identify SF-30 form")
        XCTAssertGreaterThanOrEqual(detectedForm.confidence, 0.85, "Should have high confidence in detection")
        XCTAssertFalse(detectedForm.indicators.isEmpty, "Should have detection indicators")
    }

    func test_formDetection_dd1155_identifiesCorrectly() async throws {
        // Test will fail initially - needs form detection implementation
        let document = createDD1155TestDocument()

        let detectedForm = try await FormAutoPopulationEngine.detectFormTypeFromOCR(document)

        XCTAssertEqual(detectedForm.formType, .dd1155, "Should correctly identify DD-1155 form")
        XCTAssertGreaterThanOrEqual(detectedForm.confidence, 0.85, "Should have high confidence in detection")
        XCTAssertTrue(detectedForm.indicators.contains { $0.value.contains("TDY") }, "Should detect TDY indicator")
    }

    // MARK: - Edge Cases and Error Handling

    func test_formMapping_emptyOCRData_handlesGracefully() async throws {
        // Test will fail initially - needs edge case handling
        let emptyOCRData = GovernmentFormOCRModels.SF1449OCRData()

        let result = try await FormAutoPopulationEngine.mapSF1449ToTemplate(emptyOCRData)

        XCTAssertEqual(result.confidence, 0.0, "Empty data should result in zero confidence")
        XCTAssertTrue(result.populatedFields.isEmpty, "No fields should be populated from empty data")
        XCTAssertEqual(result.suggestedFormType, .sf1449, "Should still suggest correct form type")
    }

    func test_validation_invalidFieldFormats_generatesWarnings() async throws {
        // Test will fail initially - needs validation error handling
        let fields = createPopulatedFieldsWithInvalidFormats()

        let validationResult = try await FormAutoPopulationEngine.validateGovernmentFormAccuracy(
            formType: .sf1449,
            populatedFields: fields
        )

        // Should identify validation failures
        XCTAssertFalse(validationResult.failedFields.isEmpty, "Should identify fields that failed validation")
        XCTAssertFalse(validationResult.warningFields.isEmpty, "Should identify fields needing review")
        XCTAssertFalse(validationResult.meetsAllTargets, "Should not meet all targets with invalid formats")
    }

    // MARK: - Helper Methods

    private func createHighConfidenceSF1449OCRData() -> GovernmentFormOCRModels.SF1449OCRData {
        return GovernmentFormOCRModels.SF1449OCRData(
            solicitationNumber: OCRFieldExtraction(
                rawText: "W52P1J-23-R-0001",
                processedText: "W52P1J-23-R-0001",
                confidence: 0.96,
                boundingBox: CGRect(x: 100, y: 150, width: 200, height: 20),
                validationStatus: .valid,
                fieldType: .solicitationNumber
            ),
            contractNumber: OCRFieldExtraction(
                rawText: "W52P1J-23-C-0001",
                processedText: "W52P1J-23-C-0001",
                confidence: 0.94,
                boundingBox: CGRect(x: 100, y: 180, width: 200, height: 20),
                validationStatus: .valid,
                fieldType: .contractNumber
            ),
            vendorInfo: GovernmentFormOCRModels.SF1449VendorOCRData(
                name: OCRFieldExtraction(
                    rawText: "ACME Corporation",
                    processedText: "ACME Corporation",
                    confidence: 0.92,
                    boundingBox: CGRect(x: 50, y: 250, width: 200, height: 20),
                    validationStatus: .valid,
                    fieldType: .name
                ),
                cage: OCRFieldExtraction(
                    rawText: "1ABC5",
                    processedText: "1ABC5",
                    confidence: 0.98,
                    boundingBox: CGRect(x: 50, y: 280, width: 80, height: 20),
                    validationStatus: .valid,
                    fieldType: .cageCode
                )
            ),
            contractInfo: GovernmentFormOCRModels.SF1449ContractOCRData(
                totalAmount: OCRFieldExtraction(
                    rawText: "$1,234,567.89",
                    processedText: "$1,234,567.89",
                    confidence: 0.97,
                    boundingBox: CGRect(x: 300, y: 400, width: 120, height: 20),
                    validationStatus: .valid,
                    fieldType: .currency
                )
            )
        )
    }

    private func createMediumConfidenceSF1449OCRData() -> GovernmentFormOCRModels.SF1449OCRData {
        return GovernmentFormOCRModels.SF1449OCRData(
            solicitationNumber: OCRFieldExtraction(
                rawText: "W52P1J-23-R-000l", // 'l' instead of '1' - OCR error
                processedText: "W52P1J-23-R-0001",
                confidence: 0.78,
                boundingBox: CGRect(x: 100, y: 150, width: 200, height: 20),
                validationStatus: .requiresReview,
                fieldType: .solicitationNumber
            ),
            vendorInfo: GovernmentFormOCRModels.SF1449VendorOCRData(
                name: OCRFieldExtraction(
                    rawText: "ACME Corp",
                    processedText: "ACME Corp",
                    confidence: 0.72,
                    boundingBox: CGRect(x: 50, y: 250, width: 150, height: 20),
                    validationStatus: .requiresReview,
                    fieldType: .name
                )
            )
        )
    }

    private func createSF1449OCRDataWithCriticalFields() -> GovernmentFormOCRModels.SF1449OCRData {
        return createHighConfidenceSF1449OCRData()
    }

    private func createSF1449OCRDataWithNoise() -> GovernmentFormOCRModels.SF1449OCRData {
        return GovernmentFormOCRModels.SF1449OCRData(
            solicitationNumber: OCRFieldExtraction(
                rawText: "W52P1J-23-R-0001",
                processedText: "W52P1J-23-R-0001",
                confidence: 0.96,
                boundingBox: CGRect(x: 100, y: 150, width: 200, height: 20),
                validationStatus: .valid,
                fieldType: .solicitationNumber
            ),
            vendorInfo: GovernmentFormOCRModels.SF1449VendorOCRData(
                name: OCRFieldExtraction(
                    rawText: "unclear text here",
                    processedText: "unclear text here",
                    confidence: 0.25, // Low confidence - potential false positive
                    boundingBox: CGRect(x: 50, y: 250, width: 200, height: 20),
                    validationStatus: .invalid,
                    fieldType: .name
                )
            )
        )
    }

    private func createHighConfidenceSF30OCRData() -> GovernmentFormOCRModels.SF30OCRData {
        return GovernmentFormOCRModels.SF30OCRData(
            amendmentNumber: OCRFieldExtraction(
                rawText: "0001",
                processedText: "0001",
                confidence: 0.95,
                boundingBox: CGRect(x: 150, y: 100, width: 60, height: 20),
                validationStatus: .valid,
                fieldType: .code
            ),
            contractNumber: OCRFieldExtraction(
                rawText: "W52P1J-23-C-0001",
                processedText: "W52P1J-23-C-0001",
                confidence: 0.93,
                boundingBox: CGRect(x: 100, y: 130, width: 200, height: 20),
                validationStatus: .valid,
                fieldType: .contractNumber
            ),
            contractorInfo: GovernmentFormOCRModels.SF30ContractorOCRData(
                name: OCRFieldExtraction(
                    rawText: "ACME Corporation",
                    processedText: "ACME Corporation",
                    confidence: 0.91,
                    boundingBox: CGRect(x: 50, y: 200, width: 200, height: 20),
                    validationStatus: .valid,
                    fieldType: .name
                ),
                cage: OCRFieldExtraction(
                    rawText: "2DEF7",
                    processedText: "2DEF7",
                    confidence: 0.97,
                    boundingBox: CGRect(x: 75, y: 250, width: 80, height: 20),
                    validationStatus: .valid,
                    fieldType: .cageCode
                )
            )
        )
    }

    private func createMediumConfidenceSF30OCRData() -> GovernmentFormOCRModels.SF30OCRData {
        return GovernmentFormOCRModels.SF30OCRData(
            amendmentNumber: OCRFieldExtraction(
                rawText: "000l", // OCR error
                processedText: "0001",
                confidence: 0.74,
                boundingBox: CGRect(x: 150, y: 100, width: 60, height: 20),
                validationStatus: .requiresReview,
                fieldType: .code
            )
        )
    }

    private func createHighConfidenceDD1155OCRData() -> GovernmentFormOCRModels.DD1155OCRData {
        return GovernmentFormOCRModels.DD1155OCRData(
            requestNumber: OCRFieldExtraction(
                rawText: "TDY-2025-001",
                processedText: "TDY-2025-001",
                confidence: 0.96,
                boundingBox: CGRect(x: 120, y: 80, width: 140, height: 20),
                validationStatus: .valid,
                fieldType: .code
            ),
            travelerInfo: GovernmentFormOCRModels.DD1155TravelerOCRData(
                name: OCRFieldExtraction(
                    rawText: "Smith, John A.",
                    processedText: "Smith, John A.",
                    confidence: 0.94,
                    boundingBox: CGRect(x: 100, y: 150, width: 160, height: 20),
                    validationStatus: .valid,
                    fieldType: .name
                ),
                grade: OCRFieldExtraction(
                    rawText: "GS-13",
                    processedText: "GS-13",
                    confidence: 0.92,
                    boundingBox: CGRect(x: 300, y: 150, width: 80, height: 20),
                    validationStatus: .valid,
                    fieldType: .code
                )
            ),
            costEstimate: GovernmentFormOCRModels.DD1155CostOCRData(
                totalEstimate: OCRFieldExtraction(
                    rawText: "$2,450.00",
                    processedText: "$2,450.00",
                    confidence: 0.97,
                    boundingBox: CGRect(x: 250, y: 400, width: 100, height: 20),
                    validationStatus: .valid,
                    fieldType: .currency
                )
            )
        )
    }

    private func createDD1155OCRDataWithCriticalFields() -> GovernmentFormOCRModels.DD1155OCRData {
        return createHighConfidenceDD1155OCRData()
    }

    private func createHighConfidencePopulatedFields() -> [ExtractedPopulatedField] {
        return [
            ExtractedPopulatedField(
                fieldName: "Solicitation Number",
                fieldType: .text,
                extractedValue: "W52P1J-23-R-0001",
                confidence: 0.96,
                sourceText: "W52P1J-23-R-0001",
                sourceLocation: CGRect(x: 100, y: 150, width: 200, height: 20)
            ),
            ExtractedPopulatedField(
                fieldName: "CAGE Code",
                fieldType: .text,
                extractedValue: "1ABC5",
                confidence: 0.98,
                sourceText: "1ABC5",
                sourceLocation: CGRect(x: 50, y: 280, width: 80, height: 20)
            ),
            ExtractedPopulatedField(
                fieldName: "Total Amount",
                fieldType: .currency,
                extractedValue: "$1,234,567.89",
                confidence: 0.97,
                sourceText: "$1,234,567.89",
                sourceLocation: CGRect(x: 300, y: 400, width: 120, height: 20)
            ),
            ExtractedPopulatedField(
                fieldName: "Vendor Name",
                fieldType: .text,
                extractedValue: "ACME Corporation",
                confidence: 0.95,
                sourceText: "ACME Corporation",
                sourceLocation: CGRect(x: 50, y: 250, width: 200, height: 20)
            ),
        ]
    }

    private func createPopulatedFieldsWithCAGECode() -> [ExtractedPopulatedField] {
        return [
            ExtractedPopulatedField(
                fieldName: "CAGE Code",
                fieldType: .text,
                extractedValue: "1ABC5",
                confidence: 0.95,
                sourceText: "1ABC5",
                sourceLocation: CGRect(x: 50, y: 280, width: 80, height: 20)
            ),
        ]
    }

    private func createPopulatedFieldsWithCurrency() -> [ExtractedPopulatedField] {
        return [
            ExtractedPopulatedField(
                fieldName: "Total Amount",
                fieldType: .currency,
                extractedValue: "$1,234,567.89",
                confidence: 0.97,
                sourceText: "$1,234,567.89",
                sourceLocation: CGRect(x: 300, y: 400, width: 120, height: 20)
            ),
            ExtractedPopulatedField(
                fieldName: "Travel Estimate",
                fieldType: .currency,
                extractedValue: "$2,450.00",
                confidence: 0.94,
                sourceText: "$2,450.00",
                sourceLocation: CGRect(x: 250, y: 400, width: 100, height: 20)
            ),
        ]
    }

    private func createLargeFormOCRData() -> GovernmentFormOCRModels.SF1449OCRData {
        // Create a larger dataset for performance testing
        return createHighConfidenceSF1449OCRData()
    }

    private func createStandardSF1449OCRData() -> GovernmentFormOCRModels.SF1449OCRData {
        return createHighConfidenceSF1449OCRData()
    }

    private func createPopulatedFieldsForConfidenceTest() -> [ExtractedPopulatedField] {
        return createHighConfidencePopulatedFields()
    }

    private func createSF1449TestDocument() -> ScannedDocument {
        // Create a mock scanned document with SF-1449 indicators
        let ocrResult = OCRResult(
            fullText: "SOLICITATION/CONTRACT/ORDER FOR COMMERCIAL ITEMS SF 1449",
            extractedMetadata: ExtractedMetadata(
                dates: [],
                currencies: [],
                addresses: [],
                phoneNumbers: [],
                emailAddresses: []
            ),
            confidenceScore: 0.9
        )

        let page = ScannedPage(
            image: UIImage(), // Placeholder
            ocrResult: ocrResult,
            pageNumber: 1,
            processingTime: 0.5,
            metadata: [:]
        )

        return ScannedDocument(
            id: UUID(),
            pages: [page],
            metadata: [:],
            createdAt: Date()
        )
    }

    private func createSF30TestDocument() -> ScannedDocument {
        let ocrResult = OCRResult(
            fullText: "AMENDMENT OF SOLICITATION/MODIFICATION OF CONTRACT SF 30",
            extractedMetadata: ExtractedMetadata(
                dates: [],
                currencies: [],
                addresses: [],
                phoneNumbers: [],
                emailAddresses: []
            ),
            confidenceScore: 0.88
        )

        let page = ScannedPage(
            image: UIImage(),
            ocrResult: ocrResult,
            pageNumber: 1,
            processingTime: 0.5,
            metadata: [:]
        )

        return ScannedDocument(
            id: UUID(),
            pages: [page],
            metadata: [:],
            createdAt: Date()
        )
    }

    private func createDD1155TestDocument() -> ScannedDocument {
        let ocrResult = OCRResult(
            fullText: "REQUEST AND AUTHORIZATION FOR TDY TRAVEL DD 1155",
            extractedMetadata: ExtractedMetadata(
                dates: [],
                currencies: [],
                addresses: [],
                phoneNumbers: [],
                emailAddresses: []
            ),
            confidenceScore: 0.87
        )

        let page = ScannedPage(
            image: UIImage(),
            ocrResult: ocrResult,
            pageNumber: 1,
            processingTime: 0.5,
            metadata: [:]
        )

        return ScannedDocument(
            id: UUID(),
            pages: [page],
            metadata: [:],
            createdAt: Date()
        )
    }

    private func createPopulatedFieldsWithInvalidFormats() -> [ExtractedPopulatedField] {
        return [
            ExtractedPopulatedField(
                fieldName: "CAGE Code",
                fieldType: .text,
                extractedValue: "123", // Invalid - too short
                confidence: 0.75,
                sourceText: "123",
                sourceLocation: CGRect(x: 50, y: 280, width: 80, height: 20)
            ),
            ExtractedPopulatedField(
                fieldName: "Total Amount",
                fieldType: .currency,
                extractedValue: "1234567", // Invalid - no currency symbol
                confidence: 0.80,
                sourceText: "1234567",
                sourceLocation: CGRect(x: 300, y: 400, width: 120, height: 20)
            ),
        ]
    }
}

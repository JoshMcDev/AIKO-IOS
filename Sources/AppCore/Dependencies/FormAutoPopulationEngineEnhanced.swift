import Foundation

// MARK: - Enhanced Form Auto-Population Engine (Phase 4.2)

// Government Form Templates Support

public extension FormAutoPopulationEngine {
    // MARK: - Government Form Template Mapping

    /// Maps SF-1449 OCR data to form auto-population result
    static func mapSF1449ToTemplate(_ ocrData: GovernmentFormOCRModels.SF1449OCRData) async throws -> FormAutoPopulationResult {
        let startTime = Date()
        var populatedFields: [ExtractedPopulatedField] = []
        var warnings: [String] = []

        // Map solicitation number
        if let solicitationNumber = ocrData.solicitationNumber {
            populatedFields.append(
                ExtractedPopulatedField(
                    fieldName: "Solicitation Number",
                    fieldType: .text,
                    extractedValue: solicitationNumber.processedText,
                    confidence: solicitationNumber.confidence,
                    sourceText: solicitationNumber.rawText,
                    sourceLocation: solicitationNumber.boundingBox
                )
            )
        }

        // Map contract number
        if let contractNumber = ocrData.contractNumber {
            populatedFields.append(
                ExtractedPopulatedField(
                    fieldName: "Contract Number",
                    fieldType: .text,
                    extractedValue: contractNumber.processedText,
                    confidence: contractNumber.confidence,
                    sourceText: contractNumber.rawText,
                    sourceLocation: contractNumber.boundingBox
                )
            )
        }

        // Map vendor information
        if let vendorInfo = ocrData.vendorInfo {
            if let vendorName = vendorInfo.name {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Vendor Name",
                        fieldType: .text,
                        extractedValue: vendorName.processedText,
                        confidence: vendorName.confidence,
                        sourceText: vendorName.rawText,
                        sourceLocation: vendorName.boundingBox
                    )
                )
            }

            if let cage = vendorInfo.cage {
                // Validate CAGE format
                let isValidCAGE = cage.processedText.range(of: ValidationPatterns.cageCode, options: .regularExpression) != nil
                if !isValidCAGE {
                    warnings.append("CAGE code format may be invalid: \(cage.processedText)")
                }

                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "CAGE Code",
                        fieldType: .text,
                        extractedValue: cage.processedText,
                        confidence: isValidCAGE ? cage.confidence : cage.confidence * 0.7,
                        sourceText: cage.rawText,
                        sourceLocation: cage.boundingBox
                    )
                )
            }
        }

        // Map contract information
        if let contractInfo = ocrData.contractInfo {
            if let totalAmount = contractInfo.totalAmount {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Total Amount",
                        fieldType: .currency,
                        extractedValue: totalAmount.processedText,
                        confidence: totalAmount.confidence,
                        sourceText: totalAmount.rawText,
                        sourceLocation: totalAmount.boundingBox
                    )
                )
            }
        }

        // Calculate overall confidence
        let overallConfidence = populatedFields.isEmpty ? 0.0 :
            populatedFields.map(\.confidence).reduce(0, +) / Double(populatedFields.count)

        let extractedData = GovernmentFormData(
            vendorInfo: ocrData.vendorInfo?.name != nil ? VendorInfo(
                name: ocrData.vendorInfo?.name?.processedText ?? "",
                cage: ocrData.vendorInfo?.cage?.processedText
            ) : nil,
            contractInfo: ContractInfo(
                contractNumber: ocrData.contractNumber?.processedText,
                solicitation: ocrData.solicitationNumber?.processedText
            )
        )

        return FormAutoPopulationResult(
            extractedData: extractedData,
            suggestedFormType: .sf1449,
            confidence: overallConfidence,
            populatedFields: populatedFields,
            processingTime: Date().timeIntervalSince(startTime),
            warnings: warnings
        )
    }

    /// Maps SF-30 OCR data to form auto-population result
    static func mapSF30ToTemplate(_ ocrData: GovernmentFormOCRModels.SF30OCRData) async throws -> FormAutoPopulationResult {
        let startTime = Date()
        var populatedFields: [ExtractedPopulatedField] = []
        var warnings: [String] = []

        // Map amendment number
        if let amendmentNumber = ocrData.amendmentNumber {
            populatedFields.append(
                ExtractedPopulatedField(
                    fieldName: "Amendment Number",
                    fieldType: .text,
                    extractedValue: amendmentNumber.processedText,
                    confidence: amendmentNumber.confidence,
                    sourceText: amendmentNumber.rawText,
                    sourceLocation: amendmentNumber.boundingBox
                )
            )
        }

        // Map effective date
        if let effectiveDate = ocrData.effectiveDate {
            // Validate date format
            let isValidDate = effectiveDate.processedText.range(of: ValidationPatterns.date, options: .regularExpression) != nil
            if !isValidDate {
                warnings.append("Date format may be invalid: \(effectiveDate.processedText)")
            }

            populatedFields.append(
                ExtractedPopulatedField(
                    fieldName: "Effective Date",
                    fieldType: .date,
                    extractedValue: effectiveDate.processedText,
                    confidence: isValidDate ? effectiveDate.confidence : effectiveDate.confidence * 0.8,
                    sourceText: effectiveDate.rawText,
                    sourceLocation: effectiveDate.boundingBox
                )
            )
        }

        // Map contractor information
        if let contractorInfo = ocrData.contractorInfo {
            if let contractorName = contractorInfo.name {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Contractor Name",
                        fieldType: .text,
                        extractedValue: contractorName.processedText,
                        confidence: contractorName.confidence,
                        sourceText: contractorName.rawText,
                        sourceLocation: contractorName.boundingBox
                    )
                )
            }

            if let cage = contractorInfo.cage {
                // Validate CAGE format
                let isValidCAGE = cage.processedText.range(of: ValidationPatterns.cageCode, options: .regularExpression) != nil
                if !isValidCAGE {
                    warnings.append("CAGE code format may be invalid: \(cage.processedText)")
                }

                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "CAGE Code",
                        fieldType: .text,
                        extractedValue: cage.processedText,
                        confidence: isValidCAGE ? cage.confidence : cage.confidence * 0.7,
                        sourceText: cage.rawText,
                        sourceLocation: cage.boundingBox
                    )
                )
            }
        }

        // Map price changes
        if let priceChanges = ocrData.priceChanges {
            populatedFields.append(
                ExtractedPopulatedField(
                    fieldName: "Price Changes",
                    fieldType: .currency,
                    extractedValue: priceChanges.processedText,
                    confidence: priceChanges.confidence,
                    sourceText: priceChanges.rawText,
                    sourceLocation: priceChanges.boundingBox
                )
            )
        }

        // Calculate overall confidence
        let overallConfidence = populatedFields.isEmpty ? 0.0 :
            populatedFields.map(\.confidence).reduce(0, +) / Double(populatedFields.count)

        let extractedData = GovernmentFormData(
            vendorInfo: ocrData.contractorInfo?.name != nil ? VendorInfo(
                name: ocrData.contractorInfo?.name?.processedText ?? "",
                cage: ocrData.contractorInfo?.cage?.processedText
            ) : nil,
            contractInfo: ContractInfo(
                contractNumber: ocrData.contractNumber?.processedText,
                solicitation: ocrData.solicitationNumber?.processedText
            )
        )

        return FormAutoPopulationResult(
            extractedData: extractedData,
            suggestedFormType: .sf30,
            confidence: overallConfidence,
            populatedFields: populatedFields,
            processingTime: Date().timeIntervalSince(startTime),
            warnings: warnings
        )
    }

    /// Maps DD-1155 OCR data to form auto-population result
    static func mapDD1155ToTemplate(_ ocrData: GovernmentFormOCRModels.DD1155OCRData) async throws -> FormAutoPopulationResult {
        let startTime = Date()
        var populatedFields: [ExtractedPopulatedField] = []
        var warnings: [String] = []

        // Map request number
        if let requestNumber = ocrData.requestNumber {
            populatedFields.append(
                ExtractedPopulatedField(
                    fieldName: "Request Number",
                    fieldType: .text,
                    extractedValue: requestNumber.processedText,
                    confidence: requestNumber.confidence,
                    sourceText: requestNumber.rawText,
                    sourceLocation: requestNumber.boundingBox
                )
            )
        }

        // Map traveler information
        if let travelerInfo = ocrData.travelerInfo {
            if let travelerName = travelerInfo.name {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Traveler Name",
                        fieldType: .text,
                        extractedValue: travelerName.processedText,
                        confidence: travelerName.confidence,
                        sourceText: travelerName.rawText,
                        sourceLocation: travelerName.boundingBox
                    )
                )
            }

            if let grade = travelerInfo.grade {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Grade",
                        fieldType: .text,
                        extractedValue: grade.processedText,
                        confidence: grade.confidence,
                        sourceText: grade.rawText,
                        sourceLocation: grade.boundingBox
                    )
                )
            }

            if let organization = travelerInfo.organization {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Organization",
                        fieldType: .text,
                        extractedValue: organization.processedText,
                        confidence: organization.confidence,
                        sourceText: organization.rawText,
                        sourceLocation: organization.boundingBox
                    )
                )
            }
        }

        // Map travel information
        if let travelInfo = ocrData.travelInfo {
            if let purpose = travelInfo.purpose {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Travel Purpose",
                        fieldType: .text,
                        extractedValue: purpose.processedText,
                        confidence: purpose.confidence,
                        sourceText: purpose.rawText,
                        sourceLocation: purpose.boundingBox
                    )
                )
            }

            if let destination = travelInfo.destination {
                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Destination",
                        fieldType: .address,
                        extractedValue: destination.processedText,
                        confidence: destination.confidence,
                        sourceText: destination.rawText,
                        sourceLocation: destination.boundingBox
                    )
                )
            }
        }

        // Map cost estimate
        if let costEstimate = ocrData.costEstimate {
            if let totalEstimate = costEstimate.totalEstimate {
                // Validate currency format
                let isValidCurrency = totalEstimate.processedText.range(of: ValidationPatterns.currency, options: .regularExpression) != nil
                if !isValidCurrency {
                    warnings.append("Currency format may be invalid: \(totalEstimate.processedText)")
                }

                populatedFields.append(
                    ExtractedPopulatedField(
                        fieldName: "Total Estimate",
                        fieldType: .currency,
                        extractedValue: totalEstimate.processedText,
                        confidence: isValidCurrency ? totalEstimate.confidence : totalEstimate.confidence * 0.8,
                        sourceText: totalEstimate.rawText,
                        sourceLocation: totalEstimate.boundingBox
                    )
                )
            }
        }

        // Calculate overall confidence
        let overallConfidence = populatedFields.isEmpty ? 0.0 :
            populatedFields.map(\.confidence).reduce(0, +) / Double(populatedFields.count)

        let extractedData = GovernmentFormData(
            contacts: ocrData.travelerInfo?.name != nil ? [
                ContactInfo(
                    name: ocrData.travelerInfo?.name?.processedText ?? "",
                    organization: ocrData.travelerInfo?.organization?.processedText,
                    role: .other
                ),
            ] : []
        )

        return FormAutoPopulationResult(
            extractedData: extractedData,
            suggestedFormType: .dd1155,
            confidence: overallConfidence,
            populatedFields: populatedFields,
            processingTime: Date().timeIntervalSince(startTime),
            warnings: warnings
        )
    }

    // MARK: - Government Form Validation

    /// Validates government form field accuracy against expected patterns
    static func validateGovernmentFormAccuracy(
        formType: FormType,
        populatedFields: [ExtractedPopulatedField]
    ) async throws -> GovernmentFormValidationResult {
        var accuracyResults: [FieldAccuracyResult] = []
        var overallAccuracy = 0.0
        var criticalFieldsAccuracy = 0.0

        let criticalFields = getCriticalFieldsForForm(formType)
        let requiredFields = getRequiredFieldsForForm(formType)

        for field in populatedFields {
            let isCritical = criticalFields.contains(field.fieldName)
            let isRequired = requiredFields.contains(field.fieldName)

            var accuracy = field.confidence

            // Apply field-specific validation
            switch field.fieldType {
            case .text where field.fieldName.contains("CAGE"):
                let isValidFormat = field.extractedValue.range(of: ValidationPatterns.cageCode, options: .regularExpression) != nil
                accuracy = isValidFormat ? accuracy : accuracy * 0.5

            case .currency:
                let isValidFormat = field.extractedValue.range(of: ValidationPatterns.currency, options: .regularExpression) != nil
                accuracy = isValidFormat ? accuracy : accuracy * 0.6

            case .date:
                let isValidFormat = field.extractedValue.range(of: ValidationPatterns.date, options: .regularExpression) != nil
                accuracy = isValidFormat ? accuracy : accuracy * 0.7

            default:
                break
            }

            // Boost accuracy for high-confidence fields
            if field.confidence >= 0.9 {
                accuracy = min(1.0, accuracy * 1.05)
            }

            accuracyResults.append(
                FieldAccuracyResult(
                    fieldName: field.fieldName,
                    accuracy: accuracy,
                    confidence: field.confidence,
                    isCritical: isCritical,
                    isRequired: isRequired,
                    validationStatus: accuracy >= 0.85 ? .passed : (accuracy >= 0.65 ? .warning : .failed)
                )
            )
        }

        // Calculate overall accuracy
        if !accuracyResults.isEmpty {
            overallAccuracy = accuracyResults.map(\.accuracy).reduce(0, +) / Double(accuracyResults.count)
        }

        // Calculate critical fields accuracy
        let criticalResults = accuracyResults.filter(\.isCritical)
        if !criticalResults.isEmpty {
            criticalFieldsAccuracy = criticalResults.map(\.accuracy).reduce(0, +) / Double(criticalResults.count)
        }

        let meetsAccuracyTarget = overallAccuracy >= 0.95 // 95% accuracy target from TDD rubric
        let meetsCriticalTarget = criticalFieldsAccuracy >= 0.85 // 85% accuracy for medium confidence from TDD rubric

        return GovernmentFormValidationResult(
            formType: formType,
            overallAccuracy: overallAccuracy,
            criticalFieldsAccuracy: criticalFieldsAccuracy,
            fieldResults: accuracyResults,
            meetsAccuracyTarget: meetsAccuracyTarget,
            meetsCriticalFieldTarget: meetsCriticalTarget,
            validationTimestamp: Date()
        )
    }

    // MARK: - Form Detection

    /// Detects form type from OCR data with confidence scoring
    static func detectFormTypeFromOCR(_ document: ScannedDocument) async throws -> DetectedFormType {
        // This is a minimal implementation - would use sophisticated pattern matching in live version
        var indicators: [FormIndicator] = []
        var bestMatch: FormType = .custom
        var bestConfidence = 0.0

        // Search for form indicators in OCR text
        for page in document.pages {
            if let ocrText = page.ocrResult?.fullText.lowercased() {
                // Check for SF-1449 indicators
                if ocrText.contains("solicitation"), ocrText.contains("contract") {
                    indicators.append(FormIndicator(type: .title, value: "SOLICITATION/CONTRACT", weight: 0.8))
                    if ocrText.contains("sf 1449") || ocrText.contains("sf1449") {
                        indicators.append(FormIndicator(type: .formNumber, value: "SF 1449", weight: 0.95))
                        bestMatch = .sf1449
                        bestConfidence = 0.9
                    }
                }

                // Check for SF-30 indicators
                if ocrText.contains("amendment"), ocrText.contains("modification") {
                    indicators.append(FormIndicator(type: .title, value: "AMENDMENT/MODIFICATION", weight: 0.8))
                    if ocrText.contains("sf 30") || ocrText.contains("sf30") {
                        indicators.append(FormIndicator(type: .formNumber, value: "SF 30", weight: 0.95))
                        bestMatch = .sf30
                        bestConfidence = 0.88
                    }
                }

                // Check for DD-1155 indicators
                if ocrText.contains("tdy"), ocrText.contains("travel") {
                    indicators.append(FormIndicator(type: .title, value: "TDY TRAVEL", weight: 0.75))
                    if ocrText.contains("dd 1155") || ocrText.contains("dd1155") {
                        indicators.append(FormIndicator(type: .formNumber, value: "DD 1155", weight: 0.95))
                        bestMatch = .dd1155
                        bestConfidence = 0.87
                    }
                }
            }
        }

        // Adjust confidence based on number of indicators
        let indicatorBonus = min(0.1, Double(indicators.count) * 0.02)
        bestConfidence = min(1.0, bestConfidence + indicatorBonus)

        return DetectedFormType(
            formType: bestMatch.rawValue,
            confidence: bestConfidence,
            indicators: indicators
        )
    }

    // MARK: - Helper Methods

    private static func getCriticalFieldsForForm(_ formType: FormType) -> Set<String> {
        switch formType {
        case .sf1449:
            ["CAGE Code", "Total Amount", "Vendor Name", "Solicitation Number"]
        case .sf30:
            ["CAGE Code", "Contract Number", "Amendment Number", "Price Changes"]
        case .dd1155:
            ["Total Estimate", "Traveler Name", "Travel Purpose"]
        default:
            []
        }
    }

    private static func getRequiredFieldsForForm(_ formType: FormType) -> Set<String> {
        switch formType {
        case .sf1449:
            ["Vendor Name", "Solicitation Number"]
        case .sf30:
            ["Contract Number", "Amendment Number"]
        case .dd1155:
            ["Traveler Name", "Request Number"]
        default:
            []
        }
    }
}

// MARK: - Government Form Validation Result

/// Result of government form validation with accuracy metrics
public struct GovernmentFormValidationResult: Equatable, Sendable {
    public let formType: FormType
    public let overallAccuracy: Double
    public let criticalFieldsAccuracy: Double
    public let fieldResults: [FieldAccuracyResult]
    public let meetsAccuracyTarget: Bool // ≥95% for high-confidence extractions
    public let meetsCriticalFieldTarget: Bool // ≥85% for medium-confidence extractions
    public let validationTimestamp: Date

    public init(
        formType: FormType,
        overallAccuracy: Double,
        criticalFieldsAccuracy: Double,
        fieldResults: [FieldAccuracyResult],
        meetsAccuracyTarget: Bool,
        meetsCriticalFieldTarget: Bool,
        validationTimestamp: Date
    ) {
        self.formType = formType
        self.overallAccuracy = overallAccuracy
        self.criticalFieldsAccuracy = criticalFieldsAccuracy
        self.fieldResults = fieldResults
        self.meetsAccuracyTarget = meetsAccuracyTarget
        self.meetsCriticalFieldTarget = meetsCriticalFieldTarget
        self.validationTimestamp = validationTimestamp
    }

    /// Returns true if all accuracy targets are met (TDD rubric compliance)
    public var meetsAllTargets: Bool {
        meetsAccuracyTarget && meetsCriticalFieldTarget
    }

    /// Returns fields that failed validation
    public var failedFields: [FieldAccuracyResult] {
        fieldResults.filter { $0.validationStatus == .failed }
    }

    /// Returns fields that need review
    public var warningFields: [FieldAccuracyResult] {
        fieldResults.filter { $0.validationStatus == .warning }
    }
}

/// Accuracy result for individual fields
public struct FieldAccuracyResult: Equatable, Sendable {
    public let fieldName: String
    public let accuracy: Double
    public let confidence: Double
    public let isCritical: Bool
    public let isRequired: Bool
    public let validationStatus: ValidationStatus

    public init(
        fieldName: String,
        accuracy: Double,
        confidence: Double,
        isCritical: Bool,
        isRequired: Bool,
        validationStatus: ValidationStatus
    ) {
        self.fieldName = fieldName
        self.accuracy = accuracy
        self.confidence = confidence
        self.isCritical = isCritical
        self.isRequired = isRequired
        self.validationStatus = validationStatus
    }

    public enum ValidationStatus: String, CaseIterable, Sendable {
        case passed
        case warning
        case failed
    }
}

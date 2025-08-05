import Foundation

// Type disambiguation: use the comprehensive FormField from Models (not DocumentScannerClient)

/// Error types for form mapping operations
public enum FormMappingError: Error, Sendable {
    case unsupportedFormType(FormType)
    case invalidOCRData(String)
    case fieldExtractionFailed(String)
}

/// Maps OCR text to government form fields using pattern recognition
public struct GovernmentFormMapper: Sendable {
    private let sf30Mapper: SF30FormMapper
    private let sf1449Mapper: SF1449FormMapper
    private let dd1155Mapper: DD1155FormMapper
    private let sf18Mapper: SF18FormMapper
    private let sf26Mapper: SF26FormMapper
    private let sf33Mapper: SF33FormMapper
    private let sf44Mapper: SF44FormMapper
    private let sf1408Mapper: SF1408FormMapper
    private let sf1442Mapper: SF1442FormMapper
    private let customMapper: CustomFormMapper
    private let fieldValidator: FieldValidator

    public init(fieldValidator: FieldValidator = FieldValidator()) {
        sf30Mapper = SF30FormMapper()
        sf1449Mapper = SF1449FormMapper()
        dd1155Mapper = DD1155FormMapper()
        sf18Mapper = SF18FormMapper()
        sf26Mapper = SF26FormMapper()
        sf33Mapper = SF33FormMapper()
        sf44Mapper = SF44FormMapper()
        sf1408Mapper = SF1408FormMapper()
        sf1442Mapper = SF1442FormMapper()
        customMapper = CustomFormMapper()
        self.fieldValidator = fieldValidator
    }

    /// Map OCR result to form fields based on form type
    public func mapFields(
        from ocrResult: DocumentImageProcessor.OCRResult,
        formType: FormType
    ) async throws -> [FormField] {
        switch formType {
        case .sf30:
            try await sf30Mapper.mapFields(from: ocrResult)
        case .sf1449:
            try await sf1449Mapper.mapFields(from: ocrResult)
        case .dd1155:
            try await dd1155Mapper.mapFields(from: ocrResult)
        case .sf18:
            try await sf18Mapper.mapFields(from: ocrResult)
        case .sf26:
            try await sf26Mapper.mapFields(from: ocrResult)
        case .sf33:
            try await sf33Mapper.mapFields(from: ocrResult)
        case .sf44:
            try await sf44Mapper.mapFields(from: ocrResult)
        case .sf1408:
            try await sf1408Mapper.mapFields(from: ocrResult)
        case .sf1442:
            try await sf1442Mapper.mapFields(from: ocrResult)
        case .custom:
            try await customMapper.mapFields(from: ocrResult)
        }
    }

    /// Validate field format based on field type
    public func validateField(_ field: FormField) -> FieldValidationResult {
        switch field.fieldType {
        case .cageCode:
            fieldValidator.validateCAGECode(field.value)
        case .uei:
            fieldValidator.validateUEI(field.value)
        case .currency:
            fieldValidator.validateCurrency(field.value)
        case .date:
            fieldValidator.validateDate(field.value)
        default:
            FieldValidationResult(isValid: true, errors: [])
        }
    }
}

// MARK: - Pattern Extraction Helpers

extension GovernmentFormMapper {
    /// Extract field value using regex pattern and cleanup rules
    func extractFieldValue(
        from text: String,
        pattern: String,
        removePatterns: [String] = [],
        options: NSString.CompareOptions = [.regularExpression, .caseInsensitive]
    ) -> String? {
        guard let match = text.range(of: pattern, options: options) else { return nil }

        var value = String(text[match])
        for removePattern in removePatterns {
            value = value.replacingOccurrences(of: removePattern, with: "", options: .caseInsensitive)
        }
        return value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":")))
    }

    /// Create field with common properties
    func createField(
        name: String,
        value: String,
        confidence: Double,
        fieldType: FieldType,
        isCritical: Bool = true
    ) -> FormField {
        FormField(
            name: name,
            value: value,
            confidence: ConfidenceScore(value: confidence),
            fieldType: fieldType,
            isCritical: isCritical
        )
    }
}

/// SF-30 specific form mapping
struct SF30FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Contract number extraction
        if let contractNumber = mapper.extractFieldValue(
            from: text,
            pattern: "CONTRACT NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["CONTRACT NO.", "CONTRACT NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "contractNumber",
                value: contractNumber,
                confidence: 0.8,
                fieldType: .text
            ))
        }

        // Estimated value extraction
        if let estimatedValue = mapper.extractFieldValue(
            from: text,
            pattern: "\\$([0-9,]+(?:\\.[0-9]{2})?)",
            removePatterns: ["$"]
        ) {
            mappedFields.append(mapper.createField(
                name: "estimatedValue",
                value: estimatedValue,
                confidence: 0.75,
                fieldType: .currency
            ))
        }

        // CAGE code extraction
        if let cageCode = mapper.extractFieldValue(
            from: text,
            pattern: "CAGE\\s*:?\\s*([A-Z0-9]{5})",
            removePatterns: ["CAGE"]
        ) {
            mappedFields.append(mapper.createField(
                name: "cageCode",
                value: cageCode,
                confidence: 0.85,
                fieldType: .cageCode
            ))
        }

        return mappedFields
    }
}

/// SF-1449 specific form mapping
struct SF1449FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // UEI extraction
        if let uei = mapper.extractFieldValue(
            from: text,
            pattern: "UEI\\s*:?\\s*([A-Z0-9]{12})",
            removePatterns: ["UEI"]
        ) {
            mappedFields.append(mapper.createField(
                name: "uei",
                value: uei,
                confidence: 0.9,
                fieldType: .uei
            ))
        }

        // Requisition number extraction
        if let requisitionNumber = mapper.extractFieldValue(
            from: text,
            pattern: "REQUISITION\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["REQUISITION NO.", "REQUISITION NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "requisitionNumber",
                value: requisitionNumber,
                confidence: 0.8,
                fieldType: .text
            ))
        }

        // Total amount extraction
        if let totalAmount = mapper.extractFieldValue(
            from: text,
            pattern: "TOTAL\\s*:?\\s*\\$([0-9,]+(?:\\.[0-9]{2})?)",
            removePatterns: ["TOTAL", "$"]
        ) {
            mappedFields.append(mapper.createField(
                name: "totalAmount",
                value: totalAmount,
                confidence: 0.85,
                fieldType: .currency
            ))
        }

        return mappedFields
    }
}

/// DD-1155 Purchase Request form mapping
struct DD1155FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Purchase request number extraction
        if let requestNumber = mapper.extractFieldValue(
            from: text,
            pattern: "REQUEST\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["REQUEST NO.", "REQUEST NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "requestNumber",
                value: requestNumber,
                confidence: 0.85,
                fieldType: .text
            ))
        }

        // Priority designation
        if let priority = mapper.extractFieldValue(
            from: text,
            pattern: "PRIORITY\\s*:?\\s*(\\d+)",
            removePatterns: ["PRIORITY"]
        ) {
            mappedFields.append(mapper.createField(
                name: "priority",
                value: priority,
                confidence: 0.8,
                fieldType: .text
            ))
        }

        return mappedFields
    }
}

/// SF-18 Request for Quotations form mapping
struct SF18FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // RFQ number extraction
        if let rfqNumber = mapper.extractFieldValue(
            from: text,
            pattern: "RFQ\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["RFQ NO.", "RFQ NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "rfqNumber",
                value: rfqNumber,
                confidence: 0.85,
                fieldType: .text
            ))
        }

        // Quotation due date
        if let dueDate = mapper.extractFieldValue(
            from: text,
            pattern: "DUE\\s*DATE\\s*:?\\s*(\\d{1,2}/\\d{1,2}/\\d{4})",
            removePatterns: ["DUE DATE"]
        ) {
            mappedFields.append(mapper.createField(
                name: "dueDate",
                value: dueDate,
                confidence: 0.8,
                fieldType: .date
            ))
        }

        return mappedFields
    }
}

/// SF-26 Award/Contract form mapping
struct SF26FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Award number extraction
        if let awardNumber = mapper.extractFieldValue(
            from: text,
            pattern: "AWARD\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["AWARD NO.", "AWARD NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "awardNumber",
                value: awardNumber,
                confidence: 0.9,
                fieldType: .text
            ))
        }

        // Contract amount
        if let contractAmount = mapper.extractFieldValue(
            from: text,
            pattern: "AMOUNT\\s*:?\\s*\\$([0-9,]+(?:\\.[0-9]{2})?)",
            removePatterns: ["AMOUNT", "$"]
        ) {
            mappedFields.append(mapper.createField(
                name: "contractAmount",
                value: contractAmount,
                confidence: 0.85,
                fieldType: .currency
            ))
        }

        return mappedFields
    }
}

/// SF-33 Solicitation, Offer and Award form mapping
struct SF33FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Solicitation number
        if let solicitationNumber = mapper.extractFieldValue(
            from: text,
            pattern: "SOLICITATION\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["SOLICITATION NO.", "SOLICITATION NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "solicitationNumber",
                value: solicitationNumber,
                confidence: 0.9,
                fieldType: .text
            ))
        }

        // Offer amount
        if let offerAmount = mapper.extractFieldValue(
            from: text,
            pattern: "OFFER\\s*AMOUNT\\s*:?\\s*\\$([0-9,]+(?:\\.[0-9]{2})?)",
            removePatterns: ["OFFER AMOUNT", "$"]
        ) {
            mappedFields.append(mapper.createField(
                name: "offerAmount",
                value: offerAmount,
                confidence: 0.85,
                fieldType: .currency
            ))
        }

        return mappedFields
    }
}

/// SF-44 Purchase Order-Invoice-Voucher form mapping
struct SF44FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Purchase order number
        if let poNumber = mapper.extractFieldValue(
            from: text,
            pattern: "PO\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["PO NO.", "PO NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "purchaseOrderNumber",
                value: poNumber,
                confidence: 0.85,
                fieldType: .text
            ))
        }

        // Invoice number
        if let invoiceNumber = mapper.extractFieldValue(
            from: text,
            pattern: "INVOICE\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["INVOICE NO.", "INVOICE NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "invoiceNumber",
                value: invoiceNumber,
                confidence: 0.8,
                fieldType: .text
            ))
        }

        return mappedFields
    }
}

/// SF-1408 Pre-Award Survey of Prospective Contractor form mapping
struct SF1408FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Survey case number
        if let caseNumber = mapper.extractFieldValue(
            from: text,
            pattern: "CASE\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["CASE NO.", "CASE NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "surveyCaseNumber",
                value: caseNumber,
                confidence: 0.85,
                fieldType: .text
            ))
        }

        // Contractor name
        if let contractorName = mapper.extractFieldValue(
            from: text,
            pattern: "CONTRACTOR\\s*:?\\s*([A-Z\\s&,.-]+)",
            removePatterns: ["CONTRACTOR"]
        ) {
            mappedFields.append(mapper.createField(
                name: "contractorName",
                value: contractorName,
                confidence: 0.8,
                fieldType: .text
            ))
        }

        return mappedFields
    }
}

/// SF-1442 Request and Authorization for TDY Travel form mapping
struct SF1442FormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Travel authorization number
        if let authNumber = mapper.extractFieldValue(
            from: text,
            pattern: "AUTH\\s*NO\\.?\\s*([A-Z0-9-]+)",
            removePatterns: ["AUTH NO.", "AUTH NO"]
        ) {
            mappedFields.append(mapper.createField(
                name: "travelAuthNumber",
                value: authNumber,
                confidence: 0.85,
                fieldType: .text
            ))
        }

        // Travel dates
        if let travelDates = mapper.extractFieldValue(
            from: text,
            pattern: "TRAVEL\\s*DATES\\s*:?\\s*(\\d{1,2}/\\d{1,2}/\\d{4}\\s*-\\s*\\d{1,2}/\\d{1,2}/\\d{4})",
            removePatterns: ["TRAVEL DATES"]
        ) {
            mappedFields.append(mapper.createField(
                name: "travelDates",
                value: travelDates,
                confidence: 0.8,
                fieldType: .date
            ))
        }

        return mappedFields
    }
}

/// Generic custom form mapping with adaptive pattern recognition
struct CustomFormMapper: Sendable {
    func mapFields(from ocrResult: DocumentImageProcessor.OCRResult) async throws -> [FormField] {
        let mapper = GovernmentFormMapper()
        let text = ocrResult.fullText
        var mappedFields: [FormField] = []

        // Generic patterns for common government form fields
        let patterns: [(name: String, pattern: String, removePatterns: [String], fieldType: FieldType)] = [
            ("referenceNumber", "REF\\s*NO\\.?\\s*([A-Z0-9-]+)", ["REF NO.", "REF NO"], .text),
            ("documentNumber", "DOC\\s*NO\\.?\\s*([A-Z0-9-]+)", ["DOC NO.", "DOC NO"], .text),
            ("amount", "\\$([0-9,]+(?:\\.[0-9]{2})?)", ["$"], .currency),
            ("date", "(\\d{1,2}/\\d{1,2}/\\d{4})", [], .date),
            ("cageCode", "CAGE\\s*:?\\s*([A-Z0-9]{5})", ["CAGE"], .cageCode),
            ("uei", "UEI\\s*:?\\s*([A-Z0-9]{12})", ["UEI"], .uei),
        ]

        for (name, pattern, removePatterns, fieldType) in patterns {
            if let value = mapper.extractFieldValue(
                from: text,
                pattern: pattern,
                removePatterns: removePatterns
            ) {
                mappedFields.append(mapper.createField(
                    name: name,
                    value: value,
                    confidence: 0.7, // Lower confidence for generic patterns
                    fieldType: fieldType
                ))
            }
        }

        return mappedFields
    }
}

/// Field validation result
public struct FieldValidationResult: Equatable, Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let confidence: Double

    public init(isValid: Bool, errors: [String] = [], confidence: Double = 1.0) {
        self.isValid = isValid
        self.errors = errors
        self.confidence = confidence
    }
}

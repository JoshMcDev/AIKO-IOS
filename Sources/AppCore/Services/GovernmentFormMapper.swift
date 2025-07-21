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
    private let fieldValidator: FieldValidator

    public init(fieldValidator: FieldValidator = FieldValidator()) {
        sf30Mapper = SF30FormMapper()
        sf1449Mapper = SF1449FormMapper()
        self.fieldValidator = fieldValidator
    }

    /// Map OCR result to form fields based on form type
    public func mapFields(
        from ocrResult: DocumentImageProcessor.OCRResult,
        formType: FormType
    ) async throws -> [FormField] {
        switch formType {
        case .sf30:
            return try await sf30Mapper.mapFields(from: ocrResult)
        case .sf1449:
            return try await sf1449Mapper.mapFields(from: ocrResult)
        case .dd1155, .sf18, .sf26, .sf33, .sf44, .sf1408, .sf1442, .custom:
            // TODO: Implement mappers for additional form types
            throw FormMappingError.unsupportedFormType(formType)
        }
    }

    /// Validate field format based on field type
    public func validateField(_ field: FormField) -> FieldValidationResult {
        switch field.fieldType {
        case .cageCode:
            return fieldValidator.validateCAGECode(field.value)
        case .uei:
            return fieldValidator.validateUEI(field.value)
        case .currency:
            return fieldValidator.validateCurrency(field.value)
        case .date:
            return fieldValidator.validateDate(field.value)
        default:
            return FieldValidationResult(isValid: true, errors: [])
        }
    }
}

// MARK: - Pattern Extraction Helpers

extension GovernmentFormMapper {
    /// Extract field value using regex pattern and cleanup rules
    internal func extractFieldValue(
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
    internal func createField(
        name: String,
        value: String,
        confidence: Double,
        fieldType: FieldType,
        isCritical: Bool = true
    ) -> FormField {
        return FormField(
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

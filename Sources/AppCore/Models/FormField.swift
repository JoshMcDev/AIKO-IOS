import CoreGraphics
import Foundation

/// Represents a form field extracted from a document
public struct FormField: Equatable, Sendable {
    public let name: String
    public let value: String
    public let confidence: ConfidenceScore
    public let fieldType: FieldType
    public let boundingBox: CGRect?
    public let isCritical: Bool
    public let requiresManualReview: Bool

    public init(
        name: String,
        value: String,
        confidence: ConfidenceScore,
        fieldType: FieldType,
        boundingBox: CGRect? = nil,
        isCritical: Bool = false,
        requiresManualReview: Bool = false
    ) {
        self.name = name
        self.value = value
        self.confidence = confidence
        self.fieldType = fieldType
        self.boundingBox = boundingBox
        self.isCritical = isCritical
        self.requiresManualReview = requiresManualReview
    }

    // GREEN phase - basic implementation to pass accuracy tests
    public var isAccurate: Bool {
        // Simple heuristic: high confidence fields are considered accurate
        return confidence.value >= 0.8
    }

    public var isValidFormField: Bool {
        // GREEN phase - basic validation for form fields
        return !name.isEmpty && !value.isEmpty && confidence.value > 0.0
    }
}

/// Types of form fields
public enum FieldType: String, CaseIterable, Equatable, Sendable {
    case text
    case number
    case currency
    case date
    case cageCode
    case uei
    case contractType
    case fundingSource
    case estimatedValue
}

// FormType moved to Dependencies/FormAutoPopulationEngine.swift to avoid duplication

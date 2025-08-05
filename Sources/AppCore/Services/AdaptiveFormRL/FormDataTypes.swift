import Foundation

/// Form data structure for adaptive form population
public struct FormData: Sendable {
    public let fields: [FormField]

    public init(fields: [FormField]) {
        self.fields = fields
    }

    /// Get field by name
    public func field(named name: String) -> FormField? {
        fields.first { $0.name == name }
    }

    /// Get all field names
    public var fieldNames: [String] {
        fields.map(\.name)
    }

    /// Check if form has field with given name
    public func hasField(named name: String) -> Bool {
        fields.contains { $0.name == name }
    }

    /// Update field value
    public func updatingField(named name: String, with value: String) -> FormData {
        let updatedFields = fields.map { field -> FormField in
            if field.name == name {
                return FormField(
                    name: field.name,
                    value: value,
                    confidence: field.confidence,
                    fieldType: field.fieldType,
                    boundingBox: field.boundingBox,
                    isCritical: field.isCritical,
                    requiresManualReview: field.requiresManualReview
                )
            }
            return field
        }
        return FormData(fields: updatedFields)
    }
}

/// Field prediction result from Q-learning agent
public struct FieldPrediction: Sendable {
    public let fieldId: String
    public let suggestedValue: String
    public let confidence: Double
    public let reasoning: String

    public init(fieldId: String, suggestedValue: String, confidence: Double, reasoning: String) {
        self.fieldId = fieldId
        self.suggestedValue = suggestedValue
        self.confidence = confidence
        self.reasoning = reasoning
    }
}

/// Field modification tracking
public struct FieldModification: Sendable {
    public let fieldId: String
    public let originalValue: String
    public let modifiedValue: String
    public let timestamp: Date
    public let userId: String?

    public init(fieldId: String, originalValue: String, modifiedValue: String, timestamp: Date = Date(), userId: String? = nil) {
        self.fieldId = fieldId
        self.originalValue = originalValue
        self.modifiedValue = modifiedValue
        self.timestamp = timestamp
        self.userId = userId
    }
}

/// Adaptive form population result
public struct AdaptiveFormResult: Sendable {
    public let formData: FormData
    public let predictions: [FieldPrediction]
    public let confidence: Double
    public let explanations: [FieldExplanation]
    public let source: PopulationSource
    public let error: Error?

    public init(
        formData: FormData,
        predictions: [FieldPrediction],
        confidence: Double,
        explanations: [FieldExplanation],
        source: PopulationSource,
        error: Error? = nil
    ) {
        self.formData = formData
        self.predictions = predictions
        self.confidence = confidence
        self.explanations = explanations
        self.source = source
        self.error = error
    }
}

/// Population source for adaptive forms
public enum PopulationSource: Sendable {
    case adaptive
    case staticFallback
}

/// Field explanation for user understanding
public struct FieldExplanation: Sendable {
    public let fieldId: String
    public let explanation: String
    public let confidence: Double

    public init(fieldId: String, explanation: String, confidence: Double) {
        self.fieldId = fieldId
        self.explanation = explanation
        self.confidence = confidence
    }
}

/// Decision response for reward calculation
public struct DecisionResponse: Sendable {
    public let selectedAction: RLAction
    public let confidence: Double
    public let timestamp: Date

    public init(selectedAction: RLAction, confidence: Double, timestamp: Date = Date()) {
        self.selectedAction = selectedAction
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

/// RL Action for reinforcement learning
public struct RLAction: Sendable {
    public let value: String
    public let actionType: ActionType
    public let complianceChecks: [String]

    public init(value: String, actionType: ActionType, complianceChecks: [String] = []) {
        self.value = value
        self.actionType = actionType
        self.complianceChecks = complianceChecks
    }
}

/// Action type for RL actions
public enum ActionType: String, CaseIterable, Sendable {
    case fieldPopulation = "field_population"
    case contextualSuggestion = "contextual_suggestion"
    case complianceCheck = "compliance_check"
}

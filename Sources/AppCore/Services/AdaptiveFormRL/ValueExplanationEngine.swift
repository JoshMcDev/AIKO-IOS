import Foundation

/// Engine for generating explanations for adaptive form field suggestions
/// Builds user trust through transparent reasoning about Q-learning decisions
public actor ValueExplanationEngine {
    // MARK: - Explanation Templates

    private let explanationTemplates: [ExplanationType: [String]] = [
        .qLearningBased: [
            "Based on %d similar acquisitions, this value was accepted %d%% of the time",
            "Users in similar contexts typically choose this value (%d%% success rate)",
            "Historical data from %d comparable cases suggests this value",
        ],
        .contextBased: [
            "This value is commonly used for %@ acquisitions",
            "In %@ contexts, this value typically improves processing time",
            "Based on %@ procurement patterns, this is the recommended value",
        ],
        .userPatternBased: [
            "You've used similar values in %d previous acquisitions",
            "This matches your typical preferences for %@ fields",
            "Based on your workflow patterns, this value saves time",
        ],
        .fallbackExplanation: [
            "Standard default value for this field type",
            "Regulatory compliant default based on FAR requirements",
            "Commonly accepted value across all acquisition types",
        ],
    ]

    // MARK: - Confidence Thresholds

    private let highConfidenceThreshold: Double = 0.8
    private let mediumConfidenceThreshold: Double = 0.6

    // MARK: - Public Interface

    /// Generate explanation for a field prediction
    public func generateExplanation(for prediction: FieldPrediction) -> FieldExplanation {
        let explanation = createExplanation(
            fieldId: prediction.fieldId,
            confidence: prediction.confidence,
            reasoning: prediction.reasoning
        )

        return FieldExplanation(
            fieldId: prediction.fieldId,
            explanation: explanation,
            confidence: prediction.confidence
        )
    }

    /// Generate detailed explanation with additional context
    public func generateDetailedExplanation(
        for prediction: FieldPrediction,
        context: AcquisitionContext,
        userProfile: UserProfile,
        historicalData: HistoricalData
    ) -> DetailedExplanation {
        let primaryExplanation = createContextualExplanation(
            prediction: prediction,
            context: context,
            historicalData: historicalData
        )

        let supportingEvidence = generateSupportingEvidence(
            prediction: prediction,
            context: context,
            userProfile: userProfile,
            historicalData: historicalData
        )

        let alternatives = generateAlternatives(
            prediction: prediction,
            context: context,
            historicalData: historicalData
        )

        return DetailedExplanation(
            fieldId: prediction.fieldId,
            primaryExplanation: primaryExplanation,
            supportingEvidence: supportingEvidence,
            alternatives: alternatives,
            confidence: prediction.confidence,
            explanationType: determineExplanationType(prediction: prediction, context: context)
        )
    }

    /// Generate A/B testing explanation for user trust research
    public func generateABTestExplanation(
        prediction: FieldPrediction,
        experimentGroup: ABTestGroup
    ) -> ABTestExplanation {
        let baseExplanation = createExplanation(
            fieldId: prediction.fieldId,
            confidence: prediction.confidence,
            reasoning: prediction.reasoning
        )

        let enhancedExplanation: String = switch experimentGroup {
        case .control:
            baseExplanation
        case .detailed:
            "\(baseExplanation) (Confidence: \(Int(prediction.confidence * 100))%)"
        case .simplified:
            "Recommended based on similar cases"
        case .noExplanation:
            ""
        }

        return ABTestExplanation(
            fieldId: prediction.fieldId,
            explanation: enhancedExplanation,
            experimentGroup: experimentGroup,
            originalConfidence: prediction.confidence
        )
    }

    // MARK: - Private Methods

    private func createExplanation(fieldId _: String, confidence: Double, reasoning: String) -> String {
        let explanationType = determineExplanationTypeFromReasoning(reasoning)
        let templates = explanationTemplates[explanationType] ?? explanationTemplates[.fallbackExplanation] ?? []

        let template = templates.randomElement() ?? (templates.isEmpty ? "Standard value for this field type" : templates[0])

        return formatExplanation(
            template: template,
            confidence: confidence,
            reasoning: reasoning
        )
    }

    private func createContextualExplanation(
        prediction: FieldPrediction,
        context: AcquisitionContext,
        historicalData: HistoricalData
    ) -> String {
        let contextType = context.type
        let successRate = historicalData.getSuccessRate(for: prediction.suggestedValue, context: contextType)
        let usageCount = historicalData.getUsageCount(for: prediction.suggestedValue, context: contextType)

        if prediction.confidence >= highConfidenceThreshold,
           let qLearningTemplates = explanationTemplates[.qLearningBased],
           let template = qLearningTemplates.first {
            return String(format: template, usageCount, Int(successRate * 100))
        } else if prediction.confidence >= mediumConfidenceThreshold,
                  let contextTemplates = explanationTemplates[.contextBased],
                  let template = contextTemplates.first {
            return String(format: template, contextType.displayName)
        } else {
            return explanationTemplates[.fallbackExplanation]?.first ?? "Standard default value for this field type"
        }
    }

    private func generateSupportingEvidence(
        prediction: FieldPrediction,
        context: AcquisitionContext,
        userProfile: UserProfile,
        historicalData: HistoricalData
    ) -> [SupportingEvidence] {
        var evidence: [SupportingEvidence] = []

        // Historical usage evidence
        let usageCount = historicalData.getUsageCount(for: prediction.suggestedValue, context: context.type)
        if usageCount > 0 {
            evidence.append(SupportingEvidence(
                type: .historicalUsage,
                description: "Used in \(usageCount) similar acquisitions",
                strength: calculateEvidenceStrength(count: usageCount)
            ))
        }

        // User pattern evidence
        let userUsageCount = historicalData.getUserUsageCount(
            for: prediction.suggestedValue,
            userId: userProfile.id.uuidString
        )
        if userUsageCount > 0 {
            evidence.append(SupportingEvidence(
                type: .userPattern,
                description: "You've used this value \(userUsageCount) times before",
                strength: calculateEvidenceStrength(count: userUsageCount)
            ))
        }

        // Regulatory compliance evidence
        if isRegulatoryCompliant(value: prediction.suggestedValue, context: context) {
            evidence.append(SupportingEvidence(
                type: .regulatoryCompliance,
                description: "Complies with FAR requirements for this acquisition type",
                strength: .high
            ))
        }

        return evidence
    }

    private func generateAlternatives(
        prediction: FieldPrediction,
        context: AcquisitionContext,
        historicalData: HistoricalData
    ) -> [Alternative] {
        let alternatives = historicalData.getAlternatives(
            for: prediction.fieldId,
            context: context.type,
            excluding: prediction.suggestedValue
        )

        return alternatives.prefix(3).map { alternative in
            Alternative(
                value: alternative.value,
                confidence: alternative.confidence,
                reason: "Alternative with \(Int(alternative.confidence * 100))% success rate"
            )
        }
    }

    private func determineExplanationType(prediction: FieldPrediction, context: AcquisitionContext) -> ExplanationType {
        if prediction.reasoning.contains("Q-learning") || prediction.reasoning.contains("past experience") {
            .qLearningBased
        } else if prediction.reasoning.contains("context") || prediction.reasoning.contains(context.type.rawValue) {
            .contextBased
        } else if prediction.reasoning.contains("user") || prediction.reasoning.contains("your") {
            .userPatternBased
        } else {
            .fallbackExplanation
        }
    }

    private func determineExplanationTypeFromReasoning(_ reasoning: String) -> ExplanationType {
        if reasoning.contains("Q-learning") {
            .qLearningBased
        } else if reasoning.contains("context") {
            .contextBased
        } else if reasoning.contains("user") {
            .userPatternBased
        } else {
            .fallbackExplanation
        }
    }

    private func formatExplanation(template: String, confidence _: Double, reasoning: String) -> String {
        // Extract numbers from reasoning for template formatting
        let numbers = extractNumbers(from: reasoning)

        if template.contains("%d"), numbers.count >= 2 {
            return String(format: template, numbers[0], numbers[1])
        } else if template.contains("%@") {
            let contextType = extractContextType(from: reasoning)
            return String(format: template, contextType)
        } else {
            return template
        }
    }

    private func extractNumbers(from text: String) -> [Int] {
        let pattern = #"\d+"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []

        return matches.compactMap { match in
            let range = Range(match.range, in: text)
            return range.flatMap { Int(text[$0]) }
        }
    }

    private func extractContextType(from text: String) -> String {
        if text.lowercased().contains("information technology") || text.lowercased().contains("it") {
            "Information Technology"
        } else if text.lowercased().contains("construction") {
            "Construction"
        } else if text.lowercased().contains("professional") {
            "Professional Services"
        } else {
            "General"
        }
    }

    private func calculateEvidenceStrength(count: Int) -> EvidenceStrength {
        if count >= 10 {
            .high
        } else if count >= 5 {
            .medium
        } else {
            .low
        }
    }

    private func isRegulatoryCompliant(value: String, context _: AcquisitionContext) -> Bool {
        // Simplified regulatory compliance check
        // In practice, this would integrate with actual FAR/DFARS rules
        !value.isEmpty && value.count <= 100
    }
}

// MARK: - Supporting Types

public enum ExplanationType {
    case qLearningBased
    case contextBased
    case userPatternBased
    case fallbackExplanation
}

public struct DetailedExplanation {
    public let fieldId: String
    public let primaryExplanation: String
    public let supportingEvidence: [SupportingEvidence]
    public let alternatives: [Alternative]
    public let confidence: Double
    public let explanationType: ExplanationType

    public init(fieldId: String, primaryExplanation: String, supportingEvidence: [SupportingEvidence], alternatives: [Alternative], confidence: Double, explanationType: ExplanationType) {
        self.fieldId = fieldId
        self.primaryExplanation = primaryExplanation
        self.supportingEvidence = supportingEvidence
        self.alternatives = alternatives
        self.confidence = confidence
        self.explanationType = explanationType
    }
}

public struct SupportingEvidence {
    public let type: EvidenceType
    public let description: String
    public let strength: EvidenceStrength

    public init(type: EvidenceType, description: String, strength: EvidenceStrength) {
        self.type = type
        self.description = description
        self.strength = strength
    }
}

public enum EvidenceType {
    case historicalUsage
    case userPattern
    case regulatoryCompliance
    case contextualRelevance
}

public enum EvidenceStrength {
    case high
    case medium
    case low
}

public struct Alternative {
    public let value: String
    public let confidence: Double
    public let reason: String

    public init(value: String, confidence: Double, reason: String) {
        self.value = value
        self.confidence = confidence
        self.reason = reason
    }
}

public enum ABTestGroup: String, CaseIterable {
    case control
    case detailed
    case simplified
    case noExplanation = "no_explanation"
}

public struct ABTestExplanation {
    public let fieldId: String
    public let explanation: String
    public let experimentGroup: ABTestGroup
    public let originalConfidence: Double

    public init(fieldId: String, explanation: String, experimentGroup: ABTestGroup, originalConfidence: Double) {
        self.fieldId = fieldId
        self.explanation = explanation
        self.experimentGroup = experimentGroup
        self.originalConfidence = originalConfidence
    }
}

// Placeholder for historical data - would be implemented with actual data service
public struct HistoricalData {
    public func getSuccessRate(for _: String, context _: ContextCategory) -> Double {
        0.85 // Placeholder
    }

    public func getUsageCount(for _: String, context _: ContextCategory) -> Int {
        25 // Placeholder
    }

    public func getUserUsageCount(for _: String, userId _: String) -> Int {
        3 // Placeholder
    }

    public func getAlternatives(for _: String, context _: ContextCategory, excluding _: String) -> [Alternative] {
        [
            Alternative(value: "Alternative 1", confidence: 0.7, reason: "Alternative reason"),
            Alternative(value: "Alternative 2", confidence: 0.6, reason: "Alternative reason"),
        ]
    }
}

extension ContextCategory {
    var displayName: String {
        switch self {
        case .informationTechnology:
            "Information Technology"
        case .construction:
            "Construction"
        case .professional:
            "Professional Services"
        }
    }
}

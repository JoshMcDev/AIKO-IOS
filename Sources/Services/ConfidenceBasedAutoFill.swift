import Foundation
import SwiftUI

// MARK: - Confidence-Based Auto-Fill System

/// Manages automatic field population based on confidence thresholds
public final class ConfidenceBasedAutoFillEngine: @unchecked Sendable {
    // MARK: - Types

    public struct AutoFillConfiguration {
        /// Minimum confidence required to auto-fill without user confirmation
        public let autoFillThreshold: Float

        /// Minimum confidence required to suggest a value
        public let suggestionThreshold: Float

        /// Whether to auto-fill critical fields (like financial values)
        public let autoFillCriticalFields: Bool

        /// Maximum number of fields to auto-fill in one session
        public let maxAutoFillFields: Int

        /// Whether to learn from user corrections
        public let enableLearning: Bool

        /// Confidence boost when multiple sources agree
        public let consensusBoost: Float

        public init(
            autoFillThreshold: Float = 0.85,
            suggestionThreshold: Float = 0.65,
            autoFillCriticalFields: Bool = false,
            maxAutoFillFields: Int = 20,
            enableLearning: Bool = true,
            consensusBoost: Float = 0.1
        ) {
            self.autoFillThreshold = autoFillThreshold
            self.suggestionThreshold = suggestionThreshold
            self.autoFillCriticalFields = autoFillCriticalFields
            self.maxAutoFillFields = maxAutoFillFields
            self.enableLearning = enableLearning
            self.consensusBoost = consensusBoost
        }
    }

    public struct AutoFillDecision {
        public let field: RequirementField
        public let action: AutoFillAction
        public let value: Any
        public let confidence: Float
        public let reasoning: String
        public let sources: [String]

        public enum AutoFillAction {
            case autoFill // Automatically fill without asking
            case suggest // Show as suggestion but ask for confirmation
            case skip // Don't auto-fill, ask user
        }
    }

    public struct AutoFillResult: @unchecked Sendable {
        public let autoFilledFields: [RequirementField: Any]
        public let suggestedFields: [RequirementField: FieldSuggestion]
        public let skippedFields: [RequirementField]
        public let totalConfidence: Float
        public let summary: AutoFillSummary
    }

    public struct FieldSuggestion: @unchecked Sendable {
        public let value: Any
        public let confidence: Float
        public let reasoning: String
        public let alternatives: [Alternative]

        public struct Alternative: @unchecked Sendable {
            public let value: Any
            public let confidence: Float
            public let source: String
        }
    }

    public struct AutoFillSummary {
        public let totalFields: Int
        public let autoFilledCount: Int
        public let suggestedCount: Int
        public let skippedCount: Int
        public let averageConfidence: Float
        public let timeSaved: TimeInterval // Estimated time saved in seconds
        public let confidenceDistribution: ConfidenceDistribution
    }

    public struct ConfidenceDistribution {
        public let veryHigh: Int // >= 0.9
        public let high: Int // >= 0.8
        public let medium: Int // >= 0.65
        public let low: Int // < 0.65
    }

    // MARK: - Properties

    private let configuration: AutoFillConfiguration
    private let smartDefaultsEngine: SmartDefaultsEngine
    private let criticalFields: Set<RequirementField> = [
        .estimatedValue,
        .fundingSource,
        .contractType,
        .vendorUEI,
        .vendorCAGE
    ]

    private let queue = DispatchQueue(label: "com.aiko.autofill", attributes: .concurrent)

    // Metrics tracking
    private var _metrics: AutoFillMetrics = .init()
    private var metrics: AutoFillMetrics {
        get { queue.sync { _metrics } }
        set { queue.async(flags: .barrier) { self._metrics = newValue } }
    }

    // MARK: - Initialization

    public init(
        configuration: AutoFillConfiguration = AutoFillConfiguration(),
        smartDefaultsEngine: SmartDefaultsEngine
    ) {
        self.configuration = configuration
        self.smartDefaultsEngine = smartDefaultsEngine
    }

    // MARK: - Public Methods

    /// Analyze fields and determine which can be auto-filled
    public func analyzeFieldsForAutoFill(
        fields: [RequirementField],
        context: SmartDefaultContext
    ) async -> AutoFillResult {
        let startTime = Date()

        // Get smart defaults for all fields
        let defaults = await smartDefaultsEngine.getSmartDefaults(for: fields, context: context)

        // Make auto-fill decisions
        var decisions: [AutoFillDecision] = []
        for field in fields {
            if let defaultValue = defaults[field] {
                let decision = makeAutoFillDecision(
                    field: field,
                    defaultValue: defaultValue,
                    context: context
                )
                decisions.append(decision)
            } else {
                decisions.append(AutoFillDecision(
                    field: field,
                    action: .skip,
                    value: "",
                    confidence: 0,
                    reasoning: "No default value available",
                    sources: []
                ))
            }
        }

        // Apply auto-fill limits
        let limitedDecisions = applyAutoFillLimits(decisions)

        // Build result
        let result = buildAutoFillResult(from: limitedDecisions, startTime: startTime)

        // Update metrics
        updateMetrics(with: result)

        return result
    }

    /// Process user feedback on auto-filled values
    public func processUserFeedback(
        field: RequirementField,
        autoFilledValue: Any,
        userValue: Any,
        wasAccepted: Bool,
        context: SmartDefaultContext
    ) async {
        guard configuration.enableLearning else { return }

        // Learn from the feedback
        await smartDefaultsEngine.learn(
            field: field,
            suggestedValue: autoFilledValue,
            acceptedValue: userValue,
            wasAccepted: wasAccepted,
            context: context
        )

        // Update metrics
        queue.async(flags: .barrier) {
            if wasAccepted {
                self._metrics.acceptedCount += 1
            } else {
                self._metrics.rejectedCount += 1
                self._metrics.rejectedFields.insert(field)
            }

            self._metrics.totalFeedbackCount += 1
            self._metrics.acceptanceRate = Float(self._metrics.acceptedCount) / Float(self._metrics.totalFeedbackCount)
        }
    }

    /// Get auto-fill metrics for analysis
    public func getMetrics() -> AutoFillMetrics {
        metrics
    }

    /// Reset metrics
    public func resetMetrics() {
        metrics = AutoFillMetrics()
    }

    // MARK: - Private Methods

    private func makeAutoFillDecision(
        field: RequirementField,
        defaultValue: FieldDefault,
        context _: SmartDefaultContext
    ) -> AutoFillDecision {
        var confidence = defaultValue.confidence
        let sources = [mapSourceToString(defaultValue.source)]
        var reasoning = "Based on \(sources[0])"

        // Apply confidence adjustments

        // 1. Boost confidence if field was recently used
        if isRecentlyUsedField(field) {
            confidence = min(1.0, confidence + 0.05)
            reasoning += ", recently used"
        }

        // 2. Reduce confidence for critical fields
        if criticalFields.contains(field), !configuration.autoFillCriticalFields {
            confidence *= 0.9
            reasoning += ", critical field"
        }

        // 3. Boost for consensus (if we had multiple sources)
        if sources.count > 1 {
            confidence = min(1.0, confidence + configuration.consensusBoost)
            reasoning += ", multiple sources agree"
        }

        // Determine action based on final confidence
        let action: AutoFillDecision.AutoFillAction
        if confidence >= configuration.autoFillThreshold {
            // Check if it's a critical field
            if criticalFields.contains(field), !configuration.autoFillCriticalFields {
                action = .suggest
                reasoning += " (critical field requires confirmation)"
            } else {
                action = .autoFill
            }
        } else if confidence >= configuration.suggestionThreshold {
            action = .suggest
        } else {
            action = .skip
        }

        return AutoFillDecision(
            field: field,
            action: action,
            value: defaultValue.value,
            confidence: confidence,
            reasoning: reasoning,
            sources: sources
        )
    }

    private func applyAutoFillLimits(_ decisions: [AutoFillDecision]) -> [AutoFillDecision] {
        var autoFillCount = 0
        var limitedDecisions: [AutoFillDecision] = []

        // Sort by confidence (highest first)
        let sortedDecisions = decisions.sorted { $0.confidence > $1.confidence }

        for decision in sortedDecisions {
            if decision.action == .autoFill, autoFillCount >= configuration.maxAutoFillFields {
                // Convert to suggestion if we've hit the limit
                limitedDecisions.append(AutoFillDecision(
                    field: decision.field,
                    action: .suggest,
                    value: decision.value,
                    confidence: decision.confidence,
                    reasoning: decision.reasoning + " (auto-fill limit reached)",
                    sources: decision.sources
                ))
            } else {
                limitedDecisions.append(decision)
                if decision.action == .autoFill {
                    autoFillCount += 1
                }
            }
        }

        return limitedDecisions
    }

    private func buildAutoFillResult(
        from decisions: [AutoFillDecision],
        startTime: Date
    ) -> AutoFillResult {
        var autoFilledFields: [RequirementField: Any] = [:]
        var suggestedFields: [RequirementField: FieldSuggestion] = [:]
        var skippedFields: [RequirementField] = []

        var totalConfidence: Float = 0
        var confidenceDistribution = ConfidenceDistribution(
            veryHigh: 0,
            high: 0,
            medium: 0,
            low: 0
        )

        for decision in decisions {
            switch decision.action {
            case .autoFill:
                autoFilledFields[decision.field] = decision.value
            case .suggest:
                suggestedFields[decision.field] = FieldSuggestion(
                    value: decision.value,
                    confidence: decision.confidence,
                    reasoning: decision.reasoning,
                    alternatives: [] // Could be enhanced with alternatives
                )
            case .skip:
                skippedFields.append(decision.field)
            }

            totalConfidence += decision.confidence

            // Update distribution
            switch decision.confidence {
            case 0.9...:
                confidenceDistribution = ConfidenceDistribution(
                    veryHigh: confidenceDistribution.veryHigh + 1,
                    high: confidenceDistribution.high,
                    medium: confidenceDistribution.medium,
                    low: confidenceDistribution.low
                )
            case 0.8 ..< 0.9:
                confidenceDistribution = ConfidenceDistribution(
                    veryHigh: confidenceDistribution.veryHigh,
                    high: confidenceDistribution.high + 1,
                    medium: confidenceDistribution.medium,
                    low: confidenceDistribution.low
                )
            case 0.65 ..< 0.8:
                confidenceDistribution = ConfidenceDistribution(
                    veryHigh: confidenceDistribution.veryHigh,
                    high: confidenceDistribution.high,
                    medium: confidenceDistribution.medium + 1,
                    low: confidenceDistribution.low
                )
            default:
                confidenceDistribution = ConfidenceDistribution(
                    veryHigh: confidenceDistribution.veryHigh,
                    high: confidenceDistribution.high,
                    medium: confidenceDistribution.medium,
                    low: confidenceDistribution.low + 1
                )
            }
        }

        let averageConfidence = decisions.isEmpty ? 0 : totalConfidence / Float(decisions.count)
        _ = Date().timeIntervalSince(startTime)

        // Estimate time saved (assume 15 seconds per auto-filled field, 8 seconds per suggested field)
        let timeSaved = TimeInterval(autoFilledFields.count * 15 + suggestedFields.count * 8)

        let summary = AutoFillSummary(
            totalFields: decisions.count,
            autoFilledCount: autoFilledFields.count,
            suggestedCount: suggestedFields.count,
            skippedCount: skippedFields.count,
            averageConfidence: averageConfidence,
            timeSaved: timeSaved,
            confidenceDistribution: confidenceDistribution
        )

        return AutoFillResult(
            autoFilledFields: autoFilledFields,
            suggestedFields: suggestedFields,
            skippedFields: skippedFields,
            totalConfidence: totalConfidence,
            summary: summary
        )
    }

    private func isRecentlyUsedField(_: RequirementField) -> Bool {
        // Check if field was used in last 5 sessions
        // This would integrate with session history
        false // Placeholder
    }

    private func mapSourceToString(_ source: FieldDefault.DefaultSource) -> String {
        switch source {
        case .historical:
            "historical data"
        case .userPattern:
            "user patterns"
        case .documentContext:
            "document extraction"
        case .systemDefault:
            "system rules"
        case .contextual:
            "contextual analysis"
        }
    }

    private func updateMetrics(with result: AutoFillResult) {
        queue.async(flags: .barrier) {
            self._metrics.totalAutoFillCount += result.summary.autoFilledCount
            self._metrics.totalSuggestionCount += result.summary.suggestedCount
            self._metrics.totalFieldsProcessed += result.summary.totalFields
            self._metrics.averageConfidence =
                (self._metrics.averageConfidence * Float(self._metrics.sessionsCount) +
                    result.summary.averageConfidence) / Float(self._metrics.sessionsCount + 1)
            self._metrics.sessionsCount += 1
            self._metrics.totalTimeSaved += result.summary.timeSaved
        }
    }

    // MARK: - Nested Types

    public struct AutoFillMetrics: Sendable {
        public var totalAutoFillCount: Int = 0
        public var totalSuggestionCount: Int = 0
        public var totalFieldsProcessed: Int = 0
        public var acceptedCount: Int = 0
        public var rejectedCount: Int = 0
        public var totalFeedbackCount: Int = 0
        public var acceptanceRate: Float = 0
        public var averageConfidence: Float = 0
        public var sessionsCount: Int = 0
        public var totalTimeSaved: TimeInterval = 0
        public var rejectedFields: Set<RequirementField> = []

        public init() {}
    }
}

// MARK: - Extensions for UI Integration

public extension ConfidenceBasedAutoFillEngine {
    /// Generate a user-friendly explanation of auto-fill results
    func generateAutoFillExplanation(_ result: AutoFillResult) -> String {
        let summary = result.summary

        var explanation = "I've analyzed your requirements and "

        if summary.autoFilledCount > 0 {
            explanation += "automatically filled \(summary.autoFilledCount) field\(summary.autoFilledCount > 1 ? "s" : "") with high confidence"

            if summary.suggestedCount > 0 {
                explanation += ", and have suggestions for \(summary.suggestedCount) more"
            }
            explanation += ". "
        } else if summary.suggestedCount > 0 {
            explanation += "have suggestions for \(summary.suggestedCount) field\(summary.suggestedCount > 1 ? "s" : ""). "
        } else {
            explanation += "need your input on all fields. "
        }

        if summary.timeSaved > 60 {
            let minutes = Int(summary.timeSaved / 60)
            explanation += "This should save you approximately \(minutes) minute\(minutes > 1 ? "s" : ""). "
        }

        if summary.averageConfidence > 0.8 {
            explanation += "The predictions are based on strong patterns from your previous work."
        } else if summary.averageConfidence > 0.65 {
            explanation += "Some fields have moderate confidence predictions that you may want to review."
        }

        return explanation
    }

    /// Get confidence badge color for UI display
    func getConfidenceColor(for confidence: Float) -> Color {
        switch confidence {
        case 0.9...:
            .green
        case 0.8 ..< 0.9:
            .blue
        case 0.65 ..< 0.8:
            .orange
        default:
            .gray
        }
    }

    /// Get confidence level description
    func getConfidenceDescription(for confidence: Float) -> String {
        switch confidence {
        case 0.9...:
            "Very High"
        case 0.8 ..< 0.9:
            "High"
        case 0.65 ..< 0.8:
            "Moderate"
        case 0.5 ..< 0.65:
            "Low"
        default:
            "Very Low"
        }
    }
}

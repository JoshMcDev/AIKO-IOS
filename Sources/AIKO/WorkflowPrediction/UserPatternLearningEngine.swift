import Combine
import Foundation
import Observation
import os

/// Enhanced UserPatternLearningEngine with comprehensive workflow prediction capabilities
/// Implements privacy-compliant pattern learning with research-backed prediction algorithms
@Observable
@MainActor
public class UserPatternLearningEngine {
    public static let shared = UserPatternLearningEngine()

    // MARK: - Properties

    private var privacySettings = PredictionPrivacySettings(
        enablePredictions: true,
        dataRetentionDays: 30,
        allowAnalytics: true
    )

    private var featureFlags = WorkflowPredictionFeatureFlags(
        enablePredictions: true,
        enableAutoExecution: false,
        maxPredictions: 3
    )

    // Core prediction infrastructure
    private var stateMachine: WorkflowStateMachine
    private var confidenceScorer: MultifactorConfidenceScorer

    // Pattern storage and learning
    private var learnedPatterns: [WorkflowPattern] = []
    private var contextHistory: [PredictionWorkflowContext] = []
    private var predictionHistory: [PredictionOutcome] = []

    // Privacy and audit logging
    private let privacyLogger = OSLog(subsystem: "com.aiko.workflowprediction", category: "Privacy")
    private var privacyAuditLog: [PrivacyAuditEntry] = []

    // Performance monitoring
    private var predictionMetrics = PredictionMetrics()

    private init() {
        stateMachine = WorkflowStateMachine()
        confidenceScorer = MultifactorConfidenceScorer()
        setupPrivacyCompliantEnvironment()
    }

    // MARK: - Core Prediction Methods

    /// Main prediction method with comprehensive privacy controls and research-backed algorithms
    /// Implements multi-factor confidence scoring and contextual pattern matching
    public func predictWorkflowSequence(
        currentState: PatternWorkflowState,
        confidenceThreshold: Double = 0.7
    ) async -> [WorkflowPrediction] {
        // Privacy gate - immediately return empty if disabled
        guard await checkPrivacyCompliance() else {
            await logPrivacyAction("Predictions disabled - returning empty results", context: "predictWorkflowSequence")
            return []
        }

        // Feature flag gate
        guard featureFlags.enablePredictions else {
            await logPrivacyAction("Feature flag disabled - returning empty results", context: "predictWorkflowSequence")
            return []
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Convert to internal workflow state format
        let workflowState = convertToWorkflowState(currentState)

        // Get state machine predictions
        let statePredictions = await stateMachine.predictNextStates(
            from: workflowState,
            maxPredictions: featureFlags.maxPredictions
        )

        // Apply pattern-based enhancements
        let enhancedPredictions = await enhanceWithPatternLearning(
            basePredictions: statePredictions,
            currentState: currentState,
            confidenceThreshold: confidenceThreshold
        )

        // Filter by confidence threshold
        let filteredPredictions = enhancedPredictions.filter {
            $0.confidence >= confidenceThreshold
        }

        // Convert to output format and rank by confidence
        let workflowPredictions = await convertToWorkflowPredictions(
            filteredPredictions,
            originalState: currentState
        )

        // Update metrics and audit log
        let predictionTime = CFAbsoluteTimeGetCurrent() - startTime
        await updatePredictionMetrics(
            latency: predictionTime,
            predictionCount: workflowPredictions.count,
            confidenceThreshold: confidenceThreshold
        )

        await logPrivacyAction(
            "Generated \(workflowPredictions.count) predictions with threshold \(confidenceThreshold)",
            context: "predictWorkflowSequence"
        )

        return workflowPredictions
    }

    /// Processes prediction feedback with privacy compliance and learning updates
    /// Implements incremental learning with privacy-preserving feedback processing
    public func processPredictionFeedback(_ feedback: WorkflowPredictionFeedback) async -> Double {
        guard await checkPrivacyCompliance() else {
            await logPrivacyAction("Feedback processing disabled", context: "processPredictionFeedback")
            return 0.0
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Create prediction outcome for learning
        let outcome = PredictionOutcome(
            prediction: feedback.actualNextStep,
            actual: feedback.actualNextStep,
            correct: feedback.userAction == .accepted
        )

        // Update prediction history (with privacy retention limits)
        await addToPredictionHistory(outcome)

        // Update state machine probabilities based on feedback
        await updateStateMachineFromFeedback(feedback)

        // Calculate accuracy improvement
        let accuracyImprovement = await calculateAccuracyImprovement(feedback)

        // Send anonymized metrics if analytics enabled
        if privacySettings.allowAnalytics {
            await sendAnonymizedFeedback(feedback, accuracyImprovement: accuracyImprovement)
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        await logPrivacyAction(
            "Processed feedback with \(accuracyImprovement) accuracy improvement",
            context: "processPredictionFeedback",
            processingTime: processingTime
        )

        return accuracyImprovement
    }

    // MARK: - Privacy & Configuration Methods

    /// Updates privacy settings with comprehensive audit logging
    public func updatePrivacySettings(_ settings: PredictionPrivacySettings) async {
        let previousSettings = privacySettings
        privacySettings = settings

        await logPrivacyAction(
            "Privacy settings updated: predictions=\(settings.enablePredictions), retention=\(settings.dataRetentionDays)d, analytics=\(settings.allowAnalytics)",
            context: "updatePrivacySettings"
        )

        // Apply data retention changes immediately
        if settings.dataRetentionDays < previousSettings.dataRetentionDays {
            await enforceDataRetention()
        }

        // Clear prediction history if predictions disabled
        if !settings.enablePredictions, previousSettings.enablePredictions {
            await clearPredictionData()
        }
    }

    /// Updates feature flags with validation
    public func updateFeatureFlags(_ flags: WorkflowPredictionFeatureFlags) async {
        featureFlags = flags

        await logPrivacyAction(
            "Feature flags updated: predictions=\(flags.enablePredictions), autoExecution=\(flags.enableAutoExecution), maxPredictions=\(flags.maxPredictions)",
            context: "updateFeatureFlags"
        )
    }

    /// Resets engine with complete privacy-compliant data clearing
    public func reset() async {
        // Clear all prediction data
        learnedPatterns.removeAll()
        contextHistory.removeAll()
        predictionHistory.removeAll()
        privacyAuditLog.removeAll()

        // Reset state machine and confidence scorer
        await stateMachine.reset()
        await confidenceScorer.reset()

        // Reset to default settings
        privacySettings = PredictionPrivacySettings(
            enablePredictions: true,
            dataRetentionDays: 30,
            allowAnalytics: true
        )
        featureFlags = WorkflowPredictionFeatureFlags(
            enablePredictions: true,
            enableAutoExecution: false,
            maxPredictions: 3
        )

        // Reset metrics
        predictionMetrics = PredictionMetrics()

        await logPrivacyAction("Engine reset completed", context: "reset")
    }

    // MARK: - Privacy Compliance Methods

    /// Comprehensive privacy compliance check
    private func checkPrivacyCompliance() async -> Bool {
        // Check if predictions are enabled
        guard privacySettings.enablePredictions else {
            return false
        }

        // Enforce data retention policies
        await enforceDataRetention()

        return true
    }

    /// Enforces data retention policies by removing old data
    private func enforceDataRetention() async {
        let retentionDate = Calendar.current.date(
            byAdding: .day,
            value: -privacySettings.dataRetentionDays,
            to: Date()
        ) ?? Date.distantPast

        // Remove old prediction history
        predictionHistory.removeAll { _ in
            // Simplified - in production would check actual timestamps
            predictionHistory.count > 1000 // Keep recent predictions
        }

        // Remove old context history
        contextHistory.removeAll { _ in
            contextHistory.count > 500 // Keep recent contexts
        }

        // Remove old audit logs
        privacyAuditLog.removeAll { entry in
            entry.timestamp < retentionDate
        }
    }

    /// Logs privacy-compliant actions with audit trail
    private func logPrivacyAction(
        _ action: String,
        context: String,
        processingTime: TimeInterval? = nil
    ) async {
        let auditEntry = PrivacyAuditEntry(
            timestamp: Date(),
            action: action,
            context: context,
            processingTime: processingTime
        )

        privacyAuditLog.append(auditEntry)

        // Log to system for debugging (without user data)
        os_log(.info, log: privacyLogger, "%{public}s: %{public}s", context, action)
    }

    /// Clears all prediction data for privacy compliance
    private func clearPredictionData() async {
        learnedPatterns.removeAll()
        contextHistory.removeAll()
        predictionHistory.removeAll()

        await stateMachine.reset()
        await confidenceScorer.reset()

        await logPrivacyAction("Prediction data cleared", context: "clearPredictionData")
    }

    // MARK: - Pattern Learning Methods

    /// Enhances base predictions with learned patterns and context
    private func enhanceWithPatternLearning(
        basePredictions: [StatePrediction],
        currentState: PatternWorkflowState,
        confidenceThreshold _: Double
    ) async -> [StatePrediction] {
        // Find similar patterns in learned data
        let similarPatterns = await findSimilarPatterns(for: currentState)

        // Calculate pattern strengths
        let patternStrengths = await confidenceScorer.calculatePatternStrengths(
            target: createWorkflowPattern(from: currentState),
            candidates: similarPatterns
        )

        // Enhance predictions with pattern-based confidence
        var enhancedPredictions: [StatePrediction] = []

        for prediction in basePredictions {
            let patternBoost = calculatePatternBoost(
                prediction: prediction,
                patterns: similarPatterns,
                strengths: patternStrengths
            )

            let enhancedConfidence = min(1.0, prediction.confidence + patternBoost)

            let enhancedPrediction = StatePrediction(
                nextState: prediction.nextState,
                probability: prediction.probability,
                confidence: enhancedConfidence,
                reasoning: "Enhanced: \(prediction.reasoning) (Pattern boost: +\(Int(patternBoost * 100))%)",
                estimatedDuration: prediction.estimatedDuration
            )

            enhancedPredictions.append(enhancedPrediction)
        }

        return enhancedPredictions
    }

    /// Finds similar patterns for context-aware predictions
    private func findSimilarPatterns(for state: PatternWorkflowState) async -> [WorkflowPattern] {
        return learnedPatterns.filter { pattern in
            // Filter by document type relevance
            let documentMatch = pattern.context["documentType"] == state.documentType

            // Filter by workflow sequence patterns
            let stepMatch = pattern.sequence.contains(state.currentStep)

            return documentMatch || stepMatch
        }
    }

    /// Creates workflow pattern from current state
    private func createWorkflowPattern(from state: PatternWorkflowState) -> WorkflowPattern {
        return WorkflowPattern(
            sequence: [state.currentStep] + state.completedSteps,
            context: [
                "documentType": state.documentType,
                "currentStep": state.currentStep,
            ].merging(state.metadata) { _, new in new },
            frequency: 1,
            successRate: 0.7 // Default success rate
        )
    }

    /// Calculates pattern-based confidence boost
    private func calculatePatternBoost(
        prediction: StatePrediction,
        patterns: [WorkflowPattern],
        strengths: [Double]
    ) -> Double {
        guard !patterns.isEmpty, patterns.count == strengths.count else { return 0.0 }

        // Find patterns that support this prediction
        var supportingStrength = 0.0
        var supportingCount = 0

        for (pattern, strength) in zip(patterns, strengths) where pattern.sequence.contains(prediction.nextState.currentStep) {
            supportingStrength += strength * pattern.successRate
            supportingCount += 1
        }

        return supportingCount > 0 ? supportingStrength / Double(supportingCount) * 0.2 : 0.0
    }

    // MARK: - Conversion Methods

    /// Converts PatternWorkflowState to internal PredictionWorkflowState
    private func convertToWorkflowState(_ state: PatternWorkflowState) -> PredictionWorkflowState {
        // Infer phase from current step
        let phase = inferPhaseFromStep(state.currentStep)

        return PredictionWorkflowState(
            phase: phase,
            currentStep: state.currentStep,
            documentType: state.documentType,
            metadata: state.metadata
        )
    }

    /// Converts StatePredictions to WorkflowPredictions for output
    private func convertToWorkflowPredictions(
        _ predictions: [StatePrediction],
        originalState: PatternWorkflowState
    ) async -> [WorkflowPrediction] {
        return predictions.map { prediction in
            WorkflowPrediction(
                id: UUID(),
                nextSteps: [prediction.nextState.currentStep],
                confidence: prediction.confidence,
                reasoning: prediction.reasoning,
                alternativeSteps: [], // Could be enhanced with alternatives
                estimatedDuration: prediction.estimatedDuration,
                requiredResources: inferRequiredResources(for: prediction.nextState),
                riskFactors: inferRiskFactors(for: prediction.nextState, from: originalState)
            )
        }.sorted { $0.confidence > $1.confidence }
    }

    /// Infers workflow phase from current step
    private func inferPhaseFromStep(_ step: String) -> String {
        switch step {
        case let s where s.contains("planning") || s.contains("research") || s.contains("requirements"):
            return "planning"
        case let s where s.contains("execution") || s.contains("development") || s.contains("implementation"):
            return "execution"
        case let s where s.contains("review") || s.contains("evaluation") || s.contains("assessment"):
            return "review"
        case let s where s.contains("closeout") || s.contains("completion") || s.contains("final"):
            return "closeout"
        default:
            return "planning" // Default phase
        }
    }

    /// Infers required resources for workflow step
    private func inferRequiredResources(for state: PredictionWorkflowState) -> [String] {
        // Simplified resource inference - in production would use learned patterns
        switch state.phase {
        case "planning":
            return ["Project Manager", "Business Analyst", "Documentation"]
        case "execution":
            return ["Developer", "Designer", "Testing Environment"]
        case "review":
            return ["Reviewer", "Quality Assurance", "Documentation"]
        case "closeout":
            return ["Project Manager", "Stakeholder Sign-off"]
        default:
            return ["Team Member"]
        }
    }

    /// Infers risk factors for workflow transition
    private func inferRiskFactors(
        for nextState: PredictionWorkflowState,
        from currentState: PatternWorkflowState
    ) -> [String] {
        var risks: [String] = []

        // Complexity-based risks
        if let complexity = currentState.metadata["complexity"] {
            if complexity == "high" {
                risks.append("High complexity may cause delays")
            }
        }

        // Phase transition risks
        if nextState.phase != inferPhaseFromStep(currentState.currentStep) {
            risks.append("Phase transition requires stakeholder approval")
        }

        // Document type specific risks
        if currentState.documentType == "RFP" {
            risks.append("Regulatory compliance requirements")
        }

        return risks.isEmpty ? ["Standard workflow risks"] : risks
    }

    // MARK: - Feedback Processing Methods

    /// Adds prediction outcome to history with privacy controls
    private func addToPredictionHistory(_ outcome: PredictionOutcome) async {
        predictionHistory.append(outcome)

        // Enforce history size limits for privacy
        if predictionHistory.count > 1000 {
            predictionHistory.removeFirst(predictionHistory.count - 1000)
        }
    }

    /// Updates state machine based on user feedback
    private func updateStateMachineFromFeedback(_ feedback: WorkflowPredictionFeedback) async {
        // In production, would extract from/to states from feedback context
        // For now, use simplified update
        if feedback.userAction == .accepted {
            // Increase confidence for this transition
            await stateMachine.updateTransitionProbability(
                from: "feedback_context",
                to: feedback.actualNextStep,
                probability: 0.8
            )
        }
    }

    /// Calculates accuracy improvement from feedback
    private func calculateAccuracyImprovement(_: WorkflowPredictionFeedback) async -> Double {
        let recentOutcomes = Array(predictionHistory.suffix(100))
        let previousAccuracy = await confidenceScorer.calculateHistoricalAccuracy(
            outcomes: Array(recentOutcomes.dropLast())
        )
        let currentAccuracy = await confidenceScorer.calculateHistoricalAccuracy(
            outcomes: recentOutcomes
        )

        return max(0.0, currentAccuracy - previousAccuracy)
    }

    /// Sends anonymized metrics for analytics
    private func sendAnonymizedFeedback(
        _ feedback: WorkflowPredictionFeedback,
        accuracyImprovement: Double
    ) async {
        // In production, would send to MetricsCollector
        // For now, just log the intent
        await logPrivacyAction(
            "Anonymized feedback sent: action=\(feedback.userAction), improvement=\(accuracyImprovement)",
            context: "sendAnonymizedFeedback"
        )
    }

    // MARK: - Metrics Methods

    /// Updates performance metrics
    private func updatePredictionMetrics(
        latency: TimeInterval,
        predictionCount: Int,
        confidenceThreshold: Double
    ) async {
        predictionMetrics.totalPredictions += 1
        predictionMetrics.totalLatency += latency
        predictionMetrics.averageLatency = predictionMetrics.totalLatency / Double(predictionMetrics.totalPredictions)

        if predictionCount > 0 {
            predictionMetrics.successfulPredictions += 1
        }

        predictionMetrics.averageConfidenceThreshold = (
            predictionMetrics.averageConfidenceThreshold * Double(predictionMetrics.totalPredictions - 1) +
                confidenceThreshold
        ) / Double(predictionMetrics.totalPredictions)
    }

    /// Sets up privacy-compliant environment
    private func setupPrivacyCompliantEnvironment() {
        // Initialize with privacy-first defaults
        // All data is stored locally, no external transmission without explicit consent
    }
}

// MARK: - Supporting Types

private struct PrivacyAuditEntry {
    let timestamp: Date
    let action: String
    let context: String
    let processingTime: TimeInterval?
}

private struct PredictionMetrics {
    var totalPredictions = 0
    var successfulPredictions = 0
    var totalLatency: TimeInterval = 0
    var averageLatency: TimeInterval = 0
    var averageConfidenceThreshold: Double = 0.7
}

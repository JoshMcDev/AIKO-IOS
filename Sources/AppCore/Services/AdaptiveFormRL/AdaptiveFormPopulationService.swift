import CoreData
import Foundation

/// Central coordinator for adaptive form population with performance monitoring
/// Implements Q-learning based adaptive form population with privacy-preserving learning
@MainActor
public final class AdaptiveFormPopulationService: ObservableObject {
    // MARK: - Dependencies

    private let contextClassifier: AcquisitionContextClassifier
    private let qLearningAgent: FormFieldQLearningAgent
    private let modificationTracker: FormModificationTracker
    private let explanationEngine: ValueExplanationEngine
    private let metricsCollector: AdaptiveFormMetricsCollector
    private let agenticOrchestrator: AgenticOrchestratorProtocol?

    // MARK: - Configuration

    private let confidenceThreshold: Double = 0.6
    private let performanceThreshold: TimeInterval = 0.2 // 200ms

    // MARK: - State

    @Published private var isEnabled: Bool = true
    private var fallbackCount: Int = 0
    private var avgPerformance: TimeInterval = 0.0

    // MARK: - Initialization

    public init(
        contextClassifier: AcquisitionContextClassifier,
        qLearningAgent: FormFieldQLearningAgent,
        modificationTracker: FormModificationTracker,
        explanationEngine: ValueExplanationEngine,
        metricsCollector: AdaptiveFormMetricsCollector,
        agenticOrchestrator: AgenticOrchestratorProtocol? = nil
    ) {
        self.contextClassifier = contextClassifier
        self.qLearningAgent = qLearningAgent
        self.modificationTracker = modificationTracker
        self.explanationEngine = explanationEngine
        self.metricsCollector = metricsCollector
        self.agenticOrchestrator = agenticOrchestrator
    }

    // MARK: - Public Methods

    /// Populate form with adaptive suggestions
    public func populateForm(
        _ baseData: FormData,
        acquisition: AcquisitionAggregate,
        userProfile: UserProfile
    ) async -> AdaptiveFormResult {
        let startTime = Date()

        // Classify acquisition context
        let context = await contextClassifier.classifyContext(acquisition: acquisition)

        // Get Q-learning predictions for each field
        let predictions = await getPredictions(
            baseData: baseData,
            context: context,
            userProfile: userProfile
        )

        // Route based on confidence
        let result = await routeBasedOnConfidence(
            predictions: predictions,
            fallbackData: baseData
        )

        // Track performance
        let performance = Date().timeIntervalSince(startTime)
        await metricsCollector.recordPerformance(performance)

        return result
    }

    /// Learn from user modifications
    public func learnFromModifications(
        originalData: FormData,
        modifiedData: FormData,
        context: AcquisitionContext
    ) async {
        // Track modifications for learning
        await modificationTracker.trackModifications(
            original: originalData,
            modified: modifiedData,
            context: context
        )

        // Update Q-learning agent
        let modifications = extractModifications(original: originalData, modified: modifiedData)
        for modification in modifications {
            await qLearningAgent.updateFromModification(modification, context: context)
        }
    }

    // MARK: - Private Methods

    private func getPredictions(
        baseData: FormData,
        context: AcquisitionContext,
        userProfile: UserProfile
    ) async -> [FieldPrediction] {
        var predictions: [FieldPrediction] = []

        for field in baseData.fields {
            let prediction = await qLearningAgent.predictValue(
                field: field,
                context: context,
                userProfile: userProfile
            )
            predictions.append(prediction)
        }

        return predictions
    }

    private func routeBasedOnConfidence(
        predictions: [FieldPrediction],
        fallbackData: FormData
    ) async -> AdaptiveFormResult {
        let avgConfidence = predictions.map(\.confidence).reduce(0, +) / Double(predictions.count)

        if avgConfidence >= confidenceThreshold {
            // Use adaptive predictions
            let adaptedForm = applyPredictions(predictions: predictions, to: fallbackData)
            let explanations = await generateExplanations(for: predictions)

            return AdaptiveFormResult(
                formData: adaptedForm,
                predictions: predictions,
                confidence: avgConfidence,
                explanations: explanations,
                source: .adaptive
            )
        } else {
            // Use static fallback
            fallbackCount += 1
            return AdaptiveFormResult(
                formData: fallbackData,
                predictions: predictions,
                confidence: avgConfidence,
                explanations: [],
                source: .staticFallback
            )
        }
    }

    private func applyPredictions(predictions: [FieldPrediction], to formData: FormData) -> FormData {
        var updatedFormData = formData

        for prediction in predictions where formData.hasField(named: prediction.fieldId) {
            // Find field by name (since fieldId in prediction corresponds to field name)
            updatedFormData = updatedFormData.updatingField(
                named: prediction.fieldId,
                with: prediction.suggestedValue
            )
        }

        return updatedFormData
    }

    private func generateExplanations(for predictions: [FieldPrediction]) async -> [FieldExplanation] {
        var explanations: [FieldExplanation] = []

        for prediction in predictions {
            let explanation = await explanationEngine.generateExplanation(for: prediction)
            explanations.append(explanation)
        }

        return explanations
    }

    private func extractModifications(original: FormData, modified: FormData) -> [FieldModification] {
        var modifications: [FieldModification] = []

        for (originalField, modifiedField) in zip(original.fields, modified.fields) where originalField.value != modifiedField.value {
            modifications.append(FieldModification(
                fieldId: originalField.name,
                originalValue: originalField.value,
                modifiedValue: modifiedField.value,
                timestamp: Date()
            ))
        }

        return modifications
    }
}

// MARK: - Supporting Types

// Types moved to FormDataTypes.swift to avoid duplication

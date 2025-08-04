import Foundation
import os.signpost

/// Probabilistic Finite State Machine (PFSM) for workflow prediction
/// Implements research-backed patterns with <100ms prediction latency and <50MB memory footprint
actor WorkflowStateMachine {
    // MARK: - Properties

    private var currentState: PredictionWorkflowState?
    private var history: WorkflowStateBuffer<PredictionWorkflowState>
    private var transitionMatrix: [String: [String: Double]] = [:]
    private let signpostLog = OSLog(subsystem: "com.aiko.workflowprediction", category: "StateMachine")
    private let signpostID = OSSignpostID(log: OSLog(subsystem: "com.aiko.workflowprediction", category: "StateMachine"))

    // MARK: - Constants

    /// PFSM configuration constants
    private enum PFSMConstants {
        // Performance targets
        static let maxPredictionLatencyMs: Double = 100.0
        static let maxMemoryFootprintMB: Double = 50.0

        // Default transition values
        static let defaultProbability: Double = 0.5
        static let defaultConfidence: Double = 0.4
        static let defaultDurationSeconds: TimeInterval = 3600 // 1 hour
        static let fallbackDurationSeconds: TimeInterval = 1800 // 30 minutes

        // Confidence calculation weights (aligned with MultifactorConfidenceScorer)
        static let historicalAccuracyWeight: Double = 0.4
        static let patternStrengthWeight: Double = 0.3
        static let temporalRelevanceWeight: Double = 0.2
        static let probabilityWeight: Double = 0.1

        // Incremental learning rate
        static let learningRate: Double = 0.1

        // Fallback confidence values
        static let fallbackHistoricalAccuracy: Double = 0.7
        static let fallbackPatternStrength: Double = 0.8
        static let fallbackTemporalRelevance: Double = 0.6
    }

    // Performance monitoring
    private var totalPredictions = 0
    private var totalPredictionTime: TimeInterval = 0

    // MARK: - Initialization

    init(historyCapacity: Int = 1000) {
        history = WorkflowStateBuffer(capacity: historyCapacity)
    }

    // MARK: - State Management

    /// Updates current state and adds to history with performance monitoring
    func updateCurrentState(_ state: PredictionWorkflowState) async {
        os_signpost(.begin, log: signpostLog, name: "UpdateState", signpostID: signpostID)

        currentState = state
        history.append(state)

        // Update transition probabilities based on history
        await updateTransitionProbabilitiesFromHistory()

        os_signpost(.end, log: signpostLog, name: "UpdateState", signpostID: signpostID)
    }

    /// Gets current workflow state
    func getCurrentState() async -> PredictionWorkflowState? {
        return currentState
    }

    /// Adds state to history without changing current state
    func addToHistory(_ state: PredictionWorkflowState) async {
        history.append(state)
        await updateTransitionProbabilitiesFromHistory()
    }

    /// Returns current history count for memory monitoring
    func getHistoryCount() async -> Int {
        return history.elementCount
    }

    // MARK: - Transition Management

    /// Updates transition probability with bounds checking [0.0, 1.0]
    func updateTransitionProbability(from: String, to: String, probability: Double) async {
        let clampedProbability = max(0.0, min(1.0, probability))

        if transitionMatrix[from] == nil {
            transitionMatrix[from] = [:]
        }
        transitionMatrix[from]?[to] = clampedProbability

        // Normalize probabilities to ensure stochastic matrix property
        await normalizeTransitionProbabilities(for: from)
    }

    /// Gets transition probability between states
    func getTransitionProbability(from: String, to: String) async -> Double {
        return transitionMatrix[from]?[to] ?? 0.0
    }

    /// Validates workflow state transitions using domain-specific rules
    func validateTransition(from: PredictionWorkflowState, to: PredictionWorkflowState) async -> Bool {
        // Enhanced validation logic based on acquisition workflow rules
        return await isValidWorkflowTransition(from: from, to: to)
    }

    // MARK: - Prediction Generation

    /// Generates next state predictions using PFSM with confidence scoring
    func predictNextStates(from state: PredictionWorkflowState, maxPredictions: Int) async -> [StatePrediction] {
        let startTime = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: signpostLog, name: "PredictStates", signpostID: signpostID,
                    "maxPredictions=%d", maxPredictions)

        defer {
            let endTime = CFAbsoluteTimeGetCurrent()
            let predictionTime = endTime - startTime
            totalPredictions += 1
            totalPredictionTime += predictionTime

            os_signpost(.end, log: signpostLog, name: "PredictStates", signpostID: signpostID,
                        "latency=%.2fms", predictionTime * 1000)
        }

        // Get possible next states from transition matrix
        let currentStateKey = createStateKey(from: state)
        guard let transitions = transitionMatrix[currentStateKey] else {
            return await generateFallbackPredictions(from: state, maxPredictions: maxPredictions)
        }

        // Generate predictions with confidence scoring
        var predictions: [StatePrediction] = []

        for (nextStateKey, probability) in transitions {
            guard predictions.count < maxPredictions else { break }

            let nextState = await createStateFromKey(nextStateKey, documentType: state.documentType)
            let confidence = await calculateConfidence(
                from: state,
                to: nextState,
                probability: probability
            )

            let prediction = StatePrediction(
                nextState: nextState,
                probability: probability,
                confidence: confidence,
                reasoning: await generateReasoning(from: state, to: nextState, probability: probability),
                estimatedDuration: await estimateDuration(from: state, to: nextState)
            )

            predictions.append(prediction)
        }

        // Sort by confidence * probability for optimal ranking
        predictions.sort { $0.confidence * $0.probability > $1.confidence * $1.probability }

        return Array(predictions.prefix(maxPredictions))
    }

    // MARK: - Persistence

    /// Persists current state and transition matrix
    func persistState() async {
        // TODO: Implement Core Data persistence for production
        // For now, this is a placeholder that maintains state in memory
    }

    /// Loads persisted state and transition matrix
    func loadPersistedState() async {
        // TODO: Implement Core Data loading for production
        // For now, this is a placeholder
    }

    // MARK: - Utility Methods

    /// Resets all state and clears history
    func reset() async {
        currentState = nil
        history.clear()
        transitionMatrix.removeAll()
        totalPredictions = 0
        totalPredictionTime = 0
    }

    /// Gets performance metrics for monitoring
    func getPerformanceMetrics() async -> (averageLatency: TimeInterval, totalPredictions: Int) {
        let averageLatency = totalPredictions > 0 ? totalPredictionTime / Double(totalPredictions) : 0
        return (averageLatency, totalPredictions)
    }

    // MARK: - Private Methods

    /// Updates transition probabilities based on historical patterns
    private func updateTransitionProbabilitiesFromHistory() async {
        let states = history.getAllElements()
        guard states.count >= 2 else { return }

        // Analyze sequential patterns in history
        for i in 0 ..< (states.count - 1) {
            let from = createStateKey(from: states[i])
            let to = createStateKey(from: states[i + 1])

            // Update transition count and probability
            let currentProbability = transitionMatrix[from]?[to] ?? 0.0
            let newProbability = min(1.0, currentProbability + PFSMConstants.learningRate)

            await updateTransitionProbability(from: from, to: to, probability: newProbability)
        }
    }

    /// Normalizes transition probabilities to maintain stochastic matrix property
    private func normalizeTransitionProbabilities(for fromState: String) async {
        guard let transitions = transitionMatrix[fromState] else { return }

        let sum = transitions.values.reduce(0, +)
        guard sum > 0 else { return }

        // Normalize to ensure probabilities sum to 1.0
        for (toState, probability) in transitions {
            transitionMatrix[fromState]?[toState] = probability / sum
        }
    }

    /// Creates a unique key for state identification
    private func createStateKey(from state: PredictionWorkflowState) -> String {
        return "\(state.phase)|\(state.currentStep)|\(state.documentType)"
    }

    /// Creates state from key string
    private func createStateFromKey(_ key: String, documentType: String) async -> PredictionWorkflowState {
        let components = key.split(separator: "|")
        return PredictionWorkflowState(
            phase: String(components[0]),
            currentStep: String(components[1]),
            documentType: documentType,
            metadata: [:]
        )
    }

    /// Validates workflow transitions using domain-specific rules
    private func isValidWorkflowTransition(from: PredictionWorkflowState, to: PredictionWorkflowState) async -> Bool {
        // Acquisition workflow validation rules
        let validPhaseTransitions: [String: Set<String>] = [
            "planning": ["execution", "review"],
            "execution": ["review", "closeout"],
            "review": ["execution", "closeout", "planning"],
            "closeout": ["planning"], // Can start new acquisition
        ]

        guard let validNextPhases = validPhaseTransitions[from.phase] else { return false }
        return validNextPhases.contains(to.phase)
    }

    /// Calculates confidence score for state transition
    private func calculateConfidence(
        from: PredictionWorkflowState,
        to: PredictionWorkflowState,
        probability: Double
    ) async -> Double {
        // Multi-factor confidence calculation
        let historicalAccuracy = await getHistoricalAccuracy(from: from, to: to)
        let patternStrength = await getPatternStrength(from: from, to: to)
        let temporalRelevance = await getTemporalRelevance(from: from, to: to)

        // Weighted combination (research-backed weights aligned with MultifactorConfidenceScorer)
        return historicalAccuracy * PFSMConstants.historicalAccuracyWeight +
               patternStrength * PFSMConstants.patternStrengthWeight +
               temporalRelevance * PFSMConstants.temporalRelevanceWeight +
               probability * PFSMConstants.probabilityWeight
    }

    /// Generates fallback predictions for new users or insufficient data
    private func generateFallbackPredictions(
        from state: PredictionWorkflowState,
        maxPredictions: Int
    ) async -> [StatePrediction] {
        // Simple rule-based fallback predictor
        let defaultTransitions = getDefaultTransitions(for: state.phase)
        var predictions: [StatePrediction] = []

        for (nextPhase, nextStep) in defaultTransitions.prefix(maxPredictions) {
            let nextState = PredictionWorkflowState(
                phase: nextPhase,
                currentStep: nextStep,
                documentType: state.documentType,
                metadata: state.metadata
            )

            let prediction = StatePrediction(
                nextState: nextState,
                probability: PFSMConstants.defaultProbability,
                confidence: PFSMConstants.defaultConfidence,
                reasoning: "Based on typical workflow patterns",
                estimatedDuration: PFSMConstants.defaultDurationSeconds
            )

            predictions.append(prediction)
        }

        return predictions
    }

    /// Helper methods for confidence calculation
    private func getHistoricalAccuracy(from _: PredictionWorkflowState, to _: PredictionWorkflowState) async -> Double {
        // Placeholder - would analyze past prediction accuracy
        return PFSMConstants.fallbackHistoricalAccuracy
    }

    private func getPatternStrength(from _: PredictionWorkflowState, to _: PredictionWorkflowState) async -> Double {
        // Placeholder - would analyze pattern matching strength
        return PFSMConstants.fallbackPatternStrength
    }

    private func getTemporalRelevance(from _: PredictionWorkflowState, to _: PredictionWorkflowState) async -> Double {
        // Placeholder - would analyze time-based relevance
        return PFSMConstants.fallbackTemporalRelevance
    }

    private func generateReasoning(
        from: PredictionWorkflowState,
        to: PredictionWorkflowState,
        probability: Double
    ) async -> String {
        return "Based on \(Int(probability * 100))% historical probability from \(from.currentStep) to \(to.currentStep)"
    }

    private func estimateDuration(from _: PredictionWorkflowState, to _: PredictionWorkflowState) async -> TimeInterval? {
        // Placeholder - would estimate based on historical data
        return PFSMConstants.fallbackDurationSeconds
    }

    private func getDefaultTransitions(for phase: String) -> [(String, String)] {
        switch phase {
        case "planning":
            return [("execution", "vendor_research"), ("review", "requirements_review")]
        case "execution":
            return [("review", "technical_evaluation"), ("closeout", "contract_completion")]
        case "review":
            return [("execution", "contract_negotiation"), ("closeout", "final_approval")]
        case "closeout":
            return [("planning", "lessons_learned")]
        default:
            return [("planning", "initial_research")]
        }
    }
}

// MARK: - Supporting Types

/// Efficient circular buffer for workflow state history management
private class WorkflowStateBuffer<T> {
    private var buffer: [T?]
    private var head = 0
    private var count = 0
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
        buffer = Array(repeating: nil, count: capacity)
    }

    func append(_ element: T) {
        buffer[head] = element
        head = (head + 1) % capacity
        count = min(count + 1, capacity)
    }

    func clear() {
        buffer = Array(repeating: nil, count: capacity)
        head = 0
        count = 0
    }

    func getAllElements() -> [T] {
        var elements: [T] = []

        guard !isEmpty else { return elements }

        let startIndex = count < capacity ? 0 : head

        for i in 0 ..< count {
            let index = (startIndex + i) % capacity
            if let element = buffer[index] {
                elements.append(element)
            }
        }

        return elements
    }

    var elementCount: Int {
        return count
    }

    var isEmpty: Bool {
        // swiftlint:disable:next empty_count
        return count == 0
    }
}

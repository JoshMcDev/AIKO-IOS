import Foundation

actor WorkflowStateMachine {
    private var currentState: PredictionWorkflowState?
    private var history: [PredictionWorkflowState] = []
    private var transitionMatrix: [String: [String: Double]] = [:]
    
    func updateCurrentState(_ state: PredictionWorkflowState) async {
        currentState = state
        history.append(state)
        
        // Limit history to 1000 entries
        if history.count > 1000 {
            history.removeFirst(history.count - 1000)
        }
    }
    
    func getCurrentState() async -> PredictionWorkflowState? {
        return currentState
    }
    
    func addToHistory(_ state: PredictionWorkflowState) async {
        history.append(state)
        
        // Limit history to 1000 entries
        if history.count > 1000 {
            history.removeFirst(history.count - 1000)
        }
    }
    
    func getHistoryCount() async -> Int {
        return history.count
    }
    
    func updateTransitionProbability(from: String, to: String, probability: Double) async {
        if transitionMatrix[from] == nil {
            transitionMatrix[from] = [:]
        }
        transitionMatrix[from]?[to] = probability
    }
    
    func getTransitionProbability(from: String, to: String) async -> Double {
        return transitionMatrix[from]?[to] ?? 0.0
    }
    
    func validateTransition(from: PredictionWorkflowState, to: PredictionWorkflowState) async -> Bool {
        // Simple basic transition validation
        // In a real implementation, this would be more complex
        return from.phase != to.phase
    }
    
    func persistState() async {
        // Placeholder for state persistence
    }
    
    func loadPersistedState() async {
        // Placeholder for loading persisted state
    }
    
    func predictNextStates(from state: PredictionWorkflowState, maxPredictions: Int) async -> [StatePrediction] {
        // Minimal implementation
        return []
    }
    
    func reset() async {
        currentState = nil
        history.removeAll()
        transitionMatrix.removeAll()
    }
}
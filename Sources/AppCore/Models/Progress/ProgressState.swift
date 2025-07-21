import Foundation

/// Represents the current state of a progress tracking operation
public struct ProgressState: Equatable, Sendable {
    public let id: UUID
    public let phase: ProgressPhase
    public let fractionCompleted: Double
    public let currentStep: String
    public let totalSteps: Int
    public let currentStepIndex: Int
    public let estimatedTimeRemaining: TimeInterval?
    public let accessibilityLabel: String
    public let timestamp: Date

    public init(
        phase: ProgressPhase,
        fractionCompleted: Double,
        currentStep: String,
        totalSteps: Int = 1,
        currentStepIndex: Int = 0,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.phase = phase
        self.fractionCompleted = max(0.0, min(1.0, fractionCompleted)) // Clamp to 0.0-1.0
        self.currentStep = currentStep
        self.totalSteps = max(1, totalSteps) // Ensure at least 1 step
        let validatedCurrentStepIndex = max(0, currentStepIndex) // Ensure non-negative
        self.currentStepIndex = min(validatedCurrentStepIndex, max(0, totalSteps - 1)) // Clamp to valid range
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.timestamp = Date()

        // Generate accessibility label
        let percentComplete = Int(self.fractionCompleted * 100)
        let phaseDescription = phase == .idle ? "Ready" : phase.displayName
        self.accessibilityLabel = "\(phaseDescription): \(percentComplete)% complete, \(currentStep)"
    }
}

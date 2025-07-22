import Foundation

/// Represents a progress update event in the scanning workflow
public struct ProgressUpdate: Equatable, Sendable {
    /// Unique identifier for the progress session
    public let sessionId: UUID

    /// Timestamp when the update was created
    public let timestamp: Date

    /// Current workflow phase
    public let phase: ProgressPhase

    /// Progress within the current phase (0.0 to 1.0)
    public let phaseProgress: Double

    /// Overall progress across all phases (0.0 to 1.0)
    public let overallProgress: Double

    /// Current operation description
    public let operation: String

    /// Optional metadata for additional context
    public let metadata: [String: String]

    /// Estimated time remaining in seconds
    public let estimatedTimeRemaining: TimeInterval?

    public init(
        sessionId: UUID,
        timestamp: Date = Date(),
        phase: ProgressPhase,
        phaseProgress: Double,
        overallProgress: Double,
        operation: String? = nil,
        metadata: [String: String] = [:],
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.phase = phase
        self.phaseProgress = max(0.0, min(1.0, phaseProgress))
        self.overallProgress = max(0.0, min(1.0, overallProgress))
        self.operation = operation ?? phase.operationDescription
        self.metadata = metadata
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

// MARK: - Convenience Initializers

public extension ProgressUpdate {
    /// Create a progress update with automatic overall progress calculation
    static func phaseUpdate(
        sessionId: UUID,
        phase: ProgressPhase,
        phaseProgress: Double,
        operation: String? = nil,
        metadata: [String: String] = [:],
        estimatedTimeRemaining: TimeInterval? = nil
    ) -> ProgressUpdate {
        let overallProgress = calculateOverallProgress(phase: phase, phaseProgress: phaseProgress)

        return ProgressUpdate(
            sessionId: sessionId,
            phase: phase,
            phaseProgress: phaseProgress,
            overallProgress: overallProgress,
            operation: operation,
            metadata: metadata,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
    }

    /// Create a phase transition update
    static func phaseTransition(
        sessionId: UUID,
        to phase: ProgressPhase,
        metadata: [String: String] = [:]
    ) -> ProgressUpdate {
        let overallProgress = calculateOverallProgress(phase: phase, phaseProgress: 0.0)

        return ProgressUpdate(
            sessionId: sessionId,
            phase: phase,
            phaseProgress: 0.0,
            overallProgress: overallProgress,
            metadata: metadata
        )
    }

    /// Create a completion update
    static func completion(
        sessionId: UUID,
        metadata: [String: String] = [:]
    ) -> ProgressUpdate {
        ProgressUpdate(
            sessionId: sessionId,
            phase: .completed,
            phaseProgress: 1.0,
            overallProgress: 1.0,
            metadata: metadata,
            estimatedTimeRemaining: 0
        )
    }

    /// Create an error update
    static func error(
        sessionId: UUID,
        phase: ProgressPhase,
        phaseProgress: Double,
        error: String,
        metadata: [String: String] = [:]
    ) -> ProgressUpdate {
        var errorMetadata = metadata
        errorMetadata["error"] = error
        errorMetadata["failed_phase"] = phase.rawValue

        let overallProgress = calculateOverallProgress(phase: phase, phaseProgress: phaseProgress)

        return ProgressUpdate(
            sessionId: sessionId,
            phase: .error,
            phaseProgress: phaseProgress,
            overallProgress: overallProgress,
            operation: "Error: \(error)",
            metadata: errorMetadata
        )
    }
}

// MARK: - Progress Calculation

private func calculateOverallProgress(phase: ProgressPhase, phaseProgress: Double) -> Double {
    let phases: [ProgressPhase] = [.initializing, .scanning, .processing, .ocr, .formPopulation, .finalizing]

    guard let currentIndex = phases.firstIndex(of: phase) else {
        return phase == .completed ? 1.0 : 0.0
    }

    // Calculate progress based on completed phases plus current phase progress
    var totalProgress = 0.0

    // Add progress from completed phases
    for i in 0 ..< currentIndex {
        totalProgress += phases[i].relativeDuration
    }

    // Add progress within current phase
    totalProgress += phases[currentIndex].relativeDuration * phaseProgress

    return min(1.0, totalProgress)
}

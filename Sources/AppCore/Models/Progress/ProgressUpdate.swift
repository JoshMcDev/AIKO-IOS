import Foundation

/// Represents a progress update for a specific session
public struct ProgressUpdate: Equatable, Sendable {
    public let sessionId: UUID
    public let phase: ProgressPhase
    public let fractionCompleted: Double
    public let message: String
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        sessionId: UUID,
        phase: ProgressPhase,
        fractionCompleted: Double,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.sessionId = sessionId
        self.phase = phase
        self.fractionCompleted = max(0.0, min(1.0, fractionCompleted)) // Clamp to 0.0-1.0
        self.message = message
        self.timestamp = Date()
        self.metadata = metadata
    }
}

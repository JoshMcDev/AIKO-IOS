import AppCore
import Foundation

// MARK: - LocalRLAgent Compliance Extensions

public extension LocalRLAgent {
    /// Shared instance for compliance integration testing
    static let shared: LocalRLAgent = {
        fatalError("LocalRLAgent.shared not properly initialized - RED phase")
    }()

    /// Get RL state for compliance context
    func getState(for _: AcquisitionContext) async throws -> RLState {
        // RED phase: Return basic state to cause test failures
        RLState(experienceCount: 0) // Will fail > 0 test
    }

    /// Calculate reward for compliance feedback
    func calculateReward(
        for action: UserAction,
        context _: AcquisitionContext
    ) async throws -> Double {
        // RED phase: Return positive reward to cause test failures
        switch action {
        case .dismissWarning(reason: .falsePositive):
            0.5 // Should be negative for false positive
        default:
            0.0
        }
    }
}

// MARK: - Supporting Types for RED Phase

public struct RLState: Sendable {
    public let experienceCount: Int

    public init(experienceCount: Int) {
        self.experienceCount = experienceCount
    }
}

// Using existing MockRLPersistenceManager from LocalRLAgent.swift

// RED PHASE MARKER: This implementation is designed to fail integration tests appropriately

import Foundation
import AppCore

// MARK: - LocalRLAgent Compliance Extensions

extension LocalRLAgent {
    /// Shared instance for compliance integration testing
    public static let shared: LocalRLAgent = {
        fatalError("LocalRLAgent.shared not properly initialized - RED phase")
    }()

    /// Get RL state for compliance context
    public func getState(for context: AcquisitionContext) async throws -> RLState {
        // RED phase: Return basic state to cause test failures
        return RLState(experienceCount: 0) // Will fail > 0 test
    }

    /// Calculate reward for compliance feedback
    public func calculateReward(
        for action: UserAction,
        context: AcquisitionContext
    ) async throws -> Double {
        // RED phase: Return positive reward to cause test failures
        switch action {
        case .dismissWarning(reason: .falsePositive):
            return 0.5 // Should be negative for false positive
        default:
            return 0.0
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

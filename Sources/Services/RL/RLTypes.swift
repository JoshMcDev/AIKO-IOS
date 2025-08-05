import Foundation

// MARK: - Shared RL Types

// Common types used across RL components to avoid duplication

public struct ActionIdentifier: Hashable, Codable, Sendable {
    public let actionId: String
    public let contextHash: Int

    public init(actionId: String, contextHash: Int) {
        self.actionId = actionId
        self.contextHash = contextHash
    }

    public init(action: WorkflowAction, contextHash: Int) {
        actionId = action.id.uuidString
        self.contextHash = contextHash
    }
}

public struct ContextualBandit: Codable, Sendable {
    public let contextFeatures: FeatureVector
    public var successCount: Double // Beta distribution α
    public var failureCount: Double // Beta distribution β
    public var lastUpdate: Date
    public var totalSamples: Int

    public init(contextFeatures: FeatureVector, successCount: Double, failureCount: Double, lastUpdate: Date, totalSamples: Int) {
        self.contextFeatures = contextFeatures
        self.successCount = successCount
        self.failureCount = failureCount
        self.lastUpdate = lastUpdate
        self.totalSamples = totalSamples
    }

    public mutating func updatePosterior(reward: Double) {
        // Update Beta distribution parameters based on reward signal
        if reward > 0.5 {
            successCount += reward
        } else {
            failureCount += 1.0 - reward
        }
        totalSamples += 1
        lastUpdate = Date()
    }

    public func sampleThompson() -> Double {
        // Simple Thompson sampling approximation for Beta distribution
        // For production use, implement proper Beta distribution sampling
        let mean = successCount / (successCount + failureCount)
        let variance = (successCount * failureCount) / (pow(successCount + failureCount, 2) * (successCount + failureCount + 1))
        let stdDev = sqrt(variance)

        // Use normal approximation to Beta distribution for simplicity
        // In production, use proper Beta distribution library
        let sample = Double.random(in: max(0, mean - 2 * stdDev) ... min(1, mean + 2 * stdDev))
        return sample
    }
}

public struct RewardSignal: Sendable {
    public let immediateReward: Double
    public let delayedReward: Double
    public let complianceReward: Double
    public let efficiencyReward: Double

    public init(immediateReward: Double, delayedReward: Double, complianceReward: Double, efficiencyReward: Double) {
        self.immediateReward = immediateReward
        self.delayedReward = delayedReward
        self.complianceReward = complianceReward
        self.efficiencyReward = efficiencyReward
    }

    public var totalReward: Double {
        // Weighted composition: 40% immediate, 30% delayed, 20% compliance, 10% efficiency
        immediateReward * 0.4 + delayedReward * 0.3 + complianceReward * 0.2 + efficiencyReward * 0.1
    }
}

public enum RLError: Error {
    case noValidAction
    case invalidContext
    case persistenceError
}

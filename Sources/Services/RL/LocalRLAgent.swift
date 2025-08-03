import Foundation

/// LocalRLAgent - Contextual Multi-Armed Bandit with Thompson Sampling
/// This is minimal scaffolding code to make tests compile but fail appropriately
public actor LocalRLAgent {
    // MARK: - Properties

    private var contextualBandits: [ActionIdentifier: ContextualBandit] = [:]
    private let persistenceManager: MockRLPersistenceManager

    // Thompson Sampling parameters
    private let priorAlpha: Double = 1.0
    private let priorBeta: Double = 1.0

    // MARK: - Initialization

    public init(
        persistenceManager: MockRLPersistenceManager,
        initialBandits: [ActionIdentifier: ContextualBandit]
    ) async throws {
        self.persistenceManager = persistenceManager
        contextualBandits = initialBandits
    }

    // MARK: - Public Interface - Scaffolding Implementation

    public func selectAction(
        context: FeatureVector,
        actions: [WorkflowAction]
    ) async throws -> ActionRecommendation {
        guard !actions.isEmpty else {
            throw RLError.noValidAction
        }

        // Generate action identifier based on context and action
        let contextHash = context.hash

        // Ensure bandit exists for each action in this context
        for action in actions {
            let actionKey = ActionIdentifier(action: action, contextHash: contextHash)
            if contextualBandits[actionKey] == nil {
                contextualBandits[actionKey] = ContextualBandit(
                    contextFeatures: context,
                    successCount: priorAlpha,
                    failureCount: priorBeta,
                    lastUpdate: Date(),
                    totalSamples: 0
                )
            }
        }

        // Thompson Sampling: Sample from Beta distribution for each action
        guard let firstAction = actions.first else {
            throw RLError.noValidAction
        }
        var bestAction = firstAction
        var bestConfidence = 0.0
        var bestThompsonSample = 0.0
        var alternatives: [AlternativeAction] = []

        for action in actions {
            let actionKey = ActionIdentifier(action: action, contextHash: contextHash)
            guard let bandit = contextualBandits[actionKey] else { continue }

            // Thompson sampling: sample from Beta distribution
            let thompsonSample = calculateThompsonSample(
                alpha: bandit.successCount,
                beta: bandit.failureCount
            )

            let confidence = calculateConfidence(
                thompsonSample: thompsonSample,
                context: context
            )

            if thompsonSample > bestThompsonSample {
                bestAction = action
                bestConfidence = confidence
                bestThompsonSample = thompsonSample
            }

            alternatives.append(AlternativeAction(
                action: action,
                confidence: confidence
            ))
        }

        return ActionRecommendation(
            action: bestAction,
            confidence: bestConfidence,
            reasoning: "Thompson Sampling Action Selection",
            alternatives: alternatives,
            thompsonSample: bestThompsonSample
        )
    }

    public func updateReward(
        for action: WorkflowAction,
        reward: RewardSignal,
        context: AcquisitionContext
    ) async {
        let actionKey = ActionIdentifier(action: action, contextHash: context.hash)
        let overallReward = calculateTotalReward(reward)

        guard var bandit = contextualBandits[actionKey] else { return }

        if overallReward >= 0.5 {
            // Positive reward: increase success count
            bandit.successCount += overallReward
        } else {
            // Negative reward: increase failure count
            bandit.failureCount += (1.0 - overallReward)
        }

        bandit.totalSamples += 1
        contextualBandits[actionKey] = bandit

        // Persist bandits after update
        try? await persistenceManager.saveBandits(contextualBandits)
    }

    public func getBandits() async -> [ActionIdentifier: ContextualBandit] {
        return contextualBandits
    }

    private func calculateThompsonSample(alpha: Double, beta: Double) -> Double {
        // Use the improved Thompson sampling from ContextualBandit
        let tempBandit = ContextualBandit(
            contextFeatures: FeatureVector(features: [:]),
            successCount: alpha,
            failureCount: beta,
            lastUpdate: Date(),
            totalSamples: Int(alpha + beta)
        )
        return tempBandit.sampleThompson()
    }

    private func calculateConfidence(
        thompsonSample: Double,
        context: FeatureVector
    ) -> Double {
        // Contextual confidence calculation
        let contextFeatures = context.features
        let contextComplexity = contextFeatures["complexity_score"] ?? 0.5
        let historicalSuccess = contextFeatures["historical_success"] ?? 0.5

        return min(
            max(
                thompsonSample * historicalSuccess * (1.0 - contextComplexity),
                0.0
            ),
            1.0
        )
    }

    private func calculateTotalReward(_ reward: RewardSignal) -> Double {
        // Use the standardized calculation from RewardSignal
        return reward.totalReward
    }
}

// MARK: - Supporting Types

public struct ActionRecommendation: Sendable {
    public let action: WorkflowAction
    public let confidence: Double
    public let reasoning: String
    public let alternatives: [AlternativeAction]
    public let thompsonSample: Double

    public init(action: WorkflowAction, confidence: Double, reasoning: String, alternatives: [AlternativeAction], thompsonSample: Double) {
        self.action = action
        self.confidence = confidence
        self.reasoning = reasoning
        self.alternatives = alternatives
        self.thompsonSample = thompsonSample
    }
}

// RLError moved to RLTypes.swift

// MARK: - Mock Persistence Manager

public final class MockRLPersistenceManager: @unchecked Sendable {
    private var storedBandits: [ActionIdentifier: ContextualBandit] = [:]

    public init() {}

    public func saveBandits(_ bandits: [ActionIdentifier: ContextualBandit]) async throws {
        // Mock implementation: Store in memory for testing
        storedBandits = bandits
    }

    public func loadBandits() async throws -> [ActionIdentifier: ContextualBandit] {
        // Mock implementation: Return stored bandits
        return storedBandits
    }
}

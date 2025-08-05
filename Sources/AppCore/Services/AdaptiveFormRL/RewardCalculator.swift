import Foundation

/// Multi-signal reward calculator for reinforcement learning
/// Computes weighted reward signals for Q-learning updates
public enum RewardCalculator {
    // MARK: - Reward Weights

    private static let immediateWeight: Double = 0.4
    private static let delayedWeight: Double = 0.3
    private static let complianceWeight: Double = 0.2
    private static let efficiencyWeight: Double = 0.1

    // MARK: - Main Calculation Method

    /// Calculate multi-signal reward for Q-learning update
    public static func calculate(
        decision: DecisionResponse,
        feedback: RLUserFeedback,
        context: AcquisitionContext
    ) -> RewardSignal {
        // Calculate individual reward components
        let immediateReward = calculateImmediateReward(feedback: feedback)
        let delayedReward = calculateDelayedReward(feedback: feedback)
        let complianceReward = calculateComplianceReward(decision: decision, context: context)
        let efficiencyReward = calculateEfficiencyReward(feedback: feedback, decision: decision)

        // Calculate weighted total reward
        let totalReward = (immediateReward * immediateWeight) +
            (delayedReward * delayedWeight) +
            (complianceReward * complianceWeight) +
            (efficiencyReward * efficiencyWeight)

        return RewardSignal(
            immediateReward: immediateReward,
            delayedReward: delayedReward,
            complianceReward: complianceReward,
            efficiencyReward: efficiencyReward,
            totalReward: min(1.0, max(0.0, totalReward))
        )
    }

    // MARK: - Individual Reward Components

    /// Calculate immediate reward based on user outcome
    private static func calculateImmediateReward(feedback: RLUserFeedback) -> Double {
        switch feedback.outcome {
        case .accepted:
            1.0
        case .acceptedWithModifications:
            0.7
        case .deferred:
            0.3
        case .rejected:
            0.0
        }
    }

    /// Calculate delayed reward based on satisfaction and quality metrics
    private static func calculateDelayedReward(feedback: RLUserFeedback) -> Double {
        var reward = 0.0

        // Base satisfaction component (0.0 to 1.0)
        let satisfactionScore = feedback.satisfactionScore ?? 0.5
        reward += satisfactionScore * 0.5

        // Workflow completion bonus
        if feedback.workflowCompleted {
            reward += 0.2
        }

        // Quality metrics component
        let qualityScore = feedback.qualityMetrics.average
        reward += qualityScore * 0.3

        return min(1.0, max(0.0, reward))
    }

    /// Calculate compliance reward based on regulatory coverage
    private static func calculateComplianceReward(
        decision: DecisionResponse,
        context: AcquisitionContext
    ) -> Double {
        let requiredClauses = context.regulatoryRequirements
        let providedChecks = decision.selectedAction.complianceChecks

        guard !requiredClauses.isEmpty else {
            return 1.0 // No requirements = full compliance
        }

        // Calculate coverage ratio
        let providedClausesSet = Set(providedChecks)
        let requiredClausesSet = Set(requiredClauses)
        let coverage = providedClausesSet.intersection(requiredClausesSet)

        var reward = Double(coverage.count) / Double(requiredClauses.count)

        // Apply penalties for missing critical clauses
        // For simplicity, treat first clause in each requirement as critical
        let criticalClauses = requiredClauses.prefix(1)
        let missedCriticalClauses = criticalClauses.filter { clause in
            !providedClausesSet.contains(clause)
        }

        // Penalty: 0.2 per missing critical clause
        let criticalPenalty = Double(missedCriticalClauses.count) * 0.2
        reward = max(0.0, reward - criticalPenalty)

        return min(1.0, reward)
    }

    /// Calculate efficiency reward based on time performance
    private static func calculateEfficiencyReward(
        feedback: RLUserFeedback,
        decision: DecisionResponse
    ) -> Double {
        guard let timeTaken = feedback.timeTaken else {
            return 0.5 // Default for missing time data
        }

        // Use default expected duration based on action type
        let expectedDuration: TimeInterval = switch decision.selectedAction.actionType {
        case .fieldPopulation:
            2.0 // 2 seconds for field population
        case .contextualSuggestion:
            1.0 // 1 second for suggestions
        case .complianceCheck:
            3.0 // 3 seconds for compliance checks
        }

        if timeTaken <= expectedDuration {
            return 1.0 // On time or faster
        } else {
            // Linear decrease for overtime
            let efficiency = expectedDuration / timeTaken
            return min(1.0, max(0.0, efficiency))
        }
    }
}

/// Multi-component reward signal
public struct RewardSignal {
    public let immediateReward: Double
    public let delayedReward: Double
    public let complianceReward: Double
    public let efficiencyReward: Double
    public let totalReward: Double

    public init(
        immediateReward: Double,
        delayedReward: Double,
        complianceReward: Double,
        efficiencyReward: Double,
        totalReward: Double
    ) {
        self.immediateReward = immediateReward
        self.delayedReward = delayedReward
        self.complianceReward = complianceReward
        self.efficiencyReward = efficiencyReward
        self.totalReward = totalReward
    }
}

/// User feedback for RL learning
public struct RLUserFeedback {
    public let outcome: FeedbackOutcome
    public let satisfactionScore: Double?
    public let workflowCompleted: Bool
    public let qualityMetrics: QualityMetrics
    public let timeTaken: TimeInterval?
    public let comments: String?

    public init(
        outcome: FeedbackOutcome,
        satisfactionScore: Double?,
        workflowCompleted: Bool,
        qualityMetrics: QualityMetrics,
        timeTaken: TimeInterval?,
        comments: String?
    ) {
        self.outcome = outcome
        self.satisfactionScore = satisfactionScore
        self.workflowCompleted = workflowCompleted
        self.qualityMetrics = qualityMetrics
        self.timeTaken = timeTaken
        self.comments = comments
    }
}

/// User feedback outcome types
public enum FeedbackOutcome {
    case accepted
    case acceptedWithModifications
    case deferred
    case rejected
}

/// Quality metrics for decision evaluation
public struct QualityMetrics {
    public let accuracy: Double
    public let completeness: Double
    public let compliance: Double

    public init(accuracy: Double, completeness: Double, compliance: Double) {
        self.accuracy = accuracy
        self.completeness = completeness
        self.compliance = compliance
    }

    /// Average quality score
    public var average: Double {
        (accuracy + completeness + compliance) / 3.0
    }
}

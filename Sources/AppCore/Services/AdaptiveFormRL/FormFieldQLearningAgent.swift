import CoreData
import Foundation
import MLX

/// Q-learning agent for adaptive form field value prediction
/// Implements epsilon-greedy exploration with catastrophic forgetting prevention
public actor FormFieldQLearningAgent {
    // MARK: - Q-Learning Configuration

    private let learningRate: Double = 0.1
    private let discountFactor: Double = 0.95
    private var explorationRate: Double = 0.1
    private let explorationDecay: Double = 0.995
    private let minExplorationRate: Double = 0.01

    // MARK: - Q-Table Storage

    private var qTable: [String: [String: Double]] = [:]
    private let coreDataActor: CoreDataActor

    // MARK: - Catastrophic Forgetting Prevention

    private var importanceWeights: [String: Double] = [:]
    private let ewcLambda: Double = 400.0 // Elastic Weight Consolidation coefficient

    // MARK: - Experience Replay

    private var experienceBuffer: [Experience] = []
    private let bufferSize: Int = 10000
    private let batchSize: Int = 32

    // MARK: - Initialization

    public init(coreDataActor: CoreDataActor) {
        self.coreDataActor = coreDataActor
    }

    // MARK: - Public Q-Learning Interface

    /// Predict optimal value for a form field using Q-learning
    public func predictValue(
        field: FormField,
        context: AcquisitionContext,
        userProfile: UserProfile
    ) -> FieldPrediction {
        let state = createState(field: field, context: context, userProfile: userProfile)
        let stateKey = hashState(state)

        // Epsilon-greedy action selection
        if Double.random(in: 0 ... 1) < explorationRate {
            // Explore: return random action
            let randomValue = generateRandomValue(for: field, context: context)
            return FieldPrediction(
                fieldId: field.name,
                suggestedValue: randomValue,
                confidence: explorationRate,
                reasoning: "Exploring new value"
            )
        } else {
            // Exploit: return best known action
            let bestAction = getBestAction(stateKey: stateKey)
            return FieldPrediction(
                fieldId: field.name,
                suggestedValue: bestAction.value,
                confidence: bestAction.confidence,
                reasoning: "Q-learning prediction based on past experience"
            )
        }
    }

    /// Update Q-value based on user feedback (reward)
    public func updateQValue(state: QLearningState, action: QLearningAction, reward: Double) {
        let stateKey = hashState(state)
        let actionKey = action.value

        // Get current Q-value
        let currentQ = qTable[stateKey]?[actionKey] ?? 0.0

        // Calculate new Q-value using Bellman equation
        // Q(s,a) = Q(s,a) + α[r + γ max Q(s',a') - Q(s,a)]
        let maxFutureQ = getMaxQValue(stateKey: stateKey)
        let newQ = currentQ + learningRate * (reward + discountFactor * maxFutureQ - currentQ)

        // Apply EWC regularization to prevent catastrophic forgetting
        let regularizedQ = applyEWCRegularization(
            stateKey: stateKey,
            actionKey: actionKey,
            newQ: newQ,
            currentQ: currentQ
        )

        // Update Q-table
        if qTable[stateKey] == nil {
            qTable[stateKey] = [:]
        }
        qTable[stateKey]?[actionKey] = regularizedQ

        // Add to experience replay buffer
        let experience = Experience(
            state: state,
            action: action,
            reward: reward,
            timestamp: Date()
        )
        addToExperienceBuffer(experience)

        // Decay exploration rate
        explorationRate = max(minExplorationRate, explorationRate * explorationDecay)

        // Periodically perform experience replay
        if experienceBuffer.count >= batchSize {
            performExperienceReplay()
        }
    }

    /// Learn from user modification patterns
    public func updateFromModification(_ modification: FieldModification, context: AcquisitionContext) {
        // Create reward based on modification type
        let reward = calculateReward(modification: modification)

        // Create Q-learning state and action
        let state = createStateFromModification(modification, context: context)
        let action = QLearningAction(value: modification.modifiedValue, confidence: 1.0)

        // Update Q-value
        updateQValue(state: state, action: action, reward: reward)
    }

    /// Get Q-table size for monitoring
    public func getQTableSize() -> Int {
        qTable.count
    }

    /// Get current exploration rate
    public func getExplorationRate() -> Double {
        explorationRate
    }

    // MARK: - Private Methods

    private func createState(field: FormField, context: AcquisitionContext, userProfile: UserProfile) -> QLearningState {
        // Map FormField.FieldType to FormFieldType
        let mappedFieldType = mapFieldType(field.fieldType)

        // Derive user segment from profile characteristics since UserProfile doesn't have segment property
        let userSegment = deriveUserSegment(from: userProfile)

        return QLearningState(
            fieldType: mappedFieldType,
            contextCategory: context.type,
            userSegment: userSegment,
            temporalContext: getTemporalContext()
        )
    }

    private func createStateFromModification(_: FieldModification, context: AcquisitionContext) -> QLearningState {
        QLearningState(
            fieldType: .textField, // Default for modifications
            contextCategory: context.type,
            userSegment: .standard,
            temporalContext: getTemporalContext()
        )
    }

    private func hashState(_ state: QLearningState) -> String {
        "\(state.fieldType.rawValue)_\(state.contextCategory.rawValue)_\(state.userSegment.rawValue)_\(state.temporalContext.rawValue)"
    }

    private func getBestAction(stateKey: String) -> (value: String, confidence: Double) {
        guard let actions = qTable[stateKey], !actions.isEmpty else {
            return (value: "DEFAULT", confidence: 0.0)
        }

        let bestAction = actions.max { $0.value < $1.value }
        return (
            value: bestAction?.key ?? "DEFAULT",
            confidence: min(1.0, max(0.0, bestAction?.value ?? 0.0))
        )
    }

    private func getMaxQValue(stateKey: String) -> Double {
        guard let actions = qTable[stateKey] else { return 0.0 }
        return actions.values.max() ?? 0.0
    }

    private func generateRandomValue(for field: FormField, context: AcquisitionContext) -> String {
        // Generate contextually appropriate random values
        // Map FieldType to FormFieldType for switch statement
        let mappedType = mapFieldType(field.fieldType)

        switch mappedType {
        case .textField:
            return generateRandomTextValue(context: context)
        case .numberField:
            return "\(Int.random(in: 1 ... 1000))"
        case .emailField:
            return "test@example.com"
        case .phoneField:
            return "(555) 123-4567"
        case .dateField:
            return DateFormatter().string(from: Date())
        }
    }

    private func generateRandomTextValue(context: AcquisitionContext) -> String {
        let commonValues: [String] = switch context.type {
        case .informationTechnology:
            ["NET-30", "Hardware", "Software License", "IT Services"]
        case .construction:
            ["Materials", "Labor", "Equipment Rental", "Construction Services"]
        case .professional:
            ["Consulting", "Professional Services", "Training", "Analysis"]
        }

        return commonValues.randomElement() ?? "Standard"
    }

    private func calculateReward(modification: FieldModification) -> Double {
        // Reward based on user modification patterns
        if modification.originalValue.isEmpty, !modification.modifiedValue.isEmpty {
            1.0 // User filled empty field - positive
        } else if modification.originalValue != modification.modifiedValue {
            -0.5 // User changed our suggestion - negative
        } else {
            0.5 // User kept our suggestion - positive
        }
    }

    private func getTemporalContext() -> TemporalContext {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6 ..< 12:
            return .morning
        case 12 ..< 18:
            return .afternoon
        default:
            return .evening
        }
    }

    /// Map FormField.FieldType to FormFieldType enum used in Q-learning
    private func mapFieldType(_ fieldType: FieldType) -> FormFieldType {
        switch fieldType {
        case .text:
            .textField
        case .number, .currency, .estimatedValue:
            .numberField
        case .date:
            .dateField
        default:
            .textField // Default mapping for unsupported types
        }
    }

    /// Derive user segment from UserProfile since it doesn't have a segment property
    private func deriveUserSegment(from userProfile: UserProfile) -> UserSegment {
        // Simple heuristic based on profile completeness and specializations
        let completionPercentage = userProfile.completionPercentage
        let hasSpecializations = !userProfile.specializations.isEmpty
        let hasCertifications = !userProfile.certifications.isEmpty

        if completionPercentage > 0.8, hasSpecializations, hasCertifications {
            return .expert
        } else if completionPercentage > 0.5, hasSpecializations || hasCertifications {
            return .intermediate
        } else if completionPercentage < 0.3 {
            return .novice
        } else {
            return .standard
        }
    }

    // MARK: - Catastrophic Forgetting Prevention (EWC)

    private func applyEWCRegularization(
        stateKey: String,
        actionKey: String,
        newQ: Double,
        currentQ: Double
    ) -> Double {
        let key = "\(stateKey)_\(actionKey)"
        let importance = importanceWeights[key] ?? 0.0

        // Apply EWC penalty
        let penalty = ewcLambda * importance * pow(newQ - currentQ, 2)
        return newQ - penalty * learningRate
    }

    private func updateImportanceWeights() {
        // Calculate Fisher Information Matrix approximation
        for (stateKey, actions) in qTable {
            for (actionKey, qValue) in actions {
                let key = "\(stateKey)_\(actionKey)"
                let gradient = abs(qValue) // Simplified gradient approximation
                importanceWeights[key] = gradient * gradient
            }
        }
    }

    // MARK: - Experience Replay

    private func addToExperienceBuffer(_ experience: Experience) {
        experienceBuffer.append(experience)

        // Remove oldest experiences if buffer is full
        if experienceBuffer.count > bufferSize {
            experienceBuffer.removeFirst()
        }
    }

    private func performExperienceReplay() {
        guard experienceBuffer.count >= batchSize else { return }

        // Sample random batch from experience buffer
        let batch = Array(experienceBuffer.shuffled().prefix(batchSize))

        // Update Q-values for sampled experiences
        for experience in batch {
            updateQValue(
                state: experience.state,
                action: experience.action,
                reward: experience.reward
            )
        }
    }
}

// MARK: - Supporting Types

public struct QLearningState: Hashable {
    public let fieldType: FormFieldType
    public let contextCategory: ContextCategory
    public let userSegment: UserSegment
    public let temporalContext: TemporalContext

    public init(fieldType: FormFieldType, contextCategory: ContextCategory, userSegment: UserSegment, temporalContext: TemporalContext) {
        self.fieldType = fieldType
        self.contextCategory = contextCategory
        self.userSegment = userSegment
        self.temporalContext = temporalContext
    }
}

public struct QLearningAction {
    public let value: String
    public let confidence: Double

    public init(value: String, confidence: Double) {
        self.value = value
        self.confidence = confidence
    }
}

public enum FormFieldType: String, CaseIterable {
    case textField = "text"
    case numberField = "number"
    case emailField = "email"
    case phoneField = "phone"
    case dateField = "date"
}

public enum ContextCategory: String, CaseIterable, Sendable {
    case informationTechnology = "it"
    case construction
    case professional
}

public enum UserSegment: String, CaseIterable {
    case novice
    case intermediate
    case expert
    case standard
}

public enum TemporalContext: String, CaseIterable {
    case morning
    case afternoon
    case evening
}

private struct Experience {
    let state: QLearningState
    let action: QLearningAction
    let reward: Double
    let timestamp: Date
}

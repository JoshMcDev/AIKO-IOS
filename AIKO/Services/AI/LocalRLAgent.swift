//
//  LocalRLAgent.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Combine
import Foundation
import os.log

/// Local reinforcement learning agent using contextual bandits for acquisition workflow optimization
actor LocalRLAgent {
    // MARK: - Properties

    private let logger = Logger(subsystem: "com.aiko", category: "LocalRLAgent")

    /// Contextual bandit algorithm for decision making
    private let banditAlgorithm: ContextualBandits

    /// Action space for acquisition workflows
    private let actionSpace: AcquisitionActionSpace

    /// State encoder for converting workflow states to feature vectors
    private let stateEncoder: WorkflowStateEncoder

    /// Learning parameters
    private let learningRate: Double = 0.1
    private let explorationRate: Double = 0.15
    private let decayRate: Double = 0.95

    /// Performance tracking
    private var totalDecisions: Int = 0
    private var totalReward: Double = 0.0
    private var recentPerformance: [Double] = []

    /// Context-action-reward history for learning
    private var learningHistory: [LearningRecord] = []

    // MARK: - Initialization

    init() {
        banditAlgorithm = ContextualBandits(
            algorithmType: .thompsonSampling,
            explorationRate: explorationRate
        )
        actionSpace = AcquisitionActionSpace()
        stateEncoder = WorkflowStateEncoder()

        logger.info("LocalRLAgent initialized with Thompson Sampling")
    }

    // MARK: - Public Methods

    /// Get recommendation for given state and context
    func recommend(state: RLState, context: RLContext) async -> RLRecommendation {
        logger.debug("Getting recommendation for state: \(state.phase)")

        // Encode state and context into feature vector
        let features = await stateEncoder.encode(state: state, context: context)

        // Get available actions for current state
        let availableActions = actionSpace.getAvailableActions(for: state)

        // Use contextual bandit to select action
        let selectedAction = await banditAlgorithm.selectAction(
            features: features,
            availableActions: availableActions
        )

        // Calculate confidence based on action selection confidence
        let confidence = await calculateActionConfidence(
            action: selectedAction,
            features: features,
            context: context
        )

        // Generate alternative actions
        let alternatives = await generateAlternatives(
            selectedAction: selectedAction,
            availableActions: availableActions,
            features: features
        )

        let recommendation = await RLRecommendation(
            action: selectedAction,
            confidence: confidence,
            parameters: generateActionParameters(action: selectedAction, context: context),
            reasoning: generateReasoning(action: selectedAction, confidence: confidence, context: context),
            alternatives: alternatives
        )

        logger.info("Generated recommendation: \(selectedAction.type) with confidence: \(confidence)")
        return recommendation
    }

    /// Learn from feedback and update model
    func learn(
        state: RLState,
        action: RLAction,
        reward: Double,
        nextState: RLState?
    ) async {
        logger.debug("Learning from action: \(action.type) with reward: \(reward)")

        // Encode state features
        let features = await stateEncoder.encode(
            state: state,
            context: RLContext.empty() // Context not needed for learning
        )

        // Update contextual bandit model
        await banditAlgorithm.updateModel(
            features: features,
            action: action,
            reward: reward
        )

        // Track performance
        totalDecisions += 1
        totalReward += reward
        recentPerformance.append(reward)

        // Keep recent performance window
        if recentPerformance.count > 100 {
            recentPerformance.removeFirst()
        }

        // Store learning record
        let record = LearningRecord(
            state: state,
            action: action,
            reward: reward,
            nextState: nextState,
            timestamp: Date(),
            features: features
        )
        learningHistory.append(record)

        // Keep history manageable
        if learningHistory.count > 1000 {
            learningHistory.removeFirst()
        }

        logger.info("Model updated with reward: \(reward), total decisions: \(totalDecisions)")
    }

    /// Get current learning progress
    func getLearningProgress() async -> Double {
        guard totalDecisions > 0 else { return 0.0 }

        // Calculate progress based on recent performance improvement
        let recentAverage = recentPerformance.isEmpty ? 0.0 :
            recentPerformance.reduce(0, +) / Double(recentPerformance.count)

        let overallAverage = totalReward / Double(totalDecisions)

        // Progress score combines overall performance with recent improvement
        let performanceScore = min(1.0, max(0.0, (overallAverage + 1.0) / 2.0)) // Normalize from [-1,1] to [0,1]
        let improvementScore = recentPerformance.count >= 10 ?
            calculateImprovementTrend() : 0.5

        let progressScore = (performanceScore * 0.7) + (improvementScore * 0.3)

        logger.debug("Learning progress: \(progressScore) (performance: \(performanceScore), improvement: \(improvementScore))")
        return progressScore
    }

    /// Reset learning state
    func reset() async {
        await banditAlgorithm.reset()
        totalDecisions = 0
        totalReward = 0.0
        recentPerformance.removeAll()
        learningHistory.removeAll()

        logger.info("LocalRLAgent reset complete")
    }

    /// Get learning analytics
    func getAnalytics() async -> RLAnalytics {
        let averageReward = totalDecisions > 0 ? totalReward / Double(totalDecisions) : 0.0
        let recentAverageReward = recentPerformance.isEmpty ? 0.0 :
            recentPerformance.reduce(0, +) / Double(recentPerformance.count)

        let actionDistribution = calculateActionDistribution()
        let statePerformance = calculateStatePerformance()

        return await RLAnalytics(
            totalDecisions: totalDecisions,
            totalReward: totalReward,
            averageReward: averageReward,
            recentAverageReward: recentAverageReward,
            learningProgress: getLearningProgress(),
            actionDistribution: actionDistribution,
            statePerformance: statePerformance,
            explorationRate: explorationRate
        )
    }

    // MARK: - Private Methods

    private func calculateActionConfidence(
        action: RLAction,
        features: [Double],
        context: RLContext
    ) async -> Double {
        // Base confidence from bandit algorithm
        let banditConfidence = await banditAlgorithm.getActionConfidence(
            action: action,
            features: features
        )

        // Context-based confidence adjustments
        var confidence = banditConfidence

        // Adjust confidence based on context factors
        if context.patterns.confidence > 0.8 {
            confidence += 0.1 // Boost confidence for high-pattern-confidence contexts
        }

        if context.complexity > 0.7 {
            confidence -= 0.15 // Reduce confidence for high-complexity scenarios
        }

        if context.risk.rawValue > 0.6 {
            confidence -= 0.2 // Reduce confidence for high-risk situations
        }

        // Historical performance adjustment
        if totalDecisions > 10 {
            let recentAverage = recentPerformance.suffix(10).reduce(0, +) / 10.0
            if recentAverage > 0.5 {
                confidence += 0.05 // Slight boost for recent good performance
            } else if recentAverage < -0.5 {
                confidence -= 0.05 // Slight reduction for recent poor performance
            }
        }

        return min(1.0, max(0.0, confidence))
    }

    private func generateActionParameters(
        action: RLAction,
        context: RLContext
    ) async -> [String: Any] {
        var parameters: [String: Any] = [:]

        switch action.type {
        case .fillField:
            parameters["confidence"] = await calculateActionConfidence(
                action: action,
                features: [],
                context: context
            )
            if let patterns = context.patterns.patterns.first(where: { $0.type == .fieldValues }) {
                parameters["suggestedValue"] = patterns.value
                parameters["basedOnPatterns"] = true
            }

        case .generateDocument:
            parameters["templateType"] = context.patterns.patterns.contains { $0.type == .formFilling } ?
                "learned_template" : "standard_template"

        case .suggestWorkflowStep:
            if let workflowPatterns = context.patterns.patterns.first(where: { $0.type == .workflowSequence }) {
                parameters["nextSteps"] = workflowPatterns.value
                parameters["confidence"] = workflowPatterns.confidence
            }

        case .requestManualInput:
            parameters["reason"] = "Low confidence or high complexity scenario"
            parameters["alternatives"] = await generateAlternatives(
                selectedAction: action,
                availableActions: actionSpace.getAllActions(),
                features: []
            ).map(\.type.rawValue)

        case .validateCompliance:
            parameters["checkLevel"] = context.risk.rawValue > 0.5 ? "thorough" : "standard"

        case .optimizeWorkflow:
            parameters["optimizationType"] = "efficiency"
            parameters["expectedImprovement"] = "15-30%"
        }

        return parameters
    }

    private func generateReasoning(
        action: RLAction,
        confidence: Double,
        context: RLContext
    ) -> String {
        var reasoning = "Selected action: \(action.type.rawValue) "
        reasoning += "with \(Int(confidence * 100))% confidence. "

        if !context.patterns.patterns.isEmpty {
            reasoning += "Based on \(context.patterns.patterns.count) learned patterns. "
        }

        if confidence > 0.8 {
            reasoning += "High confidence due to consistent historical patterns."
        } else if confidence > 0.6 {
            reasoning += "Medium confidence, recommend user review."
        } else {
            reasoning += "Low confidence, manual input suggested."
        }

        return reasoning
    }

    private func generateAlternatives(
        selectedAction: RLAction,
        availableActions: [RLAction],
        features: [Double]
    ) async -> [RLAction] {
        // Get top 3 alternative actions excluding the selected one
        var alternatives: [RLAction] = []

        for action in availableActions where action.id != selectedAction.id {
            let confidence = await banditAlgorithm.getActionConfidence(
                action: action,
                features: features
            )
            alternatives.append(action)
        }

        // Sort by confidence and return top 3
        alternatives.sort {
            await banditAlgorithm.getActionConfidence(action: $0, features: features) >
                await banditAlgorithm.getActionConfidence(action: $1, features: features)
        }

        return Array(alternatives.prefix(3))
    }

    private func calculateImprovementTrend() -> Double {
        guard recentPerformance.count >= 10 else { return 0.5 }

        let firstHalf = recentPerformance.prefix(recentPerformance.count / 2)
        let secondHalf = recentPerformance.suffix(recentPerformance.count / 2)

        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let improvement = secondAverage - firstAverage

        // Normalize improvement to [0, 1] range
        return min(1.0, max(0.0, 0.5 + improvement))
    }

    private func calculateActionDistribution() -> [String: Double] {
        var distribution: [String: Int] = [:]

        for record in learningHistory {
            let actionType = record.action.type.rawValue
            distribution[actionType, default: 0] += 1
        }

        let total = learningHistory.count
        guard total > 0 else { return [:] }

        return distribution.mapValues { Double($0) / Double(total) }
    }

    private func calculateStatePerformance() -> [String: Double] {
        var stateRewards: [String: [Double]] = [:]

        for record in learningHistory {
            let stateKey = record.state.phase
            stateRewards[stateKey, default: []].append(record.reward)
        }

        return stateRewards.mapValues { rewards in
            rewards.reduce(0, +) / Double(rewards.count)
        }
    }
}

// MARK: - Supporting Types

/// Reinforcement Learning State representation
struct RLState {
    let phase: String
    let documentType: String?
    let completedSteps: [String]
    let pendingSteps: [String]
    let context: [String: Any]
    let complexity: Double
    let userExperience: Double

    init(from _: AcquisitionWorkflowState?, request: DecisionRequest) {
        phase = request.workflowPhase ?? "unknown"
        documentType = request.documentType
        completedSteps = request.completedSteps
        pendingSteps = request.pendingSteps
        context = request.context

        // Calculate complexity based on context
        complexity = RLState.calculateComplexity(from: request)

        // Estimate user experience (could be enhanced with actual user data)
        userExperience = 0.5 // Default neutral experience
    }

    private static func calculateComplexity(from request: DecisionRequest) -> Double {
        var complexity = 0.0

        // Document type complexity
        switch request.documentType {
        case "SF-1449": complexity += 0.3
        case "Contract": complexity += 0.7
        case "RFP": complexity += 0.8
        default: complexity += 0.4
        }

        // Step count complexity
        let totalSteps = request.completedSteps.count + request.pendingSteps.count
        complexity += min(0.3, Double(totalSteps) / 20.0)

        return min(1.0, complexity)
    }
}

/// Reinforcement Learning Context
struct RLContext {
    let patterns: LearnedPreferences
    let complexity: Double
    let risk: RiskLevel
    let timeContext: TimeOfDay

    static func empty() -> RLContext {
        RLContext(
            patterns: LearnedPreferences(patterns: [], confidence: 0.0),
            complexity: 0.0,
            risk: .low,
            timeContext: .morning
        )
    }
}

/// RL Action representation
struct RLAction {
    let id: UUID
    let type: RLActionType
    let parameters: [String: Any]
    let description: String

    init(type: RLActionType, parameters: [String: Any] = [:]) {
        id = UUID()
        self.type = type
        self.parameters = parameters
        description = type.description
    }
}

enum RLActionType: String, CaseIterable {
    case fillField = "fill_field"
    case generateDocument = "generate_document"
    case suggestWorkflowStep = "suggest_workflow_step"
    case requestManualInput = "request_manual_input"
    case validateCompliance = "validate_compliance"
    case optimizeWorkflow = "optimize_workflow"

    var description: String {
        switch self {
        case .fillField: "Auto-fill form field based on patterns"
        case .generateDocument: "Generate document from template"
        case .suggestWorkflowStep: "Suggest next workflow step"
        case .requestManualInput: "Request manual user input"
        case .validateCompliance: "Validate regulatory compliance"
        case .optimizeWorkflow: "Optimize workflow efficiency"
        }
    }
}

/// RL Recommendation from agent
struct RLRecommendation {
    let action: RLAction
    let confidence: Double
    let parameters: [String: Any]
    let reasoning: String
    let alternatives: [RLAction]
}

/// Learning record for tracking
struct LearningRecord {
    let state: RLState
    let action: RLAction
    let reward: Double
    let nextState: RLState?
    let timestamp: Date
    let features: [Double]
}

/// Analytics for learning performance
struct RLAnalytics {
    let totalDecisions: Int
    let totalReward: Double
    let averageReward: Double
    let recentAverageReward: Double
    let learningProgress: Double
    let actionDistribution: [String: Double]
    let statePerformance: [String: Double]
    let explorationRate: Double
}

// MARK: - Contextual Bandits Implementation

actor ContextualBandits {
    enum AlgorithmType {
        case thompsonSampling
        case upperConfidenceBound
        case epsilonGreedy
    }

    private let algorithmType: AlgorithmType
    private let explorationRate: Double
    private var actionModels: [String: ActionModel] = [:]

    init(algorithmType: AlgorithmType, explorationRate: Double) {
        self.algorithmType = algorithmType
        self.explorationRate = explorationRate
    }

    func selectAction(features: [Double], availableActions: [RLAction]) async -> RLAction {
        switch algorithmType {
        case .thompsonSampling:
            await thompsonSamplingSelection(features: features, actions: availableActions)
        case .upperConfidenceBound:
            await ucbSelection(features: features, actions: availableActions)
        case .epsilonGreedy:
            await epsilonGreedySelection(features: features, actions: availableActions)
        }
    }

    func updateModel(features: [Double], action: RLAction, reward: Double) async {
        let actionKey = action.type.rawValue
        if actionModels[actionKey] == nil {
            actionModels[actionKey] = ActionModel()
        }

        actionModels[actionKey]?.update(features: features, reward: reward)
    }

    func getActionConfidence(action: RLAction, features: [Double]) async -> Double {
        let actionKey = action.type.rawValue
        guard let model = actionModels[actionKey] else { return 0.5 }

        return model.getConfidence(features: features)
    }

    func reset() async {
        actionModels.removeAll()
    }

    // MARK: - Algorithm Implementations

    private func thompsonSamplingSelection(features: [Double], actions: [RLAction]) async -> RLAction {
        guard let firstAction = actions.first else {
            fatalError("Actions array cannot be empty for Thompson sampling")
        }
        var bestAction = firstAction
        var bestSample = -Double.infinity

        for action in actions {
            let actionKey = action.type.rawValue
            let model = actionModels[actionKey] ?? ActionModel()
            let sample = model.sampleReward(features: features)

            if sample > bestSample {
                bestSample = sample
                bestAction = action
            }
        }

        return bestAction
    }

    private func ucbSelection(features: [Double], actions: [RLAction]) async -> RLAction {
        guard let firstAction = actions.first else {
            fatalError("Actions array cannot be empty for UCB selection")
        }
        var bestAction = firstAction
        var bestUCB = -Double.infinity

        let totalTrials = actionModels.values.reduce(0) { $0 + $1.trialCount }

        for action in actions {
            let actionKey = action.type.rawValue
            let model = actionModels[actionKey] ?? ActionModel()

            let meanReward = model.getMeanReward(features: features)
            let confidence = totalTrials > 0 ?
                sqrt(2 * log(Double(totalTrials)) / Double(max(1, model.trialCount))) : 1.0

            let ucb = meanReward + confidence

            if ucb > bestUCB {
                bestUCB = ucb
                bestAction = action
            }
        }

        return bestAction
    }

    private func epsilonGreedySelection(features: [Double], actions: [RLAction]) async -> RLAction {
        // Exploration vs exploitation
        if Double.random(in: 0 ... 1) < explorationRate {
            // Explore: random action
            guard let randomAction = actions.randomElement() else {
                fatalError("Actions array cannot be empty for epsilon-greedy exploration")
            }
            return randomAction
        } else {
            // Exploit: best known action
            guard let firstAction = actions.first else {
                fatalError("Actions array cannot be empty for epsilon-greedy exploitation")
            }
            var bestAction = firstAction
            var bestReward = -Double.infinity

            for action in actions {
                let actionKey = action.type.rawValue
                let model = actionModels[actionKey] ?? ActionModel()
                let expectedReward = model.getMeanReward(features: features)

                if expectedReward > bestReward {
                    bestReward = expectedReward
                    bestAction = action
                }
            }

            return bestAction
        }
    }
}

// MARK: - Action Model for Contextual Bandits

class ActionModel {
    private var rewards: [Double] = []
    private var features: [[Double]] = []
    private(set) var trialCount: Int = 0

    func update(features: [Double], reward: Double) {
        self.features.append(features)
        rewards.append(reward)
        trialCount += 1
    }

    func getMeanReward(features _: [Double]) -> Double {
        guard !rewards.isEmpty else { return 0.0 }

        // Simple average for now - could be enhanced with feature similarity weighting
        return rewards.reduce(0, +) / Double(rewards.count)
    }

    func getConfidence(features: [Double]) -> Double {
        guard trialCount > 0 else { return 0.0 }

        // Confidence based on trial count and reward variance
        let meanReward = getMeanReward(features: features)
        let variance = rewards.map { pow($0 - meanReward, 2) }.reduce(0, +) / Double(rewards.count)

        // Higher trial count and lower variance = higher confidence
        let trialConfidence = min(1.0, Double(trialCount) / 20.0) // Normalize trial count
        let varianceConfidence = 1.0 / (1.0 + variance) // Lower variance = higher confidence

        return (trialConfidence + varianceConfidence) / 2.0
    }

    func sampleReward(features: [Double]) -> Double {
        guard trialCount > 0 else { return Double.random(in: -1 ... 1) }

        let mean = getMeanReward(features: features)
        let variance = rewards.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rewards.count)
        let stdDev = sqrt(variance + 0.1) // Add small constant for numerical stability

        // Sample from normal distribution
        return mean + stdDev * Double.random(in: -2 ... 2) // Approximate normal distribution
    }
}

// MARK: - Action Space Definition

struct AcquisitionActionSpace {
    private let allActions: [RLAction] = [
        RLAction(type: .fillField),
        RLAction(type: .generateDocument),
        RLAction(type: .suggestWorkflowStep),
        RLAction(type: .requestManualInput),
        RLAction(type: .validateCompliance),
        RLAction(type: .optimizeWorkflow),
    ]

    func getAllActions() -> [RLAction] {
        allActions
    }

    func getAvailableActions(for state: RLState) -> [RLAction] {
        // Filter actions based on current state
        var availableActions: [RLAction] = []

        // Always available actions
        availableActions.append(contentsOf: [
            RLAction(type: .requestManualInput),
            RLAction(type: .validateCompliance),
        ])

        // Phase-specific actions
        switch state.phase.lowercased() {
        case "planning", "requirements":
            availableActions.append(RLAction(type: .generateDocument))
            availableActions.append(RLAction(type: .suggestWorkflowStep))

        case "execution", "implementation":
            availableActions.append(RLAction(type: .fillField))
            availableActions.append(RLAction(type: .optimizeWorkflow))

        case "review", "approval":
            availableActions.append(RLAction(type: .validateCompliance))

        default:
            // Default available actions for unknown phases
            availableActions.append(RLAction(type: .fillField))
            availableActions.append(RLAction(type: .suggestWorkflowStep))
        }

        return availableActions
    }
}

// MARK: - State Encoder

actor WorkflowStateEncoder {
    func encode(state: RLState, context: RLContext) async -> [Double] {
        var features: [Double] = []

        // Phase encoding (one-hot)
        let phases = ["planning", "requirements", "execution", "implementation", "review", "approval"]
        for phase in phases {
            features.append(state.phase.lowercased().contains(phase) ? 1.0 : 0.0)
        }

        // Document type encoding
        let documentTypes = ["sf-1449", "contract", "rfp", "statement"]
        for docType in documentTypes {
            features.append(state.documentType?.lowercased().contains(docType) == true ? 1.0 : 0.0)
        }

        // Numerical features
        features.append(state.complexity)
        features.append(state.userExperience)
        features.append(Double(state.completedSteps.count))
        features.append(Double(state.pendingSteps.count))

        // Context features
        features.append(context.patterns.confidence)
        features.append(context.complexity)
        features.append(context.risk.rawValue)
        features.append(Double(context.timeContext.rawValue))

        return features
    }
}

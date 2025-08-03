//
//  AgenticOrchestrator.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Combine
import Foundation
import os.log

/// Central orchestrator for agentic behavior and reinforcement learning
actor AgenticOrchestrator {
    // MARK: - Properties

    private let logger = Logger(subsystem: "com.aiko", category: "AgenticOrchestrator")

    /// Local reinforcement learning agent
    private let localRLAgent: LocalRLAgent

    /// Existing learning services integration
    private let patternRecognizer: PatternRecognitionAlgorithm
    private let userPatternEngine: UserPatternLearningEngine
    private let feedbackLoop: LearningFeedbackLoop

    /// State tracking for acquisition workflows
    private var currentWorkflowState: AcquisitionWorkflowState?

    /// Confidence thresholds for decision making
    private let autonomousThreshold: Double = 0.85
    private let assistedThreshold: Double = 0.65

    /// Action history for learning
    private var actionHistory: [AgenticAction] = []

    /// Decision statistics
    private var decisionStats = DecisionStatistics()

    // MARK: - Initialization

    init() {
        self.localRLAgent = LocalRLAgent()
        self.patternRecognizer = PatternRecognitionAlgorithm()
        self.userPatternEngine = UserPatternLearningEngine.shared
        self.feedbackLoop = LearningFeedbackLoop()

        logger.info("AgenticOrchestrator initialized with autonomous threshold: \(autonomousThreshold)")
    }

    // MARK: - Public Methods

    /// Process a decision request with agentic behavior
    func processDecisionRequest(_ request: DecisionRequest) async -> AgenticDecision {
        logger.debug("Processing decision request: \(request.type)")

        // Update current workflow state
        await updateWorkflowState(from: request)

        // Analyze context and get confidence
        let contextAnalysis = await analyzeDecisionContext(request)

        // Get recommendation from local RL agent
        let rlRecommendation = await localRLAgent.recommend(
            state: contextAnalysis.state,
            context: contextAnalysis.context
        )

        // Combine with pattern recognition insights
        let patternInsights = await patternRecognizer.analyze(
            interaction: contextAnalysis.toUserInteraction(),
            historicalData: await getHistoricalInteractions()
        )

        // Make agentic decision based on confidence levels
        let decision = await makeAgenticDecision(
            request: request,
            rlRecommendation: rlRecommendation,
            patternInsights: patternInsights,
            contextAnalysis: contextAnalysis
        )

        // Record action for learning
        let action = AgenticAction(
            id: UUID(),
            request: request,
            decision: decision,
            timestamp: Date(),
            confidence: decision.confidence,
            outcome: nil // Will be updated when feedback is received
        )

        actionHistory.append(action)

        // Update statistics
        updateDecisionStatistics(decision)

        logger.info("Generated agentic decision with confidence: \(decision.confidence)")
        return decision
    }

    /// Apply feedback to improve future decisions
    func applyFeedback(_ feedback: AgenticFeedback) async {
        logger.debug("Applying agentic feedback: \(feedback.type)")

        // Find the related action
        if let actionIndex = actionHistory.firstIndex(where: { $0.id == feedback.actionId }) {
            var action = actionHistory[actionIndex]
            action.outcome = feedback.toOutcome()
            actionHistory[actionIndex] = action

            // Calculate reward for RL agent
            let reward = calculateReward(feedback: feedback, action: action)

            // Train the RL agent
            await localRLAgent.learn(
                state: action.toState(),
                action: action.toRLAction(),
                reward: reward,
                nextState: feedback.resultingState
            )

            // Apply feedback to existing learning systems
            await feedbackLoop.applyReinforcement(for: action.id, reward: reward)
        }

        logger.info("Applied feedback with reward calculation")
    }

    /// Get current agentic performance metrics
    func getPerformanceMetrics() async -> AgenticPerformanceMetrics {
        let recentActions = actionHistory.suffix(100)

        let autonomousCount = recentActions.filter { $0.decision.type == .autonomous }.count
        let assistedCount = recentActions.filter { $0.decision.type == .assisted }.count
        let manualCount = recentActions.filter { $0.decision.type == .manual }.count

        let successfulActions = recentActions.filter {
            if case .success = $0.outcome { return true }
            return false
        }.count

        let averageConfidence = recentActions.map { $0.confidence }.reduce(0, +) / Double(max(1, recentActions.count))

        return AgenticPerformanceMetrics(
            autonomousDecisionRate: Double(autonomousCount) / Double(max(1, recentActions.count)),
            assistedDecisionRate: Double(assistedCount) / Double(max(1, recentActions.count)),
            manualDecisionRate: Double(manualCount) / Double(max(1, recentActions.count)),
            successRate: Double(successfulActions) / Double(max(1, recentActions.count)),
            averageConfidence: averageConfidence,
            totalDecisions: recentActions.count,
            learningProgress: await localRLAgent.getLearningProgress()
        )
    }

    /// Reset learning state (for testing or user preference)
    func resetLearningState() async {
        await localRLAgent.reset()
        actionHistory.removeAll()
        decisionStats = DecisionStatistics()
        currentWorkflowState = nil

        logger.info("Reset agentic learning state")
    }


    // MARK: - Private Methods

    private func updateWorkflowState(from request: DecisionRequest) async {
        currentWorkflowState = AcquisitionWorkflowState(
            phase: request.workflowPhase,
            documentType: request.documentType,
            completedSteps: request.completedSteps,
            pendingSteps: request.pendingSteps,
            context: request.context
        )
    }

    private func analyzeDecisionContext(_ request: DecisionRequest) async -> DecisionContextAnalysis {
        // Analyze the current context for decision making
        let historicalPatterns = await userPatternEngine.getLearnedPreferences(
            for: PatternContext(
                formType: request.formType,
                documentType: request.documentType,
                workflowPhase: request.workflowPhase,
                timeOfDay: TimeOfDay(from: Date())
            )
        )

        let complexityScore = calculateComplexityScore(request)
        let riskLevel = assessRiskLevel(request)

        return DecisionContextAnalysis(
            request: request,
            state: RLState(from: currentWorkflowState, request: request),
            context: RLContext(
                patterns: historicalPatterns,
                complexity: complexityScore,
                risk: riskLevel,
                timeContext: TimeOfDay(from: Date())
            ),
            historicalPatterns: historicalPatterns,
            complexityScore: complexityScore,
            riskLevel: riskLevel
        )
    }

    private func makeAgenticDecision(
        request: DecisionRequest,
        rlRecommendation: RLRecommendation,
        patternInsights: [UserPattern],
        contextAnalysis: DecisionContextAnalysis
    ) async -> AgenticDecision {

        // Combine different confidence sources
        let combinedConfidence = combineConfidenceScores(
            rlConfidence: rlRecommendation.confidence,
            patternConfidence: contextAnalysis.historicalPatterns.confidence,
            contextConfidenceBonus: calculateContextBonus(contextAnalysis)
        )

        // Determine decision type based on confidence thresholds
        let decisionType: AgenticDecisionType
        let recommendation: AgenticRecommendation

        if combinedConfidence >= autonomousThreshold && contextAnalysis.riskLevel.rawValue <= RiskLevel.medium.rawValue {
            // High confidence, low-medium risk - make autonomous decision
            decisionType = .autonomous
            recommendation = AgenticRecommendation(
                action: rlRecommendation.action,
                parameters: rlRecommendation.parameters,
                reasoning: generateAutonomousReasoning(rlRecommendation, patternInsights),
                confidence: combinedConfidence,
                alternatives: rlRecommendation.alternatives
            )
        } else if combinedConfidence >= assistedThreshold {
            // Medium confidence - provide assisted recommendation
            decisionType = .assisted
            recommendation = AgenticRecommendation(
                action: rlRecommendation.action,
                parameters: rlRecommendation.parameters,
                reasoning: generateAssistedReasoning(rlRecommendation, patternInsights, contextAnalysis),
                confidence: combinedConfidence,
                alternatives: rlRecommendation.alternatives
            )
        } else {
            // Low confidence - defer to manual decision
            decisionType = .manual
            recommendation = AgenticRecommendation(
                action: .requestManualInput,
                parameters: [:],
                reasoning: generateManualReasoning(contextAnalysis),
                confidence: combinedConfidence,
                alternatives: rlRecommendation.alternatives
            )
        }

        return AgenticDecision(
            id: UUID(),
            type: decisionType,
            recommendation: recommendation,
            confidence: combinedConfidence,
            reasoning: recommendation.reasoning,
            timestamp: Date(),
            request: request
        )
    }

    private func combineConfidenceScores(
        rlConfidence: Double,
        patternConfidence: Double,
        contextConfidenceBonus: Double
    ) -> Double {
        // Weighted combination of confidence sources
        let baseConfidence = (rlConfidence * 0.5) + (patternConfidence * 0.3) + (contextConfidenceBonus * 0.2)
        return min(1.0, max(0.0, baseConfidence))
    }

    private func calculateContextBonus(_ analysis: DecisionContextAnalysis) -> Double {
        var bonus = 0.5 // Base bonus

        // Time of day bonus (if user has consistent patterns)
        if analysis.historicalPatterns.patterns.contains(where: { $0.type == .timeOfDay }) {
            bonus += 0.1
        }

        // Workflow phase bonus (if in familiar phase)
        if analysis.historicalPatterns.patterns.contains(where: { $0.type == .workflowSequence }) {
            bonus += 0.15
        }

        // Risk adjustment (lower bonus for higher risk)
        bonus *= (1.0 - (analysis.riskLevel.rawValue * 0.1))

        return min(1.0, max(0.0, bonus))
    }

    private func calculateComplexityScore(_ request: DecisionRequest) -> Double {
        var complexity = 0.0

        // Document type complexity
        switch request.documentType {
        case "SF-1449": complexity += 0.3
        case "Contract": complexity += 0.7
        case "RFP": complexity += 0.8
        default: complexity += 0.4
        }

        // Field count complexity
        let fieldCount = request.context["fieldCount"] as? Int ?? 0
        complexity += min(0.3, Double(fieldCount) / 100.0)

        // Dependency complexity
        let dependencyCount = request.completedSteps.count + request.pendingSteps.count
        complexity += min(0.2, Double(dependencyCount) / 20.0)

        return min(1.0, complexity)
    }

    private func assessRiskLevel(_ request: DecisionRequest) -> RiskLevel {
        let criticalFields = ["estimatedValue", "fundingSource", "contractType", "vendorUEI"]
        let hasCriticalFields = criticalFields.contains { request.context.keys.contains($0) }

        if hasCriticalFields {
            return .high
        } else if request.documentType == "Contract" {
            return .medium
        } else {
            return .low
        }
    }

    private func generateAutonomousReasoning(
        _ rlRecommendation: RLRecommendation,
        _ patterns: [UserPattern]
    ) -> String {
        var reasoning = "Autonomous decision based on: "
        reasoning += "• High confidence RL recommendation (\(Int(rlRecommendation.confidence * 100))%) "

        if !patterns.isEmpty {
            reasoning += "• Consistent with \(patterns.count) historical patterns "
        }

        reasoning += "• Low risk context allows autonomous execution"
        return reasoning
    }

    private func generateAssistedReasoning(
        _ rlRecommendation: RLRecommendation,
        _ patterns: [UserPattern],
        _ context: DecisionContextAnalysis
    ) -> String {
        var reasoning = "Assisted recommendation: "
        reasoning += "• RL suggestion: \(rlRecommendation.action.description) "
        reasoning += "• Confidence: \(Int(rlRecommendation.confidence * 100))% "
        reasoning += "• Risk level: \(context.riskLevel) "

        if !patterns.isEmpty {
            reasoning += "• Based on \(patterns.count) similar patterns"
        }

        return reasoning
    }

    private func generateManualReasoning(_ context: DecisionContextAnalysis) -> String {
        return "Manual input recommended due to: low confidence (\(Int(context.combinedConfidence * 100))%), high complexity (\(Int(context.complexityScore * 100))%), or insufficient historical data"
    }

    private func calculateReward(feedback: AgenticFeedback, action: AgenticAction) -> Double {
        switch feedback.type {
        case .accepted:
            return 1.0
        case .modified:
            return 0.5
        case .rejected:
            return -0.5
        case .error:
            return -1.0
        }
    }

    private func updateDecisionStatistics(_ decision: AgenticDecision) {
        decisionStats.totalDecisions += 1

        switch decision.type {
        case .autonomous:
            decisionStats.autonomousDecisions += 1
        case .assisted:
            decisionStats.assistedDecisions += 1
        case .manual:
            decisionStats.manualDecisions += 1
        }

        decisionStats.averageConfidence =
            (decisionStats.averageConfidence * Double(decisionStats.totalDecisions - 1) + decision.confidence) /
            Double(decisionStats.totalDecisions)
    }

    private func getHistoricalInteractions() async -> [UserInteraction] {
        // Convert action history to user interactions for pattern analysis
        return actionHistory.map { action in
            UserInteraction(
                id: action.id,
                type: "agentic_decision",
                timestamp: action.timestamp,
                metadata: [
                    "decisionType": action.decision.type.rawValue,
                    "confidence": action.confidence,
                    "documentType": action.request.documentType ?? "",
                    "workflowPhase": action.request.workflowPhase ?? ""
                ]
            )
        }
    }
}

// MARK: - Supporting Types

struct DecisionRequest {
    let id: UUID
    let type: String
    let documentType: String?
    let formType: String?
    let workflowPhase: String?
    let completedSteps: [String]
    let pendingSteps: [String]
    let context: [String: Any]
    let timestamp: Date
}

struct AgenticDecision {
    let id: UUID
    let type: AgenticDecisionType
    let recommendation: AgenticRecommendation
    let confidence: Double
    let reasoning: String
    let timestamp: Date
    let request: DecisionRequest
}

enum AgenticDecisionType: String {
    case autonomous = "autonomous"
    case assisted = "assisted"
    case manual = "manual"
}

struct AgenticRecommendation {
    let action: RLAction
    let parameters: [String: Any]
    let reasoning: String
    let confidence: Double
    let alternatives: [RLAction]
}

struct AgenticAction {
    let id: UUID
    let request: DecisionRequest
    let decision: AgenticDecision
    let timestamp: Date
    let confidence: Double
    var outcome: AgenticOutcome?

    func toState() -> RLState {
        return RLState(from: nil, request: request)
    }

    func toRLAction() -> RLAction {
        return decision.recommendation.action
    }
}

enum AgenticOutcome {
    case success(reward: Double)
    case failure(penalty: Double)
    case partial(reward: Double)
}

struct AgenticFeedback {
    let id: UUID
    let actionId: UUID
    let type: AgenticFeedbackType
    let resultingState: RLState?
    let timestamp: Date
    let userComment: String?

    func toOutcome() -> AgenticOutcome {
        switch type {
        case .accepted:
            return .success(reward: 1.0)
        case .modified:
            return .partial(reward: 0.5)
        case .rejected:
            return .failure(penalty: -0.5)
        case .error:
            return .failure(penalty: -1.0)
        }
    }
}

enum AgenticFeedbackType {
    case accepted
    case modified
    case rejected
    case error
}

struct AcquisitionWorkflowState {
    let phase: String?
    let documentType: String?
    let completedSteps: [String]
    let pendingSteps: [String]
    let context: [String: Any]
}

struct DecisionContextAnalysis {
    let request: DecisionRequest
    let state: RLState
    let context: RLContext
    let historicalPatterns: LearnedPreferences
    let complexityScore: Double
    let riskLevel: RiskLevel
    var combinedConfidence: Double = 0.0

    func toUserInteraction() -> UserInteraction {
        return UserInteraction(
            id: request.id,
            type: "decision_context",
            timestamp: request.timestamp,
            metadata: [
                "complexity": complexityScore,
                "risk": riskLevel.rawValue,
                "documentType": request.documentType ?? "",
                "workflowPhase": request.workflowPhase ?? ""
            ]
        )
    }
}

enum RiskLevel: Double {
    case low = 0.2
    case medium = 0.5
    case high = 0.8
    case critical = 1.0
}

struct DecisionStatistics {
    var totalDecisions: Int = 0
    var autonomousDecisions: Int = 0
    var assistedDecisions: Int = 0
    var manualDecisions: Int = 0
    var averageConfidence: Double = 0.0
}

struct AgenticPerformanceMetrics {
    let autonomousDecisionRate: Double
    let assistedDecisionRate: Double
    let manualDecisionRate: Double
    let successRate: Double
    let averageConfidence: Double
    let totalDecisions: Int
    let learningProgress: Double
}

// MARK: - Extensions

extension DecisionContextAnalysis {
    var combinedConfidence: Double {
        return (context.patterns.confidence * 0.4) +
               (historicalPatterns.confidence * 0.3) +
               ((1.0 - complexityScore) * 0.2) +
               ((1.0 - riskLevel.rawValue) * 0.1)
    }
}

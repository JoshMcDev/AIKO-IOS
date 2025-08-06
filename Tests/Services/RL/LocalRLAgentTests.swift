@testable import AIKO
import Foundation
import XCTest

/// Comprehensive test suite for LocalRLAgent with Contextual Multi-Armed Bandits
/// Testing Thompson Sampling algorithm with statistical validation
///
/// Statistical Testing Layers:
/// 1. Thompson Sampling convergence validation
/// 2. Beta distribution posterior updates
/// 3. Contextual bandit learning
/// 4. Exploration vs exploitation balance
final class LocalRLAgentTests: XCTestCase {
    // MARK: - Test Properties

    var rlAgent: LocalRLAgent?
    var mockPersistenceManager: MockRLPersistenceManager?
    var statisticalValidator: StatisticalTestFramework?
    var testContext: FeatureVector?
    var standardActions: [WorkflowAction]?

    override func setUp() async throws {
        mockPersistenceManager = MockRLPersistenceManager()
        statisticalValidator = StatisticalTestFramework()

        // Create test feature vector
        testContext = FeatureVector(features: [
            "docType_requestForProposal": 1.0,
            "value_normalized": 0.5,
            "complexity_score": 0.5,
            "historical_success": 0.8,
            "time_pressure": 0.5,
            "experience_level": 0.7,
        ])

        // Create standard actions for testing
        let sampleFarClause = AgenticFARClause(
            section: "52.215-1",
            title: "Instructions to Offerors—Competitive Acquisition",
            description: "Test FAR clause for compliance testing"
        )
        let sampleComplianceCheck = ComplianceCheck(
            farClause: sampleFarClause,
            requirement: "Test compliance requirement",
            severity: .major,
            automated: true
        )
        let sampleDocumentTemplate = AgenticDocumentTemplate(
            name: "Purchase Request Template",
            templateType: .requestForProposal,
            requiredFields: ["vendor", "amount", "description"],
            complianceRequirements: [sampleComplianceCheck]
        )

        standardActions = [
            WorkflowAction(
                actionType: .generateDocument,
                documentTemplates: [sampleDocumentTemplate],
                automationLevel: .automated,
                complianceChecks: [sampleComplianceCheck],
                estimatedDuration: 300.0
            ),
            WorkflowAction(
                actionType: .requestApproval,
                documentTemplates: [],
                automationLevel: .assisted,
                complianceChecks: [sampleComplianceCheck],
                estimatedDuration: 600.0
            ),
        ]

        // Initialize RL agent
        guard let mockPersistenceManager else {
            XCTFail("MockPersistenceManager should be initialized")
            return
        }
        rlAgent = try await LocalRLAgent(
            persistenceManager: mockPersistenceManager,
            initialBandits: [:]
        )
    }

    override func tearDown() async throws {
        rlAgent = nil
        mockPersistenceManager = nil
        statisticalValidator = nil
        testContext = nil
        standardActions = nil
    }

    // MARK: - Thompson Sampling Algorithm Tests

    func testThompsonSampling_InitialPriorDistribution() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing proper initialization of Beta prior distributions

        guard let rlAgent,
              let testContext,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        // When: First action selection is requested
        let recommendation = try await rlAgent.selectAction(
            context: testContext,
            actions: standardActions
        )

        // Then: Should have valid Thompson sample
        XCTAssertGreaterThanOrEqual(recommendation.thompsonSample, 0.0, "Thompson sample should be non-negative")
        XCTAssertLessThanOrEqual(recommendation.thompsonSample, 1.0, "Thompson sample should be ≤ 1.0")
        XCTAssertNotNil(recommendation.action, "Action should be selected")
        XCTAssertGreaterThan(recommendation.confidence, 0.0, "Confidence should be positive")

        // Verify prior parameters are properly initialized
        let bandits = await rlAgent.getBandits()
        for bandit in bandits.values {
            XCTAssertEqual(bandit.successCount, 1.0, "Initial alpha should be 1.0")
            XCTAssertEqual(bandit.failureCount, 1.0, "Initial beta should be 1.0")
        }
    }

    func testThompsonSampling_PosteriorUpdate() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing Bayesian posterior updates with reward signals

        guard let rlAgent,
              let testContext,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        // Given: Initial action selection
        let initialRecommendation = try await rlAgent.selectAction(
            context: testContext,
            actions: standardActions
        )

        let initialBandits = await rlAgent.getBandits()
        let actionKey = ActionIdentifier(
            action: initialRecommendation.action,
            contextHash: testContext.hash
        )
        guard let initialBandit = initialBandits[actionKey] else {
            XCTFail("Initial bandit should exist for action key")
            return
        }

        // When: Positive reward is provided
        let positiveReward = RewardSignal(
            immediateReward: 1.0,
            delayedReward: 0.8,
            complianceReward: 1.0,
            efficiencyReward: 0.9
        )

        await rlAgent.updateReward(
            for: initialRecommendation.action,
            reward: positiveReward,
            context: AcquisitionContext.createTest()
        )

        // Then: Posterior should be updated correctly
        let updatedBandits = await rlAgent.getBandits()
        guard let updatedBandit = updatedBandits[actionKey] else {
            XCTFail("Updated bandit should exist for action key")
            return
        }

        XCTAssertGreaterThan(updatedBandit.successCount, initialBandit.successCount, "Success count should increase with positive reward")
        XCTAssertEqual(updatedBandit.failureCount, initialBandit.failureCount, "Failure count should remain unchanged with positive reward")
        XCTAssertGreaterThan(updatedBandit.totalSamples, initialBandit.totalSamples, "Total samples should increase")

        // Test negative reward
        let negativeReward = RewardSignal(
            immediateReward: 0.0,
            delayedReward: 0.2,
            complianceReward: 0.5,
            efficiencyReward: 0.1
        )

        await rlAgent.updateReward(
            for: initialRecommendation.action,
            reward: negativeReward,
            context: AcquisitionContext.createTest()
        )

        let finalBandits = await rlAgent.getBandits()
        guard let finalBandit = finalBandits[actionKey] else {
            XCTFail("Final bandit should exist for action key")
            return
        }

        XCTAssertGreaterThan(finalBandit.failureCount, updatedBandit.failureCount, "Failure count should increase with negative reward")
    }

    func testThompsonSampling_ConvergenceValidation() async throws {
        // RED PHASE: This test should FAIL initially
        // Statistical test for Thompson Sampling convergence behavior

        guard let rlAgent,
              let testContext,
              let standardActions,
              let statisticalValidator
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        let trials = 1000
        let optimalAction = standardActions[0]
        var selectedActions: [WorkflowAction] = []
        var rewards: [Double] = []

        // Simulate optimal bandit scenario
        for _ in 0 ..< trials {
            let recommendation = try await rlAgent.selectAction(
                context: testContext,
                actions: standardActions
            )

            selectedActions.append(recommendation.action)

            // Provide reward based on whether optimal action was selected
            let reward = (recommendation.action.id == optimalAction.id) ? 1.0 : 0.3
            rewards.append(reward)

            let rewardSignal = RewardSignal(
                immediateReward: reward,
                delayedReward: reward * 0.8,
                complianceReward: 1.0,
                efficiencyReward: reward * 0.9
            )

            await rlAgent.updateReward(
                for: recommendation.action,
                reward: rewardSignal,
                context: AcquisitionContext.createTest()
            )
        }

        // Statistical validation of convergence
        let convergenceResult = statisticalValidator.verifyConvergence(
            selectedActions: selectedActions,
            optimalAction: optimalAction,
            trials: trials,
            confidenceLevel: 0.95
        )

        XCTAssertTrue(convergenceResult.hasConverged, "Thompson Sampling should converge to optimal action")
        XCTAssertLessThan(convergenceResult.regretBound, 0.05, "Regret bound should be within tolerance")

        // Verify exploration decay
        let earlyExploration = calculateExplorationRate(selectedActions.prefix(100))
        let lateExploration = calculateExplorationRate(selectedActions.suffix(100))
        XCTAssertGreaterThan(earlyExploration, lateExploration, "Exploration should decrease over time")
    }

    // MARK: - Contextual Bandit Tests

    func testContextualBandit_ContextSimilarity() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing context similarity handling and generalization

        guard let rlAgent,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        let similarContext1 = FeatureVector(features: [
            "docType_purchaseRequest": 1.0,
            "value_normalized": 0.5,
            "complexity_score": 0.4,
            "days_remaining": 30.0,
        ])

        let similarContext2 = FeatureVector(features: [
            "docType_purchaseRequest": 1.0,
            "value_normalized": 0.52,
            "complexity_score": 0.42,
            "days_remaining": 31.0,
        ])

        let dissimilarContext = FeatureVector(features: [
            "docType_sourceSelection": 1.0,
            "value_normalized": 0.9,
            "complexity_score": 0.8,
            "days_remaining": 7.0,
        ])

        // Train on similar context 1
        for _ in 0 ..< 20 {
            let recommendation = try await rlAgent.selectAction(
                context: similarContext1,
                actions: standardActions
            )

            let reward = RewardSignal(
                immediateReward: 1.0,
                delayedReward: 0.9,
                complianceReward: 1.0,
                efficiencyReward: 0.8
            )

            await rlAgent.updateReward(
                for: recommendation.action,
                reward: reward,
                context: AcquisitionContext.createTest()
            )
        }

        // Test generalization to similar context
        let similarRecommendation = try await rlAgent.selectAction(
            context: similarContext2,
            actions: standardActions
        )

        // Test behavior on dissimilar context
        let dissimilarRecommendation = try await rlAgent.selectAction(
            context: dissimilarContext,
            actions: standardActions
        )

        // Then: Similar contexts should have higher confidence
        XCTAssertGreaterThan(similarRecommendation.confidence, dissimilarRecommendation.confidence, "Similar contexts should have higher confidence")

        // Verify context-action mapping consistency
        XCTAssertNotNil(similarRecommendation.action, "Similar context should have action recommendation")
        XCTAssertNotNil(dissimilarRecommendation.action, "Dissimilar context should have action recommendation")
    }

    func testContextualBandit_MultiArmedSelection() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing multi-armed bandit selection across different contexts

        guard let rlAgent,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        let contexts = [
            createFeatureVector(docType: "purchaseRequest", complexity: 0.3),
            createFeatureVector(docType: "sourceSelection", complexity: 0.7),
            createFeatureVector(docType: "emergencyProcurement", complexity: 0.9),
        ]

        var contextActionMapping: [Int: [WorkflowAction]] = [:]

        // Train different optimal actions for different contexts
        for (contextIndex, context) in contexts.enumerated() {
            let optimalActionIndex = contextIndex % standardActions.count
            contextActionMapping[contextIndex] = []

            for _ in 0 ..< 50 {
                let recommendation = try await rlAgent.selectAction(
                    context: context,
                    actions: standardActions
                )

                contextActionMapping[contextIndex]?.append(recommendation.action)

                // Provide higher reward for context-specific optimal action
                let isOptimal = recommendation.action.id == standardActions[optimalActionIndex].id
                let reward = RewardSignal(
                    immediateReward: isOptimal ? 1.0 : 0.3,
                    delayedReward: isOptimal ? 0.9 : 0.2,
                    complianceReward: 1.0,
                    efficiencyReward: isOptimal ? 0.8 : 0.4
                )

                await rlAgent.updateReward(
                    for: recommendation.action,
                    reward: reward,
                    context: AcquisitionContext.createTest()
                )
            }
        }

        // Verify context-specific learning
        for (contextIndex, actions) in contextActionMapping {
            let optimalActionId = standardActions[contextIndex % standardActions.count].id
            let optimalSelections = actions.filter { $0.id == optimalActionId }.count
            let optimalRate = Double(optimalSelections) / Double(actions.count)

            XCTAssertGreaterThan(optimalRate, 0.6, "Should learn optimal action for context \(contextIndex)")
        }
    }

    // MARK: - Confidence Calculation Tests

    func testConfidenceCalculation_PosteriorBasedConfidence() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing confidence calculation based on posterior distribution

        guard let rlAgent,
              let testContext,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        // Given: Fresh agent with no learning
        let initialRecommendation = try await rlAgent.selectAction(
            context: testContext,
            actions: standardActions
        )
        let initialConfidence = initialRecommendation.confidence

        // When: Multiple positive feedbacks are provided
        for _ in 0 ..< 10 {
            let reward = RewardSignal(
                immediateReward: 1.0,
                delayedReward: 0.9,
                complianceReward: 1.0,
                efficiencyReward: 0.8
            )

            await rlAgent.updateReward(
                for: initialRecommendation.action,
                reward: reward,
                context: AcquisitionContext.createTest()
            )
        }

        // Then: Confidence should increase with learning
        let learnedRecommendation = try await rlAgent.selectAction(
            context: testContext,
            actions: standardActions
        )

        XCTAssertGreaterThan(learnedRecommendation.confidence, initialConfidence, "Confidence should increase with positive feedback")
        XCTAssertLessThanOrEqual(learnedRecommendation.confidence, 1.0, "Confidence should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(learnedRecommendation.confidence, 0.0, "Confidence should not be negative")
    }

    func testConfidenceCalculation_UncertaintyQuantification() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing uncertainty quantification in confidence scores

        guard let rlAgent,
              let testContext,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        let uncertainContext = FeatureVector(features: [
            "docType_novel": 1.0,
            "value_normalized": 0.95,
            "complexity_score": 0.9,
        ])

        let certainContext = testContext

        // Provide extensive training for certain context
        for _ in 0 ..< 100 {
            let recommendation = try await rlAgent.selectAction(
                context: certainContext,
                actions: standardActions
            )

            let reward = RewardSignal(
                immediateReward: 1.0,
                delayedReward: 0.9,
                complianceReward: 1.0,
                efficiencyReward: 0.8
            )

            await rlAgent.updateReward(
                for: recommendation.action,
                reward: reward,
                context: AcquisitionContext.createTest()
            )
        }

        // Compare confidence for certain vs uncertain contexts
        let certainRecommendation = try await rlAgent.selectAction(
            context: certainContext,
            actions: standardActions
        )

        let uncertainRecommendation = try await rlAgent.selectAction(
            context: uncertainContext,
            actions: standardActions
        )

        XCTAssertGreaterThan(certainRecommendation.confidence, uncertainRecommendation.confidence, "Well-trained contexts should have higher confidence than novel contexts")
        XCTAssertGreaterThan(certainRecommendation.confidence, 0.7, "Well-trained contexts should have high confidence")
        XCTAssertLessThan(uncertainRecommendation.confidence, 0.5, "Novel contexts should have low confidence")
    }

    // MARK: - Performance and Concurrency Tests

    func testConcurrentActionSelection_ThreadSafety() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing thread safety under concurrent action selections

        let concurrentRequests = 50
        let contexts = (0 ..< concurrentRequests).map { index in
            createFeatureVector(docType: "test", complexity: Double(index) / 100.0)
        }

        // When: Multiple concurrent action selections
        guard let rlAgentLocal = rlAgent,
              let standardActionsLocal = standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }
        let recommendations = try await withThrowingTaskGroup(of: ActionRecommendation.self) { group in
            for context in contexts {
                group.addTask {
                    try await rlAgentLocal.selectAction(
                        context: context,
                        actions: standardActionsLocal
                    )
                }
            }

            var results: [ActionRecommendation] = []
            for try await recommendation in group {
                results.append(recommendation)
            }
            return results
        }

        // Then: All requests should be handled safely
        XCTAssertEqual(recommendations.count, concurrentRequests, "All concurrent requests should be processed")

        // Verify no state corruption
        for recommendation in recommendations {
            XCTAssertTrue(recommendation.confidence >= 0.0 && recommendation.confidence <= 1.0, "Confidence should be in valid range")
            XCTAssertNotNil(recommendation.action, "All recommendations should have actions")
            XCTAssertGreaterThanOrEqual(recommendation.thompsonSample, 0.0, "Thompson samples should be non-negative")
        }
    }

    func testActionSelection_PerformanceLatency() async throws {
        // RED PHASE: This test should FAIL initially
        // Testing action selection performance requirements

        guard let rlAgent,
              let testContext,
              let standardActions
        else {
            XCTFail("Test properties should be initialized")
            return
        }

        let context = testContext
        let iterations = 100

        let measurements = try await (0 ..< iterations).asyncMap { _ in
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await rlAgent.selectAction(
                context: context,
                actions: standardActions
            )
            let endTime = CFAbsoluteTimeGetCurrent()
            return endTime - startTime
        }

        let averageLatency = measurements.reduce(0, +) / Double(measurements.count)
        let p95Latency = measurements.sorted()[Int(Double(measurements.count) * 0.95)]

        XCTAssertLessThan(averageLatency, 0.01, "Average action selection should be < 10ms")
        XCTAssertLessThan(p95Latency, 0.05, "95th percentile action selection should be < 50ms")
    }

    // MARK: - Helper Methods

    private func createFeatureVector(docType: String, complexity: Double) -> FeatureVector {
        FeatureVector(features: [
            "docType_\(docType)": 1.0,
            "complexity_score": complexity,
            "value_normalized": 0.5,
            "days_remaining": 30.0,
        ])
    }

    private func calculateExplorationRate(_ actions: any Sequence<WorkflowAction>) -> Double {
        let actionArray = Array(actions)
        let uniqueActions = Set(actionArray.map(\.id))
        return Double(uniqueActions.count) / Double(actionArray.count)
    }
}

// MARK: - Statistical Test Framework

struct StatisticalTestFramework {
    struct ConvergenceResult {
        let hasConverged: Bool
        let regretBound: Double
        let finalOptimalRate: Double
        let explorationDecayRate: Double
    }

    func verifyConvergence(
        selectedActions: [WorkflowAction],
        optimalAction: WorkflowAction,
        trials: Int,
        confidenceLevel _: Double = 0.95
    ) -> ConvergenceResult {
        // Calculate cumulative regret
        var cumulativeRegret: Double = 0
        var optimalSelections = 0

        for action in selectedActions {
            if action.id == optimalAction.id {
                optimalSelections += 1
            } else {
                cumulativeRegret += 0.7 // Expected regret for suboptimal selection
            }
        }

        let finalOptimalRate = Double(optimalSelections) / Double(trials)
        let regretBound = cumulativeRegret / Double(trials)

        // Check if converged (>80% optimal selections in final 20% of trials)
        let finalQuarter = selectedActions.suffix(trials / 4)
        let finalOptimalCount = finalQuarter.filter { $0.id == optimalAction.id }.count
        let finalOptimalQuarterRate = Double(finalOptimalCount) / Double(finalQuarter.count)

        let hasConverged = finalOptimalQuarterRate > 0.8 && regretBound < 0.1

        return ConvergenceResult(
            hasConverged: hasConverged,
            regretBound: regretBound,
            finalOptimalRate: finalOptimalRate,
            explorationDecayRate: 0.1 // Simplified calculation
        )
    }
}

// MARK: - Extensions

extension AcquisitionContext {
    static func createTest() -> AcquisitionContext {
        AcquisitionContext(
            acquisitionId: UUID(),
            documentType: .purchaseRequest,
            acquisitionValue: 50000.0,
            complexity: TestComplexityLevel(score: 0.5, factors: ["test"]),
            timeConstraints: TestTimeConstraints(daysRemaining: 30, isUrgent: false, expectedDuration: 3600.0),
            regulatoryRequirements: Set([TestFARClause(clauseNumber: "52.215-1", isCritical: true)]),
            historicalSuccess: 0.8,
            userProfile: TestUserProfile(experienceLevel: 0.7),
            workflowProgress: 0.0,
            completedDocuments: []
        )
    }
}

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}

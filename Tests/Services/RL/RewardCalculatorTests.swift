import XCTest
import Foundation
@testable import AIKO

/// Comprehensive test suite for RewardCalculator
/// Testing multi-signal reward computation with validation
///
/// Testing Layers:
/// 1. Individual reward component calculation
/// 2. Multi-signal reward composition
/// 3. Edge case handling and boundary conditions
/// 4. Performance requirements for reward processing
final class RewardCalculatorTests: XCTestCase {

    // MARK: - Test Properties

    var testContext: AcquisitionContext!
    var testDecision: DecisionResponse!
    var standardAction: WorkflowAction!

    override func setUp() async throws {
        testContext = AcquisitionContext(
            acquisitionId: UUID(),
            documentType: .purchaseRequest,
            acquisitionValue: 100000.0,
            complexity: TestComplexityLevel(score: 0.5, factors: ["standard"]),
            timeConstraints: TestTimeConstraints(
                daysRemaining: 30,
                isUrgent: false,
                expectedDuration: 3600.0
            ),
            regulatoryRequirements: Set([
                TestFARClause(clauseNumber: "52.215-1", isCritical: true),
                TestFARClause(clauseNumber: "52.209-5", isCritical: false),
                TestFARClause(clauseNumber: "52.233-1", isCritical: true)
            ]),
            historicalSuccess: 0.8,
            userProfile: TestUserProfile(experienceLevel: 0.7),
            workflowProgress: 0.3,
            completedDocuments: ["requirements", "market-research"]
        )

        standardAction = WorkflowAction(
            actionType: .generateDocument,
            documentTemplates: [AgenticDocumentTemplate(
                name: "Purchase Request Template",
                templateType: .requestForProposal,
                requiredFields: ["description", "amount", "justification"],
                complianceRequirements: []
            )],
            automationLevel: .automated,
            complianceChecks: [
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.215-1",
                        title: "Instructions to Offerors",
                        description: "Standard clause for competitive acquisition"
                    ),
                    requirement: "Competitive acquisition compliance",
                    severity: .critical,
                    automated: true
                ),
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.209-5",
                        title: "Certification Regarding Responsibility Matters",
                        description: "Contractor responsibility certification"
                    ),
                    requirement: "Responsibility certification",
                    severity: .major,
                    automated: true
                ),
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.233-1",
                        title: "Disputes",
                        description: "Contract disputes clause"
                    ),
                    requirement: "Dispute resolution compliance",
                    severity: .critical,
                    automated: true
                )
            ],
            estimatedDuration: 1800.0
        )

        testDecision = DecisionResponse(
            selectedAction: standardAction,
            confidence: 0.8,
            decisionMode: .autonomous,
            reasoning: "Test decision reasoning",
            alternativeActions: [],
            context: testContext,
            timestamp: Date()
        )
    }

    override func tearDown() async throws {
        testContext = nil
        testDecision = nil
        standardAction = nil
    }

    // MARK: - Immediate Reward Tests

    func testImmediateReward_AcceptedOutcome() throws {
        // RED PHASE: This test should FAIL initially
        // Testing immediate reward calculation for accepted outcomes

        // Given: User feedback with accepted outcome
        let acceptedFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.9,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.95, completeness: 0.9, compliance: 1.0),
            timeTaken: 1500.0,
            comments: "Excellent recommendation"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: testDecision,
            feedback: acceptedFeedback,
            context: testContext
        )

        // Then: Immediate reward should be maximum
        XCTAssertEqual(rewardSignal.immediateReward, 1.0, "Accepted outcome should give maximum immediate reward")
        XCTAssertTrue(rewardSignal.totalReward > 0.8, "Total reward should be high for accepted outcome")
        XCTAssertLessThanOrEqual(rewardSignal.totalReward, 1.0, "Total reward should not exceed 1.0")
    }

    func testImmediateReward_RejectedOutcome() throws {
        // RED PHASE: This test should FAIL initially
        // Testing immediate reward calculation for rejected outcomes

        // Given: User feedback with rejected outcome
        let rejectedFeedback = RLUserFeedback(
            outcome: .rejected,
            satisfactionScore: 0.2,
            workflowCompleted: false,
            qualityMetrics: QualityMetrics(accuracy: 0.3, completeness: 0.4, compliance: 0.7),
            timeTaken: 3600.0,
            comments: "Inappropriate recommendation"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: testDecision,
            feedback: rejectedFeedback,
            context: testContext
        )

        // Then: Immediate reward should be minimum
        XCTAssertEqual(rewardSignal.immediateReward, 0.0, "Rejected outcome should give zero immediate reward")
        XCTAssertLessThan(rewardSignal.totalReward, 0.5, "Total reward should be low for rejected outcome")
        XCTAssertGreaterThanOrEqual(rewardSignal.totalReward, 0.0, "Total reward should not be negative")
    }

    func testImmediateReward_AcceptedWithModifications() throws {
        // RED PHASE: This test should FAIL initially
        // Testing immediate reward for partially accepted outcomes

        // Given: User feedback with modifications
        let modifiedFeedback = RLUserFeedback(
            outcome: .acceptedWithModifications,
            satisfactionScore: 0.7,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.75, compliance: 1.0),
            timeTaken: 2100.0,
            comments: "Good but needed adjustments"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: testDecision,
            feedback: modifiedFeedback,
            context: testContext
        )

        // Then: Immediate reward should be moderate
        XCTAssertEqual(rewardSignal.immediateReward, 0.7, "Accepted with modifications should give 0.7 immediate reward")
        XCTAssertTrue(rewardSignal.totalReward > 0.5 && rewardSignal.totalReward < 0.9, "Total reward should be moderate")
    }

    func testImmediateReward_DeferredOutcome() throws {
        // RED PHASE: This test should FAIL initially
        // Testing immediate reward for deferred outcomes

        // Given: User feedback with deferred outcome
        let deferredFeedback = RLUserFeedback(
            outcome: .deferred,
            satisfactionScore: 0.5,
            workflowCompleted: false,
            qualityMetrics: QualityMetrics(accuracy: 0.6, completeness: 0.5, compliance: 0.9),
            timeTaken: nil,
            comments: "Need more information"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: testDecision,
            feedback: deferredFeedback,
            context: testContext
        )

        // Then: Immediate reward should be low
        XCTAssertEqual(rewardSignal.immediateReward, 0.3, "Deferred outcome should give 0.3 immediate reward")
    }

    // MARK: - Delayed Reward Tests

    func testDelayedReward_SatisfactionScore() throws {
        // RED PHASE: This test should FAIL initially
        // Testing delayed reward based on user satisfaction

        // Given: High satisfaction feedback
        let highSatisfactionFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.9,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.85, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0,
            comments: "Very satisfied"
        )

        // When: Reward is calculated
        let highSatisfactionReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: highSatisfactionFeedback,
            context: testContext
        )

        // Given: Low satisfaction feedback
        let lowSatisfactionFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.3,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.85, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0,
            comments: "Not very satisfied"
        )

        let lowSatisfactionReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: lowSatisfactionFeedback,
            context: testContext
        )

        // Then: Higher satisfaction should yield higher delayed reward
        XCTAssertGreaterThan(highSatisfactionReward.delayedReward, lowSatisfactionReward.delayedReward, "Higher satisfaction should yield higher delayed reward")
        XCTAssertGreaterThan(highSatisfactionReward.delayedReward, 0.8, "High satisfaction should result in high delayed reward")
        XCTAssertLessThan(lowSatisfactionReward.delayedReward, 0.6, "Low satisfaction should result in low delayed reward")
    }

    func testDelayedReward_WorkflowCompletionBonus() throws {
        // RED PHASE: This test should FAIL initially
        // Testing workflow completion bonus in delayed reward

        // Given: Completed workflow feedback
        let completedFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.7,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.75, compliance: 1.0),
            timeTaken: 2000.0,
            comments: "Workflow completed successfully"
        )

        // Given: Incomplete workflow feedback
        let incompleteFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.7,
            workflowCompleted: false,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.75, compliance: 1.0),
            timeTaken: 2000.0,
            comments: "Workflow still in progress"
        )

        // When: Rewards are calculated
        let completedReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: completedFeedback,
            context: testContext
        )

        let incompleteReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: incompleteFeedback,
            context: testContext
        )

        // Then: Completed workflow should have higher delayed reward
        XCTAssertGreaterThan(completedReward.delayedReward, incompleteReward.delayedReward, "Completed workflow should have higher delayed reward")

        // Verify completion bonus magnitude
        let bonusDifference = completedReward.delayedReward - incompleteReward.delayedReward
        XCTAssertEqual(bonusDifference, 0.2, accuracy: 0.01, "Completion bonus should be approximately 0.2")
    }

    func testDelayedReward_QualityMetrics() throws {
        // RED PHASE: This test should FAIL initially
        // Testing quality metrics impact on delayed reward

        // Given: High quality metrics
        let highQualityFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.95, completeness: 0.9, compliance: 1.0),
            timeTaken: 1800.0,
            comments: "High quality output"
        )

        // Given: Low quality metrics
        let lowQualityFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.6, completeness: 0.5, compliance: 0.8),
            timeTaken: 1800.0,
            comments: "Lower quality output"
        )

        // When: Rewards are calculated
        let highQualityReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: highQualityFeedback,
            context: testContext
        )

        let lowQualityReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: lowQualityFeedback,
            context: testContext
        )

        // Then: Higher quality should yield higher delayed reward
        XCTAssertGreaterThan(highQualityReward.delayedReward, lowQualityReward.delayedReward, "Higher quality metrics should yield higher delayed reward")

        // Test individual quality components
        let highQualityAverage = highQualityFeedback.qualityMetrics.average
        let lowQualityAverage = lowQualityFeedback.qualityMetrics.average

        XCTAssertGreaterThan(highQualityAverage, 0.9, "High quality metrics should average > 0.9")
        XCTAssertLessThan(lowQualityAverage, 0.7, "Low quality metrics should average < 0.7")
    }

    // MARK: - Compliance Reward Tests

    func testComplianceReward_FullCompliance() throws {
        // RED PHASE: This test should FAIL initially
        // Testing compliance reward for full regulatory coverage

        // Given: Decision with full compliance coverage
        let fullComplianceAction = WorkflowAction(
            actionType: .reviewCompliance,
            documentTemplates: [],
            automationLevel: .assisted,
            complianceChecks: [
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.215-1",
                        title: "Instructions to Offerors",
                        description: "Standard clause for competitive acquisition"
                    ),
                    requirement: "Competitive acquisition compliance",
                    severity: .critical,
                    automated: true
                ),
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.209-5",
                        title: "Certification Regarding Responsibility Matters",
                        description: "Contractor responsibility certification"
                    ),
                    requirement: "Responsibility certification",
                    severity: .major,
                    automated: true
                ),
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.233-1",
                        title: "Disputes",
                        description: "Contract disputes clause"
                    ),
                    requirement: "Dispute resolution compliance",
                    severity: .critical,
                    automated: true
                )
            ],
            estimatedDuration: 1800.0
        )

        let fullComplianceDecision = DecisionResponse(
            selectedAction: fullComplianceAction,
            confidence: 0.8,
            decisionMode: .autonomous,
            reasoning: "Full compliance coverage",
            alternativeActions: [],
            context: testContext,
            timestamp: Date()
        )

        let feedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0,
            comments: nil
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: fullComplianceDecision,
            feedback: feedback,
            context: testContext
        )

        // Then: Compliance reward should be high
        XCTAssertEqual(rewardSignal.complianceReward, 1.0, "Full compliance coverage should yield maximum compliance reward")
    }

    func testComplianceReward_PartialCompliance() throws {
        // RED PHASE: This test should FAIL initially
        // Testing compliance reward for partial regulatory coverage

        // Given: Decision with partial compliance coverage (missing one requirement)
        let partialComplianceAction = WorkflowAction(
            actionType: .generateDocument,
            documentTemplates: [AgenticDocumentTemplate(
                name: "Purchase Request Template",
                templateType: .requestForProposal,
                requiredFields: ["description", "amount", "justification"],
                complianceRequirements: []
            )],
            automationLevel: .automated,
            complianceChecks: [
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.215-1",
                        title: "Instructions to Offerors",
                        description: "Standard clause for competitive acquisition"
                    ),
                    requirement: "Competitive acquisition compliance",
                    severity: .critical,
                    automated: true
                ),
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.209-5",
                        title: "Certification Regarding Responsibility Matters",
                        description: "Contractor responsibility certification"
                    ),
                    requirement: "Responsibility certification",
                    severity: .major,
                    automated: true
                )
                // Missing 52.233-1 (critical)
            ],
            estimatedDuration: 1500.0
        )

        let partialComplianceDecision = DecisionResponse(
            selectedAction: partialComplianceAction,
            confidence: 0.7,
            decisionMode: .assisted,
            reasoning: "Partial compliance coverage",
            alternativeActions: [],
            context: testContext,
            timestamp: Date()
        )

        let feedback = RLUserFeedback(
            outcome: .acceptedWithModifications,
            satisfactionScore: 0.6,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.7, completeness: 0.8, compliance: 0.8),
            timeTaken: 2100.0,
            comments: "Missing critical compliance check"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: partialComplianceDecision,
            feedback: feedback,
            context: testContext
        )

        // Then: Compliance reward should be reduced due to missing critical requirement
        XCTAssertLessThan(rewardSignal.complianceReward, 1.0, "Partial compliance should result in reduced compliance reward")
        XCTAssertLessThan(rewardSignal.complianceReward, 0.8, "Missing critical requirement should significantly reduce compliance reward")
        XCTAssertGreaterThanOrEqual(rewardSignal.complianceReward, 0.0, "Compliance reward should not be negative")
    }

    func testComplianceReward_MissingCriticalClauses() throws {
        // RED PHASE: This test should FAIL initially
        // Testing penalty for missing critical compliance clauses

        // Given: Decision missing critical clauses
        let nonCompliantAction = WorkflowAction(
            actionType: .generateDocument,
            documentTemplates: [AgenticDocumentTemplate(
                name: "Purchase Request Template",
                templateType: .requestForProposal,
                requiredFields: ["description", "amount", "justification"],
                complianceRequirements: []
            )],
            automationLevel: .automated,
            complianceChecks: [
                ComplianceCheck(
                    farClause: AgenticFARClause(
                        section: "52.209-5",
                        title: "Certification Regarding Responsibility Matters",
                        description: "Contractor responsibility certification"
                    ),
                    requirement: "Responsibility certification",
                    severity: .major,
                    automated: true
                )
                // Missing both critical clauses: 52.215-1 and 52.233-1
            ],
            estimatedDuration: 1200.0
        )

        let nonCompliantDecision = DecisionResponse(
            selectedAction: nonCompliantAction,
            confidence: 0.6,
            decisionMode: .deferred,
            reasoning: "Non-compliant action",
            alternativeActions: [],
            context: testContext,
            timestamp: Date()
        )

        let feedback = RLUserFeedback(
            outcome: .rejected,
            satisfactionScore: 0.3,
            workflowCompleted: false,
            qualityMetrics: QualityMetrics(accuracy: 0.5, completeness: 0.6, compliance: 0.3),
            timeTaken: nil,
            comments: "Major compliance violations"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: nonCompliantDecision,
            feedback: feedback,
            context: testContext
        )

        // Then: Compliance reward should be heavily penalized
        XCTAssertLessThan(rewardSignal.complianceReward, 0.5, "Missing critical clauses should heavily penalize compliance reward")

        // Should be penalized by 0.2 per missing critical clause (2 * 0.2 = 0.4 penalty)
        let expectedMaxReward = (1.0 / 3.0) - 0.4 // Coverage of non-critical - penalty
        XCTAssertLessThanOrEqual(rewardSignal.complianceReward, max(0, expectedMaxReward), "Penalty calculation should be correct")
    }

    // MARK: - Efficiency Reward Tests

    func testEfficiencyReward_TimeEfficiency() throws {
        // RED PHASE: This test should FAIL initially
        // Testing efficiency reward based on time performance

        // Given: Fast completion feedback
        let fastFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0, // Same as expected duration
            comments: "Completed on time"
        )

        // Given: Slow completion feedback
        let slowFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.8, compliance: 1.0),
            timeTaken: 7200.0, // Double the expected duration
            comments: "Took longer than expected"
        )

        // When: Rewards are calculated
        let fastReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: fastFeedback,
            context: testContext
        )

        let slowReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: slowFeedback,
            context: testContext
        )

        // Then: Faster completion should yield higher efficiency reward
        XCTAssertGreaterThan(fastReward.efficiencyReward, slowReward.efficiencyReward, "Faster completion should yield higher efficiency reward")
        XCTAssertEqual(fastReward.efficiencyReward, 1.0, "On-time completion should yield maximum efficiency reward")
        XCTAssertEqual(slowReward.efficiencyReward, 0.5, "Double-time completion should yield 0.5 efficiency reward")
    }

    func testEfficiencyReward_MissingTimeData() throws {
        // RED PHASE: This test should FAIL initially
        // Testing efficiency reward when time taken is not provided

        // Given: Feedback without time taken
        let noTimeFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.8, compliance: 1.0),
            timeTaken: nil,
            comments: "No time tracking"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: testDecision,
            feedback: noTimeFeedback,
            context: testContext
        )

        // Then: Should provide default efficiency reward
        XCTAssertEqual(rewardSignal.efficiencyReward, 0.5, "Missing time data should result in default 0.5 efficiency reward")
    }

    // MARK: - Total Reward Composition Tests

    func testTotalReward_WeightedComposition() throws {
        // RED PHASE: This test should FAIL initially
        // Testing total reward calculation as weighted sum of components

        // Given: Known reward components
        let feedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.9, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0,
            comments: "Good performance"
        )

        // When: Reward is calculated
        let rewardSignal = RewardCalculator.calculate(
            decision: testDecision,
            feedback: feedback,
            context: testContext
        )

        // Then: Total reward should be weighted sum of components
        let expectedTotal = rewardSignal.immediateReward * 0.4 +
            rewardSignal.delayedReward * 0.3 +
            rewardSignal.complianceReward * 0.2 +
            rewardSignal.efficiencyReward * 0.1

        XCTAssertEqual(rewardSignal.totalReward, expectedTotal, accuracy: 0.001, "Total reward should be correct weighted sum")
        XCTAssertLessThanOrEqual(rewardSignal.totalReward, 1.0, "Total reward should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(rewardSignal.totalReward, 0.0, "Total reward should not be negative")
    }

    func testTotalReward_ComponentRanges() throws {
        // RED PHASE: This test should FAIL initially
        // Testing that all reward components are in valid ranges

        let feedbackVariations = [
            RLUserFeedback(outcome: .accepted, satisfactionScore: 1.0, workflowCompleted: true, qualityMetrics: QualityMetrics(accuracy: 1.0, completeness: 1.0, compliance: 1.0), timeTaken: 900.0, comments: nil),
            RLUserFeedback(outcome: .rejected, satisfactionScore: 0.0, workflowCompleted: false, qualityMetrics: QualityMetrics(accuracy: 0.0, completeness: 0.0, compliance: 0.0), timeTaken: 7200.0, comments: nil),
            RLUserFeedback(outcome: .acceptedWithModifications, satisfactionScore: 0.5, workflowCompleted: true, qualityMetrics: QualityMetrics(accuracy: 0.5, completeness: 0.5, compliance: 0.5), timeTaken: 3600.0, comments: nil),
            RLUserFeedback(outcome: .deferred, satisfactionScore: nil, workflowCompleted: false, qualityMetrics: QualityMetrics(accuracy: 0.3, completeness: 0.4, compliance: 0.8), timeTaken: nil, comments: nil)
        ]

        // When: Rewards are calculated for various feedback scenarios
        for feedback in feedbackVariations {
            let rewardSignal = RewardCalculator.calculate(
                decision: testDecision,
                feedback: feedback,
                context: testContext
            )

            // Then: All components should be in valid ranges
            XCTAssertTrue(rewardSignal.immediateReward >= 0.0 && rewardSignal.immediateReward <= 1.0, "Immediate reward should be in [0,1] range")
            XCTAssertTrue(rewardSignal.delayedReward >= 0.0 && rewardSignal.delayedReward <= 1.0, "Delayed reward should be in [0,1] range")
            XCTAssertTrue(rewardSignal.complianceReward >= 0.0 && rewardSignal.complianceReward <= 1.0, "Compliance reward should be in [0,1] range")
            XCTAssertTrue(rewardSignal.efficiencyReward >= 0.0 && rewardSignal.efficiencyReward <= 1.0, "Efficiency reward should be in [0,1] range")
            XCTAssertTrue(rewardSignal.totalReward >= 0.0 && rewardSignal.totalReward <= 1.0, "Total reward should be in [0,1] range")
        }
    }

    // MARK: - Performance Tests

    func testRewardCalculation_ProcessingLatency() throws {
        // RED PHASE: This test should FAIL initially
        // Testing reward calculation performance requirements

        let feedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.8,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0,
            comments: nil
        )

        let iterations = 1000

        // When: Multiple reward calculations are performed
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            _ = RewardCalculator.calculate(
                decision: testDecision,
                feedback: feedback,
                context: testContext
            )
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)

        // Then: Reward calculation should meet performance requirements
        XCTAssertLessThan(averageTime, 0.001, "Average reward calculation should be < 1ms")
        XCTAssertLessThan(totalTime, 5.0, "Total calculation time should be reasonable")
    }

    func testRewardCalculation_Consistency() throws {
        // RED PHASE: This test should FAIL initially
        // Testing consistency of reward calculations

        let feedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.75,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.85, completeness: 0.8, compliance: 1.0),
            timeTaken: 1800.0,
            comments: "Consistent test"
        )

        var rewards: [RewardSignal] = []

        // When: Same calculation is performed multiple times
        for _ in 0..<100 {
            let reward = RewardCalculator.calculate(
                decision: testDecision,
                feedback: feedback,
                context: testContext
            )
            rewards.append(reward)
        }

        // Then: All calculations should be identical
        let firstReward = rewards[0]
        for reward in rewards {
            XCTAssertEqual(reward.immediateReward, firstReward.immediateReward, "Immediate rewards should be consistent")
            XCTAssertEqual(reward.delayedReward, firstReward.delayedReward, accuracy: 0.001, "Delayed rewards should be consistent")
            XCTAssertEqual(reward.complianceReward, firstReward.complianceReward, accuracy: 0.001, "Compliance rewards should be consistent")
            XCTAssertEqual(reward.efficiencyReward, firstReward.efficiencyReward, accuracy: 0.001, "Efficiency rewards should be consistent")
            XCTAssertEqual(reward.totalReward, firstReward.totalReward, accuracy: 0.001, "Total rewards should be consistent")
        }
    }

    // MARK: - Edge Case Tests

    func testRewardCalculation_ExtremeValues() throws {
        // RED PHASE: This test should FAIL initially
        // Testing reward calculation with extreme input values

        // Given: Extreme satisfaction scores
        let extremeHighFeedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 1.0,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 1.0, completeness: 1.0, compliance: 1.0),
            timeTaken: 1.0, // Extremely fast
            comments: "Perfect"
        )

        let extremeLowFeedback = RLUserFeedback(
            outcome: .rejected,
            satisfactionScore: 0.0,
            workflowCompleted: false,
            qualityMetrics: QualityMetrics(accuracy: 0.0, completeness: 0.0, compliance: 0.0),
            timeTaken: 86400.0, // Extremely slow
            comments: "Terrible"
        )

        // When: Rewards are calculated
        let maxReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: extremeHighFeedback,
            context: testContext
        )

        let minReward = RewardCalculator.calculate(
            decision: testDecision,
            feedback: extremeLowFeedback,
            context: testContext
        )

        // Then: Should handle extreme values gracefully
        XCTAssertLessThanOrEqual(maxReward.totalReward, 1.0, "Maximum reward should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(minReward.totalReward, 0.0, "Minimum reward should not be negative")
        XCTAssertGreaterThan(maxReward.totalReward, minReward.totalReward, "Maximum case should yield higher reward than minimum case")
    }
}

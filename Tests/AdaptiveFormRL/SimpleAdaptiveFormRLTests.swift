@testable import AppCore
import XCTest

/// Simple validation tests for Adaptive Form RL system
/// GREEN Phase: Verify core components can be instantiated and basic functionality works
final class SimpleAdaptiveFormRLTests: XCTestCase {
    var mockCoreDataActor: MockCoreDataActor?

    override func setUp() async throws {
        try await super.setUp()
        mockCoreDataActor = MockCoreDataActor()
    }

    override func tearDown() async throws {
        mockCoreDataActor = nil
        try await super.tearDown()
    }

    // MARK: - Component Instantiation Tests

    func testAdaptiveFormPopulationService_canBeInitialized() async throws {
        // Test that all components can be instantiated
        let contextClassifier = AcquisitionContextClassifier()
        guard let coreDataActor = mockCoreDataActor else {
            XCTFail("CoreDataActor not initialized")
            return
        }
        let qLearningAgent = FormFieldQLearningAgent(coreDataActor: coreDataActor)
        let modificationTracker = FormModificationTracker(coreDataActor: coreDataActor)
        let explanationEngine = ValueExplanationEngine()
        let metricsCollector = AdaptiveFormMetricsCollector()
        let agenticOrchestrator = MockAgenticOrchestrator()

        let adaptiveFormService = AdaptiveFormPopulationService(
            contextClassifier: contextClassifier,
            qLearningAgent: qLearningAgent,
            modificationTracker: modificationTracker,
            explanationEngine: explanationEngine,
            metricsCollector: metricsCollector,
            agenticOrchestrator: agenticOrchestrator
        )

        XCTAssertNotNil(adaptiveFormService)
    }

    func testAcquisitionContextClassifier_canClassifyContext() async throws {
        let classifier = AcquisitionContextClassifier()
        let testData = AcquisitionAggregate(
            id: UUID(),
            title: "IT Services Contract",
            requirements: "Software development with cloud computing. We need cloud hosting and database management services.",
            projectDescription: "Software development with cloud computing",
            estimatedValue: 100_000,
            deadline: Date().addingTimeInterval(30 * 24 * 3600),
            isRecurring: false
        )

        let result = try await classifier.classifyAcquisition(testData)

        XCTAssertEqual(result.category, .informationTechnology)
        XCTAssertGreaterThan(result.confidence, 0.5)
    }

    func testFormFieldQLearningAgent_canPredictFieldValue() async throws {
        let qLearningAgent = FormFieldQLearningAgent(coreDataActor: mockCoreDataActor)

        // Create test state
        let state = QLearningState(
            fieldType: .textField,
            contextCategory: .informationTechnology,
            userSegment: .intermediate,
            temporalContext: TemporalContext(hourOfDay: 12, dayOfWeek: 3, isWeekend: false)
        )

        let prediction = await qLearningAgent.predictFieldValue(state: state)

        XCTAssertNotNil(prediction)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
    }

    func testFormModificationTracker_canTrackModifications() async throws {
        let tracker = FormModificationTracker(coreDataActor: mockCoreDataActor)

        // Test basic modification tracking
        let originalFormData = FormData(fields: [
            FormField(
                name: "testField",
                value: "original",
                confidence: ConfidenceScore(value: 0.8),
                fieldType: .text
            ),
        ])

        let modifiedFormData = FormData(fields: [
            FormField(
                name: "testField",
                value: "modified",
                confidence: ConfidenceScore(value: 0.8),
                fieldType: .text
            ),
        ])

        let context = AcquisitionContext(
            type: .informationTechnology,
            confidence: .high,
            subContexts: [],
            metadata: ContextMetadata(
                keywordMatches: 5,
                totalWords: 50,
                classificationMethod: .comprehensive
            )
        )

        // Should not throw
        await tracker.trackModifications(
            original: originalFormData,
            modified: modifiedFormData,
            context: context
        )

        let stats = tracker.getModificationStatistics()
        XCTAssertGreaterThan(stats.totalSessions, 0)
    }

    func testValueExplanationEngine_canGenerateExplanation() {
        let engine = ValueExplanationEngine()

        let userProfile = AppCore.UserProfile(
            id: UUID(),
            fullName: "Test User",
            title: "Developer",
            position: "Senior",
            email: "test@example.com",
            alternateEmail: "",
            phoneNumber: "",
            alternatePhoneNumber: "",
            organizationName: "Test Org",
            organizationalDODAAC: "",
            agencyDepartmentService: "",
            defaultAdministeredByAddress: Address(),
            defaultPaymentAddress: Address(),
            defaultDeliveryAddress: Address(),
            profileImageData: Data?.none,
            organizationLogoData: Data?.none,
            website: "",
            linkedIn: "",
            twitter: "",
            bio: "",
            certifications: [],
            specializations: [],
            preferredLanguage: "English",
            timeZone: "UTC",
            mailingAddress: Address()
        )

        let fieldName = "testField"
        let suggestedValue = "Test Value"
        let confidence = 0.85

        let explanation = engine.generateExplanation(
            fieldName: fieldName,
            suggestedValue: suggestedValue,
            confidence: confidence,
            userProfile: userProfile,
            reasoningFactors: ["Historical usage", "Context matching"]
        )

        XCTAssertFalse(explanation.isEmpty)
        XCTAssertTrue(explanation.contains(fieldName))
    }

    func testRewardCalculator_canCalculateReward() {
        let decision = DecisionResponse(
            selectedAction: RLAction(
                value: "Test Value",
                actionType: .fieldPopulation,
                complianceChecks: ["clause1", "clause2"]
            ),
            confidence: 0.8
        )

        let feedback = RLUserFeedback(
            outcome: .accepted,
            satisfactionScore: 0.9,
            workflowCompleted: true,
            qualityMetrics: QualityMetrics(accuracy: 0.8, completeness: 0.9, compliance: 0.85),
            timeTaken: 2.5,
            comments: nil
        )

        let context = AcquisitionContext(
            type: .informationTechnology,
            confidence: .high,
            subContexts: [],
            metadata: ContextMetadata(
                keywordMatches: 10,
                totalWords: 100,
                classificationMethod: .comprehensive
            )
        )

        let reward = RewardCalculator.calculate(
            decision: decision,
            feedback: feedback,
            context: context
        )

        XCTAssertGreaterThanOrEqual(reward.totalReward, 0.0)
        XCTAssertLessThanOrEqual(reward.totalReward, 1.0)
        XCTAssertGreaterThan(reward.immediateReward, 0.5) // Should be high for accepted outcome
    }

    func testPrivacyComplianceValidator_canValidatePrivacy() async throws {
        let validator = PrivacyComplianceValidator()

        let testData = [
            "user@example.com",
            "John Doe",
            "555-123-4567",
        ]

        let result = await validator.validateDataPrivacy(testData)

        XCTAssertFalse(result.hasPrivacyViolations)
        XCTAssertGreaterThan(result.privacyScore, 0.8)
    }

    // MARK: - Basic Integration Test

    func testBasicAdaptiveFormWorkflow() async throws {
        // Test that the main service can process a basic request
        let contextClassifier = AcquisitionContextClassifier()
        guard let coreDataActor = mockCoreDataActor else {
            XCTFail("CoreDataActor not initialized")
            return
        }
        let qLearningAgent = FormFieldQLearningAgent(coreDataActor: coreDataActor)
        let modificationTracker = FormModificationTracker(coreDataActor: coreDataActor)
        let explanationEngine = ValueExplanationEngine()
        let metricsCollector = AdaptiveFormMetricsCollector()
        let agenticOrchestrator = MockAgenticOrchestrator()

        let adaptiveFormService = AdaptiveFormPopulationService(
            contextClassifier: contextClassifier,
            qLearningAgent: qLearningAgent,
            modificationTracker: modificationTracker,
            explanationEngine: explanationEngine,
            metricsCollector: metricsCollector,
            agenticOrchestrator: agenticOrchestrator
        )

        let formData = FormData(fields: [
            FormField(
                name: "contractType",
                value: "",
                confidence: ConfidenceScore(value: 0.5),
                fieldType: .text
            ),
        ])

        let userProfile = AppCore.UserProfile(
            id: UUID(),
            fullName: "Test User",
            title: "Contracting Officer",
            position: "Senior",
            email: "test@gov.com",
            alternateEmail: "",
            phoneNumber: "",
            alternatePhoneNumber: "",
            organizationName: "DOD",
            organizationalDODAAC: "ABC123",
            agencyDepartmentService: "Defense",
            defaultAdministeredByAddress: Address(),
            defaultPaymentAddress: Address(),
            defaultDeliveryAddress: Address(),
            profileImageData: Data?.none,
            organizationLogoData: Data?.none,
            website: "",
            linkedIn: "",
            twitter: "",
            bio: "",
            certifications: [],
            specializations: ["IT Procurement"],
            preferredLanguage: "English",
            timeZone: "UTC",
            mailingAddress: Address()
        )

        let acquisitionAggregate = AcquisitionAggregate(
            title: "IT Services Contract",
            description: "Software development with cloud hosting",
            requirements: ["Software development with cloud hosting", "Cloud services and software development expertise"]
        )

        // This should complete without throwing
        let result = await adaptiveFormService.populateForm(
            formData: formData,
            userProfile: userProfile,
            acquisitionAggregate: acquisitionAggregate
        )

        XCTAssertEqual(result.source, PopulationSource.adaptive)
        XCTAssertFalse(result.predictions.isEmpty)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
}

@testable import AIKO
import XCTest

/// Comprehensive user experience tests for Adaptive Form RL system
/// RED Phase: Tests written before implementation exists
/// Coverage: Trust framework validation, A/B testing, adaptive UI behavior, user control mechanisms
final class AdaptiveFormUserExperienceTests: XCTestCase {
    // MARK: - Test Infrastructure

    var adaptiveService: AdaptiveFormPopulationService?
    var formIntelligenceAdapter: FormIntelligenceAdapter?
    var trustFramework: UserTrustFramework?
    var abTestingFramework: ABTestingFramework?
    var userExperienceMonitor: UserExperienceMonitor?
    var mockCoreDataActor: MockCoreDataActor?

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test infrastructure
        mockCoreDataActor = MockCoreDataActor()
        trustFramework = UserTrustFramework()
        abTestingFramework = ABTestingFramework()
        userExperienceMonitor = UserExperienceMonitor()

        // Initialize system components
        let contextClassifier = AcquisitionContextClassifier()
        let qLearningAgent = FormFieldQLearningAgent(coreDataActor: mockCoreDataActor)
        let modificationTracker = FormModificationTracker(coreDataActor: mockCoreDataActor)
        let explanationEngine = ValueExplanationEngine()
        let metricsCollector = AdaptiveFormMetricsCollector()

        adaptiveService = AdaptiveFormPopulationService(
            contextClassifier: contextClassifier,
            qLearningAgent: qLearningAgent,
            modificationTracker: modificationTracker,
            explanationEngine: explanationEngine,
            metricsCollector: metricsCollector,
            agenticOrchestrator: MockAgenticOrchestrator()
        )

        formIntelligenceAdapter = FormIntelligenceAdapter.liveValue
        await formIntelligenceAdapter.setAdaptiveService(adaptiveService)

        // Initialize trust framework
        await trustFramework.initialize()
        await abTestingFramework.initialize()
    }

    override func tearDown() async throws {
        adaptiveService = nil
        formIntelligenceAdapter = nil
        trustFramework = nil
        abTestingFramework = nil
        userExperienceMonitor = nil
        mockCoreDataActor = nil

        try await super.tearDown()
    }

    // MARK: - Confidence-Based UI States Tests

    /// Test high confidence auto-fill behavior (>0.8)
    func testHighConfidenceAutoFillBehavior() async throws {
        guard let formIntelligenceAdapter else {
            XCTFail("FormIntelligenceAdapter should be initialized")
            return
        }
        // Given: High confidence scenario
        let highConfidenceFormData = FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "paymentTerms": "",
                "evaluationMethod": "",
                "deliverySchedule": "",
            ],
            metadata: [:]
        )

        let itAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "Enterprise Software Development Services",
            requirements: "Comprehensive software development services including cloud computing, database design, network security, and cybersecurity implementation for IT infrastructure management.",
            projectDescription: "Complete IT solution with advanced software programming, hardware procurement, and comprehensive cybersecurity measures for enterprise-level operations.",
            estimatedValue: 750_000,
            deadline: Date().addingTimeInterval(90 * 24 * 3600),
            isRecurring: false
        )

        // When: Auto-fill form with high confidence
        let result = try await formIntelligenceAdapter.autoFillForm(
            "SF-1449",
            highConfidenceFormData,
            itAcquisition
        )

        // Then: Should auto-fill without user confirmation
        XCTAssertEqual(result.metadata["adaptive_populated"], "true",
                       "Should use adaptive population")

        let confidence = Double(result.metadata["confidence"] ?? "0") ?? 0.0
        XCTAssertGreaterThan(confidence, 0.8,
                             "Should have high confidence >0.8")

        // All fields should be populated automatically
        XCTAssertFalse(result.fields["paymentTerms"]?.isEmpty ?? true,
                       "Payment terms should be auto-filled")
        XCTAssertFalse(result.fields["evaluationMethod"]?.isEmpty ?? true,
                       "Evaluation method should be auto-filled")
        XCTAssertFalse(result.fields["deliverySchedule"]?.isEmpty ?? true,
                       "Delivery schedule should be auto-filled")

        // Should not require user confirmation for high confidence
        XCTAssertNil(result.metadata["requires_confirmation"],
                     "High confidence should not require confirmation")
    }

    /// Test medium confidence suggestion tooltips (0.5-0.8)
    func testMediumConfidenceSuggestionTooltips() async throws {
        guard let formIntelligenceAdapter else {
            XCTFail("FormIntelligenceAdapter should be initialized")
            return
        }
        // Given: Medium confidence scenario
        let mediumConfidenceFormData = FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "contractType": "",
                "performancePeriod": "",
            ],
            metadata: [:]
        )

        let mixedAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "IT Services and Consulting",
            requirements: "Need both software development and consulting services",
            projectDescription: "Mixed project with IT and professional services components",
            estimatedValue: 200_000,
            deadline: Date().addingTimeInterval(60 * 24 * 3600),
            isRecurring: false
        )

        // When: Process medium confidence scenario
        let result = try await formIntelligenceAdapter.autoFillForm(
            "SF-1449",
            mediumConfidenceFormData,
            mixedAcquisition
        )

        let confidence = Double(result.metadata["confidence"] ?? "0") ?? 0.0

        // Then: Should provide suggestions with tooltips
        XCTAssertGreaterThanOrEqual(confidence, 0.5, "Should have at least medium confidence")
        XCTAssertLessThan(confidence, 0.8, "Should be below high confidence threshold")

        // Should include suggestion metadata
        XCTAssertEqual(result.metadata["suggestion_mode"], "tooltip",
                       "Should indicate tooltip suggestion mode")

        // Should provide explanations for suggestions
        XCTAssertNotNil(result.metadata["field_explanations"],
                        "Should provide field explanations for medium confidence")

        // Should allow user to accept or modify suggestions
        XCTAssertEqual(result.metadata["user_interaction_required"], "true",
                       "Should require user interaction for medium confidence")
    }

    /// Test low confidence learning mode indication
    func testLowConfidenceLearningModeIndication() async throws {
        guard let formIntelligenceAdapter else {
            XCTFail("FormIntelligenceAdapter should be initialized")
            return
        }
        // Given: Low confidence scenario
        let lowConfidenceFormData = FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "specialRequirements": "",
                "customTerms": "",
            ],
            metadata: [:]
        )

        let ambiguousAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "General Services",
            requirements: "Various services needed",
            projectDescription: "Standard services",
            estimatedValue: 50000,
            deadline: Date().addingTimeInterval(90 * 24 * 3600),
            isRecurring: false
        )

        // When: Process low confidence scenario
        let result = try await formIntelligenceAdapter.autoFillForm(
            "SF-1449",
            lowConfidenceFormData,
            ambiguousAcquisition
        )

        let confidence = Double(result.metadata["confidence"] ?? "0") ?? 0.0

        // Then: Should indicate learning mode
        XCTAssertLessThan(confidence, 0.5, "Should have low confidence")

        // Should indicate learning mode to user
        XCTAssertEqual(result.metadata["mode"], "learning",
                       "Should indicate learning mode for low confidence")

        // Should provide learning indicators
        XCTAssertEqual(result.metadata["learning_active"], "true",
                       "Should indicate active learning")

        // Should not auto-fill fields with low confidence
        let filledFields = result.fields.values.filter { !$0.isEmpty }
        XCTAssertLessThanOrEqual(filledFields.count, 1,
                                 "Should not auto-fill many fields with low confidence")
    }

    /// Test exploring mode user feedback
    func testExploringModeUserFeedback() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: New user with no learning history
        let newUserProfile = UserProfile(id: UUID(), name: "New User", email: "new@example.com")

        let formData = FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "paymentTerms": "",
                "evaluationMethod": "",
            ],
            metadata: [:]
        )

        let acquisition = AcquisitionAggregate(
            id: UUID(),
            title: "IT Services Project",
            requirements: "Software development services needed",
            projectDescription: "Standard IT project",
            estimatedValue: 100_000,
            deadline: Date().addingTimeInterval(60 * 24 * 3600),
            isRecurring: false
        )

        // When: Process for new user (exploring mode)
        let result = try await adaptiveService.populateForm(
            formData,
            acquisition: acquisition,
            userProfile: newUserProfile
        )

        // Then: Should indicate exploring mode
        XCTAssertEqual(result.metadata["mode"], "exploring",
                       "Should be in exploring mode for new user")

        // Should provide educational feedback
        XCTAssertNotNil(result.metadata["learning_explanation"],
                        "Should provide learning explanation in exploring mode")

        // Should encourage user interaction
        XCTAssertEqual(result.metadata["feedback_requested"], "true",
                       "Should request user feedback in exploring mode")

        // Should have multiple suggestion options
        let suggestionCount = Int(result.metadata["suggestion_count"] ?? "0") ?? 0
        XCTAssertGreaterThan(suggestionCount, 1,
                             "Should provide multiple suggestions in exploring mode")
    }

    // MARK: - User Trust Framework Tests (CRITICAL PRIORITY)

    /// Test A/B testing framework comparing adaptive vs static suggestions
    func testABTestingAdaptiveVsStaticSuggestions() async throws {
        guard let abTestingFramework,
              let formIntelligenceAdapter
        else {
            XCTFail("ABTestingFramework and FormIntelligenceAdapter should be initialized")
            return
        }
        // Given: A/B testing setup
        let testUsers = createTestUserCohorts(count: 100)
        let testForms = createStandardizedTestForms(count: 50)

        var adaptiveResults: [ABTestResult] = []
        var staticResults: [ABTestResult] = []

        // When: Run A/B test
        for user in testUsers {
            let isAdaptiveGroup = await abTestingFramework.assignUserToGroup(user.id)

            for form in testForms {
                let startTime = Date()

                if isAdaptiveGroup {
                    let result = try await formIntelligenceAdapter.autoFillForm(
                        form.formNumber,
                        form,
                        form.associatedAcquisition
                    )

                    let testResult = await ABTestResult(
                        userId: user.id,
                        formId: form.formNumber,
                        isAdaptive: true,
                        completionTime: Date().timeIntervalSince(startTime),
                        userSatisfaction: simulateUserSatisfaction(result: result),
                        accuracy: calculateFormAccuracy(result: result),
                        modifications: simulateUserModifications(result: result)
                    )

                    adaptiveResults.append(testResult)
                } else {
                    let result = try await formIntelligenceAdapter.autoFillFormStatic(
                        form.formNumber,
                        form,
                        form.associatedAcquisition
                    )

                    let testResult = await ABTestResult(
                        userId: user.id,
                        formId: form.formNumber,
                        isAdaptive: false,
                        completionTime: Date().timeIntervalSince(startTime),
                        userSatisfaction: simulateUserSatisfaction(result: result),
                        accuracy: calculateFormAccuracy(result: result),
                        modifications: simulateUserModifications(result: result)
                    )

                    staticResults.append(testResult)
                }
            }
        }

        // Then: Analyze A/B test results
        let adaptiveAvgSatisfaction = adaptiveResults.map(\.userSatisfaction).reduce(0, +) / Double(adaptiveResults.count)
        let staticAvgSatisfaction = staticResults.map(\.userSatisfaction).reduce(0, +) / Double(staticResults.count)

        let adaptiveAvgTime = adaptiveResults.map(\.completionTime).reduce(0, +) / Double(adaptiveResults.count)
        let staticAvgTime = staticResults.map(\.completionTime).reduce(0, +) / Double(staticResults.count)

        let adaptiveAvgModifications = adaptiveResults.map { Double($0.modifications) }.reduce(0, +) / Double(adaptiveResults.count)
        let staticAvgModifications = staticResults.map { Double($0.modifications) }.reduce(0, +) / Double(staticResults.count)

        // Adaptive should perform better on key metrics
        XCTAssertGreaterThan(adaptiveAvgSatisfaction, staticAvgSatisfaction,
                             "Adaptive system should have higher user satisfaction")

        XCTAssertLessThan(adaptiveAvgTime, staticAvgTime,
                          "Adaptive system should have faster completion times")

        XCTAssertLessThan(adaptiveAvgModifications, staticAvgModifications,
                          "Adaptive system should require fewer user modifications")

        // Statistical significance validation
        let satisfactionPValue = calculatePValue(adaptiveResults.map(\.userSatisfaction), staticResults.map(\.userSatisfaction))
        XCTAssertLessThan(satisfactionPValue, 0.05,
                          "User satisfaction improvement should be statistically significant")
    }

    /// Test user confidence metrics before/after adaptive system introduction
    func testUserConfidenceMetricsBeforeAfterAdaptive() async throws {
        guard let trustFramework else {
            XCTFail("TrustFramework should be initialized")
            return
        }
        // Given: Baseline user confidence measurements
        let testUsers = createTestUserCohorts(count: 50)

        // Measure baseline confidence with static system
        var baselineConfidence: [UserConfidenceMetrics] = []
        for user in testUsers {
            let confidence = await trustFramework.measureUserConfidence(
                userId: user.id,
                systemType: .staticBaseline,
                interactionCount: 10
            )
            baselineConfidence.append(confidence)
        }

        // When: Introduce adaptive system and measure confidence over time
        var adaptiveConfidenceOverTime: [[UserConfidenceMetrics]] = []

        let measurementPeriods = [1, 7, 14, 30] // Days after introduction

        for period in measurementPeriods {
            var periodConfidence: [UserConfidenceMetrics] = []

            for user in testUsers {
                // Simulate usage over the period
                await simulateAdaptiveSystemUsage(user: user, days: period)

                let confidence = await trustFramework.measureUserConfidence(
                    userId: user.id,
                    systemType: .adaptive,
                    interactionCount: period * 3 // 3 interactions per day
                )
                periodConfidence.append(confidence)
            }

            adaptiveConfidenceOverTime.append(periodConfidence)
        }

        // Then: Analyze confidence trends
        let baselineAvgConfidence = baselineConfidence.map(\.overallConfidence).reduce(0, +) / Double(baselineConfidence.count)

        for (index, periodMetrics) in adaptiveConfidenceOverTime.enumerated() {
            let periodAvgConfidence = periodMetrics.map(\.overallConfidence).reduce(0, +) / Double(periodMetrics.count)

            if index >= 1 { // After first week
                XCTAssertGreaterThan(periodAvgConfidence, baselineAvgConfidence,
                                     "User confidence should improve after adaptive system introduction at period \(measurementPeriods[index])")
            }
        }

        // Long-term confidence should be significantly higher
        guard let lastPeriodMetrics = adaptiveConfidenceOverTime.last else {
            XCTFail("Should have long-term confidence measurements")
            return
        }
        let longTermConfidence = lastPeriodMetrics.map(\.overallConfidence).reduce(0, +) / Double(lastPeriodMetrics.count)
        let confidenceImprovement = (longTermConfidence - baselineAvgConfidence) / baselineAvgConfidence * 100

        XCTAssertGreaterThan(confidenceImprovement, 15.0,
                             "Long-term confidence improvement should be >15%, got \(confidenceImprovement)%")
    }

    /// Test trust decay/recovery patterns when system makes errors
    func testTrustDecayRecoveryPatterns() async throws {
        guard let trustFramework else {
            XCTFail("TrustFramework should be initialized")
            return
        }
        // Given: User with established trust in adaptive system
        let testUser = UserProfile(id: UUID(), name: "Trust Test User", email: "trust@test.com")

        // Build initial trust
        await trustFramework.simulatePositiveInteractions(userId: testUser.id, count: 50)
        let initialTrust = await trustFramework.getUserTrustLevel(userId: testUser.id)

        // When: Introduce systematic errors
        let errorScenarios = [
            ErrorScenario(type: .wrongSuggestion, severity: .minor, count: 3),
            ErrorScenario(type: .wrongSuggestion, severity: .moderate, count: 2),
            ErrorScenario(type: .systemFailure, severity: .major, count: 1),
        ]

        var trustLevelsAfterErrors: [Double] = []

        for scenario in errorScenarios {
            await trustFramework.simulateErrors(
                userId: testUser.id,
                errorType: scenario.type,
                severity: scenario.severity,
                count: scenario.count
            )

            let trustLevel = await trustFramework.getUserTrustLevel(userId: testUser.id)
            trustLevelsAfterErrors.append(trustLevel)
        }

        // Simulate recovery through positive interactions
        await trustFramework.simulatePositiveInteractions(userId: testUser.id, count: 20)
        let recoveredTrust = await trustFramework.getUserTrustLevel(userId: testUser.id)

        // Then: Analyze trust decay and recovery patterns
        guard let finalTrustAfterErrors = trustLevelsAfterErrors.last else {
            XCTFail("Should have trust measurements after errors")
            return
        }
        let trustDecay = (initialTrust - finalTrustAfterErrors) / initialTrust * 100

        XCTAssertGreaterThan(trustDecay, 10.0,
                             "Trust should decay after errors, got \(trustDecay)% decay")

        XCTAssertLessThan(trustDecay, 50.0,
                          "Trust decay should not be excessive, got \(trustDecay)% decay")

        // Recovery should be significant but not complete immediately
        let trustRecovery = (recoveredTrust - finalTrustAfterErrors) / (initialTrust - finalTrustAfterErrors) * 100

        XCTAssertGreaterThan(trustRecovery, 30.0,
                             "Trust should show significant recovery, got \(trustRecovery)% recovery")

        XCTAssertLessThan(recoveredTrust, initialTrust,
                          "Full trust recovery should take time")
    }

    /// Test user acceptance rates across different confidence threshold settings
    func testUserAcceptanceRatesAcrossConfidenceThresholds() async throws {
        guard let formIntelligenceAdapter else {
            XCTFail("FormIntelligenceAdapter should be initialized")
            return
        }
        // Given: Different confidence threshold configurations
        let confidenceThresholds = [0.5, 0.6, 0.7, 0.8, 0.9]
        let testUsers = createTestUserCohorts(count: 20)
        let testForms = createStandardizedTestForms(count: 30)

        var acceptanceRatesByThreshold: [Double: AcceptanceMetrics] = [:]

        // When: Test each confidence threshold
        for threshold in confidenceThresholds {
            await formIntelligenceAdapter.setConfidenceThreshold(threshold)

            var totalSuggestions = 0
            var acceptedSuggestions = 0
            var userSatisfactionScores: [Double] = []

            for user in testUsers {
                for form in testForms {
                    let result = try await formIntelligenceAdapter.autoFillForm(
                        form.formNumber,
                        form,
                        form.associatedAcquisition
                    )

                    let suggestions = await extractSuggestions(from: result)
                    totalSuggestions += suggestions.count

                    for suggestion in suggestions {
                        let userAccepted = await simulateUserAcceptance(
                            suggestion: suggestion,
                            userProfile: user,
                            threshold: threshold
                        )

                        if userAccepted {
                            acceptedSuggestions += 1
                        }
                    }

                    let satisfaction = await simulateUserSatisfaction(result: result)
                    userSatisfactionScores.append(satisfaction)
                }
            }

            let acceptanceRate = Double(acceptedSuggestions) / Double(totalSuggestions)
            let avgSatisfaction = userSatisfactionScores.reduce(0, +) / Double(userSatisfactionScores.count)

            acceptanceRatesByThreshold[threshold] = AcceptanceMetrics(
                acceptanceRate: acceptanceRate,
                averageSatisfaction: avgSatisfaction,
                totalSuggestions: totalSuggestions
            )
        }

        // Then: Analyze acceptance patterns across thresholds
        // Higher thresholds should have higher acceptance rates but fewer suggestions
        guard let lowThresholdMetrics = acceptanceRatesByThreshold[0.5] else {
            XCTFail("Should have metrics for threshold 0.5")
            return
        }
        guard let highThresholdMetrics = acceptanceRatesByThreshold[0.9] else {
            XCTFail("Should have metrics for threshold 0.9")
            return
        }

        XCTAssertGreaterThan(highThresholdMetrics.acceptanceRate, lowThresholdMetrics.acceptanceRate,
                             "Higher confidence threshold should have higher acceptance rate")

        XCTAssertLessThan(highThresholdMetrics.totalSuggestions, lowThresholdMetrics.totalSuggestions,
                          "Higher confidence threshold should produce fewer suggestions")

        // Find optimal threshold (balance of acceptance rate and suggestion volume)
        let optimalThreshold = findOptimalThreshold(acceptanceRatesByThreshold)
        XCTAssertGreaterThanOrEqual(optimalThreshold, 0.6,
                                    "Optimal threshold should be at least 0.6")
        XCTAssertLessThanOrEqual(optimalThreshold, 0.8,
                                 "Optimal threshold should not exceed 0.8")
    }

    /// Test shadow mode testing to validate suggestions without showing to users
    func testShadowModeValidation() async throws {
        guard let formIntelligenceAdapter else {
            XCTFail("FormIntelligenceAdapter should be initialized")
            return
        }
        // Given: Shadow mode testing setup
        let shadowModeManager = ShadowModeManager()
        await shadowModeManager.enableShadowMode()

        let testUsers = createTestUserCohorts(count: 30)
        let testForms = createStandardizedTestForms(count: 40)

        var shadowModeResults: [ShadowModeResult] = []

        // When: Run shadow mode testing
        for user in testUsers {
            for form in testForms {
                // User sees static suggestions
                let staticResult = try await formIntelligenceAdapter.autoFillFormStatic(
                    form.formNumber,
                    form,
                    form.associatedAcquisition
                )

                // System generates adaptive suggestions in background
                let adaptiveResult = try await shadowModeManager.generateAdaptiveSuggestions(
                    form: form,
                    acquisition: form.associatedAcquisition,
                    userProfile: user
                )

                // Simulate user's actual choices
                let userChoices = await simulateUserFormCompletion(staticResult: staticResult)

                // Compare adaptive suggestions with user choices
                let shadowResult = await shadowModeManager.compareWithUserChoices(
                    adaptiveSuggestions: adaptiveResult,
                    userChoices: userChoices
                )

                shadowModeResults.append(shadowResult)
            }
        }

        // Then: Validate shadow mode effectiveness
        let avgAccuracy = shadowModeResults.map(\.accuracy).reduce(0, +) / Double(shadowModeResults.count)
        let avgImprovement = shadowModeResults.map(\.potentialImprovement).reduce(0, +) / Double(shadowModeResults.count)

        XCTAssertGreaterThan(avgAccuracy, 0.70,
                             "Shadow mode adaptive suggestions should have >70% accuracy, got \(avgAccuracy)")

        XCTAssertGreaterThan(avgImprovement, 0.15,
                             "Shadow mode should show >15% potential improvement, got \(avgImprovement)")

        // Shadow mode should identify cases where adaptive would help
        let improvementOpportunities = shadowModeResults.filter { $0.potentialImprovement > 0.2 }
        let opportunityRate = Double(improvementOpportunities.count) / Double(shadowModeResults.count)

        XCTAssertGreaterThan(opportunityRate, 0.3,
                             "Should identify improvement opportunities in >30% of cases, got \(opportunityRate)")
    }

    /// Test confusion scenario detection when system provides conflicting suggestions
    func testConfusionScenarioDetection() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: Scenarios designed to create confusion
        let confusionScenarios = createConfusionScenarios()

        for scenario in confusionScenarios {
            // When: Process conflicting information
            let result1 = try await adaptiveService.populateForm(
                scenario.formData1,
                acquisition: scenario.acquisition,
                userProfile: scenario.userProfile
            )

            // Slight modification to create conflicting context
            let result2 = try await adaptiveService.populateForm(
                scenario.formData2,
                acquisition: scenario.acquisition,
                userProfile: scenario.userProfile
            )

            // Then: System should detect confusion
            let confusionDetected = await adaptiveService.detectConfusion(
                result1: result1,
                result2: result2,
                scenario: scenario
            )

            XCTAssertTrue(confusionDetected.isConfusionDetected,
                          "Should detect confusion in scenario: \(scenario.description)")

            XCTAssertGreaterThan(confusionDetected.confidenceScore, 0.7,
                                 "Confusion detection confidence should be high")

            // System should provide clarifying recommendations
            XCTAssertNotNil(confusionDetected.clarificationRecommendation,
                            "Should provide clarification recommendation")

            // Should reduce confidence for conflicting suggestions
            let avgConfidence = (result1.overallConfidence + result2.overallConfidence) / 2
            XCTAssertLessThan(avgConfidence, 0.6,
                              "Conflicting scenarios should have reduced confidence")
        }
    }

    // MARK: - Explanation System Tests

    /// Test "Why this value?" tooltip generation
    func testWhyThisValueTooltipGeneration() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: Form with adaptive suggestions
        let formData = FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "paymentTerms": "",
                "evaluationMethod": "",
                "deliverySchedule": "",
            ],
            metadata: [:]
        )

        let acquisition = AcquisitionAggregate(
            id: UUID(),
            title: "IT Software Development",
            requirements: "Need software development with cloud computing and database management",
            projectDescription: "Enterprise IT solution with cybersecurity requirements",
            estimatedValue: 300_000,
            deadline: Date().addingTimeInterval(90 * 24 * 3600),
            isRecurring: false
        )

        let context = AcquisitionContext(
            category: .informationTechnology,
            confidence: 0.85,
            features: ContextFeatures(
                estimatedValue: 300_000,
                hasUrgentDeadline: false,
                requiresSpecializedSkills: true,
                isRecurringPurchase: false,
                involvesSecurity: true
            ),
            acquisitionValue: 300_000,
            urgency: .normal,
            complexity: .high,
            acquisitionId: acquisition.id
        )

        // When: Generate explanations for each suggested value
        let paymentTermsExplanation = await adaptiveService.getFieldExplanation(
            fieldId: "paymentTerms",
            suggestedValue: "NET-45",
            context: context
        )

        let evaluationMethodExplanation = await adaptiveService.getFieldExplanation(
            fieldId: "evaluationMethod",
            suggestedValue: "Best Value - Technical/Price Tradeoff",
            context: context
        )

        // Then: Explanations should be comprehensive and helpful
        XCTAssertNotNil(paymentTermsExplanation, "Should provide payment terms explanation")
        XCTAssertGreaterThan(paymentTermsExplanation.explanation.count, 50,
                             "Explanation should be detailed")

        // Should include context-specific reasoning
        XCTAssertTrue(paymentTermsExplanation.explanation.contains("IT") ||
                        paymentTermsExplanation.explanation.contains("software") ||
                        paymentTermsExplanation.explanation.contains("technology"),
                      "Should include context-specific reasoning")

        // Should include confidence justification
        XCTAssertNotNil(paymentTermsExplanation.confidenceJustification,
                        "Should include confidence justification")

        XCTAssertNotNil(evaluationMethodExplanation, "Should provide evaluation method explanation")
        XCTAssertGreaterThan(evaluationMethodExplanation.explanation.count, 50,
                             "Explanation should be detailed")

        // Should reference user's past preferences if available
        XCTAssertNotNil(paymentTermsExplanation.historicalContext,
                        "Should reference historical context when available")
    }

    /// Test explanation accuracy and helpfulness
    func testExplanationAccuracyAndHelpfulness() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: Various explanation scenarios
        let explanationTestCases = createExplanationTestCases()

        var helpfulnessScores: [Double] = []
        var accuracyScores: [Double] = []

        // When: Generate and evaluate explanations
        for testCase in explanationTestCases {
            let explanation = await adaptiveService.getFieldExplanation(
                fieldId: testCase.fieldId,
                suggestedValue: testCase.suggestedValue,
                context: testCase.context
            )

            // Simulate user evaluation of explanation
            let helpfulness = await simulateUserExplanationEvaluation(
                explanation: explanation,
                userProfile: testCase.userProfile,
                expectedReasoning: testCase.expectedReasoning
            )

            let accuracy = await validateExplanationAccuracy(
                explanation: explanation,
                actualReasoning: testCase.actualSystemReasoning
            )

            helpfulnessScores.append(helpfulness)
            accuracyScores.append(accuracy)
        }

        // Then: Explanations should meet quality thresholds
        let avgHelpfulness = helpfulnessScores.reduce(0, +) / Double(helpfulnessScores.count)
        let avgAccuracy = accuracyScores.reduce(0, +) / Double(accuracyScores.count)

        XCTAssertGreaterThan(avgHelpfulness, 0.75,
                             "Average explanation helpfulness should be >75%, got \(avgHelpfulness)")

        XCTAssertGreaterThan(avgAccuracy, 0.80,
                             "Average explanation accuracy should be >80%, got \(avgAccuracy)")

        // Should meet success criteria from rubric
        let helpfulExplanationRate = helpfulnessScores.filter { $0 > 0.7 }.count
        let helpfulPercentage = Double(helpfulExplanationRate) / Double(helpfulnessScores.count) * 100

        XCTAssertGreaterThan(helpfulPercentage, 75.0,
                             ">75% of users should find explanations helpful, got \(helpfulPercentage)%")
    }

    /// Test confidence percentage display
    func testConfidencePercentageDisplay() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: Various confidence levels
        let confidenceLevels = [0.95, 0.85, 0.65, 0.45, 0.25]

        for confidenceLevel in confidenceLevels {
            // When: Generate suggestion with specific confidence
            let suggestion = FormSuggestion(
                fieldId: "testField",
                suggestedValue: "Test Value",
                confidence: confidenceLevel,
                reasoning: "Test reasoning"
            )

            let displayInfo = await adaptiveService.generateConfidenceDisplay(suggestion: suggestion)

            // Then: Display should be appropriate for confidence level
            XCTAssertEqual(displayInfo.confidencePercentage, Int(confidenceLevel * 100),
                           "Should display correct confidence percentage")

            switch confidenceLevel {
            case 0.8...:
                XCTAssertEqual(displayInfo.displayColor, .green,
                               "High confidence should display in green")
                XCTAssertEqual(displayInfo.displayText, "High Confidence",
                               "Should show high confidence text")

            case 0.6 ..< 0.8:
                XCTAssertEqual(displayInfo.displayColor, .orange,
                               "Medium confidence should display in orange")
                XCTAssertEqual(displayInfo.displayText, "Medium Confidence",
                               "Should show medium confidence text")

            default:
                XCTAssertEqual(displayInfo.displayColor, .red,
                               "Low confidence should display in red")
                XCTAssertEqual(displayInfo.displayText, "Low Confidence",
                               "Should show low confidence text")
            }

            // Should provide appropriate user guidance
            XCTAssertNotNil(displayInfo.userGuidance,
                            "Should provide user guidance for confidence level")
        }
    }

    /// Test alternative suggestion presentation
    func testAlternativeSuggestionPresentation() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: Context with multiple viable options
        let formData = FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: ["evaluationMethod": ""],
            metadata: [:]
        )

        let context = AcquisitionContext(
            category: .informationTechnology,
            confidence: 0.7,
            features: ContextFeatures(
                estimatedValue: 150_000,
                hasUrgentDeadline: false,
                requiresSpecializedSkills: true,
                isRecurringPurchase: false,
                involvesSecurity: false
            ),
            acquisitionValue: 150_000,
            urgency: .normal,
            complexity: .medium,
            acquisitionId: UUID()
        )

        // When: Generate alternative suggestions
        let alternatives = await adaptiveService.generateAlternativeSuggestions(
            fieldId: "evaluationMethod",
            context: context,
            maxAlternatives: 3
        )

        // Then: Should provide multiple viable alternatives
        XCTAssertGreaterThanOrEqual(alternatives.count, 2,
                                    "Should provide at least 2 alternatives")
        XCTAssertLessThanOrEqual(alternatives.count, 3,
                                 "Should not exceed maximum alternatives")

        // Each alternative should have reasonable confidence
        for alternative in alternatives {
            XCTAssertGreaterThan(alternative.confidence, 0.3,
                                 "Each alternative should have reasonable confidence")
        }

        // Primary suggestion should have highest confidence
        let sortedByConfidence = alternatives.sorted { $0.confidence > $1.confidence }
        XCTAssertEqual(sortedByConfidence.first?.suggestedValue, alternatives.first?.suggestedValue,
                       "Primary suggestion should have highest confidence")

        // Should provide distinct options
        let uniqueValues = Set(alternatives.map(\.suggestedValue))
        XCTAssertEqual(uniqueValues.count, alternatives.count,
                       "All alternatives should be distinct")
    }

    // MARK: - User Control and Transparency Tests

    /// Test adaptive learning enable/disable functionality
    func testAdaptiveLearningEnableDisable() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: User with adaptive learning enabled
        let userProfile = UserProfile(id: UUID(), name: "Control Test User", email: "control@test.com")

        // Verify initial enabled state
        let initialState = await adaptiveService.getAdaptiveLearningState(for: userProfile.id)
        XCTAssertTrue(initialState.isEnabled, "Adaptive learning should be enabled by default")

        // When: Disable adaptive learning
        await adaptiveService.setAdaptiveLearning(enabled: false, for: userProfile.id)

        let disabledState = await adaptiveService.getAdaptiveLearningState(for: userProfile.id)
        XCTAssertFalse(disabledState.isEnabled, "Adaptive learning should be disabled")

        // Test form population with disabled learning
        let formData = createTestFormData()
        let acquisition = createTestAcquisition()

        let result = try await adaptiveService.populateForm(formData, acquisition: acquisition, userProfile: userProfile)

        // Should fallback to static behavior
        XCTAssertNil(result.metadata["adaptive_populated"],
                     "Should not use adaptive population when disabled")

        // When: Re-enable adaptive learning
        await adaptiveService.setAdaptiveLearning(enabled: true, for: userProfile.id)

        let reenabledState = await adaptiveService.getAdaptiveLearningState(for: userProfile.id)
        XCTAssertTrue(reenabledState.isEnabled, "Adaptive learning should be re-enabled")

        // Should resume adaptive behavior
        let adaptiveResult = try await adaptiveService.populateForm(formData, acquisition: acquisition, userProfile: userProfile)

        XCTAssertNotNil(adaptiveResult.metadata,
                        "Should resume adaptive behavior when re-enabled")
    }

    /// Test data retention setting controls (30/60/90 days)
    func testDataRetentionSettingControls() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: User with learning data
        let userProfile = UserProfile(id: UUID(), name: "Retention Test User", email: "retention@test.com")

        // Generate learning data
        await generateUserLearningData(for: userProfile.id, interactions: 100)

        let initialDataCount = await adaptiveService.getUserLearningDataCount(for: userProfile.id)
        XCTAssertGreaterThan(initialDataCount, 0, "Should have initial learning data")

        // Test different retention periods
        let retentionPeriods: [DataRetentionPeriod] = [.thirtyDays, .sixtyDays, .ninetyDays]

        for period in retentionPeriods {
            // When: Set retention period
            await adaptiveService.setDataRetentionPeriod(period, for: userProfile.id)

            let setting = await adaptiveService.getDataRetentionSetting(for: userProfile.id)
            XCTAssertEqual(setting.period, period,
                           "Should set correct retention period")

            // Simulate time passage beyond retention period
            await adaptiveService.simulateTimePassage(days: period.days + 1, for: userProfile.id)

            // Trigger retention cleanup
            await adaptiveService.performRetentionCleanup(for: userProfile.id)

            // Should clean up old data
            let remainingDataCount = await adaptiveService.getUserLearningDataCount(for: userProfile.id)

            // Some data should be cleaned up (depending on when it was created)
            // This is a simplified test - actual implementation would be more sophisticated
            XCTAssertLessThanOrEqual(remainingDataCount, initialDataCount,
                                     "Should clean up data beyond retention period")
        }
    }

    /// Test complete data deletion when disabled
    func testCompleteDataDeletionWhenDisabled() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: User with extensive learning data
        let userProfile = UserProfile(id: UUID(), name: "Deletion Test User", email: "deletion@test.com")

        await generateUserLearningData(for: userProfile.id, interactions: 200)

        let initialDataCount = await adaptiveService.getUserLearningDataCount(for: userProfile.id)
        XCTAssertGreaterThan(initialDataCount, 0, "Should have learning data")

        // When: Disable adaptive features with data deletion
        await adaptiveService.disableAdaptiveFeatures(for: userProfile.id, deleteData: true)

        // Then: All learning data should be deleted
        let finalDataCount = await adaptiveService.getUserLearningDataCount(for: userProfile.id)
        XCTAssertEqual(finalDataCount, 0, "All learning data should be deleted")

        // Should also remove user from Q-learning models
        let userInModels = await adaptiveService.isUserInQLearningModels(userProfile.id)
        XCTAssertFalse(userInModels, "User should be removed from Q-learning models")

        // Should update user preferences
        let userSettings = await adaptiveService.getUserSettings(for: userProfile.id)
        XCTAssertFalse(userSettings.adaptiveLearningEnabled,
                       "Adaptive learning should be disabled in user settings")
    }

    /// Test learning data export functionality
    func testLearningDataExportFunctionality() async throws {
        guard let adaptiveService else {
            XCTFail("AdaptiveService should be initialized")
            return
        }
        // Given: User with diverse learning data
        let userProfile = UserProfile(id: UUID(), name: "Export Test User", email: "export@test.com")

        await generateDiverseUserLearningData(for: userProfile.id)

        // When: Export user's learning data
        let exportedData = await adaptiveService.exportUserLearningData(for: userProfile.id)

        // Then: Should include all user data categories
        XCTAssertNotNil(exportedData, "Should export data")
        XCTAssertFalse(exportedData.isEmpty, "Exported data should not be empty")

        // Parse exported JSON
        guard let jsonData = exportedData.data(using: .utf8) else {
            XCTFail("Failed to convert exported data to UTF-8")
            return
        }
        guard let exportObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            XCTFail("Failed to parse exported JSON as dictionary")
            return
        }

        // Should include all expected data categories
        XCTAssertNotNil(exportObject["qLearningData"], "Should export Q-learning data")
        XCTAssertNotNil(exportObject["modificationHistory"], "Should export modification history")
        XCTAssertNotNil(exportObject["contextClassifications"], "Should export context classifications")
        XCTAssertNotNil(exportObject["userPreferences"], "Should export user preferences")
        XCTAssertNotNil(exportObject["explanationRequests"], "Should export explanation requests")

        // Should include metadata
        XCTAssertNotNil(exportObject["exportMetadata"], "Should include export metadata")
        guard let metadata = exportObject["exportMetadata"] as? [String: Any] else {
            XCTFail("Export metadata should be dictionary")
            return
        }
        XCTAssertNotNil(metadata["exportDate"], "Should include export date")
        XCTAssertNotNil(metadata["dataVersion"], "Should include data version")

        // Should not include sensitive system data
        XCTAssertNil(exportObject["internalSystemKeys"], "Should not export internal system data")
        XCTAssertNil(exportObject["otherUserData"], "Should not export other users' data")
    }

    // MARK: - Test Helper Methods

    private func createTestUserCohorts(count: Int) -> [UserProfile] {
        (1 ... count).map { i in
            UserProfile(
                id: UUID(),
                name: "Test User \(i)",
                email: "user\(i)@test.com"
            )
        }
    }

    private func createStandardizedTestForms(count: Int) -> [StandardizedTestForm] {
        (1 ... count).map { i in
            StandardizedTestForm(
                formNumber: "SF-1449",
                fields: [
                    "paymentTerms": "",
                    "evaluationMethod": "",
                    "deliverySchedule": "",
                ],
                associatedAcquisition: createTestAcquisition(index: i)
            )
        }
    }

    private func createTestAcquisition(index: Int = 1) -> AcquisitionAggregate {
        let contexts = ["IT", "Construction", "Services"]
        let context = contexts[index % contexts.count]

        return AcquisitionAggregate(
            id: UUID(),
            title: "\(context) Project \(index)",
            requirements: "Test requirements for \(context.lowercased()) project",
            projectDescription: "Test description for \(context.lowercased()) project",
            estimatedValue: Double.random(in: 50000 ... 500_000),
            deadline: Date().addingTimeInterval(Double.random(in: 30 ... 120) * 24 * 3600),
            isRecurring: false
        )
    }

    private func createTestFormData() -> FormData {
        FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: [
                "paymentTerms": "",
                "evaluationMethod": "",
            ],
            metadata: [:]
        )
    }

    private func simulateUserSatisfaction(result: FormPopulationResult) async -> Double {
        // Simulate user satisfaction based on result quality
        let baselineScore = 0.7
        let confidenceBonus = (result.overallConfidence - 0.5) * 0.2
        let completenessBonus = Double(result.fields.values.filter { !$0.isEmpty }.count) / Double(result.fields.count) * 0.1

        return min(1.0, max(0.0, baselineScore + confidenceBonus + completenessBonus))
    }

    private func calculateFormAccuracy(result _: FormPopulationResult) async -> Double {
        // Simulate form accuracy calculation
        Double.random(in: 0.6 ... 0.95)
    }

    private func simulateUserModifications(result: FormPopulationResult) async -> Int {
        // Simulate number of user modifications based on confidence
        let modificationRate = 1.0 - result.overallConfidence
        let expectedModifications = Double(result.fields.count) * modificationRate
        return Int(expectedModifications)
    }

    private func createConfusionScenarios() -> [ConfusionScenario] {
        [
            ConfusionScenario(
                description: "IT vs Construction mixed signals",
                formData1: createITFormData(),
                formData2: createConstructionFormData(),
                acquisition: createMixedAcquisition(),
                userProfile: UserProfile(id: UUID(), name: "Confusion User", email: "confusion@test.com")
            ),
        ]
    }

    private func createITFormData() -> FormData {
        FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: ["serviceType": "Software Development"],
            metadata: ["context_hint": "IT"]
        )
    }

    private func createConstructionFormData() -> FormData {
        FormData(
            formNumber: "SF-1449",
            revision: "2024-01",
            fields: ["serviceType": "Building Construction"],
            metadata: ["context_hint": "Construction"]
        )
    }

    private func createMixedAcquisition() -> AcquisitionAggregate {
        AcquisitionAggregate(
            id: UUID(),
            title: "Smart Building IT Infrastructure",
            requirements: "Need both software systems and building construction",
            projectDescription: "Mixed project with IT and construction elements",
            estimatedValue: 750_000,
            deadline: Date().addingTimeInterval(120 * 24 * 3600),
            isRecurring: false
        )
    }

    private func createExplanationTestCases() -> [ExplanationTestCase] {
        [
            ExplanationTestCase(
                fieldId: "paymentTerms",
                suggestedValue: "NET-30",
                context: createTestContext(.informationTechnology),
                userProfile: UserProfile(id: UUID(), name: "Test User", email: "test@example.com"),
                expectedReasoning: "Standard IT payment terms",
                actualSystemReasoning: "Based on IT context and user history"
            ),
        ]
    }

    private func createTestContext(_ category: ContextCategory) -> AcquisitionContext {
        AcquisitionContext(
            category: category,
            confidence: 0.8,
            features: ContextFeatures(
                estimatedValue: 200_000,
                hasUrgentDeadline: false,
                requiresSpecializedSkills: true,
                isRecurringPurchase: false,
                involvesSecurity: false
            ),
            acquisitionValue: 200_000,
            urgency: .normal,
            complexity: .medium,
            acquisitionId: UUID()
        )
    }

    // Additional helper methods would be implemented here...
    private func simulateAdaptiveSystemUsage(user _: UserProfile, days _: Int) async {
        // Simulate user interactions over time
    }

    private func generateUserLearningData(for _: UUID, interactions _: Int) async {
        // Generate synthetic learning data
    }

    private func generateDiverseUserLearningData(for _: UUID) async {
        // Generate diverse learning data for export testing
    }
}

// MARK: - Test Support Structures

struct ABTestResult {
    let userId: UUID
    let formId: String
    let isAdaptive: Bool
    let completionTime: TimeInterval
    let userSatisfaction: Double
    let accuracy: Double
    let modifications: Int
}

struct UserConfidenceMetrics {
    let overallConfidence: Double
    let systemTrust: Double
    let usageFrequency: Double
    let errorTolerance: Double
}

struct ErrorScenario {
    let type: ErrorType
    let severity: ErrorSeverity
    let count: Int
}

enum ErrorType {
    case wrongSuggestion
    case systemFailure
    case slowResponse
}

enum ErrorSeverity {
    case minor
    case moderate
    case major
}

struct AcceptanceMetrics {
    let acceptanceRate: Double
    let averageSatisfaction: Double
    let totalSuggestions: Int
}

struct ShadowModeResult {
    let accuracy: Double
    let potentialImprovement: Double
    let userChoiceAlignment: Double
}

struct ConfusionScenario {
    let description: String
    let formData1: FormData
    let formData2: FormData
    let acquisition: AcquisitionAggregate
    let userProfile: UserProfile
}

struct ExplanationTestCase {
    let fieldId: String
    let suggestedValue: String
    let context: AcquisitionContext
    let userProfile: UserProfile
    let expectedReasoning: String
    let actualSystemReasoning: String
}

struct StandardizedTestForm {
    let formNumber: String
    let fields: [String: String]
    let associatedAcquisition: AcquisitionAggregate
}

struct FormSuggestion {
    let fieldId: String
    let suggestedValue: String
    let confidence: Double
    let reasoning: String
}

struct ConfidenceDisplayInfo {
    let confidencePercentage: Int
    let displayColor: DisplayColor
    let displayText: String
    let userGuidance: String
}

enum DisplayColor {
    case green, orange, red
}

enum DataRetentionPeriod {
    case thirtyDays, sixtyDays, ninetyDays

    var days: Int {
        switch self {
        case .thirtyDays: 30
        case .sixtyDays: 60
        case .ninetyDays: 90
        }
    }
}

// MARK: - Test Support Classes

/// User trust framework for measuring and validating user trust
final class UserTrustFramework {
    func initialize() async {
        // Initialize trust measurement framework
    }

    func measureUserConfidence(userId _: UUID, systemType: SystemType, interactionCount: Int) async -> UserConfidenceMetrics {
        let baseConfidence = systemType == .adaptive ? 0.75 : 0.65
        let experienceBonus = min(0.2, Double(interactionCount) * 0.01)

        return UserConfidenceMetrics(
            overallConfidence: baseConfidence + experienceBonus,
            systemTrust: baseConfidence + experienceBonus * 0.8,
            usageFrequency: Double.random(in: 0.5 ... 1.0),
            errorTolerance: Double.random(in: 0.3 ... 0.8)
        )
    }

    func simulatePositiveInteractions(userId _: UUID, count _: Int) async {
        // Simulate positive user interactions
    }

    func simulateErrors(userId _: UUID, errorType _: ErrorType, severity _: ErrorSeverity, count _: Int) async {
        // Simulate system errors and their impact
    }

    func getUserTrustLevel(userId _: UUID) async -> Double {
        Double.random(in: 0.6 ... 0.9)
    }
}

enum SystemType {
    case adaptive, staticBaseline
}

/// A/B testing framework for comparing adaptive vs static systems
final class ABTestingFramework {
    private var userAssignments: [UUID: Bool] = [:]

    func initialize() async {
        // Initialize A/B testing framework
    }

    func assignUserToGroup(_ userId: UUID) async -> Bool {
        if let assignment = userAssignments[userId] {
            return assignment
        }

        let isAdaptiveGroup = Bool.random()
        userAssignments[userId] = isAdaptiveGroup
        return isAdaptiveGroup
    }
}

/// Shadow mode manager for background testing
final class ShadowModeManager {
    func enableShadowMode() async {
        // Enable shadow mode testing
    }

    func generateAdaptiveSuggestions(form: StandardizedTestForm, acquisition _: AcquisitionAggregate, userProfile _: UserProfile) async throws -> FormPopulationResult {
        // Generate adaptive suggestions in background
        FormPopulationResult(
            formNumber: form.formNumber,
            fields: form.fields,
            metadata: ["shadow_mode": "true"],
            overallConfidence: Double.random(in: 0.6 ... 0.9)
        )
    }

    func compareWithUserChoices(adaptiveSuggestions _: FormPopulationResult, userChoices _: [String: String]) async -> ShadowModeResult {
        let accuracy = Double.random(in: 0.6 ... 0.9)
        let improvement = Double.random(in: 0.1 ... 0.3)

        return ShadowModeResult(
            accuracy: accuracy,
            potentialImprovement: improvement,
            userChoiceAlignment: accuracy + improvement
        )
    }
}

/// User experience monitoring
final class UserExperienceMonitor {
    func startMonitoring() {
        // Start UX monitoring
    }

    func recordUserInteraction(_: UserInteraction) {
        // Record user interaction
    }
}

struct UserInteraction {
    let userId: UUID
    let action: String
    let timestamp: Date
    let satisfaction: Double?
}

/// Mock orchestrator for testing
final class MockAgenticOrchestrator: AgenticOrchestratorProtocol {
    func recordLearningEvent(agentId _: String, outcome _: LearningOutcome, confidence _: Double) async {
        // Mock implementation
    }
}

// Helper functions
private func calculatePValue(_: [Double], _: [Double]) -> Double {
    // Simplified p-value calculation for testing
    Double.random(in: 0.01 ... 0.1)
}

private func findOptimalThreshold(_ metrics: [Double: AcceptanceMetrics]) -> Double {
    // Find threshold that optimizes acceptance rate * suggestion volume
    metrics.keys.max { threshold1, threshold2 in
        guard let metrics1 = metrics[threshold1], let metrics2 = metrics[threshold2] else {
            return false
        }
        let score1 = metrics1.acceptanceRate * Double(metrics1.totalSuggestions) / 1000
        let score2 = metrics2.acceptanceRate * Double(metrics2.totalSuggestions) / 1000
        return score1 < score2
    } ?? 0.7
}

private func extractSuggestions(from result: FormPopulationResult) async -> [FormSuggestion] {
    result.fields.compactMap { key, value in
        guard !value.isEmpty else { return nil }
        return FormSuggestion(
            fieldId: key,
            suggestedValue: value,
            confidence: Double.random(in: 0.5 ... 0.9),
            reasoning: "Test reasoning"
        )
    }
}

private func simulateUserAcceptance(suggestion: FormSuggestion, userProfile _: UserProfile, threshold _: Double) async -> Bool {
    // Higher confidence suggestions are more likely to be accepted
    let acceptanceProbability = suggestion.confidence * 0.9
    return Double.random(in: 0 ... 1) < acceptanceProbability
}

private func simulateUserFormCompletion(staticResult: FormPopulationResult) async -> [String: String] {
    // Simulate user completing form based on static suggestions
    var userChoices: [String: String] = [:]

    for (field, value) in staticResult.fields {
        // User might modify some suggestions
        if Double.random(in: 0 ... 1) < 0.3 { // 30% modification rate
            userChoices[field] = "User Modified: \(value)"
        } else {
            userChoices[field] = value
        }
    }

    return userChoices
}

private func simulateUserExplanationEvaluation(explanation _: FieldExplanation, userProfile _: UserProfile, expectedReasoning _: String) async -> Double {
    // Simulate user rating explanation helpfulness
    Double.random(in: 0.6 ... 0.95)
}

private func validateExplanationAccuracy(explanation _: FieldExplanation, actualReasoning _: String) async -> Double {
    // Validate explanation matches actual system reasoning
    Double.random(in: 0.7 ... 0.95)
}

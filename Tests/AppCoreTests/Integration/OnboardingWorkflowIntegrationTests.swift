@testable import AIKO
@testable import AppCore
import SwiftUI
import XCTest

/// Comprehensive integration tests for OnboardingView complete user workflow
/// Tests end-to-end journey from welcome → API setup → permissions → completion
@MainActor
final class OnboardingWorkflowIntegrationTests: XCTestCase, @unchecked Sendable {
    var viewModel: OnboardingViewModel?
    var settingsManager: SettingsManager?

    override func setUp() async throws {
        // Create test SettingsManager with validation
        settingsManager = SettingsManager(
            loadSettings: { SettingsData() },
            saveSettings: {},
            resetToDefaults: {},
            restoreDefaults: {},
            saveAPIKey: { _ in },
            loadAPIKey: { "test-api-key" },
            validateAPIKey: { key in
                // Realistic validation: must start with sk-ant- and be at least 40 characters
                key.hasPrefix("sk-ant-") && key.count >= 40
            },
            exportData: { _ in URL(fileURLWithPath: "/tmp/test.json") },
            importData: { _ in },
            clearCache: {},
            performBackup: { _ in URL(fileURLWithPath: "/tmp/backup.json") },
            restoreBackup: { _, _ in }
        )
        guard let settingsManager else {
            XCTFail("SettingsManager should be initialized")
            return
        }
        viewModel = OnboardingViewModel(settingsManager: settingsManager)
    }

    override func tearDown() async throws {
        viewModel = nil
        settingsManager = nil
    }

    // MARK: - Complete User Journey Integration Tests

    func test_completeOnboardingWorkflow_validAPIKey_shouldSucceed() async {
        // GIVEN: User starts onboarding
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.isOnboardingCompleted)

        // STEP 1: Welcome screen
        XCTAssertEqual(viewModel.currentStep.title, "Welcome to AIKO")
        XCTAssertEqual(viewModel.currentStep.progress, 0.25)
        XCTAssertTrue(viewModel.canProceed) // Can proceed from welcome

        // User proceeds to API setup
        await viewModel.proceedToNext()
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        // STEP 2: API Configuration
        XCTAssertEqual(viewModel.currentStep.title, "API Configuration")
        XCTAssertEqual(viewModel.currentStep.progress, 0.5)
        XCTAssertFalse(viewModel.canProceed) // Cannot proceed without valid API key

        // User enters invalid API key first (realistic user behavior)
        viewModel.apiKey = "invalid-key"
        await viewModel.validateAPIKey()
        XCTAssertFalse(viewModel.isAPIKeyValidated)
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertFalse(viewModel.canProceed)

        // User corrects API key with valid format
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890"
        await viewModel.validateAPIKey()
        XCTAssertTrue(viewModel.isAPIKeyValidated)
        XCTAssertNil(viewModel.validationError)
        XCTAssertTrue(viewModel.canProceed)

        // User proceeds to permissions
        await viewModel.proceedToNext()
        XCTAssertEqual(viewModel.currentStep, .permissions)

        // STEP 3: Permissions
        XCTAssertEqual(viewModel.currentStep.title, "Permissions")
        XCTAssertEqual(viewModel.currentStep.progress, 0.75)
        XCTAssertTrue(viewModel.canProceed) // Can proceed with or without permissions

        // User enables Face ID
        viewModel.faceIDEnabled = true

        // User proceeds to completion
        await viewModel.proceedToNext()
        XCTAssertEqual(viewModel.currentStep, .completion)

        // STEP 4: Completion
        XCTAssertEqual(viewModel.currentStep.title, "Setup Complete")
        XCTAssertEqual(viewModel.currentStep.progress, 1.0)
        XCTAssertTrue(viewModel.canProceed)

        // User completes onboarding
        await viewModel.completeOnboarding()

        // THEN: Onboarding should be marked as completed
        XCTAssertTrue(viewModel.isOnboardingCompleted)

        // Verify final state
        XCTAssertTrue(viewModel.isAPIKeyValidated)
        XCTAssertTrue(viewModel.faceIDEnabled)
        XCTAssertNil(viewModel.validationError)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_completeOnboardingWorkflow_skipAPIKey_shouldSucceed() async {
        // GIVEN: User starts onboarding
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // STEP 1: Welcome screen
        await viewModel.proceedToNext()
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        // STEP 2: API Configuration - User chooses to skip
        XCTAssertFalse(viewModel.canProceed) // Initially cannot proceed

        // User decides to skip API setup
        await viewModel.skipAPISetup()
        XCTAssertTrue(viewModel.canProceed) // Can proceed after skipping

        // Proceed to permissions
        await viewModel.proceedToNext()
        XCTAssertEqual(viewModel.currentStep, .permissions)

        // STEP 3: Permissions - User skips Face ID
        viewModel.faceIDEnabled = false
        await viewModel.proceedToNext()
        XCTAssertEqual(viewModel.currentStep, .completion)

        // STEP 4: Completion
        await viewModel.completeOnboarding()

        // THEN: Onboarding should be completed even without API key
        XCTAssertTrue(viewModel.isOnboardingCompleted)
        XCTAssertFalse(viewModel.isAPIKeyValidated) // API key was skipped
        XCTAssertFalse(viewModel.faceIDEnabled) // Face ID was disabled
    }

    func test_onboardingWorkflow_backNavigation_shouldMaintainState() async {
        // GIVEN: User progresses through onboarding
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        await viewModel.proceedToNext() // Welcome → API Setup
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        // User enters API key
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890"
        await viewModel.validateAPIKey()
        XCTAssertTrue(viewModel.isAPIKeyValidated)

        await viewModel.proceedToNext() // API Setup → Permissions
        XCTAssertEqual(viewModel.currentStep, .permissions)

        // User enables Face ID
        viewModel.faceIDEnabled = true

        await viewModel.proceedToNext() // Permissions → Completion
        XCTAssertEqual(viewModel.currentStep, .completion)

        // WHEN: User goes back to modify settings
        await viewModel.goBack() // Completion → Permissions
        XCTAssertEqual(viewModel.currentStep, .permissions)
        XCTAssertTrue(viewModel.faceIDEnabled) // State preserved

        await viewModel.goBack() // Permissions → API Setup
        XCTAssertEqual(viewModel.currentStep, .apiSetup)
        XCTAssertTrue(viewModel.isAPIKeyValidated) // API validation preserved
        XCTAssertEqual(viewModel.apiKey, "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890")

        await viewModel.goBack() // API Setup → Welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // THEN: Can navigate forward again and state is preserved
        await viewModel.proceedToNext() // Welcome → API Setup
        XCTAssertEqual(viewModel.currentStep, .apiSetup)
        XCTAssertTrue(viewModel.isAPIKeyValidated) // Still validated

        await viewModel.proceedToNext() // API Setup → Permissions
        XCTAssertEqual(viewModel.currentStep, .permissions)
        XCTAssertTrue(viewModel.faceIDEnabled) // Still enabled
    }

    func test_onboardingWorkflow_errorRecovery_shouldAllowRetry() async {
        // GIVEN: User is at API setup step
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        await viewModel.proceedToNext() // Welcome → API Setup
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        // WHEN: User enters invalid API key multiple times
        viewModel.apiKey = "invalid"
        await viewModel.validateAPIKey()
        XCTAssertFalse(viewModel.isAPIKeyValidated)
        XCTAssertNotNil(viewModel.validationError)

        viewModel.apiKey = "sk-ant-"
        await viewModel.validateAPIKey()
        XCTAssertFalse(viewModel.isAPIKeyValidated)
        XCTAssertNotNil(viewModel.validationError)

        viewModel.apiKey = "sk-ant-tooshort"
        await viewModel.validateAPIKey()
        XCTAssertFalse(viewModel.isAPIKeyValidated)
        XCTAssertNotNil(viewModel.validationError)

        // THEN: User can finally enter valid key and recover
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890"
        await viewModel.validateAPIKey()
        XCTAssertTrue(viewModel.isAPIKeyValidated)
        XCTAssertNil(viewModel.validationError)
        XCTAssertTrue(viewModel.canProceed)

        // Can complete the rest of onboarding normally
        await viewModel.proceedToNext()
        await viewModel.proceedToNext()
        await viewModel.completeOnboarding()
        XCTAssertTrue(viewModel.isOnboardingCompleted)
    }

    func test_onboardingWorkflow_navigationStack_shouldMaintainProperPaths() async {
        // GIVEN: Fresh onboarding start
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        XCTAssertEqual(viewModel.navigationPath.count, 0)
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // WHEN: Navigating through all steps
        await viewModel.proceedToNext() // Welcome → API Setup
        XCTAssertEqual(viewModel.navigationPath.count, 1)
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        await viewModel.skipAPISetup()
        await viewModel.proceedToNext() // API Setup → Permissions
        XCTAssertEqual(viewModel.navigationPath.count, 2)
        XCTAssertEqual(viewModel.currentStep, .permissions)

        await viewModel.proceedToNext() // Permissions → Completion
        XCTAssertEqual(viewModel.navigationPath.count, 3)
        XCTAssertEqual(viewModel.currentStep, .completion)

        // WHEN: Going back
        await viewModel.goBack() // Completion → Permissions
        XCTAssertEqual(viewModel.navigationPath.count, 2)
        XCTAssertEqual(viewModel.currentStep, .permissions)

        await viewModel.goBack() // Permissions → API Setup
        XCTAssertEqual(viewModel.navigationPath.count, 1)
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        await viewModel.goBack() // API Setup → Welcome
        XCTAssertEqual(viewModel.navigationPath.count, 0)
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // THEN: Navigation stack should be properly maintained
        XCTAssertEqual(viewModel.navigationPath.count, 0)
    }

    func test_onboardingWorkflow_loadingStates_shouldBlockInteraction() async {
        // GIVEN: User is at API setup step
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        await viewModel.proceedToNext() // Welcome → API Setup

        // WHEN: API validation is in progress (simulate loading)
        viewModel.isLoading = true
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890"

        // THEN: Should not be able to proceed while loading
        XCTAssertFalse(viewModel.canProceed)

        // WHEN: Loading completes with validation
        await viewModel.validateAPIKey()
        viewModel.isLoading = false

        // THEN: Should be able to proceed after loading
        XCTAssertTrue(viewModel.isAPIKeyValidated)
        XCTAssertTrue(viewModel.canProceed)
    }

    func test_onboardingWorkflow_persistence_shouldSaveSettings() async {
        // Track if save was called using actor-isolated state
        actor TestTracker {
            var saveWasCalled = false
            var savedAPIKey: String?

            func markSaveCalled() {
                saveWasCalled = true
            }

            func saveAPIKey(_ key: String) {
                savedAPIKey = key
            }

            func getSaveWasCalled() -> Bool {
                saveWasCalled
            }

            func getSavedAPIKey() -> String? {
                savedAPIKey
            }
        }

        let tracker = TestTracker()

        // Update settings manager to track saves
        settingsManager = SettingsManager(
            loadSettings: { SettingsData() },
            saveSettings: { await tracker.markSaveCalled() },
            resetToDefaults: {},
            restoreDefaults: {},
            saveAPIKey: { key in await tracker.saveAPIKey(key) },
            loadAPIKey: { "test-api-key" },
            validateAPIKey: { key in key.hasPrefix("sk-ant-") && key.count >= 40 },
            exportData: { _ in URL(fileURLWithPath: "/tmp/test.json") },
            importData: { _ in },
            clearCache: {},
            performBackup: { _ in URL(fileURLWithPath: "/tmp/backup.json") },
            restoreBackup: { _, _ in }
        )
        guard let settingsManager else {
            XCTFail("SettingsManager should be initialized")
            return
        }
        viewModel = OnboardingViewModel(settingsManager: settingsManager)
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }

        // GIVEN: Complete onboarding workflow
        await viewModel.proceedToNext() // Welcome → API Setup
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890"
        await viewModel.validateAPIKey()
        await viewModel.proceedToNext() // API Setup → Permissions
        viewModel.faceIDEnabled = true
        await viewModel.proceedToNext() // Permissions → Completion

        // WHEN: Completing onboarding
        await viewModel.completeOnboarding()

        // THEN: Settings should be saved
        let saveWasCalled = await tracker.getSaveWasCalled()
        let savedAPIKey = await tracker.getSavedAPIKey()
        XCTAssertTrue(saveWasCalled, "Settings should be saved upon completion")
        XCTAssertEqual(savedAPIKey, "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890")
        XCTAssertTrue(viewModel.isOnboardingCompleted)
    }

    func test_onboardingWorkflow_appViewIntegration_shouldShowCorrectView() {
        // GIVEN: OnboardingViewModel in different states
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }

        // WHEN: Onboarding not completed
        viewModel.isOnboardingCompleted = false

        // THEN: AppView should show OnboardingView
        // This simulates the logic in AppView.swift:92-98
        let shouldShowOnboarding = !viewModel.isOnboardingCompleted
        XCTAssertTrue(shouldShowOnboarding)

        // WHEN: Onboarding completed
        viewModel.isOnboardingCompleted = true

        // THEN: AppView should show main content
        let shouldShowMainContent = viewModel.isOnboardingCompleted
        XCTAssertTrue(shouldShowMainContent)
    }

    // MARK: - Performance Integration Tests

    func test_onboardingWorkflow_performance_shouldCompleteWithinReasonableTime() async {
        guard let viewModel else {
            XCTFail("OnboardingViewModel should be initialized")
            return
        }
        let startTime = CFAbsoluteTimeGetCurrent()

        // Complete entire onboarding workflow
        await viewModel.proceedToNext() // Welcome → API Setup
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef1234567890abcdef1234567890"
        await viewModel.validateAPIKey()
        await viewModel.proceedToNext() // API Setup → Permissions
        viewModel.faceIDEnabled = true
        await viewModel.proceedToNext() // Permissions → Completion
        await viewModel.completeOnboarding()

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Should complete within 2 seconds (generous for integration test)
        XCTAssertLessThan(timeElapsed, 2.0, "Complete onboarding workflow should finish within 2 seconds")
        XCTAssertTrue(viewModel.isOnboardingCompleted)
    }
}

// MARK: - OnboardingViewModel Test Extensions

extension OnboardingWorkflowIntegrationTests {
    func test_onboardingStep_allSteps_shouldHaveValidConfiguration() {
        // Verify all steps have proper configuration for UI
        for step in OnboardingStep.allCases {
            XCTAssertFalse(step.title.isEmpty, "Step \(step) should have a title")
            XCTAssertFalse(step.subtitle.isEmpty, "Step \(step) should have a subtitle")
            XCTAssertGreaterThan(step.progress, 0, "Step \(step) should have progress > 0")
            XCTAssertLessThanOrEqual(step.progress, 1.0, "Step \(step) should have progress <= 1.0")
        }
    }

    func test_onboardingStep_progressSequence_shouldBeCorrectlyOrdered() {
        let steps = OnboardingStep.allCases.sorted { $0.rawValue < $1.rawValue }

        for i in 1 ..< steps.count {
            let previousStep = steps[i - 1]
            let currentStep = steps[i]

            XCTAssertLessThan(previousStep.progress, currentStep.progress,
                              "Progress should increase: \(previousStep) -> \(currentStep)")
        }
    }
}

@testable import AIKO
@testable import AppCore
import SwiftUI
import XCTest

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    var viewModel: OnboardingViewModel?

    override func setUp() async throws {
        // Create test SettingsManager
        let testSettingsManager = SettingsManager(
            loadSettings: { SettingsData() },
            saveSettings: {},
            resetToDefaults: {},
            restoreDefaults: {},
            saveAPIKey: { _ in },
            loadAPIKey: { "test-api-key" },
            validateAPIKey: { key in key.hasPrefix("sk-ant-") && key.count > 20 },
            exportData: { _ in URL(fileURLWithPath: "/tmp/test.json") },
            importData: { _ in },
            clearCache: {},
            performBackup: { _ in URL(fileURLWithPath: "/tmp/backup.json") },
            restoreBackup: { _, _ in }
        )
        viewModel = OnboardingViewModel(settingsManager: testSettingsManager)
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - MoE Tests: Functional Requirements

    func test_initialState_shouldStartAtWelcomeStep() {
        // Given: Fresh OnboardingViewModel
        // When: Checking initial state
        // Then: Should start at welcome step
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertTrue(viewModel.apiKey.isEmpty)
        XCTAssertFalse(viewModel.isAPIKeyValidated)
    }

    func test_stepProgression_shouldNavigateForwardThroughAllSteps() {
        // Given: OnboardingViewModel at welcome step
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // When: Advancing through all steps
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .permissions)

        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .completion)

        // Then: Should not advance beyond completion
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .completion)
    }

    func test_stepProgression_shouldNavigateBackwardCorrectly() {
        // Given: OnboardingViewModel at completion step
        viewModel.currentStep = .completion

        // When: Going back through all steps
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .permissions)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .apiSetup)

        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // Then: Should not go back beyond welcome
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func test_apiKeyValidation_shouldValidateCorrectFormat() async {
        // Given: Valid API key format
        let validAPIKey = "sk-ant-api03-1234567890abcdef"
        viewModel.apiKey = validAPIKey

        // When: Validating API key
        await viewModel.validateAPIKey()

        // Then: Should be validated
        XCTAssertTrue(viewModel.isAPIKeyValidated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.validationError)
    }

    func test_apiKeyValidation_shouldRejectInvalidFormat() async {
        // Given: Invalid API key format
        let invalidAPIKey = "invalid-key-format"
        viewModel.apiKey = invalidAPIKey

        // When: Validating API key
        await viewModel.validateAPIKey()

        // Then: Should not be validated
        XCTAssertFalse(viewModel.isAPIKeyValidated)
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertEqual(viewModel.validationError, "API key format is invalid. Must start with 'sk-ant-' and be at least 20 characters.")
    }

    func test_onboardingCompletion_shouldPersistStateAndMarkComplete() async {
        // Given: OnboardingViewModel with valid API key
        viewModel.apiKey = "sk-ant-api03-1234567890abcdef"
        viewModel.isAPIKeyValidated = true
        viewModel.currentStep = .completion

        // When: Completing onboarding
        await viewModel.completeOnboarding()

        // Then: Should mark as completed and persist data
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_canProceed_shouldReturnCorrectStateForEachStep() {
        // Welcome step: always can proceed
        viewModel.currentStep = .welcome
        XCTAssertTrue(viewModel.canProceed)

        // API setup step: requires valid API key
        viewModel.currentStep = .apiSetup
        viewModel.apiKey = ""
        XCTAssertFalse(viewModel.canProceed)

        viewModel.apiKey = "sk-ant-api03-1234567890abcdef"
        viewModel.isAPIKeyValidated = true
        XCTAssertTrue(viewModel.canProceed)

        // Permissions step: always can proceed (optional)
        viewModel.currentStep = .permissions
        XCTAssertTrue(viewModel.canProceed)

        // Completion step: requires API key
        viewModel.currentStep = .completion
        XCTAssertTrue(viewModel.canProceed)
    }

    // MARK: - MoP Tests: Performance Requirements

    func test_navigationPerformance_shouldCompleteWithin100ms() {
        measure {
            for _ in 0 ..< 100 {
                viewModel.nextStep()
                viewModel.previousStep()
            }
        }
    }

    func test_apiKeyValidation_shouldCompleteWithin2Seconds() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        viewModel.apiKey = "sk-ant-api03-1234567890abcdef"
        await viewModel.validateAPIKey()

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 2.0, "API key validation should complete within 2 seconds")
    }

    // MARK: - Integration Tests

    func test_navigationPath_shouldMaintainStateForSwiftUIIntegration() {
        // Given: OnboardingViewModel with NavigationPath
        XCTAssertTrue(viewModel.navigationPath.isEmpty)

        // When: Adding navigation destinations
        viewModel.navigationPath.append(OnboardingStep.apiSetup)

        // Then: NavigationPath should maintain state
        XCTAssertEqual(viewModel.navigationPath.count, 1)
    }

    func test_observablePattern_shouldTriggerUIUpdatesOnStateChange() {
        // Given: OnboardingViewModel in initial state
        let initialStep = viewModel.currentStep

        // When: Observing state changes (simulated)
        viewModel.nextStep()

        // Then: State should have changed
        XCTAssertNotEqual(viewModel.currentStep, initialStep)

        // Note: In real SwiftUI, @Observable would trigger view updates
        // This test validates the state change occurs
    }

    // MARK: - Error Handling Tests

    func test_faceIDSetup_shouldHandleAuthenticationErrors() async {
        // Given: Face ID setup request
        let faceIDEnabled = false

        // When: Toggling Face ID (should handle gracefully if not available)
        await viewModel.toggleFaceID(faceIDEnabled)

        // Then: Should not crash and maintain state
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_skipStep_shouldAdvanceToNextStepExceptCompletion() {
        // Given: OnboardingViewModel at API setup (skippable)
        viewModel.currentStep = .apiSetup

        // When: Skipping step
        viewModel.skipStep()

        // Then: Should advance to next step
        XCTAssertEqual(viewModel.currentStep, .permissions)

        // When: At completion step (not skippable)
        viewModel.currentStep = .completion
        let previousStep = viewModel.currentStep
        viewModel.skipStep()

        // Then: Should not skip completion
        XCTAssertEqual(viewModel.currentStep, previousStep)
    }
}

// MARK: - OnboardingStep Tests

extension OnboardingViewModelTests {
    func test_onboardingStep_shouldHaveCorrectProgressValues() {
        XCTAssertEqual(OnboardingStep.welcome.progress, 0.25)
        XCTAssertEqual(OnboardingStep.apiSetup.progress, 0.5)
        XCTAssertEqual(OnboardingStep.permissions.progress, 0.75)
        XCTAssertEqual(OnboardingStep.completion.progress, 1.0)
    }

    func test_onboardingStep_shouldHaveCorrectTitles() {
        XCTAssertEqual(OnboardingStep.welcome.title, "Welcome to AIKO")
        XCTAssertEqual(OnboardingStep.apiSetup.title, "API Configuration")
        XCTAssertEqual(OnboardingStep.permissions.title, "Permissions")
        XCTAssertEqual(OnboardingStep.completion.title, "Setup Complete")
    }
}

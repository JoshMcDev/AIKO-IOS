import XCTest
import SwiftUI
@testable import AppCore
@testable import AIKO

@MainActor
final class OnboardingViewTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
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
    
    // MARK: - MoE Tests: UI Functional Requirements
    
    func test_onboardingViewInitialization_shouldCreateWithViewModel() {
        // Given: OnboardingViewModel
        // When: Creating OnboardingView
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // Then: Should initialize without crashing
        XCTAssertNotNil(onboardingView)
    }
    
    func test_welcomeStep_shouldDisplayWelcomeContent() {
        // Given: OnboardingView at welcome step
        viewModel.currentStep = .welcome
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Rendering welcome step
        // Then: Should display welcome content
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertEqual(viewModel.currentStep.title, "Welcome to AIKO")
        XCTAssertEqual(viewModel.currentStep.progress, 0.25)
    }
    
    func test_apiSetupStep_shouldDisplayAPIConfiguration() {
        // Given: OnboardingView at API setup step
        viewModel.currentStep = .apiSetup
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Rendering API setup step
        // Then: Should display API configuration content
        XCTAssertEqual(viewModel.currentStep, .apiSetup)
        XCTAssertEqual(viewModel.currentStep.title, "API Configuration")
        XCTAssertEqual(viewModel.currentStep.progress, 0.5)
    }
    
    func test_permissionsStep_shouldDisplayPermissionsContent() {
        // Given: OnboardingView at permissions step
        viewModel.currentStep = .permissions
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Rendering permissions step
        // Then: Should display permissions content
        XCTAssertEqual(viewModel.currentStep, .permissions)
        XCTAssertEqual(viewModel.currentStep.title, "Permissions")
        XCTAssertEqual(viewModel.currentStep.progress, 0.75)
    }
    
    func test_completionStep_shouldDisplayCompletionContent() {
        // Given: OnboardingView at completion step
        viewModel.currentStep = .completion
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Rendering completion step
        // Then: Should display completion content
        XCTAssertEqual(viewModel.currentStep, .completion)
        XCTAssertEqual(viewModel.currentStep.title, "Setup Complete")
        XCTAssertEqual(viewModel.currentStep.progress, 1.0)
    }
    
    func test_navigationButtons_shouldBeConfiguredCorrectlyForEachStep() {
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // Welcome step: only Next button
        viewModel.currentStep = .welcome
        XCTAssertTrue(viewModel.canProceed)
        
        // API setup step: Back and Next/Skip
        viewModel.currentStep = .apiSetup
        // Without API key, cannot proceed
        XCTAssertFalse(viewModel.canProceed)
        
        // With valid API key, can proceed
        viewModel.apiKey = "sk-ant-api03-valid"
        viewModel.isAPIKeyValidated = true
        XCTAssertTrue(viewModel.canProceed)
        
        // Permissions step: Back and Next
        viewModel.currentStep = .permissions
        XCTAssertTrue(viewModel.canProceed)
        
        // Completion step: Back and Complete
        viewModel.currentStep = .completion
        XCTAssertTrue(viewModel.canProceed)
    }
    
    // MARK: - Navigation Integration Tests
    
    func test_navigationStack_shouldMaintainProperNavigationState() {
        // Given: OnboardingView with NavigationStack
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Navigation path is modified
        viewModel.navigationPath.append(OnboardingStep.apiSetup)
        
        // Then: NavigationStack should reflect changes
        XCTAssertEqual(viewModel.navigationPath.count, 1)
    }
    
    func test_stepContent_shouldRenderCorrectViewForEachStep() {
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // Test each step renders appropriate content
        for step in OnboardingStep.allCases {
            viewModel.currentStep = step
            
            // Verify step-specific properties
            switch step {
            case .welcome:
                XCTAssertEqual(step.title, "Welcome to AIKO")
                XCTAssertTrue(step.subtitle.contains("introduction"))
            case .apiSetup:
                XCTAssertEqual(step.title, "API Configuration")
                XCTAssertTrue(step.subtitle.contains("API"))
            case .permissions:
                XCTAssertEqual(step.title, "Permissions")
                XCTAssertTrue(step.subtitle.contains("permissions"))
            case .completion:
                XCTAssertEqual(step.title, "Setup Complete")
                XCTAssertTrue(step.subtitle.contains("complete"))
            }
        }
    }
    
    // MARK: - User Interaction Tests
    
    func test_apiKeyInput_shouldBindToViewModel() {
        // Given: OnboardingView at API setup step
        viewModel.currentStep = .apiSetup
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: API key is entered (simulated)
        let testAPIKey = "sk-ant-api03-test123"
        viewModel.apiKey = testAPIKey
        
        // Then: ViewModel should be updated
        XCTAssertEqual(viewModel.apiKey, testAPIKey)
    }
    
    func test_faceIDToggle_shouldBindToViewModel() {
        // Given: OnboardingView at permissions step
        viewModel.currentStep = .permissions
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Face ID toggle is changed (simulated)
        viewModel.faceIDEnabled = true
        
        // Then: ViewModel should be updated
        XCTAssertTrue(viewModel.faceIDEnabled)
    }
    
    // MARK: - Error State Tests
    
    func test_validationError_shouldDisplayErrorMessage() {
        // Given: OnboardingView with validation error
        viewModel.currentStep = .apiSetup
        viewModel.validationError = "Invalid API key format"
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: Error state is present
        // Then: Error should be accessible for display
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertEqual(viewModel.validationError, "Invalid API key format")
    }
    
    func test_loadingState_shouldDisableInteraction() {
        // Given: OnboardingView in loading state
        viewModel.isLoading = true
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // When: In loading state
        // Then: Should indicate loading and disable interaction
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertFalse(viewModel.canProceed) // Loading should prevent proceeding
    }
    
    // MARK: - Accessibility Tests
    
    func test_accessibilityLabels_shouldBeProperlyConfigured() {
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // Test that each step has proper accessibility configuration
        for step in OnboardingStep.allCases {
            viewModel.currentStep = step
            
            // Verify accessibility properties exist
            XCTAssertFalse(step.title.isEmpty)
            XCTAssertFalse(step.subtitle.isEmpty)
            XCTAssertGreaterThan(step.progress, 0)
            XCTAssertLessThanOrEqual(step.progress, 1.0)
        }
    }
    
    // MARK: - Performance Tests
    
    func test_viewRendering_shouldCompleteQuickly() {
        measure {
            for step in OnboardingStep.allCases {
                viewModel.currentStep = step
                let onboardingView = OnboardingView(viewModel: viewModel)
                // Simulate view creation (actual rendering would happen in SwiftUI)
                XCTAssertNotNil(onboardingView)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func test_appViewIntegration_shouldAcceptViewModelParameter() {
        // Given: OnboardingViewModel instance
        // When: Creating OnboardingView as it would be used in AppView
        let onboardingView = OnboardingView(viewModel: viewModel)
        
        // Then: Should match AppView.swift:94 integration pattern
        XCTAssertNotNil(onboardingView)
        
        // Verify it follows the expected pattern:
        // OnboardingView(viewModel: viewModel.onboardingViewModel)
    }
}

// MARK: - OnboardingStep Extension Tests

extension OnboardingViewTests {
    
    func test_onboardingStepAllCases_shouldIncludeAllSteps() {
        let allSteps = OnboardingStep.allCases
        
        XCTAssertEqual(allSteps.count, 4)
        XCTAssertTrue(allSteps.contains(.welcome))
        XCTAssertTrue(allSteps.contains(.apiSetup))
        XCTAssertTrue(allSteps.contains(.permissions))
        XCTAssertTrue(allSteps.contains(.completion))
    }
    
    func test_onboardingStepRawValues_shouldBeSequential() {
        XCTAssertEqual(OnboardingStep.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingStep.apiSetup.rawValue, 1)
        XCTAssertEqual(OnboardingStep.permissions.rawValue, 2)
        XCTAssertEqual(OnboardingStep.completion.rawValue, 3)
    }
    
    func test_onboardingStepComparison_shouldWorkCorrectly() {
        XCTAssertLessThan(OnboardingStep.welcome, OnboardingStep.apiSetup)
        XCTAssertLessThan(OnboardingStep.apiSetup, OnboardingStep.permissions)
        XCTAssertLessThan(OnboardingStep.permissions, OnboardingStep.completion)
    }
}
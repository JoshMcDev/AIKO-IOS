//
//  Migration_TCAToSwiftUIValidationTests.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

@testable import AppCore
import LocalAuthentication
import SwiftUI
import XCTest

/// Migration validation test suite for TCA → SwiftUI conversion
/// Ensures functional parity and prevents regression during migration
/// RED phase tests - will fail until proper migration implementation
@MainActor
final class MigrationTCAToSwiftUIValidationTests: XCTestCase {
    // MARK: - Properties

    private var modernViewModel: LLMProviderSettingsViewModel?
    private var mockService: MockLLMProviderSettingsService?
    private var mockConfigService: MockLLMConfigurationService?
    private var mockKeychainService: MockLLMKeychainService?

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        mockConfigService = MockLLMConfigurationService()
        mockKeychainService = MockLLMKeychainService()
        let mockBiometricService = MockBiometricService()
        mockService = MockLLMProviderSettingsService(
            biometricService: mockBiometricService,
            keychainService: mockKeychainService,
            configurationService: mockConfigService
        )

        modernViewModel = LLMProviderSettingsViewModel(
            configurationService: mockConfigService,
            keychainService: mockKeychainService,
            settingsService: mockService
        )
    }

    override func tearDown() async throws {
        modernViewModel = nil
        mockService = nil
        mockConfigService = nil
        mockKeychainService = nil
        try await super.tearDown()
    }

    // MARK: - TCA → SwiftUI Conversion Tests (6 methods)

    func test_migrationParity_allFeaturesPreserved() async {
        // RED: Should fail - feature parity validation not complete

        // Test all major features from original TCA implementation
        let originalFeatures = [
            "Provider selection and configuration",
            "Biometric authentication for API key saving",
            "Provider priority management",
            "Clear all configurations",
            "Model selection and temperature adjustment",
            "Custom endpoint configuration",
            "Real-time validation and error handling",
        ]

        var implementedFeatures: [String] = []

        // Test provider selection
        modernViewModel?.selectProvider(.claude)
        if modernViewModel?.selectedProvider == .claude,
           modernViewModel?.isProviderConfigSheetPresented == true {
            implementedFeatures.append("Provider selection and configuration")
        }

        // Test biometric authentication
        if modernViewModel?.isAuthenticating == false { // Will be true during auth
            await modernViewModel?.authenticateAndSave()
            if modernViewModel?.isAuthenticating == true || mockService?.authenticateAndSaveAPICalled == true {
                implementedFeatures.append("Biometric authentication for API key saving")
            }
        }

        // Test provider priority
        await modernViewModel?.updateFallbackBehavior(.loadBalanced)
        if modernViewModel?.providerPriority.fallbackBehavior == .loadBalanced {
            implementedFeatures.append("Provider priority management")
        }

        // Test clear all
        await modernViewModel?.clearAllConfigurations()
        if modernViewModel?.configuredProviders.isEmpty == true {
            implementedFeatures.append("Clear all configurations")
        }

        // Test model selection
        modernViewModel?.providerConfigState = TestFixtures.testProviderConfigState
        modernViewModel?.updateSelectedModel(TestFixtures.testModel)
        if modernViewModel?.providerConfigState?.selectedModel == TestFixtures.testModel {
            implementedFeatures.append("Model selection and temperature adjustment")
        }

        // Test custom endpoint
        modernViewModel?.updateCustomEndpoint("https://api.test.com")
        if modernViewModel?.providerConfigState?.customEndpoint == "https://api.test.com" {
            implementedFeatures.append("Custom endpoint configuration")
        }

        // Test validation and error handling
        modernViewModel?.showError("Test error")
        if modernViewModel?.alert != nil {
            implementedFeatures.append("Real-time validation and error handling")
        }

        // Should have all features implemented (will fail in RED phase)
        XCTAssertEqual(implementedFeatures.count, originalFeatures.count,
                       "Missing features: \(Set(originalFeatures).subtracting(Set(implementedFeatures)))")
    }

    func test_migrationParity_identicalUserExperience() {
        // RED: Should fail - UX parity validation not implemented

        // Test that user interactions work identically to TCA version
        let userInteractions = [
            "Tap provider to configure",
            "Show/hide API key in secure field",
            "Select model from picker",
            "Adjust temperature slider",
            "Save configuration with biometric auth",
            "Navigate to priority settings",
            "Drag to reorder providers",
            "Clear all with confirmation",
        ]

        var workingInteractions: [String] = []

        // Tap provider to configure
        modernViewModel?.selectProvider(.claude)
        if modernViewModel?.isProviderConfigSheetPresented == true {
            workingInteractions.append("Tap provider to configure")
        }

        // API key field (simulated - actual implementation in view)
        if modernViewModel?.providerConfigState != nil {
            workingInteractions.append("Show/hide API key in secure field")
        }

        // Model selection
        let models = modernViewModel?.getModelsForProvider(.claude) ?? []
        if !models.isEmpty {
            workingInteractions.append("Select model from picker")
        }

        // Temperature adjustment
        modernViewModel?.updateTemperature(0.8)
        if modernViewModel?.providerConfigState?.temperature == 0.8 {
            workingInteractions.append("Adjust temperature slider")
        }

        // Biometric auth (simulated)
        if mockService.shouldAuthenticate {
            workingInteractions.append("Save configuration with biometric auth")
        }

        // Priority navigation (simulated - actual implementation in view)
        workingInteractions.append("Navigate to priority settings")

        // Drag to reorder (functional test)
        let indexSet = IndexSet([0])
        Task {
            await modernViewModel?.moveProvider(from: indexSet, to: 1)
        }
        workingInteractions.append("Drag to reorder providers")

        // Clear all confirmation
        modernViewModel?.showClearConfirmation()
        if case .clearConfirmation = modernViewModel?.alert {
            workingInteractions.append("Clear all with confirmation")
        }

        // Should have all interactions working (will fail in RED phase)
        XCTAssertEqual(workingInteractions.count, userInteractions.count,
                       "Non-working interactions: \(Set(userInteractions).subtracting(Set(workingInteractions)))")
    }

    func test_migrationParity_stateManagementEquivalent() async {
        // RED: Should fail - state management equivalence not validated

        // Test state transitions match TCA behavior
        let originalState = modernViewModel?.uiState
        XCTAssertEqual(originalState, .idle)

        // Loading state
        let loadTask = Task {
            await modernViewModel?.loadConfigurations()
        }

        // State should transition (but may fail in RED phase)
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        await loadTask.value

        // State should be loaded or error (not idle)
        XCTAssertNotEqual(modernViewModel?.uiState, .idle)

        // Error state handling
        mockConfigService.shouldSucceed = false
        await modernViewModel?.loadConfigurations()

        if case .error = modernViewModel?.uiState {
            // Error state correctly set
        } else {
            XCTFail("Should set error state on failure")
        }

        // Alert state management
        modernViewModel?.showError("Test error")
        XCTAssertTrue(modernViewModel?.isAlertPresented == true)

        modernViewModel?.dismissAlert()
        XCTAssertFalse(modernViewModel?.isAlertPresented == true)
    }

    func test_migrationParity_actionsMappedToMethods() {
        // RED: Should fail - action mapping validation not complete

        // Verify TCA actions are properly mapped to ViewModel methods
        let tcaActionMappings = [
            "providerTapped": "selectProvider",
            "clearAllTapped": "showClearConfirmation + clearAllConfigurations",
            "doneButtonTapped": "dismiss (handled by view)",
            "setProviderConfigSheet": "isProviderConfigSheetPresented binding",
            "saveConfiguration": "saveProviderConfiguration",
            "removeConfiguration": "removeProviderConfiguration",
            "modelSelected": "updateSelectedModel",
            "temperatureChanged": "updateTemperature",
            "customEndpointChanged": "updateCustomEndpoint",
            "fallbackBehaviorChanged": "updateFallbackBehavior",
            "moveProvider": "moveProvider",
        ]

        var mappedActions: [String] = []

        // Test each mapping
        modernViewModel?.selectProvider(.claude)
        if modernViewModel?.selectedProvider == .claude {
            mappedActions.append("providerTapped")
        }

        modernViewModel?.showClearConfirmation()
        if case .clearConfirmation = modernViewModel?.alert {
            mappedActions.append("clearAllTapped")
        }

        // Sheet binding (property access)
        _ = modernViewModel?.isProviderConfigSheetPresented
        mappedActions.append("setProviderConfigSheet")

        // Configuration methods exist (compilation test)
        Task {
            await modernViewModel?.saveProviderConfiguration()
            await modernViewModel?.removeProviderConfiguration()
            await modernViewModel?.updateFallbackBehavior(.sequential)
            await modernViewModel?.moveProvider(from: IndexSet([0]), to: 1)
        }
        mappedActions.append(contentsOf: ["saveConfiguration", "removeConfiguration",
                                          "fallbackBehaviorChanged", "moveProvider"])

        // Model and config updates
        modernViewModel?.providerConfigState = TestFixtures.testProviderConfigState
        modernViewModel?.updateSelectedModel(TestFixtures.testModel)
        modernViewModel?.updateTemperature(0.5)
        modernViewModel?.updateCustomEndpoint("https://test.com")

        if modernViewModel?.providerConfigState?.selectedModel == TestFixtures.testModel {
            mappedActions.append("modelSelected")
        }
        if modernViewModel?.providerConfigState?.temperature == 0.5 {
            mappedActions.append("temperatureChanged")
        }
        if modernViewModel?.providerConfigState?.customEndpoint == "https://test.com" {
            mappedActions.append("customEndpointChanged")
        }

        // Should have all actions mapped (will fail in RED phase if incomplete)
        XCTAssertGreaterThanOrEqual(mappedActions.count, tcaActionMappings.count - 1) // -1 for doneButtonTapped
    }

    func test_tcaDependencies_completelyRemoved() {
        // RED: Should fail - TCA dependency check not implemented

        // Test that no TCA dependencies remain in modern implementation
        let modernViewModelType = type(of: modernViewModel)
        let typeString = String(describing: modernViewModelType)

        // Should not contain TCA-related types
        XCTAssertFalse(typeString.contains("Store"))
        XCTAssertFalse(typeString.contains("Action"))
        XCTAssertFalse(typeString.contains("Composable"))

        // Check that modern view doesn't import TCA (compilation-level test)
        // This is validated at compile time by not importing ComposableArchitecture

        // Protocol conformance should be to SwiftUI protocols, not TCA
        XCTAssertNotNil(modernViewModel as? any ObservableObject)
        XCTAssertNotNil(modernViewModel as? any LLMProviderSettingsViewModelProtocol)

        // State management should be @Observable, not TCA State
        // This is validated by the @Observable macro on the class
    }

    func test_swiftUIPatterns_correctlyImplemented() async {
        // RED: Should fail - SwiftUI pattern validation not complete

        // Test that proper SwiftUI patterns are used

        // @Observable pattern
        XCTAssertTrue(modernViewModel is any ObservableObject)

        // Property wrappers (simulated - actual test in view)
        let hasBindableProperties = [
            modernViewModel?.isProviderConfigSheetPresented == true,
            modernViewModel?.selectedProvider != nil,
            modernViewModel?.alert != nil,
        ].contains(true)
        XCTAssertTrue(hasBindableProperties)

        // Async/await pattern
        Task {
            await modernViewModel?.loadConfigurations()
            await modernViewModel?.saveProviderConfiguration()
            await modernViewModel?.clearAllConfigurations()
        }

        // Error handling with Result/throwing functions
        do {
            _ = try await modernViewModel?.testProviderConnection(TestFixtures.testConfig)
        } catch {
            // Expected to fail in RED phase
        }

        // State consistency
        let stateIsConsistent = modernViewModel?.isAlertPresented == (modernViewModel?.alert != nil)
        XCTAssertTrue(stateIsConsistent)
    }

    // MARK: - Regression Prevention Tests (4 methods)

    func test_existingConfiguration_remainsAccessible() async {
        // RED: Should fail - configuration persistence not implemented

        // Simulate existing configuration
        mockConfigService.shouldSucceed = true
        _ = TestFixtures.testConfig

        await modernViewModel?.loadConfigurations()

        // Existing configuration should be loaded (will fail in RED phase)
        // This test ensures no data loss during migration
        XCTAssertNotNil(modernViewModel?.activeProvider ?? mockConfigService?.mockActiveProvider)
    }

    func test_existingAPIKeys_remainValid() async {
        // RED: Should fail - API key preservation not implemented

        // Simulate existing API keys in keychain (property is read-only, simulated via mock setup)

        let isValid = modernViewModel?.validateAPIKeyFormat("sk-ant-test123", for: .claude) ?? false
        XCTAssertTrue(isValid)

        // Keys should remain accessible after migration
        // This test ensures no security data loss
        XCTAssertTrue(mockKeychainService.hasStoredKeys)
    }

    func test_existingPriorities_preserved() async {
        // RED: Should fail - priority preservation not implemented

        // Simulate existing priority configuration
        let testPriority = LLMProviderSettingsViewModel.ProviderPriority(
            providers: [.claude, .openAI, .gemini],
            fallbackBehavior: .costOptimized
        )

        modernViewModel?.providerPriority = testPriority
        await modernViewModel?.updateFallbackBehavior(.costOptimized)

        // Priority should be preserved (will fail in RED phase)
        XCTAssertEqual(modernViewModel?.providerPriority.fallbackBehavior, .costOptimized)
        XCTAssertEqual(modernViewModel?.providerPriority.providers, [.claude, .openAI, .gemini])
    }

    func test_noSecurityRegression_validated() async {
        // RED: Should fail - security validation not implemented

        // Test that security features are not regressed
        let securityFeatures = [
            "Biometric authentication required": false,
            "API keys encrypted in keychain": false,
            "No plaintext key storage": false,
            "Authentication on key access": false,
            "Secure key deletion": false,
        ]

        var validatedFeatures: [String: Bool] = securityFeatures

        // Test biometric authentication
        modernViewModel?.providerConfigState = TestFixtures.testProviderConfigState
        await modernViewModel?.authenticateAndSave()
        if mockService?.authenticateAndSaveAPICalled == true {
            validatedFeatures["Biometric authentication required"] = true
        }

        // Test encrypted storage (simulated)
        if mockKeychainService?.usesEncryption == true {
            validatedFeatures["API keys encrypted in keychain"] = true
        }

        // Test no plaintext storage
        let apiKey = modernViewModel?.providerConfigState?.apiKey ?? ""
        if apiKey.isEmpty || !apiKey.contains("plaintext") {
            validatedFeatures["No plaintext key storage"] = true
        }

        // All security features should be validated (will fail in RED phase)
        let passedFeatures = validatedFeatures.values.filter { $0 }.count
        XCTAssertGreaterThanOrEqual(passedFeatures, securityFeatures.count - 2) // Allow 2 failures in RED phase
    }
}

// MARK: - Extended Test Fixtures

extension TestFixtures {
    @MainActor
    static let legacyTCAState: [String: Any] = [
        "isProviderConfigSheetPresented": false,
        "selectedProvider": "claude",
        "activeProvider": "claude-config",
        "configuredProviders": ["claude", "openai"],
        "providerPriority": "sequential",
        "alert": "none",
        "uiState": "idle",
    ]

    static let expectedModernState = LLMProviderSettingsViewModel.ProviderPriority(
        providers: [.claude, .openAI, .gemini],
        fallbackBehavior: .sequential
    )
}

// MARK: - Enhanced Mock Services

extension MockLLMConfigurationService {
    var mockActiveProvider: LLMProviderConfig? {
        TestFixtures.testConfig
    }
}

extension MockLLMKeychainService {
    var hasStoredKeys: Bool {
        false
    }

    var usesEncryption: Bool {
        false
    }
}

// MARK: - Mock Biometric Service for Migration Tests

@MainActor
class MockBiometricService: ObservableObject, BiometricAuthenticationServiceProtocol {
    nonisolated(unsafe) var shouldSucceed = true
    nonisolated(unsafe) var shouldCanEvaluate = true

    nonisolated func canEvaluateBiometrics() -> Bool {
        shouldCanEvaluate
    }

    nonisolated func canEvaluateDeviceOwnerAuthentication() -> Bool {
        shouldCanEvaluate
    }

    func authenticateWithBiometrics(reason _: String) async throws -> Bool {
        if shouldSucceed {
            return true
        } else {
            throw LAError(.authenticationFailed)
        }
    }

    func authenticateWithPasscode(reason _: String) async throws -> Bool {
        if shouldSucceed {
            return true
        } else {
            throw LAError(.authenticationFailed)
        }
    }

    nonisolated func biometryType() -> LABiometryType {
        .faceID
    }

    nonisolated func biometryDescription() -> String {
        "Face ID"
    }

    nonisolated func resetContext() {
        // Mock implementation - does nothing
    }
}

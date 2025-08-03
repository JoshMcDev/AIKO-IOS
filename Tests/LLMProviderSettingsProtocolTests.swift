//
//  LLMProviderSettingsProtocolTests.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import XCTest
@testable import AppCore

/// Comprehensive test suite for LLMProviderSettingsViewModelProtocol conformance
/// Part of RED phase - implementing failing tests before implementation
/// Follows DocumentScannerView testing pattern with 125+ test methods
@MainActor
final class LLMProviderSettingsProtocolTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: LLMProviderSettingsViewModel!
    private var mockService: MockLLMProviderSettingsService!
    private var mockConfigService: MockLLMConfigurationService!
    private var mockKeychainService: MockLLMKeychainService!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        mockConfigService = MockLLMConfigurationService()
        mockKeychainService = MockLLMKeychainService()
        mockService = MockLLMProviderSettingsService()
        
        viewModel = LLMProviderSettingsViewModel(
            configurationService: mockConfigService,
            keychainService: mockKeychainService,
            settingsService: mockService
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockService = nil
        mockConfigService = nil
        mockKeychainService = nil
        try await super.tearDown()
    }
    
    // MARK: - Protocol Conformance Tests (8 methods)
    
    func test_viewModel_conformsToProtocol() {
        // RED: This should pass - viewModel conforms to protocol
        XCTAssertTrue(viewModel is any LLMProviderSettingsViewModelProtocol)
    }
    
    func test_protocolRequiredProperties_allImplemented() {
        // RED: Test that all required properties exist
        XCTAssertNotNil(viewModel.uiState)
        XCTAssertEqual(viewModel.uiState, .idle)
        XCTAssertNil(viewModel.alert)
        XCTAssertFalse(viewModel.isProviderConfigSheetPresented)
        XCTAssertNil(viewModel.activeProvider)
        XCTAssertTrue(viewModel.configuredProviders.isEmpty)
        XCTAssertNil(viewModel.selectedProvider)
        XCTAssertNotNil(viewModel.providerPriority)
        XCTAssertFalse(viewModel.isAuthenticating)
        XCTAssertNil(viewModel.providerConfigState)
    }
    
    func test_protocolRequiredMethods_allImplemented() {
        // RED: Verify all protocol methods are implemented
        // These calls should compile but may fail at runtime (expected in RED phase)
        Task {
            await viewModel.loadConfigurations()
            viewModel.selectProvider(.claude)
            await viewModel.saveProviderConfiguration()
            await viewModel.removeProviderConfiguration()
            await viewModel.clearAllConfigurations()
            await viewModel.updateFallbackBehavior(.sequential)
            await viewModel.moveProvider(from: IndexSet([0]), to: 1)
            
            viewModel.updateSelectedModel(TestFixtures.testModel)
            viewModel.updateTemperature(0.5)
            viewModel.updateCustomEndpoint("https://api.test.com")
            viewModel.updateAPIKey("test-key")
            
            viewModel.dismissAlert()
            viewModel.showClearConfirmation()
            viewModel.showError("Test error")
            viewModel.showSuccess("Test success")
            
            await viewModel.authenticateAndSave()
            _ = try await viewModel.testProviderConnection(TestFixtures.testConfig)
            _ = viewModel.validateAPIKeyFormat("test-key", for: .claude)
        }
    }
    
    func test_protocolStateProperties_correctTypes() {
        // RED: Verify state properties have correct types
        XCTAssertTrue(type(of: viewModel.uiState) == LLMProviderSettingsViewModel.UIState.self)
        XCTAssertTrue(type(of: viewModel.alert) == Optional<LLMProviderSettingsViewModel.AlertType>.self)
        XCTAssertTrue(type(of: viewModel.providerPriority) == LLMProviderSettingsViewModel.ProviderPriority.self)
        XCTAssertTrue(type(of: viewModel.configuredProviders) == Array<LLMProvider>.self)
    }
    
    func test_protocolAsyncMethods_correctSignatures() async {
        // RED: Test async method signatures are correct
        await viewModel.loadConfigurations()
        await viewModel.saveProviderConfiguration()
        await viewModel.removeProviderConfiguration()
        await viewModel.clearAllConfigurations()
        await viewModel.updateFallbackBehavior(.sequential)
        await viewModel.moveProvider(from: IndexSet([0]), to: 1)
        await viewModel.authenticateAndSave()
        
        do {
            _ = try await viewModel.testProviderConnection(TestFixtures.testConfig)
        } catch {
            // Expected to fail in RED phase
        }
    }
    
    func test_protocolBindingProperties_correctGetSet() {
        // RED: Test binding properties work correctly
        viewModel.isProviderConfigSheetPresented = true
        XCTAssertTrue(viewModel.isProviderConfigSheetPresented)
        
        viewModel.selectedProvider = .claude
        XCTAssertEqual(viewModel.selectedProvider, .claude)
        
        viewModel.alert = .error("Test")
        XCTAssertNotNil(viewModel.alert)
        
        if case .error(let message) = viewModel.alert {
            XCTAssertEqual(message, "Test")
        } else {
            XCTFail("Alert should be error type")
        }
    }
    
    func test_protocolObservableObject_conformance() {
        // RED: Test ObservableObject conformance
        XCTAssertTrue(viewModel is ObservableObject)
        
        // Test that property changes trigger objectWillChange
        let expectation = XCTestExpectation(description: "ObjectWillChange fired")
        let cancellable = viewModel.objectWillChange.sink {
            expectation.fulfill()
        }
        
        viewModel.uiState = .loading
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    func test_protocolMainActorIsolation_enforced() {
        // RED: Verify @MainActor isolation
        XCTAssertTrue(Thread.isMainThread)
        
        // All property access should be on main thread
        _ = viewModel.uiState
        _ = viewModel.alert
        _ = viewModel.configuredProviders
        _ = viewModel.providerPriority
    }
    
    // MARK: - State Management Tests (12 methods)
    
    func test_initialState_allPropertiesCorrectlySet() {
        // RED: Should fail - initial state may not be correctly set
        XCTAssertEqual(viewModel.uiState, .idle)
        XCTAssertNil(viewModel.activeProvider)
        XCTAssertTrue(viewModel.configuredProviders.isEmpty)
        XCTAssertEqual(viewModel.providerPriority.fallbackBehavior, .sequential)
        XCTAssertNil(viewModel.selectedProvider)
        XCTAssertFalse(viewModel.isProviderConfigSheetPresented)
        XCTAssertFalse(viewModel.isAuthenticating)
        XCTAssertNil(viewModel.providerConfigState)
        XCTAssertNil(viewModel.alert)
        XCTAssertFalse(viewModel.isAlertPresented)
    }
    
    func test_initialState_uiStateIsIdle() {
        // RED: Should pass - initial UI state should be idle
        XCTAssertEqual(viewModel.uiState, .idle)
    }
    
    func test_initialState_noActiveProvider() {
        // RED: Should pass - no active provider initially
        XCTAssertNil(viewModel.activeProvider)
    }
    
    func test_initialState_emptyConfiguredProviders() {
        // RED: Should pass - no configured providers initially
        XCTAssertTrue(viewModel.configuredProviders.isEmpty)
    }
    
    func test_loadConfigurations_stateTransition_idleToLoading() async {
        // RED: Should fail - state management not implemented
        XCTAssertEqual(viewModel.uiState, .idle)
        
        let task = Task {
            await viewModel.loadConfigurations()
        }
        
        // State should transition to loading (but will fail in RED phase)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        await task.value
        
        // This will fail in RED phase as state management is not implemented
        XCTAssertNotEqual(viewModel.uiState, .idle)
    }
    
    func test_loadConfigurations_stateTransition_loadingToLoaded() async {
        // RED: Should fail - state transitions not implemented
        mockConfigService.shouldSucceed = true
        
        await viewModel.loadConfigurations()
        
        // Should be loaded state (will fail in RED phase)
        XCTAssertEqual(viewModel.uiState, .loaded)
    }
    
    func test_loadConfigurations_stateTransition_loadingToError() async {
        // RED: Should fail - error handling not implemented
        mockConfigService.shouldSucceed = false
        mockConfigService.errorToThrow = TestError.configurationFailed
        
        await viewModel.loadConfigurations()
        
        // Should be error state (will fail in RED phase)
        if case .error(let message) = viewModel.uiState {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func test_saveConfiguration_stateTransition_loadedToSaving() async {
        // RED: Should fail - saving state not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        let task = Task {
            await viewModel.saveProviderConfiguration()
        }
        
        // Check for saving state during operation
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        await task.value
        
        // This will fail in RED phase
        XCTAssertTrue(viewModel.providerConfigState?.isSaving == true || viewModel.uiState == .saving)
    }
    
    func test_stateChanges_triggersObservableUpdates() {
        // RED: Should pass - @Observable should trigger updates
        let expectation = XCTestExpectation(description: "State change triggers update")
        let cancellable = viewModel.objectWillChange.sink {
            expectation.fulfill()
        }
        
        viewModel.uiState = .loading
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    func test_concurrentStateChanges_handledCorrectly() async {
        // RED: Should fail - concurrent access not properly handled
        let tasks = (0..<10).map { _ in
            Task {
                await viewModel.loadConfigurations()
            }
        }
        
        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask {
                    await task.value
                }
            }
        }
        
        // State should be consistent (will fail in RED phase)
        XCTAssertTrue([.loaded, .error(""), .loading].contains { state in
            switch (state, viewModel.uiState) {
            case (.loaded, .loaded), (.loading, .loading):
                return true
            case (.error, .error):
                return true
            default:
                return false
            }
        })
    }
    
    func test_stateRollback_onOperationFailure() async {
        // RED: Should fail - rollback not implemented
        let originalState = viewModel.uiState
        mockConfigService.shouldSucceed = false
        
        await viewModel.saveProviderConfiguration()
        
        // State should rollback on failure (will fail in RED phase)
        XCTAssertEqual(viewModel.uiState, originalState)
    }
    
    func test_stateConsistency_acrossAsyncOperations() async {
        // RED: Should fail - state consistency not guaranteed
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        // Start multiple operations
        async let load = viewModel.loadConfigurations()
        async let save = viewModel.saveProviderConfiguration()
        async let clear = viewModel.clearAllConfigurations()
        
        await load
        await save
        await clear
        
        // State should be consistent (will fail in RED phase)
        XCTAssertNotEqual(viewModel.uiState, .loading) // Should not be stuck in loading
    }
    
    // MARK: - Provider Configuration Tests (10 methods)
    
    func test_selectProvider_updatesSelectedProvider() {
        // RED: Should pass - basic property setting
        viewModel.selectProvider(.claude)
        XCTAssertEqual(viewModel.selectedProvider, .claude)
    }
    
    func test_selectProvider_presentsConfigurationSheet() {
        // RED: Should fail - sheet presentation logic not implemented
        viewModel.selectProvider(.claude)
        XCTAssertTrue(viewModel.isProviderConfigSheetPresented)
    }
    
    func test_selectProvider_initializesProviderConfigState() {
        // RED: Should fail - config state initialization not implemented
        viewModel.selectProvider(.claude)
        
        XCTAssertNotNil(viewModel.providerConfigState)
        XCTAssertEqual(viewModel.providerConfigState?.provider, .claude)
        XCTAssertNotNil(viewModel.providerConfigState?.selectedModel)
        XCTAssertEqual(viewModel.providerConfigState?.temperature, 0.7)
        XCTAssertFalse(viewModel.providerConfigState?.customEndpoint.isEmpty == false)
    }
    
    func test_selectProvider_withNoModels_showsError() {
        // RED: Should fail - error handling for no models not implemented
        // This test simulates a provider with no available models
        viewModel.selectProvider(.custom) // Custom provider might have no models
        
        // Should show error for no models (will fail in RED phase)
        XCTAssertNotNil(viewModel.alert)
        if case .error(let message) = viewModel.alert {
            XCTAssertTrue(message.contains("No models available"))
        } else {
            XCTFail("Expected error alert")
        }
    }
    
    func test_updateAPIKey_updatesProviderConfigState() {
        // RED: Should fail - API key update not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        viewModel.updateAPIKey("sk-ant-test123")
        
        XCTAssertEqual(viewModel.providerConfigState?.apiKey, "sk-ant-test123")
    }
    
    func test_updateSelectedModel_updatesProviderConfigState() {
        // RED: Should fail - model update not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        let newModel = TestFixtures.testModel
        viewModel.updateSelectedModel(newModel)
        
        XCTAssertEqual(viewModel.providerConfigState?.selectedModel, newModel)
    }
    
    func test_updateTemperature_validatesRange() {
        // RED: Should fail - temperature validation not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        viewModel.updateTemperature(0.5)
        XCTAssertEqual(viewModel.providerConfigState?.temperature, 0.5)
        
        // Test boundary values
        viewModel.updateTemperature(0.0)
        XCTAssertEqual(viewModel.providerConfigState?.temperature, 0.0)
        
        viewModel.updateTemperature(1.0)
        XCTAssertEqual(viewModel.providerConfigState?.temperature, 1.0)
        
        // Test invalid values (should be clamped or rejected)
        viewModel.updateTemperature(-0.1)
        XCTAssertGreaterThanOrEqual(viewModel.providerConfigState?.temperature ?? 0, 0.0)
        
        viewModel.updateTemperature(1.1)
        XCTAssertLessThanOrEqual(viewModel.providerConfigState?.temperature ?? 1, 1.0)
    }
    
    func test_updateCustomEndpoint_validatesURL() {
        // RED: Should fail - URL validation not implemented
        viewModel.selectedProvider = .custom
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        viewModel.updateCustomEndpoint("https://api.test.com")
        XCTAssertEqual(viewModel.providerConfigState?.customEndpoint, "https://api.test.com")
        
        // Test invalid URLs (should show error or reject)
        viewModel.updateCustomEndpoint("invalid-url")
        // Should either reject or show error (will fail in RED phase)
        XCTAssertTrue(viewModel.alert != nil || viewModel.providerConfigState?.customEndpoint != "invalid-url")
    }
    
    func test_saveConfiguration_callsServiceWithCorrectParameters() async {
        // RED: Should fail - service integration not implemented
        mockService.shouldAuthenticate = true
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        viewModel.providerConfigState?.apiKey = "sk-ant-test123"
        
        await viewModel.saveProviderConfiguration()
        
        XCTAssertTrue(mockService.authenticateAndSaveAPICalled)
        XCTAssertEqual(mockService.lastSavedAPIKey, "sk-ant-test123")
        XCTAssertEqual(mockService.lastSavedProvider, .claude)
    }
    
    func test_removeConfiguration_clearsProviderState() async {
        // RED: Should fail - remove configuration not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        await viewModel.removeProviderConfiguration()
        
        // Should clear state and update UI (will fail in RED phase)
        XCTAssertFalse(viewModel.isProviderConfigSheetPresented)
        XCTAssertNil(viewModel.selectedProvider)
        XCTAssertNil(viewModel.providerConfigState)
    }
    
    // MARK: - Error Handling Tests (8 methods)
    
    func test_saveConfiguration_emptyAPIKey_showsValidationError() async {
        // RED: Should fail - validation not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        viewModel.providerConfigState?.apiKey = ""
        
        await viewModel.saveProviderConfiguration()
        
        XCTAssertNotNil(viewModel.alert)
        if case .error(let message) = viewModel.alert {
            XCTAssertTrue(message.contains("API key is required"))
        } else {
            XCTFail("Expected error alert")
        }
    }
    
    func test_saveConfiguration_invalidAPIKeyFormat_showsError() async {
        // RED: Should fail - format validation not implemented
        mockService.shouldValidateFormat = false
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        viewModel.providerConfigState?.apiKey = "invalid-key"
        
        await viewModel.saveProviderConfiguration()
        
        XCTAssertNotNil(viewModel.alert)
        if case .error(let message) = viewModel.alert {
            XCTAssertTrue(message.contains("Invalid API key format"))
        } else {
            XCTFail("Expected error alert")
        }
    }
    
    func test_updateTemperature_invalidRange_showsError() {
        // RED: Should fail - range validation not implemented
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        viewModel.updateTemperature(-1.0)
        
        // Should show error for invalid range (will fail in RED phase)
        XCTAssertNotNil(viewModel.alert)
    }
    
    func test_updateCustomEndpoint_invalidURL_showsError() {
        // RED: Should fail - URL validation not implemented
        viewModel.selectedProvider = .custom
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        
        viewModel.updateCustomEndpoint("not-a-url")
        
        // Should show error for invalid URL (will fail in RED phase)
        XCTAssertNotNil(viewModel.alert)
    }
    
    func test_loadConfigurations_serviceError_setsErrorState() async {
        // RED: Should fail - error handling not implemented
        mockConfigService.shouldSucceed = false
        mockConfigService.errorToThrow = TestError.networkError
        
        await viewModel.loadConfigurations()
        
        if case .error(let message) = viewModel.uiState {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func test_saveConfiguration_serviceError_showsAlert() async {
        // RED: Should fail - error handling not implemented
        mockService.shouldAuthenticate = false
        mockService.errorToThrow = TestError.authenticationFailed
        viewModel.selectedProvider = .claude
        viewModel.providerConfigState = TestFixtures.testProviderConfigState
        viewModel.providerConfigState?.apiKey = "sk-ant-test123"
        
        await viewModel.saveProviderConfiguration()
        
        XCTAssertNotNil(viewModel.alert)
        if case .error(let message) = viewModel.alert {
            XCTAssertTrue(message.contains("Authentication failed"))
        } else {
            XCTFail("Expected error alert")
        }
    }
    
    func test_removeConfiguration_serviceError_maintainsState() async {
        // RED: Should fail - error recovery not implemented
        mockConfigService.shouldSucceed = false
        mockConfigService.errorToThrow = TestError.configurationFailed
        
        let originalConfigState = viewModel.providerConfigState
        
        await viewModel.removeProviderConfiguration()
        
        // Should maintain state on error (will fail in RED phase)
        XCTAssertEqual(viewModel.providerConfigState, originalConfigState)
    }
    
    func test_clearAllConfigurations_serviceError_showsAlert() async {
        // RED: Should fail - error handling not implemented
        mockService.shouldSucceed = false
        mockService.errorToThrow = TestError.configurationFailed
        
        await viewModel.clearAllConfigurations()
        
        XCTAssertNotNil(viewModel.alert)
        if case .error(let message) = viewModel.alert {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error alert")
        }
    }
    
    // MARK: - Alert Management Tests (7 methods)
    
    func test_alert_propertyUpdates_triggersUIUpdate() {
        // RED: Should pass - @Observable should trigger updates
        let expectation = XCTestExpectation(description: "Alert update triggers UI update")
        let cancellable = viewModel.objectWillChange.sink {
            expectation.fulfill()
        }
        
        viewModel.alert = .error("Test error")
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    func test_dismissAlert_clearsAlertState() {
        // RED: Should pass - basic property clearing
        viewModel.alert = .error("Test error")
        viewModel.dismissAlert()
        XCTAssertNil(viewModel.alert)
        XCTAssertFalse(viewModel.isAlertPresented)
    }
    
    func test_multipleAlerts_latestOverridesPrevious() {
        // RED: Should pass - property replacement
        viewModel.alert = .error("First error")
        viewModel.alert = .success("Success message")
        
        if case .success(let message) = viewModel.alert {
            XCTAssertEqual(message, "Success message")
        } else {
            XCTFail("Expected success alert")
        }
    }
    
    func test_errorAlert_setsCorrectMessage() {
        // RED: Should pass - basic property setting
        viewModel.showError("Test error message")
        
        XCTAssertNotNil(viewModel.alert)
        if case .error(let message) = viewModel.alert {
            XCTAssertEqual(message, "Test error message")
        } else {
            XCTFail("Expected error alert")
        }
    }
    
    func test_successAlert_setsCorrectMessage() {
        // RED: Should pass - basic property setting
        viewModel.showSuccess("Test success message")
        
        XCTAssertNotNil(viewModel.alert)
        if case .success(let message) = viewModel.alert {
            XCTAssertEqual(message, "Test success message")
        } else {
            XCTFail("Expected success alert")
        }
    }
    
    func test_clearConfirmationAlert_setsCorrectActions() {
        // RED: Should pass - basic property setting
        viewModel.showClearConfirmation()
        
        XCTAssertNotNil(viewModel.alert)
        if case .clearConfirmation = viewModel.alert {
            // Correct alert type set
        } else {
            XCTFail("Expected clear confirmation alert")
        }
    }
    
    func test_alertEquality_worksCorrectly() {
        // RED: Should pass - enum equality
        let error1 = LLMProviderSettingsViewModel.AlertType.error("Same message")
        let error2 = LLMProviderSettingsViewModel.AlertType.error("Same message")
        let error3 = LLMProviderSettingsViewModel.AlertType.error("Different message")
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        
        let success1 = LLMProviderSettingsViewModel.AlertType.success("Same message")
        let success2 = LLMProviderSettingsViewModel.AlertType.success("Same message")
        
        XCTAssertEqual(success1, success2)
        XCTAssertNotEqual(error1, success1)
        
        let clear1 = LLMProviderSettingsViewModel.AlertType.clearConfirmation
        let clear2 = LLMProviderSettingsViewModel.AlertType.clearConfirmation
        
        XCTAssertEqual(clear1, clear2)
    }
}

// MARK: - Test Fixtures and Mocks

struct TestFixtures {
    static let testModel = LLMModel(
        id: "claude-3-opus-20240229",
        name: "Claude 3 Opus",
        description: "Test model",
        contextLength: 200_000
    )
    
    static let testConfig = LLMProviderConfig(
        provider: "claude",
        model: "claude-3-opus-20240229",
        customEndpoint: nil,
        temperature: 0.7
    )
    
    static let testProviderConfigState = LLMProviderSettingsViewModel.ProviderConfigurationState(
        provider: .claude,
        hasExistingKey: false,
        selectedModel: testModel,
        temperature: 0.7,
        customEndpoint: "",
        isSaving: false
    )
}

enum TestError: Error, LocalizedError {
    case configurationFailed
    case networkError
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .configurationFailed:
            return "Configuration failed"
        case .networkError:
            return "Network error"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}

// Mock Services
class MockLLMProviderSettingsService: LLMProviderSettingsService {
    var shouldAuthenticate = true
    var shouldValidateFormat = true
    var shouldSucceed = true
    var errorToThrow: Error?
    
    var authenticateAndSaveAPICalled = false
    var lastSavedAPIKey: String?
    var lastSavedProvider: LLMProvider?
    
    override func authenticateAndSaveAPIKey(_ key: String, for provider: LLMProvider) async throws {
        authenticateAndSaveAPICalled = true
        lastSavedAPIKey = key
        lastSavedProvider = provider
        
        if !shouldAuthenticate {
            throw errorToThrow ?? TestError.authenticationFailed
        }
        
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
    }
    
    override func validateAPIKeyFormat(_ key: String, for provider: LLMProvider) -> Bool {
        return shouldValidateFormat
    }
    
    override func testProviderConnection(_ config: LLMProviderConfig) async throws -> Bool {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.networkError
        }
        return true
    }
}

class MockLLMConfigurationService: LLMConfigurationServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: Error?
    
    func getActiveProvider() async throws -> LLMProviderConfig? {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
        return nil
    }
    
    func getAvailableProviders() async throws -> [LLMProvider] {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
        return []
    }
    
    func getProviderPriority() async throws -> LLMProviderSettingsViewModel.ProviderPriority? {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
        return nil
    }
    
    func configureProvider(_ provider: LLMProvider, apiKey: String, config: LLMProviderConfig) async throws {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
    }
    
    func removeProvider(_ provider: LLMProvider) async throws {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
    }
    
    func clearAllConfigurations() async throws {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
    }
    
    func updateProviderPriority(_ priority: LLMProviderSettingsViewModel.ProviderPriority) async throws {
        if !shouldSucceed {
            throw errorToThrow ?? TestError.configurationFailed
        }
    }
}

class MockLLMKeychainService: LLMKeychainServiceProtocol {
    var shouldValidate = true
    
    func validateAPIKeyFormat(_ key: String, _ provider: LLMProvider) -> Bool {
        return shouldValidate
    }
}
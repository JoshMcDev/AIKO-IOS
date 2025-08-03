//
//  LLMProviderSettingsViewModel.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation
import SwiftUI

/// LLMProviderSettingsViewModel - SwiftUI @Observable pattern implementation
/// Manages LLM provider configuration state and business logic
/// Replaces TCA pattern with native SwiftUI state management
/// Conforms to LLMProviderSettingsViewModelProtocol for protocol-based testing
@MainActor
@Observable
public final class LLMProviderSettingsViewModel: LLMProviderSettingsViewModelProtocol {
    // MARK: - UI State

    public enum UIState: Equatable {
        case idle
        case loading
        case loaded
        case saving
        case error(String)
    }

    // MARK: - Alert Types

    public enum AlertType: Equatable {
        case clearConfirmation
        case error(String)
        case success(String)
    }

    // MARK: - Provider Priority

    public struct ProviderPriority: Codable, Equatable, Sendable {
        public let providers: [LLMProvider]
        public let fallbackBehavior: FallbackBehavior

        public enum FallbackBehavior: String, Codable, Sendable {
            case sequential // Try providers in order
            case loadBalanced // Distribute across available providers
            case costOptimized // Choose cheapest available provider
            case performanceOptimized // Choose fastest available provider
        }

        public init(providers: [LLMProvider], fallbackBehavior: FallbackBehavior) {
            self.providers = providers
            self.fallbackBehavior = fallbackBehavior
        }
    }

    // MARK: - Published State

    public var uiState: UIState = .idle
    public var activeProvider: LLMProviderConfig?
    public var configuredProviders: [LLMProvider] = []
    public var providerPriority: ProviderPriority = .init(
        providers: [.claude, .openAI, .gemini],
        fallbackBehavior: .sequential
    )

    public var selectedProvider: LLMProvider?
    public var isProviderConfigSheetPresented = false
    public var providerConfigState: ProviderConfigurationState?

    public var alert: AlertType?
    public var isAlertPresented: Bool { alert != nil }

    /// Whether biometric authentication is currently in progress
    public var isAuthenticating: Bool = false

    // MARK: - Provider Configuration State

    public struct ProviderConfigurationState: Equatable, Sendable {
        public let provider: LLMProvider
        public var hasExistingKey: Bool
        public var selectedModel: LLMModel
        public var temperature: Double
        public var customEndpoint: String
        public var isSaving: Bool
        public var apiKey: String = ""

        public init(
            provider: LLMProvider,
            hasExistingKey: Bool,
            selectedModel: LLMModel,
            temperature: Double = 0.7,
            customEndpoint: String = "",
            isSaving: Bool = false
        ) {
            self.provider = provider
            self.hasExistingKey = hasExistingKey
            self.selectedModel = selectedModel
            self.temperature = temperature
            self.customEndpoint = customEndpoint
            self.isSaving = isSaving
        }
    }

    // MARK: - Dependencies

    private let configurationService: LLMConfigurationServiceProtocol
    private let keychainService: LLMKeychainServiceProtocol
    private let settingsService: LLMProviderSettingsService

    // MARK: - Initialization

    public init(
        configurationService: LLMConfigurationServiceProtocol,
        keychainService: LLMKeychainServiceProtocol,
        settingsService: LLMProviderSettingsService
    ) {
        self.configurationService = configurationService
        self.keychainService = keychainService
        self.settingsService = settingsService
    }

    // MARK: - Public Methods

    public func loadConfigurations() async {
        uiState = .loading

        do {
            let activeProvider = try await configurationService.getActiveProvider()
            let configuredProviders = try await configurationService.getAvailableProviders()
            let priority = try await configurationService.getProviderPriority() ?? ProviderPriority(
                providers: [.claude, .openAI, .gemini],
                fallbackBehavior: .sequential
            )

            self.activeProvider = activeProvider
            self.configuredProviders = configuredProviders
            providerPriority = priority

            uiState = .loaded
        } catch {
            uiState = .error(error.localizedDescription)
            alert = .error(error.localizedDescription)
        }
    }

    public func selectProvider(_ provider: LLMProvider) {
        selectedProvider = provider

        // Get available models for the provider
        let availableModels = getModelsForProvider(provider)
        guard let defaultModel = availableModels.first else {
            alert = .error("No models available for \(provider.name)")
            return
        }

        providerConfigState = ProviderConfigurationState(
            provider: provider,
            hasExistingKey: configuredProviders.contains(provider),
            selectedModel: defaultModel,
            temperature: 0.7
        )

        isProviderConfigSheetPresented = true
    }

    public func dismissProviderConfigSheet() {
        isProviderConfigSheetPresented = false
        selectedProvider = nil
        providerConfigState = nil
    }

    public func saveProviderConfiguration() async {
        guard var configState = providerConfigState else { return }

        // Validate API key
        let apiKey = configState.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            alert = .error("API key is required")
            return
        }

        let isValid = keychainService.validateAPIKeyFormat(apiKey, configState.provider)
        guard isValid else {
            alert = .error("Invalid API key format for \(configState.provider.name)")
            return
        }

        configState.isSaving = true
        providerConfigState = configState

        let config = LLMProviderConfig(
            provider: configState.provider.rawValue,
            model: configState.selectedModel.id,
            customEndpoint: configState.customEndpoint.isEmpty ? nil : configState.customEndpoint,
            temperature: configState.temperature
        )

        do {
            try await configurationService.configureProvider(
                configState.provider,
                apiKey: apiKey,
                config: config
            )

            dismissProviderConfigSheet()
            await loadConfigurations()
            alert = .success("\(configState.provider.name) configured successfully")
        } catch {
            configState.isSaving = false
            providerConfigState = configState
            alert = .error("Failed to save configuration: \(error.localizedDescription)")
        }
    }

    public func removeProviderConfiguration() async {
        guard var configState = providerConfigState else { return }

        configState.isSaving = true
        providerConfigState = configState

        do {
            try await configurationService.removeProvider(configState.provider)

            dismissProviderConfigSheet()
            await loadConfigurations()
            alert = .success("\(configState.provider.name) configuration removed")
        } catch {
            configState.isSaving = false
            providerConfigState = configState
            alert = .error("Failed to remove configuration: \(error.localizedDescription)")
        }
    }

    public func clearAllConfigurations() async {
        do {
            try await configurationService.clearAllConfigurations()
            activeProvider = nil
            configuredProviders = []
            alert = .success("All configurations cleared")
        } catch {
            alert = .error("Failed to clear configurations: \(error.localizedDescription)")
        }
    }

    public func updateFallbackBehavior(_ behavior: ProviderPriority.FallbackBehavior) async {
        providerPriority = ProviderPriority(
            providers: providerPriority.providers,
            fallbackBehavior: behavior
        )

        do {
            try await configurationService.updateProviderPriority(providerPriority)
        } catch {
            alert = .error("Failed to update fallback behavior: \(error.localizedDescription)")
        }
    }

    public func moveProvider(from source: IndexSet, to destination: Int) async {
        var providers = providerPriority.providers
        providers.move(fromOffsets: source, toOffset: destination)

        providerPriority = ProviderPriority(
            providers: providers,
            fallbackBehavior: providerPriority.fallbackBehavior
        )

        do {
            try await configurationService.updateProviderPriority(providerPriority)
        } catch {
            alert = .error("Failed to update provider order: \(error.localizedDescription)")
        }
    }

    public func dismissAlert() {
        alert = nil
    }

    public func showClearConfirmation() {
        alert = .clearConfirmation
    }

    public func showError(_ message: String) {
        alert = .error(message)
    }

    public func showSuccess(_ message: String) {
        alert = .success(message)
    }

    /// Perform biometric authentication before saving configuration
    /// Preserves the exact pattern from original TCA implementation (lines 395-424)
    public func authenticateAndSave() async {
        guard let configState = providerConfigState else { return }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            try await settingsService.authenticateAndSaveAPIKey(
                configState.apiKey,
                for: configState.provider
            )

            // Update configuration after successful save
            dismissProviderConfigSheet()
            await loadConfigurations()
            alert = .success("\(configState.provider.name) configured successfully")
        } catch LLMProviderError.invalidCredentials {
            showError("Authentication failed: Biometric authentication required")
        } catch {
            showError("Authentication failed: \(error.localizedDescription)")
        }
    }

    /// Test connection to the specified provider
    @MainActor
    public func testProviderConnection(_ config: LLMProviderConfig) async throws -> Bool {
        try await settingsService.testProviderConnection(config)
    }

    /// Validate API key format for the specified provider
    public func validateAPIKeyFormat(_ key: String, for provider: LLMProvider) -> Bool {
        settingsService.validateAPIKeyFormat(key, for: provider)
    }

    // MARK: - Provider Config Methods

    public func updateSelectedModel(_ model: LLMModel) {
        guard var configState = providerConfigState else { return }
        configState.selectedModel = model
        providerConfigState = configState
    }

    public func updateTemperature(_ temperature: Double) {
        guard var configState = providerConfigState else { return }

        // Validate and clamp temperature to valid range
        let validatedTemperature = validateTemperature(temperature)
        configState.temperature = validatedTemperature.value

        if let errorMessage = validatedTemperature.errorMessage {
            alert = .error(errorMessage)
        }

        providerConfigState = configState
    }

    /// Validates and clamps temperature to valid range (0.0 to 1.0)
    /// - Parameter temperature: Temperature value to validate
    /// - Returns: Tuple containing validated temperature and optional error message
    private func validateTemperature(_ temperature: Double) -> (value: Double, errorMessage: String?) {
        let minTemperature = 0.0
        let maxTemperature = 1.0
        let errorMessage = "Temperature must be between \(minTemperature) and \(maxTemperature)"

        if temperature < minTemperature {
            return (minTemperature, errorMessage)
        } else if temperature > maxTemperature {
            return (maxTemperature, errorMessage)
        } else {
            return (temperature, nil)
        }
    }

    public func updateCustomEndpoint(_ endpoint: String) {
        guard var configState = providerConfigState else { return }

        // Validate URL format if not empty
        if !endpoint.isEmpty {
            if URL(string: endpoint) == nil {
                alert = .error("Invalid URL format")
                return
            }
        }

        configState.customEndpoint = endpoint
        providerConfigState = configState
    }

    public func updateAPIKey(_ apiKey: String) {
        guard var configState = providerConfigState else { return }
        configState.apiKey = apiKey
        providerConfigState = configState
    }

    // MARK: - Helper Methods

    public func getModelsForProvider(_ provider: LLMProvider) -> [LLMModel] {
        LLMModelProviderService.shared.getModelsForProvider(provider)
    }
}

// MARK: - Service Protocols

public protocol LLMConfigurationServiceProtocol: Sendable {
    func getActiveProvider() async throws -> LLMProviderConfig?
    func getAvailableProviders() async throws -> [LLMProvider]
    func getProviderPriority() async throws -> LLMProviderSettingsViewModel.ProviderPriority?
    func configureProvider(_ provider: LLMProvider, apiKey: String, config: LLMProviderConfig) async throws
    func removeProvider(_ provider: LLMProvider) async throws
    func clearAllConfigurations() async throws
    func updateProviderPriority(_ priority: LLMProviderSettingsViewModel.ProviderPriority) async throws
}

public protocol LLMKeychainServiceProtocol: Sendable {
    func validateAPIKeyFormat(_ key: String, _ provider: LLMProvider) -> Bool
    func saveAPIKey(_ key: String, for provider: LLMProvider) async throws
    func getAPIKey(for provider: LLMProvider) async throws -> String
    func deleteAPIKey(for provider: LLMProvider) async throws
    func clearAllAPIKeys() async throws
}

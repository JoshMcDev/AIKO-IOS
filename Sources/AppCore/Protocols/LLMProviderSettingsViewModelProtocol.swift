import Foundation
import SwiftUI

/// Protocol defining the interface for LLM provider settings view models
/// This enables protocol-based testing and dependency injection following DocumentScannerView pattern
@MainActor
public protocol LLMProviderSettingsViewModelProtocol: ObservableObject {
    // MARK: - Associated Types

    associatedtype UIState: Equatable
    associatedtype AlertType: Equatable
    associatedtype ProviderPriority: Equatable & Sendable
    associatedtype ProviderConfigurationState: Equatable

    // MARK: - State Properties

    /// Current UI state (idle, loading, loaded, saving, error)
    var uiState: UIState { get }

    /// Current alert to display, if any
    var alert: AlertType? { get set }

    /// Whether the provider configuration sheet is presented
    var isProviderConfigSheetPresented: Bool { get set }

    /// Currently active/selected provider configuration
    var activeProvider: LLMProviderConfig? { get }

    /// List of providers that have been configured with API keys
    var configuredProviders: [LLMProvider] { get }

    /// Currently selected provider for configuration
    var selectedProvider: LLMProvider? { get set }

    /// Provider priority and fallback behavior configuration
    var providerPriority: ProviderPriority { get }

    /// Whether biometric authentication is currently in progress
    var isAuthenticating: Bool { get }

    /// Configuration state for the provider being configured
    var providerConfigState: ProviderConfigurationState? { get set }

    // MARK: - Computed Properties

    /// Whether an alert is currently presented
    var isAlertPresented: Bool { get }

    // MARK: - Core Actions

    /// Load all provider configurations from storage
    func loadConfigurations() async

    /// Select a provider for configuration
    func selectProvider(_ provider: LLMProvider)

    /// Save the current provider configuration with biometric authentication
    func saveProviderConfiguration() async

    /// Remove the configuration for the currently selected provider
    func removeProviderConfiguration() async

    /// Clear all provider configurations with confirmation
    func clearAllConfigurations() async

    /// Update the fallback behavior for provider selection
    func updateFallbackBehavior(_ behavior: LLMProviderSettingsViewModel.ProviderPriority.FallbackBehavior) async

    /// Move provider in priority order
    func moveProvider(from: IndexSet, to: Int) async

    // MARK: - Provider Configuration Actions

    /// Update the selected model for the current provider
    func updateSelectedModel(_ model: LLMModel)

    /// Update the temperature setting for the current provider
    func updateTemperature(_ temperature: Double)

    /// Update the custom endpoint URL for the current provider
    func updateCustomEndpoint(_ endpoint: String)

    /// Update the API key for the current provider
    func updateAPIKey(_ apiKey: String)

    // MARK: - Alert Management

    /// Dismiss the currently displayed alert
    func dismissAlert()

    /// Show confirmation dialog for clearing all configurations
    func showClearConfirmation()

    /// Show an error alert with the specified message
    func showError(_ message: String)

    /// Show a success alert with the specified message
    func showSuccess(_ message: String)

    // MARK: - Security Actions

    /// Perform biometric authentication before saving configuration
    func authenticateAndSave() async

    /// Test connection to the specified provider
    func testProviderConnection(_ config: LLMProviderConfig) async throws -> Bool

    /// Validate API key format for the specified provider
    func validateAPIKeyFormat(_ key: String, for provider: LLMProvider) -> Bool
}

// MARK: - Default Implementations

public extension LLMProviderSettingsViewModelProtocol {
    /// Default implementation of isAlertPresented
    var isAlertPresented: Bool {
        alert != nil
    }

    /// Default implementation of dismissAlert
    func dismissAlert() {
        alert = nil
    }

    /// Default implementation of showError
    func showError(_: String) {
        // Implementation provided by conforming type
    }

    /// Default implementation of showSuccess
    func showSuccess(_: String) {
        // Implementation provided by conforming type
    }
}

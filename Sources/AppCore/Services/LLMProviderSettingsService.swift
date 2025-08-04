import Foundation

/// Service layer for LLM provider settings management
/// Coordinates between biometric authentication, keychain storage, and provider validation
/// Following DocumentScannerService architectural pattern
/// Removed ObservableObject dependency to decouple from SwiftUI framework
@MainActor
open class LLMProviderSettingsService {
    // MARK: - Dependencies

    private let biometricService: any BiometricAuthenticationServiceProtocol
    private let keychainService: LLMKeychainServiceProtocol
    private let configurationService: LLMConfigurationServiceProtocol

    // MARK: - Initialization

    public init(
        biometricService: any BiometricAuthenticationServiceProtocol,
        keychainService: LLMKeychainServiceProtocol,
        configurationService: LLMConfigurationServiceProtocol
    ) {
        self.biometricService = biometricService
        self.keychainService = keychainService
        self.configurationService = configurationService
    }

    // MARK: - Security Operations

    /// Authenticate user and save API key securely
    /// Preserves biometric authentication pattern from original implementation (lines 395-424)
    /// - Parameters:
    ///   - key: API key to save
    ///   - provider: Provider to associate with the key
    /// - Throws: AuthenticationError or KeychainError
    open func authenticateAndSaveAPIKey(_ key: String, for provider: LLMProvider) async throws {
        // Require biometric authentication before saving
        let authenticated = try await performBiometricAuthentication(
            reason: "Authenticate to save \(provider.name) API key"
        )

        guard authenticated else {
            throw LLMProviderError.invalidCredentials
        }

        try await keychainService.saveAPIKey(key, for: provider)
    }

    /// Validate API key format for the specified provider
    /// - Parameters:
    ///   - key: API key to validate
    ///   - provider: Provider to validate against
    /// - Returns: True if the key format is valid
    public func validateAPIKeyFormat(_ key: String, for provider: LLMProvider) -> Bool {
        guard !key.isEmpty else { return false }

        switch provider {
        case .claude:
            return key.hasPrefix("sk-ant-") && key.count > 20
        case .openAI, .chatGPT:
            return key.hasPrefix("sk-") && key.count > 20
        case .gemini:
            return key.hasPrefix("AIza") && key.count > 20
        case .azureOpenAI:
            return key.count >= 30 // Azure keys are typically 32 characters hex
        case .local:
            return true // Local models don't need API keys
        case .custom:
            return key.count > 10 // Basic validation for custom providers
        }
    }

    /// Delete API key for the specified provider with authentication
    /// - Parameter provider: Provider whose API key should be deleted
    /// - Throws: AuthenticationError or KeychainError
    public func deleteAPIKey(for provider: LLMProvider) async throws {
        let authenticated = try await performBiometricAuthentication(
            reason: "Authenticate to remove \(provider.name) API key"
        )

        guard authenticated else {
            throw LLMProviderError.invalidCredentials
        }

        try await keychainService.deleteAPIKey(for: provider)
    }

    /// Perform biometric authentication with fallback to passcode
    /// Implements the exact pattern from lines 395-424 of original TCA implementation
    /// - Parameter reason: Localized reason for authentication
    /// - Returns: True if authentication succeeded
    /// - Throws: AuthenticationError if authentication fails
    public func performBiometricAuthentication(reason: String) async throws -> Bool {
        // Check if biometrics are available
        if biometricService.canEvaluateBiometrics() {
            do {
                return try await biometricService.authenticateWithBiometrics(reason: reason)
            } catch {
                print("Biometric authentication failed: \(error)")
                // Fallback to device passcode
                return try await biometricService.authenticateWithPasscode(reason: reason)
            }
        } else {
            // Fallback to device passcode if biometrics not available
            return try await biometricService.authenticateWithPasscode(reason: reason)
        }
    }

    // MARK: - Provider Management

    /// Load all provider configurations from storage
    /// - Returns: Array of configured LLMProviderConfig objects
    /// - Throws: ConfigurationError if loading fails
    public func loadProviderConfigurations() async throws -> [LLMProviderConfig] {
        let availableProviders = try await configurationService.getAvailableProviders()
        var configurations: [LLMProviderConfig] = []

        for provider in availableProviders {
            let hasKey = await hasAPIKey(for: provider)
            if hasKey {
                // Create basic configuration for providers with API keys
                let models = getModelsForProvider(provider)
                let defaultModel = models.first?.id ?? "default"

                let config = LLMProviderConfig(
                    provider: provider,
                    model: defaultModel,
                    temperature: 0.7
                )
                configurations.append(config)
            }
        }

        return configurations
    }

    /// Update provider priority configuration
    /// - Parameter priority: New provider priority configuration
    /// - Throws: ConfigurationError if update fails
    public func updateProviderPriority(_ priority: LLMProviderSettingsViewModel.ProviderPriority) async throws {
        try await configurationService.updateProviderPriority(priority)
    }

    /// Test connection to a provider with the given configuration
    /// - Parameter config: Provider configuration to test
    /// - Returns: True if connection is successful
    /// - Throws: NetworkError or ProviderError if connection fails
    public func testProviderConnection(_ config: LLMProviderConfig) async throws -> Bool {
        // Get provider enum from config
        guard let provider = LLMProvider(rawValue: config.provider) else {
            throw LLMProviderError.modelNotSupported(config.provider)
        }

        // Check if API key exists
        let hasKey = await hasAPIKey(for: provider)
        guard hasKey else {
            throw LLMProviderError.notConfigured
        }

        // For GREEN phase: simulate connection test
        // In a real implementation, this would make actual API calls
        switch provider {
        case .local:
            // Local models are always available
            return true
        case .claude, .openAI, .chatGPT, .gemini, .azureOpenAI, .custom:
            // Simulate network test delay
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms

            // Basic validation of endpoint if custom
            if let endpoint = config.customEndpoint {
                guard URL(string: endpoint) != nil else {
                    throw LLMProviderError.invalidResponse("Invalid endpoint URL")
                }
            }

            // Simulate successful connection for GREEN phase
            return true
        }
    }

    /// Check if a provider has an API key configured
    /// - Parameter provider: Provider to check
    /// - Returns: True if API key exists in keychain
    public func hasAPIKey(for provider: LLMProvider) async -> Bool {
        do {
            let key = try await keychainService.getAPIKey(for: provider)
            return !key.isEmpty
        } catch {
            return false
        }
    }

    /// Clear all provider configurations with authentication
    /// - Throws: AuthenticationError or KeychainError
    public func clearAllConfigurations() async throws {
        let authenticated = try await performBiometricAuthentication(
            reason: "Authenticate to clear all API keys"
        )

        guard authenticated else {
            throw LLMProviderError.invalidCredentials
        }

        try await keychainService.clearAllAPIKeys()
        try await configurationService.clearAllConfigurations()
    }

    // MARK: - Helper Methods

    /// Get available models for a provider using centralized service
    /// - Parameter provider: Provider to get models for
    /// - Returns: Array of available models
    private func getModelsForProvider(_ provider: LLMProvider) -> [LLMModel] {
        LLMModelProviderService.shared.getModelsForProvider(provider)
    }
}

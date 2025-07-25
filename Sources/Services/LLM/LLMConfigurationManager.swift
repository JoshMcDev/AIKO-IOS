//
//  LLMConfigurationManager.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import AppCore
import Foundation
import SwiftUI

/// Manages LLM provider configurations with secure storage
@MainActor
final class LLMConfigurationManager: ObservableObject, @unchecked Sendable {
    // MARK: - Properties

    static let shared = LLMConfigurationManager()

    /// Current active provider configuration
    @Published var activeProviderConfig: LLMProviderConfig?

    /// All configured providers
    @Published var configuredProviders: [LLMProvider: LLMProviderConfig] = [:]

    /// Provider priority for fallback
    @Published var providerPriority: LLMProviderPriority

    /// UserDefaults keys for non-sensitive data
    private enum UserDefaultsKeys {
        static let activeProvider = "llm.activeProvider"
        static let providerConfigs = "llm.providerConfigs"
        static let providerPriority = "llm.providerPriority"
    }

    private let keychain = LLMKeychainService.shared

    // MARK: - Initialization

    private init() {
        // Default provider priority
        providerPriority = LLMProviderPriority(
            providers: [.claude, .openAI, .gemini],
            fallbackBehavior: .sequential
        )

        // Load saved configurations
        loadConfigurations()

        // Migrate from UserDefaults if needed
        // Migration would go here if needed
    }

    // MARK: - Configuration Management

    /// Configures a provider with API key and settings
    /// - Parameters:
    ///   - provider: The LLM provider
    ///   - apiKey: The API key
    ///   - config: Additional configuration
    /// - Throws: KeychainError if storing API key fails
    func configureProvider(
        _ provider: LLMProvider,
        apiKey: String,
        config: LLMProviderConfig? = nil
    ) throws {
        // Validate API key format
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.invalidAPIKey(provider: provider)
        }

        // Store API key securely in keychain
        try keychain.storeAPIKey(apiKey, for: provider.rawValue)

        // Create or update configuration (without API key)
        let defaultModel = getDefaultModel(for: provider)
        let providerConfig = config ?? LLMProviderConfig(
            provider: provider.rawValue,
            providerId: provider.rawValue,
            model: defaultModel
        )
        let finalConfig = LLMProviderConfig(
            provider: provider.rawValue,
            providerId: provider.rawValue,
            model: providerConfig.model,
            apiKey: nil, // Never store API key in config
            organizationId: providerConfig.organizationId,
            customEndpoint: providerConfig.customEndpoint,
            customHeaders: providerConfig.customHeaders,
            temperature: providerConfig.temperature,
            maxTokens: providerConfig.maxTokens,
            topP: providerConfig.topP,
            frequencyPenalty: providerConfig.frequencyPenalty,
            presencePenalty: providerConfig.presencePenalty,
            stopSequences: providerConfig.stopSequences
        )

        configuredProviders[provider] = finalConfig

        // If no active provider, set this as active
        if activeProviderConfig == nil {
            activeProviderConfig = finalConfig
        }

        // Save configurations
        saveConfigurations()
    }

    /// Removes a provider configuration
    /// - Parameter provider: The provider to remove
    func removeProvider(_ provider: LLMProvider) throws {
        // Remove API key from keychain
        try keychain.deleteAPIKey(for: provider.rawValue)

        // Remove configuration
        configuredProviders.removeValue(forKey: provider)

        // If this was the active provider, switch to next available
        if activeProviderConfig?.provider == provider.rawValue {
            activeProviderConfig = configuredProviders.values.first
        }

        // Save configurations
        saveConfigurations()
    }

    /// Sets the active provider
    /// - Parameter provider: The provider to activate
    func setActiveProvider(_ provider: LLMProvider) throws {
        guard let config = configuredProviders[provider] else {
            throw LLMError.providerUnavailable(provider: provider)
        }

        // Verify API key exists
        guard keychain.hasAPIKey(for: provider.rawValue) else {
            throw LLMError.noAPIKey(provider: provider)
        }

        activeProviderConfig = config
        UserDefaults.standard.set(provider.rawValue, forKey: UserDefaultsKeys.activeProvider)
    }

    /// Updates provider priority for fallback
    /// - Parameter priority: New priority configuration
    func updateProviderPriority(_ priority: LLMProviderPriority) {
        providerPriority = priority

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(priority) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.providerPriority)
        }
    }

    /// Gets the API key for a provider
    /// - Parameter provider: The provider
    /// - Returns: The API key if available
    func getAPIKey(for provider: LLMProvider) -> String? {
        try? keychain.retrieveAPIKey(for: provider.rawValue)
    }

    /// Gets all available providers (configured with API keys)
    /// - Returns: Array of available providers
    func getAvailableProviders() -> [LLMProvider] {
        configuredProviders.keys.filter { provider in
            keychain.hasAPIKey(for: provider.rawValue)
        }.sorted { $0.rawValue < $1.rawValue }
    }

    /// Lists configured provider IDs
    /// - Returns: Array of provider ID strings
    func listConfiguredProviders() -> [String] {
        configuredProviders.keys.map(\.rawValue)
    }

    /// Checks if a provider is configured
    /// - Parameter providerId: The provider ID to check
    /// - Returns: True if the provider is configured
    nonisolated func isProviderConfigured(_ providerId: String) -> Bool {
        guard let provider = LLMProvider(rawValue: providerId) else { return false }
        return MainActor.assumeIsolated {
            configuredProviders[provider] != nil && keychain.hasAPIKey(for: providerId)
        }
    }

    /// Loads configuration for a specific provider
    /// - Parameter providerId: The provider ID
    /// - Returns: The configuration if available
    nonisolated func loadConfiguration(for providerId: String) throws -> LLMProviderConfig? {
        guard let provider = LLMProvider(rawValue: providerId) else {
            throw LLMError.configurationError("Invalid provider ID: \(providerId)")
        }
        return MainActor.assumeIsolated {
            configuredProviders[provider]
        }
    }

    /// Gets default model for a provider
    /// - Parameter provider: The LLM provider
    /// - Returns: Default model name for the provider
    private func getDefaultModel(for provider: LLMProvider) -> String {
        switch provider {
        case .claude:
            "claude-3-sonnet-20240229"
        case .openAI, .chatGPT:
            "gpt-4"
        case .gemini:
            "gemini-pro"
        case .azureOpenAI:
            "gpt-4"
        case .local:
            "local-model"
        case .custom:
            "custom-model"
        }
    }

    /// Gets the next provider in fallback order
    /// - Parameter currentProvider: The current provider that failed
    /// - Returns: Next provider if available
    func getNextFallbackProvider(after currentProvider: LLMProvider) -> LLMProvider? {
        let availableProviders = getAvailableProviders()
        let priorityProviders = providerPriority.providers.filter { availableProviders.contains($0) }

        guard let currentIndex = priorityProviders.firstIndex(of: currentProvider),
              currentIndex + 1 < priorityProviders.count
        else {
            return nil
        }

        return priorityProviders[currentIndex + 1]
    }

    // MARK: - Persistence

    /// Loads configurations from UserDefaults
    private func loadConfigurations() {
        // Load provider configurations
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.providerConfigs),
           let configs = try? JSONDecoder().decode([LLMProvider: LLMProviderConfig].self, from: data)
        {
            configuredProviders = configs
        }

        // Load active provider
        if let activeProviderString = UserDefaults.standard.string(forKey: UserDefaultsKeys.activeProvider),
           let activeProvider = LLMProvider(rawValue: activeProviderString),
           let config = configuredProviders[activeProvider]
        {
            activeProviderConfig = config
        }

        // Load provider priority
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.providerPriority),
           let priority = try? JSONDecoder().decode(LLMProviderPriority.self, from: data)
        {
            providerPriority = priority
        }
    }

    /// Saves configurations to UserDefaults
    private func saveConfigurations() {
        // Save provider configurations (without API keys)
        if let encoded = try? JSONEncoder().encode(configuredProviders) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.providerConfigs)
        }

        // Save active provider
        if let activeProvider = activeProviderConfig?.provider {
            UserDefaults.standard.set(activeProvider, forKey: UserDefaultsKeys.activeProvider)
        }
    }

    // MARK: - Security

    /// Clears all provider configurations and API keys
    func clearAllConfigurations() throws {
        // Clear keychain
        try keychain.deleteAllAPIKeys()

        // Clear configurations
        configuredProviders.removeAll()
        activeProviderConfig = nil

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.providerConfigs)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.activeProvider)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.providerPriority)
    }

    /// Validates all configured providers have valid API keys
    /// - Returns: Dictionary of validation results
    func validateAllProviders() async -> [LLMProvider: Bool] {
        var results: [LLMProvider: Bool] = [:]

        for provider in configuredProviders.keys {
            results[provider] = keychain.hasAPIKey(for: provider.rawValue)
        }

        return results
    }
}

// MARK: - TCA Integration

/// Configuration client for The Composable Architecture
public struct LLMConfigurationClient: Sendable {
    public var configureProvider: @Sendable (LLMProvider, String, LLMProviderConfig?) async throws -> Void
    public var removeProvider: @Sendable (LLMProvider) async throws -> Void
    public var setActiveProvider: @Sendable (LLMProvider) async throws -> Void
    public var getAPIKey: @Sendable (LLMProvider) async -> String?
    public var getAvailableProviders: @Sendable () async -> [LLMProvider]
    public var getActiveProvider: @Sendable () async -> LLMProviderConfig?
    public var getNextFallbackProvider: @Sendable (LLMProvider) async -> LLMProvider?
    public var updateProviderPriority: @Sendable (LLMProviderPriority) async -> Void
    public var validateAllProviders: @Sendable () async -> [LLMProvider: Bool]
    public var clearAllConfigurations: @Sendable () async throws -> Void

    // MARK: - Initializer

    public init(
        configureProvider: @escaping @Sendable (LLMProvider, String, LLMProviderConfig?) async throws -> Void,
        removeProvider: @escaping @Sendable (LLMProvider) async throws -> Void,
        setActiveProvider: @escaping @Sendable (LLMProvider) async throws -> Void,
        getAPIKey: @escaping @Sendable (LLMProvider) async -> String?,
        getAvailableProviders: @escaping @Sendable () async -> [LLMProvider],
        getActiveProvider: @escaping @Sendable () async -> LLMProviderConfig?,
        getNextFallbackProvider: @escaping @Sendable (LLMProvider) async -> LLMProvider?,
        updateProviderPriority: @escaping @Sendable (LLMProviderPriority) async -> Void,
        validateAllProviders: @escaping @Sendable () async -> [LLMProvider: Bool],
        clearAllConfigurations: @escaping @Sendable () async throws -> Void
    ) {
        self.configureProvider = configureProvider
        self.removeProvider = removeProvider
        self.setActiveProvider = setActiveProvider
        self.getAPIKey = getAPIKey
        self.getAvailableProviders = getAvailableProviders
        self.getActiveProvider = getActiveProvider
        self.getNextFallbackProvider = getNextFallbackProvider
        self.updateProviderPriority = updateProviderPriority
        self.validateAllProviders = validateAllProviders
        self.clearAllConfigurations = clearAllConfigurations
    }
}

public extension LLMConfigurationClient {
    static let liveValue = Self(
        configureProvider: { provider, apiKey, config in
            try await MainActor.run {
                try LLMConfigurationManager.shared.configureProvider(provider, apiKey: apiKey, config: config)
            }
        },
        removeProvider: { provider in
            try await MainActor.run {
                try LLMConfigurationManager.shared.removeProvider(provider)
            }
        },
        setActiveProvider: { provider in
            try await MainActor.run {
                try LLMConfigurationManager.shared.setActiveProvider(provider)
            }
        },
        getAPIKey: { provider in
            await MainActor.run {
                LLMConfigurationManager.shared.getAPIKey(for: provider)
            }
        },
        getAvailableProviders: {
            await MainActor.run {
                LLMConfigurationManager.shared.getAvailableProviders()
            }
        },
        getActiveProvider: {
            await MainActor.run {
                LLMConfigurationManager.shared.activeProviderConfig
            }
        },
        getNextFallbackProvider: { provider in
            await MainActor.run {
                LLMConfigurationManager.shared.getNextFallbackProvider(after: provider)
            }
        },
        updateProviderPriority: { priority in
            await MainActor.run {
                LLMConfigurationManager.shared.updateProviderPriority(priority)
            }
        },
        validateAllProviders: {
            await LLMConfigurationManager.shared.validateAllProviders()
        },
        clearAllConfigurations: {
            try await MainActor.run {
                try LLMConfigurationManager.shared.clearAllConfigurations()
            }
        }
    )
}

// MARK: - Environment Key for SwiftUI

public extension EnvironmentValues {
    var llmConfiguration: LLMConfigurationClient {
        get { self[LLMConfigurationEnvironmentKey.self] }
        set { self[LLMConfigurationEnvironmentKey.self] = newValue }
    }
}

public struct LLMConfigurationEnvironmentKey: EnvironmentKey {
    public static let defaultValue: LLMConfigurationClient = .liveValue
}

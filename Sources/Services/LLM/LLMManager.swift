import AppCore
import ComposableArchitecture
import Foundation

// MARK: - LLM Manager

/// Central manager for all LLM providers with fallback support
@MainActor
public final class LLMManager: ObservableObject {
    // MARK: - Properties

    public static let shared = LLMManager()

    @Published public private(set) var providers: [any LLMProviderProtocol] = []
    @Published public private(set) var activeProvider: (any LLMProviderProtocol)?
    @Published public private(set) var isConfigured: Bool = false

    private let configManager = LLMConfigurationManager.shared
    private var providerInstances: [String: any LLMProviderProtocol] = [:]

    // Provider priority order for fallback
    private let providerPriority = [
        "claude",
        "openai",
        "azure-openai",
        "gemini",
        "local",
    ]

    // MARK: - Initialization

    private init() {
        initializeProviders()
        Task {
            await loadConfigurations()
        }
    }

    private func initializeProviders() {
        // Initialize all available providers
        let availableProviders: [any LLMProviderProtocol] = [
            ClaudeProvider(),
            OpenAIProvider(),
            GeminiProvider(),
            AzureOpenAIProvider(),
            LocalModelProvider(),
        ]

        for provider in availableProviders {
            providerInstances[provider.id] = provider
        }

        providers = availableProviders
    }

    // MARK: - Public Methods

    /// Load configurations and set active provider
    public func loadConfigurations() async {
        let configuredProviders = configManager.listConfiguredProviders()

        // Find first configured provider in priority order
        for providerId in providerPriority {
            if configuredProviders.contains(providerId),
               let provider = providerInstances[providerId]
            {
                let isValid = await provider.isConfigured
                if isValid {
                    activeProvider = provider
                    isConfigured = true
                    break
                }
            }
        }

        // If no provider in priority order, use first configured
        if activeProvider == nil, !configuredProviders.isEmpty {
            for providerId in configuredProviders {
                if let provider = providerInstances[providerId] {
                    let isValid = await provider.isConfigured
                    if isValid {
                        activeProvider = provider
                        isConfigured = true
                        break
                    }
                }
            }
        }
    }

    /// Set active provider
    public func setActiveProvider(_ providerId: String) async throws {
        guard let provider = providerInstances[providerId] else {
            throw LLMManagerError.providerNotFound(providerId)
        }

        guard await provider.isConfigured else {
            throw LLMManagerError.providerNotConfigured(providerId)
        }

        activeProvider = provider
        isConfigured = true
    }

    /// Configure a provider
    public func configureProvider(_ config: LLMProviderConfig) async throws {
        guard let providerInstance = providerInstances[config.providerId] else {
            throw LLMManagerError.providerNotFound(config.providerId)
        }

        guard let providerEnum = LLMProvider(rawValue: config.providerId) else {
            throw LLMManagerError.providerNotFound(config.providerId)
        }
        try configManager.configureProvider(providerEnum, apiKey: config.apiKey ?? "", config: config)

        // Validate the configuration
        let isValid = try await providerInstance.validateCredentials()
        if !isValid {
            try configManager.removeProvider(LLMProvider(rawValue: config.providerId) ?? .custom)
            throw LLMProviderError.invalidCredentials
        }

        // Set as active if no active provider
        if activeProvider == nil {
            activeProvider = providerInstance
            isConfigured = true
        }
    }

    /// Remove provider configuration
    public func removeProviderConfiguration(_ providerId: String) throws {
        try configManager.removeProvider(LLMProvider(rawValue: providerId) ?? .custom)

        // If this was the active provider, find a new one
        if activeProvider?.id == providerId {
            activeProvider = nil
            isConfigured = false
            Task {
                await loadConfigurations()
            }
        }
    }

    /// Get configured providers
    public func getConfiguredProviders() -> [(provider: any LLMProviderProtocol, isActive: Bool)] {
        let configuredIds = configManager.listConfiguredProviders()
        return configuredIds.compactMap { providerId in
            guard let provider = providerInstances[providerId] else { return nil }
            return (provider, provider.id == activeProvider?.id)
        }
    }

    /// Get all available providers
    public func getAllProviders() -> [any LLMProviderProtocol] {
        Array(providerInstances.values)
    }

    // MARK: - Chat Methods with Fallback

    /// Send chat completion with automatic fallback
    public func chatCompletion(_ request: LLMChatRequest) async throws -> LLMChatResponse {
        guard let primaryProvider = activeProvider else {
            throw LLMManagerError.noActiveProvider
        }

        // Try primary provider
        do {
            return try await primaryProvider.chatCompletion(request)
        } catch {
            // Log primary failure
            print("Primary provider \(primaryProvider.id) failed: \(error)")

            // Try fallback providers
            for providerId in providerPriority {
                guard providerId != primaryProvider.id,
                      let fallbackProvider = providerInstances[providerId],
                      await fallbackProvider.isConfigured
                else {
                    continue
                }

                do {
                    print("Attempting fallback to \(fallbackProvider.id)")
                    return try await fallbackProvider.chatCompletion(request)
                } catch {
                    print("Fallback provider \(fallbackProvider.id) failed: \(error)")
                    continue
                }
            }

            // All providers failed, throw original error
            throw error
        }
    }

    /// Stream chat completion with automatic fallback
    public func streamChatCompletion(_ request: LLMChatRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let primaryProvider = activeProvider else {
                    continuation.finish(throwing: LLMManagerError.noActiveProvider)
                    return
                }

                // Try primary provider
                do {
                    for try await chunk in primaryProvider.streamChatCompletion(request) {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    print("Primary provider \(primaryProvider.id) streaming failed: \(error)")

                    // Try fallback providers
                    var fallbackSucceeded = false

                    for providerId in providerPriority {
                        guard providerId != primaryProvider.id,
                              let fallbackProvider = providerInstances[providerId],
                              await fallbackProvider.isConfigured
                        else {
                            continue
                        }

                        do {
                            print("Attempting streaming fallback to \(fallbackProvider.id)")
                            for try await chunk in fallbackProvider.streamChatCompletion(request) {
                                continuation.yield(chunk)
                            }
                            continuation.finish()
                            fallbackSucceeded = true
                            break
                        } catch {
                            print("Fallback provider \(fallbackProvider.id) streaming failed: \(error)")
                            continue
                        }
                    }

                    if !fallbackSucceeded {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }

    /// Generate embeddings with fallback
    public func generateEmbeddings(_ text: String) async throws -> [Float] {
        guard let primaryProvider = activeProvider else {
            throw LLMManagerError.noActiveProvider
        }

        // Check if primary supports embeddings
        guard primaryProvider.capabilities.supportsEmbeddings else {
            // Find a provider that supports embeddings
            for provider in providers where provider.capabilities.supportsEmbeddings {
                if await provider.isConfigured {
                    return try await provider.generateEmbeddings(text)
                }
            }
            throw LLMProviderError.embeddingsNotSupported
        }

        return try await primaryProvider.generateEmbeddings(text)
    }

    /// Get token count
    public func tokenCount(for text: String) async throws -> Int {
        guard let provider = activeProvider else {
            throw LLMManagerError.noActiveProvider
        }

        return try await provider.tokenCount(for: text)
    }
}

// MARK: - Manager Errors

public enum LLMManagerError: LocalizedError {
    case noActiveProvider
    case providerNotFound(String)
    case providerNotConfigured(String)

    public var errorDescription: String? {
        switch self {
        case .noActiveProvider:
            "No LLM provider is configured"
        case let .providerNotFound(id):
            "Provider '\(id)' not found"
        case let .providerNotConfigured(id):
            "Provider '\(id)' is not configured"
        }
    }
}

// MARK: - TCA Dependency

public extension DependencyValues {
    var llmManager: LLMManager {
        get { self[LLMManagerKey.self] }
        set { self[LLMManagerKey.self] = newValue }
    }
}

private enum LLMManagerKey: DependencyKey {
    static var liveValue: LLMManager {
        MainActor.assumeIsolated {
            LLMManager.shared
        }
    }
}

//
//  LLMServiceManager.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import ComposableArchitecture
import Foundation

/// Main service manager for LLM operations with fallback support
@MainActor
final class LLMServiceManager: ObservableObject {
    // MARK: - Properties

    static let shared = LLMServiceManager()

    /// Currently active provider adapter
    @Published private(set) var activeAdapter: LLMProviderProtocol?

    /// Available provider adapters
    private var adapters: [LLMProvider: LLMProviderProtocol] = [:]

    /// Configuration manager
    private let configurationManager = LLMConfigurationManager.shared

    /// Request queue for managing concurrent requests
    private let requestQueue = DispatchQueue(label: "com.aiko.llm.requests", attributes: .concurrent)

    /// Active request tracking
    private var activeRequests: Set<UUID> = []

    // MARK: - Initialization

    private init() {
        setupAdapters()
        observeConfigurationChanges()
    }

    // MARK: - Public Methods

    /// Send a request to the active LLM provider with automatic fallback
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - context: Conversation context
    ///   - options: Request options
    /// - Returns: The LLM response
    func sendRequest(
        prompt: String,
        context: ConversationContext? = nil,
        options: LLMRequestOptions = LLMRequestOptions()
    ) async throws -> LLMResponse {
        guard let adapter = activeAdapter else {
            throw LLMError.providerUnavailable(provider: .claude)
        }

        let requestId = UUID()
        activeRequests.insert(requestId)
        defer { activeRequests.remove(requestId) }

        do {
            return try await adapter.sendRequest(
                prompt: prompt,
                context: context,
                options: options
            )
        } catch {
            // Try fallback providers
            return try await sendRequestWithFallback(
                prompt: prompt,
                context: context,
                options: options,
                failedProvider: adapter.provider,
                originalError: error
            )
        }
    }

    /// Stream a response from the active LLM provider
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - context: Conversation context
    ///   - options: Request options
    /// - Returns: An async stream of response chunks
    func streamRequest(
        prompt: String,
        context: ConversationContext? = nil,
        options: LLMRequestOptions = LLMRequestOptions()
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        guard let adapter = activeAdapter else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMError.providerUnavailable(provider: .claude))
            }
        }

        return adapter.streamRequest(
            prompt: prompt,
            context: context,
            options: options
        )
    }

    /// Switch to a specific provider
    /// - Parameter provider: The provider to switch to
    func switchProvider(_ provider: LLMProvider) async throws {
        guard let config = configurationManager.configuredProviders[provider] else {
            throw LLMError.providerUnavailable(provider: provider)
        }

        // Validate API key exists
        guard configurationManager.getAPIKey(for: provider) != nil else {
            throw LLMError.noAPIKey(provider: provider)
        }

        // Create or get adapter
        if let adapter = adapters[provider] {
            activeAdapter = adapter
        } else {
            let adapter = createAdapter(for: provider, config: config)
            adapters[provider] = adapter
            activeAdapter = adapter
        }

        // Update active configuration
        try configurationManager.setActiveProvider(provider)
    }

    /// Get available providers
    /// - Returns: List of configured providers
    func getAvailableProviders() -> [LLMProvider] {
        configurationManager.getAvailableProviders()
    }

    /// Validate all configured providers
    /// - Returns: Dictionary of provider validation results
    func validateProviders() async -> [LLMProvider: Bool] {
        var results: [LLMProvider: Bool] = [:]

        for provider in getAvailableProviders() {
            if let adapter = adapters[provider] ?? createAdapterIfNeeded(for: provider) {
                results[provider] = await adapter.validateConfiguration()
            } else {
                results[provider] = false
            }
        }

        return results
    }

    /// Cancel all active requests
    func cancelAllRequests() {
        activeRequests.removeAll()
        adapters.values.forEach { $0.cancelAllRequests() }
    }

    /// Count tokens for text using the active provider
    /// - Parameter text: The text to count tokens for
    /// - Returns: Approximate token count
    func countTokens(for text: String) -> Int {
        activeAdapter?.countTokens(for: text) ?? text.count / 4
    }

    // MARK: - Private Methods

    private func setupAdapters() {
        // Initialize with active provider if available
        if let activeConfig = configurationManager.activeProviderConfig {
            let adapter = createAdapter(for: activeConfig.provider, config: activeConfig)
            adapters[activeConfig.provider] = adapter
            activeAdapter = adapter
        }
    }

    private func observeConfigurationChanges() {
        // Observe configuration changes
        configurationManager.$activeProviderConfig
            .sink { [weak self] config in
                guard let self, let config else { return }
                Task {
                    try? await self.switchProvider(config.provider)
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func createAdapter(for provider: LLMProvider, config: LLMProviderConfig) -> LLMProviderProtocol {
        switch provider {
        case .claude:
            ClaudeAdapter(provider: provider, configuration: config)
        case .openAI, .chatGPT:
            OpenAIAdapter(provider: provider, configuration: config)
        case .gemini:
            GeminiAdapter(provider: provider, configuration: config)
        case .custom:
            // For custom providers, use OpenAI adapter as base
            OpenAIAdapter(provider: provider, configuration: config)
        }
    }

    private func createAdapterIfNeeded(for provider: LLMProvider) -> LLMProviderProtocol? {
        guard let config = configurationManager.configuredProviders[provider] else {
            return nil
        }

        let adapter = createAdapter(for: provider, config: config)
        adapters[provider] = adapter
        return adapter
    }

    private func sendRequestWithFallback(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions,
        failedProvider: LLMProvider,
        originalError: Error
    ) async throws -> LLMResponse {
        var errors: [LLMProvider: Error] = [failedProvider: originalError]

        // Get fallback providers based on priority
        let priority = configurationManager.providerPriority
        let availableProviders = getAvailableProviders()
        let fallbackProviders = priority.providers.filter {
            availableProviders.contains($0) && $0 != failedProvider
        }

        // Try each fallback provider
        for provider in fallbackProviders {
            guard let adapter = adapters[provider] ?? createAdapterIfNeeded(for: provider) else {
                errors[provider] = LLMError.providerUnavailable(provider: provider)
                continue
            }

            do {
                let response = try await adapter.sendRequest(
                    prompt: prompt,
                    context: context,
                    options: options
                )

                // Update active adapter for future requests
                activeAdapter = adapter

                return response
            } catch {
                errors[provider] = error
            }
        }

        // All providers failed
        throw LLMError.allProvidersFailed(errors)
    }
}

// MARK: - TCA Integration

/// LLM service client for The Composable Architecture
struct LLMServiceClient {
    var sendRequest: @Sendable (String, ConversationContext?, LLMRequestOptions) async throws -> LLMResponse
    var streamRequest: @Sendable (String, ConversationContext?, LLMRequestOptions) -> AsyncThrowingStream<LLMStreamChunk, Error>
    var switchProvider: @Sendable (LLMProvider) async throws -> Void
    var getAvailableProviders: @Sendable () async -> [LLMProvider]
    var validateProviders: @Sendable () async -> [LLMProvider: Bool]
    var countTokens: @Sendable (String) async -> Int
    var cancelAllRequests: @Sendable () async -> Void
}

extension LLMServiceClient: DependencyKey {
    static let liveValue = Self(
        sendRequest: { prompt, context, options in
            try await LLMServiceManager.shared.sendRequest(
                prompt: prompt,
                context: context,
                options: options
            )
        },
        streamRequest: { prompt, context, options in
            LLMServiceManager.shared.streamRequest(
                prompt: prompt,
                context: context,
                options: options
            )
        },
        switchProvider: { provider in
            try await LLMServiceManager.shared.switchProvider(provider)
        },
        getAvailableProviders: {
            await MainActor.run {
                LLMServiceManager.shared.getAvailableProviders()
            }
        },
        validateProviders: {
            await LLMServiceManager.shared.validateProviders()
        },
        countTokens: { text in
            await MainActor.run {
                LLMServiceManager.shared.countTokens(for: text)
            }
        },
        cancelAllRequests: {
            await MainActor.run {
                LLMServiceManager.shared.cancelAllRequests()
            }
        }
    )
}

extension DependencyValues {
    var llmService: LLMServiceClient {
        get { self[LLMServiceClient.self] }
        set { self[LLMServiceClient.self] = newValue }
    }
}

// MARK: - Combine Support

import Combine

extension LLMServiceManager {
    /// Publisher for LLM responses
    func responsePublisher(
        for prompt: String,
        context: ConversationContext? = nil,
        options: LLMRequestOptions = LLMRequestOptions()
    ) -> AnyPublisher<LLMResponse, Error> {
        Future { promise in
            Task {
                do {
                    let response = try await sendRequest(
                        prompt: prompt,
                        context: context,
                        options: options
                    )
                    promise(.success(response))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

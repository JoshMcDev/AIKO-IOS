//
//  LLMProvider.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation

/// Represents supported LLM providers
enum LLMProvider: String, CaseIterable, Identifiable, Codable {
    case claude
    case openAI = "openai"
    case chatGPT = "chatgpt"
    case gemini
    case custom

    var id: String { rawValue }

    /// Human-readable name for the provider
    var name: String {
        switch self {
        case .claude:
            "Claude (Anthropic)"
        case .openAI:
            "OpenAI"
        case .chatGPT:
            "ChatGPT"
        case .gemini:
            "Google Gemini"
        case .custom:
            "Custom Provider"
        }
    }

    /// Icon name for the provider (SF Symbols)
    var iconName: String {
        switch self {
        case .claude:
            "brain.head.profile"
        case .openAI, .chatGPT:
            "cpu"
        case .gemini:
            "sparkles"
        case .custom:
            "server.rack"
        }
    }

    /// Base URL for the provider's API
    var baseURL: String {
        switch self {
        case .claude:
            "https://api.anthropic.com"
        case .openAI, .chatGPT:
            "https://api.openai.com"
        case .gemini:
            "https://generativelanguage.googleapis.com"
        case .custom:
            "" // User-defined
        }
    }

    /// Available models for each provider
    var availableModels: [LLMModel] {
        switch self {
        case .claude:
            [
                LLMModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", contextWindow: 200_000),
                LLMModel(id: "claude-3-sonnet-20240229", name: "Claude 3 Sonnet", contextWindow: 200_000),
                LLMModel(id: "claude-3-haiku-20240307", name: "Claude 3 Haiku", contextWindow: 200_000),
                LLMModel(id: "claude-2.1", name: "Claude 2.1", contextWindow: 200_000),
                LLMModel(id: "claude-2.0", name: "Claude 2.0", contextWindow: 100_000),
            ]

        case .openAI, .chatGPT:
            [
                LLMModel(id: "gpt-4-turbo-preview", name: "GPT-4 Turbo", contextWindow: 128_000),
                LLMModel(id: "gpt-4", name: "GPT-4", contextWindow: 8192),
                LLMModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", contextWindow: 16385),
                LLMModel(id: "gpt-3.5-turbo-16k", name: "GPT-3.5 Turbo 16K", contextWindow: 16385),
            ]

        case .gemini:
            [
                LLMModel(id: "gemini-pro", name: "Gemini Pro", contextWindow: 32768),
                LLMModel(id: "gemini-pro-vision", name: "Gemini Pro Vision", contextWindow: 32768),
                LLMModel(id: "gemini-ultra", name: "Gemini Ultra", contextWindow: 32768),
            ]

        case .custom:
            [] // User-defined models
        }
    }

    /// Default model for each provider
    var defaultModel: LLMModel? {
        availableModels.first
    }

    /// Provider-specific features and capabilities
    var capabilities: LLMCapabilities {
        switch self {
        case .claude:
            LLMCapabilities(
                streaming: true,
                functionCalling: true,
                visionSupport: true,
                codeExecution: false,
                maxTokensPerRequest: 200_000,
                supportedFileTypes: ["txt", "pdf", "docx", "md"],
                rateLimit: LLMRateLimit(requestsPerMinute: 60, tokensPerMinute: 100_000)
            )

        case .openAI, .chatGPT:
            LLMCapabilities(
                streaming: true,
                functionCalling: true,
                visionSupport: true,
                codeExecution: true,
                maxTokensPerRequest: 128_000,
                supportedFileTypes: ["txt", "pdf", "docx", "md", "jpg", "png"],
                rateLimit: LLMRateLimit(requestsPerMinute: 60, tokensPerMinute: 90000)
            )

        case .gemini:
            LLMCapabilities(
                streaming: true,
                functionCalling: true,
                visionSupport: true,
                codeExecution: false,
                maxTokensPerRequest: 32768,
                supportedFileTypes: ["txt", "pdf", "jpg", "png", "gif"],
                rateLimit: LLMRateLimit(requestsPerMinute: 60, tokensPerMinute: 120_000)
            )

        case .custom:
            LLMCapabilities(
                streaming: false,
                functionCalling: false,
                visionSupport: false,
                codeExecution: false,
                maxTokensPerRequest: 4096,
                supportedFileTypes: ["txt"],
                rateLimit: LLMRateLimit(requestsPerMinute: 10, tokensPerMinute: 10000)
            )
        }
    }
}

/// Represents an LLM model configuration
struct LLMModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let contextWindow: Int
    var customEndpoint: String?

    /// Estimated cost per 1K tokens (in cents)
    var costPer1KTokens: (input: Double, output: Double) {
        // These are example costs - should be updated with actual pricing
        switch id {
        case "claude-3-opus-20240229":
            (input: 1.5, output: 7.5)
        case "claude-3-sonnet-20240229":
            (input: 0.3, output: 1.5)
        case "claude-3-haiku-20240307":
            (input: 0.025, output: 0.125)
        case "gpt-4-turbo-preview", "gpt-4":
            (input: 1.0, output: 3.0)
        case "gpt-3.5-turbo", "gpt-3.5-turbo-16k":
            (input: 0.05, output: 0.15)
        case "gemini-pro":
            (input: 0.025, output: 0.05)
        case "gemini-ultra":
            (input: 0.1, output: 0.3)
        default:
            (input: 0.01, output: 0.03)
        }
    }
}

/// Capabilities of an LLM provider
struct LLMCapabilities: Codable, Equatable {
    let streaming: Bool
    let functionCalling: Bool
    let visionSupport: Bool
    let codeExecution: Bool
    let maxTokensPerRequest: Int
    let supportedFileTypes: [String]
    let rateLimit: LLMRateLimit
}

/// Rate limiting configuration
struct LLMRateLimit: Codable, Equatable {
    let requestsPerMinute: Int
    let tokensPerMinute: Int
}

/// Provider configuration including custom settings
struct LLMProviderConfig: Codable, Equatable {
    let provider: LLMProvider
    let model: LLMModel
    let apiKey: String? // Not stored directly, reference to keychain
    let customEndpoint: String?
    let customHeaders: [String: String]?
    let temperature: Double
    let maxTokens: Int?
    let topP: Double?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    let stopSequences: [String]?

    init(
        provider: LLMProvider,
        model: LLMModel? = nil,
        apiKey: String? = nil,
        customEndpoint: String? = nil,
        customHeaders: [String: String]? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stopSequences: [String]? = nil
    ) {
        self.provider = provider
        self.model = model ?? provider.defaultModel ?? LLMModel(id: "default", name: "Default", contextWindow: 4096)
        self.apiKey = apiKey
        self.customEndpoint = customEndpoint
        self.customHeaders = customHeaders
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.stopSequences = stopSequences
    }
}

/// Priority order for provider fallback
struct LLMProviderPriority: Codable, Equatable {
    let providers: [LLMProvider]
    let fallbackBehavior: FallbackBehavior

    enum FallbackBehavior: String, Codable {
        case sequential // Try providers in order
        case loadBalanced // Distribute across available providers
        case costOptimized // Choose cheapest available provider
        case performanceOptimized // Choose fastest available provider
    }
}

/// Error types specific to LLM operations
enum LLMError: LocalizedError {
    case noAPIKey(provider: LLMProvider)
    case invalidAPIKey(provider: LLMProvider)
    case rateLimitExceeded(provider: LLMProvider)
    case modelNotAvailable(model: String, provider: LLMProvider)
    case providerUnavailable(provider: LLMProvider)
    case networkError(Error)
    case invalidResponse(String)
    case contextWindowExceeded(limit: Int, actual: Int)
    case allProvidersFailed([LLMProvider: Error])

    var errorDescription: String? {
        switch self {
        case let .noAPIKey(provider):
            return "No API key configured for \(provider.name)"
        case let .invalidAPIKey(provider):
            return "Invalid API key for \(provider.name)"
        case let .rateLimitExceeded(provider):
            return "Rate limit exceeded for \(provider.name)"
        case let .modelNotAvailable(model, provider):
            return "Model '\(model)' is not available for \(provider.name)"
        case let .providerUnavailable(provider):
            return "\(provider.name) is currently unavailable"
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case let .invalidResponse(message):
            return "Invalid response: \(message)"
        case let .contextWindowExceeded(limit, actual):
            return "Context window exceeded: \(actual) tokens (limit: \(limit))"
        case let .allProvidersFailed(failures):
            let failureMessages = failures.map { "\($0.key.name): \($0.value.localizedDescription)" }
            return "All providers failed:\n" + failureMessages.joined(separator: "\n")
        }
    }
}

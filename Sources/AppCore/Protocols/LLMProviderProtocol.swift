import Foundation
import ComposableArchitecture

// MARK: - LLM Provider Protocol

/// Defines the interface for any LLM provider integration
public protocol LLMProviderProtocol: Sendable {
    /// Unique identifier for the provider
    var id: String { get }
    
    /// Human-readable name of the provider
    var name: String { get }
    
    /// Provider capabilities
    var capabilities: LLMProviderCapabilities { get }
    
    /// Check if the provider is configured and ready to use
    var isConfigured: Bool { get async }
    
    /// Validate API key or credentials
    func validateCredentials() async throws -> Bool
    
    /// Send a chat completion request
    func chatCompletion(_ request: LLMChatRequest) async throws -> LLMChatResponse
    
    /// Stream a chat completion response
    func streamChatCompletion(_ request: LLMChatRequest) -> AsyncThrowingStream<LLMStreamChunk, Error>
    
    /// Generate embeddings for text
    func generateEmbeddings(_ text: String) async throws -> [Float]
    
    /// Get token count for text
    func tokenCount(for text: String) async throws -> Int
    
    /// Get provider-specific settings
    func getSettings() -> LLMProviderSettings
}

// MARK: - Supporting Types

/// LLM Provider enum
public enum LLMProvider: String, CaseIterable, Identifiable, Codable, Sendable {
    case claude = "claude"
    case openAI = "openai"
    case chatGPT = "chatgpt"
    case gemini = "gemini"
    case azureOpenAI = "azure-openai"
    case local = "local"
    case custom = "custom"
    
    public var id: String { rawValue }
    
    /// Human-readable name for the provider
    public var name: String {
        switch self {
        case .claude:
            return "Claude (Anthropic)"
        case .openAI:
            return "OpenAI"
        case .chatGPT:
            return "ChatGPT"
        case .gemini:
            return "Google Gemini"
        case .azureOpenAI:
            return "Azure OpenAI"
        case .local:
            return "Local Model"
        case .custom:
            return "Custom Provider"
        }
    }
}

/// Capabilities that a provider supports
public struct LLMProviderCapabilities: Equatable, Sendable {
    public let supportsStreaming: Bool
    public let supportsEmbeddings: Bool
    public let supportsVision: Bool
    public let supportsFunctionCalling: Bool
    public let maxTokens: Int
    public let maxContextLength: Int
    public let supportedModels: [LLMModel]
    
    public init(
        supportsStreaming: Bool = true,
        supportsEmbeddings: Bool = false,
        supportsVision: Bool = false,
        supportsFunctionCalling: Bool = false,
        maxTokens: Int = 4096,
        maxContextLength: Int = 128000,
        supportedModels: [LLMModel] = []
    ) {
        self.supportsStreaming = supportsStreaming
        self.supportsEmbeddings = supportsEmbeddings
        self.supportsVision = supportsVision
        self.supportsFunctionCalling = supportsFunctionCalling
        self.maxTokens = maxTokens
        self.maxContextLength = maxContextLength
        self.supportedModels = supportedModels
    }
}

/// Model information
public struct LLMModel: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let contextLength: Int
    public let pricing: ModelPricing?
    
    public init(
        id: String,
        name: String,
        description: String,
        contextLength: Int,
        pricing: ModelPricing? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.contextLength = contextLength
        self.pricing = pricing
    }
}

/// Model pricing information
public struct ModelPricing: Equatable, Sendable {
    public let inputPricePerMillion: Decimal
    public let outputPricePerMillion: Decimal
    public let currency: String
    
    public init(
        inputPricePerMillion: Decimal,
        outputPricePerMillion: Decimal,
        currency: String = "USD"
    ) {
        self.inputPricePerMillion = inputPricePerMillion
        self.outputPricePerMillion = outputPricePerMillion
        self.currency = currency
    }
}

/// Chat request structure
public struct LLMChatRequest: Equatable, Sendable {
    public let messages: [LLMMessage]
    public let model: String
    public let temperature: Double
    public let maxTokens: Int?
    public let systemPrompt: String?
    public let functions: [LLMFunction]?
    public let responseFormat: ResponseFormat?
    
    public init(
        messages: [LLMMessage],
        model: String,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        systemPrompt: String? = nil,
        functions: [LLMFunction]? = nil,
        responseFormat: ResponseFormat? = nil
    ) {
        self.messages = messages
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.systemPrompt = systemPrompt
        self.functions = functions
        self.responseFormat = responseFormat
    }
}

/// Message structure
public struct LLMMessage: Equatable, Sendable, Codable {
    public let role: MessageRole
    public let content: String
    public let name: String?
    public let functionCall: FunctionCall?
    
    public init(
        role: MessageRole,
        content: String,
        name: String? = nil,
        functionCall: FunctionCall? = nil
    ) {
        self.role = role
        self.content = content
        self.name = name
        self.functionCall = functionCall
    }
}

/// Message role
public enum MessageRole: String, Equatable, Sendable, Codable {
    case system
    case user
    case assistant
    case function
}

/// Function definition for function calling
public struct LLMFunction: Equatable {
    public let name: String
    public let description: String
    public let parameters: [String: Any]
    
    public init(name: String, description: String, parameters: [String: Any]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    public static func == (lhs: LLMFunction, rhs: LLMFunction) -> Bool {
        lhs.name == rhs.name && lhs.description == rhs.description
    }
}

// Mark as @unchecked Sendable since parameters are immutable and only used for JSON serialization
extension LLMFunction: @unchecked Sendable {}

/// Function call structure
public struct FunctionCall: Equatable, Sendable, Codable {
    public let name: String
    public let arguments: String
    
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}

/// Response format specification
public enum ResponseFormat: Equatable, Sendable {
    case text
    case json
    case jsonSchema(String)
}

/// Chat response structure
public struct LLMChatResponse: Equatable, Sendable {
    public let id: String
    public let model: String
    public let message: LLMMessage
    public let usage: TokenUsage
    public let finishReason: FinishReason
    
    public init(
        id: String,
        model: String,
        message: LLMMessage,
        usage: TokenUsage,
        finishReason: FinishReason
    ) {
        self.id = id
        self.model = model
        self.message = message
        self.usage = usage
        self.finishReason = finishReason
    }
}

/// Stream chunk for streaming responses
public struct LLMStreamChunk: Equatable, Sendable {
    public let delta: String
    public let role: MessageRole?
    public let finishReason: FinishReason?
    
    public init(
        delta: String,
        role: MessageRole? = nil,
        finishReason: FinishReason? = nil
    ) {
        self.delta = delta
        self.role = role
        self.finishReason = finishReason
    }
}

/// Token usage information
public struct TokenUsage: Equatable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    public init(promptTokens: Int, completionTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
    }
}

/// Finish reason for completion
public enum FinishReason: String, Equatable, Sendable {
    case stop
    case length
    case contentFilter = "content_filter"
    case functionCall = "function_call"
}

/// Provider-specific settings
public struct LLMProviderSettings: Equatable, Sendable {
    public let apiEndpoint: String?
    public let apiVersion: String?
    public let organizationId: String?
    public let customHeaders: [String: String]
    public let timeout: TimeInterval
    public let retryCount: Int
    
    public init(
        apiEndpoint: String? = nil,
        apiVersion: String? = nil,
        organizationId: String? = nil,
        customHeaders: [String: String] = [:],
        timeout: TimeInterval = 30,
        retryCount: Int = 3
    ) {
        self.apiEndpoint = apiEndpoint
        self.apiVersion = apiVersion
        self.organizationId = organizationId
        self.customHeaders = customHeaders
        self.timeout = timeout
        self.retryCount = retryCount
    }
}

// MARK: - Provider Configuration

/// Configuration for LLM provider
public struct LLMProviderConfig: Codable, Equatable, Sendable {
    public let provider: String
    public let providerId: String // Add providerId for compatibility
    public let model: String
    public let apiKey: String? // Not stored directly, reference to keychain
    public let organizationId: String? // Organization ID for providers that support it
    public let customEndpoint: String?
    public let customHeaders: [String: String]?
    public let temperature: Double
    public let maxTokens: Int?
    public let topP: Double?
    public let frequencyPenalty: Double?
    public let presencePenalty: Double?
    public let stopSequences: [String]?
    
    public init(
        provider: String,
        providerId: String? = nil,
        model: String,
        apiKey: String? = nil,
        organizationId: String? = nil,
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
        self.providerId = providerId ?? provider // Use provider as default providerId
        self.model = model
        self.apiKey = apiKey
        self.organizationId = organizationId
        self.customEndpoint = customEndpoint
        self.customHeaders = customHeaders
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.stopSequences = stopSequences
    }
    
    // Add convenience initializer that takes LLMProvider enum
    public init(
        provider: LLMProvider,
        model: String,
        apiKey: String? = nil,
        organizationId: String? = nil,
        customEndpoint: String? = nil,
        customHeaders: [String: String]? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stopSequences: [String]? = nil
    ) {
        self.init(
            provider: provider.rawValue,
            providerId: provider.id,
            model: model,
            apiKey: apiKey,
            organizationId: organizationId,
            customEndpoint: customEndpoint,
            customHeaders: customHeaders,
            temperature: temperature,
            maxTokens: maxTokens,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            stopSequences: stopSequences
        )
    }
}

// MARK: - Provider Priority

/// Defines provider priority for fallback behavior
public struct LLMProviderPriority: Codable, Equatable, Sendable {
    public let providers: [LLMProvider]
    public let fallbackBehavior: FallbackBehavior
    
    public init(providers: [LLMProvider], fallbackBehavior: FallbackBehavior = .sequential) {
        self.providers = providers
        self.fallbackBehavior = fallbackBehavior
    }
    
    public enum FallbackBehavior: String, Codable, Sendable {
        case sequential // Try providers in order
        case random // Try providers randomly
        case loadBalanced // Distribute load across providers
    }
}

// MARK: - LLM Error

/// Common errors for LLM operations
public enum LLMError: LocalizedError {
    case invalidAPIKey(provider: LLMProvider)
    case providerUnavailable(provider: LLMProvider)
    case noAPIKey(provider: LLMProvider)
    case configurationError(String)
    case keychainError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey(let provider):
            return "Invalid API key format for \(provider.name)"
        case .providerUnavailable(let provider):
            return "Provider \(provider.name) is not available"
        case .noAPIKey(let provider):
            return "No API key found for \(provider.name)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        }
    }
}

// MARK: - Provider Errors

public enum LLMProviderError: LocalizedError {
    case notConfigured
    case invalidCredentials
    case rateLimitExceeded
    case contextLengthExceeded
    case modelNotSupported(String)
    case networkError(String)
    case invalidResponse(String)
    case streamingNotSupported
    case functionCallingNotSupported
    case embeddingsNotSupported
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "LLM provider is not configured"
        case .invalidCredentials:
            return "Invalid API credentials"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .contextLengthExceeded:
            return "Context length exceeded"
        case .modelNotSupported(let model):
            return "Model '\(model)' is not supported"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .streamingNotSupported:
            return "Streaming is not supported by this provider"
        case .functionCallingNotSupported:
            return "Function calling is not supported by this provider"
        case .embeddingsNotSupported:
            return "Embeddings are not supported by this provider"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}
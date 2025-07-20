import Foundation

/// API-agnostic AI provider protocol
/// This allows the application to work with any LLM provider
public protocol AIProvider: Sendable {
    func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse
    func streamComplete(_ request: AICompletionRequest) async throws -> AsyncThrowingStream<AIStreamEvent, Error>
}

/// API-agnostic completion request
public struct AICompletionRequest: Sendable {
    public let messages: [AIMessage]
    public let model: String
    public let maxTokens: Int
    public let temperature: Double?
    public let systemPrompt: String?
    public let stopSequences: [String]?

    public init(
        messages: [AIMessage],
        model: String = "claude-sonnet-4-20250514",
        maxTokens: Int = 4096,
        temperature: Double? = nil,
        systemPrompt: String? = nil,
        stopSequences: [String]? = nil
    ) {
        self.messages = messages
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.systemPrompt = systemPrompt
        self.stopSequences = stopSequences
    }
}

/// API-agnostic message
public struct AIMessage: Sendable {
    public enum Role: String, Sendable {
        case user
        case assistant
        case system
    }

    public let role: Role
    public let content: String

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }

    public static func user(_ content: String) -> AIMessage {
        AIMessage(role: .user, content: content)
    }

    public static func assistant(_ content: String) -> AIMessage {
        AIMessage(role: .assistant, content: content)
    }

    public static func system(_ content: String) -> AIMessage {
        AIMessage(role: .system, content: content)
    }
}

/// API-agnostic completion response
public struct AICompletionResponse: Sendable {
    public let content: String
    public let model: String
    public let usage: AIUsage?

    public init(content: String, model: String, usage: AIUsage? = nil) {
        self.content = content
        self.model = model
        self.usage = usage
    }
}

/// API-agnostic usage information
public struct AIUsage: Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    public init(promptTokens: Int, completionTokens: Int, totalTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
    }
}

/// API-agnostic stream event
public enum AIStreamEvent: Sendable {
    case text(String)
    case error(Error)
    case done
}

/// Configuration for AI providers
public struct AIProviderConfig: Sendable {
    public let apiKey: String
    public let baseURL: String?
    public let additionalHeaders: [String: String]?

    public init(apiKey: String, baseURL: String? = nil, additionalHeaders: [String: String]? = nil) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.additionalHeaders = additionalHeaders
    }
}

/// Factory for creating AI providers
public actor AIProviderFactory {
    private static let shared = AIProviderFactory()
    private var providers: [String: any AIProvider] = [:]

    private init() {}

    /// Register a provider implementation
    public static func register(_ provider: any AIProvider, for name: String) async {
        await shared.registerProvider(provider, for: name)
    }

    /// Get a provider by name
    public static func provider(named name: String) async -> (any AIProvider)? {
        await shared.getProvider(named: name)
    }

    /// Get the default provider
    public static func defaultProvider() async -> (any AIProvider)? {
        await shared.getDefaultProvider()
    }

    // Actor-isolated methods
    private func registerProvider(_ provider: any AIProvider, for name: String) {
        providers[name] = provider
    }

    private func getProvider(named name: String) -> (any AIProvider)? {
        providers[name]
    }

    private func getDefaultProvider() -> (any AIProvider)? {
        providers["default"] ?? providers.values.first
    }
}

import Foundation

// Migration helpers to ease the transition from direct SwiftAnthropic usage
// to the API-agnostic AIProvider interface

// MARK: - Factory Migration

/// Drop-in replacement for AnthropicServiceFactory
/// This provides a migration path from SwiftAnthropic to the API-agnostic interface
public enum AnthropicServiceFactory {
    /// Creates an AIProvider configured for Anthropic
    /// This allows existing code to work with minimal changes
    public static func service(apiKey: String, betaHeaders: [String]? = nil) -> any AIProvider {
        let config = AIProviderConfig(
            apiKey: apiKey,
            additionalHeaders: betaHeaders?.reduce(into: [:]) { dict, header in
                let parts = header.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    dict[String(parts[0]).trimmingCharacters(in: .whitespaces)] = String(parts[1]).trimmingCharacters(in: .whitespaces)
                }
            }
        )
        return AnthropicProvider(config: config)
    }
}

// MARK: - Common Patterns

/// Namespace for common AI completion patterns
public enum AIPatterns {
    /// Simple text completion
    public static func textCompletion(
        prompt: String,
        model: String = "claude-sonnet-4-20250514",
        systemPrompt: String? = nil,
        maxTokens: Int = 4096,
        temperature: Double? = nil
    ) -> AICompletionRequest {
        AICompletionRequest(
            messages: [.user(prompt)],
            model: model,
            maxTokens: maxTokens,
            temperature: temperature,
            systemPrompt: systemPrompt
        )
    }

    /// Multi-turn conversation
    public static func conversation(
        messages: [(role: AIMessage.Role, content: String)],
        model: String = "claude-sonnet-4-20250514",
        systemPrompt: String? = nil,
        maxTokens: Int = 4096
    ) -> AICompletionRequest {
        let messageParams = messages.map { msg in
            AIMessage(role: msg.role, content: msg.content)
        }

        return AICompletionRequest(
            messages: messageParams,
            model: model,
            maxTokens: maxTokens,
            systemPrompt: systemPrompt
        )
    }
}

// MARK: - Error Handling

public enum AIProviderError: Error, LocalizedError {
    case noTextContent
    case apiKeyNotSet
    case invalidResponse(String)
    case providerNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .noTextContent:
            "No text content in response"
        case .apiKeyNotSet:
            "API key not set"
        case let .invalidResponse(details):
            "Invalid response: \(details)"
        case let .providerNotFound(name):
            "AI provider '\(name)' not found"
        }
    }
}

// MARK: - Convenience Extensions

public extension AICompletionRequest {
    /// Create a simple single-message request
    static func simple(prompt: String, model: String = "claude-sonnet-4-20250514") -> AICompletionRequest {
        AICompletionRequest(
            messages: [.user(prompt)],
            model: model
        )
    }
}

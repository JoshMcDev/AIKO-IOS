import Foundation
@preconcurrency import SwiftAnthropic

/// Anthropic implementation of the API-agnostic AIProvider protocol
public actor AnthropicProvider: AIProvider {
    private let client: any AnthropicService

    public init(config: AIProviderConfig) {
        client = SwiftAnthropic.AnthropicServiceFactory.service(
            apiKey: config.apiKey,
            betaHeaders: config.additionalHeaders?.map { "\($0.key): \($0.value)" }
        )
    }

    public func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
        // Convert API-agnostic request to Anthropic-specific format
        let messages = request.messages.map { msg in
            MessageParameter.Message(
                role: MessageParameter.Message.Role(rawValue: msg.role.rawValue) ?? .user,
                content: .text(msg.content)
            )
        }

        let parameters = MessageParameter(
            model: .other(request.model),
            messages: messages,
            maxTokens: request.maxTokens,
            system: request.systemPrompt.map { .text($0) },
            metadata: nil,
            stopSequences: request.stopSequences,
            stream: false,
            temperature: request.temperature,
            topK: nil,
            topP: nil,
            tools: nil,
            toolChoice: nil
        )

        let response = try await client.createMessage(parameters)

        // Extract text content from response
        let content = response.content.compactMap { content in
            switch content {
            case let .text(text, _):
                text
            default:
                nil
            }
        }.joined(separator: "\n")

        let usage = AIUsage(
            promptTokens: response.usage.inputTokens ?? 0,
            completionTokens: response.usage.outputTokens,
            totalTokens: (response.usage.inputTokens ?? 0) + response.usage.outputTokens
        )

        return AICompletionResponse(
            content: content,
            model: response.model ?? "unknown",
            usage: usage
        )
    }

    public func streamComplete(_ request: AICompletionRequest) async throws -> AsyncThrowingStream<AIStreamEvent, Error> {
        // For now, we'll implement streaming as a single response
        // This can be enhanced later when we understand the SwiftAnthropic streaming API better
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await self.complete(request)
                    continuation.yield(.text(response.content))
                    continuation.yield(.done)
                    continuation.finish()
                } catch {
                    continuation.yield(.error(error))
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Anthropic-specific types (for migration only)

public typealias MessageParameter = SwiftAnthropic.MessageParameter
public typealias MessageResponse = SwiftAnthropic.MessageResponse

// MARK: - Registration

public extension AIProviderFactory {
    /// Register Anthropic as the default provider
    static func registerAnthropic(apiKey: String) async {
        let config = AIProviderConfig(apiKey: apiKey)
        let provider = AnthropicProvider(config: config)
        await register(provider, for: "anthropic")
        await register(provider, for: "default")
    }
}

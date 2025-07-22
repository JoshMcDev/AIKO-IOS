//
//  ClaudeAdapter.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation

/// Claude API adapter implementation
final class ClaudeAdapter: LLMProviderAdapter {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    override init(provider: LLMProvider = .claude, configuration: LLMProviderConfig) {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)

        super.init(provider: provider, configuration: configuration)

        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - LLMProviderProtocol

    override func sendRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) async throws -> LLMResponse {
        guard let apiKey = await getAPIKey() else {
            throw LLMError.noAPIKey(provider: provider)
        }

        let mergedOptions = options.merged(with: configuration)
        let requestBody = try buildRequestBody(
            prompt: prompt,
            context: context,
            options: mergedOptions
        )

        guard let url = URL(string: "\(getBaseURL())/v1/messages") else {
            throw LLMError.invalidResponse("Invalid API URL configuration")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(requestBody)
        request.allHTTPHeaderFields = buildClaudeHeaders(apiKey: apiKey)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200:
            let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
            return claudeResponse.toLLMResponse()

        case 429:
            throw LLMError.rateLimitExceeded(provider: provider)

        case 401:
            throw LLMError.invalidAPIKey(provider: provider)

        default:
            if let errorResponse = try? decoder.decode(ClaudeErrorResponse.self, from: data) {
                throw LLMError.invalidResponse(errorResponse.error.message)
            }
            throw LLMError.networkError(URLError(.badServerResponse))
        }
    }

    override func streamRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let apiKey = await getAPIKey() else {
                        throw LLMError.noAPIKey(provider: provider)
                    }

                    let mergedOptions = options.merged(with: configuration)
                    var requestBody = try buildRequestBody(
                        prompt: prompt,
                        context: context,
                        options: mergedOptions
                    )
                    requestBody.stream = true

                    guard let url = URL(string: "\(getBaseURL())/v1/messages") else {
                        throw LLMError.invalidResponse("Invalid API URL configuration")
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = try encoder.encode(requestBody)
                    request.allHTTPHeaderFields = buildClaudeHeaders(apiKey: apiKey)

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200
                    else {
                        throw LLMError.networkError(URLError(.badServerResponse))
                    }

                    var buffer = ""

                    for try await byte in bytes {
                        buffer.append(Character(UnicodeScalar(byte)))

                        // Process complete SSE events
                        while let eventRange = buffer.range(of: "\n\n") {
                            let event = String(buffer[..<eventRange.lowerBound])
                            buffer.removeSubrange(..<eventRange.upperBound)

                            if let chunk = parseSSEEvent(event) {
                                continuation.yield(chunk)
                            }
                        }
                    }

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }

            trackTask(task)

            continuation.onTermination = { _ in
                task.cancel()
                self.removeTask(task)
            }
        }
    }

    override func countTokens(for text: String) -> Int {
        // Claude uses a similar tokenization to GPT models
        // More accurate counting would require the actual tokenizer
        let words = text.split(separator: " ").count
        let characters = text.count

        // Rough approximation: average of word count * 1.3 and character count / 4
        return (Int(Double(words) * 1.3) + (characters / 4)) / 2
    }

    // MARK: - Private Methods

    private func buildClaudeHeaders(apiKey: String) -> [String: String] {
        var headers = buildHeaders(apiKey: apiKey)
        headers["x-api-key"] = apiKey
        headers["anthropic-version"] = "2023-06-01"
        return headers
    }

    private func buildRequestBody(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) throws -> ClaudeRequestBody {
        var messages: [ClaudeMessage] = []

        // Add context messages
        if let context {
            // Add system prompt if available
            if let systemPrompt = context.systemPrompt {
                messages.append(ClaudeMessage(
                    role: "assistant",
                    content: "System: \(systemPrompt)"
                ))
            }

            // Add conversation history
            for message in context.messages {
                messages.append(ClaudeMessage(
                    role: message.role == .user ? "user" : "assistant",
                    content: message.content
                ))
            }
        }

        // Add current prompt
        messages.append(ClaudeMessage(role: "user", content: prompt))

        return ClaudeRequestBody(
            model: configuration.model.id,
            messages: messages,
            system: context?.systemPrompt,
            max_tokens: options.maxTokens ?? 4096,
            temperature: options.temperature,
            top_p: options.topP,
            top_k: options.topK,
            stop_sequences: options.stopSequences,
            stream: false
        )
    }

    private func parseSSEEvent(_ event: String) -> LLMStreamChunk? {
        guard event.hasPrefix("data: ") else { return nil }

        let jsonString = String(event.dropFirst(6))
        guard jsonString != "[DONE]",
              let data = jsonString.data(using: .utf8),
              let streamEvent = try? decoder.decode(ClaudeStreamEvent.self, from: data)
        else {
            return nil
        }

        switch streamEvent.type {
        case "content_block_delta":
            if let delta = streamEvent.delta?.text {
                return LLMStreamChunk(
                    id: UUID().uuidString,
                    delta: delta,
                    role: .assistant,
                    finishReason: nil,
                    functionCall: nil
                )
            }

        case "message_stop":
            return LLMStreamChunk(
                id: UUID().uuidString,
                delta: "",
                role: .assistant,
                finishReason: .stop,
                functionCall: nil
            )

        default:
            break
        }

        return nil
    }
}

// MARK: - Claude API Types

private struct ClaudeRequestBody: Codable {
    let model: String
    let messages: [ClaudeMessage]
    let system: String?
    let max_tokens: Int
    let temperature: Double?
    let top_p: Double?
    let top_k: Int?
    let stop_sequences: [String]?
    var stream: Bool = false
}

private struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stop_reason: String?
    let stop_sequence: String?
    let usage: ClaudeUsage

    func toLLMResponse() -> LLMResponse {
        let content = content.map(\.text).joined(separator: "\n")

        let finishReason: FinishReason? = switch stop_reason {
        case "end_turn": .stop
        case "max_tokens": .length
        case "stop_sequence": .stop
        default: nil
        }

        return LLMResponse(
            id: id,
            content: content,
            role: .assistant,
            finishReason: finishReason,
            usage: TokenUsage(
                promptTokens: usage.input_tokens,
                completionTokens: usage.output_tokens,
                totalTokens: usage.input_tokens + usage.output_tokens
            )
        )
    }
}

private struct ClaudeContent: Codable {
    let type: String
    let text: String
}

private struct ClaudeUsage: Codable {
    let input_tokens: Int
    let output_tokens: Int
}

private struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ClaudeError
}

private struct ClaudeError: Codable {
    let type: String
    let message: String
}

private struct ClaudeStreamEvent: Codable {
    let type: String
    let message: ClaudeStreamMessage?
    let delta: ClaudeStreamDelta?
}

private struct ClaudeStreamMessage: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
}

private struct ClaudeStreamDelta: Codable {
    let type: String
    let text: String?
}

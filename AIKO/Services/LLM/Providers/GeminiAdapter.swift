//
//  GeminiAdapter.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation

/// Google Gemini API adapter implementation
final class GeminiAdapter: LLMProviderAdapter {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    override init(provider: LLMProvider = .gemini, configuration: LLMProviderConfig) {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)

        super.init(provider: provider, configuration: configuration)
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

        let endpoint = configuration.model.id.contains("vision") ? "generateContent" : "generateContent"
        let url = URL(string: "\(getBaseURL())/v1beta/models/\(configuration.model.id):\(endpoint)?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(requestBody)
        request.allHTTPHeaderFields = buildGeminiHeaders()

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200:
            let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
            return try geminiResponse.toLLMResponse()

        case 429:
            throw LLMError.rateLimitExceeded(provider: provider)

        case 400:
            if let errorData = try? decoder.decode(GeminiErrorResponse.self, from: data) {
                throw LLMError.invalidResponse(errorData.error.message)
            }
            throw LLMError.invalidAPIKey(provider: provider)

        default:
            if let errorResponse = try? decoder.decode(GeminiErrorResponse.self, from: data) {
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
                    let requestBody = try buildRequestBody(
                        prompt: prompt,
                        context: context,
                        options: mergedOptions
                    )

                    let url = URL(string: "\(getBaseURL())/v1beta/models/\(configuration.model.id):streamGenerateContent?key=\(apiKey)")!

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = try encoder.encode(requestBody)
                    request.allHTTPHeaderFields = buildGeminiHeaders()

                    let (data, response) = try await session.data(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200
                    else {
                        throw LLMError.networkError(URLError(.badServerResponse))
                    }

                    // Gemini returns a JSON array of responses for streaming
                    // Parse the complete response and emit chunks
                    if let streamResponses = try? decoder.decode([GeminiResponse].self, from: data) {
                        for (index, response) in streamResponses.enumerated() {
                            if let candidate = response.candidates?.first,
                               let text = candidate.content.parts.first?.text
                            {
                                let chunk = LLMStreamChunk(
                                    id: UUID().uuidString,
                                    delta: text,
                                    role: .assistant,
                                    finishReason: index == streamResponses.count - 1 ? .stop : nil,
                                    functionCall: nil
                                )
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
        // Gemini uses a different tokenization approach
        // This is a rough approximation
        let words = text.split(separator: " ").count
        let characters = text.count

        // Gemini tends to use fewer tokens than GPT models
        return Int(Double(words) * 1.1) + (characters / 5)
    }

    // MARK: - Private Methods

    private func buildGeminiHeaders() -> [String: String] {
        var headers = buildHeaders(apiKey: "") // API key is in URL for Gemini
        headers.removeValue(forKey: "Authorization")
        return headers
    }

    private func buildRequestBody(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) throws -> GeminiRequestBody {
        var contents: [GeminiContent] = []

        // Add conversation history
        if let context {
            // Add system instruction if available
            if let systemPrompt = context.systemPrompt {
                contents.append(GeminiContent(
                    role: "user",
                    parts: [GeminiPart(text: "System instruction: \(systemPrompt)")]
                ))
                contents.append(GeminiContent(
                    role: "model",
                    parts: [GeminiPart(text: "Understood. I'll follow these instructions.")]
                ))
            }

            // Add conversation messages
            for message in context.messages {
                let role = message.role == .user ? "user" : "model"
                contents.append(GeminiContent(
                    role: role,
                    parts: [GeminiPart(text: message.content)]
                ))
            }
        }

        // Add current prompt
        contents.append(GeminiContent(
            role: "user",
            parts: [GeminiPart(text: prompt)]
        ))

        // Build generation config
        let generationConfig = GeminiGenerationConfig(
            temperature: options.temperature,
            topP: options.topP,
            topK: options.topK,
            candidateCount: 1,
            maxOutputTokens: options.maxTokens,
            stopSequences: options.stopSequences
        )

        // Build safety settings (using default for now)
        let safetySettings = [
            GeminiSafetySetting(
                category: "HARM_CATEGORY_HARASSMENT",
                threshold: "BLOCK_MEDIUM_AND_ABOVE"
            ),
            GeminiSafetySetting(
                category: "HARM_CATEGORY_HATE_SPEECH",
                threshold: "BLOCK_MEDIUM_AND_ABOVE"
            ),
            GeminiSafetySetting(
                category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                threshold: "BLOCK_MEDIUM_AND_ABOVE"
            ),
            GeminiSafetySetting(
                category: "HARM_CATEGORY_DANGEROUS_CONTENT",
                threshold: "BLOCK_MEDIUM_AND_ABOVE"
            ),
        ]

        return GeminiRequestBody(
            contents: contents,
            generationConfig: generationConfig,
            safetySettings: safetySettings
        )
    }
}

// MARK: - Gemini API Types

private struct GeminiRequestBody: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    let safetySettings: [GeminiSafetySetting]?
}

private struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiGenerationConfig: Codable {
    let temperature: Double?
    let topP: Double?
    let topK: Int?
    let candidateCount: Int?
    let maxOutputTokens: Int?
    let stopSequences: [String]?
}

private struct GeminiSafetySetting: Codable {
    let category: String
    let threshold: String
}

private struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: GeminiPromptFeedback?
    let usageMetadata: GeminiUsageMetadata?

    func toLLMResponse() throws -> LLMResponse {
        guard let candidate = candidates?.first else {
            if let feedback = promptFeedback {
                throw LLMError.invalidResponse("Content blocked: \(feedback.blockReason ?? "Unknown reason")")
            }
            throw LLMError.invalidResponse("No candidates in response")
        }

        let content = candidate.content.parts
            .compactMap(\.text)
            .joined(separator: "\n")

        let finishReason: FinishReason? = switch candidate.finishReason {
        case "STOP": .stop
        case "MAX_TOKENS": .length
        case "SAFETY": .contentFilter
        default: nil
        }

        return LLMResponse(
            id: UUID().uuidString,
            content: content,
            role: .assistant,
            finishReason: finishReason,
            usage: usageMetadata.map { TokenUsage(
                promptTokens: $0.promptTokenCount,
                completionTokens: $0.candidatesTokenCount,
                totalTokens: $0.totalTokenCount
            ) }
        )
    }
}

private struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int
    let safetyRatings: [GeminiSafetyRating]?
}

private struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

private struct GeminiPromptFeedback: Codable {
    let blockReason: String?
    let safetyRatings: [GeminiSafetyRating]?
}

private struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
}

private struct GeminiErrorResponse: Codable {
    let error: GeminiError
}

private struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}

//
//  OpenAIAdapter.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation

/// OpenAI API adapter implementation (also used for ChatGPT)
final class OpenAIAdapter: LLMProviderAdapter {
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    override init(provider: LLMProvider, configuration: LLMProviderConfig) {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
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
        
        let url = URL(string: "\(getBaseURL())/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(requestBody)
        request.allHTTPHeaderFields = buildOpenAIHeaders(apiKey: apiKey)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
            return try openAIResponse.toLLMResponse()
            
        case 429:
            throw LLMError.rateLimitExceeded(provider: provider)
            
        case 401:
            throw LLMError.invalidAPIKey(provider: provider)
            
        default:
            if let errorResponse = try? decoder.decode(OpenAIErrorResponse.self, from: data) {
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
                    
                    let url = URL(string: "\(getBaseURL())/v1/chat/completions")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = try encoder.encode(requestBody)
                    request.allHTTPHeaderFields = buildOpenAIHeaders(apiKey: apiKey)
                    
                    let (bytes, response) = try await session.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
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
                                
                                if chunk.finishReason != nil {
                                    continuation.finish()
                                    return
                                }
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
        // OpenAI uses tiktoken for tokenization
        // This is a rough approximation
        let words = text.split(separator: " ").count
        let punctuation = text.filter { ".,!?;:".contains($0) }.count
        
        // Rough approximation based on GPT tokenization patterns
        return Int(Double(words) * 1.3) + punctuation
    }
    
    // MARK: - Private Methods
    
    private func buildOpenAIHeaders(apiKey: String) -> [String: String] {
        var headers = buildHeaders(apiKey: apiKey)
        headers["Authorization"] = "Bearer \(apiKey)"
        
        // Add organization header if configured
        if let orgId = configuration.customHeaders?["OpenAI-Organization"] {
            headers["OpenAI-Organization"] = orgId
        }
        
        return headers
    }
    
    private func buildRequestBody(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) throws -> OpenAIRequestBody {
        var messages: [OpenAIMessage] = []
        
        // Add system message if available
        if let systemPrompt = context?.systemPrompt {
            messages.append(OpenAIMessage(
                role: "system",
                content: systemPrompt
            ))
        }
        
        // Add conversation history
        if let context = context {
            for message in context.messages {
                messages.append(OpenAIMessage(
                    role: message.role.openAIRole,
                    content: message.content,
                    name: message.metadata?["name"]
                ))
            }
        }
        
        // Add current prompt
        messages.append(OpenAIMessage(
            role: "user",
            content: prompt
        ))
        
        // Build function definitions if provided
        let functions = options.functions?.map { function in
            OpenAIFunction(
                name: function.name,
                description: function.description,
                parameters: function.parameters
            )
        }
        
        return OpenAIRequestBody(
            model: configuration.model.id,
            messages: messages,
            temperature: options.temperature,
            top_p: options.topP,
            n: 1,
            stream: false,
            stop: options.stopSequences,
            max_tokens: options.maxTokens,
            presence_penalty: options.presencePenalty,
            frequency_penalty: options.frequencyPenalty,
            functions: functions,
            function_call: functions != nil ? "auto" : nil,
            response_format: options.responseFormat?.openAIFormat
        )
    }
    
    private func parseSSEEvent(_ event: String) -> LLMStreamChunk? {
        guard event.hasPrefix("data: ") else { return nil }
        
        let jsonString = String(event.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard jsonString != "[DONE]",
              let data = jsonString.data(using: .utf8),
              let streamResponse = try? decoder.decode(OpenAIStreamResponse.self, from: data),
              let choice = streamResponse.choices.first else {
            return nil
        }
        
        let chunk = LLMStreamChunk(
            id: streamResponse.id,
            delta: choice.delta?.content ?? "",
            role: choice.delta?.role.map { MessageRole(openAIRole: $0) },
            finishReason: choice.finish_reason.map { FinishReason(openAIReason: $0) },
            functionCall: choice.delta?.function_call.map { FunctionCall(name: $0.name ?? "", arguments: $0.arguments ?? "") }
        )
        
        return chunk
    }
}

// MARK: - OpenAI API Types

private struct OpenAIRequestBody: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double?
    let top_p: Double?
    let n: Int?
    var stream: Bool = false
    let stop: [String]?
    let max_tokens: Int?
    let presence_penalty: Double?
    let frequency_penalty: Double?
    let functions: [OpenAIFunction]?
    let function_call: String?
    let response_format: OpenAIResponseFormat?
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
    let name: String?
    
    init(role: String, content: String, name: String? = nil) {
        self.role = role
        self.content = content
        self.name = name
    }
}

private struct OpenAIFunction: Codable {
    let name: String
    let description: String
    let parameters: [String: Any]
    
    // Custom encoding/decoding for parameters
    enum CodingKeys: String, CodingKey {
        case name, description, parameters
    }
    
    init(name: String, description: String, parameters: [String: Any]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        if let jsonData = try? container.decode(Data.self, forKey: .parameters),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            parameters = json
        } else {
            parameters = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters) {
            try container.encode(jsonData, forKey: .parameters)
        }
    }
}

private struct OpenAIResponseFormat: Codable {
    let type: String
}

private struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
    
    func toLLMResponse() throws -> LLMResponse {
        guard let choice = choices.first else {
            throw LLMError.invalidResponse("No choices in response")
        }
        
        let finishReason = choice.finish_reason.map { FinishReason(openAIReason: $0) }
        
        let functionCalls = choice.message.function_call.map { call in
            [FunctionCall(name: call.name, arguments: call.arguments)]
        }
        
        return LLMResponse(
            id: id,
            content: choice.message.content ?? "",
            role: MessageRole(openAIRole: choice.message.role) ?? .assistant,
            finishReason: finishReason,
            usage: usage.map { TokenUsage(
                promptTokens: $0.prompt_tokens,
                completionTokens: $0.completion_tokens,
                totalTokens: $0.total_tokens
            )},
            functionCalls: functionCalls
        )
    }
}

private struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIChoiceMessage
    let finish_reason: String?
}

private struct OpenAIChoiceMessage: Codable {
    let role: String
    let content: String?
    let function_call: OpenAIFunctionCall?
}

private struct OpenAIFunctionCall: Codable {
    let name: String
    let arguments: String
}

private struct OpenAIUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

private struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

private struct OpenAIError: Codable {
    let message: String
    let type: String
    let param: String?
    let code: String?
}

// Stream response types
private struct OpenAIStreamResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIStreamChoice]
}

private struct OpenAIStreamChoice: Codable {
    let index: Int
    let delta: OpenAIStreamDelta?
    let finish_reason: String?
}

private struct OpenAIStreamDelta: Codable {
    let role: String?
    let content: String?
    let function_call: OpenAIStreamFunctionCall?
}

private struct OpenAIStreamFunctionCall: Codable {
    let name: String?
    let arguments: String?
}

// MARK: - Extensions

private extension MessageRole {
    var openAIRole: String {
        switch self {
        case .system: return "system"
        case .user: return "user"
        case .assistant: return "assistant"
        case .function: return "function"
        }
    }
    
    init?(openAIRole: String) {
        switch openAIRole {
        case "system": self = .system
        case "user": self = .user
        case "assistant": self = .assistant
        case "function": self = .function
        default: return nil
        }
    }
}

private extension FinishReason {
    init?(openAIReason: String) {
        switch openAIReason {
        case "stop": self = .stop
        case "length": self = .length
        case "function_call": self = .functionCall
        case "content_filter": self = .contentFilter
        default: return nil
        }
    }
}

private extension ResponseFormat {
    var openAIFormat: OpenAIResponseFormat? {
        switch self {
        case .text:
            return nil
        case .json:
            return OpenAIResponseFormat(type: "json_object")
        case .jsonSchema:
            // OpenAI doesn't support JSON schema directly yet
            return OpenAIResponseFormat(type: "json_object")
        }
    }
}
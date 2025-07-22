import AppCore
import Foundation

// MARK: - Local Model Provider

/// Local model provider for offline/air-gapped environments (using llama.cpp or similar)
public final class LocalModelProvider: LLMProviderProtocol, @unchecked Sendable {
    // MARK: - Properties

    public let id = "local"
    public let name = "Local Model"

    public var capabilities: LLMProviderCapabilities {
        LLMProviderCapabilities(
            supportsStreaming: true,
            supportsEmbeddings: false,
            supportsVision: false,
            supportsFunctionCalling: false,
            maxTokens: 4096,
            maxContextLength: 32768,
            supportedModels: [
                LLMModel(
                    id: "llama-3-8b",
                    name: "Llama 3 8B",
                    description: "Meta's Llama 3 8B model",
                    contextLength: 8192,
                    pricing: nil // Free for local models
                ),
                LLMModel(
                    id: "llama-3-70b",
                    name: "Llama 3 70B",
                    description: "Meta's Llama 3 70B model",
                    contextLength: 8192,
                    pricing: nil
                ),
                LLMModel(
                    id: "mistral-7b",
                    name: "Mistral 7B",
                    description: "Mistral AI's 7B model",
                    contextLength: 32768,
                    pricing: nil
                ),
                LLMModel(
                    id: "mixtral-8x7b",
                    name: "Mixtral 8x7B",
                    description: "Mistral's MoE model",
                    contextLength: 32768,
                    pricing: nil
                ),
                LLMModel(
                    id: "phi-3",
                    name: "Phi-3",
                    description: "Microsoft's small efficient model",
                    contextLength: 4096,
                    pricing: nil
                ),
            ]
        )
    }

    private var serverURL: String = "http://localhost:8080"
    private let session: URLSession

    // MARK: - Initialization

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60 // Longer timeout for local models
        configuration.timeoutIntervalForResource = 600
        session = URLSession(configuration: configuration)
    }

    // MARK: - LLMProviderProtocol

    public var isConfigured: Bool {
        get async {
            // Check if local server is running
            if let config = try? await LLMConfigurationManager.shared.loadConfiguration(for: id),
               let customEndpoint = config.customEndpoint {
                serverURL = customEndpoint
            }

            // Try to ping the server
            do {
                guard let url = URL(string: "\(serverURL)/health") else { return false }
                let (_, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 200
                }
            } catch {
                // Server not reachable
            }
            return false
        }
    }

    public func validateCredentials() async throws -> Bool {
        // Local models don't need API keys, just check if server is running
        let configured = await isConfigured
        if !configured {
            throw LLMProviderError.notConfigured
        }
        return true
    }

    public func chatCompletion(_ request: LLMChatRequest) async throws -> LLMChatResponse {
        // Update server URL if custom endpoint is configured
        if let config = try? await LLMConfigurationManager.shared.loadConfiguration(for: id),
           let customEndpoint = config.customEndpoint {
            serverURL = customEndpoint
        }

        // Build prompt from messages
        var prompt = ""
        if let systemPrompt = request.systemPrompt {
            prompt = "System: \(systemPrompt)\n\n"
        }

        for message in request.messages {
            switch message.role {
            case .user:
                prompt += "User: \(message.content)\n"
            case .assistant:
                prompt += "Assistant: \(message.content)\n"
            case .system:
                prompt += "System: \(message.content)\n"
            case .function:
                prompt += "Function: \(message.content)\n"
            }
        }
        prompt += "Assistant: "

        // Build request body for llama.cpp server format
        let body: [String: Any] = [
            "prompt": prompt,
            "n_predict": request.maxTokens ?? 4096,
            "temperature": request.temperature,
            "stop": ["User:", "System:"],
            "stream": false,
        ]

        // Make API request
        guard let url = URL(string: "\(serverURL)/completion") else {
            throw LLMProviderError.networkError("Invalid URL")
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMProviderError.networkError("Invalid response from local server")
        }

        guard httpResponse.statusCode == 200 else {
            throw LLMProviderError.networkError("Local server returned \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMProviderError.invalidResponse("Invalid JSON from local server")
        }

        guard let content = json["content"] as? String else {
            throw LLMProviderError.invalidResponse("Missing content in response")
        }

        // Extract token counts if available
        let promptTokens = json["tokens_evaluated"] as? Int ?? 0
        let completionTokens = json["tokens_predicted"] as? Int ?? 0
        let stopped = json["stopped_limit"] as? Bool ?? false

        let message = LLMMessage(role: .assistant, content: content.trimmingCharacters(in: .whitespacesAndNewlines))
        let tokenUsage = TokenUsage(promptTokens: promptTokens, completionTokens: completionTokens)
        let finishReason: FinishReason = stopped ? .length : .stop

        return LLMChatResponse(
            id: UUID().uuidString,
            model: request.model,
            message: message,
            usage: tokenUsage,
            finishReason: finishReason
        )
    }

    public func streamChatCompletion(_ request: LLMChatRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Update server URL if custom endpoint is configured
                    if let config = try? await LLMConfigurationManager.shared.loadConfiguration(for: id),
                       let customEndpoint = config.customEndpoint {
                        self.serverURL = customEndpoint
                    }

                    // Build prompt from messages
                    var prompt = ""
                    if let systemPrompt = request.systemPrompt {
                        prompt = "System: \(systemPrompt)\n\n"
                    }

                    for message in request.messages {
                        switch message.role {
                        case .user:
                            prompt += "User: \(message.content)\n"
                        case .assistant:
                            prompt += "Assistant: \(message.content)\n"
                        case .system:
                            prompt += "System: \(message.content)\n"
                        case .function:
                            prompt += "Function: \(message.content)\n"
                        }
                    }
                    prompt += "Assistant: "

                    // Build request body
                    let body: [String: Any] = [
                        "prompt": prompt,
                        "n_predict": request.maxTokens ?? 4096,
                        "temperature": request.temperature,
                        "stop": ["User:", "System:"],
                        "stream": true,
                    ]

                    // Make streaming request
                    guard let url = URL(string: "\(serverURL)/completion") else {
                        throw LLMProviderError.networkError("Invalid URL")
                    }
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200
                    else {
                        throw LLMProviderError.networkError("Stream request failed")
                    }

                    // Process streaming response
                    for try await line in bytes.lines where line.hasPrefix("data: ") {
                        let jsonString = String(line.dropFirst(6))

                        if let data = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let content = json["content"] as? String {
                                continuation.yield(LLMStreamChunk(delta: content))
                            }

                            if let stop = json["stop"] as? Bool, stop {
                                let stoppedLimit = json["stopped_limit"] as? Bool ?? false
                                let finishReason: FinishReason = stoppedLimit ? .length : .stop
                                continuation.yield(LLMStreamChunk(delta: "", finishReason: finishReason))
                                continuation.finish()
                                break
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func generateEmbeddings(_: String) async throws -> [Float] {
        throw LLMProviderError.embeddingsNotSupported
    }

    public func tokenCount(for text: String) async throws -> Int {
        // Update server URL if custom endpoint is configured
        if let config = try? await LLMConfigurationManager.shared.loadConfiguration(for: id),
           let customEndpoint = config.customEndpoint {
            serverURL = customEndpoint
        }

        let body: [String: Any] = ["content": text]

        guard let url = URL(string: "\(serverURL)/tokenize") else {
            throw LLMProviderError.networkError("Invalid URL")
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            // Fallback to estimation if tokenize endpoint not available
            return text.split(separator: " ").count
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [[String: Any]]
        else {
            return text.split(separator: " ").count
        }

        return tokens.count
    }

    public func getSettings() -> LLMProviderSettings {
        LLMProviderSettings(
            apiEndpoint: serverURL,
            timeout: 60,
            retryCount: 3
        )
    }
}

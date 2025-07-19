import Foundation
import AppCore

// MARK: - Google Gemini Provider

/// Google Gemini API provider implementation
public final class GeminiProvider: LLMProviderProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    public let id = "gemini"
    public let name = "Google Gemini"
    
    public var capabilities: LLMProviderCapabilities {
        LLMProviderCapabilities(
            supportsStreaming: true,
            supportsEmbeddings: true,
            supportsVision: true,
            supportsFunctionCalling: true,
            maxTokens: 8192,
            maxContextLength: 1048576, // 1M tokens for Gemini 1.5 Pro
            supportedModels: [
                LLMModel(
                    id: "gemini-1.5-pro",
                    name: "Gemini 1.5 Pro",
                    description: "Most capable model with 1M token context",
                    contextLength: 1048576,
                    pricing: ModelPricing(
                        inputPricePerMillion: 3.5,
                        outputPricePerMillion: 10.5
                    )
                ),
                LLMModel(
                    id: "gemini-1.5-flash",
                    name: "Gemini 1.5 Flash",
                    description: "Fast and efficient with 1M token context",
                    contextLength: 1048576,
                    pricing: ModelPricing(
                        inputPricePerMillion: 0.35,
                        outputPricePerMillion: 1.05
                    )
                ),
                LLMModel(
                    id: "gemini-pro",
                    name: "Gemini Pro",
                    description: "Balanced performance model",
                    contextLength: 32768,
                    pricing: ModelPricing(
                        inputPricePerMillion: 0.5,
                        outputPricePerMillion: 1.5
                    )
                ),
                LLMModel(
                    id: "gemini-pro-vision",
                    name: "Gemini Pro Vision",
                    description: "Multimodal model for text and images",
                    contextLength: 32768,
                    pricing: ModelPricing(
                        inputPricePerMillion: 0.5,
                        outputPricePerMillion: 1.5
                    )
                )
            ]
        )
    }
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private var apiKey: String?
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - LLMProviderProtocol
    
    public var isConfigured: Bool {
        get async {
            await LLMConfigurationManager.shared.isProviderConfigured(id)
        }
    }
    
    public func validateCredentials() async throws -> Bool {
        guard try await LLMConfigurationManager.shared.loadConfiguration(for: id) != nil else {
            throw LLMProviderError.notConfigured
        }
        
        // Test API key with a simple request
        let testRequest = LLMChatRequest(
            messages: [LLMMessage(role: .user, content: "Hi")],
            model: "gemini-pro",
            maxTokens: 10
        )
        
        do {
            _ = try await chatCompletion(testRequest)
            return true
        } catch {
            if case LLMProviderError.invalidCredentials = error {
                return false
            }
            throw error
        }
    }
    
    public func chatCompletion(_ request: LLMChatRequest) async throws -> LLMChatResponse {
        guard let config = try await LLMConfigurationManager.shared.loadConfiguration(for: id) else {
            throw LLMProviderError.notConfigured
        }
        
        // Convert messages to Gemini format
        var contents: [[String: Any]] = []
        
        // Add system instruction if provided
        var systemInstruction: String? = nil
        if let systemPrompt = request.systemPrompt {
            systemInstruction = systemPrompt
        }
        
        // Convert messages to Gemini format
        for message in request.messages {
            let role = message.role == .assistant ? "model" : "user"
            contents.append([
                "role": role,
                "parts": [["text": message.content]]
            ])
        }
        
        // Build request body
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": request.temperature,
                "maxOutputTokens": request.maxTokens ?? 8192
            ]
        ]
        
        if let systemInstruction = systemInstruction {
            body["systemInstruction"] = ["parts": [["text": systemInstruction]]]
        }
        
        // Make API request
        let endpoint = "\(baseURL)/models/\(request.model):generateContent?key=\(config.apiKey ?? "")"
        var urlRequest = URLRequest(url: URL(string: endpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMProviderError.networkError("Invalid response")
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw LLMProviderError.invalidCredentials
        }
        
        if httpResponse.statusCode == 429 {
            throw LLMProviderError.rateLimitExceeded
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let error = errorBody?["error"] as? [String: Any]
            let message = error?["message"] as? String ?? "Unknown error"
            throw LLMProviderError.networkError("HTTP \(httpResponse.statusCode): \(message)")
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMProviderError.invalidResponse("Invalid JSON")
        }
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw LLMProviderError.invalidResponse("Missing required fields")
        }
        
        // Extract usage metadata if available
        let usageMetadata = json["usageMetadata"] as? [String: Any]
        let promptTokens = usageMetadata?["promptTokenCount"] as? Int ?? 0
        let candidateTokens = usageMetadata?["candidatesTokenCount"] as? Int ?? 0
        
        let message = LLMMessage(role: .assistant, content: text)
        let tokenUsage = TokenUsage(promptTokens: promptTokens, completionTokens: candidateTokens)
        
        let finishReason = firstCandidate["finishReason"] as? String
        let reason: FinishReason = {
            switch finishReason {
            case "MAX_TOKENS": return .length
            case "SAFETY": return .contentFilter
            default: return .stop
            }
        }()
        
        return LLMChatResponse(
            id: UUID().uuidString,
            model: request.model,
            message: message,
            usage: tokenUsage,
            finishReason: reason
        )
    }
    
    public func streamChatCompletion(_ request: LLMChatRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let config = try await LLMConfigurationManager.shared.loadConfiguration(for: id) else {
                        throw LLMProviderError.notConfigured
                    }
                    
                    // Convert messages to Gemini format
                    var contents: [[String: Any]] = []
                    
                    for message in request.messages {
                        let role = message.role == .assistant ? "model" : "user"
                        contents.append([
                            "role": role,
                            "parts": [["text": message.content]]
                        ])
                    }
                    
                    // Build request body
                    var body: [String: Any] = [
                        "contents": contents,
                        "generationConfig": [
                            "temperature": request.temperature,
                            "maxOutputTokens": request.maxTokens ?? 8192
                        ]
                    ]
                    
                    if let systemPrompt = request.systemPrompt {
                        body["systemInstruction"] = ["parts": [["text": systemPrompt]]]
                    }
                    
                    // Make streaming request
                    let endpoint = "\(baseURL)/models/\(request.model):streamGenerateContent?alt=sse&key=\(config.apiKey ?? "")"
                    var urlRequest = URLRequest(url: URL(string: endpoint)!)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw LLMProviderError.networkError("Stream request failed")
                    }
                    
                    // Process SSE stream
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let candidates = json["candidates"] as? [[String: Any]],
                               let firstCandidate = candidates.first,
                               let content = firstCandidate["content"] as? [String: Any],
                               let parts = content["parts"] as? [[String: Any]],
                               let firstPart = parts.first,
                               let text = firstPart["text"] as? String {
                                
                                continuation.yield(LLMStreamChunk(delta: text))
                                
                                if let finishReason = firstCandidate["finishReason"] as? String {
                                    let reason: FinishReason = {
                                        switch finishReason {
                                        case "MAX_TOKENS": return .length
                                        case "SAFETY": return .contentFilter
                                        default: return .stop
                                        }
                                    }()
                                    continuation.yield(LLMStreamChunk(delta: "", finishReason: reason))
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func generateEmbeddings(_ text: String) async throws -> [Float] {
        guard let config = try await LLMConfigurationManager.shared.loadConfiguration(for: id) else {
            throw LLMProviderError.notConfigured
        }
        
        let body: [String: Any] = [
            "model": "models/embedding-001",
            "content": ["parts": [["text": text]]]
        ]
        
        let endpoint = "\(baseURL)/models/embedding-001:embedContent?key=\(config.apiKey ?? "")"
        var urlRequest = URLRequest(url: URL(string: endpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMProviderError.networkError("Embeddings request failed")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let embedding = json["embedding"] as? [String: Any],
              let values = embedding["values"] as? [Double] else {
            throw LLMProviderError.invalidResponse("Invalid embeddings response")
        }
        
        return values.map { Float($0) }
    }
    
    public func tokenCount(for text: String) async throws -> Int {
        guard let config = try await LLMConfigurationManager.shared.loadConfiguration(for: id) else {
            throw LLMProviderError.notConfigured
        }
        
        let body: [String: Any] = [
            "contents": [["parts": [["text": text]]]]
        ]
        
        let endpoint = "\(baseURL)/models/gemini-pro:countTokens?key=\(config.apiKey ?? "")"
        var urlRequest = URLRequest(url: URL(string: endpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LLMProviderError.networkError("Token count request failed")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let totalTokens = json["totalTokens"] as? Int else {
            throw LLMProviderError.invalidResponse("Invalid token count response")
        }
        
        return totalTokens
    }
    
    public func getSettings() -> LLMProviderSettings {
        LLMProviderSettings(
            apiEndpoint: baseURL,
            timeout: 30,
            retryCount: 3
        )
    }
}
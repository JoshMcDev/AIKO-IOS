//
//  LLMProviderProtocol.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation

/// Common protocol for all LLM provider adapters
protocol LLMProviderProtocol {
    /// The provider type
    var provider: LLMProvider { get }
    
    /// Current configuration
    var configuration: LLMProviderConfig { get }
    
    /// Provider capabilities
    var capabilities: LLMCapabilities { get }
    
    /// Send a request to the LLM provider
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - context: Conversation context
    ///   - options: Request options
    /// - Returns: The LLM response
    func sendRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) async throws -> LLMResponse
    
    /// Stream a response from the LLM provider
    /// - Parameters:
    ///   - prompt: The user's prompt
    ///   - context: Conversation context
    ///   - options: Request options
    /// - Returns: An async stream of response chunks
    func streamRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) -> AsyncThrowingStream<LLMStreamChunk, Error>
    
    /// Validate if the provider is properly configured
    /// - Returns: True if ready to use
    func validateConfiguration() async -> Bool
    
    /// Get token count for a text
    /// - Parameter text: The text to count tokens for
    /// - Returns: Approximate token count
    func countTokens(for text: String) -> Int
    
    /// Cancel any ongoing requests
    func cancelAllRequests()
}

// MARK: - Common Data Types

/// Conversation context for maintaining chat history
struct ConversationContext: Codable, Equatable {
    let messages: [ConversationMessage]
    let systemPrompt: String?
    let metadata: [String: String]?
    
    init(
        messages: [ConversationMessage] = [],
        systemPrompt: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.messages = messages
        self.systemPrompt = systemPrompt
        self.metadata = metadata
    }
    
    /// Total approximate token count
    var totalTokens: Int {
        messages.reduce(0) { $0 + $1.approximateTokens }
    }
}

/// A single message in the conversation
struct ConversationMessage: Codable, Equatable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    let metadata: [String: String]?
    
    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    /// Approximate token count (rough estimate)
    var approximateTokens: Int {
        // Rough approximation: 1 token ≈ 4 characters
        return content.count / 4
    }
}

/// Message role in conversation
enum MessageRole: String, Codable, CaseIterable {
    case system
    case user
    case assistant
    case function
}

/// Options for LLM requests
struct LLMRequestOptions: Codable, Equatable {
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let topK: Int?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    let stopSequences: [String]?
    let functions: [LLMFunction]?
    let responseFormat: ResponseFormat?
    let timeout: TimeInterval?
    
    init(
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        frequencyPenalty: Double? = nil,
        presencePenalty: Double? = nil,
        stopSequences: [String]? = nil,
        functions: [LLMFunction]? = nil,
        responseFormat: ResponseFormat? = nil,
        timeout: TimeInterval? = 60
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.topK = topK
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.stopSequences = stopSequences
        self.functions = functions
        self.responseFormat = responseFormat
        self.timeout = timeout
    }
    
    /// Merge with provider defaults
    func merged(with defaults: LLMProviderConfig) -> LLMRequestOptions {
        return LLMRequestOptions(
            temperature: temperature ?? defaults.temperature,
            maxTokens: maxTokens ?? defaults.maxTokens,
            topP: topP ?? defaults.topP,
            topK: topK,
            frequencyPenalty: frequencyPenalty ?? defaults.frequencyPenalty,
            presencePenalty: presencePenalty ?? defaults.presencePenalty,
            stopSequences: stopSequences ?? defaults.stopSequences,
            functions: functions,
            responseFormat: responseFormat,
            timeout: timeout
        )
    }
}

/// Response format specification
enum ResponseFormat: Codable, Equatable {
    case text
    case json
    case jsonSchema(String) // JSON schema as string
}

/// Function definition for function calling
struct LLMFunction: Codable, Equatable {
    let name: String
    let description: String
    let parameters: [String: Any]
    
    init(name: String, description: String, parameters: [String: Any]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    // Custom Codable implementation for [String: Any]
    enum CodingKeys: String, CodingKey {
        case name, description, parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // Decode parameters as JSON string
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
        
        // Encode parameters as JSON data
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters) {
            try container.encode(jsonData, forKey: .parameters)
        }
    }
}

/// LLM response structure
struct LLMResponse: Codable, Equatable {
    let id: String
    let content: String
    let role: MessageRole
    let finishReason: FinishReason?
    let usage: TokenUsage?
    let functionCalls: [FunctionCall]?
    let metadata: [String: String]?
    
    init(
        id: String = UUID().uuidString,
        content: String,
        role: MessageRole = .assistant,
        finishReason: FinishReason? = nil,
        usage: TokenUsage? = nil,
        functionCalls: [FunctionCall]? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.finishReason = finishReason
        self.usage = usage
        self.functionCalls = functionCalls
        self.metadata = metadata
    }
}

/// Reason for response completion
enum FinishReason: String, Codable {
    case stop = "stop"
    case length = "length"
    case functionCall = "function_call"
    case contentFilter = "content_filter"
    case error = "error"
}

/// Token usage statistics
struct TokenUsage: Codable, Equatable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    /// Calculate estimated cost
    func estimatedCost(for model: LLMModel) -> Double {
        let costs = model.costPer1KTokens
        let promptCost = Double(promptTokens) / 1000.0 * costs.input
        let completionCost = Double(completionTokens) / 1000.0 * costs.output
        return promptCost + completionCost
    }
}

/// Function call in response
struct FunctionCall: Codable, Equatable {
    let name: String
    let arguments: String // JSON string
}

/// Streaming response chunk
struct LLMStreamChunk: Codable, Equatable {
    let id: String
    let delta: String
    let role: MessageRole?
    let finishReason: FinishReason?
    let functionCall: FunctionCall?
}

// MARK: - Provider Adapter Base

/// Base class for provider adapters with common functionality
class LLMProviderAdapter: LLMProviderProtocol {
    let provider: LLMProvider
    let configuration: LLMProviderConfig
    let capabilities: LLMCapabilities
    
    private var activeTasks: Set<Task<Void, Never>> = []
    private let taskQueue = DispatchQueue(label: "com.aiko.llm.tasks", attributes: .concurrent)
    
    init(provider: LLMProvider, configuration: LLMProviderConfig) {
        self.provider = provider
        self.configuration = configuration
        self.capabilities = provider.capabilities
    }
    
    // Default implementations
    
    func sendRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) async throws -> LLMResponse {
        fatalError("Subclasses must implement sendRequest")
    }
    
    func streamRequest(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        fatalError("Subclasses must implement streamRequest")
    }
    
    func validateConfiguration() async -> Bool {
        // Check if API key exists
        guard let _ = await getAPIKey() else { return false }
        
        // Additional validation can be added by subclasses
        return true
    }
    
    func countTokens(for text: String) -> Int {
        // Basic approximation - subclasses can override with provider-specific tokenizers
        return text.count / 4
    }
    
    func cancelAllRequests() {
        taskQueue.async(flags: .barrier) {
            self.activeTasks.forEach { $0.cancel() }
            self.activeTasks.removeAll()
        }
    }
    
    // Helper methods for subclasses
    
    /// Get API key from keychain
    @MainActor
    protected func getAPIKey() async -> String? {
        return LLMConfigurationManager.shared.getAPIKey(for: provider)
    }
    
    /// Track an active task
    protected func trackTask(_ task: Task<Void, Never>) {
        taskQueue.async(flags: .barrier) {
            self.activeTasks.insert(task)
        }
    }
    
    /// Remove a completed task
    protected func removeTask(_ task: Task<Void, Never>) {
        taskQueue.async(flags: .barrier) {
            self.activeTasks.remove(task)
        }
    }
    
    /// Build headers with authentication
    protected func buildHeaders(apiKey: String) -> [String: String] {
        var headers = [
            "Content-Type": "application/json"
        ]
        
        // Add custom headers if configured
        if let customHeaders = configuration.customHeaders {
            headers.merge(customHeaders) { _, custom in custom }
        }
        
        return headers
    }
    
    /// Get base URL for requests
    protected func getBaseURL() -> String {
        return configuration.customEndpoint ?? provider.baseURL
    }
}
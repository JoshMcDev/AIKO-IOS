//
//  OpenRouterSyncAdapter.swift
//  AIKO
//
//  Created for OpenRouter API integration with SyncEngine
//

import Foundation
import os.log

/// Configuration for OpenRouter models
struct OpenRouterModelConfig: Codable {
    let modelId: String
    let provider: String
    let role: String
    let maxTokens: Int
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case provider
        case role
        case maxTokens = "max_tokens"
        case description
    }
}

/// OpenRouter API adapter for synchronization
actor OpenRouterSyncAdapter {
    private let logger = Logger(subsystem: "com.aiko.cache", category: "OpenRouterSync")
    
    /// Available models from configuration
    private let models: [String: OpenRouterModelConfig] = [
        "x-ai/grok-4": OpenRouterModelConfig(
            modelId: "x-ai/grok-4",
            provider: "openrouter",
            role: "chat",
            maxTokens: 256000,
            description: "Primary general chat - high capability"
        ),
        "google/gemini-2.5-pro": OpenRouterModelConfig(
            modelId: "google/gemini-2.5-pro",
            provider: "openrouter",
            role: "thinkdeep",
            maxTokens: 1048576,
            description: "Long think-deep dives with massive context"
        ),
        "google/gemini-2.5-flash-preview": OpenRouterModelConfig(
            modelId: "google/gemini-2.5-flash-preview",
            provider: "openrouter",
            role: "fast_chat",
            maxTokens: 1048576,
            description: "Ultra-fast responses for everyday chat"
        ),
        "deepseek/deepseek-chat": OpenRouterModelConfig(
            modelId: "deepseek/deepseek-chat",
            provider: "openrouter",
            role: "complex_reasoning",
            maxTokens: 64000,
            description: "Step-by-step reasoning specialist - very cost effective"
        ),
        "openai/gpt-4o-2024-08-06": OpenRouterModelConfig(
            modelId: "openai/gpt-4o-2024-08-06",
            provider: "openrouter",
            role: "debug",
            maxTokens: 128000,
            description: "Best for JSON compliance and vision tasks"
        ),
        "openai/gpt-4o-mini": OpenRouterModelConfig(
            modelId: "openai/gpt-4o-mini",
            provider: "openrouter",
            role: "validator",
            maxTokens: 128000,
            description: "Lightweight sanity check and validation"
        ),
        "google/gemini-2.0-flash-exp": OpenRouterModelConfig(
            modelId: "google/gemini-2.0-flash-exp",
            provider: "openrouter",
            role: "validator2",
            maxTokens: 1048576,
            description: "Second validator with different training for edge cases"
        ),
        "tngtech/deepseek-r1t-chimera:free": OpenRouterModelConfig(
            modelId: "tngtech/deepseek-r1t-chimera:free",
            provider: "openrouter",
            role: "codereview",
            maxTokens: 163840,
            description: "Code review specialist - large context, no cost"
        ),
        "qwen/qwen-2.5-coder-32b-instruct": OpenRouterModelConfig(
            modelId: "qwen/qwen-2.5-coder-32b-instruct",
            provider: "openrouter",
            role: "codegen",
            maxTokens: 32768,
            description: "Specialized code generation - outperforms on coding tasks"
        ),
        "mistralai/mixtral-8x22b-instruct": OpenRouterModelConfig(
            modelId: "mistralai/mixtral-8x22b-instruct",
            provider: "openrouter",
            role: "refactor",
            maxTokens: 65536,
            description: "Code refactoring and transformation tasks"
        ),
        "cohere/command-r-plus": OpenRouterModelConfig(
            modelId: "cohere/command-r-plus",
            provider: "openrouter",
            role: "consensus_for",
            maxTokens: 128000,
            description: "Consensus building - arguing for proposals"
        ),
        "meta-llama/llama-3.3-70b-instruct": OpenRouterModelConfig(
            modelId: "meta-llama/llama-3.3-70b-instruct",
            provider: "openrouter",
            role: "consensus_against",
            maxTokens: 131072,
            description: "Consensus building - critical perspective"
        ),
        "qwen/qwq-32b-preview": OpenRouterModelConfig(
            modelId: "qwen/qwq-32b-preview",
            provider: "openrouter",
            role: "math_science",
            maxTokens: 32768,
            description: "Mathematical reasoning and scientific analysis"
        ),
        "openai/gpt-4o-search-preview": OpenRouterModelConfig(
            modelId: "openai/gpt-4o-search-preview",
            provider: "openrouter",
            role: "search",
            maxTokens: 128000,
            description: "Web search with built-in citation support"
        )
    ]
    
    /// Rate limiting configuration per model
    private var rateLimits: [String: RateLimitInfo] = [:]
    
    /// API configuration
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    private let session: URLSession
    
    /// Initialize adapter
    init(apiKey: String) {
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        // Initialize rate limits
        Task {
            await initializeRateLimits()
        }
    }
    
    /// Initialize rate limiting for models
    private func initializeRateLimits() {
        // Conservative defaults based on model tiers
        for (modelId, config) in models {
            let rateLimit: RateLimitInfo
            
            switch config.role {
            case "chat", "thinkdeep":
                rateLimit = RateLimitInfo(
                    requestsPerMinute: 60,
                    tokensPerMinute: 1_000_000,
                    concurrentRequests: 5
                )
            case "fast_chat", "validator", "validator2":
                rateLimit = RateLimitInfo(
                    requestsPerMinute: 120,
                    tokensPerMinute: 2_000_000,
                    concurrentRequests: 10
                )
            case "codereview", "codegen", "refactor":
                rateLimit = RateLimitInfo(
                    requestsPerMinute: 30,
                    tokensPerMinute: 500_000,
                    concurrentRequests: 3
                )
            default:
                rateLimit = RateLimitInfo(
                    requestsPerMinute: 45,
                    tokensPerMinute: 750_000,
                    concurrentRequests: 4
                )
            }
            
            rateLimits[modelId] = rateLimit
        }
    }
    
    /// Sync a cached item to OpenRouter
    func syncCacheItem(_ item: OutboxItem) async throws -> SyncItemResult {
        guard let modelConfig = getModelForRole(item.syncRole ?? "chat") else {
            throw OpenRouterError.invalidModel("No model configured for role: \(item.syncRole ?? "chat")")
        }
        
        // Check rate limits
        try await enforceRateLimit(for: modelConfig.modelId)
        
        // Prepare request with token guardrails
        let request = try buildRequestWithGuardrails(for: item, model: modelConfig)
        
        // Execute with retries
        let response = try await executeWithRetry(request, modelId: modelConfig.modelId)
        
        // Process response
        return try processResponse(response, for: item)
    }
    
    /// Get model configuration for a specific role
    private func getModelForRole(_ role: String) -> OpenRouterModelConfig? {
        models.values.first { $0.role == role }
    }
    
    /// Build API request
    private func buildRequest(for item: OutboxItem, model: OpenRouterModelConfig) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AIKO-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Build request body based on operation
        let body: [String: Any]
        
        switch item.operation {
        case .create, .update:
            // For cache sync, we might send metadata about the cached item
            body = [
                "model": model.modelId,
                "messages": [
                    [
                        "role": "system",
                        "content": "Cache sync operation: \(item.operation.rawValue)"
                    ],
                    [
                        "role": "user",
                        "content": String(data: item.data ?? Data(), encoding: .utf8) ?? ""
                    ]
                ],
                "max_tokens": min(1000, model.maxTokens),
                "temperature": 0.1,
                "metadata": [
                    "cache_key": item.cacheKey,
                    "content_type": item.contentType.rawValue,
                    "priority": item.priority.rawValue
                ]
            ]
            
        case .delete:
            // For delete operations, we might just log or verify
            body = [
                "model": model.modelId,
                "messages": [
                    [
                        "role": "system",
                        "content": "Cache deletion confirmation for key: \(item.cacheKey)"
                    ]
                ],
                "max_tokens": 100,
                "temperature": 0
            ]
            
        case .query:
            // For query operations
            body = [
                "model": model.modelId,
                "messages": [
                    [
                        "role": "user",
                        "content": String(data: item.data ?? Data(), encoding: .utf8) ?? ""
                    ]
                ],
                "max_tokens": model.maxTokens,
                "temperature": 0.7
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    /// Execute request with retry logic
    private func executeWithRetry(_ request: URLRequest, modelId: String, attempt: Int = 0) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenRouterError.invalidResponse
            }
            
            // Update rate limit headers
            updateRateLimitInfo(from: httpResponse, for: modelId)
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
                
            case 429:
                // Rate limited - use exponential backoff
                let delay = calculateBackoffDelay(attempt: attempt, response: httpResponse)
                logger.warning("Rate limited for \(modelId), retrying in \(delay)s")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request, modelId: modelId, attempt: attempt + 1)
                
            case 500...599:
                // Server error - retry with backoff
                if attempt < 3 {
                    let delay = calculateBackoffDelay(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await executeWithRetry(request, modelId: modelId, attempt: attempt + 1)
                }
                throw OpenRouterError.serverError(httpResponse.statusCode)
                
            default:
                // Client error - don't retry
                let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let message = errorData?["error"] as? String ?? "Unknown error"
                throw OpenRouterError.clientError(httpResponse.statusCode, message)
            }
            
        } catch {
            if attempt < 3 && isRetriableError(error) {
                let delay = calculateBackoffDelay(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(request, modelId: modelId, attempt: attempt + 1)
            }
            throw error
        }
    }
    
    /// Calculate backoff delay
    private func calculateBackoffDelay(attempt: Int, response: HTTPURLResponse? = nil) -> Double {
        // Check for Retry-After header
        if let response = response,
           let retryAfter = response.value(forHTTPHeaderField: "Retry-After") {
            if let seconds = Double(retryAfter) {
                return seconds
            }
        }
        
        // Exponential backoff with jitter
        let baseDelay = 1.0
        let maxDelay = 60.0
        let exponentialDelay = min(maxDelay, baseDelay * pow(2.0, Double(attempt)))
        let jitter = Double.random(in: 0...baseDelay)
        
        return exponentialDelay + jitter
    }
    
    /// Check if error is retriable
    private func isRetriableError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .networkConnectionLost, .notConnectedToInternet, .timedOut:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    /// Process API response
    private func processResponse(_ data: Data, for item: OutboxItem) throws -> SyncItemResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Extract response data
        let _ = json?["choices"] as? [[String: Any]]
        let usage = json?["usage"] as? [String: Any]
        
        return SyncItemResult(
            key: item.cacheKey,
            success: true,
            syncedAt: Date(),
            responseData: data,
            tokensUsed: usage?["total_tokens"] as? Int ?? 0
        )
    }
    
    /// Enforce rate limiting
    private func enforceRateLimit(for modelId: String) async throws {
        guard let limit = rateLimits[modelId] else { return }
        
        // Simple rate limiting - in production, use a more sophisticated approach
        let now = Date()
        if let lastRequest = limit.lastRequestTime,
           now.timeIntervalSince(lastRequest) < (60.0 / Double(limit.requestsPerMinute)) {
            let waitTime = (60.0 / Double(limit.requestsPerMinute)) - now.timeIntervalSince(lastRequest)
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        limit.lastRequestTime = now
    }
    
    /// Update rate limit info from response headers
    private func updateRateLimitInfo(from response: HTTPURLResponse, for modelId: String) {
        guard let limit = rateLimits[modelId] else { return }
        
        // Parse OpenRouter rate limit headers
        if let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let remainingInt = Int(remaining) {
            limit.remainingRequests = remainingInt
        }
        
        if let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let resetTime = Double(reset) {
            limit.resetTime = Date(timeIntervalSince1970: resetTime)
        }
    }
    
    /// Build request with token guardrails
    func buildRequestWithGuardrails(
        for item: OutboxItem,
        model: OpenRouterModelConfig
    ) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AIKO-iOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Get appropriate token limit
        let promptText = String(data: item.data ?? Data(), encoding: .utf8) ?? ""
        let tokenLimit = TokenGuardrails.contextAwareTokenLimit(
            modelId: model.modelId,
            role: model.role,
            promptLength: promptText.count,
            urgency: item.priority
        )
        
        // Log token limit decision
        logger.debug("Token limit for \(model.modelId) (\(model.role)): \(tokenLimit) tokens")
        
        // Build request body based on operation
        let body: [String: Any]
        
        switch item.operation {
        case .create, .update:
            body = [
                "model": model.modelId,
                "messages": [
                    [
                        "role": "system",
                        "content": "Cache sync operation: \(item.operation.rawValue). Be concise."
                    ],
                    [
                        "role": "user",
                        "content": promptText
                    ]
                ],
                "max_tokens": min(tokenLimit, 500),  // Conservative for sync ops
                "temperature": 0.1,
                "metadata": [
                    "cache_key": item.cacheKey,
                    "content_type": item.contentType.rawValue,
                    "priority": item.priority.rawValue
                ]
            ]
            
        case .delete:
            body = [
                "model": model.modelId,
                "messages": [
                    [
                        "role": "system",
                        "content": "Confirm cache deletion for key: \(item.cacheKey)"
                    ]
                ],
                "max_tokens": 100,  // Minimal for confirmations
                "temperature": 0
            ]
            
        case .query:
            // Add token usage instruction to system message for cost awareness
            let systemMessage = """
            You are a \(model.role) assistant. Provide a focused response within \(tokenLimit) tokens.
            Be concise while maintaining quality and completeness.
            """
            
            body = [
                "model": model.modelId,
                "messages": [
                    [
                        "role": "system",
                        "content": systemMessage
                    ],
                    [
                        "role": "user",
                        "content": promptText
                    ]
                ],
                "max_tokens": tokenLimit,
                "temperature": temperatureForRole(model.role),
                "top_p": 0.9,
                "frequency_penalty": 0.1,
                "presence_penalty": 0.1
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    /// Get appropriate temperature for role
    private func temperatureForRole(_ role: String) -> Double {
        switch role {
        case "validator", "validator2", "debug":
            return 0.1  // Very deterministic
        case "math_science", "search":
            return 0.3  // Mostly deterministic
        case "complex_reasoning", "codereview":
            return 0.5  // Balanced
        case "chat", "thinkdeep":
            return 0.7  // More creative
        case "codegen", "refactor":
            return 0.6  // Slightly creative
        case "consensus_for", "consensus_against":
            return 0.8  // More varied arguments
        default:
            return 0.5
        }
    }
}

/// Rate limit information
class RateLimitInfo {
    let requestsPerMinute: Int
    let tokensPerMinute: Int
    let concurrentRequests: Int
    var remainingRequests: Int?
    var resetTime: Date?
    var lastRequestTime: Date?
    
    init(requestsPerMinute: Int, tokensPerMinute: Int, concurrentRequests: Int) {
        self.requestsPerMinute = requestsPerMinute
        self.tokensPerMinute = tokensPerMinute
        self.concurrentRequests = concurrentRequests
    }
}

/// Sync item result
struct SyncItemResult {
    let key: String
    let success: Bool
    let syncedAt: Date
    let responseData: Data?
    let tokensUsed: Int
}

/// OpenRouter errors
enum OpenRouterError: LocalizedError {
    case invalidModel(String)
    case invalidResponse
    case serverError(Int)
    case clientError(Int, String)
    case rateLimited(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidModel(let message):
            return "Invalid model: \(message)"
        case .invalidResponse:
            return "Invalid response from OpenRouter"
        case .serverError(let code):
            return "Server error: HTTP \(code)"
        case .clientError(let code, let message):
            return "Client error \(code): \(message)"
        case .rateLimited(let seconds):
            return "Rate limited. Retry after \(seconds) seconds"
        }
    }
}
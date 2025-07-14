//
//  VanillaIce-QuickWin-Optimizations.swift
//  AIKO
//
//  Quick optimization implementations that can be applied immediately
//

import Foundation
import os.log

// MARK: - Quick Win #1: Response Timeout Optimization
extension VanillaIceOperation {
    /// Determine optimal timeout based on operation type
    var optimalTimeout: TimeInterval {
        switch self {
        case .parallelQuery(let prompt):
            // Shorter timeout for simple queries
            return prompt.count < 50 ? 5.0 : 10.0
        case .consensus:
            // Longer timeout for consensus operations
            return 15.0
        case .modelBenchmark:
            // Standard timeout for benchmarks
            return 20.0
        }
    }
}

// MARK: - Quick Win #2: LRU Cache for Recent Queries
actor VanillaIceQuickCache {
    private var cache: [String: (result: VanillaIceResult, timestamp: Date)] = [:]
    private var accessOrder: [String] = []
    private let maxSize = 100
    private let ttl: TimeInterval = 300 // 5 minutes
    
    func get(_ key: String) -> VanillaIceResult? {
        guard let cached = cache[key] else { return nil }
        
        // Check TTL
        if Date().timeIntervalSince(cached.timestamp) > ttl {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
            return nil
        }
        
        // Update access order
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        
        return cached.result
    }
    
    func set(_ key: String, value: VanillaIceResult) {
        // Evict if needed
        if cache.count >= maxSize && cache[key] == nil {
            if let lru = accessOrder.first {
                cache.removeValue(forKey: lru)
                accessOrder.removeFirst()
            }
        }
        
        cache[key] = (value, Date())
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }
}

// MARK: - Quick Win #3: Parallel Consensus Generation
extension SyncEngine {
    /// Optimized consensus with parallel processing
    func executeOptimizedConsensus(
        operation: VanillaIceOperation,
        timeout: TimeInterval? = nil
    ) async throws -> VanillaIceResult {
        
        let effectiveTimeout = timeout ?? operation.optimalTimeout
        let startTime = Date()
        
        switch operation {
        case .consensus(let prompt, let models):
            // Start consensus generation early
            let consensusTask = Task<String, Error> {
                // Collect responses progressively
                var responses: [VanillaIceModelResponse] = []
                let responseStream = createResponseStream(models: models, prompt: prompt)
                
                for await response in responseStream {
                    responses.append(response)
                    
                    // Start preliminary consensus after 3 responses
                    if responses.count == 3 {
                        Task {
                            logger.info("Starting preliminary consensus with \(responses.count) responses")
                        }
                    }
                }
                
                // Generate final consensus
                return try await analyzeOptimizedConsensus(
                    responses: responses,
                    originalPrompt: prompt
                )
            }
            
            // Collect all responses with timeout
            let responses = try await withThrowingTaskGroup(of: VanillaIceModelResponse?.self) { group in
                for model in models {
                    group.addTask {
                        try await self.queryModelWithTimeout(
                            modelId: model.modelId,
                            prompt: self.buildConsensusPrompt(
                                basePrompt: prompt,
                                stance: model.stance,
                                customPrompt: model.customPrompt
                            ),
                            timeout: effectiveTimeout
                        )
                    }
                }
                
                var collected: [VanillaIceModelResponse] = []
                for try await response in group {
                    if let response = response {
                        collected.append(response)
                    }
                }
                return collected
            }
            
            let consensus = try await consensusTask.value
            let duration = Date().timeIntervalSince(startTime)
            
            return VanillaIceResult(
                operation: "optimized_consensus",
                prompt: prompt,
                responses: responses,
                consensus: consensus,
                timestamp: Date(),
                totalDuration: duration
            )
            
        default:
            // Fall back to standard implementation
            return try await executeVanillaIceConsensus(
                operation: operation,
                timeout: effectiveTimeout
            )
        }
    }
    
    /// Create async stream of model responses
    private func createResponseStream(
        models: [VanillaIceModel],
        prompt: String
    ) -> AsyncStream<VanillaIceModelResponse> {
        AsyncStream { continuation in
            Task {
                await withTaskGroup(of: VanillaIceModelResponse?.self) { group in
                    for model in models {
                        group.addTask {
                            try? await self.queryModelWithTimeout(
                                modelId: model.modelId,
                                prompt: self.buildConsensusPrompt(
                                    basePrompt: prompt,
                                    stance: model.stance,
                                    customPrompt: model.customPrompt
                                ),
                                timeout: 10.0
                            )
                        }
                    }
                    
                    for await response in group {
                        if let response = response {
                            continuation.yield(response)
                        }
                    }
                    continuation.finish()
                }
            }
        }
    }
    
    /// Query model with aggressive timeout
    private func queryModelWithTimeout(
        modelId: String,
        prompt: String,
        timeout: TimeInterval
    ) async throws -> VanillaIceModelResponse? {
        let task = Task {
            try await queryModel(
                modelId: modelId,
                prompt: prompt,
                timeout: timeout
            )
        }
        
        // Race between query and timeout
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            task.cancel()
            throw VanillaIceError.timeout(modelId)
        }
        
        do {
            let result = try await task.value
            timeoutTask.cancel()
            return result
        } catch {
            timeoutTask.cancel()
            if error is CancellationError {
                return VanillaIceModelResponse(
                    modelId: modelId,
                    response: nil,
                    error: "Timeout after \(timeout)s",
                    duration: timeout,
                    tokensUsed: 0
                )
            }
            throw error
        }
    }
    
    /// Optimized consensus analysis with caching
    private func analyzeOptimizedConsensus(
        responses: [VanillaIceModelResponse],
        originalPrompt: String
    ) async throws -> String {
        // Use a more efficient prompt
        let efficientPrompt = """
        Analyze these \(responses.count) model responses and provide a concise consensus:
        
        \(responses.map { "\($0.modelId): \($0.response ?? "No response")" }.joined(separator: "\n---\n"))
        
        Provide:
        1. Key agreements (bullet points)
        2. Major disagreements (if any)
        3. Consensus conclusion (2-3 sentences)
        
        Be concise and focus on actionable insights.
        """
        
        // Use fast model for consensus
        let consensusResponse = try await queryModel(
            modelId: "google/gemini-2.5-flash-preview", // Fast model
            prompt: efficientPrompt,
            timeout: 5.0,
            role: "fast_chat"
        )
        
        return consensusResponse.response ?? "Failed to generate consensus"
    }
}

// MARK: - Quick Win #4: Smart Retry with Fallback Models
extension OpenRouterSyncAdapter {
    /// Execute with smart fallback to alternative models
    func syncCacheItemWithFallback(_ item: OutboxItem) async throws -> SyncItemResult {
        let primaryModelId = getModelForRole(item.syncRole ?? "chat")?.modelId ?? "openai/gpt-4o-mini"
        
        // Try primary model
        do {
            return try await syncCacheItem(item)
        } catch {
            logger.warning("Primary model \(primaryModelId) failed, trying fallback")
            
            // Determine fallback based on role
            let fallbackRole = getFallbackRole(for: item.syncRole ?? "chat")
            var fallbackItem = item
            fallbackItem.syncRole = fallbackRole
            
            // Try fallback
            return try await syncCacheItem(fallbackItem)
        }
    }
    
    /// Get fallback role for a given role
    private func getFallbackRole(for role: String) -> String {
        switch role {
        case "chat": return "fast_chat"
        case "thinkdeep": return "complex_reasoning"
        case "validator": return "validator2"
        case "codegen": return "refactor"
        case "search": return "chat"
        default: return "validator"
        }
    }
}

// MARK: - Error Types
enum VanillaIceError: LocalizedError {
    case timeout(String)
    case noResponses
    case consensusFailed
    
    var errorDescription: String? {
        switch self {
        case .timeout(let model):
            return "Model \(model) timed out"
        case .noResponses:
            return "No models responded"
        case .consensusFailed:
            return "Failed to generate consensus"
        }
    }
}

// MARK: - Usage Example
/*
// Using optimized consensus
let operation = VanillaIceOperation.consensus(
    prompt: "Should we implement these optimizations?",
    models: [
        VanillaIceModel(modelId: "google/gemini-2.5-pro", stance: .for, customPrompt: nil),
        VanillaIceModel(modelId: "openai/gpt-4o-mini", stance: .against, customPrompt: nil)
    ]
)

let result = try await syncEngine.executeOptimizedConsensus(
    operation: operation,
    timeout: 8.0 // Aggressive timeout
)
*/
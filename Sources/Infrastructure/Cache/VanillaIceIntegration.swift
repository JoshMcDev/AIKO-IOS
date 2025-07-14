//
//  VanillaIceIntegration.swift
//  AIKO
//
//  Created for VanillaIce consensus integration with SyncEngine
//

import Foundation
import os.log

/// VanillaIce consensus operation types
enum VanillaIceOperation {
    case consensus(prompt: String, models: [VanillaIceModel])
    case parallelQuery(prompt: String)
    case modelBenchmark(prompt: String)
}

/// Model configuration for VanillaIce
struct VanillaIceModel {
    let modelId: String
    let stance: ConsensusStance
    let customPrompt: String?
}

/// Consensus stance for models
enum ConsensusStance: String {
    case `for` = "for"
    case against = "against"
    case neutral = "neutral"
}

/// Extension for VanillaIce consensus operations
extension SyncEngine {
    
    /// Execute VanillaIce consensus operation
    func executeVanillaIceConsensus(
        operation: VanillaIceOperation,
        timeout: TimeInterval = 60
    ) async throws -> VanillaIceResult {
        
        let logger = Logger(subsystem: "com.aiko.cache", category: "VanillaIce")
        logger.info("Starting VanillaIce operation")
        
        switch operation {
        case .consensus(let prompt, let models):
            return try await performConsensus(prompt: prompt, models: models, timeout: timeout)
            
        case .parallelQuery(let prompt):
            return try await performParallelQuery(prompt: prompt, timeout: timeout)
            
        case .modelBenchmark(let prompt):
            return try await performModelBenchmark(prompt: prompt, timeout: timeout)
        }
    }
    
    /// Perform consensus analysis with specified models
    private func performConsensus(
        prompt: String,
        models: [VanillaIceModel],
        timeout: TimeInterval
    ) async throws -> VanillaIceResult {
        
        let logger = Logger(subsystem: "com.aiko.cache", category: "VanillaIce.Consensus")
        var responses: [VanillaIceModelResponse] = []
        
        // Create parallel tasks for each model
        await withTaskGroup(of: VanillaIceModelResponse?.self) { group in
            for model in models {
                group.addTask {
                    do {
                        return try await self.queryModel(
                            modelId: model.modelId,
                            prompt: self.buildConsensusPrompt(
                                basePrompt: prompt,
                                stance: model.stance,
                                customPrompt: model.customPrompt
                            ),
                            timeout: timeout
                        )
                    } catch {
                        logger.error("Failed to query model \(model.modelId): \(error)")
                        return VanillaIceModelResponse(
                            modelId: model.modelId,
                            response: nil,
                            error: error.localizedDescription,
                            duration: 0,
                            tokensUsed: 0
                        )
                    }
                }
            }
            
            // Collect results
            for await response in group {
                if let response = response {
                    responses.append(response)
                }
            }
        }
        
        // Generate consensus analysis
        let consensus = try await analyzeConsensus(responses: responses, originalPrompt: prompt)
        
        return VanillaIceResult(
            operation: "consensus",
            prompt: prompt,
            responses: responses,
            consensus: consensus,
            timestamp: Date(),
            totalDuration: responses.reduce(0) { max($0, $1.duration) }
        )
    }
    
    /// Perform parallel query with all available models
    private func performParallelQuery(
        prompt: String,
        timeout: TimeInterval
    ) async throws -> VanillaIceResult {
        
        // Define all available models with their optimal roles
        let modelConfigs = [
            ("x-ai/grok-4", "chat"),
            ("google/gemini-2.5-pro", "thinkdeep"),
            ("google/gemini-2.5-flash-preview", "fast_chat"),
            ("deepseek/deepseek-chat", "complex_reasoning"),
            ("openai/gpt-4o-2024-08-06", "debug"),
            ("openai/gpt-4o-mini", "validator"),
            ("google/gemini-2.0-flash-exp", "validator2"),
            ("tngtech/deepseek-r1t-chimera:free", "codereview"),
            ("qwen/qwen-2.5-coder-32b-instruct", "codegen"),
            ("mistralai/mixtral-8x22b-instruct", "refactor"),
            ("cohere/command-r-plus", "consensus_for"),
            ("meta-llama/llama-3.3-70b-instruct", "consensus_against"),
            ("qwen/qwq-32b-preview", "math_science"),
            ("openai/gpt-4o-search-preview", "search")
        ]
        
        var responses: [VanillaIceModelResponse] = []
        
        await withTaskGroup(of: VanillaIceModelResponse?.self) { group in
            for (modelId, role) in modelConfigs {
                group.addTask {
                    do {
                        return try await self.queryModel(
                            modelId: modelId,
                            prompt: prompt,
                            timeout: timeout,
                            role: role
                        )
                    } catch {
                        return VanillaIceModelResponse(
                            modelId: modelId,
                            response: nil,
                            error: error.localizedDescription,
                            duration: 0,
                            tokensUsed: 0
                        )
                    }
                }
            }
            
            for await response in group {
                if let response = response {
                    responses.append(response)
                }
            }
        }
        
        return VanillaIceResult(
            operation: "parallel_query",
            prompt: prompt,
            responses: responses,
            consensus: nil,
            timestamp: Date(),
            totalDuration: responses.reduce(0) { max($0, $1.duration) }
        )
    }
    
    /// Perform model benchmark
    private func performModelBenchmark(
        prompt: String,
        timeout: TimeInterval
    ) async throws -> VanillaIceResult {
        
        let result = try await performParallelQuery(prompt: prompt, timeout: timeout)
        
        // Add benchmark analysis
        let benchmarkData = analyzeBenchmarkData(responses: result.responses)
        
        return VanillaIceResult(
            operation: "benchmark",
            prompt: prompt,
            responses: result.responses,
            consensus: benchmarkData,
            timestamp: Date(),
            totalDuration: result.totalDuration
        )
    }
    
    /// Query individual model
    private func queryModel(
        modelId: String,
        prompt: String,
        timeout: TimeInterval,
        role: String? = nil
    ) async throws -> VanillaIceModelResponse {
        
        let startTime = Date()
        
        // Determine role if not provided
        let effectiveRole = role ?? determineRoleForModel(modelId)
        
        // Create outbox item for the query with role
        let queryData = prompt.data(using: .utf8)!
        let item = OutboxItem(
            cacheKey: "vanillaice_\(UUID().uuidString)",
            operation: .query,
            data: queryData,
            contentType: .llmResponse,
            priority: .urgent,
            syncRole: effectiveRole
        )
        
        // Use OpenRouter adapter to query the model
        guard let adapter = openRouterAdapter else {
            throw SyncError.networkError("OpenRouter adapter not available")
        }
        
        let result = try await adapter.syncCacheItem(item)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Parse response
        let responseText: String?
        var tokensUsed = result.tokensUsed
        
        if let responseData = result.responseData,
           let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            responseText = content
            
            // Get actual token usage from response
            if let usage = json["usage"] as? [String: Any] {
                tokensUsed = usage["total_tokens"] as? Int ?? result.tokensUsed
            }
            
            // Log token usage vs limits
            let tokenLimit = TokenGuardrails.maxTokens(for: modelId, role: effectiveRole)
            let vanillaLogger = Logger(subsystem: "com.aiko.cache", category: "VanillaIce")
            vanillaLogger.info("Model \(modelId) used \(tokensUsed) tokens (limit: \(tokenLimit))")
        } else {
            responseText = nil
        }
        
        return VanillaIceModelResponse(
            modelId: modelId,
            response: responseText,
            error: result.success ? nil : "Failed to get response",
            duration: duration,
            tokensUsed: tokensUsed
        )
    }
    
    /// Determine role for a model ID
    private func determineRoleForModel(_ modelId: String) -> String {
        // Map model IDs to their roles
        switch modelId {
        case "x-ai/grok-4": return "chat"
        case "google/gemini-2.5-pro": return "thinkdeep"
        case "google/gemini-2.5-flash-preview": return "fast_chat"
        case "deepseek/deepseek-chat": return "complex_reasoning"
        case "openai/gpt-4o-2024-08-06": return "debug"
        case "openai/gpt-4o-mini": return "validator"
        case "google/gemini-2.0-flash-exp": return "validator2"
        case "tngtech/deepseek-r1t-chimera:free": return "codereview"
        case "qwen/qwen-2.5-coder-32b-instruct": return "codegen"
        case "mistralai/mixtral-8x22b-instruct": return "refactor"
        case "cohere/command-r-plus": return "consensus_for"
        case "meta-llama/llama-3.3-70b-instruct": return "consensus_against"
        case "qwen/qwq-32b-preview": return "math_science"
        case "openai/gpt-4o-search-preview": return "search"
        default: return "chat"
        }
    }
    
    /// Build consensus prompt with stance
    private func buildConsensusPrompt(
        basePrompt: String,
        stance: ConsensusStance,
        customPrompt: String?
    ) -> String {
        
        let stancePrompt: String
        switch stance {
        case .for:
            stancePrompt = "Please analyze this proposal and provide arguments IN FAVOR of it. Focus on benefits, advantages, and positive outcomes."
        case .against:
            stancePrompt = "Please analyze this proposal and provide arguments AGAINST it. Focus on risks, disadvantages, and potential problems."
        case .neutral:
            stancePrompt = "Please analyze this proposal objectively, considering both benefits and drawbacks equally."
        }
        
        if let custom = customPrompt {
            return "\(stancePrompt)\n\n\(custom)\n\nProposal: \(basePrompt)"
        } else {
            return "\(stancePrompt)\n\nProposal: \(basePrompt)"
        }
    }
    
    /// Analyze consensus from model responses
    private func analyzeConsensus(
        responses: [VanillaIceModelResponse],
        originalPrompt: String
    ) async throws -> String {
        
        let successfulResponses = responses.filter { $0.response != nil }
        
        guard !successfulResponses.isEmpty else {
            return "No successful model responses to analyze for consensus."
        }
        
        // Use the thinkdeep model for consensus analysis
        let analysisPrompt = """
        Analyze the following model responses and provide a consensus summary:
        
        Original Query: \(originalPrompt)
        
        Model Responses:
        \(successfulResponses.map { "Model \($0.modelId): \($0.response ?? "No response")" }.joined(separator: "\n\n"))
        
        Please provide:
        1. Points of agreement across models
        2. Points of disagreement or unique insights
        3. Overall consensus recommendation
        4. Key considerations and caveats
        """
        
        let analysisResponse = try await queryModel(
            modelId: "google/gemini-2.5-pro",
            prompt: analysisPrompt,
            timeout: 30,
            role: "thinkdeep"
        )
        
        return analysisResponse.response ?? "Failed to generate consensus analysis"
    }
    
    /// Analyze benchmark data
    private func analyzeBenchmarkData(responses: [VanillaIceModelResponse]) -> String {
        let successCount = responses.filter { $0.response != nil }.count
        let avgDuration = responses.reduce(0.0) { $0 + $1.duration } / Double(responses.count)
        let totalTokens = responses.reduce(0) { $0 + $1.tokensUsed }
        
        let fastest = responses.min(by: { $0.duration < $1.duration })
        let slowest = responses.max(by: { $0.duration < $1.duration })
        
        return """
        Benchmark Results:
        - Total Models Queried: \(responses.count)
        - Successful Responses: \(successCount)
        - Average Response Time: \(String(format: "%.2f", avgDuration))s
        - Total Tokens Used: \(totalTokens)
        - Fastest Model: \(fastest?.modelId ?? "N/A") (\(String(format: "%.2f", fastest?.duration ?? 0))s)
        - Slowest Model: \(slowest?.modelId ?? "N/A") (\(String(format: "%.2f", slowest?.duration ?? 0))s)
        
        Model Performance:
        \(responses.sorted(by: { $0.duration < $1.duration }).map { 
            "- \($0.modelId): \(String(format: "%.2f", $0.duration))s (\($0.tokensUsed) tokens)"
        }.joined(separator: "\n"))
        """
    }
}

/// VanillaIce model response
struct VanillaIceModelResponse {
    let modelId: String
    let response: String?
    let error: String?
    let duration: TimeInterval
    let tokensUsed: Int
}

/// VanillaIce operation result
struct VanillaIceResult {
    let operation: String
    let prompt: String
    let responses: [VanillaIceModelResponse]
    let consensus: String?
    let timestamp: Date
    let totalDuration: TimeInterval
    
    /// Get successful response count
    var successCount: Int {
        responses.filter { $0.response != nil }.count
    }
    
    /// Get failure count
    var failureCount: Int {
        responses.filter { $0.response == nil }.count
    }
    
    /// Format result for display
    func formatForDisplay() -> String {
        var output = """
        🍦 VanillaIce \(operation.capitalized) Results
        ============================================
        
        Query: \(prompt)
        
        Model Responses (\(successCount)/\(responses.count) successful):
        """
        
        for response in responses {
            output += "\n\n📍 \(response.modelId)"
            if let content = response.response {
                output += "\n\(content)"
            } else if let error = response.error {
                output += "\n⚠️ Error: \(error)"
            }
        }
        
        if let consensus = consensus {
            output += "\n\n" + String(repeating: "─", count: 72)
            output += "\nCONSENSUS ANALYSIS"
            output += "\n" + String(repeating: "─", count: 72)
            output += "\n\(consensus)"
        }
        
        output += "\n\n" + String(repeating: "═", count: 72)
        output += "\nExecution Time: \(String(format: "%.2f", totalDuration))s"
        
        return output
    }
}
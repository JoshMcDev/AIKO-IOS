//
//  TokenGuardrails.swift
//  AIKO
//
//  Token limit guardrails for VanillaIce OpenRouter models
//

import Foundation
import os.log

/// Token limit configuration for each model role
struct TokenGuardrails {
    
    /// Get optimal max tokens for a model based on its role and use case
    static func maxTokens(for modelId: String, role: String, operation: SyncOperation = .query) -> Int {
        // Special cases for specific operations
        switch operation {
        case .delete:
            return 100  // Minimal tokens for deletion confirmations
        case .create, .update:
            return 500  // Moderate tokens for sync operations
        case .query:
            // Continue to role-based limits
            break
        }
        
        // Role-based token limits optimized for cost and effectiveness
        switch role {
        case "chat":
            // General conversation - balanced response length
            return 1000
            
        case "thinkdeep":
            // Deep analysis - needs more space for comprehensive responses
            return 2000
            
        case "fast_chat":
            // Quick responses - keep it concise
            return 500
            
        case "complex_reasoning":
            // Step-by-step reasoning - needs space for process
            return 1500
            
        case "debug":
            // Technical debugging - moderate detail needed
            return 1000
            
        case "validator", "validator2":
            // Quick validation - concise yes/no with brief explanation
            return 300
            
        case "codereview":
            // Code review - needs space for detailed feedback
            return 1500
            
        case "codegen":
            // Code generation - needs space for implementation
            return 2000
            
        case "refactor":
            // Code refactoring - similar to codegen
            return 1500
            
        case "consensus_for", "consensus_against":
            // Argumentation - needs space for reasoning
            return 1000
            
        case "math_science":
            // Mathematical/scientific explanation - moderate detail
            return 1000
            
        case "search":
            // Search results with citations - needs space for results
            return 1500
            
        default:
            // Default fallback - conservative limit
            return 800
        }
    }
    
    /// Get token limit with context-aware adjustments
    static func contextAwareTokenLimit(
        modelId: String,
        role: String,
        promptLength: Int,
        urgency: SyncPriority = .normal
    ) -> Int {
        let baseLimit = maxTokens(for: modelId, role: role)
        
        // Adjust based on prompt length (longer prompts may need longer responses)
        let promptAdjustment: Double
        switch promptLength {
        case 0..<100:
            promptAdjustment = 0.8  // Short prompt, likely needs short response
        case 100..<500:
            promptAdjustment = 1.0  // Normal prompt
        case 500..<1000:
            promptAdjustment = 1.2  // Longer prompt may need more detailed response
        default:
            promptAdjustment = 1.5  // Very long prompt, likely complex topic
        }
        
        // Adjust based on urgency (urgent = shorter for speed)
        let urgencyAdjustment: Double
        switch urgency {
        case .urgent:
            urgencyAdjustment = 0.7  // Prioritize speed
        case .high:
            urgencyAdjustment = 0.85
        case .normal:
            urgencyAdjustment = 1.0
        case .low:
            urgencyAdjustment = 1.2  // Can take more time
        }
        
        let adjustedLimit = Double(baseLimit) * promptAdjustment * urgencyAdjustment
        
        // Apply bounds
        let minTokens = 100
        let maxTokens = 3000  // Hard upper limit for cost control
        
        return max(minTokens, min(maxTokens, Int(adjustedLimit)))
    }
    
    /// Cost estimation based on token usage
    static func estimateCost(
        modelId: String,
        promptTokens: Int,
        completionTokens: Int
    ) -> (input: Double, output: Double, total: Double) {
        // Approximate costs per 1M tokens (varies by model)
        let costPer1MTokens: (input: Double, output: Double)
        
        switch modelId {
        case "x-ai/grok-4":
            costPer1MTokens = (15.0, 60.0)
        case "google/gemini-2.5-pro":
            costPer1MTokens = (2.5, 10.0)
        case "google/gemini-2.5-flash-preview", "google/gemini-2.0-flash-exp":
            costPer1MTokens = (0.075, 0.3)
        case "deepseek/deepseek-chat":
            costPer1MTokens = (0.14, 0.28)
        case "openai/gpt-4o-2024-08-06", "openai/gpt-4o-search-preview":
            costPer1MTokens = (2.5, 10.0)
        case "openai/gpt-4o-mini":
            costPer1MTokens = (0.15, 0.6)
        case "tngtech/deepseek-r1t-chimera:free":
            costPer1MTokens = (0.0, 0.0)  // Free model
        case "qwen/qwen-2.5-coder-32b-instruct", "qwen/qwq-32b-preview":
            costPer1MTokens = (0.18, 0.18)
        case "mistralai/mixtral-8x22b-instruct":
            costPer1MTokens = (0.9, 2.7)
        case "cohere/command-r-plus":
            costPer1MTokens = (2.5, 10.0)
        case "meta-llama/llama-3.3-70b-instruct":
            costPer1MTokens = (0.35, 0.4)
        default:
            costPer1MTokens = (1.0, 4.0)  // Conservative estimate
        }
        
        let inputCost = (Double(promptTokens) / 1_000_000) * costPer1MTokens.input
        let outputCost = (Double(completionTokens) / 1_000_000) * costPer1MTokens.output
        
        return (inputCost, outputCost, inputCost + outputCost)
    }
}


// MARK: - Token Limit Recommendations
/*
Based on analysis, here are the token guardrails I recommend:

1. **Validators** (300 tokens)
   - Quick yes/no responses with brief explanations
   - Cost-effective for high-volume validation

2. **Fast Chat** (500 tokens)  
   - Rapid responses for simple queries
   - Optimized for speed over depth

3. **General Chat** (1000 tokens)
   - Balanced conversational responses
   - Good for most interactions

4. **Complex Reasoning** (1500 tokens)
   - Space for step-by-step explanations
   - Critical for debugging and analysis

5. **Code Generation** (2000 tokens)
   - Sufficient for most code implementations
   - Highest limit due to code verbosity

6. **Deep Thinking** (2000 tokens)
   - Comprehensive analysis and exploration
   - For when depth matters more than cost

These limits balance:
- Cost control (reducing unnecessary token usage)
- Response quality (ensuring sufficient detail)
- User experience (appropriate response lengths)
- Model strengths (optimized for each role)

The contextual adjustments further optimize based on:
- Prompt length (longer prompts → longer responses)
- Urgency (urgent → shorter for speed)
- Operation type (sync ops → minimal tokens)
*/
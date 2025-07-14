//
//  SyncEngineOptimizer.swift
//  AIKO
//
//  Performance optimization helper for SyncEngine and VanillaIce operations
//

import Foundation
import os.log

/// Analyzes and optimizes SyncEngine performance based on test results
actor SyncEngineOptimizer {
    
    private let logger = Logger(subsystem: "com.aiko.cache", category: "SyncOptimizer")
    
    /// Model performance metrics
    struct ModelMetrics {
        let modelId: String
        var totalRequests: Int = 0
        var successfulRequests: Int = 0
        var totalDuration: TimeInterval = 0
        var totalTokens: Int = 0
        var errors: [String] = []
        var lastRequestTime: Date?
        
        var averageResponseTime: TimeInterval {
            totalRequests > 0 ? totalDuration / Double(totalRequests) : 0
        }
        
        var successRate: Double {
            totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 0
        }
        
        var tokensPerSecond: Double {
            totalDuration > 0 ? Double(totalTokens) / totalDuration : 0
        }
    }
    
    /// Performance recommendations
    struct OptimizationRecommendations {
        let modelAdjustments: [ModelAdjustment]
        let rateLimitChanges: [RateLimitChange]
        let retryStrategyUpdates: [RetryStrategyUpdate]
        let cacheOptimizations: [CacheOptimization]
    }
    
    struct ModelAdjustment {
        let modelId: String
        let recommendation: String
        let priority: OptimizationPriority
    }
    
    struct RateLimitChange {
        let modelId: String
        let currentLimit: Int
        let recommendedLimit: Int
        let reason: String
    }
    
    struct RetryStrategyUpdate {
        let modelId: String
        let currentStrategy: String
        let recommendedStrategy: String
        let expectedImprovement: String
    }
    
    struct CacheOptimization {
        let area: String
        let recommendation: String
        let impact: String
    }
    
    enum OptimizationPriority: String {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }
    
    /// Collected metrics for all models
    private var modelMetrics: [String: ModelMetrics] = [:]
    
    /// Initialize optimizer with existing metrics
    init(existingMetrics: [String: ModelMetrics]? = nil) {
        if let metrics = existingMetrics {
            self.modelMetrics = metrics
        } else {
            // Initialize with all 14 models
            let modelIds = [
                "x-ai/grok-4",
                "google/gemini-2.5-pro",
                "google/gemini-2.5-flash-preview",
                "deepseek/deepseek-chat",
                "openai/gpt-4o-2024-08-06",
                "openai/gpt-4o-mini",
                "google/gemini-2.0-flash-exp",
                "tngtech/deepseek-r1t-chimera:free",
                "qwen/qwen-2.5-coder-32b-instruct",
                "mistralai/mixtral-8x22b-instruct",
                "cohere/command-r-plus",
                "meta-llama/llama-3.3-70b-instruct",
                "qwen/qwq-32b-preview",
                "openai/gpt-4o-search-preview"
            ]
            
            for modelId in modelIds {
                modelMetrics[modelId] = ModelMetrics(modelId: modelId)
            }
        }
    }
    
    /// Record metrics from a VanillaIce result
    func recordMetrics(from result: VanillaIceResult) {
        for response in result.responses {
            guard var metrics = modelMetrics[response.modelId] else { continue }
            
            metrics.totalRequests += 1
            if response.response != nil {
                metrics.successfulRequests += 1
            } else if let error = response.error {
                metrics.errors.append(error)
            }
            
            metrics.totalDuration += response.duration
            metrics.totalTokens += response.tokensUsed
            metrics.lastRequestTime = Date()
            
            modelMetrics[response.modelId] = metrics
        }
        
        logger.info("Recorded metrics for \(result.responses.count) model responses")
    }
    
    /// Analyze performance and generate recommendations
    func analyzePerformance() -> OptimizationRecommendations {
        var modelAdjustments: [ModelAdjustment] = []
        var rateLimitChanges: [RateLimitChange] = []
        var retryStrategyUpdates: [RetryStrategyUpdate] = []
        var cacheOptimizations: [CacheOptimization] = []
        
        // Analyze each model's performance
        for (modelId, metrics) in modelMetrics {
            // Model reliability analysis
            if metrics.successRate < 0.5 && metrics.totalRequests > 5 {
                modelAdjustments.append(ModelAdjustment(
                    modelId: modelId,
                    recommendation: "Consider deprioritizing this model due to low success rate (\(String(format: "%.1f%%", metrics.successRate * 100)))",
                    priority: .high
                ))
            }
            
            // Response time analysis
            if metrics.averageResponseTime > 10.0 {
                modelAdjustments.append(ModelAdjustment(
                    modelId: modelId,
                    recommendation: "Model has slow response time (\(String(format: "%.1f", metrics.averageResponseTime))s). Consider using for non-time-critical operations only.",
                    priority: .medium
                ))
                
                // Suggest different retry strategy for slow models
                retryStrategyUpdates.append(RetryStrategyUpdate(
                    modelId: modelId,
                    currentStrategy: "Standard exponential backoff",
                    recommendedStrategy: "Aggressive timeout (5s) with immediate failover to faster model",
                    expectedImprovement: "Reduce waiting time by up to \(String(format: "%.0f", (metrics.averageResponseTime - 5) * 100))%"
                ))
            }
            
            // Token efficiency analysis
            if metrics.tokensPerSecond < 100 && metrics.totalTokens > 1000 {
                modelAdjustments.append(ModelAdjustment(
                    modelId: modelId,
                    recommendation: "Low token throughput (\(String(format: "%.0f", metrics.tokensPerSecond)) tokens/s). Best for short prompts only.",
                    priority: .low
                ))
            }
            
            // Error pattern analysis
            let rateLimitErrors = metrics.errors.filter { $0.contains("rate") || $0.contains("429") }
            if Double(rateLimitErrors.count) / Double(metrics.totalRequests) > 0.2 {
                rateLimitChanges.append(RateLimitChange(
                    modelId: modelId,
                    currentLimit: 60, // Assuming default
                    recommendedLimit: 30,
                    reason: "High rate limit error rate (\(rateLimitErrors.count) errors)"
                ))
            }
        }
        
        // Overall system optimizations
        let totalRequests = modelMetrics.values.reduce(0) { $0 + $1.totalRequests }
        let totalSuccesses = modelMetrics.values.reduce(0) { $0 + $1.successfulRequests }
        let overallSuccessRate = totalRequests > 0 ? Double(totalSuccesses) / Double(totalRequests) : 0
        
        if overallSuccessRate < 0.8 {
            cacheOptimizations.append(CacheOptimization(
                area: "Fallback Strategy",
                recommendation: "Implement local fallback for critical operations when API success rate is low",
                impact: "Improve reliability by \(String(format: "%.0f%%", (1.0 - overallSuccessRate) * 100))"
            ))
        }
        
        // Identify best performing models for each role
        let roleRecommendations = generateRoleRecommendations()
        for rec in roleRecommendations {
            modelAdjustments.append(rec)
        }
        
        // Cache optimization based on response patterns
        cacheOptimizations.append(CacheOptimization(
            area: "Response Caching",
            recommendation: "Cache frequent queries with TTL based on content type. LLM responses: 1 hour, Search results: 15 minutes",
            impact: "Reduce API calls by estimated 30-40% for repeated queries"
        ))
        
        cacheOptimizations.append(CacheOptimization(
            area: "Batch Processing",
            recommendation: "Implement query batching for consensus operations to reduce connection overhead",
            impact: "Improve throughput by 20-30% for multi-model operations"
        ))
        
        return OptimizationRecommendations(
            modelAdjustments: modelAdjustments,
            rateLimitChanges: rateLimitChanges,
            retryStrategyUpdates: retryStrategyUpdates,
            cacheOptimizations: cacheOptimizations
        )
    }
    
    /// Generate role-based model recommendations
    private func generateRoleRecommendations() -> [ModelAdjustment] {
        var recommendations: [ModelAdjustment] = []
        
        // Find best model for each role based on metrics
        let roleAssignments: [(role: String, models: [String])] = [
            ("chat", ["x-ai/grok-4", "google/gemini-2.5-flash-preview"]),
            ("thinkdeep", ["google/gemini-2.5-pro", "deepseek/deepseek-chat"]),
            ("validator", ["openai/gpt-4o-mini", "google/gemini-2.0-flash-exp"]),
            ("codegen", ["qwen/qwen-2.5-coder-32b-instruct", "openai/gpt-4o-2024-08-06"]),
            ("search", ["openai/gpt-4o-search-preview", "google/gemini-2.5-pro"])
        ]
        
        for (role, candidateModels) in roleAssignments {
            let bestModel = candidateModels
                .compactMap { model in modelMetrics[model] }
                .max(by: { scoreModel($0) < scoreModel($1) })
            
            if let best = bestModel {
                recommendations.append(ModelAdjustment(
                    modelId: best.modelId,
                    recommendation: "Optimal model for '\(role)' role based on performance metrics",
                    priority: .medium
                ))
            }
        }
        
        return recommendations
    }
    
    /// Score a model based on multiple factors
    private func scoreModel(_ metrics: ModelMetrics) -> Double {
        let reliabilityScore = metrics.successRate * 100
        let speedScore = max(0, 100 - metrics.averageResponseTime * 10)
        let efficiencyScore = min(100, metrics.tokensPerSecond / 10)
        
        // Weighted average
        return reliabilityScore * 0.5 + speedScore * 0.3 + efficiencyScore * 0.2
    }
    
    /// Generate optimization report
    func generateReport() -> String {
        let recommendations = analyzePerformance()
        
        var report = """
        ═══════════════════════════════════════════════════════════════
                     SyncEngine Performance Optimization Report
        ═══════════════════════════════════════════════════════════════
        
        Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))
        
        """
        
        // Model Performance Summary
        report += "\n📊 MODEL PERFORMANCE SUMMARY\n"
        report += String(repeating: "─", count: 60) + "\n\n"
        
        let sortedMetrics = modelMetrics.values.sorted { scoreModel($0) > scoreModel($1) }
        
        for (index, metrics) in sortedMetrics.enumerated() {
            let score = scoreModel(metrics)
            let medal = index < 3 ? ["🥇", "🥈", "🥉"][index] : "  "
            
            report += "\(medal) \(metrics.modelId)\n"
            report += "   Score: \(String(format: "%.1f", score))/100"
            report += " | Success: \(String(format: "%.1f%%", metrics.successRate * 100))"
            report += " | Avg Time: \(String(format: "%.2fs", metrics.averageResponseTime))"
            report += " | Tokens/s: \(String(format: "%.0f", metrics.tokensPerSecond))\n\n"
        }
        
        // Model Adjustments
        if !recommendations.modelAdjustments.isEmpty {
            report += "\n🔧 MODEL ADJUSTMENTS\n"
            report += String(repeating: "─", count: 60) + "\n\n"
            
            for adjustment in recommendations.modelAdjustments.sorted(by: { $0.priority.rawValue < $1.priority.rawValue }) {
                report += "[\(adjustment.priority.rawValue)] \(adjustment.modelId)\n"
                report += "    → \(adjustment.recommendation)\n\n"
            }
        }
        
        // Rate Limit Changes
        if !recommendations.rateLimitChanges.isEmpty {
            report += "\n⚡ RATE LIMIT OPTIMIZATIONS\n"
            report += String(repeating: "─", count: 60) + "\n\n"
            
            for change in recommendations.rateLimitChanges {
                report += "• \(change.modelId)\n"
                report += "  Current: \(change.currentLimit) req/min → Recommended: \(change.recommendedLimit) req/min\n"
                report += "  Reason: \(change.reason)\n\n"
            }
        }
        
        // Retry Strategy Updates
        if !recommendations.retryStrategyUpdates.isEmpty {
            report += "\n🔄 RETRY STRATEGY UPDATES\n"
            report += String(repeating: "─", count: 60) + "\n\n"
            
            for update in recommendations.retryStrategyUpdates {
                report += "• \(update.modelId)\n"
                report += "  From: \(update.currentStrategy)\n"
                report += "  To: \(update.recommendedStrategy)\n"
                report += "  Impact: \(update.expectedImprovement)\n\n"
            }
        }
        
        // Cache Optimizations
        if !recommendations.cacheOptimizations.isEmpty {
            report += "\n💾 CACHE OPTIMIZATIONS\n"
            report += String(repeating: "─", count: 60) + "\n\n"
            
            for optimization in recommendations.cacheOptimizations {
                report += "• \(optimization.area)\n"
                report += "  → \(optimization.recommendation)\n"
                report += "  Impact: \(optimization.impact)\n\n"
            }
        }
        
        // Implementation Priority
        report += "\n🎯 IMPLEMENTATION PRIORITY\n"
        report += String(repeating: "─", count: 60) + "\n\n"
        report += "1. Adjust rate limits for frequently rate-limited models\n"
        report += "2. Implement aggressive timeouts for slow models\n"
        report += "3. Optimize role assignments based on performance data\n"
        report += "4. Add response caching for common queries\n"
        report += "5. Implement batch processing for consensus operations\n"
        
        report += "\n" + String(repeating: "═", count: 60) + "\n"
        
        return report
    }
}

// MARK: - Integration with SyncEngine
extension SyncEngine {
    
    /// Run performance analysis and return optimization report
    func analyzePerformance() async -> String {
        let optimizer = SyncEngineOptimizer()
        
        // In a real implementation, we would collect historical metrics
        // For now, return a template report
        return await optimizer.generateReport()
    }
    
    /// Apply optimization recommendations
    func applyOptimizations(_ recommendations: SyncEngineOptimizer.OptimizationRecommendations) async {
        let optimizationLogger = Logger(subsystem: "com.aiko.cache", category: "SyncEngine.Optimization")
        optimizationLogger.info("Applying \(recommendations.modelAdjustments.count) model adjustments")
        optimizationLogger.info("Applying \(recommendations.rateLimitChanges.count) rate limit changes")
        optimizationLogger.info("Applying \(recommendations.retryStrategyUpdates.count) retry strategy updates")
        
        // Implementation would update the actual configurations
        // This is a placeholder for the optimization logic
    }
}
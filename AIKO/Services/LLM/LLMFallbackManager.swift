//
//  LLMFallbackManager.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation
import os.log

/// Manages fallback logic and provider health monitoring
final class LLMFallbackManager {
    // MARK: - Properties

    /// Provider health status tracking
    private var providerHealth: [LLMProvider: ProviderHealth] = [:]

    /// Queue for thread-safe access
    private let healthQueue = DispatchQueue(label: "com.aiko.llm.health", attributes: .concurrent)

    /// Logger for fallback events
    private let logger = Logger(subsystem: "com.aiko", category: "LLMFallback")

    /// Health check interval (5 minutes)
    private let healthCheckInterval: TimeInterval = 300

    /// Health check timer
    private var healthCheckTimer: Timer?

    // MARK: - Provider Health

    struct ProviderHealth {
        let provider: LLMProvider
        var isHealthy: Bool
        var lastSuccessTime: Date?
        var lastFailureTime: Date?
        var consecutiveFailures: Int
        var totalRequests: Int
        var totalFailures: Int
        var averageResponseTime: TimeInterval
        var lastHealthCheck: Date

        var successRate: Double {
            guard totalRequests > 0 else { return 1.0 }
            return Double(totalRequests - totalFailures) / Double(totalRequests)
        }

        var shouldRetry: Bool {
            // Don't retry if too many consecutive failures
            if consecutiveFailures >= 3 { return false }

            // Retry after cooldown period
            if let lastFailure = lastFailureTime {
                let cooldownPeriod = TimeInterval(consecutiveFailures * 60) // Exponential backoff
                return Date().timeIntervalSince(lastFailure) > cooldownPeriod
            }

            return true
        }

        init(provider: LLMProvider) {
            self.provider = provider
            isHealthy = true
            lastSuccessTime = nil
            lastFailureTime = nil
            consecutiveFailures = 0
            totalRequests = 0
            totalFailures = 0
            averageResponseTime = 0
            lastHealthCheck = Date()
        }
    }

    // MARK: - Initialization

    init() {
        startHealthMonitoring()
    }

    deinit {
        stopHealthMonitoring()
    }

    // MARK: - Public Methods

    /// Get the next available provider based on fallback strategy
    /// - Parameters:
    ///   - excludingProviders: Providers to exclude (already failed)
    ///   - priority: Provider priority configuration
    ///   - availableProviders: List of configured providers
    /// - Returns: Next provider to try, or nil if none available
    func getNextProvider(
        excludingProviders: Set<LLMProvider>,
        priority: LLMProviderPriority,
        availableProviders: [LLMProvider]
    ) -> LLMProvider? {
        switch priority.fallbackBehavior {
        case .sequential:
            getSequentialProvider(
                excludingProviders: excludingProviders,
                priority: priority,
                availableProviders: availableProviders
            )

        case .loadBalanced:
            getLoadBalancedProvider(
                excludingProviders: excludingProviders,
                availableProviders: availableProviders
            )

        case .costOptimized:
            getCostOptimizedProvider(
                excludingProviders: excludingProviders,
                availableProviders: availableProviders
            )

        case .performanceOptimized:
            getPerformanceOptimizedProvider(
                excludingProviders: excludingProviders,
                availableProviders: availableProviders
            )
        }
    }

    /// Record a successful request
    /// - Parameters:
    ///   - provider: The provider that succeeded
    ///   - responseTime: Time taken for the request
    func recordSuccess(for provider: LLMProvider, responseTime: TimeInterval) {
        healthQueue.async(flags: .barrier) {
            var health = self.providerHealth[provider] ?? ProviderHealth(provider: provider)

            health.isHealthy = true
            health.lastSuccessTime = Date()
            health.consecutiveFailures = 0
            health.totalRequests += 1

            // Update average response time
            let currentTotal = health.averageResponseTime * Double(health.totalRequests - 1)
            health.averageResponseTime = (currentTotal + responseTime) / Double(health.totalRequests)

            self.providerHealth[provider] = health

            self.logger.debug("Provider \(provider.name) succeeded in \(responseTime)s")
        }
    }

    /// Record a failed request
    /// - Parameters:
    ///   - provider: The provider that failed
    ///   - error: The error that occurred
    func recordFailure(for provider: LLMProvider, error: Error) {
        healthQueue.async(flags: .barrier) {
            var health = self.providerHealth[provider] ?? ProviderHealth(provider: provider)

            health.lastFailureTime = Date()
            health.consecutiveFailures += 1
            health.totalRequests += 1
            health.totalFailures += 1

            // Mark unhealthy after 3 consecutive failures
            if health.consecutiveFailures >= 3 {
                health.isHealthy = false
            }

            self.providerHealth[provider] = health

            self.logger.error("Provider \(provider.name) failed: \(error.localizedDescription)")
        }
    }

    /// Get current health status for all providers
    /// - Returns: Dictionary of provider health status
    func getHealthStatus() -> [LLMProvider: ProviderHealth] {
        healthQueue.sync {
            providerHealth
        }
    }

    /// Reset health status for a provider
    /// - Parameter provider: The provider to reset
    func resetHealth(for provider: LLMProvider) {
        healthQueue.async(flags: .barrier) {
            self.providerHealth[provider] = ProviderHealth(provider: provider)
        }
    }

    // MARK: - Private Methods

    private func startHealthMonitoring() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { _ in
            Task {
                await self.performHealthChecks()
            }
        }
    }

    private func stopHealthMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    private func performHealthChecks() async {
        // Reset providers that have been unhealthy for a while
        healthQueue.async(flags: .barrier) {
            let now = Date()

            for (provider, health) in self.providerHealth {
                if !health.isHealthy,
                   let lastFailure = health.lastFailureTime,
                   now.timeIntervalSince(lastFailure) > 3600 { // 1 hour
                    self.logger.info("Resetting health for provider \(provider.name) after cooldown")
                    self.providerHealth[provider] = ProviderHealth(provider: provider)
                }
            }
        }
    }

    // MARK: - Fallback Strategies

    private func getSequentialProvider(
        excludingProviders: Set<LLMProvider>,
        priority: LLMProviderPriority,
        availableProviders: [LLMProvider]
    ) -> LLMProvider? {
        // Try providers in priority order
        for provider in priority.providers {
            guard availableProviders.contains(provider),
                  !excludingProviders.contains(provider) else { continue }

            let health = healthQueue.sync { providerHealth[provider] ?? ProviderHealth(provider: provider) }

            if health.isHealthy, health.shouldRetry {
                return provider
            }
        }

        return nil
    }

    private func getLoadBalancedProvider(
        excludingProviders: Set<LLMProvider>,
        availableProviders: [LLMProvider]
    ) -> LLMProvider? {
        // Select provider with lowest current load (fewest recent requests)
        let candidates = availableProviders.filter { !excludingProviders.contains($0) }

        let providerLoads = healthQueue.sync {
            candidates.compactMap { provider -> (LLMProvider, Int)? in
                let health = providerHealth[provider] ?? ProviderHealth(provider: provider)
                guard health.isHealthy, health.shouldRetry else { return nil }
                return (provider, health.totalRequests)
            }
        }

        // Return provider with lowest request count
        return providerLoads.min(by: { $0.1 < $1.1 })?.0
    }

    private func getCostOptimizedProvider(
        excludingProviders: Set<LLMProvider>,
        availableProviders: [LLMProvider]
    ) -> LLMProvider? {
        // Select cheapest available provider
        let candidates = availableProviders.filter { !excludingProviders.contains($0) }

        let providerCosts = healthQueue.sync {
            candidates.compactMap { provider -> (LLMProvider, Double)? in
                let health = providerHealth[provider] ?? ProviderHealth(provider: provider)
                guard health.isHealthy, health.shouldRetry else { return nil }

                // Get cost from default model
                let cost = provider.defaultModel?.costPer1KTokens.input ?? 1.0
                return (provider, cost)
            }
        }

        // Return cheapest provider
        return providerCosts.min(by: { $0.1 < $1.1 })?.0
    }

    private func getPerformanceOptimizedProvider(
        excludingProviders: Set<LLMProvider>,
        availableProviders: [LLMProvider]
    ) -> LLMProvider? {
        // Select fastest responding provider
        let candidates = availableProviders.filter { !excludingProviders.contains($0) }

        let providerPerformance = healthQueue.sync {
            candidates.compactMap { provider -> (LLMProvider, TimeInterval)? in
                let health = providerHealth[provider] ?? ProviderHealth(provider: provider)
                guard health.isHealthy, health.shouldRetry else { return nil }

                // Use average response time, default to 1.0 if no data
                let avgTime = health.averageResponseTime > 0 ? health.averageResponseTime : 1.0
                return (provider, avgTime)
            }
        }

        // Return fastest provider
        return providerPerformance.min(by: { $0.1 < $1.1 })?.0
    }
}

// MARK: - Retry Policy

struct LLMRetryPolicy {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    static let `default` = LLMRetryPolicy(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    /// Calculate delay for retry attempt
    /// - Parameter attempt: The attempt number (0-based)
    /// - Returns: Delay in seconds
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = initialDelay * pow(multiplier, Double(attempt))
        return min(exponentialDelay, maxDelay)
    }
}

// MARK: - Fallback Result

struct LLMFallbackResult {
    let response: LLMResponse
    let provider: LLMProvider
    let attemptCount: Int
    let totalDuration: TimeInterval
    let failedProviders: [LLMProvider: Error]
}

// MARK: - Fallback Coordinator

extension LLMServiceManager {
    /// Internal fallback manager
    private static let fallbackManager = LLMFallbackManager()

    /// Send request with comprehensive fallback support
    func sendRequestWithFallback(
        prompt: String,
        context: ConversationContext?,
        options: LLMRequestOptions,
        retryPolicy: LLMRetryPolicy = .default
    ) async throws -> LLMFallbackResult {
        let startTime = Date()
        var failedProviders: [LLMProvider: Error] = [:]
        var attemptCount = 0

        // Get available providers
        let availableProviders = getAvailableProviders()
        let priority = configurationManager.providerPriority

        // Try providers based on fallback strategy
        var excludedProviders = Set<LLMProvider>()

        while attemptCount < retryPolicy.maxAttempts {
            attemptCount += 1

            // Get next provider
            guard let provider = Self.fallbackManager.getNextProvider(
                excludingProviders: excludedProviders,
                priority: priority,
                availableProviders: availableProviders
            ) else {
                // No more providers available
                break
            }

            excludedProviders.insert(provider)

            // Get or create adapter
            guard let adapter = adapters[provider] ?? createAdapterIfNeeded(for: provider) else {
                failedProviders[provider] = LLMError.providerUnavailable(provider: provider)
                continue
            }

            let requestStartTime = Date()

            do {
                let response = try await adapter.sendRequest(
                    prompt: prompt,
                    context: context,
                    options: options
                )

                // Record success
                let responseTime = Date().timeIntervalSince(requestStartTime)
                Self.fallbackManager.recordSuccess(for: provider, responseTime: responseTime)

                // Return successful result
                return LLMFallbackResult(
                    response: response,
                    provider: provider,
                    attemptCount: attemptCount,
                    totalDuration: Date().timeIntervalSince(startTime),
                    failedProviders: failedProviders
                )

            } catch {
                // Record failure
                failedProviders[provider] = error
                Self.fallbackManager.recordFailure(for: provider, error: error)

                // Add delay before retry (if not the last attempt)
                if attemptCount < retryPolicy.maxAttempts {
                    let delay = retryPolicy.delay(for: attemptCount - 1)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        // All attempts failed
        throw LLMError.allProvidersFailed(failedProviders)
    }
}

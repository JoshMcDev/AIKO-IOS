//
//  VanillaIceIntegrationTests.swift
//  AIKO
//
//  Comprehensive tests for VanillaIce integration with all 14 OpenRouter models
//

import XCTest
@testable import AIKO
import Foundation

@MainActor
final class VanillaIceIntegrationTests: XCTestCase {
    
    var cacheManager: OfflineCacheManager!
    let testTimeout: TimeInterval = 120.0 // 2 minutes for all models
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize cache manager with test configuration
        cacheManager = OfflineCacheManager.shared
        
        // Ensure OpenRouter API key is set
        let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
        XCTAssertNotNil(apiKey, "OPENROUTER_API_KEY environment variable must be set for tests")
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        // Clean up test data
        try await cacheManager.clearAll()
    }
    
    /// Test parallel query with all 14 models
    func testParallelQueryAllModels() async throws {
        let operation = VanillaIceOperation.parallelQuery(
            prompt: "What is 2 + 2? Respond in exactly one word."
        )
        
        let result = try await cacheManager.executeVanillaIceOperation(operation)
        
        XCTAssertNotNil(result, "VanillaIce operation should return a result")
        
        // Print results for analysis
        print("\n=== VanillaIce Parallel Query Test Results ===")
        print("Total models queried: \(result!.responses.count)")
        print("Successful responses: \(result!.successCount)")
        print("Failed responses: \(result!.failureCount)")
        print("\nModel-by-model results:")
        
        for response in result!.responses {
            if let content = response.response {
                print("✅ \(response.modelId): \(content.prefix(50))...")
            } else if let error = response.error {
                print("❌ \(response.modelId): \(error)")
            }
        }
        
        // Verify we attempted to query all 14 models
        XCTAssertEqual(result!.responses.count, 14, "Should query all 14 configured models")
        
        // At least some models should respond successfully
        XCTAssertGreaterThan(result!.successCount, 0, "At least one model should respond successfully")
    }
    
    /// Test consensus operation with diverse models
    func testConsensusOperation() async throws {
        let models = [
            VanillaIceModel(modelId: "google/gemini-2.5-pro", stance: .for, customPrompt: nil),
            VanillaIceModel(modelId: "openai/gpt-4o-2024-08-06", stance: .against, customPrompt: nil),
            VanillaIceModel(modelId: "deepseek/deepseek-chat", stance: .neutral, customPrompt: nil)
        ]
        
        let operation = VanillaIceOperation.consensus(
            prompt: "Should AI assistants have the ability to refuse user requests?",
            models: models
        )
        
        let result = try await cacheManager.executeVanillaIceOperation(operation)
        
        XCTAssertNotNil(result, "Consensus operation should return a result")
        XCTAssertNotNil(result!.consensus, "Consensus analysis should be generated")
        
        print("\n=== VanillaIce Consensus Test Results ===")
        print(result!.formatForDisplay())
    }
    
    /// Test model benchmark operation
    func testModelBenchmark() async throws {
        let operation = VanillaIceOperation.modelBenchmark(
            prompt: "Generate a haiku about Swift programming."
        )
        
        let result = try await cacheManager.executeVanillaIceOperation(operation)
        
        XCTAssertNotNil(result, "Benchmark operation should return a result")
        XCTAssertNotNil(result!.consensus, "Benchmark analysis should be generated")
        
        print("\n=== VanillaIce Benchmark Test Results ===")
        print(result!.formatForDisplay())
        
        // Verify benchmark data includes performance metrics
        XCTAssertTrue(result!.consensus!.contains("Average Response Time"), "Should include average response time")
        XCTAssertTrue(result!.consensus!.contains("Fastest Model"), "Should identify fastest model")
        XCTAssertTrue(result!.consensus!.contains("Slowest Model"), "Should identify slowest model")
    }
    
    /// Test rate limiting behavior
    func testRateLimiting() async throws {
        // Create multiple rapid requests to the same model
        let fastModel = "google/gemini-2.5-flash-preview"
        
        var operations: [VanillaIceOperation] = []
        for i in 0..<5 {
            operations.append(
                VanillaIceOperation.parallelQuery(
                    prompt: "Quick test \(i): What is \(i) + \(i)?"
                )
            )
        }
        
        let startTime = Date()
        
        // Execute operations concurrently
        try await withThrowingTaskGroup(of: VanillaIceResult?.self) { group in
            for operation in operations {
                group.addTask {
                    try await self.cacheManager.executeVanillaIceOperation(operation)
                }
            }
            
            var results: [VanillaIceResult] = []
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            
            let totalDuration = Date().timeIntervalSince(startTime)
            
            print("\n=== Rate Limiting Test Results ===")
            print("Total duration for 5 concurrent requests: \(String(format: "%.2f", totalDuration))s")
            print("Average duration per request: \(String(format: "%.2f", totalDuration / 5))s")
            
            // Verify rate limiting is working (requests should be spaced out)
            XCTAssertGreaterThan(totalDuration, 2.0, "Rate limiting should space out requests")
        }
    }
    
    /// Test error handling and retry logic
    func testErrorHandlingAndRetry() async throws {
        // Use an invalid model ID to trigger error handling
        let syncEngine = await cacheManager.syncEngine
        XCTAssertNotNil(syncEngine, "SyncEngine should be initialized")
        
        // Create an item that will likely fail
        await syncEngine!.queueChange(
            key: "test-error-key",
            operation: .query,
            data: "Test error handling".data(using: .utf8),
            contentType: .llmResponse,
            priority: .urgent,
            syncRole: "invalid_model_role"
        )
        
        // Attempt sync
        let syncResult = await syncEngine!.performSync()
        
        print("\n=== Error Handling Test Results ===")
        print("Sync success: \(syncResult.success)")
        print("Failed items: \(syncResult.failedItems.count)")
        
        for (key, error) in syncResult.failedItems {
            print("Failed: \(key) - \(error)")
        }
        
        // Verify error was handled gracefully
        XCTAssertFalse(syncResult.success, "Sync should fail for invalid model")
        XCTAssertGreaterThan(syncResult.failedItems.count, 0, "Should have failed items")
    }
    
    /// Test cache integration with VanillaIce responses
    func testCacheIntegration() async throws {
        let testPrompt = "What is the capital of France?"
        let operation = VanillaIceOperation.parallelQuery(prompt: testPrompt)
        
        // Execute operation
        let result = try await cacheManager.executeVanillaIceOperation(operation)
        XCTAssertNotNil(result)
        
        // Verify responses are cached
        let cacheKeys = await cacheManager.getAllKeys()
        let vanillaIceKeys = cacheKeys.filter { $0.contains("vanillaice_") }
        
        print("\n=== Cache Integration Test Results ===")
        print("Total cache entries: \(cacheKeys.count)")
        print("VanillaIce cache entries: \(vanillaIceKeys.count)")
        
        XCTAssertGreaterThan(vanillaIceKeys.count, 0, "VanillaIce responses should be cached")
        
        // Retrieve a cached response
        if let firstKey = vanillaIceKeys.first {
            let cachedData = try await cacheManager.retrieveData(
                forKey: "\(firstKey)_response",
                isSecure: false
            )
            XCTAssertNotNil(cachedData, "Should be able to retrieve cached response")
        }
    }
    
    /// Performance test for all models
    func testPerformanceAllModels() async throws {
        measure {
            let expectation = self.expectation(description: "Performance test")
            
            Task {
                let operation = VanillaIceOperation.modelBenchmark(
                    prompt: "Explain quantum computing in one sentence."
                )
                
                do {
                    let result = try await cacheManager.executeVanillaIceOperation(operation)
                    XCTAssertNotNil(result)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: testTimeout)
        }
    }
}

// MARK: - Test Helpers
extension VanillaIceIntegrationTests {
    
    /// Verify a specific model is working
    func verifyModel(_ modelId: String) async throws -> Bool {
        let operation = VanillaIceOperation.parallelQuery(
            prompt: "Respond with 'OK' if you receive this message."
        )
        
        guard let result = try await cacheManager.executeVanillaIceOperation(operation) else {
            return false
        }
        
        let modelResponse = result.responses.first { $0.modelId == modelId }
        return modelResponse?.response != nil
    }
    
    /// Get model statistics from test results
    func getModelStatistics(from results: [VanillaIceResult]) -> String {
        var totalResponses = 0
        var totalSuccesses = 0
        var modelSuccessRates: [String: Double] = [:]
        var modelAverageTimes: [String: Double] = [:]
        
        for result in results {
            for response in result.responses {
                totalResponses += 1
                if response.response != nil {
                    totalSuccesses += 1
                }
                
                // Track per-model statistics
                let currentSuccess = modelSuccessRates[response.modelId] ?? 0
                let currentCount = modelAverageTimes[response.modelId] ?? 0
                
                modelSuccessRates[response.modelId] = currentSuccess + (response.response != nil ? 1 : 0)
                modelAverageTimes[response.modelId] = (currentCount * modelAverageTimes.count + response.duration) / Double(modelAverageTimes.count + 1)
            }
        }
        
        var stats = """
        === Model Performance Statistics ===
        Total Responses: \(totalResponses)
        Total Successes: \(totalSuccesses)
        Overall Success Rate: \(String(format: "%.1f%%", Double(totalSuccesses) / Double(totalResponses) * 100))
        
        Per-Model Statistics:
        """
        
        for (model, successCount) in modelSuccessRates.sorted(by: { $0.key < $1.key }) {
            let avgTime = modelAverageTimes[model] ?? 0
            stats += "\n- \(model):"
            stats += "\n  Success Rate: \(String(format: "%.1f%%", successCount / Double(results.count) * 100))"
            stats += "\n  Avg Response Time: \(String(format: "%.2f", avgTime))s"
        }
        
        return stats
    }
}
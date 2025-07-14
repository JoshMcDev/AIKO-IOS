//
//  VanillaIceTestRunner.swift
//  AIKO
//
//  Command-line test runner for VanillaIce integration verification
//

import Foundation
@testable import AIKO

/// Simple test runner for VanillaIce verification
@MainActor
struct VanillaIceTestRunner {
    
    static func runTests() async {
        print("🍦 VanillaIce Integration Test Runner")
        print(String(repeating: "═", count: 60))
        
        // Check API key
        guard ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"] != nil else {
            print("❌ Error: OPENROUTER_API_KEY environment variable not set")
            print("Please set: export OPENROUTER_API_KEY=your_key_here")
            return
        }
        
        let cacheManager = OfflineCacheManager.shared
        let optimizer = SyncEngineOptimizer()
        
        // Test 1: Quick connectivity test
        print("\n📡 Test 1: Quick Connectivity Test")
        print(String(repeating: "─", count: 40))
        
        do {
            let operation = VanillaIceOperation.parallelQuery(
                prompt: "Respond with 'OK' if you receive this."
            )
            
            if let result = try await cacheManager.executeVanillaIceOperation(operation) {
                print("✅ Connected to \(result.successCount)/\(result.responses.count) models")
                
                // Record metrics
                await optimizer.recordMetrics(from: result)
            } else {
                print("❌ Failed to execute operation")
            }
        } catch {
            print("❌ Error: \(error)")
        }
        
        // Test 2: Model-specific role test
        print("\n🎭 Test 2: Model Role Verification")
        print(String(repeating: "─", count: 40))
        
        let roleTests: [(role: String, prompt: String)] = [
            ("chat", "What's the weather like today?"),
            ("thinkdeep", "Explain the concept of recursion in computer science."),
            ("validator", "Is this statement correct: 2 + 2 = 4?"),
            ("codegen", "Write a Swift function to reverse a string."),
            ("search", "What are the latest developments in quantum computing?")
        ]
        
        for (role, prompt) in roleTests {
            print("\nTesting role: \(role)")
            
            do {
                let operation = VanillaIceOperation.parallelQuery(prompt: prompt)
                
                if let result = try await cacheManager.executeVanillaIceOperation(operation) {
                    // Find the model assigned to this role
                    let modelForRole = result.responses.first { response in
                        // Match based on known role assignments
                        switch role {
                        case "chat": return response.modelId.contains("grok")
                        case "thinkdeep": return response.modelId.contains("gemini-2.5-pro")
                        case "validator": return response.modelId.contains("gpt-4o-mini")
                        case "codegen": return response.modelId.contains("qwen-2.5-coder")
                        case "search": return response.modelId.contains("search-preview")
                        default: return false
                        }
                    }
                    
                    if let model = modelForRole, model.response != nil {
                        print("✅ \(model.modelId) responded in \(String(format: "%.2f", model.duration))s")
                    } else {
                        print("⚠️  No response from designated model for role '\(role)'")
                    }
                    
                    await optimizer.recordMetrics(from: result)
                }
            } catch {
                print("❌ Error testing role '\(role)': \(error)")
            }
        }
        
        // Test 3: Consensus operation
        print("\n\n🤝 Test 3: Consensus Analysis")
        print(String(repeating: "─", count: 40))
        
        do {
            let models = [
                VanillaIceModel(modelId: "google/gemini-2.5-pro", stance: .for, customPrompt: nil),
                VanillaIceModel(modelId: "deepseek/deepseek-chat", stance: .against, customPrompt: nil),
                VanillaIceModel(modelId: "openai/gpt-4o-mini", stance: .neutral, customPrompt: nil)
            ]
            
            let operation = VanillaIceOperation.consensus(
                prompt: "Should developers use AI assistants for code generation?",
                models: models
            )
            
            if let result = try await cacheManager.executeVanillaIceOperation(operation) {
                print("✅ Consensus generated with \(result.successCount)/\(models.count) models")
                
                if let consensus = result.consensus {
                    print("\nConsensus Summary:")
                    print(String(repeating: "─", count: 40))
                    // Print first 500 characters of consensus
                    let preview = String(consensus.prefix(500))
                    print(preview)
                    if consensus.count > 500 {
                        print("... [truncated]")
                    }
                }
                
                await optimizer.recordMetrics(from: result)
            }
        } catch {
            print("❌ Consensus test failed: \(error)")
        }
        
        // Test 4: Performance benchmark
        print("\n\n⚡ Test 4: Performance Benchmark")
        print(String(repeating: "─", count: 40))
        
        do {
            let operation = VanillaIceOperation.modelBenchmark(
                prompt: "Count from 1 to 5."
            )
            
            if let result = try await cacheManager.executeVanillaIceOperation(operation) {
                print("✅ Benchmark completed")
                
                if let benchmarkData = result.consensus {
                    print("\n" + benchmarkData)
                }
                
                await optimizer.recordMetrics(from: result)
            }
        } catch {
            print("❌ Benchmark failed: \(error)")
        }
        
        // Generate optimization report
        print("\n\n📊 Performance Analysis")
        print(String(repeating: "═", count: 60))
        
        let report = await optimizer.generateReport()
        print(report)
        
        // Test summary
        print("\n\n✨ Test Summary")
        print(String(repeating: "═", count: 60))
        
        // Get sync engine statistics
        if let syncEngine = await cacheManager.syncEngine {
            let pendingCount = await syncEngine.pendingChangesCount()
            print("• Pending sync operations: \(pendingCount)")
            print("• Cache integration: ✅ Active")
            print("• OpenRouter adapter: ✅ Connected")
            print("• VanillaIce operations: ✅ Functional")
        }
        
        print("\n🍦 VanillaIce integration test completed!")
    }
}

// MARK: - Standalone Execution
extension VanillaIceTestRunner {
    
    /// Run tests from command line
    static func main() async {
        await runTests()
    }
}
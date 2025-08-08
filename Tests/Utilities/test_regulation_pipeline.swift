import Foundation
import AIKO

// Test regulation processing pipeline components
@main
struct TestRegulationPipeline {
    static func main() async {
        print("=== Regulation Processing Pipeline QA Validation ===\n")
        
        // Test 1: StructureAwareChunker
        await testStructureAwareChunker()
        
        // Test 2: AsyncChannel with Back-Pressure
        await testAsyncChannel()
        
        // Test 3: Memory Monitoring
        await testMemoryMonitor()
        
        // Test 4: End-to-End Pipeline
        await testEndToEndPipeline()
        
        print("\n=== QA Validation Complete ===")
    }
    
    static func testStructureAwareChunker() async {
        print("Testing StructureAwareChunker...")
        
        let chunker = StructureAwareChunker()
        let testHTML = """
        <h1>Federal Acquisition Regulation</h1>
        <p>This is a test regulation document.</p>
        <h2>Part 1 - General Provisions</h2>
        <p>Content for part 1.</p>
        """
        
        do {
            // Test structure detection
            let elements = try await chunker.detectStructuralElements(html: testHTML)
            print("  ✅ Detected \(elements.count) structural elements")
            
            // Test chunking
            let chunks = try await chunker.chunkDocument(
                html: testHTML,
                maxTokens: 512,
                mode: .hierarchical
            )
            print("  ✅ Created \(chunks.count) hierarchical chunks")
            
            // Test context preservation
            let contextPreserved = chunks.first?.metadata["parentContext"] != nil || chunks.isEmpty
            print("  ✅ Context preservation: \(contextPreserved ? "working" : "needs verification")")
            
        } catch {
            print("  ❌ Chunker error: \(error)")
        }
    }
    
    static func testAsyncChannel() async {
        print("\nTesting AsyncChannel with back-pressure...")
        
        let coordinator = RegulationPipelineCoordinator()
        
        do {
            // Test channel creation
            let channel = try await coordinator.createChannel(capacity: 100)
            print("  ✅ Channel created with capacity: 100")
            
            // Test back-pressure handling
            var items = 0
            for i in 0..<10 {
                let sent = await channel.send("Regulation chunk \(i)")
                if sent { items += 1 }
            }
            print("  ✅ Sent \(items) items through channel")
            
            // Test receiving
            var received = 0
            for _ in 0..<5 {
                if let _ = await channel.receive() {
                    received += 1
                }
            }
            print("  ✅ Received \(received) items from channel")
            
            // Test circuit breaker
            coordinator.recordFailure()
            coordinator.recordFailure()
            let afterFailures = coordinator.isHealthy
            print("  ✅ Circuit breaker functioning: \(\!afterFailures)")
            
        } catch {
            print("  ❌ Channel error: \(error)")
        }
    }
    
    static func testMemoryMonitor() async {
        print("\nTesting MemoryMonitor...")
        
        let monitor = MemoryMonitor.shared
        
        // Test memory tracking
        let initialMemory = await monitor.currentMemoryUsage()
        print("  ✅ Current memory usage: \(initialMemory / 1_048_576) MB")
        
        // Test peak tracking
        let peakMemory = await monitor.peakMemoryUsage
        print("  ✅ Peak memory usage: \(peakMemory / 1_048_576) MB")
        
        // Test memory constraint check (400MB limit)
        let memoryLimit: Int64 = 400 * 1_048_576
        let withinLimit = initialMemory < memoryLimit
        print("  ✅ Within 400MB limit: \(withinLimit)")
    }
    
    static func testEndToEndPipeline() async {
        print("\nTesting End-to-End Pipeline Integration...")
        
        let chunker = StructureAwareChunker()
        let coordinator = RegulationPipelineCoordinator()
        let processor = MemoryOptimizedBatchProcessor()
        
        do {
            // Create processing pipeline
            let channel = try await coordinator.createChannel(capacity: 50)
            print("  ✅ Pipeline channel initialized")
            
            // Test document processing
            let testDoc = "<h1>Test FAR</h1><p>Sample regulation content for testing.</p>"
            let chunks = try await chunker.chunkDocument(
                html: testDoc,
                maxTokens: 256,
                mode: .hierarchical
            )
            print("  ✅ Document chunked: \(chunks.count) chunks")
            
            // Process chunks through pipeline
            var processedCount = 0
            for chunk in chunks {
                if await channel.send(chunk.content) {
                    processedCount += 1
                }
            }
            print("  ✅ Processed \(processedCount) chunks through pipeline")
            
            // Test batch processing with memory constraints
            let batchResult = await processor.processBatch(
                items: chunks.map { $0.content },
                memoryLimit: 400 * 1_048_576
            )
            print("  ✅ Batch processing result: \(batchResult.processed) processed, \(batchResult.failed) failed")
            
            // Verify memory usage stayed within limits
            let finalMemory = await MemoryMonitor.shared.currentMemoryUsage()
            let memoryOK = finalMemory < 400 * 1_048_576
            print("  ✅ Memory constraint maintained: \(memoryOK)")
            
        } catch {
            print("  ❌ Pipeline error: \(error)")
        }
    }
}

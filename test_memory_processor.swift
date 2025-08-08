#!/usr/bin/env swift

// Test script for MemoryManagedBatchProcessor
import Foundation

// Import the AIKO module path (simulated for testing)
#if canImport(AIKO)
import AIKO
#endif

@main
struct TestMemoryProcessor {
    static func main() async {
        print("Testing MemoryManagedBatchProcessor...")
        
        // Test basic instantiation
        let processor = MemoryManagedBatchProcessor(
            totalPermits: 10,
            memoryLimitMB: 100.0,
            permitStrategy: .fairness,
            permitTimeoutSeconds: 2.0,
            enableAdaptiveBatching: true,
            enableMemoryAwareBatching: true,
            enableDynamicAdjustment: true
        )
        
        print("✅ MemoryManagedBatchProcessor instantiated successfully")
        
        // Test permit acquisition
        do {
            let permitId = try await processor.acquirePermit(estimatedMemoryMB: 5.0)
            print("✅ Permit acquired: \(permitId)")
            
            // Test permit release
            await processor.releasePermit(permitId)
            print("✅ Permit released successfully")
            
            // Test state queries
            let activeCount = await processor.getActivePermitCount()
            let availableCount = await processor.getAvailablePermitCount()
            let batchSize = await processor.getCurrentBatchSize()
            
            print("✅ State queries work - Active: \(activeCount), Available: \(availableCount), BatchSize: \(batchSize)")
            
        } catch {
            print("❌ Error during permit operations: \(error)")
        }
        
        print("MemoryManagedBatchProcessor basic test completed!")
    }
}
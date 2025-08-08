import Foundation

/// Simple memory monitor for regulation processing pipeline tests
/// Delegates to UnifiedMemoryMonitor for consistent behavior
public typealias MemoryMonitor = UnifiedMemoryMonitor

// Legacy compatibility extension
public extension UnifiedMemoryMonitor {
    func getCurrentUsage() async -> Int {
        Int(await currentMemoryUsage())
    }

    func getPeakUsage() async -> Int {
        Int(peakMemoryUsage)
    }
}

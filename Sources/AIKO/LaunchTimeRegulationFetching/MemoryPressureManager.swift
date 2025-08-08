import Foundation
import os.log

/// Centralized memory pressure management service for Launch-Time Regulation Fetching
/// Provides adaptive behavior across all services based on memory conditions
public actor MemoryPressureManager {
    // MARK: - Singleton

    public static let shared = MemoryPressureManager()

    // MARK: - Properties

    private var currentPressureLevel: LaunchMemoryPressure = .normal
    private var adaptiveBatchSize: Int = 8
    private var adaptiveChunkSize: Int = 16384 // 16KB default
    private var memoryWarningCount: Int = 0
    private var lastMemoryCheckTime: Date = .init()
    private let logger = Logger(subsystem: "com.aiko.regulation", category: "MemoryPressure")

    // MARK: - Configuration

    private enum LocalMemoryConfiguration {
        static let memoryCheckInterval: TimeInterval = 5.0 // Check every 5 seconds
        static let memoryWarningThreshold: Int64 = 300 * 1024 * 1024 // 300MB
        static let memoryCriticalThreshold: Int64 = 400 * 1024 * 1024 // 400MB
    }

    // MARK: - Initialization

    private init() {
        Task {
            await setupMemoryMonitoring()
        }
    }

    // MARK: - Memory Monitoring

    /// Sets up continuous memory monitoring
    private func setupMemoryMonitoring() {
        Task {
            while true {
                await checkMemoryPressure()
                try? await Task.sleep(nanoseconds: UInt64(LocalMemoryConfiguration.memoryCheckInterval * 1_000_000_000))
            }
        }
    }

    /// Checks current memory pressure and adapts configuration
    public func checkMemoryPressure() async {
        let memoryUsage = getCurrentMemoryUsage()

        let newPressureLevel: LaunchMemoryPressure = if memoryUsage > LocalMemoryConfiguration.memoryCriticalThreshold {
            .critical
        } else if memoryUsage > LocalMemoryConfiguration.memoryWarningThreshold {
            .warning
        } else {
            .normal
        }

        if newPressureLevel != currentPressureLevel {
            await updatePressureLevel(newPressureLevel)
        }

        lastMemoryCheckTime = Date()
    }

    /// Updates pressure level and adapts configurations
    private func updatePressureLevel(_ level: LaunchMemoryPressure) async {
        currentPressureLevel = level

        adaptiveBatchSize = MemoryConfiguration.batchSize(for: level)
        adaptiveChunkSize = MemoryConfiguration.chunkSize(for: level)

        switch level {
        case .normal:
            logger.info("Memory pressure normal - restored default configurations")

        case .warning:
            memoryWarningCount += 1
            logger.warning("Memory pressure warning - reduced batch and chunk sizes")

        case .critical:
            memoryWarningCount += 1
            logger.error("Memory pressure critical - minimal resource usage")
            await performEmergencyCleanup()
        }
    }

    /// Performs emergency cleanup under critical memory pressure
    private func performEmergencyCleanup() async {
        // Clear any caches
        URLCache.shared.removeAllCachedResponses()

        // Force autorelease pool drain
        await Task.yield()

        logger.info("Emergency memory cleanup performed")
    }

    /// Gets current memory usage in bytes
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if result == KERN_SUCCESS {
            return Int64(info.resident_size)
        }

        // Fallback to estimate
        return 200 * 1024 * 1024 // 200MB fallback
    }

    // MARK: - Public API

    /// Gets current memory pressure level
    public func getCurrentPressureLevel() async -> LaunchMemoryPressure {
        currentPressureLevel
    }

    /// Gets adapted batch size for current memory conditions
    public func getAdaptedBatchSize() async -> Int {
        adaptiveBatchSize
    }

    /// Gets adapted chunk size for current memory conditions
    public func getAdaptedChunkSize() async -> Int {
        adaptiveChunkSize
    }

    /// Reports memory usage for a specific operation
    public func reportMemoryUsage(operation: String, bytes: Int64) async {
        if bytes > LocalMemoryConfiguration.memoryWarningThreshold / 10 {
            logger.warning("High memory usage for \(operation): \(bytes / 1024 / 1024)MB")
        }
    }

    /// Suggests optimal configuration for a given operation size
    public func suggestOptimalConfiguration(for _: Int64) async -> (batchSize: Int, chunkSize: Int) {
        let pressureLevel = await getCurrentPressureLevel()
        return (
            MemoryConfiguration.batchSize(for: pressureLevel),
            MemoryConfiguration.chunkSize(for: pressureLevel)
        )
    }

    /// Performs operation with memory pressure awareness
    public func performWithMemoryAwareness<T: Sendable>(
        operation: String,
        block: () async throws -> T
    ) async throws -> T {
        await checkMemoryPressure()

        let startMemory = getCurrentMemoryUsage()
        defer {
            Task {
                let endMemory = getCurrentMemoryUsage()
                let memoryDelta = endMemory - startMemory
                await reportMemoryUsage(operation: operation, bytes: memoryDelta)
            }
        }

        return try await block()
    }

    // MARK: - Statistics

    /// Gets memory pressure statistics
    public func getStatistics() async -> MemoryPressureStatistics {
        MemoryPressureStatistics(
            currentLevel: currentPressureLevel,
            warningCount: memoryWarningCount,
            currentBatchSize: adaptiveBatchSize,
            currentChunkSize: adaptiveChunkSize,
            lastCheckTime: lastMemoryCheckTime,
            currentMemoryUsage: getCurrentMemoryUsage()
        )
    }
}

// MARK: - Supporting Types

/// Memory pressure statistics for monitoring
public struct MemoryPressureStatistics: Sendable {
    public let currentLevel: LaunchMemoryPressure
    public let warningCount: Int
    public let currentBatchSize: Int
    public let currentChunkSize: Int
    public let lastCheckTime: Date
    public let currentMemoryUsage: Int64
}

// MARK: - Extensions for Integration

public extension StreamingRegulationChunk {
    /// Adapts to current memory pressure using centralized manager
    func adaptToCurrentMemoryPressure() async {
        let level = await MemoryPressureManager.shared.getCurrentPressureLevel()
        await adaptToMemoryPressure(level)
    }
}

public extension BackgroundRegulationProcessor {
    /// Gets adapted batch size from centralized manager
    func getOptimalBatchSize() async -> Int {
        await MemoryPressureManager.shared.getAdaptedBatchSize()
    }
}

public extension LFM2Service {
    /// Gets optimal configuration for embedding generation
    func getOptimalEmbeddingConfiguration() async -> (batchSize: Int, chunkSize: Int) {
        let dataSize = Int64(512 * 100) // Estimate for 100 tokens
        return await MemoryPressureManager.shared.suggestOptimalConfiguration(for: dataSize)
    }
}

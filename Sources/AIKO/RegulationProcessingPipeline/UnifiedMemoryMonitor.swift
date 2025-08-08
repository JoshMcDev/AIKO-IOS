import Foundation
import os

/// Unified memory monitor for regulation processing pipeline
/// Consolidates functionality from GraphRAG and Pipeline implementations
public actor UnifiedMemoryMonitor {
    // MARK: - Singleton

    public static let shared = UnifiedMemoryMonitor()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.aiko.pipeline", category: "MemoryMonitor")

    // Memory tracking
    private var peakUsage: Int64 = 0
    private var currentStatus: MemoryStatus
    private var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?

    // Configuration
    private let updateInterval: TimeInterval = 2.0
    private let criticalThreshold: Double = 0.95
    private let warningThreshold: Double = 0.85
    private let safeThreshold: Double = 0.70

    // Performance metrics
    private var memoryCheckpoints: [MemoryCheckpoint] = []
    private let maxCheckpoints = 100

    // MARK: - Initialization

    public init() {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        currentStatus = MemoryStatus(
            totalMemory: totalMemory,
            availableMemory: Int64(totalMemory),
            usedMemory: 0,
            appMemoryUsage: 0,
            memoryPressure: .normal,
            canPerformOperations: true,
            timestamp: Date()
        )
    }

    // MARK: - Legacy API Support (for test compatibility)

    public var peakMemoryUsage: Int64 {
        peakUsage
    }

    public func currentMemoryUsage() async -> Int64 {
        await updateMemoryStatus()
        return currentStatus.usedMemory
    }

    // MARK: - Monitoring Control

    public func startMonitoring() async {
        guard !isMonitoring else { return }

        isMonitoring = true
        logger.info("🚀 Starting unified memory monitoring")

        monitoringTask = Task {
            while !Task.isCancelled {
                await self.updateMemoryStatus()

                do {
                    try await Task.sleep(nanoseconds: UInt64(self.updateInterval * 1_000_000_000))
                } catch {
                    break
                }
            }
        }
    }

    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        logger.info("🛑 Stopping memory monitoring")
    }

    // MARK: - Memory Status

    public func checkMemoryStatus() async -> MemoryStatus {
        await updateMemoryStatus()
        return currentStatus
    }

    public func canPerformOperation(requiredMemory: Int64 = 100_000_000) async -> Bool {
        let status = await checkMemoryStatus()
        return status.availableMemory >= requiredMemory &&
            status.memoryPressure != .critical
    }

    public func recordMemoryCheckpoint(label: String) async {
        let status = await checkMemoryStatus()
        let checkpoint = MemoryCheckpoint(
            label: label,
            memoryUsage: status.usedMemory,
            timestamp: Date()
        )

        memoryCheckpoints.append(checkpoint)

        // Keep only recent checkpoints
        if memoryCheckpoints.count > maxCheckpoints {
            memoryCheckpoints.removeFirst()
        }
    }

    // MARK: - Performance Metrics

    public func getMemoryGrowth(since label: String) async -> Int64? {
        guard let checkpoint = memoryCheckpoints.last(where: { $0.label == label }) else {
            return nil
        }

        let currentUsage = await currentMemoryUsage()
        return currentUsage - checkpoint.memoryUsage
    }

    public func getMemoryMetrics() async -> MemoryMetrics {
        let status = await checkMemoryStatus()

        let averageUsage = memoryCheckpoints.isEmpty ? status.usedMemory :
            memoryCheckpoints.reduce(0) { $0 + $1.memoryUsage } / Int64(memoryCheckpoints.count)

        return MemoryMetrics(
            current: status.usedMemory,
            peak: peakUsage,
            average: averageUsage,
            pressure: status.memoryPressure,
            checkpointCount: memoryCheckpoints.count
        )
    }

    // MARK: - Private Implementation

    @discardableResult
    private func updateMemoryStatus() async -> MemoryStatus {
        let totalMemory = ProcessInfo.processInfo.physicalMemory

        // Get system memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        let usedMemory: Int64
        let availableMemory: Int64

        if kerr == KERN_SUCCESS {
            usedMemory = Int64(info.resident_size)
            availableMemory = Int64(totalMemory) - usedMemory
        } else {
            // Fallback for testing
            usedMemory = 50 * 1024 * 1024
            availableMemory = Int64(totalMemory) - usedMemory
        }

        // Update peak tracking
        peakUsage = max(peakUsage, usedMemory)

        // Calculate pressure
        let usagePercentage = Double(usedMemory) / Double(totalMemory)
        let pressure = calculatePressure(usagePercentage)

        // Update status
        currentStatus = MemoryStatus(
            totalMemory: totalMemory,
            availableMemory: availableMemory,
            usedMemory: usedMemory,
            appMemoryUsage: usedMemory,
            memoryPressure: pressure,
            canPerformOperations: pressure != .critical && availableMemory > 100_000_000,
            timestamp: Date()
        )

        return currentStatus
    }

    private func calculatePressure(_ usagePercentage: Double) -> MemoryPressure {
        switch usagePercentage {
        case 0 ..< safeThreshold:
            return .normal
        case safeThreshold ..< warningThreshold:
            return .moderate
        case warningThreshold ..< criticalThreshold:
            return .high
        default:
            return .critical
        }
    }
}

// MARK: - Supporting Types

public struct MemoryStatus: Sendable {
    public let totalMemory: UInt64
    public let availableMemory: Int64
    public let usedMemory: Int64
    public let appMemoryUsage: Int64
    public let memoryPressure: MemoryPressure
    public let canPerformOperations: Bool
    public let timestamp: Date

    public var usagePercentage: Double {
        Double(usedMemory) / Double(totalMemory)
    }

    public var availableGB: Double {
        Double(availableMemory) / 1_073_741_824
    }

    public var usedGB: Double {
        Double(usedMemory) / 1_073_741_824
    }
}

public enum MemoryPressure: String, Sendable, CaseIterable {
    case normal = "Normal"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"

    public var emoji: String {
        switch self {
        case .normal: return "🟢"
        case .moderate: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
}

public struct MemoryCheckpoint: Sendable {
    public let label: String
    public let memoryUsage: Int64
    public let timestamp: Date
}

public struct MemoryMetrics: Sendable {
    public let current: Int64
    public let peak: Int64
    public let average: Int64
    public let pressure: MemoryPressure
    public let checkpointCount: Int
}

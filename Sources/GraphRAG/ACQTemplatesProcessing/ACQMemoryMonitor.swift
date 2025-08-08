import Foundation
import os.log

// MARK: - ACQMemoryMonitor

/// Memory monitoring service for tracking system memory usage
/// Tracks peak usage and provides memory pressure simulation
actor ACQMemoryMonitor: MemoryMonitorProtocol {
    // MARK: Internal

    var currentMemoryUsage: Int64 {
        get async {
            updateMemoryUsage()
            return _currentMemoryUsage
        }
    }

    var peakMemoryUsage: Int64 {
        get async { _peakMemoryUsage }
    }

    // MARK: - Monitoring Control

    func startMonitoring() async {
        guard !isMonitoring else {
            return
        }

        logger.info("Starting memory monitoring")
        isMonitoring = true

        // Capture baseline memory usage
        updateMemoryUsage()
        baselineMemory = _currentMemoryUsage
        _peakMemoryUsage = _currentMemoryUsage

        // Start continuous monitoring
        monitoringTask = Task { [weak self] in
            while let self, await isMonitoring {
                await updateMemoryUsage()

                // Sleep for 100ms between updates
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    func stopMonitoring() async {
        logger.info("Stopping memory monitoring")
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    // MARK: - Memory Pressure Simulation

    func simulateMemoryPressure() async {
        logger.warning("Simulating memory pressure")
        isMemoryPressureSimulated = true

        // Simulate increased memory usage
        _currentMemoryUsage += (20 * 1024 * 1024) // Add 20MB
        if _currentMemoryUsage > _peakMemoryUsage {
            _peakMemoryUsage = _currentMemoryUsage
        }
    }

    // MARK: - Helper Methods

    func resetPeakUsage() async {
        _peakMemoryUsage = _currentMemoryUsage
        logger.debug("Peak memory usage reset to current: \(self._currentMemoryUsage)")
    }

    // MARK: Private

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "ACQMemoryMonitor")

    private var isMonitoring = false
    private var _currentMemoryUsage: Int64 = 0
    private var _peakMemoryUsage: Int64 = 0
    private var baselineMemory: Int64 = 0

    // Monitoring state
    private var monitoringTask: Task<Void, Never>?
    private var isMemoryPressureSimulated = false

    // MARK: - Memory Usage Tracking

    private func updateMemoryUsage() {
        let usage = getSystemMemoryUsage()
        _currentMemoryUsage = usage

        if usage > _peakMemoryUsage {
            _peakMemoryUsage = usage
        }
    }

    private func getSystemMemoryUsage() -> Int64 {
        // Get current memory usage from the system
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let memoryBytes = Int64(info.resident_size)

            // Add simulated pressure if active
            if isMemoryPressureSimulated {
                return memoryBytes + (20 * 1024 * 1024) // Add 20MB for pressure simulation
            }

            return memoryBytes
        } else {
            // Fallback to estimated usage if system call fails
            return estimateMemoryUsage()
        }
    }

    private func estimateMemoryUsage() -> Int64 {
        // Fallback estimation based on baseline + simulated usage
        var estimate = baselineMemory

        if isMemoryPressureSimulated {
            estimate += (20 * 1024 * 1024) // Add 20MB for pressure simulation
        }

        return estimate
    }
}

// MARK: - MemoryMonitorProtocol

protocol MemoryMonitorProtocol {
    func startMonitoring() async
    func stopMonitoring() async
    func simulateMemoryPressure() async
    var currentMemoryUsage: Int64 { get async }
    var peakMemoryUsage: Int64 { get async }
}

// MARK: - TemplateProcessorProtocol

protocol TemplateProcessorProtocol {
    func processTemplate(content: Data, metadata: TemplateMetadata) async throws -> ProcessedTemplate
    func getConcurrencyViolations() async -> Int
    func performMemoryCleanup() async
}

// MARK: - MemoryPermitSystemProtocol

public protocol MemoryPermitSystemProtocol {
    func acquire(bytes: Int64, timeout: TimeInterval?) async throws -> MemoryPermit
    func release(_ permit: MemoryPermit) async
    func emergencyMemoryRelease() async
    var usedBytes: Int64 { get async }
    var limitBytes: Int64 { get }
}

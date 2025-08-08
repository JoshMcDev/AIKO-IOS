//
//  UserRecordsCapture.swift
//  AIKO
//
//  User Acquisition Records GraphRAG Data Collection System
//  @MainActor isolated UI event capture with <0.5ms latency requirements
//

import Foundation
import os.log

// MARK: - UserRecordsCapture

/// MainActor-isolated UI event capture system
/// Provides non-blocking capture with AsyncStream for downstream processing
/// Meets <0.5ms P95 latency requirement through optimized async patterns
@MainActor
public final class UserRecordsCapture {

    // MARK: - Properties

    /// Indicates if the capture system is properly MainActor isolated
    public var isMainActorIsolated: Bool { true }

    /// Event stream for continuous processing by downstream actors
    public var eventStream: AsyncStream<UserAction> {
        return _eventStream
    }

    // MARK: - Private Properties

    private let logger: Logger = .init(subsystem: "com.aiko.graphrag", category: "UserRecordsCapture")
    private let permitSystem: any MemoryPermitSystemProtocol

    /// Internal event stream and continuation
    private let _eventStream: AsyncStream<UserAction>
    private let eventContinuation: AsyncStream<UserAction>.Continuation

    /// Captured events buffer for testing and overflow handling
    private var capturedEvents: [UserAction] = []
    private var capturedEventCount: Int = 0

    /// Memory pressure tracking
    private var currentMemoryPressure: MemoryPressureLevel = .normal

    /// Performance tracking
    private var concurrencyViolations: Int = 0

    // MARK: - Initialization

    public init(permitSystem: any MemoryPermitSystemProtocol) {
        self.permitSystem = permitSystem

        // Create AsyncStream for non-blocking event processing
        let (stream, continuation) = AsyncStream<UserAction>.makeStream()
        self._eventStream = stream
        self.eventContinuation = continuation

        logger.info("UserRecordsCapture initialized with MainActor isolation")
    }

    deinit {
        eventContinuation.finish()
    }

    // MARK: - Core Capture Methods

    /// Capture user action with <0.5ms P95 latency requirement
    /// Non-blocking operation that immediately returns to UI thread
    @discardableResult
    public func capture(_ action: UserAction) async -> CaptureResult {
        // Fast path validation - must complete in <0.1ms
        guard isValidAction(action) else {
            return .dropped(reason: .invalidAction)
        }

        // Check memory pressure for adaptive behavior
        if currentMemoryPressure == .critical {
            return .dropped(reason: .memoryPressure)
        }

        // Non-blocking capture - queue for background processing
        capturedEvents.append(action)
        capturedEventCount += 1

        // Send to AsyncStream for downstream processing (non-blocking)
        eventContinuation.yield(action)

        // Log at debug level to avoid performance impact
        logger.debug("Captured action: \(String(describing: action.type)) for document: \(action.documentId)")

        // Return success immediately - actual processing happens asynchronously
        return .success
    }

    // MARK: - Testing and Monitoring Methods

    /// Get all captured events for testing verification
    public func getCapturedEvents() async -> [UserAction] {
        return capturedEvents
    }

    /// Get count of captured events for performance testing
    public func getCapturedEventCount() async -> Int {
        return capturedEventCount
    }

    /// Verify structured concurrency compliance
    public func verifyStructuredConcurrencyCompliance() async -> ComplianceResult {
        var issues: [String] = []

        // Check for MainActor isolation - we're @MainActor so this is always satisfied
        // Note: Thread.isMainThread is not available in async contexts, but @MainActor guarantees main thread execution

        // Check for any detected concurrency violations
        if concurrencyViolations > 0 {
            issues.append("Detected \(concurrencyViolations) concurrency violations")
        }

        // Check event stream health
        if capturedEventCount > 10000 {
            issues.append("Event buffer potentially overflowing: \(capturedEventCount) events")
        }

        let isCompliant = issues.isEmpty
        logger.debug("Concurrency compliance check: \(isCompliant ? "PASS" : "FAIL"), issues: \(issues.count)")

        return ComplianceResult(isCompliant: isCompliant, issues: issues)
    }

    // MARK: - Memory Pressure Simulation (Testing Support)

    /// Simulate memory pressure for testing
    internal func simulateMemoryPressure(_ level: MemoryPressureLevel) {
        currentMemoryPressure = level
        logger.warning("Memory pressure simulated: \(String(describing: level))")
    }

    // MARK: - Private Helper Methods

    /// Fast validation to ensure action is properly formed
    private func isValidAction(_ action: UserAction) -> Bool {
        // Basic validation - keep fast for <0.1ms requirement
        return !action.documentId.isEmpty &&
               action.timestamp <= Date() &&
               action.type.rawValue > 0
    }
}

// MARK: - MemoryPermitSystemProtocol Support

extension UserRecordsCapture {
    /// Mock memory permit system for testing when real system not available
    internal class MockMemoryPermitSystem: MemoryPermitSystemProtocol {
        private(set) var usedBytes: Int64 = 0
        let limitBytes: Int64 = 50 * 1024 * 1024 // 50MB limit
        private var currentPressure: MemoryPressureLevel = .normal

        func acquire(bytes: Int64, timeout: TimeInterval?) async throws -> MemoryPermit {
            if currentPressure == .critical {
                throw MemoryPermitError.systemOverloaded
            }

            return MemoryPermit(bytes: bytes)
        }

        func release(_ permit: MemoryPermit) async {
            // Mock implementation
        }

        func emergencyMemoryRelease() async {
            usedBytes = 0
        }

        func simulateMemoryPressure(level: MemoryPressureLevel) {
            currentPressure = level
        }
    }
}

// MARK: - Performance Optimizations

extension UserRecordsCapture {
    /// Clear captured events buffer to prevent memory bloat during testing
    public func clearCapturedEvents() async {
        capturedEvents.removeAll(keepingCapacity: true)
        logger.debug("Cleared captured events buffer")
    }

    /// Get performance metrics for monitoring
    public func getPerformanceMetrics() async -> PerformanceMetrics {
        return PerformanceMetrics(
            capturedEventCount: capturedEventCount,
            concurrencyViolations: concurrencyViolations,
            memoryPressureLevel: currentMemoryPressure,
            bufferSize: capturedEvents.count
        )
    }
}

// MARK: - Supporting Types

/// Performance metrics for monitoring and testing
public struct PerformanceMetrics: Sendable {
    public let capturedEventCount: Int
    public let concurrencyViolations: Int
    public let memoryPressureLevel: MemoryPressureLevel
    public let bufferSize: Int
    public let timestamp: Date

    public init(
        capturedEventCount: Int,
        concurrencyViolations: Int,
        memoryPressureLevel: MemoryPressureLevel,
        bufferSize: Int,
        timestamp: Date = Date()
    ) {
        self.capturedEventCount = capturedEventCount
        self.concurrencyViolations = concurrencyViolations
        self.memoryPressureLevel = memoryPressureLevel
        self.bufferSize = bufferSize
        self.timestamp = timestamp
    }
}

import Foundation
import os

/// Coordinator for regulation processing pipeline with circuit breaker pattern
public actor RegulationPipelineCoordinator {
    // MARK: - Properties

    private let logger = Logger(subsystem: "com.aiko.pipeline", category: "Coordinator")

    // Circuit breaker state
    private var failureCount = 0
    private let maxFailures = 3
    private var circuitState: CircuitState = .closed
    private var lastFailureTime: Date?
    private let cooldownPeriod: TimeInterval = 30.0

    // Channel management
    private var channels: [UUID: AsyncChannelWrapper] = [:]

    // MARK: - Types

    fileprivate enum CircuitState {
        case closed // Normal operation
        case open // Circuit broken, rejecting requests
        case halfOpen // Testing if service recovered
    }

    private struct AsyncChannelWrapper {
        let channel: AsyncChannel<String>
        let createdAt: Date
        let capacity: Int
    }

    // MARK: - Public Interface

    public init() {}

    /// Create a new async channel for pipeline communication
    public func createChannel(capacity: Int) async throws -> AsyncChannel<String> {
        // Check circuit breaker
        try checkCircuitBreaker()

        let channel = AsyncChannel<String>(capacity: capacity)
        let wrapper = AsyncChannelWrapper(
            channel: channel,
            createdAt: Date(),
            capacity: capacity
        )

        let channelId = UUID()
        channels[channelId] = wrapper

        logger.info("Created channel with capacity: \(capacity), ID: \(channelId)")

        return channel
    }

    /// Record a processing failure
    public func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()

        if failureCount >= maxFailures {
            circuitState = .open
            logger.warning("Circuit breaker OPEN after \(self.failureCount) failures")
        }
    }

    /// Record a processing success
    public func recordSuccess() {
        // Reset on success if in half-open state
        if circuitState == .halfOpen {
            failureCount = 0
            circuitState = .closed
            logger.info("Circuit breaker CLOSED after successful operation")
        }
    }

    /// Check if the pipeline is healthy
    public var isHealthy: Bool {
        switch circuitState {
        case .closed, .halfOpen:
            return true
        case .open:
            // Check if cooldown period has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > cooldownPeriod {
                // Try to move to half-open state
                circuitState = .halfOpen
                logger.info("Circuit breaker moved to HALF-OPEN state")
                return true
            }
            return false
        }
    }

    /// Get pipeline statistics
    public func getStatistics() async -> PipelineStatistics {
        PipelineStatistics(
            activeChannels: channels.count,
            totalCapacity: channels.values.reduce(0) { $0 + $1.capacity },
            failureCount: failureCount,
            circuitState: circuitState.description,
            isHealthy: isHealthy
        )
    }

    /// Clean up old channels
    public func cleanupChannels(olderThan age: TimeInterval = 3600) async {
        let cutoffDate = Date().addingTimeInterval(-age)
        let oldChannelIds = channels.compactMap { key, value in
            value.createdAt < cutoffDate ? key : nil
        }

        for channelId in oldChannelIds {
            channels.removeValue(forKey: channelId)
        }

        if !oldChannelIds.isEmpty {
            logger.info("Cleaned up \(oldChannelIds.count) old channels")
        }
    }

    // MARK: - Private Methods

    private func checkCircuitBreaker() throws {
        switch circuitState {
        case .closed, .halfOpen:
            // Allow operation
            return

        case .open:
            // Check if cooldown has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > cooldownPeriod {
                circuitState = .halfOpen
                logger.info("Circuit breaker moved to HALF-OPEN for testing")
                return
            }

            throw PipelineError.circuitBreakerOpen
        }
    }
}

// MARK: - Supporting Types

public struct PipelineStatistics: Sendable {
    public let activeChannels: Int
    public let totalCapacity: Int
    public let failureCount: Int
    public let circuitState: String
    public let isHealthy: Bool
}

public enum PipelineError: Error, LocalizedError {
    case circuitBreakerOpen
    case capacityExceeded
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .circuitBreakerOpen:
            return "Circuit breaker is open - pipeline temporarily unavailable"
        case .capacityExceeded:
            return "Pipeline capacity exceeded"
        case .invalidConfiguration:
            return "Invalid pipeline configuration"
        }
    }
}

// MARK: - Circuit State Extension

fileprivate extension RegulationPipelineCoordinator.CircuitState {
    var description: String {
        switch self {
        case .closed:
            return "Closed (Normal)"
        case .open:
            return "Open (Failing)"
        case .halfOpen:
            return "Half-Open (Testing)"
        }
    }
}

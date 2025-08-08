//
//  MockTypes.swift
//  AIKO
//
//  Supporting mock types for User Acquisition Records testing
//

import Foundation

// MARK: - Mock Memory Permit System

public class MockMemoryPermitSystem: MemoryPermitSystemProtocol {
    public var usedBytes: Int64 { _usedBytes }
    public let limitBytes: Int64 = 50 * 1024 * 1024 // 50MB

    private var _usedBytes: Int64 = 0
    private(set) var acquiredPermitCount = 0
    private(set) var releasedPermitCount = 0
    private var availablePermits = 10
    private var permitTimeout: TimeInterval = 1.0

    public init() {}

    public func setAvailablePermits(_ count: Int) {
        availablePermits = count
    }

    public func setPermitTimeout(_ timeout: TimeInterval) {
        permitTimeout = timeout
    }

    public func acquire(bytes: Int64, timeout: TimeInterval? = nil) async throws -> MemoryPermit {
        acquiredPermitCount += 1

        let effectiveTimeout = timeout ?? permitTimeout
        if effectiveTimeout <= 0.001 && acquiredPermitCount > availablePermits {
            throw MemoryPermitTimeoutError()
        }

        if acquiredPermitCount > availablePermits {
            throw MemoryPermitTimeoutError()
        }

        _usedBytes += bytes

        return MemoryPermit(bytes: bytes)
    }

    public func release(_ permit: MemoryPermit) async {
        await handleRelease()
    }

    public func emergencyMemoryRelease() async {
        _usedBytes = 0
        acquiredPermitCount = 0
        releasedPermitCount = 0
    }

    private func handleRelease() async {
        releasedPermitCount += 1
    }
}

// MARK: - Mock Privacy Engine

public final class MockPrivacyEngine: @unchecked Sendable {
    public var privacyBudget: Double = 1.0

    public init() {}

    public func privatize(_ event: UserAction) async -> UserAction {
        // Mock implementation - return event with minimal privacy transformation
        return UserAction(
            type: event.type,
            documentId: "privatized-\(event.documentId.prefix(8))",
            timestamp: event.timestamp,
            metadata: event.metadata.mapValues { _ in "***" }
        )
    }
}

// MARK: - Mock Graph Updater

public final class MockUserRecordsGraphUpdater: @unchecked Sendable {
    public private(set) var updateCount = 0
    public private(set) var lastResults: ProcessingResults?

    public init() {}

    public func updateWithResults(_ results: ProcessingResults) async {
        updateCount += 1
        lastResults = results
    }
}

// MARK: - Error Types

public struct MemoryPermitTimeoutError: Error {
    public init() {}
}

public struct BufferOverflowError: Error {
    public static let bufferFull = BufferOverflowError()

    public init() {}
}

// MARK: - Additional Pattern Types

public struct WorkflowAnomaly: Sendable {
    public let event: UserAction
    public let anomalyScore: Double
    public let reasons: [String]

    public init(event: UserAction, anomalyScore: Double, reasons: [String]) {
        self.event = event
        self.anomalyScore = anomalyScore
        self.reasons = reasons
    }
}

public struct ProcessingResults: Sendable {
    public let patterns: [WorkflowPattern]
    public let embeddings: [WorkflowEmbedding]
    public let anomalies: [WorkflowAnomaly]
    public let processingTime: TimeInterval

    public init(patterns: [WorkflowPattern], embeddings: [WorkflowEmbedding], anomalies: [WorkflowAnomaly], processingTime: TimeInterval) {
        self.patterns = patterns
        self.embeddings = embeddings
        self.anomalies = anomalies
        self.processingTime = processingTime
    }
}

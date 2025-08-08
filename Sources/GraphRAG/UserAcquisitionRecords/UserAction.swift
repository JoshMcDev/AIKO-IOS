//
//  UserAction.swift
//  AIKO
//
//  User Acquisition Records GraphRAG Data Collection System
//  User action types and capture result types for workflow tracking
//

import Foundation

// MARK: - UserAction for User Acquisition Records

/// User action type for User Acquisition Records workflow tracking
/// This type is required by the test suite and supports workflow event capture
public struct UserAction: Sendable, Equatable, Codable {
    public let type: WorkflowEventType
    public let documentId: String
    public let timestamp: Date
    public let metadata: [String: String] // Simplified for Sendable compliance

    public init(type: WorkflowEventType, documentId: String, timestamp: Date, metadata: [String: String] = [:]) {
        self.type = type
        self.documentId = documentId
        self.timestamp = timestamp
        self.metadata = metadata
    }

    /// Convert to CompactWorkflowEvent for storage
    public func toCompactEvent(userId: String, templateId: String? = nil, flags: EventFlags = []) -> CompactWorkflowEvent {
        return CompactWorkflowEvent(
            timestamp: timestamp,
            userId: userId,
            actionType: type,
            documentId: documentId,
            templateId: templateId,
            flags: flags
        )
    }
}

// MARK: - CaptureResult

/// Result of a user action capture attempt
public enum CaptureResult: Equatable, Sendable {
    case success
    case deferred
    case dropped(reason: DropReason)

    public enum DropReason: Equatable, Sendable {
        case memoryPressure
        case queueFull
        case invalidAction
        case systemOverload
    }
}

// MARK: - ComplianceResult

/// Result of structured concurrency compliance verification
public struct ComplianceResult: Sendable {
    public let isCompliant: Bool
    public let issues: [String]
    public let timestamp: Date

    public init(isCompliant: Bool, issues: [String] = [], timestamp: Date = Date()) {
        self.isCompliant = isCompliant
        self.issues = issues
        self.timestamp = timestamp
    }
}

// MARK: - Memory Pressure Support

/// Memory pressure levels for adaptive behavior
public enum MemoryPressureLevel: Sendable {
    case normal
    case elevated
    case critical
}

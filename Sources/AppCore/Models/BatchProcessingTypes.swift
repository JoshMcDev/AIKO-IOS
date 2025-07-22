import Foundation

// MARK: - Batch Processing Types

/// Represents a batch operation that can be executed
public struct BatchOperation: Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let items: [BatchOperationItem]
    public let estimatedDuration: TimeInterval

    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        items: [BatchOperationItem] = [],
        estimatedDuration: TimeInterval = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.items = items
        self.estimatedDuration = estimatedDuration
    }
}

/// Individual item within a batch operation
public struct BatchOperationItem: Sendable, Identifiable {
    public let id: UUID
    public let type: String
    public let data: Data?
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        type: String,
        data: Data? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.metadata = metadata
    }
}

/// Handle to reference and control a batch operation
public struct BatchOperationHandle: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let operationId: UUID
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        operationId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.operationId = operationId
        self.createdAt = createdAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: BatchOperationHandle, rhs: BatchOperationHandle) -> Bool {
        lhs.id == rhs.id
    }
}

/// Status of a media batch operation
public enum MediaBatchOperationStatus: String, Sendable, CaseIterable {
    case pending
    case running
    case paused
    case completed
    case failed
    case cancelled

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

/// Progress information for a batch operation
public struct BatchProgress: Sendable {
    public let completedItems: Int
    public let totalItems: Int
    public let currentItem: String?
    public let estimatedTimeRemaining: TimeInterval?
    public let bytesProcessed: Int64
    public let totalBytes: Int64

    public init(
        completedItems: Int = 0,
        totalItems: Int = 0,
        currentItem: String? = nil,
        estimatedTimeRemaining: TimeInterval? = nil,
        bytesProcessed: Int64 = 0,
        totalBytes: Int64 = 0
    ) {
        self.completedItems = completedItems
        self.totalItems = totalItems
        self.currentItem = currentItem
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.bytesProcessed = bytesProcessed
        self.totalBytes = totalBytes
    }

    public var percentage: Double {
        guard totalItems > 0 else { return 0.0 }
        return Double(completedItems) / Double(totalItems)
    }
}

/// Result of a batch operation item
public struct BatchOperationResult: Sendable, Identifiable {
    public let id: UUID
    public let itemId: UUID
    public let success: Bool
    public let error: String?
    public let data: Data?
    public let completedAt: Date

    public init(
        id: UUID = UUID(),
        itemId: UUID,
        success: Bool,
        error: String? = nil,
        data: Data? = nil,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.success = success
        self.error = error
        self.data = data
        self.completedAt = completedAt
    }
}

/// Summary of a batch operation for history tracking
public struct BatchOperationSummary: Sendable, Identifiable {
    public let id: UUID
    public let operationId: UUID
    public let name: String
    public let status: MediaBatchOperationStatus
    public let startedAt: Date
    public let completedAt: Date?
    public let totalItems: Int
    public let successfulItems: Int
    public let failedItems: Int

    public init(
        id: UUID = UUID(),
        operationId: UUID,
        name: String,
        status: MediaBatchOperationStatus,
        startedAt: Date,
        completedAt: Date? = nil,
        totalItems: Int = 0,
        successfulItems: Int = 0,
        failedItems: Int = 0
    ) {
        self.id = id
        self.operationId = operationId
        self.name = name
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.totalItems = totalItems
        self.successfulItems = successfulItems
        self.failedItems = failedItems
    }
}

/// Priority levels for batch operations
public enum OperationPriority: Int, Sendable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3

    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

/// Configuration settings for the batch processing engine
public struct BatchEngineSettings: Sendable {
    public let maxConcurrentOperations: Int
    public let maxRetries: Int
    public let timeout: TimeInterval
    public let enableProgressTracking: Bool

    public init(
        maxConcurrentOperations: Int = 3,
        maxRetries: Int = 3,
        timeout: TimeInterval = 300,
        enableProgressTracking: Bool = true
    ) {
        self.maxConcurrentOperations = maxConcurrentOperations
        self.maxRetries = maxRetries
        self.timeout = timeout
        self.enableProgressTracking = enableProgressTracking
    }

    public static let `default` = BatchEngineSettings()
}

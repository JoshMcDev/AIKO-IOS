import Foundation

// MARK: - Core Types for Launch-Time Regulation Fetching

/// Represents the processing state of regulation fetching
public enum ProcessingState: Sendable {
    case idle
    case deferred
    case processing(ProcessPhase)
    case skipped
    case completed
}

/// Represents the current phase of processing
public enum ProcessPhase: Sendable {
    case fetching(FetchSubPhase)
    case processing
    case indexing
}

/// Represents sub-phases of fetching
public enum FetchSubPhase: Sendable {
    case manifest
    case files
}

/// Network quality detection
public enum NetworkQuality: Sendable {
    case wifi
    case cellular
    case disconnected
    case unknown
}

/// Regulation manifest schema versions
public enum RegulationManifestSchema: String, Sendable {
    case v1 = "1.0"
    case v2 = "2.0"
}

/// Memory pressure levels for adaptive behavior (Launch-Time specific)
public enum LaunchMemoryPressure: Sendable {
    case normal, warning, critical
}

/// User onboarding choices for regulation setup
public enum OnboardingChoice: Sendable {
    case downloadNow
    case skipAndRemindLater
    case skipPermanently
}

// MARK: - Data Models

/// Regulation manifest containing list of regulations
public struct RegulationManifest: Sendable {
    public let regulations: [RegulationFile]
    public let version: String
    public let checksum: String

    public init(regulations: [RegulationFile], version: String, checksum: String) {
        self.regulations = regulations
        self.version = version
        self.checksum = checksum
    }
}

/// Individual regulation file metadata
public struct RegulationFile: Sendable {
    public let url: String
    public let sha256Hash: String
    public let title: String
    public let content: String?

    public init(url: String, sha256Hash: String, title: String, content: String? = nil) {
        self.url = url
        self.sha256Hash = sha256Hash
        self.title = title
        self.content = content
    }
}

/// Launch-time regulation content chunk for streaming processing
public struct LaunchTimeRegulationChunk: Sendable {
    public let id: String
    public let content: String
    public let chunkIndex: Int

    public init(id: String, content: String, chunkIndex: Int) {
        self.id = id
        self.content = content
        self.chunkIndex = chunkIndex
    }
}

/// Regulation embedding for vector storage
public struct RegulationEmbedding: Sendable {
    public let id: String
    public let title: String
    public let content: String
    public let embedding: [Float]

    public init(id: String, title: String, content: String, embedding: [Float]) {
        self.id = id
        self.title = title
        self.content = content
        self.embedding = embedding
    }
}

/// LFM2 embedding result
public struct LFM2Embedding: Sendable {
    public let vector: [Float]
    public let dimensions: Int
    public let magnitude: Float

    public init(vector: [Float], dimensions: Int, magnitude: Float) {
        self.vector = vector
        self.dimensions = dimensions
        self.magnitude = magnitude
    }
}

/// Processing progress tracking
public struct ProcessingProgress: Sendable {
    public let percentage: Double
    public let processedCount: Int
    public let estimatedTimeRemaining: TimeInterval?
    public let currentPhase: String?
    public let checkpointToken: String
    public let previousProcessedCount: Int

    public init(percentage: Double, processedCount: Int, estimatedTimeRemaining: TimeInterval?,
                currentPhase: String?, checkpointToken: String, previousProcessedCount: Int) {
        self.percentage = percentage
        self.processedCount = processedCount
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.currentPhase = currentPhase
        self.checkpointToken = checkpointToken
        self.previousProcessedCount = previousProcessedCount
    }
}

/// Checkpoint data for resuming processing
public struct ProcessingCheckpoint: Codable, Sendable {
    public let processedCount: Int
    public let progressPercentage: Double
    public let timestamp: Date

    public init(processedCount: Int, progressPercentage: Double, timestamp: Date) {
        self.processedCount = processedCount
        self.progressPercentage = progressPercentage
        self.timestamp = timestamp
    }
}

/// Progress update for UI
public struct ProgressUpdate: Sendable {
    public let percentage: Double
    public let currentPhase: String?
    public let estimatedTimeRemaining: TimeInterval?

    public init(percentage: Double, currentPhase: String?, estimatedTimeRemaining: TimeInterval?) {
        self.percentage = percentage
        self.currentPhase = currentPhase
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

// MARK: - Error Types

/// Main error type for regulation fetching operations
public enum RegulationFetchingError: Error, LocalizedError {
    case dependencyContainerNotInitialized
    case serviceNotConfigured
    case invalidConfiguration
    case testTimeout
    case rateLimitExceeded
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .dependencyContainerNotInitialized:
            "Dependency container not initialized"
        case .serviceNotConfigured:
            "Required service not configured"
        case .invalidConfiguration:
            "Invalid service configuration"
        case .testTimeout:
            "Test operation timed out"
        case .rateLimitExceeded:
            "API rate limit exceeded"
        case let .networkError(message):
            "Network error: \(message)"
        }
    }
}

/// Security-related errors
public enum SecurityError: Error, LocalizedError {
    case certificatePinningFailure
    case fileIntegrityViolation
    case fileSizeExceedsLimit(Int64)
    case untrustedSource

    public var errorDescription: String? {
        switch self {
        case .certificatePinningFailure:
            "Certificate pinning validation failed"
        case .fileIntegrityViolation:
            "File integrity check failed"
        case let .fileSizeExceedsLimit(size):
            "File size exceeds limit: \(size) bytes"
        case .untrustedSource:
            "Regulation source is not trusted"
        }
    }
}

/// Network-related errors (using NetworkError from NetworkService)
public typealias LaunchTimeNetworkError = NetworkError

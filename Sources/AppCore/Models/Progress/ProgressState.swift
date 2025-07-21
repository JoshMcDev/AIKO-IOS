import Foundation

/// Current state of a progress tracking session
public struct ProgressState: Equatable, Sendable {
    /// Unique identifier for this progress session
    public let sessionId: UUID
    
    /// Current workflow phase
    public let currentPhase: ProgressPhase
    
    /// Progress within the current phase (0.0 to 1.0)
    public let phaseProgress: Double
    
    /// Overall progress across all phases (0.0 to 1.0)
    public let overallProgress: Double
    
    /// Current operation description
    public let currentOperation: String
    
    /// Estimated time remaining in seconds
    public let estimatedTimeRemaining: TimeInterval?
    
    /// Processing speed metrics
    public let processingSpeed: ProcessingSpeed?
    
    /// Error state information
    public let errorState: ProgressError?
    
    /// Whether the operation can be cancelled
    public let canCancel: Bool
    
    /// Session start time
    public let startTime: Date
    
    /// Last update timestamp
    public let lastUpdateTime: Date
    
    /// Number of updates received in this session
    public let updateCount: Int
    
    /// Accessibility label for screen readers
    public var accessibilityLabel: String {
        let percentage = Int(overallProgress * 100)
        let timeRemaining = estimatedTimeRemaining.map { " Estimated time remaining: \(Int($0)) seconds" } ?? ""
        return "\(currentPhase.displayName). \(percentage)% complete. \(currentOperation)\(timeRemaining)"
    }
    
    public init(
        sessionId: UUID,
        currentPhase: ProgressPhase,
        phaseProgress: Double,
        overallProgress: Double,
        currentOperation: String,
        estimatedTimeRemaining: TimeInterval? = nil,
        processingSpeed: ProcessingSpeed? = nil,
        errorState: ProgressError? = nil,
        canCancel: Bool? = nil,
        startTime: Date = Date(),
        lastUpdateTime: Date = Date(),
        updateCount: Int = 0
    ) {
        self.sessionId = sessionId
        self.currentPhase = currentPhase
        self.phaseProgress = max(0.0, min(1.0, phaseProgress))
        self.overallProgress = max(0.0, min(1.0, overallProgress))
        self.currentOperation = currentOperation
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.processingSpeed = processingSpeed
        self.errorState = errorState
        self.canCancel = canCancel ?? currentPhase.canCancel
        self.startTime = startTime
        self.lastUpdateTime = lastUpdateTime
        self.updateCount = updateCount
    }
}

// MARK: - State Updates

public extension ProgressState {
    /// Create a new state by applying a progress update
    func applying(_ update: ProgressUpdate) -> ProgressState {
        let processingSpeed = calculateProcessingSpeed(from: update)
        
        return ProgressState(
            sessionId: sessionId,
            currentPhase: update.phase,
            phaseProgress: update.phaseProgress,
            overallProgress: update.overallProgress,
            currentOperation: update.operation,
            estimatedTimeRemaining: update.estimatedTimeRemaining,
            processingSpeed: processingSpeed,
            errorState: extractError(from: update),
            canCancel: update.phase.canCancel,
            startTime: startTime,
            lastUpdateTime: update.timestamp,
            updateCount: updateCount + 1
        )
    }
    
    /// Create initial state for a new session
    static func initial(sessionId: UUID) -> ProgressState {
        return ProgressState(
            sessionId: sessionId,
            currentPhase: .initializing,
            phaseProgress: 0.0,
            overallProgress: 0.0,
            currentOperation: ProgressPhase.initializing.operationDescription,
            canCancel: false,
            updateCount: 0
        )
    }
    
    /// Create a completed state
    func completed() -> ProgressState {
        return ProgressState(
            sessionId: sessionId,
            currentPhase: .completed,
            phaseProgress: 1.0,
            overallProgress: 1.0,
            currentOperation: ProgressPhase.completed.operationDescription,
            estimatedTimeRemaining: 0,
            processingSpeed: processingSpeed,
            errorState: nil,
            canCancel: false,
            startTime: startTime,
            lastUpdateTime: Date(),
            updateCount: updateCount + 1
        )
    }
    
    /// Create an error state
    func withError(_ error: ProgressError) -> ProgressState {
        return ProgressState(
            sessionId: sessionId,
            currentPhase: .error,
            phaseProgress: phaseProgress,
            overallProgress: overallProgress,
            currentOperation: "Error: \(error.localizedDescription)",
            estimatedTimeRemaining: nil,
            processingSpeed: processingSpeed,
            errorState: error,
            canCancel: false,
            startTime: startTime,
            lastUpdateTime: Date(),
            updateCount: updateCount + 1
        )
    }
}

// MARK: - Helper Types

/// Processing speed metrics
public struct ProcessingSpeed: Equatable, Sendable {
    /// Operations per second
    public let operationsPerSecond: Double
    
    /// Average update frequency in Hz
    public let updateFrequency: Double
    
    /// Processing efficiency (0.0 to 1.0)
    public let efficiency: Double
    
    public init(
        operationsPerSecond: Double,
        updateFrequency: Double,
        efficiency: Double
    ) {
        self.operationsPerSecond = max(0, operationsPerSecond)
        self.updateFrequency = max(0, updateFrequency)
        self.efficiency = max(0, min(1.0, efficiency))
    }
}

/// Progress-related error information
public struct ProgressError: Equatable, Sendable, LocalizedError {
    /// Error type
    public let type: ProgressErrorType
    
    /// Human-readable error message
    public let message: String
    
    /// Error metadata
    public let metadata: [String: String]
    
    /// Whether the error is recoverable
    public let isRecoverable: Bool
    
    public init(
        type: ProgressErrorType,
        message: String,
        metadata: [String: String] = [:],
        isRecoverable: Bool = true
    ) {
        self.type = type
        self.message = message
        self.metadata = metadata
        self.isRecoverable = isRecoverable
    }
    
    public var errorDescription: String? {
        message
    }
}

/// Types of progress errors
public enum ProgressErrorType: String, CaseIterable, Equatable, Sendable {
    case tracking = "tracking"
    case cancelled = "cancelled"
    case timeout = "timeout"
    case serviceFailure = "service_failure"
    case networkError = "network_error"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .tracking:
            "Tracking Error"
        case .cancelled:
            "Cancelled"
        case .timeout:
            "Timeout"
        case .serviceFailure:
            "Service Error"
        case .networkError:
            "Network Error"
        case .unknown:
            "Unknown Error"
        }
    }
}

// MARK: - Private Helpers

private extension ProgressState {
    func calculateProcessingSpeed(from update: ProgressUpdate) -> ProcessingSpeed? {
        guard updateCount > 0 else { return nil }
        
        let elapsedTime = update.timestamp.timeIntervalSince(startTime)
        guard elapsedTime > 0 else { return nil }
        
        let operationsPerSecond = update.overallProgress / elapsedTime
        let updateFrequency = Double(updateCount) / elapsedTime
        let efficiency = min(1.0, operationsPerSecond * 10) // Simple efficiency metric
        
        return ProcessingSpeed(
            operationsPerSecond: operationsPerSecond,
            updateFrequency: updateFrequency,
            efficiency: efficiency
        )
    }
    
    func extractError(from update: ProgressUpdate) -> ProgressError? {
        guard update.phase == .error,
              let errorMessage = update.metadata["error"] else {
            return nil
        }
        
        let errorType: ProgressErrorType
        if let typeString = update.metadata["error_type"],
           let type = ProgressErrorType(rawValue: typeString) {
            errorType = type
        } else {
            errorType = .unknown
        }
        
        return ProgressError(
            type: errorType,
            message: errorMessage,
            metadata: update.metadata
        )
    }
}
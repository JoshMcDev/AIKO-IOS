import Foundation

/// Thread-safe Actor for coordinating progress tracking across concurrent operations
public actor ProgressTrackingEngine {
    
    // MARK: - State
    
    private var activeSessions: [UUID: SessionTracker] = [:]
    private var batchedUpdates: [UUID: [ProgressUpdate]] = [:]
    private var updateTimers: [UUID: Task<Void, Never>] = [:]
    
    // MARK: - Public Interface
    
    /// Start a new progress tracking session
    public func startSession(
        sessionId: UUID,
        config: ProgressSessionConfig = .balanced
    ) async -> AsyncStream<ProgressUpdate> {
        var tracker = SessionTracker(
            sessionId: sessionId,
            config: config,
            startTime: Date()
        )
        
        activeSessions[sessionId] = tracker
        batchedUpdates[sessionId] = []
        
        // Start the update batching timer if needed
        if config.shouldBatchUpdates {
            startBatchingTimer(for: sessionId, config: config)
        }
        
        // Create the async stream for progress updates
        return AsyncStream { continuation in
            tracker.continuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.endSession(sessionId)
                }
            }
            
            // Send initial update
            let initialUpdate = ProgressUpdate.phaseTransition(
                sessionId: sessionId,
                to: .initializing
            )
            continuation.yield(initialUpdate)
        }
    }
    
    /// Submit a progress update for a session
    public func submitUpdate(_ update: ProgressUpdate) async {
        guard let tracker = activeSessions[update.sessionId] else {
            return
        }
        
        // Validate update
        guard await isValidUpdate(update, for: tracker) else {
            return
        }
        
        // Update session state
        await updateSessionState(sessionId: update.sessionId, with: update)
        
        // Handle update delivery based on batching configuration
        if tracker.config.shouldBatchUpdates {
            await batchUpdate(update)
        } else {
            await deliverUpdate(update)
        }
    }
    
    /// Cancel a progress session
    public func cancelSession(_ sessionId: UUID) async {
        guard let tracker = activeSessions[sessionId] else {
            return
        }
        
        // Send cancellation update
        let cancelUpdate = ProgressUpdate.error(
            sessionId: sessionId,
            phase: tracker.currentState.currentPhase,
            phaseProgress: tracker.currentState.phaseProgress,
            error: "Operation cancelled by user"
        )
        
        await deliverUpdate(cancelUpdate)
        await endSession(sessionId)
    }
    
    /// Complete a progress session
    public func completeSession(_ sessionId: UUID) async {
        guard activeSessions[sessionId] != nil else {
            return
        }
        
        let completionUpdate = ProgressUpdate.completion(sessionId: sessionId)
        await deliverUpdate(completionUpdate)
        await endSession(sessionId)
    }
    
    /// Get current state for a session
    public func getSessionState(_ sessionId: UUID) async -> ProgressState? {
        return activeSessions[sessionId]?.currentState
    }
    
    /// Get all active session IDs
    public func getActiveSessions() async -> [UUID] {
        return Array(activeSessions.keys)
    }
    
    /// Clean up expired sessions
    public func cleanupExpiredSessions() async {
        let now = Date()
        let expiredSessions = activeSessions.compactMap { (sessionId, tracker) in
            let elapsed = now.timeIntervalSince(tracker.startTime)
            return elapsed > tracker.config.sessionTimeout ? sessionId : nil
        }
        
        for sessionId in expiredSessions {
            await timeoutSession(sessionId)
        }
    }
}

// MARK: - Private Implementation

private extension ProgressTrackingEngine {
    
    /// Session tracking data
    struct SessionTracker {
        let sessionId: UUID
        let config: ProgressSessionConfig
        let startTime: Date
        var currentState: ProgressState
        var continuation: AsyncStream<ProgressUpdate>.Continuation?
        var lastDeliveryTime: Date
        var updateCount: Int
        
        init(sessionId: UUID, config: ProgressSessionConfig, startTime: Date) {
            self.sessionId = sessionId
            self.config = config
            self.startTime = startTime
            self.currentState = ProgressState.initial(sessionId: sessionId)
            self.lastDeliveryTime = startTime
            self.updateCount = 0
        }
        
        mutating func updateState(with update: ProgressUpdate) {
            currentState = currentState.applying(update)
            updateCount += 1
        }
        
        func shouldDeliverUpdate(_ update: ProgressUpdate) -> Bool {
            let now = Date()
            let timeSinceLastUpdate = now.timeIntervalSince(lastDeliveryTime)
            let progressDelta = abs(update.overallProgress - currentState.overallProgress)
            
            // Always deliver terminal states
            if update.phase.isTerminal {
                return true
            }
            
            // Check frequency limit
            if timeSinceLastUpdate < config.updateInterval {
                return false
            }
            
            // Check progress delta
            return progressDelta >= config.minProgressDelta
        }
    }
    
    func isValidUpdate(_ update: ProgressUpdate, for tracker: SessionTracker) async -> Bool {
        // Check session ID match
        guard update.sessionId == tracker.sessionId else {
            return false
        }
        
        // Check progress bounds
        guard update.phaseProgress >= 0.0 && update.phaseProgress <= 1.0,
              update.overallProgress >= 0.0 && update.overallProgress <= 1.0 else {
            return false
        }
        
        // Check progress doesn't go backwards (except for errors)
        if update.phase != .error &&
           update.overallProgress < tracker.currentState.overallProgress {
            return false
        }
        
        return true
    }
    
    func updateSessionState(sessionId: UUID, with update: ProgressUpdate) async {
        guard var tracker = activeSessions[sessionId] else {
            return
        }
        
        tracker.updateState(with: update)
        activeSessions[sessionId] = tracker
    }
    
    func batchUpdate(_ update: ProgressUpdate) async {
        var updates = batchedUpdates[update.sessionId] ?? []
        updates.append(update)
        batchedUpdates[update.sessionId] = updates
    }
    
    func deliverUpdate(_ update: ProgressUpdate) async {
        guard let tracker = activeSessions[update.sessionId],
              let continuation = tracker.continuation else {
            return
        }
        
        continuation.yield(update)
        
        // Update last delivery time
        if var updatedTracker = activeSessions[update.sessionId] {
            updatedTracker.lastDeliveryTime = Date()
            activeSessions[update.sessionId] = updatedTracker
        }
    }
    
    func startBatchingTimer(for sessionId: UUID, config: ProgressSessionConfig) {
        updateTimers[sessionId] = Task {
            while !Task.isCancelled && activeSessions[sessionId] != nil {
                try? await Task.sleep(nanoseconds: UInt64(config.batchUpdateWindow * 1_000_000_000))
                await processBatchedUpdates(for: sessionId)
            }
        }
    }
    
    func processBatchedUpdates(for sessionId: UUID) async {
        guard let updates = batchedUpdates[sessionId],
              !updates.isEmpty,
              let tracker = activeSessions[sessionId] else {
            return
        }
        
        // Find the most recent update that should be delivered
        _ = Date() // Used for timing if needed in future
        let validUpdates = updates.filter { update in
            let mockTracker = SessionTracker(
                sessionId: sessionId,
                config: tracker.config,
                startTime: tracker.startTime
            )
            return mockTracker.shouldDeliverUpdate(update)
        }
        
        if let latestUpdate = validUpdates.last {
            await deliverUpdate(latestUpdate)
        }
        
        // Clear batched updates
        batchedUpdates[sessionId] = []
    }
    
    func endSession(_ sessionId: UUID) async {
        activeSessions[sessionId]?.continuation?.finish()
        activeSessions.removeValue(forKey: sessionId)
        batchedUpdates.removeValue(forKey: sessionId)
        updateTimers[sessionId]?.cancel()
        updateTimers.removeValue(forKey: sessionId)
    }
    
    func timeoutSession(_ sessionId: UUID) async {
        guard let tracker = activeSessions[sessionId] else {
            return
        }
        
        let timeoutUpdate = ProgressUpdate.error(
            sessionId: sessionId,
            phase: tracker.currentState.currentPhase,
            phaseProgress: tracker.currentState.phaseProgress,
            error: "Session timed out after \(tracker.config.sessionTimeout) seconds"
        )
        
        await deliverUpdate(timeoutUpdate)
        await endSession(sessionId)
    }
}

// MARK: - Error Types

public enum ProgressTrackingError: LocalizedError, Equatable, Sendable {
    case sessionNotFound(UUID)
    case invalidUpdate(String)
    case sessionExpired(UUID)
    case engineShutdown
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotFound(let sessionId):
            "Progress session not found: \(sessionId)"
        case .invalidUpdate(let reason):
            "Invalid progress update: \(reason)"
        case .sessionExpired(let sessionId):
            "Progress session expired: \(sessionId)"
        case .engineShutdown:
            "Progress tracking engine is shutting down"
        }
    }
}
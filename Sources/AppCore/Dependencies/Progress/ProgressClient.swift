import Foundation

/// TCA dependency client for progress tracking operations
public struct ProgressClient: Sendable {
    /// Start a new progress tracking session
    public var startSession: @Sendable (UUID, ProgressSessionConfig?) async -> AsyncStream<ProgressUpdate> = { _, _ in AsyncStream { _ in } }

    /// Submit a progress update for a session
    public var submitUpdate: @Sendable (ProgressUpdate) async -> Void = { _ in }

    /// Cancel a progress tracking session
    public var cancelSession: @Sendable (UUID) async -> Void = { _ in }

    /// Complete a progress tracking session
    public var completeSession: @Sendable (UUID) async -> Void = { _ in }

    /// Get current state for a session
    public var getSessionState: @Sendable (UUID) async -> ProgressState? = { _ in nil }

    /// Get all active session IDs
    public var getActiveSessions: @Sendable () async -> [UUID] = { [] }

    /// Check if progress tracking is available
    public var isAvailable: @Sendable () -> Bool = { false }
}

// MARK: - Live Implementation

public extension ProgressClient {
    static let liveValue: Self = {
        let engine = ProgressTrackingEngine()

        // Start cleanup timer
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                await engine.cleanupExpiredSessions()
            }
        }

        return Self(
            startSession: { sessionId, config in
                await engine.startSession(
                    sessionId: sessionId,
                    config: config ?? .balanced
                )
            },
            submitUpdate: { update in
                await engine.submitUpdate(update)
            },
            cancelSession: { sessionId in
                await engine.cancelSession(sessionId)
            },
            completeSession: { sessionId in
                await engine.completeSession(sessionId)
            },
            getSessionState: { sessionId in
                await engine.getSessionState(sessionId)
            },
            getActiveSessions: {
                await engine.getActiveSessions()
            },
            isAvailable: { true }
        )
    }()

    static let testValue: Self = .init(
        startSession: { sessionId, _ in
            AsyncStream { continuation in
                // Send initial update
                let initialUpdate = ProgressUpdate.phaseTransition(
                    sessionId: sessionId,
                    to: .initializing
                )
                continuation.yield(initialUpdate)

                // Simulate progress updates
                Task {
                    let phases: [ProgressPhase] = [.scanning, .processing, .ocr, .formPopulation, .completed]

                    for (index, phase) in phases.enumerated() {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                        if phase == .completed {
                            let completionUpdate = ProgressUpdate.completion(sessionId: sessionId)
                            continuation.yield(completionUpdate)
                            continuation.finish()
                        } else {
                            // Phase transition
                            let transitionUpdate = ProgressUpdate.phaseTransition(
                                sessionId: sessionId,
                                to: phase
                            )
                            continuation.yield(transitionUpdate)

                            // Progress within phase
                            for progress in stride(from: 0.2, through: 1.0, by: 0.2) {
                                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

                                let progressUpdate = ProgressUpdate.phaseUpdate(
                                    sessionId: sessionId,
                                    phase: phase,
                                    phaseProgress: progress
                                )
                                continuation.yield(progressUpdate)
                            }
                        }
                    }
                }

                continuation.onTermination = { _ in
                    // Cleanup handled by continuation finishing
                }
            }
        },
        submitUpdate: { _ in
            // Test implementation - updates are handled by the stream
        },
        cancelSession: { _ in
            // Test implementation - cancellation handled by stream termination
        },
        completeSession: { _ in
            // Test implementation - completion handled by the stream
        },
        getSessionState: { sessionId in
            // Return mock state for testing
            ProgressState.initial(sessionId: sessionId)
        },
        getActiveSessions: {
            // Return empty for test
            []
        },
        isAvailable: { true }
    )

    static let previewValue: Self = testValue
}

// MARK: - Dependency Registration

// MARK: - Convenience Extensions

public extension ProgressClient {
    /// Start a session with default configuration
    func startSession(_ sessionId: UUID) async -> AsyncStream<ProgressUpdate> {
        await startSession(sessionId, .balanced)
    }

    /// Submit a phase transition update
    func submitPhaseTransition(
        sessionId: UUID,
        to phase: ProgressPhase,
        metadata: [String: String] = [:]
    ) async {
        let update = ProgressUpdate.phaseTransition(
            sessionId: sessionId,
            to: phase,
            metadata: metadata
        )
        await submitUpdate(update)
    }

    /// Submit a progress update within the current phase
    func submitPhaseProgress(
        sessionId: UUID,
        phase: ProgressPhase,
        progress: Double,
        operation: String? = nil,
        estimatedTimeRemaining: TimeInterval? = nil
    ) async {
        let update = ProgressUpdate.phaseUpdate(
            sessionId: sessionId,
            phase: phase,
            phaseProgress: progress,
            operation: operation,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
        await submitUpdate(update)
    }

    /// Submit an error update
    func submitError(
        sessionId: UUID,
        phase: ProgressPhase,
        phaseProgress: Double,
        error: String,
        metadata: [String: String] = [:]
    ) async {
        let update = ProgressUpdate.error(
            sessionId: sessionId,
            phase: phase,
            phaseProgress: phaseProgress,
            error: error,
            metadata: metadata
        )
        await submitUpdate(update)
    }

    /// Track progress from another client's progress callback
    func trackProgressCallback<T>(
        sessionId: UUID,
        phase: ProgressPhase,
        operation: @escaping () async throws -> T,
        progressMapper _: @escaping (Double) -> Double = { $0 }
    ) async throws -> T {
        // Submit phase transition
        await submitPhaseTransition(sessionId: sessionId, to: phase)

        // Execute operation with progress tracking
        do {
            let result = try await operation()
            // Submit completion for this phase
            await submitPhaseProgress(
                sessionId: sessionId,
                phase: phase,
                progress: 1.0
            )
            return result
        } catch {
            // Submit error
            await submitError(
                sessionId: sessionId,
                phase: phase,
                phaseProgress: 0.5,
                error: error.localizedDescription
            )
            throw error
        }
    }
}

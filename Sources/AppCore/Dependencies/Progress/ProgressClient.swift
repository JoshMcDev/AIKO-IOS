import ComposableArchitecture
@preconcurrency import Combine
import Foundation

/// Client for managing progress tracking sessions across the AIKO application
/// 
/// This client provides a unified interface for tracking progress of long-running operations
/// such as document scanning, processing, and analysis. It supports:
/// - Session-based progress tracking with unique identifiers
/// - Real-time progress updates through Combine publishers
/// - Accessibility-first progress reporting
/// - Thread-safe operations with Swift 6 concurrency
///
/// **Usage Example:**
/// ```swift
/// let session = await progressClient.createSession(.defaultSinglePageScan)
/// await progressClient.updateProgress(session.id, ProgressUpdate(phase: .scanning, fraction: 0.3))
/// await progressClient.completeSession(session.id)
/// ```
@DependencyClient
public struct ProgressClient: Sendable {
    /// Create a new progress tracking session
    /// - Parameter config: Configuration for the progress session including expected phases and steps
    /// - Returns: A new progress session with unique identifier and publisher for real-time updates
    public var createSession: @Sendable (ProgressSessionConfig) async -> ProgressSession = { _ in .mock }

    /// Update progress for an active session
    /// - Parameters:
    ///   - sessionId: Unique identifier of the progress session
    ///   - update: Progress update containing new phase, fraction, and step information
    public var updateProgress: @Sendable (UUID, ProgressUpdate) async -> Void = { _, _ in }

    /// Complete a progress session successfully
    /// - Parameter sessionId: Unique identifier of the progress session to complete
    public var completeSession: @Sendable (UUID) async -> Void = { _ in }

    /// Cancel a progress session (operation was interrupted or failed)
    /// - Parameter sessionId: Unique identifier of the progress session to cancel
    public var cancelSession: @Sendable (UUID) async -> Void = { _ in }

    /// Get the current state for an active session
    /// - Parameter sessionId: Unique identifier of the progress session
    /// - Returns: Current progress state, or nil if session doesn't exist
    public var getCurrentState: @Sendable (UUID) async -> ProgressState? = { _ in nil }

    /// Check if a session is currently active and accepting updates
    /// - Parameter sessionId: Unique identifier of the progress session
    /// - Returns: True if the session exists and is active
    public var isSessionActive: @Sendable (UUID) async -> Bool = { _ in false }
}

/// Represents an active progress tracking session
/// 
/// A progress session provides real-time updates for long-running operations.
/// Each session has a unique identifier and publishes progress state changes
/// through a Combine publisher for SwiftUI integration.
///
/// **Key Features:**
/// - Unique session identifier for tracking multiple concurrent operations
/// - Configuration-based setup defining expected phases and steps
/// - Real-time publisher for live progress updates in the UI
/// - Thread-safe design compatible with Swift 6 strict concurrency
public struct ProgressSession: Sendable, Identifiable, Equatable {
    /// Unique identifier for this progress session
    public let id: UUID

    /// Configuration used to create this session
    public let config: ProgressSessionConfig

    /// Publisher that emits progress state updates in real-time
    public nonisolated(unsafe) let progressPublisher: AnyPublisher<ProgressState, Never>

    /// Timestamp when this session was created
    public let createdAt: Date

    public init(
        config: ProgressSessionConfig,
        progressPublisher: AnyPublisher<ProgressState, Never>
    ) {
        // STUB IMPLEMENTATION - Basic initialization
        self.id = UUID()
        self.config = config
        self.progressPublisher = progressPublisher
        self.createdAt = Date()
    }

    public static func == (lhs: ProgressSession, rhs: ProgressSession) -> Bool {
        lhs.id == rhs.id
    }

    public static let mock = ProgressSession(
        config: .defaultSinglePageScan,
        progressPublisher: Just(ProgressState(
            phase: .idle,
            fractionCompleted: 0.0,
            currentStep: "Ready"
        )).eraseToAnyPublisher()
    )
}

extension ProgressClient: DependencyKey {
    public static let liveValue: ProgressClient = {
        // Shared state for live implementation
        let sessionManager = LiveProgressSessionManager()

        return ProgressClient(
            createSession: { config in
                await sessionManager.createSession(config: config)
            },
            updateProgress: { sessionId, update in
                await sessionManager.updateProgress(sessionId: sessionId, update: update)
            },
            completeSession: { sessionId in
                await sessionManager.completeSession(sessionId: sessionId)
            },
            cancelSession: { sessionId in
                await sessionManager.cancelSession(sessionId: sessionId)
            },
            getCurrentState: { sessionId in
                await sessionManager.getCurrentState(sessionId: sessionId)
            },
            isSessionActive: { sessionId in
                await sessionManager.isSessionActive(sessionId: sessionId)
            }
        )
    }()

    public static let testValue: ProgressClient = {
        // Shared state for test implementation
        let sessionManager = TestProgressSessionManager()

        return ProgressClient(
            createSession: { config in
                await sessionManager.createSession(config: config)
            },
            updateProgress: { sessionId, update in
                await sessionManager.updateProgress(sessionId: sessionId, update: update)
            },
            completeSession: { sessionId in
                await sessionManager.completeSession(sessionId: sessionId)
            },
            cancelSession: { sessionId in
                await sessionManager.cancelSession(sessionId: sessionId)
            },
            getCurrentState: { sessionId in
                await sessionManager.getCurrentState(sessionId: sessionId)
            },
            isSessionActive: { sessionId in
                await sessionManager.isSessionActive(sessionId: sessionId)
            }
        )
    }()
}

// MARK: - Live Implementation

@MainActor
private final class LiveProgressSessionManager {
    private var activeSessions: [UUID: (ProgressState, CurrentValueSubject<ProgressState, Never>)] = [:]

    func createSession(config: ProgressSessionConfig) -> ProgressSession {
        let sessionId = UUID()
        let initialState = ProgressState(
            phase: .preparing,
            fractionCompleted: 0.0,
            currentStep: "Initializing...",
            totalSteps: config.expectedPhases.count,
            currentStepIndex: 0
        )

        let subject = CurrentValueSubject<ProgressState, Never>(initialState)
        activeSessions[sessionId] = (initialState, subject)

        return ProgressSession(
            id: sessionId,
            config: config,
            progressPublisher: subject.eraseToAnyPublisher(),
            createdAt: Date()
        )
    }

    func updateProgress(sessionId: UUID, update: ProgressUpdate) {
        guard let (_, subject) = activeSessions[sessionId] else { return }

        let newState = ProgressState(
            phase: update.phase,
            fractionCompleted: update.fractionCompleted,
            currentStep: update.message
        )

        activeSessions[sessionId] = (newState, subject)
        subject.send(newState)
    }

    func completeSession(sessionId: UUID) {
        guard let (_, subject) = activeSessions[sessionId] else { return }

        subject.send(completion: .finished)
        activeSessions.removeValue(forKey: sessionId)
    }

    func cancelSession(sessionId: UUID) {
        guard let (_, subject) = activeSessions[sessionId] else { return }

        subject.send(completion: .finished)
        activeSessions.removeValue(forKey: sessionId)
    }

    func getCurrentState(sessionId: UUID) async -> ProgressState? {
        return activeSessions[sessionId]?.0
    }

    func isSessionActive(sessionId: UUID) async -> Bool {
        return activeSessions[sessionId] != nil
    }
}

// MARK: - Test Implementation

private final class TestProgressSessionManager: @unchecked Sendable {
    private let lock = NSLock()
    private var activeSessions: [UUID: ProgressState] = [:]

    func createSession(config: ProgressSessionConfig) -> ProgressSession {
        let sessionId = UUID()
        let initialState = ProgressState(
            phase: .preparing,
            fractionCompleted: 0.0,
            currentStep: "Initializing...",
            totalSteps: config.expectedPhases.count,
            currentStepIndex: 0
        )

        lock.withLock {
            activeSessions[sessionId] = initialState
        }

        let subject = CurrentValueSubject<ProgressState, Never>(initialState)

        let session = ProgressSession(
            id: sessionId,
            config: config,
            progressPublisher: subject.eraseToAnyPublisher(),
            createdAt: Date()
        )

        return session
    }

    func updateProgress(sessionId: UUID, update: ProgressUpdate) {
        lock.withLock {
            guard activeSessions[sessionId] != nil else { return }

            let newState = ProgressState(
                phase: update.phase,
                fractionCompleted: update.fractionCompleted,
                currentStep: update.message
            )

            activeSessions[sessionId] = newState
        }
    }

    func completeSession(sessionId: UUID) {
        lock.withLock {
            activeSessions.removeValue(forKey: sessionId)
        }
    }

    func cancelSession(sessionId: UUID) {
        lock.withLock {
            activeSessions.removeValue(forKey: sessionId)
        }
    }

    func getCurrentState(sessionId: UUID) async -> ProgressState? {
        return lock.withLock {
            return activeSessions[sessionId]
        }
    }

    func isSessionActive(sessionId: UUID) async -> Bool {
        return lock.withLock {
            return activeSessions[sessionId] != nil
        }
    }
}

extension ProgressSession {
    init(id: UUID, config: ProgressSessionConfig, progressPublisher: AnyPublisher<ProgressState, Never>, createdAt: Date) {
        self.id = id
        self.config = config
        self.progressPublisher = progressPublisher
        self.createdAt = createdAt
    }
}

extension DependencyValues {
    public var progressClient: ProgressClient {
        get { self[ProgressClient.self] }
        set { self[ProgressClient.self] = newValue }
    }
}

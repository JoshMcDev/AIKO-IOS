import Combine
import ComposableArchitecture
import Foundation

/// TCA Feature for managing progress feedback across the application
@Reducer
public struct ProgressFeedbackFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var activeSessions: [UUID: ProgressState] = [:]
        public var currentSession: UUID?
        public var accessibilityAnnouncements: [String] = []
        public var lastAnnouncedProgress: [UUID: Int] = [:]

        public var currentProgress: ProgressState? {
            guard let currentSession else { return nil }
            return activeSessions[currentSession]
        }

        public var isActive: Bool {
            !activeSessions.isEmpty
        }

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        // Public Actions
        case startSession(ProgressSessionConfig)
        case updateProgress(UUID, ProgressUpdate)
        case completeSession(UUID)
        case cancelSession(UUID)
        case setCurrentSession(UUID?)
        case clearAccessibilityAnnouncements

        // Internal Actions
        case _sessionCreated
        case _progressReceived(UUID, ProgressState)
        case _sessionCompleted(UUID)
        case _sessionCancelled(UUID)
        case _announceProgress
    }

    @Dependency(\.progressClient) var progressClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .startSession(config):
                return .run { send in
                    // Start the session through the client
                    let sessionId = UUID()
                    _ = await progressClient.startSession(sessionId, config)
                    await send(._sessionCreated)
                }

            case ._sessionCreated:
                // Create a session with proper initial state
                let sessionId = UUID()
                let initialState = ProgressState.initial(sessionId: sessionId)

                state.activeSessions[sessionId] = initialState
                if state.currentSession == nil {
                    state.currentSession = sessionId
                }

                return .none

            case let .updateProgress(_, update):
                return .run { _ in
                    await progressClient.submitUpdate(update)
                }

            case let ._progressReceived(sessionId, progressState):
                guard state.activeSessions[sessionId] != nil else {
                    return .none
                }

                state.activeSessions[sessionId] = progressState

                // Check if we should announce progress (25% increments)
                let currentPercent = Int(progressState.overallProgress * 100)
                let lastAnnouncedPercent = state.lastAnnouncedProgress[sessionId] ?? -1

                let shouldAnnounce = (currentPercent >= 25 && currentPercent % 25 == 0 && currentPercent > lastAnnouncedPercent)

                if shouldAnnounce {
                    state.lastAnnouncedProgress[sessionId] = currentPercent
                    let announcement = "\(progressState.currentPhase.displayName): \(currentPercent)% complete"
                    state.accessibilityAnnouncements.append(announcement)
                    return .send(._announceProgress)
                }

                return .none

            case let .completeSession(sessionId):
                return .run { send in
                    await progressClient.completeSession(sessionId)
                    await send(._sessionCompleted(sessionId))
                }

            case let ._sessionCompleted(sessionId):
                state.activeSessions.removeValue(forKey: sessionId)
                state.lastAnnouncedProgress.removeValue(forKey: sessionId)

                // Update current session
                if state.currentSession == sessionId {
                    state.currentSession = state.activeSessions.keys.first
                }

                return .cancel(id: CancelID.progressSubscription(sessionId))

            case let .cancelSession(sessionId):
                return .run { send in
                    await progressClient.cancelSession(sessionId)
                    await send(._sessionCancelled(sessionId))
                }

            case let ._sessionCancelled(sessionId):
                state.activeSessions.removeValue(forKey: sessionId)
                state.lastAnnouncedProgress.removeValue(forKey: sessionId)

                // Update current session
                if state.currentSession == sessionId {
                    state.currentSession = state.activeSessions.keys.first
                }

                return .cancel(id: CancelID.progressSubscription(sessionId))

            case let .setCurrentSession(sessionId):
                state.currentSession = sessionId
                return .none

            case .clearAccessibilityAnnouncements:
                state.accessibilityAnnouncements.removeAll()
                return .none

            case ._announceProgress:
                // This action is for triggering accessibility announcements
                // The actual announcement handling would be done by the UI layer
                return .none
            }
        }
    }
}

extension ProgressFeedbackFeature {
    enum CancelID: Hashable {
        case progressSubscription(UUID)
    }
}

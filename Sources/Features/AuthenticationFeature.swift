import ComposableArchitecture
import Foundation
import LocalAuthentication

/// Handles app authentication state and biometric authentication
@Reducer
public struct AuthenticationFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var isAuthenticating: Bool = false
        public var isAuthenticated: Bool = false
        public var authenticationError: String?
        public var biometricType: BiometricType = .none
        public var lastAuthenticationDate: Date?
        public var requiresAuthentication: Bool = true

        public init(
            isAuthenticated: Bool = false,
            requiresAuthentication: Bool = true
        ) {
            self.isAuthenticated = isAuthenticated
            self.requiresAuthentication = requiresAuthentication
        }
    }

    // MARK: - Action

    public enum Action: Equatable {
        case checkBiometricAvailability
        case authenticate
        case authenticationStarted
        case authenticationSucceeded
        case authenticationFailed(String)
        case logout
        case setRequiresAuthentication(Bool)
        case biometricTypeDetected(BiometricType)
    }

    // MARK: - Dependencies

    @Dependency(\.biometricAuthenticationService) var biometricAuth
    @Dependency(\.date) var date

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkBiometricAvailability:
                return .run { send in
                    let biometricType = await detectBiometricType()
                    await send(.biometricTypeDetected(biometricType))
                }

            case .authenticate:
                guard !state.isAuthenticating,
                      state.biometricType != .none else { return .none }

                return .concatenate(
                    .send(.authenticationStarted),
                    .run { [biometricType = state.biometricType] send in
                        do {
                            let reason = authenticationReason(for: biometricType)
                            let success = try await biometricAuth.authenticate(reason)

                            if success {
                                await send(.authenticationSucceeded)
                            } else {
                                await send(.authenticationFailed("Authentication was cancelled"))
                            }
                        } catch {
                            await send(.authenticationFailed(error.localizedDescription))
                        }
                    }
                )

            case .authenticationStarted:
                state.isAuthenticating = true
                state.authenticationError = nil
                return .none

            case .authenticationSucceeded:
                state.isAuthenticating = false
                state.isAuthenticated = true
                state.authenticationError = nil
                state.lastAuthenticationDate = date.now
                return .none

            case let .authenticationFailed(error):
                state.isAuthenticating = false
                state.isAuthenticated = false
                state.authenticationError = error
                return .none

            case .logout:
                state.isAuthenticated = false
                state.lastAuthenticationDate = nil
                state.authenticationError = nil
                return .none

            case let .setRequiresAuthentication(required):
                state.requiresAuthentication = required
                if !required {
                    state.isAuthenticated = true
                }
                return .none

            case let .biometricTypeDetected(type):
                state.biometricType = type
                return .none
            }
        }
    }

    // MARK: - Helper Methods

    private func detectBiometricType() async -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    private func authenticationReason(for type: BiometricType) -> String {
        switch type {
        case .faceID:
            "Use Face ID to access AIKO"
        case .touchID:
            "Use Touch ID to access AIKO"
        case .opticID:
            "Use Optic ID to access AIKO"
        case .none:
            "Authenticate to access AIKO"
        }
    }
}

// MARK: - Models

public enum BiometricType: String, Equatable, Sendable {
    case none = "None"
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"

    public var iconName: String {
        switch self {
        case .none:
            "lock"
        case .faceID:
            "faceid"
        case .touchID:
            "touchid"
        case .opticID:
            "opticid"
        }
    }
}

// MARK: - Extensions

public extension AuthenticationFeature.State {
    /// Check if authentication is needed
    var needsAuthentication: Bool {
        requiresAuthentication && !isAuthenticated
    }

    /// Check if biometric authentication is available
    var canUseBiometrics: Bool {
        biometricType != .none
    }

    /// Get human-readable authentication status
    var authenticationStatus: String {
        if isAuthenticating {
            "Authenticating..."
        } else if isAuthenticated {
            "Authenticated"
        } else if let error = authenticationError {
            "Authentication failed: \(error)"
        } else {
            "Not authenticated"
        }
    }

    /// Check if authentication is fresh (within last 5 minutes)
    func isAuthenticationFresh(now: Date = Date()) -> Bool {
        guard let lastAuth = lastAuthenticationDate else { return false }
        return now.timeIntervalSince(lastAuth) < 300 // 5 minutes
    }
}

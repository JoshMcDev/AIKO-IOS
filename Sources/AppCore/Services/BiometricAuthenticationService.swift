import Foundation
@preconcurrency import LocalAuthentication

/// Protocol for biometric authentication services
@MainActor
public protocol BiometricAuthenticationServiceProtocol: ObservableObject {
    nonisolated func canEvaluateBiometrics() -> Bool
    nonisolated func canEvaluateDeviceOwnerAuthentication() -> Bool
    func authenticateWithBiometrics(reason: String) async throws -> Bool
    func authenticateWithPasscode(reason: String) async throws -> Bool
    nonisolated func biometryType() -> LABiometryType
    nonisolated func biometryDescription() -> String
    nonisolated func resetContext()
}

/// Service for handling biometric authentication using Local Authentication framework
/// Preserves security patterns from original TCA implementation (lines 395-424)
@MainActor
public final class BiometricAuthenticationService: ObservableObject, BiometricAuthenticationServiceProtocol {
    // MARK: - Properties

    private let context = LAContext()

    // MARK: - Public Methods

    /// Check if biometric authentication is available on the device
    nonisolated public func canEvaluateBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Check if device owner authentication (biometrics or passcode) is available
    nonisolated public func canEvaluateDeviceOwnerAuthentication() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Authenticate using biometrics with the specified reason
    /// - Parameter reason: Localized reason to display to the user
    /// - Returns: True if authentication succeeded, false otherwise
    /// - Throws: LAError if authentication fails
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        guard canEvaluateBiometrics() else {
            throw LAError(.biometryNotAvailable)
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }

    /// Authenticate using device owner authentication (biometrics or passcode)
    /// - Parameter reason: Localized reason to display to the user
    /// - Returns: True if authentication succeeded, false otherwise
    /// - Throws: LAError if authentication fails
    public func authenticateWithPasscode(reason: String) async throws -> Bool {
        try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        )
    }

    /// Get the type of biometric authentication available
    nonisolated public func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }

    /// Get a localized description of the biometric authentication type
    nonisolated public func biometryDescription() -> String {
        switch biometryType() {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Device Passcode"
        @unknown default:
            return "Biometric Authentication"
        }
    }

    /// Reset the authentication context (useful for testing)
    nonisolated public func resetContext() {
        // Create a new context to clear any cached authentication state
        // Note: LAContext doesn't have a public reset method
        Task { @MainActor in
            context.invalidate()
        }
    }
}

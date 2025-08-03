import Foundation
@preconcurrency import LocalAuthentication

/// Service for handling biometric authentication using Local Authentication framework
/// Preserves security patterns from original TCA implementation (lines 395-424)
@MainActor
public final class BiometricAuthenticationService: ObservableObject {
    // MARK: - Properties

    private let context = LAContext()

    // MARK: - Public Methods

    /// Check if biometric authentication is available on the device
    public func canEvaluateBiometrics() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Check if device owner authentication (biometrics or passcode) is available
    public func canEvaluateDeviceOwnerAuthentication() -> Bool {
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
    public func biometryType() -> LABiometryType {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }

    /// Get a localized description of the biometric authentication type
    public func biometryDescription() -> String {
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
    public func resetContext() {
        // Create a new context to clear any cached authentication state
        // Note: LAContext doesn't have a public reset method
        Task { @MainActor in
            context.invalidate()
        }
    }
}

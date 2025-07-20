import Foundation

/// Types of biometric authentication available
public enum BiometricType: Sendable {
    case faceID
    case touchID
    case none
}

/// Errors that can occur during biometric authentication
public enum BiometricError: Error, Sendable {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case passcodeNotSet
    case unknown(Error)
}

/// Platform-agnostic protocol for biometric authentication
public protocol BiometricAuthenticationProtocol: Sendable {
    /// Get the available biometric type on the device
    func biometricType() -> BiometricType

    /// Authenticate using biometrics with a reason string
    func authenticate(reason: String) async throws -> Bool
}

import Foundation
import LocalAuthentication

public struct BiometricAuthenticationService: Sendable {
    public enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancelled
        case passcodeNotSet
        case unknown(Error)
    }

    public enum BiometricType {
        case faceID
        case touchID
        case none
    }

    public var biometricType: @Sendable () -> BiometricType
    public var authenticate: @Sendable (String) async throws -> Bool

    public init(
        biometricType: @escaping @Sendable () -> BiometricType,
        authenticate: @escaping @Sendable (String) async throws -> Bool
    ) {
        self.biometricType = biometricType
        self.authenticate = authenticate
    }
}

extension BiometricAuthenticationService {
    public static var liveValue: BiometricAuthenticationService {
        BiometricAuthenticationService(
            biometricType: {
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
                case .none:
                    return .none
                case .opticID:
                    return .faceID // Treat OpticID as FaceID for now
                @unknown default:
                    return .none
                }
            },
            authenticate: { reason in
                let context = LAContext()
                var error: NSError?

                // Check if biometric authentication is available
                guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                    if let error {
                        throw mapError(error)
                    }
                    throw BiometricError.notAvailable
                }

                // Perform authentication
                do {
                    let success = try await context.evaluatePolicy(
                        .deviceOwnerAuthenticationWithBiometrics,
                        localizedReason: reason
                    )
                    return success
                } catch let authError as NSError {
                    throw mapError(authError)
                }
            }
        )
    }

    public static var testValue: BiometricAuthenticationService {
        BiometricAuthenticationService(
            biometricType: { .faceID },
            authenticate: { _ in true }
        )
    }

    public static var previewValue: BiometricAuthenticationService {
        BiometricAuthenticationService(
            biometricType: { .none },
            authenticate: { _ in true }
        )
    }
}

private func mapError(_ error: NSError) -> BiometricAuthenticationService.BiometricError {
    switch error.code {
    case LAError.biometryNotAvailable.rawValue:
        .notAvailable
    case LAError.biometryNotEnrolled.rawValue:
        .notEnrolled
    case LAError.authenticationFailed.rawValue:
        .authenticationFailed
    case LAError.userCancel.rawValue:
        .userCancelled
    case LAError.passcodeNotSet.rawValue:
        .passcodeNotSet
    default:
        .unknown(error)
    }
}

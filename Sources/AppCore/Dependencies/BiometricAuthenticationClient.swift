import Foundation

/// TCA-compatible dependency client for biometric authentication
public struct BiometricAuthenticationClient: Sendable {
    public var biometricType: @Sendable () -> BiometricType = { .none }
    public var authenticate: @Sendable (String) async throws -> Bool
}

extension BiometricAuthenticationClient {
    public static let testValue = Self(authenticate: { _ in false })
    public static let previewValue = Self(
        biometricType: { .none },
        authenticate: { _ in true }
    )
}

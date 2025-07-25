import Foundation

/// TCA-compatible dependency client for biometric authentication
public struct BiometricAuthenticationClient: Sendable {
    public var biometricType: @Sendable () -> BiometricType = { .none }
    public var authenticate: @Sendable (String) async throws -> Bool
}

public extension BiometricAuthenticationClient {
    static let testValue = Self(authenticate: { _ in false })
    static let previewValue = Self(
        biometricType: { .none },
        authenticate: { _ in true }
    )
}

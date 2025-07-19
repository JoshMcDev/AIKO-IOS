import ComposableArchitecture
import Foundation

/// TCA-compatible dependency client for biometric authentication
@DependencyClient
public struct BiometricAuthenticationClient {
    public var biometricType: @Sendable () -> BiometricType = { .none }
    public var authenticate: @Sendable (String) async throws -> Bool
}

extension BiometricAuthenticationClient: TestDependencyKey {
    public static var testValue = Self()
    public static var previewValue = Self(
        biometricType: { .none },
        authenticate: { _ in true }
    )
}

public extension DependencyValues {
    var biometricAuthenticationClient: BiometricAuthenticationClient {
        get { self[BiometricAuthenticationClient.self] }
        set { self[BiometricAuthenticationClient.self] = newValue }
    }
}
import ComposableArchitecture
import Foundation

/// TCA-compatible dependency client for user profile management
@DependencyClient
public struct UserProfileClient {
    public var loadProfile: @Sendable () async throws -> UserProfile?
    public var saveProfile: @Sendable (UserProfile) async throws -> Void
    public var deleteProfile: @Sendable () async throws -> Void
    public var hasProfile: @Sendable () async -> Bool = { false }
}

extension UserProfileClient: TestDependencyKey {
    public static var testValue = Self()
    public static var previewValue = Self(
        loadProfile: { nil },
        saveProfile: { _ in },
        deleteProfile: { },
        hasProfile: { false }
    )
}

public extension DependencyValues {
    var userProfileClient: UserProfileClient {
        get { self[UserProfileClient.self] }
        set { self[UserProfileClient.self] = newValue }
    }
}
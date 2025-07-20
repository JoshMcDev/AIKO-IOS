import ComposableArchitecture
import Foundation

/// TCA-compatible dependency client for user profile management
@DependencyClient
public struct UserProfileClient: Sendable {
    public var loadProfile: @Sendable () async throws -> UserProfile?
    public var saveProfile: @Sendable (UserProfile) async throws -> Void
    public var deleteProfile: @Sendable () async throws -> Void
    public var hasProfile: @Sendable () async -> Bool = { false }
}

extension UserProfileClient: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        loadProfile: { nil },
        saveProfile: { _ in },
        deleteProfile: {},
        hasProfile: { false }
    )
}

public extension DependencyValues {
    var userProfileClient: UserProfileClient {
        get { self[UserProfileClient.self] }
        set { self[UserProfileClient.self] = newValue }
    }
}

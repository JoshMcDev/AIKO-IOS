import Foundation

/// TCA-compatible dependency client for user profile management
public struct UserProfileClient: Sendable {
    public var loadProfile: @Sendable () async throws -> UserProfile?
    public var saveProfile: @Sendable (UserProfile) async throws -> Void
    public var deleteProfile: @Sendable () async throws -> Void
    public var hasProfile: @Sendable () async -> Bool = { false }
}

extension UserProfileClient {
    public static let testValue = Self(
        loadProfile: { nil },
        saveProfile: { _ in },
        deleteProfile: {}
    )

    public static let previewValue = Self(
        loadProfile: { nil },
        saveProfile: { _ in },
        deleteProfile: {},
        hasProfile: { false }
    )
}

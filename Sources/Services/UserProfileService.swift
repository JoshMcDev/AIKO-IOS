import AppCore
import ComposableArchitecture
import Foundation

public struct UserProfileService: Sendable {
    public var loadProfile: @Sendable () async throws -> UserProfile?
    public var saveProfile: @Sendable (UserProfile) async throws -> Void
    public var deleteProfile: @Sendable () async throws -> Void
    public var hasProfile: @Sendable () async -> Bool

    public init(
        loadProfile: @escaping @Sendable () async throws -> UserProfile?,
        saveProfile: @escaping @Sendable (UserProfile) async throws -> Void,
        deleteProfile: @escaping @Sendable () async throws -> Void,
        hasProfile: @escaping @Sendable () async -> Bool
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.deleteProfile = deleteProfile
        self.hasProfile = hasProfile
    }
}

extension UserProfileService: DependencyKey {
    public static var liveValue: UserProfileService {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory")
        }
        let profileURL = documentsDirectory.appendingPathComponent("userProfile.json")

        return UserProfileService(
            loadProfile: {
                guard FileManager.default.fileExists(atPath: profileURL.path) else {
                    return nil
                }

                let data = try Data(contentsOf: profileURL)
                let decoder = JSONDecoder()
                return try decoder.decode(UserProfile.self, from: data)
            },
            saveProfile: { profile in
                var updatedProfile = profile
                updatedProfile.updatedAt = Date()

                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(updatedProfile)

                try data.write(to: profileURL, options: .atomicWrite)
            },
            deleteProfile: {
                if FileManager.default.fileExists(atPath: profileURL.path) {
                    try FileManager.default.removeItem(at: profileURL)
                }
            },
            hasProfile: {
                FileManager.default.fileExists(atPath: profileURL.path)
            }
        )
    }

    public static var testValue: UserProfileService {
        let testStorage = TestProfileStorage()

        return UserProfileService(
            loadProfile: { await testStorage.getProfile() },
            saveProfile: { profile in await testStorage.setProfile(profile) },
            deleteProfile: { await testStorage.clearProfile() },
            hasProfile: { await testStorage.hasProfile() }
        )
    }
}

// MARK: - Test Storage Actor

private actor TestProfileStorage {
    private var savedProfile: UserProfile?

    func getProfile() -> UserProfile? {
        savedProfile
    }

    func setProfile(_ profile: UserProfile) {
        savedProfile = profile
    }

    func clearProfile() {
        savedProfile = nil
    }

    func hasProfile() -> Bool {
        savedProfile != nil
    }
}

public extension DependencyValues {
    var userProfileService: UserProfileService {
        get { self[UserProfileService.self] }
        set { self[UserProfileService.self] = newValue }
    }
}

import ComposableArchitecture
import Foundation
import AppCore

public struct UserProfileService {
    public var loadProfile: () async throws -> UserProfile?
    public var saveProfile: (UserProfile) async throws -> Void
    public var deleteProfile: () async throws -> Void
    public var hasProfile: () async -> Bool

    public init(
        loadProfile: @escaping () async throws -> UserProfile?,
        saveProfile: @escaping (UserProfile) async throws -> Void,
        deleteProfile: @escaping () async throws -> Void,
        hasProfile: @escaping () async -> Bool
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.deleteProfile = deleteProfile
        self.hasProfile = hasProfile
    }
}

extension UserProfileService: DependencyKey {
    public static var liveValue: UserProfileService {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        var savedProfile: UserProfile?

        return UserProfileService(
            loadProfile: { savedProfile },
            saveProfile: { profile in savedProfile = profile },
            deleteProfile: { savedProfile = nil },
            hasProfile: { savedProfile != nil }
        )
    }
}

public extension DependencyValues {
    var userProfileService: UserProfileService {
        get { self[UserProfileService.self] }
        set { self[UserProfileService.self] = newValue }
    }
}

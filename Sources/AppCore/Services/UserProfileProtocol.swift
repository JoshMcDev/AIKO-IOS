import Foundation

/// Platform-agnostic protocol for user profile management
public protocol UserProfileProtocol: Sendable {
    /// Load the user profile
    func loadProfile() async throws -> UserProfile?

    /// Save the user profile
    func saveProfile(_ profile: UserProfile) async throws

    /// Delete the user profile
    func deleteProfile() async throws

    /// Check if a profile exists
    func hasProfile() async -> Bool
}

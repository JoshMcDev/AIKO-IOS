//
//  LLMKeychainManager.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import CryptoKit
import Foundation
import Security

/// Secure keychain manager for LLM provider API keys
/// Provides encrypted storage with biometric protection and access control
@MainActor
final class LLMKeychainManager: ObservableObject {
    // MARK: - Properties

    static let shared = LLMKeychainManager()

    /// Service identifier for keychain items
    private let keychainService = "com.aiko.llm.apikeys"

    /// Access group for shared keychain items (if needed for app extensions)
    private let accessGroup: String? = nil

    /// Biometric protection requirement
    private let requireBiometric: Bool

    // MARK: - Initialization

    private init(requireBiometric: Bool = true) {
        self.requireBiometric = requireBiometric
    }

    // MARK: - Key Storage

    /// Stores an API key for a specific LLM provider
    /// - Parameters:
    ///   - apiKey: The API key to store
    ///   - provider: The LLM provider
    ///   - requireUserPresence: Whether to require biometric/passcode for access
    /// - Throws: KeychainError if storage fails
    func storeAPIKey(_ apiKey: String, for provider: LLMProvider, requireUserPresence: Bool = true) throws {
        let account = keychainAccount(for: provider)
        let data = Data(apiKey.utf8)

        // Create query with security attributes
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        // Add access control
        if requireUserPresence, requireBiometric {
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .userPresence,
                nil
            )
            query[kSecAttrAccessControl as String] = access
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        // Add access group if configured
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status: status)
        }
    }

    /// Retrieves an API key for a specific LLM provider
    /// - Parameter provider: The LLM provider
    /// - Returns: The API key if found
    /// - Throws: KeychainError if retrieval fails
    func retrieveAPIKey(for provider: LLMProvider) throws -> String? {
        let account = keychainAccount(for: provider)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]

        // Add access group if configured
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let apiKey = String(data: data, encoding: .utf8)
            else {
                throw KeychainError.dataCorrupted
            }
            return apiKey

        case errSecItemNotFound:
            return nil

        default:
            throw KeychainError.retrieveFailed(status: status)
        }
    }

    /// Updates an existing API key
    /// - Parameters:
    ///   - apiKey: The new API key
    ///   - provider: The LLM provider
    /// - Throws: KeychainError if update fails
    func updateAPIKey(_ apiKey: String, for provider: LLMProvider) throws {
        let account = keychainAccount(for: provider)
        let data = Data(apiKey.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            // If not found, store it instead
            try storeAPIKey(apiKey, for: provider)
        default:
            throw KeychainError.updateFailed(status: status)
        }
    }

    /// Deletes an API key for a specific provider
    /// - Parameter provider: The LLM provider
    /// - Throws: KeychainError if deletion fails
    func deleteAPIKey(for provider: LLMProvider) throws {
        let account = keychainAccount(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    /// Checks if an API key exists for a provider
    /// - Parameter provider: The LLM provider
    /// - Returns: True if API key exists
    func hasAPIKey(for provider: LLMProvider) -> Bool {
        do {
            return try retrieveAPIKey(for: provider) != nil
        } catch {
            return false
        }
    }

    /// Deletes all stored API keys
    /// - Throws: KeychainError if deletion fails
    func deleteAllAPIKeys() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    // MARK: - Validation

    /// Validates an API key format for a specific provider
    /// - Parameters:
    ///   - apiKey: The API key to validate
    ///   - provider: The LLM provider
    /// - Returns: True if the API key format is valid
    func validateAPIKeyFormat(_ apiKey: String, for provider: LLMProvider) -> Bool {
        switch provider {
        case .claude:
            // Claude API keys start with "sk-ant-"
            apiKey.hasPrefix("sk-ant-") && apiKey.count > 20

        case .openAI:
            // OpenAI API keys start with "sk-"
            apiKey.hasPrefix("sk-") && apiKey.count > 20

        case .chatGPT:
            // ChatGPT uses same format as OpenAI
            apiKey.hasPrefix("sk-") && apiKey.count > 20

        case .gemini:
            // Google Gemini API keys are typically 39 characters
            apiKey.count == 39

        case .custom:
            // For custom providers, accept any non-empty key
            !apiKey.isEmpty
        }
    }

    // MARK: - Migration

    /// Migrates API keys from UserDefaults to Keychain (for app updates)
    func migrateFromUserDefaults() {
        let providers: [LLMProvider] = [.claude, .openAI, .chatGPT, .gemini]

        for provider in providers {
            let userDefaultsKey = "LLMAPIKey_\(provider.rawValue)"
            if let apiKey = UserDefaults.standard.string(forKey: userDefaultsKey) {
                do {
                    try storeAPIKey(apiKey, for: provider)
                    // Remove from UserDefaults after successful migration
                    UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                } catch {
                    print("Failed to migrate API key for \(provider.name): \(error)")
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Generates a unique account identifier for each provider
    private func keychainAccount(for provider: LLMProvider) -> String {
        "llm.apikey.\(provider.rawValue)"
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case storeFailed(status: OSStatus)
    case retrieveFailed(status: OSStatus)
    case updateFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case dataCorrupted
    case biometricAuthenticationFailed

    var errorDescription: String? {
        switch self {
        case let .storeFailed(status):
            "Failed to store API key: \(keychainErrorMessage(status))"
        case let .retrieveFailed(status):
            "Failed to retrieve API key: \(keychainErrorMessage(status))"
        case let .updateFailed(status):
            "Failed to update API key: \(keychainErrorMessage(status))"
        case let .deleteFailed(status):
            "Failed to delete API key: \(keychainErrorMessage(status))"
        case .dataCorrupted:
            "API key data is corrupted"
        case .biometricAuthenticationFailed:
            "Biometric authentication failed"
        }
    }

    private func keychainErrorMessage(_ status: OSStatus) -> String {
        if let error = SecCopyErrorMessageString(status, nil) as String? {
            return error
        }
        return "Unknown error (\(status))"
    }
}

// MARK: - Keychain Wrapper for TCA

/// A wrapper for use with The Composable Architecture
struct LLMKeychainClient {
    var storeAPIKey: @Sendable (String, LLMProvider, Bool) async throws -> Void
    var retrieveAPIKey: @Sendable (LLMProvider) async throws -> String?
    var updateAPIKey: @Sendable (String, LLMProvider) async throws -> Void
    var deleteAPIKey: @Sendable (LLMProvider) async throws -> Void
    var hasAPIKey: @Sendable (LLMProvider) async -> Bool
    var validateAPIKeyFormat: @Sendable (String, LLMProvider) -> Bool
    var deleteAllAPIKeys: @Sendable () async throws -> Void
}

extension LLMKeychainClient: DependencyKey {
    static let liveValue = Self(
        storeAPIKey: { apiKey, provider, requireUserPresence in
            try await MainActor.run {
                try LLMKeychainManager.shared.storeAPIKey(
                    apiKey,
                    for: provider,
                    requireUserPresence: requireUserPresence
                )
            }
        },
        retrieveAPIKey: { provider in
            try await MainActor.run {
                try LLMKeychainManager.shared.retrieveAPIKey(for: provider)
            }
        },
        updateAPIKey: { apiKey, provider in
            try await MainActor.run {
                try LLMKeychainManager.shared.updateAPIKey(apiKey, for: provider)
            }
        },
        deleteAPIKey: { provider in
            try await MainActor.run {
                try LLMKeychainManager.shared.deleteAPIKey(for: provider)
            }
        },
        hasAPIKey: { provider in
            await MainActor.run {
                LLMKeychainManager.shared.hasAPIKey(for: provider)
            }
        },
        validateAPIKeyFormat: { apiKey, provider in
            LLMKeychainManager.shared.validateAPIKeyFormat(apiKey, for: provider)
        },
        deleteAllAPIKeys: {
            try await MainActor.run {
                try LLMKeychainManager.shared.deleteAllAPIKeys()
            }
        }
    )
}

extension DependencyValues {
    var llmKeychain: LLMKeychainClient {
        get { self[LLMKeychainClient.self] }
        set { self[LLMKeychainClient.self] = newValue }
    }
}

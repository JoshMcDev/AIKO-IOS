import Foundation
import Security

// MARK: - LLM Keychain Service

/// Secure storage for LLM provider API keys using iOS/macOS Keychain
public final class LLMKeychainService: @unchecked Sendable {
    
    // MARK: - Properties
    
    public static let shared = LLMKeychainService()
    
    private let serviceName = "com.aiko.llm"
    private let accessGroup: String? = nil // Set if using app groups
    
    // MARK: - Public Methods
    
    /// Store API key for a provider
    public func storeAPIKey(_ key: String, for provider: String) throws {
        let account = accountName(for: provider)
        let data = key.data(using: .utf8)!
        
        // Check if key already exists
        if let _ = try? retrieveAPIKey(for: provider) {
            // Update existing key
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            
            if status != errSecSuccess {
                throw KeychainError.updateFailed(status)
            }
        } else {
            // Add new key
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            if let accessGroup = accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status != errSecSuccess {
                throw KeychainError.saveFailed(status)
            }
        }
    }
    
    /// Retrieve API key for a provider
    public func retrieveAPIKey(for provider: String) throws -> String {
        let account = accountName(for: provider)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return key
    }
    
    /// Delete API key for a provider
    public func deleteAPIKey(for provider: String) throws {
        let account = accountName(for: provider)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Check if API key exists for a provider
    public func hasAPIKey(for provider: String) -> Bool {
        do {
            _ = try retrieveAPIKey(for: provider)
            return true
        } catch {
            return false
        }
    }
    
    /// List all configured providers
    public func listConfiguredProviders() -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            guard let account = item[kSecAttrAccount as String] as? String else { return nil }
            return providerFromAccount(account)
        }
    }
    
    /// Delete all stored API keys
    public func deleteAllAPIKeys() throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Private Methods
    
    private func accountName(for provider: String) -> String {
        return "llm_provider_\(provider)"
    }
    
    private func providerFromAccount(_ account: String) -> String? {
        guard account.hasPrefix("llm_provider_") else { return nil }
        return String(account.dropFirst("llm_provider_".count))
    }
}

// MARK: - Keychain Errors

public enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case updateFailed(OSStatus)
    case deleteFailed(OSStatus)
    case notFound
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(errorMessage(for: status))"
        case .updateFailed(let status):
            return "Failed to update keychain: \(errorMessage(for: status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(errorMessage(for: status))"
        case .notFound:
            return "API key not found in keychain"
        case .invalidData:
            return "Invalid data in keychain"
        }
    }
    
    private func errorMessage(for status: OSStatus) -> String {
        if let error = SecCopyErrorMessageString(status, nil) as String? {
            return error
        }
        return "Unknown error (\(status))"
    }
}

// MARK: - Provider Configuration

/// Configuration for an LLM provider including credentials
public struct LLMProviderConfiguration: Equatable, Sendable {
    public let providerId: String
    public let apiKey: String
    public let organizationId: String?
    public let customEndpoint: String?
    public let additionalSettings: [String: String]
    
    public init(
        providerId: String,
        apiKey: String,
        organizationId: String? = nil,
        customEndpoint: String? = nil,
        additionalSettings: [String: String] = [:]
    ) {
        self.providerId = providerId
        self.apiKey = apiKey
        self.organizationId = organizationId
        self.customEndpoint = customEndpoint
        self.additionalSettings = additionalSettings
    }
}

// MARK: - Secure Configuration Manager

/// Manages provider configurations with secure storage
public final class LLMConfigurationManager: @unchecked Sendable {
    
    public static let shared = LLMConfigurationManager()
    
    private let keychainService = LLMKeychainService.shared
    private let userDefaults = UserDefaults.standard
    private let configurationKey = "com.aiko.llm.configurations"
    
    /// Save provider configuration
    public func saveConfiguration(_ config: LLMProviderConfiguration) throws {
        // Store API key securely in keychain
        try keychainService.storeAPIKey(config.apiKey, for: config.providerId)
        
        // Store other settings in UserDefaults
        var configs = loadConfigurations()
        configs[config.providerId] = StoredConfiguration(
            organizationId: config.organizationId,
            customEndpoint: config.customEndpoint,
            additionalSettings: config.additionalSettings
        )
        
        saveConfigurations(configs)
    }
    
    /// Load provider configuration
    public func loadConfiguration(for providerId: String) throws -> LLMProviderConfiguration? {
        guard let apiKey = try? keychainService.retrieveAPIKey(for: providerId) else {
            return nil
        }
        
        let configs = loadConfigurations()
        guard let stored = configs[providerId] else {
            return LLMProviderConfiguration(providerId: providerId, apiKey: apiKey)
        }
        
        return LLMProviderConfiguration(
            providerId: providerId,
            apiKey: apiKey,
            organizationId: stored.organizationId,
            customEndpoint: stored.customEndpoint,
            additionalSettings: stored.additionalSettings
        )
    }
    
    /// Delete provider configuration
    public func deleteConfiguration(for providerId: String) throws {
        try keychainService.deleteAPIKey(for: providerId)
        
        var configs = loadConfigurations()
        configs.removeValue(forKey: providerId)
        saveConfigurations(configs)
    }
    
    /// List all configured providers
    public func listConfiguredProviders() -> [String] {
        return keychainService.listConfiguredProviders()
    }
    
    /// Check if provider is configured
    public func isProviderConfigured(_ providerId: String) -> Bool {
        return keychainService.hasAPIKey(for: providerId)
    }
    
    // MARK: - Private
    
    private struct StoredConfiguration: Codable {
        let organizationId: String?
        let customEndpoint: String?
        let additionalSettings: [String: String]
    }
    
    private func loadConfigurations() -> [String: StoredConfiguration] {
        guard let data = userDefaults.data(forKey: configurationKey),
              let configs = try? JSONDecoder().decode([String: StoredConfiguration].self, from: data) else {
            return [:]
        }
        return configs
    }
    
    private func saveConfigurations(_ configs: [String: StoredConfiguration]) {
        if let data = try? JSONEncoder().encode(configs) {
            userDefaults.set(data, forKey: configurationKey)
        }
    }
}
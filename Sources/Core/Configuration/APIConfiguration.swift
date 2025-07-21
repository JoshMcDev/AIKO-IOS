import Foundation

public enum APIConfiguration {
    private static let defaultAnthropicAPIKey = "YOUR_API_KEY_HERE"

    public static func getAnthropicKey() -> String {
        if let keychainKey = KeychainManager.shared.getAnthropicKey() {
            return keychainKey
        }

        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !envKey.isEmpty {
            _ = KeychainManager.shared.saveAnthropicKey(envKey)
            return envKey
        }

        return defaultAnthropicAPIKey
    }

    public static var anthropicBaseURL: String {
        ProcessInfo.processInfo.environment["ANTHROPIC_BASE_URL"] ?? "https://api.anthropic.com"
    }

    public static var isProduction: Bool {
        ProcessInfo.processInfo.environment["ENVIRONMENT"] == "production"
    }
}

public final class KeychainManager: @unchecked Sendable {
    public static let shared = KeychainManager()

    private let service = "com.aiko.app"
    private let anthropicKeyAccount = "anthropic_api_key"

    private init() {}

    public func saveAnthropicKey(_ key: String) -> Bool {
        save(key: anthropicKeyAccount, data: key.data(using: .utf8) ?? Data())
    }

    public func getAnthropicKey() -> String? {
        guard let data = load(key: anthropicKeyAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func deleteAnthropicKey() -> Bool {
        delete(key: anthropicKeyAccount)
    }

    private func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    private func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        return status == errSecSuccess ? result as? Data : nil
    }

    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

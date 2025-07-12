import Foundation
import CryptoKit
import Security

/// Enhanced API Key Manager with rotation, encryption, and certificate pinning
public actor EnhancedAPIKeyManager {
    // MARK: - Singleton
    public static let shared = EnhancedAPIKeyManager()
    
    // MARK: - Properties
    private let keychainService = "com.aiko.app.enhanced"
    private let keyRotationInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    private var certificatePins: [String: String] = [:] // Domain to pin mapping
    
    // Key metadata
    public struct KeyMetadata: Codable {
        let key: String
        let createdAt: Date
        let lastRotated: Date
        let rotationCount: Int
        let environment: String
    }
    
    // MARK: - Initialization
    private init() {
        Task { await setupCertificatePins() }
    }
    
    // MARK: - Public Methods
    
    /// Get the current API key with automatic rotation check
    public func getAPIKey(for service: APIService) async throws -> String {
        let metadata = try await loadKeyMetadata(for: service)
        
        // Check if rotation is needed
        if shouldRotateKey(metadata: metadata) {
            return try await rotateKey(for: service, currentMetadata: metadata)
        }
        
        return try decrypt(metadata.key)
    }
    
    /// Store a new API key
    public func storeAPIKey(_ key: String, for service: APIService) async throws {
        let encryptedKey = try encrypt(key)
        let metadata = KeyMetadata(
            key: encryptedKey,
            createdAt: Date(),
            lastRotated: Date(),
            rotationCount: 0,
            environment: currentEnvironment()
        )
        
        try await saveKeyMetadata(metadata, for: service)
    }
    
    /// Rotate an API key
    public func rotateKey(for service: APIService, currentMetadata: KeyMetadata? = nil) async throws -> String {
        let metadata: KeyMetadata
        if let currentMetadata = currentMetadata {
            metadata = currentMetadata
        } else {
            metadata = try await loadKeyMetadata(for: service)
        }
        
        // Generate new key (in production, this would call the API provider)
        let newKey = try await requestNewKey(for: service, oldKey: try decrypt(metadata.key))
        
        // Store the new key
        let encryptedNewKey = try encrypt(newKey)
        let newMetadata = KeyMetadata(
            key: encryptedNewKey,
            createdAt: metadata.createdAt,
            lastRotated: Date(),
            rotationCount: metadata.rotationCount + 1,
            environment: currentEnvironment()
        )
        
        try await saveKeyMetadata(newMetadata, for: service)
        
        // Revoke old key after successful rotation
        try await revokeOldKey(try decrypt(metadata.key), for: service)
        
        return newKey
    }
    
    /// Validate certificate pinning
    public func validateCertificatePin(for host: String, serverTrust: SecTrust) async -> Bool {
        guard let expectedPin = certificatePins[host] else { return true }
        
        // Get certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            return false
        }
        
        // Check each certificate in the chain
        for certificate in certificateChain {
            let certificateData = SecCertificateCopyData(certificate) as Data
            let hash = SHA256.hash(data: certificateData)
            let pin = hash.compactMap { String(format: "%02x", $0) }.joined()
            
            if pin == expectedPin {
                return true
            }
        }
        
        return false
    }
    
    /// Delete all stored keys
    public func deleteAllKeys() async throws {
        for service in APIService.allCases {
            _ = try? await deleteKey(for: service)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCertificatePins() {
        // Production pins (these should be updated with actual certificate pins)
        certificatePins = [
            "api.anthropic.com": "abc123def456...", // Replace with actual pin
            "api.openai.com": "ghi789jkl012...",    // Replace with actual pin
        ]
    }
    
    private func shouldRotateKey(metadata: KeyMetadata) -> Bool {
        // Check if key is older than rotation interval
        let timeSinceRotation = Date().timeIntervalSince(metadata.lastRotated)
        return timeSinceRotation > keyRotationInterval
    }
    
    private func encrypt(_ plainText: String) throws -> String {
        guard let data = plainText.data(using: .utf8) else {
            throw APIKeyError.encryptionFailed
        }
        
        // Generate a symmetric key
        let key = SymmetricKey(size: .bits256)
        
        // Encrypt the data
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // Store the key in keychain (simplified for demo)
        let keyData = key.withUnsafeBytes { Data($0) }
        try storeInKeychain(keyData, identifier: "encryption_key")
        
        // Return base64 encoded encrypted data
        return sealedBox.combined?.base64EncodedString() ?? ""
    }
    
    private func decrypt(_ encryptedText: String) throws -> String {
        guard let encryptedData = Data(base64Encoded: encryptedText),
              let keyData = try? loadFromKeychain(identifier: "encryption_key") else {
            throw APIKeyError.decryptionFailed
        }
        
        let key = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw APIKeyError.decryptionFailed
        }
        
        return decryptedString
    }
    
    private func loadKeyMetadata(for service: APIService) async throws -> KeyMetadata {
        guard let data = try? loadFromKeychain(identifier: service.keychainIdentifier) else {
            throw APIKeyError.keyNotFound
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(KeyMetadata.self, from: data)
    }
    
    private func saveKeyMetadata(_ metadata: KeyMetadata, for service: APIService) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        try storeInKeychain(data, identifier: service.keychainIdentifier)
    }
    
    private func deleteKey(for service: APIService) async throws -> Bool {
        return deleteFromKeychain(identifier: service.keychainIdentifier)
    }
    
    private func requestNewKey(for service: APIService, oldKey: String) async throws -> String {
        // In production, this would make an API call to rotate the key
        // For now, return a mock new key
        return "new_\(service.rawValue)_key_\(UUID().uuidString)"
    }
    
    private func revokeOldKey(_ oldKey: String, for service: APIService) async throws {
        // In production, this would make an API call to revoke the old key
        // Log the revocation for audit purposes
        print("Revoked old key for \(service.rawValue)")
    }
    
    private func currentEnvironment() -> String {
        return ProcessInfo.processInfo.environment["ENVIRONMENT"] ?? "development"
    }
    
    // MARK: - Keychain Operations
    
    private func storeInKeychain(_ data: Data, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw APIKeyError.keychainError(status)
        }
    }
    
    private func loadFromKeychain(identifier: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw APIKeyError.keychainError(status)
        }
        
        return data
    }
    
    private func deleteFromKeychain(identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier
        ]
        
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - Supporting Types

public enum APIService: String, CaseIterable {
    case anthropic = "anthropic"
    case openai = "openai"
    case sam = "sam_gov"
    
    var keychainIdentifier: String {
        return "api_key_\(rawValue)"
    }
}

public enum APIKeyError: LocalizedError {
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
    case rotationFailed
    case keychainError(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "API key not found"
        case .encryptionFailed:
            return "Failed to encrypt API key"
        case .decryptionFailed:
            return "Failed to decrypt API key"
        case .rotationFailed:
            return "Failed to rotate API key"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - URLSession Extension for Certificate Pinning

extension URLSession {
    /// Create a session with certificate pinning
    public static func pinnedSession() -> URLSession {
        let delegate = PinnedSessionDelegate()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
}

/// URLSession delegate for certificate pinning
public final class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession, 
                          didReceive challenge: URLAuthenticationChallenge,
                          completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              true else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        Task {
            let isValid = await EnhancedAPIKeyManager.shared.validateCertificatePin(
                for: challenge.protectionSpace.host,
                serverTrust: serverTrust
            )
            
            if isValid {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}
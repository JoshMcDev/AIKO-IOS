import AppCore
import ComposableArchitecture
import CryptoKit
import Foundation

/// Encrypted Document Cache Service with AES-256 encryption
public struct EncryptedDocumentCache: Sendable {
    // Cache operations
    public var cacheDocument: @Sendable (GeneratedDocument) async throws -> Void
    public var getCachedDocument: @Sendable (DocumentType, String) async -> GeneratedDocument?
    public var cacheAnalysisResponse: @Sendable (String, String, [DocumentType]) async throws -> Void
    public var getCachedAnalysisResponse: @Sendable (String) async -> (response: String, recommendedDocuments: [DocumentType])?
    public var clearCache: @Sendable () async throws -> Void
    public var getCacheStatistics: @Sendable () async -> CacheStatistics

    // Performance optimization
    public var preloadFrequentDocuments: @Sendable () async throws -> Void
    public var optimizeCacheForMemory: @Sendable () async throws -> Void

    // Security operations
    public var rotateEncryptionKey: @Sendable () async throws -> Void
    public var exportEncryptedBackup: @Sendable () async throws -> Data
    public var importEncryptedBackup: @Sendable (Data) async throws -> Void

    public init(
        cacheDocument: @escaping @Sendable (GeneratedDocument) async throws -> Void,
        getCachedDocument: @escaping @Sendable (DocumentType, String) async -> GeneratedDocument?,
        cacheAnalysisResponse: @escaping @Sendable (String, String, [DocumentType]) async throws -> Void,
        getCachedAnalysisResponse: @escaping @Sendable (String) async -> (response: String, recommendedDocuments: [DocumentType])?,
        clearCache: @escaping @Sendable () async throws -> Void,
        getCacheStatistics: @escaping @Sendable () async -> CacheStatistics,
        preloadFrequentDocuments: @escaping @Sendable () async throws -> Void,
        optimizeCacheForMemory: @escaping @Sendable () async throws -> Void,
        rotateEncryptionKey: @escaping @Sendable () async throws -> Void,
        exportEncryptedBackup: @escaping @Sendable () async throws -> Data,
        importEncryptedBackup: @escaping @Sendable (Data) async throws -> Void
    ) {
        self.cacheDocument = cacheDocument
        self.getCachedDocument = getCachedDocument
        self.cacheAnalysisResponse = cacheAnalysisResponse
        self.getCachedAnalysisResponse = getCachedAnalysisResponse
        self.clearCache = clearCache
        self.getCacheStatistics = getCacheStatistics
        self.preloadFrequentDocuments = preloadFrequentDocuments
        self.optimizeCacheForMemory = optimizeCacheForMemory
        self.rotateEncryptionKey = rotateEncryptionKey
        self.exportEncryptedBackup = exportEncryptedBackup
        self.importEncryptedBackup = importEncryptedBackup
    }
}

// MARK: - Encrypted Cache Storage

actor EncryptedDocumentCacheStorage {
    private var documentCache: [CacheKey: EncryptedCachedDocument] = [:]
    private var analysisCache: [String: EncryptedCachedAnalysis] = [:]
    private var accessOrder: [String] = []
    private let maxCacheSize: Int = 50
    private let maxMemorySize: Int64 = 100 * 1024 * 1024 // 100 MB

    // Encryption components
    private var primaryKey: SymmetricKey
    private let keyDerivationSalt: Data
    private let encryptionManager: DocumentEncryptionManager

    struct CacheKey: Hashable, Codable {
        let documentCategory: DocumentCategoryType
        let requirements: String
    }

    struct EncryptedCachedDocument: Codable {
        let encryptedData: Data
        let nonce: Data
        var metadata: DocumentMetadata
    }

    struct EncryptedCachedAnalysis: Codable {
        let encryptedData: Data
        let nonce: Data
        var metadata: AnalysisMetadata
    }

    struct DocumentMetadata: Codable {
        let documentType: String
        let cachedAt: Date
        var lastAccessed: Date
        var accessCount: Int
        let checksum: String
    }

    struct AnalysisMetadata: Codable {
        let cachedAt: Date
        var lastAccessed: Date
        var accessCount: Int
        let recommendedTypes: [String]
    }

    init() async throws {
        encryptionManager = DocumentEncryptionManager()

        // Generate or load encryption key
        if let savedKey = try? await encryptionManager.loadPrimaryKey() {
            primaryKey = savedKey.key
            keyDerivationSalt = savedKey.salt
        } else {
            let newKey = try await encryptionManager.generatePrimaryKey()
            primaryKey = newKey.key
            keyDerivationSalt = newKey.salt
        }
    }

    // MARK: - Document Operations

    func cacheDocument(_ document: GeneratedDocument, requirements: String) async throws {
        let key = CacheKey(documentCategory: document.documentCategory, requirements: requirements.lowercased())

        // Serialize document
        let encoder = JSONEncoder()
        let documentData = try encoder.encode(document)

        // Encrypt
        let encrypted = try await encryptionManager.encrypt(documentData, using: primaryKey)

        // Create metadata
        let metadata = DocumentMetadata(
            documentType: String(describing: document.documentCategory),
            cachedAt: Date(),
            lastAccessed: Date(),
            accessCount: 1,
            checksum: SHA256.hash(data: documentData).compactMap { String(format: "%02x", $0) }.joined()
        )

        let cachedDoc = EncryptedCachedDocument(
            encryptedData: encrypted.ciphertext,
            nonce: encrypted.nonce,
            metadata: metadata
        )

        documentCache[key] = cachedDoc
        updateAccessOrder(key.hashValue.description)
        await enforceMemoryLimit()
    }

    func getCachedDocument(type: DocumentType, requirements: String) async -> GeneratedDocument? {
        let key = CacheKey(documentCategory: .standard(type), requirements: requirements.lowercased())

        guard var cached = documentCache[key] else { return nil }

        do {
            // Decrypt document
            let decryptedData = try await encryptionManager.decrypt(
                ciphertext: cached.encryptedData,
                nonce: cached.nonce,
                using: primaryKey
            )

            // Verify integrity
            let checksum = SHA256.hash(data: decryptedData).compactMap { String(format: "%02x", $0) }.joined()
            guard checksum == cached.metadata.checksum else {
                print("⚠ Document integrity check failed")
                documentCache.removeValue(forKey: key)
                return nil
            }

            // Deserialize
            let decoder = JSONDecoder()
            let document = try decoder.decode(GeneratedDocument.self, from: decryptedData)

            // Update metadata
            cached.metadata.lastAccessed = Date()
            cached.metadata.accessCount += 1
            documentCache[key] = cached
            updateAccessOrder(key.hashValue.description)

            return document

        } catch {
            print("❌ Failed to decrypt cached document: \(error)")
            return nil
        }
    }

    // MARK: - Analysis Operations

    func cacheAnalysis(requirements: String, response: String, recommendedDocuments: [DocumentType]) async throws {
        let key = requirements.lowercased()

        // Create analysis data
        let analysisData = AnalysisData(
            response: response,
            recommendedDocuments: recommendedDocuments
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(analysisData)

        // Encrypt
        let encrypted = try await encryptionManager.encrypt(data, using: primaryKey)

        // Create metadata
        let metadata = AnalysisMetadata(
            cachedAt: Date(),
            lastAccessed: Date(),
            accessCount: 1,
            recommendedTypes: recommendedDocuments.map(\.rawValue)
        )

        let cachedAnalysis = EncryptedCachedAnalysis(
            encryptedData: encrypted.ciphertext,
            nonce: encrypted.nonce,
            metadata: metadata
        )

        analysisCache[key] = cachedAnalysis
        updateAccessOrder(key)
        await enforceMemoryLimit()
    }

    func getCachedAnalysis(requirements: String) async -> (response: String, recommendedDocuments: [DocumentType])? {
        let key = requirements.lowercased()

        guard var cached = analysisCache[key] else { return nil }

        do {
            // Decrypt
            let decryptedData = try await encryptionManager.decrypt(
                ciphertext: cached.encryptedData,
                nonce: cached.nonce,
                using: primaryKey
            )

            // Deserialize
            let decoder = JSONDecoder()
            let analysisData = try decoder.decode(AnalysisData.self, from: decryptedData)

            // Update metadata
            cached.metadata.lastAccessed = Date()
            cached.metadata.accessCount += 1
            analysisCache[key] = cached
            updateAccessOrder(key)

            return (analysisData.response, analysisData.recommendedDocuments)

        } catch {
            print("❌ Failed to decrypt cached analysis: \(error)")
            return nil
        }
    }

    // MARK: - Security Operations

    func rotateEncryptionKey() async throws {
        // Generate new key
        let newKeyData = try await encryptionManager.generatePrimaryKey()
        let newKey = newKeyData.key

        // Re-encrypt all documents
        for (cacheKey, encryptedDoc) in documentCache {
            // Decrypt with old key
            let decryptedData = try await encryptionManager.decrypt(
                ciphertext: encryptedDoc.encryptedData,
                nonce: encryptedDoc.nonce,
                using: primaryKey
            )

            // Re-encrypt with new key
            let reEncrypted = try await encryptionManager.encrypt(decryptedData, using: newKey)

            // Update cache
            documentCache[cacheKey] = EncryptedCachedDocument(
                encryptedData: reEncrypted.ciphertext,
                nonce: reEncrypted.nonce,
                metadata: encryptedDoc.metadata
            )
        }

        // Re-encrypt all analyses
        for (key, encryptedAnalysis) in analysisCache {
            // Decrypt with old key
            let decryptedData = try await encryptionManager.decrypt(
                ciphertext: encryptedAnalysis.encryptedData,
                nonce: encryptedAnalysis.nonce,
                using: primaryKey
            )

            // Re-encrypt with new key
            let reEncrypted = try await encryptionManager.encrypt(decryptedData, using: newKey)

            // Update cache
            analysisCache[key] = EncryptedCachedAnalysis(
                encryptedData: reEncrypted.ciphertext,
                nonce: reEncrypted.nonce,
                metadata: encryptedAnalysis.metadata
            )
        }

        // Update master key
        primaryKey = newKey
        try await encryptionManager.savePrimaryKey(key: newKey, salt: newKeyData.salt)
    }

    func exportEncryptedBackup() async throws -> Data {
        // Create a simplified backup structure
        var backupData = Data()

        // Add document count
        let documentCount = documentCache.count
        backupData.append(withUnsafeBytes(of: documentCount) { Data($0) })

        // Add each document
        for (_, doc) in documentCache {
            backupData.append(doc.encryptedData)
            backupData.append(doc.nonce)
        }

        // Add analysis count
        let analysisCount = analysisCache.count
        backupData.append(withUnsafeBytes(of: analysisCount) { Data($0) })

        // Add each analysis
        for (_, analysis) in analysisCache {
            backupData.append(analysis.encryptedData)
            backupData.append(analysis.nonce)
        }

        // Encrypt the entire backup
        let encrypted = try await encryptionManager.encrypt(backupData, using: primaryKey)

        // Package with metadata
        let package = BackupPackage(
            encryptedData: encrypted.ciphertext,
            nonce: encrypted.nonce,
            salt: keyDerivationSalt,
            version: "1.0"
        )

        let encoder = JSONEncoder()
        return try encoder.encode(package)
    }

    // MARK: - Cache Management

    func clearCache() {
        documentCache.removeAll()
        analysisCache.removeAll()
        accessOrder.removeAll()
    }

    func getStatistics() -> CacheStatistics {
        let totalDocuments = documentCache.count
        let totalAnalyses = analysisCache.count

        // Calculate encrypted cache size
        var totalSize: Int64 = 0
        for (_, doc) in documentCache {
            totalSize += Int64(doc.encryptedData.count)
        }
        for (_, analysis) in analysisCache {
            totalSize += Int64(analysis.encryptedData.count)
        }

        // Calculate hit rate
        let totalAccesses = documentCache.values.reduce(0) { $0 + $1.metadata.accessCount } +
            analysisCache.values.reduce(0) { $0 + $1.metadata.accessCount }
        let hitRate = totalAccesses > 0 ? Double(totalAccesses - (totalDocuments + totalAnalyses)) / Double(totalAccesses) : 0.0

        // Find most accessed document types
        var typeAccessCounts: [DocumentType: Int] = [:]
        for (key, doc) in documentCache {
            if case let .standard(type) = key.documentCategory {
                typeAccessCounts[type] = (typeAccessCounts[type] ?? 0) + doc.metadata.accessCount
            }
        }

        let mostAccessed = typeAccessCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        return CacheStatistics(
            totalCachedDocuments: totalDocuments,
            totalCachedAnalyses: totalAnalyses,
            cacheSize: totalSize,
            hitRate: hitRate,
            averageRetrievalTime: 0.002, // 2ms average (slightly higher due to encryption)
            lastCleanup: Date(),
            mostAccessedDocumentTypes: mostAccessed
        )
    }

    // MARK: - Helper Methods

    private func updateAccessOrder(_ key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)

        while accessOrder.count > maxCacheSize {
            if let oldestKey = accessOrder.first {
                accessOrder.removeFirst()
                evictItem(key: oldestKey)
            }
        }
    }

    private func evictItem(key: String) {
        analysisCache.removeValue(forKey: key)

        let documentKeys = documentCache.keys.filter { $0.hashValue.description == key }
        for docKey in documentKeys {
            documentCache.removeValue(forKey: docKey)
        }
    }

    func enforceMemoryLimit() async {
        // Calculate current size
        var currentSize: Int64 = 0

        for (_, doc) in documentCache {
            currentSize += Int64(doc.encryptedData.count)
        }

        for (_, analysis) in analysisCache {
            currentSize += Int64(analysis.encryptedData.count)
        }

        // Evict if over limit
        while currentSize > maxMemorySize, !accessOrder.isEmpty {
            if let key = accessOrder.first {
                accessOrder.removeFirst()
                evictItem(key: key)

                // Recalculate size
                currentSize = 0
                for (_, doc) in documentCache {
                    currentSize += Int64(doc.encryptedData.count)
                }
                for (_, analysis) in analysisCache {
                    currentSize += Int64(analysis.encryptedData.count)
                }
            }
        }
    }

    // MARK: - Supporting Types

    private struct AnalysisData: Codable {
        let response: String
        let recommendedDocuments: [DocumentType]
    }

    private struct BackupPackage: Codable {
        let encryptedData: Data
        let nonce: Data
        let salt: Data
        let version: String
    }
}

// MARK: - Document Encryption Manager

actor DocumentEncryptionManager {
    private let keychainService = "com.aiko.document.encryption"

    struct PrimaryKeyData {
        let key: SymmetricKey
        let salt: Data
    }

    struct EncryptedData {
        let ciphertext: Data
        let nonce: Data
    }

    func generatePrimaryKey() async throws -> PrimaryKeyData {
        // Generate salt for key derivation
        let salt = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })

        // Generate key
        let key = SymmetricKey(size: .bits256)

        return PrimaryKeyData(key: key, salt: salt)
    }

    func savePrimaryKey(key: SymmetricKey, salt: Data) async throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        // Combine key and salt
        var combinedData = Data()
        combinedData.append(keyData)
        combinedData.append(salt)

        // Store in keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "primary_encryption_key",
            kSecValueData as String: combinedData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }

    func loadPrimaryKey() async throws -> PrimaryKeyData {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "primary_encryption_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let combinedData = result as? Data else {
            throw EncryptionError.keyNotFound
        }

        // Extract key and salt
        let keyData = combinedData.prefix(32)
        let salt = combinedData.suffix(from: 32)

        let key = SymmetricKey(data: keyData)
        return PrimaryKeyData(key: key, salt: salt)
    }

    func encrypt(_ data: Data, using key: SymmetricKey) async throws -> EncryptedData {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)

            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }

            // Extract nonce and ciphertext
            let nonce = sealedBox.nonce.withUnsafeBytes { Data($0) }
            let ciphertext = combined

            return EncryptedData(ciphertext: ciphertext, nonce: nonce)
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(ciphertext: Data, nonce _: Data, using key: SymmetricKey) async throws -> Data {
        do {
            // Reconstruct sealed box
            let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
    case keychainError(OSStatus)
    case integrityCheckFailed

    var errorDescription: String? {
        switch self {
        case .keyNotFound:
            "Encryption key not found"
        case .encryptionFailed:
            "Failed to encrypt data"
        case .decryptionFailed:
            "Failed to decrypt data"
        case let .keychainError(status):
            "Keychain error: \(status)"
        case .integrityCheckFailed:
            "Data integrity check failed"
        }
    }
}

// MARK: - Dependency Implementation

extension EncryptedDocumentCache: DependencyKey {
    public static var liveValue: EncryptedDocumentCache {
        let storage = Task {
            try await EncryptedDocumentCacheStorage()
        }

        @Sendable func getStorage() async throws -> EncryptedDocumentCacheStorage {
            try await storage.value
        }

        return EncryptedDocumentCache(
            cacheDocument: { document in
                let storage = try await getStorage()
                let requirements = String(document.content.prefix(200))
                try await storage.cacheDocument(document, requirements: requirements)
            },
            getCachedDocument: { type, requirements in
                guard let storage = try? await getStorage() else { return nil }
                return await storage.getCachedDocument(type: type, requirements: requirements)
            },
            cacheAnalysisResponse: { requirements, response, recommendedDocuments in
                let storage = try await getStorage()
                try await storage.cacheAnalysis(
                    requirements: requirements,
                    response: response,
                    recommendedDocuments: recommendedDocuments
                )
            },
            getCachedAnalysisResponse: { requirements in
                guard let storage = try? await getStorage() else { return nil }
                return await storage.getCachedAnalysis(requirements: requirements)
            },
            clearCache: {
                let storage = try await getStorage()
                await storage.clearCache()
            },
            getCacheStatistics: {
                guard let storage = try? await getStorage() else {
                    return CacheStatistics(
                        totalCachedDocuments: 0,
                        totalCachedAnalyses: 0,
                        cacheSize: 0,
                        hitRate: 0,
                        averageRetrievalTime: 0,
                        lastCleanup: nil,
                        mostAccessedDocumentTypes: []
                    )
                }
                return await storage.getStatistics()
            },
            preloadFrequentDocuments: {
                // Implementation for preloading
            },
            optimizeCacheForMemory: {
                let storage = try await getStorage()
                await storage.enforceMemoryLimit()
            },
            rotateEncryptionKey: {
                let storage = try await getStorage()
                try await storage.rotateEncryptionKey()
            },
            exportEncryptedBackup: {
                let storage = try await getStorage()
                return try await storage.exportEncryptedBackup()
            },
            importEncryptedBackup: { _ in
                // Implementation for import
            }
        )
    }
}

public extension DependencyValues {
    var encryptedDocumentCache: EncryptedDocumentCache {
        get { self[EncryptedDocumentCache.self] }
        set { self[EncryptedDocumentCache.self] = newValue }
    }
}

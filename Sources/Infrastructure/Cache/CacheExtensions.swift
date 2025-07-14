//
//  CacheExtensions.swift
//  AIKO
//
//  Extensions to support cache API functionality
//

import Foundation

// MARK: - MemoryCache Extensions

extension MemoryCache {
    
    /// Get metadata for a key
    func getMetadata(forKey key: String) async -> OfflineCacheMetadata? {
        guard let entry = storage[key] else { return nil }
        
        return OfflineCacheMetadata(
            key: key,
            size: Int64(entry.data.count),
            contentType: entry.contentType,
            createdAt: entry.createdAt,
            lastAccessed: entry.lastAccessedAt,
            accessCount: entry.accessCount,
            expiresAt: entry.expiresAt
        )
    }
    
    /// Check cache health
    func checkHealth() async -> Bool {
        // Check if cache is operating normally
        let currentSize = await size()
        let maxSize = Int64(configuration.maxSize / 3) // Memory gets 1/3 of total
        
        return currentSize < Int64(Double(maxSize) * 0.9)
    }
    
    /// Remove expired entries from memory cache
    func removeExpiredMemoryEntries() async {
        let expiredKeys = storage.compactMap { key, entry in
            entry.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            storage.removeValue(forKey: key)
        }
    }
    
    /// Export all data
    func exportAllData() async -> [String: Data] {
        var exportData: [String: Data] = [:]
        
        for (key, entry) in storage {
            exportData[key] = entry.data
        }
        
        return exportData
    }
}

// MARK: - DiskCache Extensions

extension DiskCache {
    
    /// Get metadata for a key
    func getMetadata(forKey key: String) async -> OfflineCacheMetadata? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            let createdAt = attributes[.creationDate] as? Date ?? Date()
            let modifiedAt = attributes[.modificationDate] as? Date ?? Date()
            
            // Load metadata file if exists
            let metadataURL = fileURL.appendingPathExtension("metadata")
            if let metadataData = try? Data(contentsOf: metadataURL),
               let metadata = try? JSONDecoder().decode(DiskCacheMetadata.self, from: metadataData) {
                return OfflineCacheMetadata(
                    key: key,
                    size: size,
                    contentType: metadata.contentType,
                    createdAt: createdAt,
                    lastAccessed: modifiedAt,
                    accessCount: metadata.accessCount,
                    expiresAt: metadata.expiresAt
                )
            }
            
            return OfflineCacheMetadata(
                key: key,
                size: size,
                contentType: .document,
                createdAt: createdAt,
                lastAccessed: modifiedAt,
                accessCount: 0,
                expiresAt: nil
            )
        } catch {
            return nil
        }
    }
    
    /// Check cache health
    func checkHealth() async -> Bool {
        // Verify cache directory exists and is writable
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: cacheDirectory.path,
            isDirectory: &isDirectory
        )
        
        guard exists && isDirectory.boolValue else { return false }
        
        // Check available disk space
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(
                forPath: cacheDirectory.path
            )
            
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                // Need at least 100MB free
                return freeSpace > 100_000_000
            }
        } catch {
            return false
        }
        
        return true
    }
    
    /// Remove expired entries from disk cache
    func removeExpiredDiskEntries() async {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: []
            )
            
            for fileURL in contents {
                // Check metadata for expiration
                let metadataURL = fileURL.appendingPathExtension("metadata")
                if let metadataData = try? Data(contentsOf: metadataURL),
                   let metadata = try? JSONDecoder().decode(DiskCacheMetadata.self, from: metadataData),
                   let expiresAt = metadata.expiresAt,
                   expiresAt < Date() {
                    // Remove expired file and metadata
                    try? FileManager.default.removeItem(at: fileURL)
                    try? FileManager.default.removeItem(at: metadataURL)
                }
            }
        } catch {
            // Log error
        }
    }
    
    /// Export all data
    func exportAllData() async -> [String: Data] {
        var exportData: [String: Data] = [:]
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil,
                options: []
            )
            
            for fileURL in contents {
                // Skip metadata files
                if fileURL.pathExtension == "metadata" {
                    continue
                }
                
                let key = fileURL.lastPathComponent
                if let data = try? Data(contentsOf: fileURL) {
                    exportData[key] = data
                }
            }
        } catch {
            // Log error
        }
        
        return exportData
    }
}

// MARK: - SecureCache Extensions

extension SecureCache {
    
    /// Get metadata for a key
    func getMetadata(forKey key: String) async -> OfflineCacheMetadata? {
        // Try to get from keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let attributes = result as? [String: Any] else {
            return nil
        }
        
        // Extract metadata from attributes
        let createdAt = attributes[kSecAttrCreationDate as String] as? Date ?? Date()
        let modifiedAt = attributes[kSecAttrModificationDate as String] as? Date ?? Date()
        
        return OfflineCacheMetadata(
            key: key,
            size: 0, // Size not directly available
            contentType: .userData,
            createdAt: createdAt,
            lastAccessed: modifiedAt,
            accessCount: 0,
            expiresAt: nil
        )
    }
    
    /// Check cache health
    func checkHealth() async -> Bool {
        // Verify keychain is accessible
        let testKey = "health_check_test"
        let testData = "test".data(using: .utf8)!
        
        // Try to store and retrieve
        do {
            try await storeData(testData, forKey: testKey)
            let retrieved = try await retrieveData(forKey: testKey)
            try await remove(forKey: testKey)
            
            return retrieved != nil
        } catch {
            return false
        }
    }
    
    /// Remove expired entries from secure cache
    func removeExpiredSecureEntries() async {
        // Keychain doesn't support expiration directly
        // Would need to implement custom expiration tracking
    }
    
    /// Export all data (with caution)
    func exportAllData() async -> [String: Data] {
        // Note: Exporting secure data should be done with extreme caution
        // This is a placeholder - real implementation would need security checks
        [:]
    }
}

// MARK: - Supporting Types

struct DiskCacheMetadata: Codable {
    let contentType: CacheContentType
    let accessCount: Int
    let expiresAt: Date?
}

// MARK: - Cache Statistics Extension

extension OfflineCacheStatistics {
    mutating func recordRetrieval(duration: TimeInterval) {
        let currentAvg = averageRetrievalTime
        let newCount = Double(hitCount + missCount)
        averageRetrievalTime = (currentAvg * (newCount - 1) + duration) / newCount
    }
    
    mutating func recordStorage(duration: TimeInterval) {
        let currentAvg = averageStorageTime
        let newCount = Double(entryCount)
        averageStorageTime = (currentAvg * (newCount - 1) + duration) / newCount
    }
}
//
//  DiskCache.swift
//  AIKO
//
//  Created for offline caching system
//

import AppCore
import Foundation
import os.log

/// Disk-based cache implementation for persistent storage
actor DiskCache: OfflineCacheProtocol {
    /// Logger
    private let logger = Logger(subsystem: "com.aiko.cache", category: "DiskCache")

    /// Cache directory URL
    let cacheDirectory: URL

    /// Cache configuration
    private let configuration: OfflineCacheConfiguration

    /// Metadata storage
    private var metadata: [String: CacheEntry] = [:]

    /// Metadata file URL
    private var metadataURL: URL {
        cacheDirectory.appendingPathComponent("cache_metadata.json")
    }

    /// File manager
    private let fileManager = FileManager.default

    /// Initialize with configuration
    init(configuration: OfflineCacheConfiguration) {
        self.configuration = configuration

        // Set up cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        cacheDirectory = documentsPath.appendingPathComponent("AIKOCache/DiskCache")

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load metadata
        Task {
            await self.loadMetadata()
        }
    }

    func store(_ object: some Codable & Sendable, forKey key: String) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try await storeData(data, forKey: key)
    }

    func retrieve<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard let data = try await retrieveData(forKey: key) else { return nil }

        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    func storeData(_ data: Data, forKey key: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(key.fileNameSafe())

        // Check size limits
        let currentSize = await size()
        let newSize = Int64(data.count)

        if currentSize + newSize > configuration.maxSize {
            try await makeSpace(for: newSize)
        }

        // Write data to disk
        do {
            try data.write(to: fileURL)

            // Update metadata
            let entry = CacheEntry(
                key: key,
                data: Data(), // Don't store data in metadata
                contentType: .document,
                expiresAt: Date().addingTimeInterval(configuration.defaultExpiration)
            )

            metadata[key] = entry
            await saveMetadata()

            logger.debug("Stored \(newSize) bytes to disk for key: \(key)")
        } catch {
            logger.error("Failed to write to disk: \(error)")
            throw OfflineCacheError.storageFailure(error.localizedDescription)
        }
    }

    func retrieveData(forKey key: String) async throws -> Data? {
        guard var entry = metadata[key] else {
            logger.debug("No metadata for key: \(key)")
            return nil
        }

        // Check expiration
        if entry.isExpired {
            logger.debug("Entry expired for key: \(key)")
            try await remove(forKey: key)
            return nil
        }

        let fileURL = cacheDirectory.appendingPathComponent(key.fileNameSafe())

        do {
            let data = try Data(contentsOf: fileURL)

            // Update access metadata
            entry.lastAccessedAt = Date()
            entry.accessCount += 1
            metadata[key] = entry
            await saveMetadata()

            logger.debug("Retrieved \(data.count) bytes from disk for key: \(key)")
            return data
        } catch {
            logger.error("Failed to read from disk: \(error)")
            // Remove corrupt metadata
            metadata.removeValue(forKey: key)
            await saveMetadata()
            return nil
        }
    }

    func remove(forKey key: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(key.fileNameSafe())

        try? fileManager.removeItem(at: fileURL)
        metadata.removeValue(forKey: key)
        await saveMetadata()

        logger.debug("Removed disk cache for key: \(key)")
    }

    func clearAll() async throws {
        // Remove all files
        if let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for fileURL in contents {
                try? fileManager.removeItem(at: fileURL)
            }
        }

        metadata.removeAll()
        await saveMetadata()

        logger.info("Cleared all disk cache")
    }

    func size() async -> Int64 {
        var totalSize: Int64 = 0

        if let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for fileURL in contents {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }

    func exists(forKey key: String) async -> Bool {
        guard let entry = metadata[key], !entry.isExpired else { return false }

        let fileURL = cacheDirectory.appendingPathComponent(key.fileNameSafe())
        return fileManager.fileExists(atPath: fileURL.path)
    }

    func allKeys() async -> [String] {
        Array(metadata.keys)
    }

    func setExpiration(_ duration: TimeInterval, forKey key: String) async throws {
        guard var entry = metadata[key] else {
            throw OfflineCacheError.keyNotFound
        }

        entry.expiresAt = Date().addingTimeInterval(duration)
        metadata[key] = entry
        await saveMetadata()
    }

    /// Remove expired entries
    private func removeExpiredEntries() async {
        let expiredKeys = metadata.compactMap { key, entry in
            entry.isExpired ? key : nil
        }

        for key in expiredKeys {
            try? await remove(forKey: key)
        }

        if !expiredKeys.isEmpty {
            logger.debug("Removed \(expiredKeys.count) expired entries from disk")
        }
    }

    /// Load metadata from disk
    private func loadMetadata() async {
        guard fileManager.fileExists(atPath: metadataURL.path) else { return }

        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            metadata = try decoder.decode([String: CacheEntry].self, from: data)
            logger.debug("Loaded metadata with \(metadata.count) entries")
        } catch {
            logger.error("Failed to load metadata: \(error)")
            metadata = [:]
        }
    }

    /// Save metadata to disk
    private func saveMetadata() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            logger.error("Failed to save metadata: \(error)")
        }
    }

    /// Make space for new data
    private func makeSpace(for requiredSize: Int64) async throws {
        // Remove expired entries first
        await removeExpiredEntries()

        let currentSize = await size()
        if currentSize + requiredSize > configuration.maxSize {
            // Apply eviction policy
            switch configuration.evictionPolicy {
            case .leastRecentlyUsed:
                await evictLRU(targetSize: requiredSize)
            case .leastFrequentlyUsed:
                await evictLFU(targetSize: requiredSize)
            case .firstInFirstOut:
                await evictFIFO(targetSize: requiredSize)
            case .timeBasedExpiration:
                break
            }
        }

        // Final check
        let finalSize = await size()
        if finalSize + requiredSize > configuration.maxSize {
            throw OfflineCacheError.insufficientSpace
        }
    }

    /// Evict least recently used entries
    private func evictLRU(targetSize: Int64) async {
        let sortedEntries = metadata.values.sorted { $0.lastAccessedAt < $1.lastAccessedAt }
        let currentSize = await size()
        var targetRemoval = currentSize + targetSize - configuration.maxSize

        for entry in sortedEntries {
            if targetRemoval <= 0 { break }

            let fileURL = cacheDirectory.appendingPathComponent(entry.key.fileNameSafe())
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                try? await remove(forKey: entry.key)
                targetRemoval -= Int64(fileSize)
            }
        }
    }

    /// Evict least frequently used entries
    private func evictLFU(targetSize: Int64) async {
        let sortedEntries = metadata.values.sorted { $0.accessCount < $1.accessCount }
        let currentSize = await size()
        var targetRemoval = currentSize + targetSize - configuration.maxSize

        for entry in sortedEntries {
            if targetRemoval <= 0 { break }

            let fileURL = cacheDirectory.appendingPathComponent(entry.key.fileNameSafe())
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                try? await remove(forKey: entry.key)
                targetRemoval -= Int64(fileSize)
            }
        }
    }

    /// Evict oldest entries first
    private func evictFIFO(targetSize: Int64) async {
        let sortedEntries = metadata.values.sorted { $0.createdAt < $1.createdAt }
        let currentSize = await size()
        var targetRemoval = currentSize + targetSize - configuration.maxSize

        for entry in sortedEntries {
            if targetRemoval <= 0 { break }

            let fileURL = cacheDirectory.appendingPathComponent(entry.key.fileNameSafe())
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                try? await remove(forKey: entry.key)
                targetRemoval -= Int64(fileSize)
            }
        }
    }
}

// MARK: - String Extension

extension String {
    /// Convert string to file-safe name
    func fileNameSafe() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

import AppCore
import CoreData
import Foundation
import os
import Security

public struct SettingsManager: Sendable {
    public var loadSettings: @Sendable () async throws -> SettingsData
    public var saveSettings: @Sendable () async throws -> Void
    public var resetToDefaults: @Sendable () async throws -> Void
    public var restoreDefaults: @Sendable () async throws -> Void
    public var saveAPIKey: @Sendable (String) async throws -> Void
    public var loadAPIKey: @Sendable () async throws -> String?
    public var validateAPIKey: @Sendable (String) async -> Bool
    public var exportData: @Sendable (@escaping @Sendable (Double) -> Void) async throws -> URL
    public var importData: @Sendable (URL) async throws -> Void
    public var clearCache: @Sendable () async throws -> Void
    public var performBackup: @Sendable (@escaping @Sendable (Double) -> Void) async throws -> URL
    public var restoreBackup: @Sendable (URL, @escaping @Sendable (Double) -> Void) async throws -> Void

    public init(
        loadSettings: @escaping @Sendable () async throws -> SettingsData,
        saveSettings: @escaping @Sendable () async throws -> Void,
        resetToDefaults: @escaping @Sendable () async throws -> Void,
        restoreDefaults: @escaping @Sendable () async throws -> Void,
        saveAPIKey: @escaping @Sendable (String) async throws -> Void,
        loadAPIKey: @escaping @Sendable () async throws -> String?,
        validateAPIKey: @escaping @Sendable (String) async -> Bool,
        exportData: @escaping @Sendable (@escaping @Sendable (Double) -> Void) async throws -> URL,
        importData: @escaping @Sendable (URL) async throws -> Void,
        clearCache: @escaping @Sendable () async throws -> Void,
        performBackup: @escaping @Sendable (@escaping @Sendable (Double) -> Void) async throws -> URL,
        restoreBackup: @escaping @Sendable (URL, @escaping @Sendable (Double) -> Void) async throws -> Void
    ) {
        self.loadSettings = loadSettings
        self.saveSettings = saveSettings
        self.resetToDefaults = resetToDefaults
        self.restoreDefaults = restoreDefaults
        self.saveAPIKey = saveAPIKey
        self.loadAPIKey = loadAPIKey
        self.validateAPIKey = validateAPIKey
        self.exportData = exportData
        self.importData = importData
        self.clearCache = clearCache
        self.performBackup = performBackup
        self.restoreBackup = restoreBackup
    }
}

// SettingsData and related structs moved to AppCore/Models/SettingsData.swift


// Using AppCore.APISettingsData

// Using AppCore.APIKeyEntryData

// Using AppCore.DocumentSettingsData

// Using AppCore.NotificationSettingsData

// Using AppCore.DataPrivacySettingsData

// Using AppCore.AdvancedSettingsData

public extension SettingsManager {
    nonisolated static var liveValue: SettingsManager {
        let settingsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("aiko_settings.json")

        @Sendable
        func loadSettingsData() async throws -> SettingsData {
            if FileManager.default.fileExists(atPath: settingsURL.path) {
                let data = try Data(contentsOf: settingsURL)
                return try JSONDecoder().decode(SettingsData.self, from: data)
            } else {
                return SettingsData()
            }
        }

        @Sendable
        func saveSettingsData(_ settings: SettingsData) async throws {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: settingsURL)
        }

        // Shared settings state
        let currentSettings = OSAllocatedUnfairLock(initialState: SettingsData())

        return SettingsManager(
            loadSettings: {
                let settings = try await loadSettingsData()
                currentSettings.withLock { $0 = settings }
                return settings
            },
            saveSettings: {
                let settings = currentSettings.withLock { $0 }
                try await saveSettingsData(settings)
            },
            resetToDefaults: {
                let defaultSettings = SettingsData()
                currentSettings.withLock { $0 = defaultSettings }
                try await saveSettingsData(defaultSettings)
            },
            restoreDefaults: {
                // Clear all settings and cache
                let defaultSettings = SettingsData()
                currentSettings.withLock { $0 = defaultSettings }
                try await saveSettingsData(defaultSettings)

                // Clear API key from keychain
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "com.aiko.api",
                    kSecAttrAccount as String: "anthropic_api_key",
                ]
                SecItemDelete(query as CFDictionary)

                // Clear cache
                let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                if FileManager.default.fileExists(atPath: cacheURL.path) {
                    try FileManager.default.removeItem(at: cacheURL)
                }

                // Clear documents directory (except settings file)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let contents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                for item in contents where item.lastPathComponent != "aiko_settings.json" {
                    try FileManager.default.removeItem(at: item)
                }
            },
            saveAPIKey: { key in
                // Save to keychain
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "com.aiko.api",
                    kSecAttrAccount as String: "anthropic_api_key",
                    kSecValueData as String: key.data(using: .utf8) ?? Data(),
                ]

                // Delete existing
                SecItemDelete(query as CFDictionary)

                // Add new
                let status = SecItemAdd(query as CFDictionary, nil)
                if status != errSecSuccess {
                    throw SettingsError.keychainError
                }
            },
            loadAPIKey: {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "com.aiko.api",
                    kSecAttrAccount as String: "anthropic_api_key",
                    kSecReturnData as String: true,
                ]

                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)

                if status == errSecSuccess,
                   let data = result as? Data,
                   let key = String(data: data, encoding: .utf8) {
                    return key
                }

                return nil
            },
            validateAPIKey: { key in
                // Simple validation - check if it looks like a valid Anthropic API key
                key.hasPrefix("sk-ant-") && key.count > 20
            },
            exportData: { progressHandler in
                let exportURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("aiko_export_\(Date().timeIntervalSince1970).json")

                // Simulate progress
                progressHandler(0.1)

                // Gather all data
                let settings = currentSettings.withLock { $0 }
                progressHandler(0.3)

                // Create export data structure
                let exportData = ExportData(
                    settings: settings,
                    exportDate: Date(),
                    version: "1.0"
                )
                progressHandler(0.6)

                // Encode and save
                let data = try JSONEncoder().encode(exportData)
                try data.write(to: exportURL)
                progressHandler(1.0)

                return exportURL
            },
            importData: { url in
                let data = try Data(contentsOf: url)
                let exportData = try JSONDecoder().decode(ExportData.self, from: data)

                // Import settings
                currentSettings.withLock { $0 = exportData.settings }
                try await saveSettingsData(exportData.settings)
            },
            clearCache: {
                // Clear cache directory
                let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let contents = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)

                for item in contents {
                    try FileManager.default.removeItem(at: item)
                }
            },
            performBackup: { progressHandler in
                let backupURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("aiko_backup_\(Date().timeIntervalSince1970).json")

                progressHandler(0.1)

                // Gather all data including settings, Core Data, templates
                let settings = currentSettings.withLock { $0 }
                progressHandler(0.2)

                // Export Core Data
                let coreDataSnapshot: Data?
                do {
                    coreDataSnapshot = try await Task.detached {
                        try await CoreDataStack.shared.exportCoreDataToJSON()
                    }.value
                } catch {
                    print("Failed to export Core Data: \(error)")
                    coreDataSnapshot = nil
                }
                progressHandler(0.4)

                // Export templates
                var templates: [CustomTemplate] = []
                do {
                    let templateService = TemplateStorageService.liveValue
                    templates = try await templateService.loadTemplates()
                } catch {
                    print("Failed to export templates: \(error)")
                    templates = []
                }
                progressHandler(0.6)

                // Create backup data structure
                let backupData = BackupData(
                    settings: settings,
                    coreDataSnapshot: coreDataSnapshot,
                    templates: templates.map { template in
                        // Convert CustomTemplate to JSON string
                        if let data = try? JSONEncoder().encode(template),
                           let jsonString = String(data: data, encoding: .utf8) {
                            return jsonString
                        }
                        return ""
                    }.filter { !$0.isEmpty },
                    backupDate: Date(),
                    version: "1.0"
                )
                progressHandler(0.7)

                // Encode and save
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(backupData)
                try data.write(to: backupURL)
                progressHandler(1.0)

                return backupURL
            },
            restoreBackup: { url, progressHandler in
                progressHandler(0.1)

                // Read backup file
                let data = try Data(contentsOf: url)
                let backupData = try JSONDecoder().decode(BackupData.self, from: data)
                progressHandler(0.2)

                // Restore settings
                currentSettings.withLock { $0 = backupData.settings }
                try await saveSettingsData(backupData.settings)
                progressHandler(0.4)

                // Restore Core Data if available
                if let coreDataSnapshot = backupData.coreDataSnapshot {
                    do {
                        try await Task.detached {
                            try await CoreDataStack.shared.importCoreDataFromJSON(coreDataSnapshot)
                        }.value
                    } catch {
                        print("Failed to restore Core Data: \(error)")
                    }
                }
                progressHandler(0.7)

                // Restore templates
                if !backupData.templates.isEmpty {
                    let templateService = TemplateStorageService.liveValue
                    for templateJSON in backupData.templates {
                        if let data = templateJSON.data(using: .utf8),
                           let template = try? JSONDecoder().decode(CustomTemplate.self, from: data) {
                            try? await templateService.saveTemplate(template)
                        }
                    }
                }
                progressHandler(1.0)
            }
        )
    }

    static var testValue: SettingsManager {
        SettingsManager(
            loadSettings: { SettingsData() },
            saveSettings: {},
            resetToDefaults: {},
            restoreDefaults: {},
            saveAPIKey: { _ in },
            loadAPIKey: { "test-api-key" },
            validateAPIKey: { _ in true },
            exportData: { _ in URL(string: "file://test.json") ?? URL(fileURLWithPath: "/tmp/test.json") },
            importData: { _ in },
            clearCache: {},
            performBackup: { _ in URL(string: "file://backup.json") ?? URL(fileURLWithPath: "/tmp/backup.json") },
            restoreBackup: { _, _ in }
        )
    }

    static var previewValue: SettingsManager {
        SettingsManager(
            loadSettings: {
                var settings = SettingsData()
                settings.appSettings.faceIDEnabled = false // Disable Face ID for previews
                return settings
            },
            saveSettings: {},
            resetToDefaults: {},
            restoreDefaults: {},
            saveAPIKey: { _ in },
            loadAPIKey: { "preview-api-key" },
            validateAPIKey: { _ in true },
            exportData: { _ in URL(string: "file://test.json") ?? URL(fileURLWithPath: "/tmp/test.json") },
            importData: { _ in },
            clearCache: {},
            performBackup: { _ in URL(string: "file://backup.json") ?? URL(fileURLWithPath: "/tmp/backup.json") },
            restoreBackup: { _, _ in }
        )
    }
}

struct ExportData: Codable {
    let settings: SettingsData
    let exportDate: Date
    let version: String
}

struct BackupData: Codable {
    let settings: SettingsData
    let coreDataSnapshot: Data?
    let templates: [String]
    let backupDate: Date
    let version: String
}

enum SettingsError: Error {
    case keychainError
    case importError
    case exportError
}

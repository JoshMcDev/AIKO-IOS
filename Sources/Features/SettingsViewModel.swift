import SwiftUI
import Foundation
import AppCore

// MARK: - SaveStatus Enum

@frozen
public enum SaveStatus: Equatable {
    case none
    case saving
    case saved
    case error
}

// MARK: - SettingsViewModel

@MainActor
@Observable
public final class SettingsViewModel {
    
    // MARK: - State Properties
    
    public var settingsData: SettingsData
    public var isLoading: Bool = false
    public var saveStatus: SaveStatus = .none
    public var validationError: String?
    public var error: Error?
    public var showingSettings: Bool = false
    
    // MARK: - Test Support Properties
    
    public var simulateSaveFailure: Bool = false
    
    // MARK: - Initialization
    
    public init(settingsData: SettingsData = SettingsData()) {
        self.settingsData = settingsData
    }
    
    // MARK: - App Settings Methods
    
    public func updateAppSetting<T>(_ keyPath: WritableKeyPath<AppSettingsData, T>, value: T) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        // Apply validation for specific settings
        if keyPath == \.autoSaveInterval, let interval = value as? Int {
            let clampedInterval = max(10, min(300, interval))
            settingsData.appSettings[keyPath: keyPath] = clampedInterval as! T
        } else if keyPath == \.theme, let theme = value as? String {
            let validThemes = ["system", "light", "dark"]
            if validThemes.contains(theme) {
                settingsData.appSettings[keyPath: keyPath] = value
            } else {
                validationError = "Invalid theme selection"
                isLoading = false
                saveStatus = .error
                return
            }
        } else {
            settingsData.appSettings[keyPath: keyPath] = value
        }
        
        await saveSettings()
    }
    
    // MARK: - API Settings Methods
    
    public func updateAPISetting<T>(_ keyPath: WritableKeyPath<APISettingsData, T>, value: T) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        settingsData.apiSettings[keyPath: keyPath] = value
        await saveSettings()
    }
    
    public func addAPIKey(_ apiKey: APIKeyEntryData) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        // Validate API key format
        guard apiKey.key.hasPrefix("sk-ant-") || apiKey.key.hasPrefix("sk-") else {
            validationError = "API key format is invalid. Key must start with 'sk-ant-' or 'sk-'"
            isLoading = false
            saveStatus = .error
            return
        }
        
        // Deactivate other keys if this one is active
        if apiKey.isActive {
            for index in settingsData.apiSettings.apiKeys.indices {
                settingsData.apiSettings.apiKeys[index].isActive = false
            }
            settingsData.apiSettings.selectedAPIKeyId = apiKey.id
        }
        
        settingsData.apiSettings.apiKeys.append(apiKey)
        await saveSettings()
    }
    
    public func removeAPIKey(_ keyId: String) async {
        isLoading = true
        saveStatus = .saving
        
        settingsData.apiSettings.apiKeys.removeAll { $0.id == keyId }
        
        // If removed key was selected, clear selection
        if settingsData.apiSettings.selectedAPIKeyId == keyId {
            settingsData.apiSettings.selectedAPIKeyId = ""
        }
        
        await saveSettings()
    }
    
    public func selectAPIKey(_ keyId: String) async {
        isLoading = true
        saveStatus = .saving
        
        // Deactivate all keys
        for index in settingsData.apiSettings.apiKeys.indices {
            settingsData.apiSettings.apiKeys[index].isActive = false
        }
        
        // Activate selected key
        if let index = settingsData.apiSettings.apiKeys.firstIndex(where: { $0.id == keyId }) {
            settingsData.apiSettings.apiKeys[index].isActive = true
            settingsData.apiSettings.selectedAPIKeyId = keyId
        }
        
        await saveSettings()
    }
    
    // MARK: - Document Settings Methods
    
    public func updateDocumentSetting<T>(_ keyPath: WritableKeyPath<DocumentSettingsData, T>, value: T) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        settingsData.documentSettings[keyPath: keyPath] = value
        await saveSettings()
    }
    
    // MARK: - Notification Settings Methods
    
    public func updateNotificationSetting<T>(_ keyPath: WritableKeyPath<NotificationSettingsData, T>, value: T) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        settingsData.notificationSettings[keyPath: keyPath] = value
        await saveSettings()
    }
    
    // MARK: - Privacy Settings Methods
    
    public func updatePrivacySetting<T>(_ keyPath: WritableKeyPath<DataPrivacySettingsData, T>, value: T) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        settingsData.dataPrivacySettings[keyPath: keyPath] = value
        await saveSettings()
    }
    
    // MARK: - Advanced Settings Methods
    
    public func updateAdvancedSetting<T>(_ keyPath: WritableKeyPath<AdvancedSettingsData, T>, value: T) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        settingsData.advancedSettings[keyPath: keyPath] = value
        await saveSettings()
    }
    
    // MARK: - Persistence Methods
    
    public func saveSettings() async {
        if simulateSaveFailure {
            error = NSError(domain: "SettingsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated save failure"])
            saveStatus = .error
            isLoading = false
            return
        }
        
        // Simulate persistence delay (reduced for better performance)
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // In real implementation, this would save to UserDefaults, Core Data, or other persistence
        // UserDefaults.standard.set(try? JSONEncoder().encode(settingsData), forKey: "settingsData")
        
        saveStatus = .saved
        isLoading = false
        
        // Reset save status after a brief delay (only in non-test environment)
        if !simulateSaveFailure { // Use simulateSaveFailure as a test environment indicator
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if saveStatus == .saved {
                    saveStatus = .none
                }
            }
        }
    }
    
    // MARK: - Reset and Export Methods
    
    public func resetToDefaults() async {
        isLoading = true
        saveStatus = .saving
        
        settingsData = SettingsData()
        await saveSettings()
    }
    
    public func exportSettings() async -> Data {
        // Simulate export processing delay
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        if let data = try? JSONEncoder().encode(settingsData) {
            return data
        } else {
            return Data()
        }
    }
    
    // MARK: - API Key Update Method
    
    public func updateAPIKey(_ updatedKey: APIKeyEntryData) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        // Find and update the existing key
        if let index = settingsData.apiSettings.apiKeys.firstIndex(where: { $0.id == updatedKey.id }) {
            settingsData.apiSettings.apiKeys[index] = updatedKey
            
            // Update selection if this key is active
            if updatedKey.isActive {
                settingsData.apiSettings.selectedAPIKeyId = updatedKey.id
                // Deactivate other keys
                for i in settingsData.apiSettings.apiKeys.indices where i != index {
                    settingsData.apiSettings.apiKeys[i].isActive = false
                }
            }
            
            await saveSettings()
        } else {
            validationError = "API key not found"
            isLoading = false
            saveStatus = .error
        }
    }
    
    // MARK: - Settings Import Method
    
    public func importSettings(_ data: Data) async {
        isLoading = true
        saveStatus = .saving
        validationError = nil
        
        do {
            let importedSettings = try JSONDecoder().decode(SettingsData.self, from: data)
            settingsData = importedSettings
            await saveSettings()
        } catch {
            validationError = "Failed to import settings: \(error.localizedDescription)"
            isLoading = false
            saveStatus = .error
        }
    }
}
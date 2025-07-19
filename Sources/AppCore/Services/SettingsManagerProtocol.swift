import Foundation

/// Platform-agnostic protocol for settings management
public protocol SettingsManagerProtocol {
    /// Load application settings
    func loadSettings() async throws -> SettingsData
    
    /// Save application settings
    func saveSettings(_ settings: SettingsData) async throws
    
    /// Reset settings to defaults
    func resetToDefaults() async throws
    
    /// Save API key securely
    func saveAPIKey(_ key: String) async throws
    
    /// Load API key securely
    func loadAPIKey() async throws -> String?
    
    /// Validate API key format
    func validateAPIKey(_ key: String) async -> Bool
    
    /// Export data with progress callback
    func exportData(progressHandler: @escaping (Double) -> Void) async throws -> URL
    
    /// Import data from URL
    func importData(from url: URL) async throws
    
    /// Clear application cache
    func clearCache() async throws
    
    /// Perform backup with progress callback
    func performBackup(progressHandler: @escaping (Double) -> Void) async throws -> URL
    
    /// Restore from backup with progress callback
    func restoreBackup(from url: URL, progressHandler: @escaping (Double) -> Void) async throws
}
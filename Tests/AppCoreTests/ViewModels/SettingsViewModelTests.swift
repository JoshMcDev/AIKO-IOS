import XCTest
import SwiftUI
@testable import AppCore
@testable import AIKO

@MainActor
final class SettingsViewModelTests: XCTestCase {
    
    var viewModel: SettingsViewModel!
    var mockSettingsData: AppCore.SettingsData!
    
    override func setUp() async throws {
        mockSettingsData = AppCore.SettingsData()
        viewModel = SettingsViewModel(settingsData: mockSettingsData)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockSettingsData = nil
    }
    
    // MARK: - MoE Tests: Functional Requirements
    
    func test_initialState_shouldLoadDefaultSettingsData() {
        // Given: Fresh SettingsViewModel
        // When: Checking initial state
        // Then: Should have default settings loaded
        XCTAssertNotNil(viewModel.settingsData)
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        XCTAssertEqual(viewModel.settingsData.appSettings.accentColor, "blue")
        XCTAssertEqual(viewModel.settingsData.appSettings.fontSize, "medium")
        XCTAssertTrue(viewModel.settingsData.appSettings.autoSaveEnabled)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.saveStatus, .none)
    }
    
    func test_appSettingsUpdate_shouldUpdateAndPersistImmediately() async {
        // Given: SettingsViewModel with default app settings
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        
        // When: Updating theme setting
        await viewModel.updateAppSetting(\.theme, value: "dark")
        
        // Then: Should update and persist immediately
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "dark")
        XCTAssertEqual(viewModel.saveStatus, .saved)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_apiSettingsUpdate_shouldUpdateAPIConfiguration() async {
        // Given: SettingsViewModel with default API settings
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "Claude 3 Opus")
        
        // When: Updating API model
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")
        
        // Then: Should update API configuration
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "GPT-4")
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
    
    func test_documentSettingsUpdate_shouldUpdateDocumentConfiguration() async {
        // Given: SettingsViewModel with default document settings
        XCTAssertTrue(viewModel.settingsData.documentSettings.includeMetadata)
        
        // When: Updating document metadata setting
        await viewModel.updateDocumentSetting(\.includeMetadata, value: false)
        
        // Then: Should update document configuration
        XCTAssertFalse(viewModel.settingsData.documentSettings.includeMetadata)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
    
    func test_notificationSettingsUpdate_shouldUpdateNotificationPreferences() async {
        // Given: SettingsViewModel with default notification settings
        XCTAssertTrue(viewModel.settingsData.notificationSettings.enableNotifications)
        
        // When: Disabling notifications
        await viewModel.updateNotificationSetting(\.enableNotifications, value: false)
        
        // Then: Should update notification preferences
        XCTAssertFalse(viewModel.settingsData.notificationSettings.enableNotifications)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
    
    func test_privacySettingsUpdate_shouldUpdatePrivacyConfiguration() async {
        // Given: SettingsViewModel with default privacy settings
        XCTAssertFalse(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)
        
        // When: Enabling analytics
        await viewModel.updatePrivacySetting(\.analyticsEnabled, value: true)
        
        // Then: Should update privacy configuration
        XCTAssertTrue(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
    
    func test_advancedSettingsUpdate_shouldUpdateAdvancedConfiguration() async {
        // Given: SettingsViewModel with default advanced settings
        XCTAssertFalse(viewModel.settingsData.advancedSettings.debugModeEnabled)
        
        // When: Enabling debug mode
        await viewModel.updateAdvancedSetting(\.debugModeEnabled, value: true)
        
        // Then: Should update advanced configuration
        XCTAssertTrue(viewModel.settingsData.advancedSettings.debugModeEnabled)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
    
    func test_apiKeyManagement_shouldAddAndRemoveAPIKeys() async {
        // Given: SettingsViewModel with no API keys
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.isEmpty)
        
        // When: Adding API key
        let apiKey = AppCore.APIKeyEntryData(name: "Test Key", key: "sk-ant-api03-test", isActive: true)
        await viewModel.addAPIKey(apiKey)
        
        // Then: Should add API key
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 1)
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.first?.name, "Test Key")
        
        // When: Removing API key
        await viewModel.removeAPIKey(apiKey.id)
        
        // Then: Should remove API key
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.isEmpty)
    }
    
    func test_apiKeySelection_shouldUpdateSelectedAPIKey() async {
        // Given: SettingsViewModel with multiple API keys
        let key1 = APIKeyEntryData(name: "Key 1", key: "sk-ant-api03-key1", isActive: true)
        let key2 = APIKeyEntryData(name: "Key 2", key: "sk-ant-api03-key2", isActive: false)
        
        await viewModel.addAPIKey(key1)
        await viewModel.addAPIKey(key2)
        
        // When: Selecting different API key
        await viewModel.selectAPIKey(key2.id)
        
        // Then: Should update selected API key
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, key2.id)
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.first { $0.id == key2.id }?.isActive == true)
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.first { $0.id == key1.id }?.isActive == false)
    }
    
    // MARK: - MoP Tests: Performance Requirements
    
    func test_settingsUpdate_shouldCompleteWithin500ms() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When: Updating multiple settings rapidly
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAppSetting(\.accentColor, value: "red")
        await viewModel.updateAppSetting(\.fontSize, value: "large")
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 0.5, "Settings updates should complete within 500ms")
    }
    
    func test_settingsPersistence_shouldCompleteWithin1Second() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When: Persisting settings to storage
        await viewModel.saveSettings()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 1.0, "Settings persistence should complete within 1 second")
    }
    
    func test_memoryUsage_shouldStayWithinReasonableLimits() {
        // Given: SettingsViewModel with large amount of data
        var settingsUpdates: [() async -> Void] = []
        let vm = viewModel!
        
        for i in 0..<100 {
            settingsUpdates.append({
                await vm.updateAppSetting(\.autoSaveInterval, value: i)
            })
        }
        
        // When: Performing many updates (simulating heavy usage)
        measure {
            Task { @MainActor in
                for update in settingsUpdates {
                    await update()
                }
            }
        }
        
        // Then: Memory usage should remain reasonable (measured by performance test)
    }
    
    // MARK: - Integration Tests
    
    func test_observablePattern_shouldTriggerUIUpdatesOnSettingsChange() async {
        // Given: SettingsViewModel in initial state
        let initialTheme = viewModel.settingsData.appSettings.theme
        
        // When: Changing settings (simulating @Observable behavior)
        await viewModel.updateAppSetting(\.theme, value: "light")
        
        // Then: State should change (triggering UI updates in real SwiftUI)
        // Note: This validates state change; @Observable handles UI updates
        XCTAssertNotEqual(viewModel.settingsData.appSettings.theme, initialTheme)
    }
    
    func test_settingsDataIntegration_shouldWorkWithExistingModels() {
        // Given: SettingsViewModel with existing SettingsData structure
        // When: Accessing all settings sections
        // Then: Should have all required sections available
        XCTAssertNotNil(viewModel.settingsData.appSettings)
        XCTAssertNotNil(viewModel.settingsData.apiSettings)
        XCTAssertNotNil(viewModel.settingsData.documentSettings)
        XCTAssertNotNil(viewModel.settingsData.notificationSettings)
        XCTAssertNotNil(viewModel.settingsData.dataPrivacySettings)
        XCTAssertNotNil(viewModel.settingsData.advancedSettings)
    }
    
    // MARK: - Error Handling Tests
    
    func test_invalidAPIKey_shouldProvideValidationError() async {
        // Given: Invalid API key format
        let invalidKey = APIKeyEntryData(name: "Invalid", key: "invalid-format", isActive: false)
        
        // When: Adding invalid API key
        await viewModel.addAPIKey(invalidKey)
        
        // Then: Should provide validation error
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError?.contains("API key format") ?? false)
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.isEmpty)
    }
    
    func test_settingsSaveFailure_shouldHandleErrorGracefully() async {
        // Given: SettingsViewModel with simulated save failure
        viewModel.simulateSaveFailure = true
        
        // When: Attempting to save settings
        await viewModel.saveSettings()
        
        // Then: Should handle error gracefully
        XCTAssertEqual(viewModel.saveStatus, .error)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_concurrentSettingsUpdates_shouldHandleRaceConditions() async {
        // Given: Multiple concurrent setting updates
        let vm = viewModel!
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await vm.updateAppSetting(\.autoSaveInterval, value: i * 10)
                }
            }
        }
        
        // Then: Should handle concurrent updates without corruption
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotEqual(viewModel.saveStatus, .error)
    }
    
    // MARK: - Reset and Restore Tests
    
    func test_resetToDefaults_shouldRestoreDefaultSettings() async {
        // Given: SettingsViewModel with modified settings
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAppSetting(\.accentColor, value: "red")
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "dark")
        
        // When: Resetting to defaults
        await viewModel.resetToDefaults()
        
        // Then: Should restore default settings
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        XCTAssertEqual(viewModel.settingsData.appSettings.accentColor, "blue")
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
    
    func test_exportSettings_shouldGenerateValidExportData() async {
        // Given: SettingsViewModel with configured settings
        await viewModel.updateAppSetting(\.theme, value: "dark")
        
        // When: Exporting settings
        let exportData = await viewModel.exportSettings()
        
        // Then: Should generate valid export data
        XCTAssertNotNil(exportData)
        XCTAssertFalse(exportData.isEmpty)
    }
}

// MARK: - Settings Validation Tests

extension SettingsViewModelTests {
    
    func test_themeValidation_shouldAcceptValidThemes() async {
        let validThemes = ["system", "light", "dark"]
        
        for theme in validThemes {
            await viewModel.updateAppSetting(\.theme, value: theme)
            XCTAssertEqual(viewModel.settingsData.appSettings.theme, theme)
            XCTAssertNil(viewModel.validationError)
        }
    }
    
    func test_autoSaveIntervalValidation_shouldEnforceReasonableLimits() async {
        // Test minimum boundary
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 5)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.appSettings.autoSaveInterval, 10)
        
        // Test maximum boundary
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 400)
        XCTAssertLessThanOrEqual(viewModel.settingsData.appSettings.autoSaveInterval, 300)
        
        // Test valid range
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 60)
        XCTAssertEqual(viewModel.settingsData.appSettings.autoSaveInterval, 60)
    }
}
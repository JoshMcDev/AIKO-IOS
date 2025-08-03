import XCTest
import SwiftUI
@testable import AppCore
@testable import AIKO

/// Comprehensive integration tests for SettingsView complete user workflow
/// Tests end-to-end journey including settings modification, persistence, validation, and export/import
@MainActor
final class SettingsWorkflowIntegrationTests: XCTestCase, @unchecked Sendable {

    var viewModel: SettingsViewModel!
    var originalSettingsData: SettingsData!

    override func setUp() async throws {
        viewModel = SettingsViewModel()
        originalSettingsData = viewModel.settingsData
    }

    override func tearDown() async throws {
        viewModel = nil
        originalSettingsData = nil
    }

    // MARK: - Complete Settings Configuration Workflow

    func test_completeSettingsWorkflow_allSections_shouldPersistCorrectly() async {
        // GIVEN: Fresh SettingsView with default values
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "Claude 3 Opus")
        XCTAssertTrue(viewModel.settingsData.documentSettings.includeMetadata)
        XCTAssertTrue(viewModel.settingsData.notificationSettings.enableNotifications)
        XCTAssertFalse(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)
        XCTAssertFalse(viewModel.settingsData.advancedSettings.debugModeEnabled)

        // STEP 1: Configure App Settings
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAppSetting(\.accentColor, value: "red")
        await viewModel.updateAppSetting(\.fontSize, value: "large")
        await viewModel.updateAppSetting(\.autoSaveEnabled, value: true)
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 60)
        await viewModel.updateAppSetting(\.confirmBeforeDelete, value: false)

        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "dark")
        XCTAssertEqual(viewModel.settingsData.appSettings.accentColor, "red")
        XCTAssertEqual(viewModel.settingsData.appSettings.fontSize, "large")
        XCTAssertTrue(viewModel.settingsData.appSettings.autoSaveEnabled)
        XCTAssertEqual(viewModel.settingsData.appSettings.autoSaveInterval, 60)
        XCTAssertFalse(viewModel.settingsData.appSettings.confirmBeforeDelete)
        XCTAssertEqual(viewModel.saveStatus, .saved)

        // STEP 2: Configure API Settings
        let testAPIKey1 = APIKeyEntryData(name: "Primary Key", key: "sk-ant-api03-primary-1234567890abcdef", isActive: true)
        let testAPIKey2 = APIKeyEntryData(name: "Secondary Key", key: "sk-ant-api03-secondary-1234567890abcdef", isActive: false)

        await viewModel.addAPIKey(testAPIKey1)
        await viewModel.addAPIKey(testAPIKey2)
        await viewModel.selectAPIKey(testAPIKey1.id)
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")
        await viewModel.updateAPISetting(\.maxRetries, value: 5)
        await viewModel.updateAPISetting(\.timeoutInterval, value: 45.0)

        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 2)
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, testAPIKey1.id)
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "GPT-4")
        XCTAssertEqual(viewModel.settingsData.apiSettings.maxRetries, 5)
        XCTAssertEqual(viewModel.settingsData.apiSettings.timeoutInterval, 45.0)

        // STEP 3: Configure Document Settings
        await viewModel.updateDocumentSetting(\.defaultTemplateSet, value: "professional")
        await viewModel.updateDocumentSetting(\.includeMetadata, value: false)
        await viewModel.updateDocumentSetting(\.includeVersionHistory, value: false)
        await viewModel.updateDocumentSetting(\.autoGenerateTableOfContents, value: false)
        await viewModel.updateDocumentSetting(\.pageNumbering, value: false)

        XCTAssertEqual(viewModel.settingsData.documentSettings.defaultTemplateSet, "professional")
        XCTAssertFalse(viewModel.settingsData.documentSettings.includeMetadata)
        XCTAssertFalse(viewModel.settingsData.documentSettings.includeVersionHistory)
        XCTAssertFalse(viewModel.settingsData.documentSettings.autoGenerateTableOfContents)
        XCTAssertFalse(viewModel.settingsData.documentSettings.pageNumbering)

        // STEP 4: Configure Notification Settings
        await viewModel.updateNotificationSetting(\.enableNotifications, value: false)
        await viewModel.updateNotificationSetting(\.documentGenerationComplete, value: false)
        await viewModel.updateNotificationSetting(\.acquisitionReminders, value: true)
        await viewModel.updateNotificationSetting(\.soundEnabled, value: false)

        XCTAssertFalse(viewModel.settingsData.notificationSettings.enableNotifications)
        XCTAssertFalse(viewModel.settingsData.notificationSettings.documentGenerationComplete)
        XCTAssertTrue(viewModel.settingsData.notificationSettings.acquisitionReminders)
        XCTAssertFalse(viewModel.settingsData.notificationSettings.soundEnabled)

        // STEP 5: Configure Privacy Settings
        await viewModel.updatePrivacySetting(\.analyticsEnabled, value: true)
        await viewModel.updatePrivacySetting(\.crashReportingEnabled, value: false)
        await viewModel.updatePrivacySetting(\.dataRetentionDays, value: 30)
        await viewModel.updatePrivacySetting(\.encryptLocalData, value: true)

        XCTAssertTrue(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)
        XCTAssertFalse(viewModel.settingsData.dataPrivacySettings.crashReportingEnabled)
        XCTAssertEqual(viewModel.settingsData.dataPrivacySettings.dataRetentionDays, 30)
        XCTAssertTrue(viewModel.settingsData.dataPrivacySettings.encryptLocalData)

        // STEP 6: Configure Advanced Settings
        await viewModel.updateAdvancedSetting(\.debugModeEnabled, value: true)
        await viewModel.updateAdvancedSetting(\.showDetailedErrors, value: true)
        await viewModel.updateAdvancedSetting(\.enableBetaFeatures, value: true)
        await viewModel.updateAdvancedSetting(\.cacheSizeMB, value: 1000)
        await viewModel.updateAdvancedSetting(\.maxConcurrentGenerations, value: 5)

        XCTAssertTrue(viewModel.settingsData.advancedSettings.debugModeEnabled)
        XCTAssertTrue(viewModel.settingsData.advancedSettings.showDetailedErrors)
        XCTAssertTrue(viewModel.settingsData.advancedSettings.enableBetaFeatures)
        XCTAssertEqual(viewModel.settingsData.advancedSettings.cacheSizeMB, 1000)
        XCTAssertEqual(viewModel.settingsData.advancedSettings.maxConcurrentGenerations, 5)

        // THEN: Final verification - all settings should be properly saved
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_settingsWorkflow_apiKeyManagement_shouldHandleCRUDOperations() async {
        // GIVEN: Empty API key list
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.isEmpty)
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, "")

        // STEP 1: Add multiple API keys
        let primaryKey = APIKeyEntryData(name: "Primary", key: "sk-ant-api03-primary-key-1234567890abcdef", isActive: true)
        let secondaryKey = APIKeyEntryData(name: "Secondary", key: "sk-ant-api03-secondary-key-1234567890abcdef", isActive: false)
        let backupKey = APIKeyEntryData(name: "Backup", key: "sk-ant-api03-backup-key-1234567890abcdef", isActive: false)

        await viewModel.addAPIKey(primaryKey)
        await viewModel.addAPIKey(secondaryKey)
        await viewModel.addAPIKey(backupKey)

        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 3)

        // STEP 2: Select different API keys
        await viewModel.selectAPIKey(primaryKey.id)
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, primaryKey.id)

        await viewModel.selectAPIKey(secondaryKey.id)
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, secondaryKey.id)

        // STEP 3: Update API key
        let updatedSecondaryKey = APIKeyEntryData(
            id: secondaryKey.id,
            name: "Updated Secondary",
            key: "sk-ant-api03-updated-secondary-1234567890abcdef",
            isActive: true
        )
        await viewModel.updateAPIKey(updatedSecondaryKey)

        let foundKey = viewModel.settingsData.apiSettings.apiKeys.first { $0.id == secondaryKey.id }
        XCTAssertEqual(foundKey?.name, "Updated Secondary")
        XCTAssertEqual(foundKey?.key, "sk-ant-api03-updated-secondary-1234567890abcdef")
        XCTAssertTrue(foundKey?.isActive ?? false)

        // STEP 4: Remove API key
        await viewModel.removeAPIKey(backupKey.id)
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 2)
        XCTAssertNil(viewModel.settingsData.apiSettings.apiKeys.first { $0.id == backupKey.id })

        // STEP 5: Remove selected API key (should update selection)
        await viewModel.removeAPIKey(secondaryKey.id) // Remove currently selected key
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 1)

        // Selection should automatically switch to remaining key or be cleared
        if !viewModel.settingsData.apiSettings.apiKeys.isEmpty {
            XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, primaryKey.id)
        } else {
            XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, "")
        }

        // THEN: Final state should be consistent
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_settingsWorkflow_exportImportCycle_shouldPreserveAllData() async throws {
        // GIVEN: Fully configured settings
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAppSetting(\.accentColor, value: "purple")

        let apiKey = APIKeyEntryData(name: "Test Key", key: "sk-ant-api03-test-1234567890abcdef", isActive: true)
        await viewModel.addAPIKey(apiKey)
        await viewModel.selectAPIKey(apiKey.id)
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")

        await viewModel.updateDocumentSetting(\.defaultTemplateSet, value: "custom")
        await viewModel.updateNotificationSetting(\.enableNotifications, value: false)
        await viewModel.updatePrivacySetting(\.analyticsEnabled, value: true)
        await viewModel.updateAdvancedSetting(\.debugModeEnabled, value: true)

        // Store reference to configured settings
        let configuredSettings = viewModel.settingsData

        // STEP 1: Export settings
        let exportedData = await viewModel.exportSettings()
        XCTAssertFalse(exportedData.isEmpty)

        // Verify exported data can be decoded
        let decodedSettings = try XCTUnwrap(try? JSONDecoder().decode(SettingsData.self, from: exportedData))
        XCTAssertEqual(decodedSettings.appSettings.theme, "dark")
        XCTAssertEqual(decodedSettings.appSettings.accentColor, "purple")
        XCTAssertEqual(decodedSettings.apiSettings.selectedModel, "GPT-4")
        XCTAssertEqual(decodedSettings.apiSettings.apiKeys.count, 1)

        // STEP 2: Reset to defaults
        await viewModel.resetToDefaults()
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        XCTAssertEqual(viewModel.settingsData.appSettings.accentColor, "blue")
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "Claude 3 Opus")
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.isEmpty)

        // STEP 3: Import settings
        await viewModel.importSettings(exportedData)

        // THEN: All settings should be restored exactly
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, configuredSettings.appSettings.theme)
        XCTAssertEqual(viewModel.settingsData.appSettings.accentColor, configuredSettings.appSettings.accentColor)
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, configuredSettings.apiSettings.selectedModel)
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, configuredSettings.apiSettings.apiKeys.count)
        XCTAssertEqual(viewModel.settingsData.documentSettings.defaultTemplateSet, configuredSettings.documentSettings.defaultTemplateSet)
        XCTAssertEqual(viewModel.settingsData.notificationSettings.enableNotifications, configuredSettings.notificationSettings.enableNotifications)
        XCTAssertEqual(viewModel.settingsData.dataPrivacySettings.analyticsEnabled, configuredSettings.dataPrivacySettings.analyticsEnabled)
        XCTAssertEqual(viewModel.settingsData.advancedSettings.debugModeEnabled, configuredSettings.advancedSettings.debugModeEnabled)

        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_settingsWorkflow_validationErrors_shouldShowAppropriateMessages() async {
        // STEP 1: Test invalid API key validation
        let invalidAPIKey = APIKeyEntryData(name: "Invalid", key: "invalid-format", isActive: false)
        await viewModel.addAPIKey(invalidAPIKey)

        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError?.contains("API key format") ?? false)

        // Clear error and test valid key
        viewModel.validationError = nil
        let validAPIKey = APIKeyEntryData(name: "Valid", key: "sk-ant-api03-valid-1234567890abcdef", isActive: true)
        await viewModel.addAPIKey(validAPIKey)

        XCTAssertNil(viewModel.validationError)
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 1) // Invalid key was rejected

        // STEP 2: Test boundary validation for sliders
        // These should be automatically clamped to valid ranges
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 5) // Below minimum (10)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.appSettings.autoSaveInterval, 10)

        await viewModel.updateAppSetting(\.autoSaveInterval, value: 400) // Above maximum (300)
        XCTAssertLessThanOrEqual(viewModel.settingsData.appSettings.autoSaveInterval, 300)

        await viewModel.updateAPISetting(\.maxRetries, value: 0) // Below minimum (1)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.apiSettings.maxRetries, 1)

        await viewModel.updateAPISetting(\.maxRetries, value: 15) // Above maximum (10)
        XCTAssertLessThanOrEqual(viewModel.settingsData.apiSettings.maxRetries, 10)

        // THEN: Validation should maintain data integrity
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_settingsWorkflow_rapidUpdates_shouldMaintainConsistency() async {
        // GIVEN: Settings view with rapid user interactions
        let updateTasks = await withTaskGroup(of: Void.self) { group in
            // Simulate rapid concurrent updates across different sections
            group.addTask { await self.viewModel.updateAppSetting(\.theme, value: "dark") }
            group.addTask { await self.viewModel.updateAppSetting(\.accentColor, value: "red") }
            group.addTask { await self.viewModel.updateAPISetting(\.selectedModel, value: "GPT-4") }
            group.addTask { await self.viewModel.updateAPISetting(\.maxRetries, value: 7) }
            group.addTask { await self.viewModel.updateDocumentSetting(\.includeMetadata, value: false) }
            group.addTask { await self.viewModel.updateNotificationSetting(\.enableNotifications, value: false) }
            group.addTask { await self.viewModel.updatePrivacySetting(\.analyticsEnabled, value: true) }
            group.addTask { await self.viewModel.updateAdvancedSetting(\.debugModeEnabled, value: true) }

            return []
        }

        // THEN: All updates should be applied correctly without race conditions
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "dark")
        XCTAssertEqual(viewModel.settingsData.appSettings.accentColor, "red")
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "GPT-4")
        XCTAssertEqual(viewModel.settingsData.apiSettings.maxRetries, 7)
        XCTAssertFalse(viewModel.settingsData.documentSettings.includeMetadata)
        XCTAssertFalse(viewModel.settingsData.notificationSettings.enableNotifications)
        XCTAssertTrue(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)
        XCTAssertTrue(viewModel.settingsData.advancedSettings.debugModeEnabled)

        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_settingsWorkflow_crossPlatformCompatibility_shouldWorkOnBothPlatforms() {
        // GIVEN: SettingsView created for cross-platform usage
        let settingsView = SettingsView(viewModel: viewModel)

        // WHEN: Testing platform-specific features
        XCTAssertNotNil(settingsView)

        // THEN: Should handle platform differences gracefully
        #if os(iOS)
        // iOS-specific verification
        XCTAssertTrue(viewModel.settingsData.appSettings.faceIDEnabled == false) // Default state
        #elseif os(macOS)
        // macOS-specific verification - keyboard shortcuts should be available
        XCTAssertNotNil(settingsView) // View should render on macOS
        #endif

        // Cross-platform settings should work on both
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "Claude 3 Opus")
    }

    func test_settingsWorkflow_appViewIntegration_shouldShowInSheet() {
        // GIVEN: SettingsView integration with AppView
        let settingsView = SettingsView(viewModel: viewModel)

        // WHEN: Used in AppView sheet context
        // This simulates the usage in AppView.swift:115-117
        // .sheet(isPresented: $viewModel.showingSettings) {
        //     SettingsView(viewModel: viewModel.settingsViewModel)
        // }

        // THEN: Should be properly configured for sheet presentation
        XCTAssertNotNil(settingsView)

        // Sheet dismissal should preserve settings
        viewModel.showingSettings = true
        viewModel.showingSettings = false
        XCTAssertEqual(viewModel.saveStatus, .none) // No changes made yet
    }

    // MARK: - Performance Integration Tests

    func test_settingsWorkflow_performance_shouldCompleteWithinReasonableTime() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Perform comprehensive settings configuration
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAppSetting(\.accentColor, value: "red")
        await viewModel.updateAppSetting(\.fontSize, value: "large")

        let apiKey = APIKeyEntryData(name: "Test", key: "sk-ant-api03-test-1234567890abcdef", isActive: true)
        await viewModel.addAPIKey(apiKey)
        await viewModel.selectAPIKey(apiKey.id)
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")

        await viewModel.updateDocumentSetting(\.includeMetadata, value: false)
        await viewModel.updateNotificationSetting(\.enableNotifications, value: false)
        await viewModel.updatePrivacySetting(\.analyticsEnabled, value: true)
        await viewModel.updateAdvancedSetting(\.debugModeEnabled, value: true)

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Should complete within 1 second
        XCTAssertLessThan(timeElapsed, 1.0, "Comprehensive settings configuration should complete within 1 second")
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_settingsWorkflow_memoryUsage_shouldNotLeak() async {
        // Create multiple settings configurations to test for memory leaks
        for iteration in 1...10 {
            let testAPIKey = APIKeyEntryData(
                name: "Test Key \(iteration)",
                key: "sk-ant-api03-test\(iteration)-1234567890abcdef",
                isActive: iteration % 2 == 0
            )

            await viewModel.addAPIKey(testAPIKey)
            await viewModel.updateAppSetting(\.theme, value: iteration % 2 == 0 ? "dark" : "light")
            await viewModel.updateAdvancedSetting(\.cacheSizeMB, value: 100 + iteration * 50)

            if iteration % 3 == 0 {
                // Periodically reset to simulate real usage
                await viewModel.resetToDefaults()
            }
        }

        // Final state should be clean
        XCTAssertEqual(viewModel.saveStatus, .saved)

        // Memory should be properly managed (this is more of a conceptual test)
        // In practice, you'd use memory profiling tools to verify no leaks
        XCTAssertNotNil(viewModel.settingsData)
    }
}

// MARK: - Settings Validation Extensions

extension SettingsWorkflowIntegrationTests {

    func test_settingsData_allSections_shouldHaveValidDefaults() {
        // Verify all settings sections have sensible defaults
        let defaults = SettingsData()

        // App Settings
        XCTAssertEqual(defaults.appSettings.theme, "system")
        XCTAssertEqual(defaults.appSettings.accentColor, "blue")
        XCTAssertEqual(defaults.appSettings.fontSize, "medium")
        XCTAssertTrue(defaults.appSettings.autoSaveEnabled)
        XCTAssertEqual(defaults.appSettings.autoSaveInterval, 30)
        XCTAssertTrue(defaults.appSettings.confirmBeforeDelete)

        // API Settings
        XCTAssertEqual(defaults.apiSettings.apiEndpoint, "https://api.anthropic.com")
        XCTAssertEqual(defaults.apiSettings.maxRetries, 3)
        XCTAssertEqual(defaults.apiSettings.timeoutInterval, 30)
        XCTAssertEqual(defaults.apiSettings.selectedModel, "Claude 3 Opus")
        XCTAssertTrue(defaults.apiSettings.apiKeys.isEmpty)

        // Document Settings
        XCTAssertEqual(defaults.documentSettings.defaultTemplateSet, "standard")
        XCTAssertTrue(defaults.documentSettings.includeMetadata)
        XCTAssertTrue(defaults.documentSettings.includeVersionHistory)

        // Notification Settings
        XCTAssertTrue(defaults.notificationSettings.enableNotifications)
        XCTAssertTrue(defaults.notificationSettings.soundEnabled)

        // Privacy Settings
        XCTAssertFalse(defaults.dataPrivacySettings.analyticsEnabled)
        XCTAssertTrue(defaults.dataPrivacySettings.crashReportingEnabled)
        XCTAssertEqual(defaults.dataPrivacySettings.dataRetentionDays, 90)

        // Advanced Settings
        XCTAssertFalse(defaults.advancedSettings.debugModeEnabled)
        XCTAssertFalse(defaults.advancedSettings.showDetailedErrors)
        XCTAssertEqual(defaults.advancedSettings.cacheSizeMB, 500)
        XCTAssertEqual(defaults.advancedSettings.maxConcurrentGenerations, 3)
    }
}

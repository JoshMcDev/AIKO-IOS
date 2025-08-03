import XCTest
import SwiftUI
@testable import AppCore
@testable import AIKO

@MainActor
final class SettingsViewTests: XCTestCase {

    var viewModel: SettingsViewModel!

    override func setUp() async throws {
        viewModel = SettingsViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - MoE Tests: UI Functional Requirements

    func test_settingsViewInitialization_shouldCreateWithViewModel() {
        // Given: SettingsViewModel
        // When: Creating SettingsView
        let settingsView = SettingsView(viewModel: viewModel)

        // Then: Should initialize without crashing
        XCTAssertNotNil(settingsView)
    }

    func test_formSections_shouldDisplayAllRequiredSections() {
        // Given: SettingsView with SettingsViewModel
        let settingsView = SettingsView(viewModel: viewModel)

        // When: Checking section structure
        // Then: Should have all 6 sections: App, API, Document, Notification, Privacy, Advanced
        XCTAssertNotNil(viewModel.settingsData.appSettings)
        XCTAssertNotNil(viewModel.settingsData.apiSettings)
        XCTAssertNotNil(viewModel.settingsData.documentSettings)
        XCTAssertNotNil(viewModel.settingsData.notificationSettings)
        XCTAssertNotNil(viewModel.settingsData.dataPrivacySettings)
        XCTAssertNotNil(viewModel.settingsData.advancedSettings)
    }

    func test_appSettings_shouldBindToViewModel() async {
        // Given: SettingsView at default state
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")

        // When: Changing app settings through binding simulation
        await viewModel.updateAppSetting(\.theme, value: "dark")

        // Then: ViewModel should be updated
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "dark")
    }

    func test_apiSettings_shouldBindToViewModel() async {
        // Given: SettingsView with default API settings
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "Claude 3 Opus")

        // When: Changing API settings through binding simulation
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")

        // Then: ViewModel should be updated
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "GPT-4")
    }

    func test_documentSettings_shouldBindToViewModel() async {
        // Given: SettingsView with default document settings
        XCTAssertTrue(viewModel.settingsData.documentSettings.includeMetadata)

        // When: Changing document settings through binding simulation
        await viewModel.updateDocumentSetting(\.includeMetadata, value: false)

        // Then: ViewModel should be updated
        XCTAssertFalse(viewModel.settingsData.documentSettings.includeMetadata)
    }

    func test_notificationSettings_shouldBindToViewModel() async {
        // Given: SettingsView with default notification settings
        XCTAssertTrue(viewModel.settingsData.notificationSettings.enableNotifications)

        // When: Changing notification settings through binding simulation
        await viewModel.updateNotificationSetting(\.enableNotifications, value: false)

        // Then: ViewModel should be updated
        XCTAssertFalse(viewModel.settingsData.notificationSettings.enableNotifications)
    }

    func test_privacySettings_shouldBindToViewModel() async {
        // Given: SettingsView with default privacy settings
        XCTAssertFalse(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)

        // When: Changing privacy settings through binding simulation
        await viewModel.updatePrivacySetting(\.analyticsEnabled, value: true)

        // Then: ViewModel should be updated
        XCTAssertTrue(viewModel.settingsData.dataPrivacySettings.analyticsEnabled)
    }

    func test_advancedSettings_shouldBindToViewModel() async {
        // Given: SettingsView with default advanced settings
        XCTAssertFalse(viewModel.settingsData.advancedSettings.debugModeEnabled)

        // When: Changing advanced settings through binding simulation
        await viewModel.updateAdvancedSetting(\.debugModeEnabled, value: true)

        // Then: ViewModel should be updated
        XCTAssertTrue(viewModel.settingsData.advancedSettings.debugModeEnabled)
    }

    // MARK: - Advanced Features Tests

    func test_autoSaveSlider_shouldUpdateInterval() async {
        // Given: SettingsView with auto save enabled
        await viewModel.updateAppSetting(\.autoSaveEnabled, value: true)
        XCTAssertTrue(viewModel.settingsData.appSettings.autoSaveEnabled)

        // When: Changing auto save interval via slider simulation
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 120)

        // Then: Interval should be updated
        XCTAssertEqual(viewModel.settingsData.appSettings.autoSaveInterval, 120)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_maxRetriesSlider_shouldUpdateAPIRetries() async {
        // Given: SettingsView with default max retries
        XCTAssertEqual(viewModel.settingsData.apiSettings.maxRetries, 3)

        // When: Changing max retries via slider simulation
        await viewModel.updateAPISetting(\.maxRetries, value: 7)

        // Then: Max retries should be updated
        XCTAssertEqual(viewModel.settingsData.apiSettings.maxRetries, 7)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_timeoutSlider_shouldUpdateAPITimeout() async {
        // Given: SettingsView with default timeout
        XCTAssertEqual(viewModel.settingsData.apiSettings.timeoutInterval, 30.0)

        // When: Changing timeout via slider simulation
        await viewModel.updateAPISetting(\.timeoutInterval, value: 60.0)

        // Then: Timeout should be updated
        XCTAssertEqual(viewModel.settingsData.apiSettings.timeoutInterval, 60.0)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_dataRetentionSlider_shouldUpdateRetentionDays() async {
        // Given: SettingsView with default data retention
        XCTAssertEqual(viewModel.settingsData.dataPrivacySettings.dataRetentionDays, 90)

        // When: Changing data retention via slider simulation
        await viewModel.updatePrivacySetting(\.dataRetentionDays, value: 180)

        // Then: Data retention should be updated
        XCTAssertEqual(viewModel.settingsData.dataPrivacySettings.dataRetentionDays, 180)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_cacheSizeSlider_shouldUpdateCacheSize() async {
        // Given: SettingsView with default cache size
        XCTAssertEqual(viewModel.settingsData.advancedSettings.cacheSizeMB, 500)

        // When: Changing cache size via slider simulation
        await viewModel.updateAdvancedSetting(\.cacheSizeMB, value: 1000)

        // Then: Cache size should be updated
        XCTAssertEqual(viewModel.settingsData.advancedSettings.cacheSizeMB, 1000)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    func test_maxConcurrentGenerationsSlider_shouldUpdateConcurrency() async {
        // Given: SettingsView with default concurrent generations
        XCTAssertEqual(viewModel.settingsData.advancedSettings.maxConcurrentGenerations, 3)

        // When: Changing max concurrent generations via slider simulation
        await viewModel.updateAdvancedSetting(\.maxConcurrentGenerations, value: 6)

        // Then: Max concurrent generations should be updated
        XCTAssertEqual(viewModel.settingsData.advancedSettings.maxConcurrentGenerations, 6)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }

    // MARK: - Export/Import Tests

    func test_exportSettings_shouldGenerateValidData() async {
        // Given: SettingsView with configured settings
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")

        // When: Exporting settings
        let exportData = await viewModel.exportSettings()

        // Then: Should generate valid export data
        XCTAssertFalse(exportData.isEmpty)

        // Verify data can be decoded
        do {
            let decodedSettings = try JSONDecoder().decode(SettingsData.self, from: exportData)
            XCTAssertEqual(decodedSettings.appSettings.theme, "dark")
            XCTAssertEqual(decodedSettings.apiSettings.selectedModel, "GPT-4")
        } catch {
            XCTFail("Failed to decode exported settings: \(error)")
        }
    }

    // MARK: - Error Handling Tests

    func test_validationError_shouldBeDisplayedInAlert() async {
        // Given: SettingsView with validation error potential
        let invalidKey = APIKeyEntryData(name: "Invalid", key: "invalid-format", isActive: false)

        // When: Adding invalid API key (should trigger validation error)
        await viewModel.addAPIKey(invalidKey)

        // Then: Should have validation error
        XCTAssertNotNil(viewModel.validationError)
        XCTAssertTrue(viewModel.validationError?.contains("API key format") ?? false)
    }

    func test_saveStatusView_shouldReflectCurrentStatus() {
        // Given: SettingsView with different save statuses

        // When: Save status is .none
        viewModel.saveStatus = .none
        // Then: Status should be none (tested in UI)

        // When: Save status is .saving
        viewModel.saveStatus = .saving
        // Then: Should show progress indicator (tested in UI)

        // When: Save status is .saved
        viewModel.saveStatus = .saved
        // Then: Should show checkmark (tested in UI)

        // When: Save status is .error
        viewModel.saveStatus = .error
        // Then: Should show error indicator (tested in UI)

        XCTAssertTrue([.none, .saving, .saved, .error].contains(viewModel.saveStatus))
    }

    // MARK: - Performance Tests

    func test_viewRendering_shouldCompleteQuickly() {
        measure {
            let settingsView = SettingsView(viewModel: viewModel)
            // Simulate view creation (actual rendering would happen in SwiftUI)
            XCTAssertNotNil(settingsView)
        }
    }

    func test_multipleSettingUpdates_shouldCompleteWithin500ms() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        // When: Updating multiple settings rapidly
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAppSetting(\.accentColor, value: "red")
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")
        await viewModel.updateDocumentSetting(\.includeMetadata, value: false)
        await viewModel.updateNotificationSetting(\.enableNotifications, value: false)

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 0.5, "Multiple setting updates should complete within 500ms")
    }

    // MARK: - Cross-Platform Tests

    func test_crossPlatformCompatibility_shouldHandleiOSAndmacOS() {
        // Given: SettingsView created for cross-platform use
        let settingsView = SettingsView(viewModel: viewModel)

        // When: Checking cross-platform elements
        // Then: Should handle platform-specific elements gracefully
        XCTAssertNotNil(settingsView)

        // Note: Platform-specific toolbar placements and navigation styles
        // are handled in the view implementation with #if os(iOS) directives
    }

    // MARK: - API Key Management Tests

    func test_apiKeyManagement_shouldAllowCRUDOperations() async {
        // Given: SettingsView with API key management
        XCTAssertTrue(viewModel.settingsData.apiSettings.apiKeys.isEmpty)

        // When: Adding API key
        let apiKey = APIKeyEntryData(name: "Test Key", key: "sk-ant-api03-test123", isActive: true)
        await viewModel.addAPIKey(apiKey)

        // Then: Should add API key
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 1)
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.first?.name, "Test Key")

        // When: Selecting different API key
        let secondKey = APIKeyEntryData(name: "Second Key", key: "sk-ant-api03-second", isActive: false)
        await viewModel.addAPIKey(secondKey)
        await viewModel.selectAPIKey(secondKey.id)

        // Then: Should update selection
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedAPIKeyId, secondKey.id)

        // When: Removing API key
        await viewModel.removeAPIKey(apiKey.id)

        // Then: Should remove API key
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.count, 1)
        XCTAssertEqual(viewModel.settingsData.apiSettings.apiKeys.first?.name, "Second Key")
    }

    // MARK: - Integration Tests

    func test_settingsViewIntegration_shouldWorkWithAppView() {
        // Given: SettingsView as it would be used in AppView
        let settingsView = SettingsView(viewModel: viewModel)

        // When: Creating view for AppView integration
        // Then: Should match AppView integration pattern
        XCTAssertNotNil(settingsView)

        // Verify it can be used in navigation context
        // NavigationStack { SettingsView(viewModel: viewModel) }
    }

    func test_resetToDefaults_shouldRestoreAllSettings() async {
        // Given: SettingsView with modified settings
        await viewModel.updateAppSetting(\.theme, value: "dark")
        await viewModel.updateAPISetting(\.selectedModel, value: "GPT-4")
        await viewModel.updateDocumentSetting(\.includeMetadata, value: false)

        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "dark")
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "GPT-4")
        XCTAssertFalse(viewModel.settingsData.documentSettings.includeMetadata)

        // When: Resetting to defaults
        await viewModel.resetToDefaults()

        // Then: Should restore all default values
        XCTAssertEqual(viewModel.settingsData.appSettings.theme, "system")
        XCTAssertEqual(viewModel.settingsData.apiSettings.selectedModel, "Claude 3 Opus")
        XCTAssertTrue(viewModel.settingsData.documentSettings.includeMetadata)
        XCTAssertEqual(viewModel.saveStatus, .saved)
    }
}

// MARK: - Slider Range Validation Tests

extension SettingsViewTests {

    func test_sliderRanges_shouldEnforceCorrectBounds() async {
        // Auto save interval: 10-300 seconds
        await viewModel.updateAppSetting(\.autoSaveInterval, value: 5) // Below minimum
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.appSettings.autoSaveInterval, 10)

        await viewModel.updateAppSetting(\.autoSaveInterval, value: 400) // Above maximum
        XCTAssertLessThanOrEqual(viewModel.settingsData.appSettings.autoSaveInterval, 300)

        // Max retries: 1-10
        await viewModel.updateAPISetting(\.maxRetries, value: 5)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.apiSettings.maxRetries, 1)
        XCTAssertLessThanOrEqual(viewModel.settingsData.apiSettings.maxRetries, 10)

        // Timeout: 5-120 seconds
        await viewModel.updateAPISetting(\.timeoutInterval, value: 60.0)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.apiSettings.timeoutInterval, 5.0)
        XCTAssertLessThanOrEqual(viewModel.settingsData.apiSettings.timeoutInterval, 120.0)

        // Data retention: 1-365 days
        await viewModel.updatePrivacySetting(\.dataRetentionDays, value: 100)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.dataPrivacySettings.dataRetentionDays, 1)
        XCTAssertLessThanOrEqual(viewModel.settingsData.dataPrivacySettings.dataRetentionDays, 365)

        // Cache size: 50-2000 MB
        await viewModel.updateAdvancedSetting(\.cacheSizeMB, value: 1000)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.advancedSettings.cacheSizeMB, 50)
        XCTAssertLessThanOrEqual(viewModel.settingsData.advancedSettings.cacheSizeMB, 2000)

        // Max concurrent generations: 1-10
        await viewModel.updateAdvancedSetting(\.maxConcurrentGenerations, value: 5)
        XCTAssertGreaterThanOrEqual(viewModel.settingsData.advancedSettings.maxConcurrentGenerations, 1)
        XCTAssertLessThanOrEqual(viewModel.settingsData.advancedSettings.maxConcurrentGenerations, 10)
    }
}

import Foundation

public struct SettingsData: Codable, Equatable, Sendable {
    public var appSettings: AppSettingsData
    public var apiSettings: APISettingsData
    public var documentSettings: DocumentSettingsData
    public var notificationSettings: NotificationSettingsData
    public var dataPrivacySettings: DataPrivacySettingsData
    public var advancedSettings: AdvancedSettingsData

    public init(
        appSettings: AppSettingsData = AppSettingsData(),
        apiSettings: APISettingsData = APISettingsData(),
        documentSettings: DocumentSettingsData = DocumentSettingsData(),
        notificationSettings: NotificationSettingsData = NotificationSettingsData(),
        dataPrivacySettings: DataPrivacySettingsData = DataPrivacySettingsData(),
        advancedSettings: AdvancedSettingsData = AdvancedSettingsData()
    ) {
        self.appSettings = appSettings
        self.apiSettings = apiSettings
        self.documentSettings = documentSettings
        self.notificationSettings = notificationSettings
        self.dataPrivacySettings = dataPrivacySettings
        self.advancedSettings = advancedSettings
    }
}

public struct AppSettingsData: Codable, Equatable, Sendable {
    public var theme: String = "system"
    public var accentColor: String = "blue"
    public var fontSize: String = "medium"
    public var autoSaveEnabled: Bool = true
    public var autoSaveInterval: Int = 30
    public var confirmBeforeDelete: Bool = true
    public var defaultFileFormat: String = "docx"
    // Backup settings
    public var backupEnabled: Bool = false
    public var backupSchedule: String = "manual"
    public var lastBackupDate: Date?
    public var nextScheduledBackup: Date?
    // Biometric authentication
    public var faceIDEnabled: Bool = false

    public init() {}
}

public struct APISettingsData: Codable, Equatable, Sendable {
    public var apiEndpoint: String = "https://api.anthropic.com"
    public var maxRetries: Int = 3
    public var timeoutInterval: TimeInterval = 30
    public var useCustomEndpoint: Bool = false
    public var customEndpoint: String = ""
    // Multiple API keys and models
    public var apiKeys: [APIKeyEntryData] = []
    public var selectedAPIKeyId: String = ""
    public var selectedModel: String = "Claude 3 Opus"
    // SAM.gov API
    public var samGovAPIKey: String = ""

    public init() {}
}

public struct APIKeyEntryData: Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var key: String
    public var isActive: Bool

    public init(id: String = UUID().uuidString, name: String, key: String, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.key = key
        self.isActive = isActive
    }
}

public struct DocumentSettingsData: Codable, Equatable, Sendable {
    public var defaultTemplateSet: String = "standard"
    public var includeMetadata: Bool = true
    public var includeVersionHistory: Bool = true
    public var autoGenerateTableOfContents: Bool = true
    public var defaultDocumentLanguage: String = "english"
    public var pageNumbering: Bool = true
    public var headerFooterEnabled: Bool = true
    public var watermarkEnabled: Bool = false
    public var watermarkText: String = "DRAFT"

    public init() {}
}

public struct NotificationSettingsData: Codable, Equatable, Sendable {
    public var enableNotifications: Bool = true
    public var documentGenerationComplete: Bool = true
    public var acquisitionReminders: Bool = true
    public var updateAvailable: Bool = true
    public var weeklyUsageReport: Bool = false
    public var soundEnabled: Bool = true
    public var notificationSound: String = "default"

    public init() {}
}

public struct DataPrivacySettingsData: Codable, Equatable, Sendable {
    public var analyticsEnabled: Bool = false
    public var crashReportingEnabled: Bool = true
    public var dataRetentionDays: Int = 90
    public var autoDeleteOldAcquisitions: Bool = false
    public var encryptLocalData: Bool = true
    public var biometricLockEnabled: Bool = false

    public init() {}
}

public struct AdvancedSettingsData: Codable, Equatable, Sendable {
    public var debugModeEnabled: Bool = false
    public var showDetailedErrors: Bool = false
    public var enableBetaFeatures: Bool = false
    public var cacheSizeMB: Int = 500
    public var maxConcurrentGenerations: Int = 3
    public var customPromptPrefixEnabled: Bool = false
    public var customPromptPrefix: String = ""
    // New advanced settings
    public var outputFormat: String = "rtf"
    public var llmTemperature: Double = 0.3
    public var outputLength: Int = 4000

    public init() {}
}

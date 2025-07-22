import Foundation

// MARK: - Scan Context for GlobalScanFeature

/// Context information for document scanning operations
public struct ScanContext: Equatable, Sendable {
    public let originScreen: AppScreen
    public let formContext: FormContext?
    public let sessionId: UUID
    public let timestamp: Date

    public init(
        originScreen: AppScreen,
        formContext: FormContext? = nil,
        sessionId: UUID = UUID(),
        timestamp: Date = Date()
    ) {
        self.originScreen = originScreen
        self.formContext = formContext
        self.sessionId = sessionId
        self.timestamp = timestamp
    }
}

/// Form context for scan operations
public struct FormContext: Equatable, Sendable {
    public let formType: FormType
    public let fieldMap: [String: String] // Simplified to be Sendable
    public let autoFillEnabled: Bool

    public init(
        formType: FormType,
        fieldMap: [String: String] = [:],
        autoFillEnabled: Bool = true
    ) {
        self.formType = formType
        self.fieldMap = fieldMap
        self.autoFillEnabled = autoFillEnabled
    }
}

/// Application screens for navigation context
public enum AppScreen: String, CaseIterable, Sendable {
    case documentList = "document_list"
    case formEntry = "form_entry"
    case settings
    case onboarding
    case profile
    case acquisitions
    case chat
    case documentAnalysis = "document_analysis"
    case documentGeneration = "document_generation"
    case documentStatus = "document_status"
    case shareFeature = "share_feature"
    case authentication
    case llmProviderSettings = "llm_provider_settings"
    case smartDefaultsDemo = "smart_defaults_demo"
    case documentDelivery = "document_delivery"
    case documentExecution = "document_execution"

    public var displayName: String {
        switch self {
        case .documentList: "Document List"
        case .formEntry: "Form Entry"
        case .settings: "Settings"
        case .onboarding: "Onboarding"
        case .profile: "Profile"
        case .acquisitions: "Acquisitions"
        case .chat: "Chat"
        case .documentAnalysis: "Document Analysis"
        case .documentGeneration: "Document Generation"
        case .documentStatus: "Document Status"
        case .shareFeature: "Share"
        case .authentication: "Authentication"
        case .llmProviderSettings: "LLM Provider Settings"
        case .smartDefaultsDemo: "Smart Defaults Demo"
        case .documentDelivery: "Document Delivery"
        case .documentExecution: "Document Execution"
        }
    }
}

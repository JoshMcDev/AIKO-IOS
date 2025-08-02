import AppCore
import Foundation
import SwiftUI
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

@MainActor
@Observable
public final class AppViewModel {
    // MARK: - Child ViewModels
    public var documentGenerationViewModel = DocumentGenerationViewModel()
    public var profileViewModel = ProfileViewModel()
    public var onboardingViewModel = OnboardingViewModel()
    public var acquisitionsListViewModel = AcquisitionsListViewModel()
    public var acquisitionChatViewModel = AcquisitionChatViewModel()
    public var settingsViewModel = SettingsViewModel()
    public var documentScannerViewModel = DocumentScannerViewModel()
    public var globalScanViewModel = GlobalScanViewModel()
    public var smartWorkflowEngine = SmartWorkflowEngine.shared

    // MARK: - Navigation State
    public var isOnboardingCompleted: Bool = false
    public var isAuthenticated: Bool = false
    public var isAuthenticating: Bool = false
    public var authenticationError: String?
    public var hasProfile: Bool = false
    public var showingMenu: Bool = false
    public var selectedMenuItem: MenuItem?
    public var showingQuickReferences: Bool = false
    public var selectedQuickReference: QuickReference?
    public var showingProfile: Bool = false
    public var showingAcquisitions: Bool = false
    public var showingUserGuide: Bool = false
    public var showingSearchTemplates: Bool = false
    public var showingSettings: Bool = false
    public var showingAcquisitionChat: Bool = false
    public var showingDocumentScanner: Bool = false
    public var showingQuickDocumentScanner: Bool = false
    public var loadedAcquisition: AppCore.Acquisition?
    public var loadedAcquisitionDisplayName: String?
    public var isChatMode: Bool = false
    public var showingDownloadOptions: Bool = false
    public var downloadTargetAcquisitionId: UUID?
    public var downloadTargetAcquisition: AppCore.Acquisition?
    public var showingSAMGovLookup: Bool = false

    // MARK: - Document Selection State
    public var selectedTypes: Set<AppCore.DocumentType> = []
    public var selectedDFTypes: Set<AppCore.DFDocumentType> = []
    public var documentStatus: [AppCore.DocumentType: DocumentStatus] = [:]
    public var hasAcquisition: Bool { loadedAcquisition != nil }
    public var hasSelectedDocuments: Bool {
        !selectedTypes.isEmpty || !selectedDFTypes.isEmpty
    }

    // MARK: - Document Sharing State
    public var showingDocumentSelection: Bool = false
    public var showingShareSheet: Bool = false
    public var shareTargetAcquisitionId: UUID?
    public var shareMode: ShareMode = .singleDocument
    public var selectedDocumentsForShare: Set<UUID> = []
    public var shareItems: [Any] = []

    // MARK: - Input Area State (for original InputArea component)
    public var requirements: String = ""
    public var isGenerating: Bool = false
    public var uploadedDocuments: [UploadedDocument] = []
    public var isRecording: Bool = false

    // MARK: - Error Handling
    public var error: Error?
    public var showingError: Bool = false

    public init() {
        // Check if onboarding is completed (in real app, load from UserDefaults)
        isOnboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        isAuthenticated = false // Always require authentication on app start
        
        // Initialize document status with realistic defaults
        initializeDocumentStatus()
    }
    
    private func initializeDocumentStatus() {
        // Intelligent status initialization based on acquisition context
        updateDocumentStatusIntelligently()
    }
    
    /// Update document status based on current acquisition and requirements
    public func updateDocumentStatusIntelligently() {
        for docType in AppCore.DocumentType.allCases {
            documentStatus[docType] = calculateIntelligentStatus(for: docType)
        }
    }
    
    private func calculateIntelligentStatus(for docType: AppCore.DocumentType) -> DocumentStatus {
        // Base requirements check
        guard let acquisition = loadedAcquisition else {
            // Without acquisition, most documents need more info
            return getDefaultStatusWithoutAcquisition(for: docType)
        }
        
        let requirements = acquisition.requirements.lowercased()
        
        // Analyze requirements content for this document type
        switch docType {
        case .sow, .soo:
            // Statement of Work needs clear deliverables and tasks
            if requirements.contains("deliverable") && requirements.contains("task") && requirements.count > 200 {
                return .ready
            } else if requirements.count > 100 {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .pws:
            // Performance Work Statement needs performance standards
            if requirements.contains("performance") && requirements.contains("standard") && requirements.contains("metric") {
                return .ready
            } else if requirements.contains("performance") {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .qasp:
            // QASP needs performance standards and monitoring approach
            if requirements.contains("performance") && requirements.contains("quality") && requirements.contains("surveillance") {
                return .ready
            } else if requirements.contains("performance") || requirements.contains("quality") {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .requestForProposal:
            // RFP needs comprehensive requirements and evaluation criteria
            let hasScope = requirements.contains("scope") || requirements.contains("requirement")
            let hasBudget = requirements.contains("budget") || requirements.contains("cost")
            let hasTimeline = requirements.contains("timeline") || requirements.contains("schedule")
            let hasEvaluation = requirements.contains("evaluation") || requirements.contains("criteria")
            
            let readyCount = [hasScope, hasBudget, hasTimeline, hasEvaluation].count { $0 }
            
            if readyCount >= 3 {
                return .ready
            } else if readyCount >= 2 {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .requestForQuote:
            // RFQ needs clear specifications and delivery requirements
            if requirements.contains("specification") && requirements.contains("delivery") {
                return .ready
            } else if requirements.contains("specification") || requirements.contains("delivery") {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .marketResearch:
            // Market research can be done with basic requirements
            if requirements.count > 50 {
                return .ready
            } else {
                return .needsMoreInfo
            }
            
        case .acquisitionPlan:
            // Acquisition plan needs comprehensive information
            let hasScope = requirements.contains("scope")
            let hasBudget = requirements.contains("budget") || requirements.contains("cost")
            let hasJustification = requirements.contains("justification") || requirements.contains("need")
            let hasStrategy = requirements.contains("strategy") || requirements.contains("approach")
            
            let componentCount = [hasScope, hasBudget, hasJustification, hasStrategy].count { $0 }
            
            if componentCount >= 3 {
                return .ready
            } else if componentCount >= 2 {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .evaluationPlan:
            // Evaluation plan needs criteria and methodology
            if requirements.contains("evaluation") && requirements.contains("criteria") {
                return .ready
            } else if requirements.contains("evaluation") || requirements.contains("criteria") {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        case .contractScaffold:
            // Contract needs comprehensive requirements and terms
            let hasSOW = selectedTypes.contains(.sow) || selectedTypes.contains(.pws)
            let hasTerms = requirements.contains("term") || requirements.contains("condition")
            let hasDelivery = requirements.contains("delivery") || requirements.contains("performance")
            
            if hasSOW && hasTerms && hasDelivery {
                return .ready
            } else if hasSOW || hasTerms {
                return .needsMoreInfo
            } else {
                return .notReady
            }
            
        default:
            // For other document types, use basic content analysis
            if requirements.count > 150 {
                return .ready
            } else if requirements.count > 75 {
                return .needsMoreInfo
            } else {
                return .notReady
            }
        }
    }
    
    private func getDefaultStatusWithoutAcquisition(for docType: AppCore.DocumentType) -> DocumentStatus {
        switch docType {
        case .marketResearch:
            // Market research can be done with minimal info
            return .needsMoreInfo
        case .acquisitionPlan:
            // Acquisition plan needs substantial information
            return .notReady
        case .sow, .soo, .pws, .qasp:
            // Work statements need acquisition context
            return .notReady
        case .requestForProposal, .requestForQuote:
            // Solicitations need comprehensive requirements
            return .notReady
        case .evaluationPlan:
            // Evaluation plan needs requirements context
            return .notReady
        case .contractScaffold:
            // Contract needs all components
            return .notReady
        default:
            return .needsMoreInfo
        }
    }

    // MARK: - App Lifecycle
    public func onAppear() {
        // Initialize app state
        if !isOnboardingCompleted {
            return
        }
        
        if !isAuthenticated {
            authenticateWithFaceID()
        }
    }

    // MARK: - Authentication
    public func authenticateWithFaceID() {
        isAuthenticating = true
        authenticationError = nil
        
        Task {
            // Simulate biometric authentication
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                // In real app, use LAContext for biometric authentication
                isAuthenticated = true
                isAuthenticating = false
            }
        }
    }

    // MARK: - Navigation Actions
    public func toggleMenu(_ show: Bool? = nil) {
        showingMenu = show ?? !showingMenu
    }

    public func selectMenuItem(_ item: MenuItem) {
        selectedMenuItem = item
        showingMenu = false

        switch item {
        case .profile:
            showingProfile = true
        case .acquisitions:
            showingAcquisitions = true
        case .userGuide:
            showingUserGuide = true
        case .searchTemplates:
            showingSearchTemplates = true
        case .settings:
            showingSettings = true
        }
    }

    public func startNewAcquisition() {
        loadedAcquisition = nil
        loadedAcquisitionDisplayName = nil
        isChatMode = false
        // Navigate to document generation or acquisition creation
    }

    public func startAcquisitionChat(for acquisition: AppCore.Acquisition) {
        loadedAcquisition = acquisition
        loadedAcquisitionDisplayName = acquisition.title
        showingAcquisitionChat = true
        isChatMode = true
    }

    public func closeAcquisitionChat() {
        showingAcquisitionChat = false
        loadedAcquisition = nil
        loadedAcquisitionDisplayName = nil
        isChatMode = false
    }

    public func showDocumentScanner(_ show: Bool) {
        showingDocumentScanner = show
    }

    public func startQuickDocumentScanner() {
        showingQuickDocumentScanner = true
    }

    public func closeDocumentScanner() {
        showingDocumentScanner = false
        showingQuickDocumentScanner = false
    }

    public func showSAMGovLookup(_ show: Bool) {
        showingSAMGovLookup = show
    }

    public func executeAllDocuments() {
        // Check if execution should proceed using smart workflow engine
        let decision = smartWorkflowEngine.shouldProceedWithExecution(
            selectedTypes: selectedTypes,
            loadedAcquisition: loadedAcquisition
        )
        
        if !decision.shouldProceed {
            // Trigger agent chat to help gather missing information
            showingAcquisitionChat = true
            return
        }
        
        // Execute all selected documents
        guard hasSelectedDocuments else { return }
        
        Task {
            // Simulate document execution
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                selectedTypes.removeAll()
                selectedDFTypes.removeAll()
                selectedDocumentsForShare.removeAll()
            }
        }
    }
    
    // MARK: - Smart Workflow Analysis
    
    private func analyzeWorkflowState() {
        let analysis = smartWorkflowEngine.analyzeWorkflowState(
            selectedTypes: selectedTypes,
            selectedDFTypes: selectedDFTypes,
            hasAcquisition: hasAcquisition,
            loadedAcquisition: loadedAcquisition,
            documentStatus: documentStatus
        )
        
        // Auto-trigger agent chat if confidence is too low
        if analysis.shouldTriggerAgentChat && analysis.confidenceScore < 0.4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showingAcquisitionChat = true
            }
        }
    }

    // MARK: - Document Selection Actions
    public func toggleDocumentType(_ documentType: AppCore.DocumentType) {
        let wasSelected = selectedTypes.contains(documentType)
        
        if wasSelected {
            selectedTypes.remove(documentType)
        } else {
            selectedTypes.insert(documentType)
        }
        
        // Record selection for pattern analysis
        smartWorkflowEngine.recordDocumentSelection(
            documentType: documentType,
            isSelected: !wasSelected
        )
        
        // Analyze workflow state and potentially trigger agent chat
        analyzeWorkflowState()
    }

    public func toggleDFDocumentType(_ dfDocumentType: AppCore.DFDocumentType) {
        if selectedDFTypes.contains(dfDocumentType) {
            selectedDFTypes.remove(dfDocumentType)
        } else {
            selectedDFTypes.insert(dfDocumentType)
        }
    }

    public func executeCategory(_ category: AppCore.DocumentCategory) {
        // TODO: Implement category execution
        print("Executing category: \(category.rawValue)")
    }

    // MARK: - Download Actions
    public func showDownloadOptions(for acquisition: AppCore.Acquisition) {
        downloadTargetAcquisition = acquisition
        downloadTargetAcquisitionId = acquisition.id
        showingDownloadOptions = true
    }

    public func hideDownloadOptions() {
        showingDownloadOptions = false
        downloadTargetAcquisition = nil
        downloadTargetAcquisitionId = nil
    }

    // MARK: - Share Actions
    public func showDocumentSelection(for acquisitionId: UUID, mode: ShareMode = .singleDocument) {
        shareTargetAcquisitionId = acquisitionId
        shareMode = mode
        showingDocumentSelection = true
    }

    public func hideDocumentSelection() {
        showingDocumentSelection = false
        shareTargetAcquisitionId = nil
        selectedDocumentsForShare.removeAll()
        shareItems.removeAll()
    }

    public func toggleDocumentSelection(_ documentId: UUID) {
        if selectedDocumentsForShare.contains(documentId) {
            selectedDocumentsForShare.remove(documentId)
        } else {
            selectedDocumentsForShare.insert(documentId)
        }
    }

    public func dismissShareSheet() {
        showingShareSheet = false
        shareItems.removeAll()
    }

    // MARK: - Error Handling
    public func setError(_ error: AppError) {
        self.error = error
        self.showingError = true
    }

    public func clearError() {
        self.error = nil
        self.showingError = false
    }
    
    // MARK: - InputArea Methods
    
    public func updateRequirements(_ newRequirements: String) {
        self.requirements = newRequirements
    }
    
    public func analyzeRequirements() {
        isGenerating = true
        Task {
            // Simulate analysis
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                isGenerating = false
            }
        }
    }
    
    public func enhancePrompt() {
        // Simulate prompt enhancement
        requirements += " (enhanced with AI suggestions)"
    }
    
    public func startRecording() {
        isRecording = true
    }
    
    public func stopRecording() {
        isRecording = false
    }
    
    public func showDocumentPicker() {
        // Implementation for document picker
    }
    
    public func showImagePicker() {
        // Implementation for image picker
    }
    
    public func removeDocument(_ documentId: UploadedDocument.ID) {
        uploadedDocuments.removeAll { $0.id == documentId }
    }
}

// MARK: - Supporting Types
public enum MenuItem: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case acquisitions = "Acquisitions"
    case userGuide = "User Guide"
    case searchTemplates = "Search Templates"
    case settings = "Settings"

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .profile:
            return "person.circle"
        case .acquisitions:
            return "doc.text"
        case .userGuide:
            return "book"
        case .searchTemplates:
            return "magnifyingglass"
        case .settings:
            return "gear"
        }
    }
}

public enum ShareMode: String, CaseIterable {
    case singleDocument = "Single Document"
    case multipleDocuments = "Multiple Documents"
    case fullAcquisition = "Full Acquisition"
}

public enum QuickReference: String, CaseIterable, Identifiable {
    case farBasics = "FAR Basics"
    case dfars = "DFARS"
    case contractTypes = "Contract Types"  
    case socioeconomic = "Socioeconomic Programs"

    public var id: String { rawValue }
}

// Use existing AppError from Sources/Models/AppError.swift

// MARK: - Feature ViewModels

@MainActor
@Observable
public final class DocumentGenerationViewModel {
    public var documentType: AppCore.DocumentType = .sow
    public var title: String = ""
    public var requirements: String = ""
    public var isGenerating: Bool = false
    public var generationProgress: Double = 0.0
    public var generatedContent: String = ""
    public var error: Error?

    public init() {}

    public func generateDocument() async {
        isGenerating = true
        generationProgress = 0.0
        defer { 
            isGenerating = false 
            generationProgress = 1.0
        }

        // TODO: Implement document generation
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

@MainActor
@Observable
public final class ProfileViewModel {
    public var profile: AppCore.UserProfile
    public var isEditing: Bool = false
    public var isSaving: Bool = false
    public var showImagePicker: Bool = false
    public var selectedImageType: ImageType = .profile
    public var error: Error?

    public enum ImageType {
        case profile
        case organizationLogo
    }

    public init(profile: AppCore.UserProfile = AppCore.UserProfile()) {
        self.profile = profile
    }

    public func startEditing() {
        isEditing = true
    }

    public func cancelEditing() {
        isEditing = false
    }

    public func saveProfile() async {
        isSaving = true
        defer { 
            isSaving = false
            isEditing = false
        }

        // TODO: Implement profile saving
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    public func showImagePicker(for type: ImageType) {
        selectedImageType = type
        showImagePicker = true
    }
}

@MainActor
@Observable
public final class OnboardingViewModel {
    public var currentStep: Int = 0
    public var totalSteps: Int = 5
    public var isCompleted: Bool = false
    public var userProfile: AppCore.UserProfile = AppCore.UserProfile()
    public var skipOnboarding: Bool = false

    public init() {}

    public func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }

    public func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    public func completeOnboarding() {
        isCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }

    public func skipToEnd() {
        skipOnboarding = true
        completeOnboarding()
    }
}

@MainActor
@Observable
public final class AcquisitionsListViewModel {
    public var acquisitions: [AppCore.Acquisition] = []
    public var filteredAcquisitions: [AppCore.Acquisition] = []
    public var searchText: String = ""
    public var selectedStatus: AppCore.AcquisitionStatus?
    public var isLoading: Bool = false
    public var showingCreateAcquisition: Bool = false
    public var error: Error?

    public init() {
        filterAcquisitions()
    }

    public func loadAcquisitions() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Implement acquisition loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        filterAcquisitions()
    }

    public func filterAcquisitions() {
        var filtered = acquisitions

        if !searchText.isEmpty {
            filtered = filtered.filter { acquisition in
                acquisition.title.localizedCaseInsensitiveContains(searchText) ||
                acquisition.requirements.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }

        filteredAcquisitions = filtered
    }

    public func createAcquisition() {
        showingCreateAcquisition = true
    }

    public func deleteAcquisition(_ acquisition: AppCore.Acquisition) {
        acquisitions.removeAll { $0.id == acquisition.id }
        filterAcquisitions()
    }
}

@MainActor
@Observable
public final class AcquisitionChatViewModel {
    public var acquisition: AppCore.Acquisition?
    public var messages: [ChatMessage] = []
    public var currentMessage: String = ""
    public var isTyping: Bool = false
    public var isGeneratingResponse: Bool = false
    public var error: Error?

    public init() {}

    public func loadAcquisition(_ acquisition: AppCore.Acquisition) {
        self.acquisition = acquisition
        loadChatHistory()
    }

    public func sendMessage() async {
        guard !currentMessage.isEmpty else { return }

        let userMessage = ChatMessage(content: currentMessage, isUser: true)
        messages.append(userMessage)

        let messageToSend = currentMessage
        currentMessage = ""

        isGeneratingResponse = true
        defer { isGeneratingResponse = false }

        // TODO: Implement AI response generation
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let aiResponse = ChatMessage(content: "AI response to: \(messageToSend)", isUser: false)
        messages.append(aiResponse)
    }

    private func loadChatHistory() {
        // TODO: Load chat history for acquisition
        messages = []
    }
}

@MainActor
@Observable
public final class SettingsViewModel {
    public var settings: AppCore.SettingsData = AppCore.SettingsData()
    public var isDarkMode: Bool = false
    public var enableNotifications: Bool = true
    public var autoSaveInterval: TimeInterval = 300 // 5 minutes
    public var showingAbout: Bool = false
    public var showingPrivacyPolicy: Bool = false
    public var isSaving: Bool = false
    public var error: Error?

    public init() {
        loadSettings()
    }

    public func loadSettings() {
        // TODO: Load settings from storage
    }

    public func saveSettings() async {
        isSaving = true
        defer { isSaving = false }

        // TODO: Save settings to storage
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    public func resetToDefaults() {
        settings = AppCore.SettingsData()
        isDarkMode = false
        enableNotifications = true
        autoSaveInterval = 300
    }
}

@MainActor
@Observable
public final class DocumentScannerViewModel {
    public var isScanning: Bool = false
    public var scannedPages: [AppCore.ScannedPage] = []
    public var currentPage: Int = 0
    public var scanQuality: ScanQuality = .high
    public var documentTitle: String = ""
    public var scanSession: AppCore.ScanSession?
    public var error: Error?

    public enum ScanQuality {
        case low, medium, high
    }

    public init() {}

    public func startScanning() async {
        isScanning = true
        scanSession = AppCore.ScanSession()

        // TODO: Implement document scanning
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isScanning = false
    }

    public func addPage(_ page: AppCore.ScannedPage) {
        scannedPages.append(page)
        currentPage = scannedPages.count - 1
    }

    public func removePage(at index: Int) {
        guard index < scannedPages.count else { return }
        scannedPages.remove(at: index)
        if currentPage >= scannedPages.count {
            currentPage = max(0, scannedPages.count - 1)
        }
    }

    public func saveDocument() async {
        // TODO: Save scanned document
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

@MainActor
@Observable
public final class GlobalScanViewModel {
    public var isGlobalScanEnabled: Bool = true
    public var scanTrigger: ScanTrigger = .floatingButton
    public var lastScanResult: ScanResult?
    public var scanHistory: [ScanResult] = []
    public var error: Error?

    public enum ScanTrigger {
        case floatingButton
        case keyboardShortcut
        case voiceCommand
    }

    public init() {}

    public func performGlobalScan() async {
        // TODO: Implement global scan functionality
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let result = ScanResult(content: "Scanned content", timestamp: Date())
        lastScanResult = result
        scanHistory.append(result)
    }

    public func clearHistory() {
        scanHistory.removeAll()
        lastScanResult = nil
    }
}

// MARK: - Supporting Types for ViewModels

public struct ChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let content: String
    public let isUser: Bool
    public let timestamp: Date

    public init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

public struct ScanResult: Identifiable, Sendable {
    public let id = UUID()
    public let content: String
    public let timestamp: Date

    public init(content: String, timestamp: Date = Date()) {
        self.content = content
        self.timestamp = timestamp
    }
}

// Use existing AppCore types - no need to redefine them
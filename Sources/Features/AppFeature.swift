import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

@Reducer
public struct AppFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var documentGeneration = DocumentGenerationFeature.State()
        public var profile = ProfileFeature.State()
        public var onboarding = OnboardingFeature.State()
        public var acquisitionsList = AcquisitionsListFeature.State()
        public var acquisitionChat = AcquisitionChatFeature.State()
        public var settings = SettingsFeature.State()
        public var documentScanner = DocumentScannerFeature.State()
        public var globalScan = GlobalScanFeature.State()
        public var isOnboardingCompleted: Bool = false
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

        // Document sharing state
        public var showingDocumentSelection: Bool = false
        public var shareTargetAcquisitionId: UUID?
        public var shareMode: ShareMode = .singleDocument
        public var selectedDocumentsForShare: Set<UUID> = []
        @ObservationStateIgnored public var shareItems: [Any] = []
        public var showingShareSheet: Bool = false

        public enum ShareMode: Sendable {
            case singleDocument
            case contractFile
        }

        // Face ID authentication state
        public var isAuthenticating: Bool = false
        public var isAuthenticated: Bool = false
        public var authenticationError: String?

        // General error alert
        @Presents public var errorAlert: AlertState<Action.Alert>?

        public var hasSelectedDocuments: Bool {
            !documentGeneration.status.selectedDocumentTypes.isEmpty ||
                !documentGeneration.status.selectedDFDocumentTypes.isEmpty
        }

        public init() {}

        public static func == (lhs: State, rhs: State) -> Bool {
            lhs.documentGeneration == rhs.documentGeneration &&
                lhs.profile == rhs.profile &&
                lhs.onboarding == rhs.onboarding &&
                lhs.acquisitionsList == rhs.acquisitionsList &&
                lhs.acquisitionChat == rhs.acquisitionChat &&
                lhs.settings == rhs.settings &&
                lhs.isOnboardingCompleted == rhs.isOnboardingCompleted &&
                lhs.hasProfile == rhs.hasProfile &&
                lhs.showingMenu == rhs.showingMenu &&
                lhs.selectedMenuItem == rhs.selectedMenuItem &&
                lhs.showingQuickReferences == rhs.showingQuickReferences &&
                lhs.selectedQuickReference == rhs.selectedQuickReference &&
                lhs.showingProfile == rhs.showingProfile &&
                lhs.showingAcquisitions == rhs.showingAcquisitions &&
                lhs.showingUserGuide == rhs.showingUserGuide &&
                lhs.showingSearchTemplates == rhs.showingSearchTemplates &&
                lhs.showingSettings == rhs.showingSettings &&
                lhs.showingAcquisitionChat == rhs.showingAcquisitionChat &&
                lhs.showingQuickDocumentScanner == rhs.showingQuickDocumentScanner &&
                lhs.loadedAcquisition == rhs.loadedAcquisition &&
                lhs.loadedAcquisitionDisplayName == rhs.loadedAcquisitionDisplayName &&
                lhs.isChatMode == rhs.isChatMode &&
                lhs.showingDownloadOptions == rhs.showingDownloadOptions &&
                lhs.downloadTargetAcquisitionId == rhs.downloadTargetAcquisitionId &&
                lhs.downloadTargetAcquisition == rhs.downloadTargetAcquisition &&
                lhs.showingSAMGovLookup == rhs.showingSAMGovLookup &&
                lhs.showingDocumentSelection == rhs.showingDocumentSelection &&
                lhs.shareTargetAcquisitionId == rhs.shareTargetAcquisitionId &&
                lhs.shareMode == rhs.shareMode &&
                lhs.selectedDocumentsForShare == rhs.selectedDocumentsForShare &&
                lhs.showingShareSheet == rhs.showingShareSheet &&
                lhs.isAuthenticating == rhs.isAuthenticating &&
                lhs.isAuthenticated == rhs.isAuthenticated &&
                lhs.authenticationError == rhs.authenticationError &&
                lhs.errorAlert == rhs.errorAlert &&
                lhs.globalScan == rhs.globalScan
            // Note: shareItems is intentionally excluded from equality check
        }
    }

    public enum MenuItem: String, CaseIterable, Equatable, Sendable {
        case myProfile = "My Profile"
        case myAcquisitions = "My Acquisitions"
        case documentScanner = "Document Scanner"
        case quickReferences = "Quick Links"
        case searchTemplates = "Search Document Templates"
        case userGuide = "User Guide"
        case settings = "Settings"

        public var icon: String {
            switch self {
            case .myProfile: "person.crop.circle.fill"
            case .myAcquisitions: "clock.arrow.circlepath"
            case .documentScanner: "doc.text.viewfinder"
            case .quickReferences: "link.circle.fill"
            case .searchTemplates: "doc.text.magnifyingglass"
            case .userGuide: "questionmark.circle.fill"
            case .settings: "gearshape.fill"
            }
        }

        public var description: String {
            switch self {
            case .myProfile: "Your profile information"
            case .myAcquisitions: "View your requirement history"
            case .documentScanner: "Scan documents for acquisition contracts"
            case .quickReferences: "Access useful acquisition resources"
            case .searchTemplates: "Browse all document templates"
            case .userGuide: "Learn how to use AIKO"
            case .settings: "App preferences and configuration"
            }
        }
    }

    public enum QuickReference: String, CaseIterable, Equatable, Sendable {
        case acquisitionGov = "Acquisition.gov"
        case samGov = "SAM.gov"
        case fpdsNG = "FPDS-NG"
        case forms = "Forms"
        case acqGatewayDocs = "ACQ Gateway Docs"
        case gsaSPBASamples = "GSA SPBA Samples"
        case gsaTemplates = "GSA Templates"
        case customLink = "Custom Link"

        public var url: String {
            switch self {
            case .acquisitionGov: "https://www.acquisition.gov/browse/index/far"
            case .samGov: "https://sam.gov/"
            case .fpdsNG: "https://www.fpds.gov/fpdsng_cms/index.php/en/"
            case .forms: "https://www.gsa.gov/forms"
            case .acqGatewayDocs: "https://acquisitiongateway.gov/documents"
            case .gsaSPBASamples: "https://buy.gsa.gov/spba-resource-library?sort_by=title&sort_order=asc&page=1"
            case .gsaTemplates: "https://buy.gsa.gov/find-samples-templates-tips?sort_by=title&sort_order=asc&page=1"
            case .customLink: ""
            }
        }

        public var icon: String {
            switch self {
            case .acquisitionGov: "book.circle.fill"
            case .samGov: "building.columns.circle.fill"
            case .fpdsNG: "chart.bar.doc.horizontal.fill"
            case .forms: "doc.text.fill"
            case .acqGatewayDocs: "doc.richtext.fill"
            case .gsaSPBASamples: "doc.on.doc.fill"
            case .gsaTemplates: "doc.badge.plus"
            case .customLink: "plus.circle.fill"
            }
        }

        public var description: String {
            switch self {
            case .acquisitionGov: "Federal Acquisition Regulation"
            case .samGov: "System for Award Management"
            case .fpdsNG: "Federal Procurement Data System"
            case .forms: "GSA Forms Library"
            case .acqGatewayDocs: "Acquisition Gateway Documents"
            case .gsaSPBASamples: "Strategic Partnership Agreement Samples"
            case .gsaTemplates: "GSA Contract Templates & Tips"
            case .customLink: "Add your own reference link"
            }
        }
    }

    public enum Action {
        case documentGeneration(DocumentGenerationFeature.Action)
        case profile(ProfileFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case acquisitionsList(AcquisitionsListFeature.Action)
        case onAppear
        case profileCheckCompleted(Bool)
        case completeOnboarding
        case toggleMenu(Bool)
        case selectMenuItem(MenuItem?)
        case toggleQuickReferences(Bool)
        case selectQuickReference(QuickReference?)
        case openURL(URL)
        case showProfile(Bool)
        case showAcquisitions(Bool)
        case showUserGuide(Bool)
        case showSearchTemplates(Bool)
        case showSettings(Bool)
        case settings(SettingsFeature.Action)
        case loadAcquisition(UUID)
        case acquisitionLoaded(AppCore.Acquisition)
        case loadAcquisitionError(String)
        case clearLoadedAcquisition
        case showDownloadOptions(UUID)
        case shareAcquisitionDocuments(UUID)
        case shareAcquisitionContractFiles(UUID)
        case hideDownloadOptions
        case showDocumentSelectionForShare
        case hideDocumentSelection
        case toggleDocumentForShare(UUID)
        case confirmShareSelection
        case shareSelectedDocuments
        case presentShareSheet([Any])
        case dismissShareSheet
        case startNewAcquisition
        case saveCurrentAcquisitionBeforeNew
        case newAcquisitionStarted
        case executeAllDocuments
        case acquisitionChat(AcquisitionChatFeature.Action)
        case showAcquisitionChat(Bool)
        case acquisitionChatCompleted(UUID, Set<DocumentType>)
        case showSAMGovLookup(Bool)

        // Document Scanner actions
        case showDocumentScanner(Bool)
        case showQuickDocumentScanner(Bool)
        case startQuickScan
        case documentScanner(DocumentScannerFeature.Action)

        // Global Scan actions
        case globalScan(GlobalScanFeature.Action)
        case toggleGlobalScanVisibility(Bool)
        case configureGlobalScan(GlobalScanConfiguration)

        // Face ID authentication actions
        case checkFaceIDAuthentication
        case authenticateWithFaceID
        case authenticationCompleted(Bool)
        case authenticationError(String)
        case dismissAuthenticationError

        // Alert actions
        case errorAlert(PresentationAction<Alert>)

        public enum Alert: Equatable, Sendable {
            case dismiss
        }
    }

    public init() {}

    @Dependency(\.userProfileService) var userProfileService
    @Dependency(\.acquisitionService) var acquisitionService
    @Dependency(\.settingsManager) var settingsManager
    @Dependency(\.biometricAuthenticationService) var biometricAuthenticationService

    public var body: some ReducerOf<Self> {
        Scope(state: \.documentGeneration, action: \.documentGeneration) {
            DocumentGenerationFeature()
        }

        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Scope(state: \.acquisitionsList, action: \.acquisitionsList) {
            AcquisitionsListFeature()
        }

        Scope(state: \.acquisitionChat, action: \.acquisitionChat) {
            AcquisitionChatFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Scope(state: \.documentScanner, action: \.documentScanner) {
            DocumentScannerFeature()
        }

        Scope(state: \.globalScan, action: \.globalScan) {
            GlobalScanFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                // Check if user has a profile
                return .run { send in
                    let hasProfile = await userProfileService.hasProfile()
                    await send(.profileCheckCompleted(hasProfile))
                    await send(.checkFaceIDAuthentication)
                }

            case let .profileCheckCompleted(hasProfile):
                state.hasProfile = hasProfile
                state.isOnboardingCompleted = hasProfile
                return .none

            case .checkFaceIDAuthentication:
                guard state.isOnboardingCompleted else { return .none }

                // Skip Face ID in preview mode
                #if DEBUG
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        state.isAuthenticated = true
                        return .none
                    }
                #endif

                return .run { send in
                    let settings = try await settingsManager.loadSettings()
                    if settings.appSettings.faceIDEnabled {
                        await send(.authenticateWithFaceID)
                    } else {
                        await send(.authenticationCompleted(true))
                    }
                }

            case .authenticateWithFaceID:
                state.isAuthenticating = true
                return .run { send in
                    do {
                        let success = try await biometricAuthenticationService.authenticate("Unlock AIKO")
                        await send(.authenticationCompleted(success))
                    } catch {
                        await send(.authenticationError(error.localizedDescription))
                    }
                }

            case let .authenticationCompleted(success):
                state.isAuthenticating = false
                state.isAuthenticated = success
                if !success {
                    // If authentication failed, show error and retry
                    return .run { send in
                        await send(.authenticationError("Authentication failed. Please try again."))
                    }
                }
                return .none

            case let .authenticationError(error):
                state.isAuthenticating = false
                state.authenticationError = error
                // Retry authentication after showing error
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    await send(.dismissAuthenticationError)
                    await send(.authenticateWithFaceID)
                }

            case .dismissAuthenticationError:
                state.authenticationError = nil
                return .none

            case .completeOnboarding:
                state.isOnboardingCompleted = true
                return .none

            case let .toggleMenu(show):
                state.showingMenu = show
                return .none

            case let .selectMenuItem(item):
                state.selectedMenuItem = item
                // Handle menu item selection
                switch item {
                case .myProfile:
                    state.showingProfile = true
                    state.showingMenu = false
                case .myAcquisitions:
                    state.showingAcquisitions = true
                    state.showingMenu = false
                case .documentScanner:
                    state.showingDocumentScanner = true
                    state.showingMenu = false
                case .quickReferences:
                    state.showingQuickReferences = true
                case .userGuide:
                    state.showingUserGuide = true
                    state.showingMenu = false
                case .searchTemplates:
                    state.showingSearchTemplates = true
                    state.showingMenu = false
                case .settings:
                    state.showingSettings = true
                    state.showingMenu = false
                default:
                    break
                }
                return .none

            case let .toggleQuickReferences(show):
                state.showingQuickReferences = show
                return .none

            case let .selectQuickReference(reference):
                state.selectedQuickReference = reference
                if let reference,
                   let url = URL(string: reference.url)
                {
                    return .run { send in
                        await send(.openURL(url))
                    }
                }
                return .none

            case let .openURL(url):
                Task { @MainActor in
                    #if os(iOS)
                        UIApplication.shared.open(url)
                    #else
                        NSWorkspace.shared.open(url)
                    #endif
                }
                return .none

            case let .showProfile(show):
                state.showingProfile = show
                return .none

            case let .showAcquisitions(show):
                state.showingAcquisitions = show
                return .none

            case let .showUserGuide(show):
                state.showingUserGuide = show
                return .none

            case let .showSearchTemplates(show):
                state.showingSearchTemplates = show
                return .none

            case let .showSettings(show):
                state.showingSettings = show
                return .none

            case .settings:
                // Settings actions are handled by the child reducer
                return .none

            case let .documentGeneration(.needsMoreInfoForDocuments(documentTypes)):
                // Open the Agentic Chat Interface to gather info for documents with red status
                state.showingAcquisitionChat = true
                state.acquisitionChat = AcquisitionChatFeature.State()
                state.acquisitionChat.recommendedDocuments = documentTypes

                // Initialize with an intent for gathering document requirements
                let intent = AcquisitionIntent(
                    id: UUID(),
                    type: .modifyRequirements,
                    parameters: ["documents": documentTypes.map(\.shortName).joined(separator: ", ")],
                    confidence: 0.95,
                    requiresExecution: true
                )
                state.acquisitionChat.currentIntent = intent
                state.acquisitionChat.agentState = .thinking

                // Add initial message using the enhanced Agentic Chat format
                let message = ChatMessage(
                    id: UUID(),
                    role: .assistant,
                    content: """
                    # Additional Information Needed

                    I see you've selected documents that require more information before they can be generated. Let me help gather the necessary details.

                    **Selected documents requiring information:**
                    \(documentTypes.map { "- \($0.shortName)" }.joined(separator: "\n"))

                    I'll guide you through gathering the required information for each document. What type of product or service are you looking to acquire?
                    """,
                    timestamp: Date(),
                    card: MessageCard(
                        type: .compliance,
                        title: "Document Requirements Status",
                        data: .compliance(ComplianceData(
                            score: 0.3,
                            issues: documentTypes.map { "\($0.shortName) - Missing required information" },
                            recommendations: ["Provide acquisition details", "Specify requirements", "Add technical specifications"]
                        ))
                    )
                )

                // Convert to AcquisitionChatFeature message format
                state.acquisitionChat.messages.append(AcquisitionChatFeature.ChatMessage(
                    role: .assistant,
                    content: message.content
                ))

                // Add task to queue for gathering information
                let task = AgentTask(action: AgentAction(
                    id: UUID(),
                    type: .gatherMarketResearch,
                    description: "Gather information for \(documentTypes.count) documents",
                    requiresApproval: false
                ))
                state.acquisitionChat.activeTask = task

                return .none

            case .documentGeneration:
                return .none

            case .profile:
                return .none

            case let .acquisitionsList(.openAcquisition(id)):
                // Load the acquisition and switch to main view
                state.showingAcquisitions = false
                return .send(.loadAcquisition(id))

            case let .acquisitionsList(.shareDocument(id)):
                // Share individual documents for the acquisition
                return .send(.shareAcquisitionDocuments(id))

            case let .acquisitionsList(.shareContractFile(id)):
                // Share all contract files and summary for the acquisition
                return .send(.shareAcquisitionContractFiles(id))

            case .acquisitionsList(.duplicateAcquisition):
                // Duplicate is handled within AcquisitionsListFeature
                return .none

            case .acquisitionsList:
                return .none

            case let .loadAcquisition(id):
                return .run { send in
                    do {
                        if let acquisition = try await acquisitionService.fetchAcquisition(id) {
                            await send(.acquisitionLoaded(acquisition))
                        } else {
                            await send(.loadAcquisitionError("Acquisition not found"))
                        }
                    } catch {
                        await send(.loadAcquisitionError(error.localizedDescription))
                    }
                }

            case let .acquisitionLoaded(acquisition):
                state.loadedAcquisition = acquisition
                state.isChatMode = true

                // Generate a relevant display name based on requirements
                if !acquisition.requirements.isEmpty {
                    state.loadedAcquisitionDisplayName = generateRelevantName(from: acquisition.requirements)
                } else if !acquisition.title.isEmpty {
                    state.loadedAcquisitionDisplayName = acquisition.title
                } else {
                    state.loadedAcquisitionDisplayName = "Acquisition \(acquisition.projectNumber ?? "")"
                }

                // Clear the input field for chat mode but keep requirements in analysis context
                state.documentGeneration.requirements = ""

                // Set the current acquisition ID and load context
                state.documentGeneration.analysis.currentAcquisitionId = acquisition.id
                // Don't populate requirements in the input field - keep it empty

                // Update document status based on generated files
                let generatedFiles = acquisition.generatedFilesArray
                return .concatenate(
                    .send(.documentGeneration(.analysis(.loadAcquisition(acquisition.id)))),
                    .send(.documentGeneration(.status(.updateStatusFromGeneratedDocuments(generatedFiles))))
                )

            case let .loadAcquisitionError(error):
                state.errorAlert = AlertState {
                    TextState("Failed to Load Acquisition")
                } actions: {
                    ButtonState(action: .dismiss) {
                        TextState("OK")
                    }
                } message: {
                    TextState(error)
                }
                return .none

            case .clearLoadedAcquisition:
                state.loadedAcquisition = nil
                state.loadedAcquisitionDisplayName = nil
                state.isChatMode = false
                state.documentGeneration.requirements = ""
                state.documentGeneration.analysis.currentAcquisitionId = nil
                return .none

            case let .showDownloadOptions(id):
                state.downloadTargetAcquisitionId = id
                // Find and store the acquisition directly
                state.downloadTargetAcquisition = state.acquisitionsList.acquisitions.first { $0.id == id }
                state.showingDownloadOptions = true
                return .none

            case let .shareAcquisitionDocuments(id):
                // Show document selection for sharing
                state.shareTargetAcquisitionId = id
                state.shareMode = .singleDocument
                state.selectedDocumentsForShare = []
                state.showingDocumentSelection = true
                return .none

            case let .shareAcquisitionContractFiles(id):
                // Share all contract files with summary
                state.shareTargetAcquisitionId = id
                state.shareMode = .contractFile
                state.selectedDocumentsForShare = []
                return .send(.shareSelectedDocuments)

            case .hideDownloadOptions:
                state.showingDownloadOptions = false
                state.downloadTargetAcquisitionId = nil
                state.downloadTargetAcquisition = nil
                return .none

            case .showDocumentSelectionForShare:
                state.showingDocumentSelection = true
                return .none

            case .hideDocumentSelection:
                state.showingDocumentSelection = false
                state.selectedDocumentsForShare = []
                return .none

            case let .toggleDocumentForShare(documentId):
                if state.selectedDocumentsForShare.contains(documentId) {
                    state.selectedDocumentsForShare.remove(documentId)
                } else {
                    state.selectedDocumentsForShare.insert(documentId)
                }
                return .none

            case .confirmShareSelection:
                guard !state.selectedDocumentsForShare.isEmpty else { return .none }
                return .send(.shareSelectedDocuments)

            case .shareSelectedDocuments:
                return .run { [shareMode = state.shareMode, shareTargetAcquisitionId = state.shareTargetAcquisitionId, selectedDocumentsForShare = state.selectedDocumentsForShare] send in
                    guard let acquisitionId = shareTargetAcquisitionId else { return }

                    @Dependency(\.acquisitionService) var acquisitionService

                    // Get the acquisition
                    guard let acquisition = try await acquisitionService.fetchAcquisition(acquisitionId) else { return }

                    // Generate share content based on mode
                    var shareContent = ""

                    if shareMode == .contractFile {
                        // Share all contract files with summary
                        shareContent = """
                        Acquisition Report
                        Generated: \(Date().formatted())

                        ACQUISITION DETAILS:
                        - ID: \(acquisition.id.uuidString)
                        - Title: \(acquisition.title)
                        - Project Number: \(acquisition.projectNumber ?? "N/A")
                        - Status: \(acquisition.status.displayName)
                        - Created: \(acquisition.createdDate.formatted())
                        - Modified: \(acquisition.lastModifiedDate.formatted())

                        REQUIREMENTS:
                        \(acquisition.requirements)
                        """
                        shareContent += "\n\n--- ALL CONTRACT FILES ---\n\n"

                        // Add all documents
                        for document in acquisition.generatedFilesArray {
                            shareContent += "Document: \(document.documentType?.shortName ?? "Untitled")\n"
                            shareContent += "Type: \(document.documentType?.shortName ?? "Unknown")\n"
                            shareContent += "Generated: \(document.createdAt.formatted())\n"
                            shareContent += "---\n\n"
                        }
                    } else {
                        // Share selected documents
                        shareContent = "Selected Documents from Acquisition: \(acquisition.title)\n\n"

                        let selectedDocs = acquisition.generatedFilesArray.filter { doc in
                            selectedDocumentsForShare.contains(doc.id)
                        }

                        for document in selectedDocs {
                            shareContent += "Document: \(document.documentType?.shortName ?? "Untitled")\n"
                            shareContent += "Type: \(document.documentType?.shortName ?? "Unknown")\n"
                            shareContent += "---\n\n"
                        }
                    }

                    // Create share items
                    var items: [Any] = [shareContent]

                    // Add documents as files if available
                    if shareMode == .contractFile {
                        // Add all documents
                        for document in acquisition.generatedFilesArray {
                            if !document.content.isEmpty,
                               let documentType = document.documentType
                            {
                                let fileName = documentType.shortName
                                let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).txt")
                                try? document.content.write(to: url, atomically: true, encoding: .utf8)
                                items.append(url)
                            }
                        }
                    } else {
                        // Add selected documents
                        let selectedDocs = acquisition.generatedFilesArray.filter { doc in
                            selectedDocumentsForShare.contains(doc.id)
                        }

                        for document in selectedDocs {
                            if !document.content.isEmpty,
                               let documentType = document.documentType
                            {
                                let fileName = documentType.shortName
                                let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).txt")
                                try? document.content.write(to: url, atomically: true, encoding: .utf8)
                                items.append(url)
                            }
                        }
                    }

                    await send(.presentShareSheet(items))
                    await send(.hideDocumentSelection)
                }

            case let .presentShareSheet(items):
                state.shareItems = items
                state.showingShareSheet = true
                return .none

            case .dismissShareSheet:
                state.shareItems = []
                state.showingShareSheet = false
                return .none

            case .onboarding(.onboardingCompleted):
                state.isOnboardingCompleted = true
                state.hasProfile = true
                return .none

            case .onboarding:
                return .none

            case .startNewAcquisition:
                // Show the acquisition chat dialog
                state.showingAcquisitionChat = true
                state.acquisitionChat = AcquisitionChatFeature.State()
                return .none

            case .saveCurrentAcquisitionBeforeNew:
                // Save current acquisition state
                if state.documentGeneration.analysis.currentAcquisitionId != nil {
                    return .concatenate(
                        // Save the current state
                        .send(.documentGeneration(.analysis(.saveCurrentState))),
                        // Wait a moment for save to complete
                        .run { send in
                            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            await send(.newAcquisitionStarted)
                        }
                    )
                }
                return .send(.newAcquisitionStarted)

            case .newAcquisitionStarted:
                // Clear current acquisition
                state.loadedAcquisition = nil
                state.loadedAcquisitionDisplayName = nil
                state.isChatMode = false
                state.documentGeneration.requirements = ""
                state.documentGeneration.analysis.currentAcquisitionId = nil
                state.documentGeneration.analysis.conversationHistory = []
                state.documentGeneration.analysis.requirements = ""
                state.documentGeneration.analysis.uploadedDocuments = []
                state.documentGeneration.analysis.documentChain = nil
                state.documentGeneration.analysis.chainValidation = nil
                state.documentGeneration.selectedDocumentTypes = []
                state.documentGeneration.status.selectedDFDocumentTypes = []
                state.documentGeneration.status.documentReadinessStatus = [:]

                // Set RRD as selected by default for new acquisition
                state.documentGeneration.selectedDocumentTypes = [.rrd]

                // Trigger RRD analysis
                return .send(.documentGeneration(.analyzeRequirements))

            case .executeAllDocuments:
                // Execute all selected documents across all categories
                let selectedDocs = state.documentGeneration.status.selectedDocumentTypes
                let selectedDFDocs = state.documentGeneration.status.selectedDFDocumentTypes

                // Check if any selected documents have red status (not ready)
                let notReadyDocs = selectedDocs.filter { documentType in
                    if let status = state.documentGeneration.status.documentReadinessStatus[documentType] {
                        return status == .notReady
                    }
                    return true // If no status, assume not ready
                }

                // If there are documents that aren't ready, open chat to gather info
                if !notReadyDocs.isEmpty {
                    // Prepare chat state with selected documents that need info
                    state.showingAcquisitionChat = true
                    state.acquisitionChat = AcquisitionChatFeature.State()
                    state.acquisitionChat.recommendedDocuments = selectedDocs
                    // Add initial message about gathering info for specific documents
                    state.acquisitionChat.messages.append(AcquisitionChatFeature.ChatMessage(
                        role: .assistant,
                        content: """
                        # Additional Information Needed

                        I see you've selected documents that require more information before they can be generated. Let me help gather the necessary details.

                        **Selected documents requiring information:**
                        \(notReadyDocs.map { "- \($0.shortName)" }.joined(separator: "\n"))

                        Let's start by understanding your requirements better. What type of product or service are you looking to acquire?
                        """
                    ))
                    return .none
                }

                // All documents are ready, proceed with generation
                return .send(.documentGeneration(.execution(.executeCategory(
                    .requirements, // Use any category as placeholder
                    selectedDocs,
                    selectedDFDocs
                ))))

            case let .showAcquisitionChat(show):
                state.showingAcquisitionChat = show
                return .none

            case let .showSAMGovLookup(show):
                state.showingSAMGovLookup = show
                return .none

            case .acquisitionChat(.closeChat):
                // Handle chat close
                state.showingAcquisitionChat = false

                // If acquisition was saved, load it
                if let acquisitionId = state.acquisitionChat.acquisitionId {
                    return .concatenate(
                        .send(.loadAcquisition(acquisitionId)),
                        .send(.acquisitionChatCompleted(
                            acquisitionId,
                            state.acquisitionChat.recommendedDocuments
                        ))
                    )
                }
                return .none

            case .acquisitionChat(.generateDocuments):
                // Close chat and generate recommended documents
                state.showingAcquisitionChat = false

                if let acquisitionId = state.acquisitionChat.acquisitionId {
                    // Set recommended documents as selected
                    state.documentGeneration.status.selectedDocumentTypes = state.acquisitionChat.recommendedDocuments

                    return .concatenate(
                        .send(.loadAcquisition(acquisitionId)),
                        .run { send in
                            // Wait for acquisition to load
                            try await Task.sleep(nanoseconds: 500_000_000)
                            await send(.documentGeneration(.generateDocuments))
                        }
                    )
                }
                return .none

            case .acquisitionChat:
                return .none

            case let .acquisitionChatCompleted(_, recommendedDocuments):
                // Update document readiness based on chat
                for docType in recommendedDocuments {
                    state.documentGeneration.status.documentReadinessStatus[docType] = .ready
                }
                return .none

            // MARK: Document Scanner

            case let .showDocumentScanner(show):
                state.showingDocumentScanner = show
                return .none

            case let .showQuickDocumentScanner(show):
                state.showingQuickDocumentScanner = show
                return .none

            case .startQuickScan:
                state.showingQuickDocumentScanner = true
                return .send(.documentScanner(.startQuickScan))

            case .documentScanner(.dismissScanner):
                state.showingDocumentScanner = false
                state.showingQuickDocumentScanner = false
                return .none

            case .documentScanner(.documentSaved):
                // Scanner successfully saved document to pipeline
                state.showingDocumentScanner = false
                state.showingQuickDocumentScanner = false
                // Optionally refresh acquisition data or show success
                return .none

            case .documentScanner:
                // Other scanner actions are handled by the child reducer
                return .none

            // MARK: Global Scan

            case .globalScan(.activateScanner):
                // When global scan activates, ensure we don't have conflicts
                // with existing scanner state
                if state.showingDocumentScanner || state.showingQuickDocumentScanner {
                    // Dismiss existing scanner first
                    state.showingDocumentScanner = false
                    state.showingQuickDocumentScanner = false
                }
                return .none

            case .globalScan(.scannerCompleted):
                // Global scan completed successfully
                return .run { _ in
                    // Optionally refresh acquisition data or show success feedback
                }

            case .globalScan:
                // Other global scan actions handled by child reducer
                return .none

            case let .toggleGlobalScanVisibility(visible):
                return .send(.globalScan(.setVisibility(visible)))

            case let .configureGlobalScan(config):
                return .send(.globalScan(.updateConfiguration(config)))

            case .errorAlert:
                return .none
            }
        }
        .ifLet(\.$errorAlert, action: \.errorAlert)
    }

    // Helper function to generate a relevant name from requirements
    private func generateRelevantName(from requirements: String) -> String {
        // Extract key information from requirements
        let lowercased = requirements.lowercased()
        let lines = requirements.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Look for common patterns
        if lowercased.contains("cloud") && lowercased.contains("services") {
            if lowercased.contains("data") || lowercased.contains("analytics") {
                return "Cloud Services - Data Analytics"
            }
            return "Cloud Services"
        } else if lowercased.contains("software") || lowercased.contains("application") {
            if lowercased.contains("development") {
                return "Software Development Contract"
            } else if lowercased.contains("maintenance") {
                return "Software Maintenance Contract"
            } else if lowercased.contains("license") {
                return "Software Licensing Agreement"
            }
            return "Software Acquisition"
        } else if lowercased.contains("equipment") || lowercased.contains("hardware") {
            if lowercased.contains("maintenance") {
                return "Equipment Maintenance Contract"
            } else if lowercased.contains("purchase") || lowercased.contains("procurement") {
                return "Equipment Procurement"
            }
            return "Equipment Acquisition"
        } else if lowercased.contains("service") || lowercased.contains("support") {
            if lowercased.contains("technical") {
                return "Technical Services Contract"
            } else if lowercased.contains("professional") {
                return "Professional Services Contract"
            } else if lowercased.contains("maintenance") {
                return "Maintenance Services Contract"
            }
            return "Services Contract"
        } else if lowercased.contains("construction") || lowercased.contains("renovation") {
            return "Construction Contract"
        } else if lowercased.contains("consulting") || lowercased.contains("advisory") {
            return "Consulting Services"
        } else if lowercased.contains("training") || lowercased.contains("education") {
            return "Training Services Contract"
        } else if lowercased.contains("research") || lowercased.contains("development") {
            return "R&D Contract"
        } else if lowercased.contains("supply") || lowercased.contains("materials") {
            return "Supply Contract"
        }

        // If no pattern matches, try to use the first meaningful part
        if firstLine.count > 10, firstLine.count < 50 {
            return firstLine
        } else if firstLine.count >= 50 {
            // Truncate long first lines
            let words = firstLine.components(separatedBy: .whitespaces)
            return words.prefix(5).joined(separator: " ") + "..."
        }

        // Default fallback
        return "Contract Requirements"
    }
}

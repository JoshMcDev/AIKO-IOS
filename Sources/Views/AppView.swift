import ComposableArchitecture
import SwiftUI
import AppCore
#if os(iOS)
    import UIKit
    import UniformTypeIdentifiers
    import VisionKit
    import AIKOiOS
#elseif os(macOS)
    import AppKit
    import AIKOmacOS
#endif

// App Icon View Component
struct AppIconView: View {
    var body: some View {
        if let image = loadAppIconFromBundle() {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        } else {
            // Show the actual design if PNG not found
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.5, blue: 0.2),
                                Color(red: 0.2, green: 0.4, blue: 0.8),
                            ]),
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )

                // Scroll and quill design
                ZStack {
                    Image(systemName: "scroll")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.cyan)

                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.cyan)
                        .rotationEffect(.degrees(-45))
                        .offset(x: 8, y: -8)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
    
    private func loadAppIconFromBundle() -> Image? {
        // Try multiple loading methods to ensure it works in previews
        
        // Method 1: Try loading from bundle with different approaches
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let data = try? Data(contentsOf: url) {
            #if os(iOS)
                if let uiImage = UIImage(data: data) {
                    return Image(uiImage: uiImage)
                }
            #elseif os(macOS)
                if let nsImage = NSImage(data: data) {
                    return Image(nsImage: nsImage)
                }
            #endif
        }
        
        // Method 2: Try named image loading
        #if os(iOS)
            if let uiImage = UIImage(named: "AppIcon", in: Bundle.main, compatibleWith: nil) {
                return Image(uiImage: uiImage)
            }
            // Method 3: Try without specifying bundle (for previews)
            if let uiImage = UIImage(named: "AppIcon") {
                return Image(uiImage: uiImage)
            }
        #else
            if let nsImage = NSImage(named: "AppIcon") {
                return Image(nsImage: nsImage)
            }
        #endif
        
        // Method 4: Try from module bundle (for SPM)
        if let bundleURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let data = try? Data(contentsOf: bundleURL) {
            #if os(iOS)
                if let uiImage = UIImage(data: data) {
                    return Image(uiImage: uiImage)
                }
            #elseif os(macOS)
                if let nsImage = NSImage(data: data) {
                    return Image(nsImage: nsImage)
                }
            #endif
        }
        
        return nil
    }
}

public struct AppView: View {
    let store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    contentView
                    #if os(iOS)
                    .navigationBarHidden(true)
                    #endif
                }
                .preferredColorScheme(.dark)
                .tint(.white)
            } else {
                SwiftUI.NavigationView {
                    contentView
                    #if os(iOS)
                    .navigationBarHidden(true)
                    #endif
                }
                #if os(iOS)
                .navigationViewStyle(StackNavigationViewStyle())
                #endif
                .preferredColorScheme(.dark)
            }
        #else
            SwiftUI.NavigationView {
                contentView
            }
            .preferredColorScheme(.dark)
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if !viewStore.isOnboardingCompleted {
                onboardingView
            } else if !viewStore.isAuthenticated {
                authenticationView(viewStore: viewStore)
            } else {
                mainContentView(viewStore: viewStore)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert(
            store: store.scope(state: \.$errorAlert, action: \.errorAlert)
        )
    }

    private var onboardingView: some View {
        OnboardingView(
            store: store.scope(
                state: \.onboarding,
                action: \.onboarding
            )
        )
        .transition(.opacity)
    }

    private func authenticationView(viewStore: ViewStore<AppFeature.State, AppFeature.Action>) -> some View {
        FaceIDAuthenticationView(
            isAuthenticating: viewStore.isAuthenticating,
            error: viewStore.authenticationError,
            onRetry: { viewStore.send(.authenticateWithFaceID) }
        )
        .transition(.opacity)
    }

    @ViewBuilder
    private func mainContentView(viewStore: ViewStore<AppFeature.State, AppFeature.Action>) -> some View {
        ZStack(alignment: .trailing) {
            // Background that extends to safe area
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HeaderView(
                    showMenu: .init(
                        get: { viewStore.showingMenu },
                        set: { viewStore.send(.toggleMenu($0)) }
                    ),
                    loadedAcquisition: viewStore.loadedAcquisition,
                    loadedAcquisitionDisplayName: viewStore.loadedAcquisitionDisplayName,
                    hasSelectedDocuments: viewStore.hasSelectedDocuments,
                    onNewAcquisition: {
                        viewStore.send(.startNewAcquisition)
                    },
                    onSAMGovLookup: {
                        viewStore.send(.showSAMGovLookup(true))
                    },
                    onExecuteAll: {
                        viewStore.send(.executeAllDocuments)
                    }
                )

                // Main Content
                DocumentGenerationView(
                    store: store.scope(
                        state: \.documentGeneration,
                        action: \.documentGeneration
                    ),
                    isChatMode: viewStore.isChatMode,
                    loadedAcquisition: viewStore.loadedAcquisition,
                    loadedAcquisitionDisplayName: viewStore.loadedAcquisitionDisplayName,
                    onShowDocumentScanner: {
                        viewStore.send(.showDocumentScanner(true))
                    }
                )
            }
            .modifier(NavigationBarHiddenModifier())
            .preferredColorScheme(.dark)
            .ignoresSafeArea(.keyboard) // Allow keyboard to overlay content

            // Menu overlay
            if viewStore.showingMenu {
                MenuView(
                    store: store,
                    isShowing: .init(
                        get: { viewStore.showingMenu },
                        set: { viewStore.send(.toggleMenu($0)) }
                    ),
                    selectedMenuItem: .init(
                        get: { viewStore.selectedMenuItem },
                        set: { viewStore.send(.selectMenuItem($0)) }
                    )
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
                .allowsHitTesting(true) // Ensure menu is interactive
            }
        }
        .onAppear {
            viewStore.send(.onAppear)
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingProfile },
            set: { viewStore.send(.showProfile($0)) }
        )) {
            SwiftUI.NavigationView {
                ProfileView(
                    store: store.scope(
                        state: \.profile,
                        action: \.profile
                    )
                )
            }
            .aikoSheet()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingAcquisitions },
            set: { viewStore.send(.showAcquisitions($0)) }
        )) {
            SwiftUI.NavigationView {
                AcquisitionsListView(
                    store: store.scope(
                        state: \.acquisitionsList,
                        action: \.acquisitionsList
                    )
                )
            }
            .aikoSheet()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingUserGuide },
            set: { viewStore.send(.showUserGuide($0)) }
        )) {
            SwiftUI.NavigationView {
                UserGuideView()
            }
            .aikoSheet()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingSearchTemplates },
            set: { viewStore.send(.showSearchTemplates($0)) }
        )) {
            SearchDocumentTemplatesView()
                .aikoSheet()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingSettings },
            set: { viewStore.send(.showSettings($0)) }
        )) {
            SettingsView(
                store: store.scope(
                    state: \.settings,
                    action: \.settings
                )
            )
            .aikoSheet()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingDownloadOptions },
            set: { _ in viewStore.send(.hideDownloadOptions) }
        )) {
            if let acquisition = viewStore.downloadTargetAcquisition {
                DownloadOptionsSheet(
                    acquisition: acquisition,
                    onDismiss: { viewStore.send(.hideDownloadOptions) }
                )
            }
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingAcquisitionChat },
            set: { viewStore.send(.showAcquisitionChat($0)) }
        )) {
            AcquisitionChatView(
                store: store.scope(
                    state: \.acquisitionChat,
                    action: \.acquisitionChat
                )
            )
            .aikoSheet()
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingSAMGovLookup },
            set: { viewStore.send(.showSAMGovLookup($0)) }
        )) {
            SAMGovLookupView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .aikoSheet()
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingDocumentScanner },
            set: { viewStore.send(.showDocumentScanner($0)) }
        )) {
            #if os(iOS)
            DocumentScannerView(
                store: store.scope(
                    state: \.documentScanner,
                    action: \.documentScanner
                )
            )
            .aikoSheet()
            #else
            Text("Document scanning is not available on macOS")
                .font(.title)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aikoSheet()
            #endif
        }
        .sheet(isPresented: .init(
            get: { viewStore.showingDocumentSelection },
            set: { _ in viewStore.send(.hideDocumentSelection) }
        )) {
            DocumentSelectionSheet(
                acquisitionId: viewStore.shareTargetAcquisitionId,
                selectedDocuments: viewStore.selectedDocumentsForShare,
                onToggleDocument: { docId in
                    viewStore.send(.toggleDocumentForShare(docId))
                },
                onConfirm: {
                    viewStore.send(.confirmShareSelection)
                },
                onCancel: {
                    viewStore.send(.hideDocumentSelection)
                }
            )
            .aikoSheet()
        }
        #if os(iOS)
        .sheet(isPresented: .init(
            get: { viewStore.showingShareSheet },
            set: { _ in viewStore.send(.dismissShareSheet) }
        )) {
            ShareSheetView(items: viewStore.shareItems)
        }
        #endif
    }
}

struct HeaderView: View {
    @Binding var showMenu: Bool
    let loadedAcquisition: Acquisition?
    let loadedAcquisitionDisplayName: String?
    let hasSelectedDocuments: Bool
    let onNewAcquisition: () -> Void
    let onSAMGovLookup: () -> Void
    let onExecuteAll: () -> Void

    private func loadSAMIcon() -> Image? {
        // For Swift Package, load from module bundle
        guard let url = Bundle.module.url(forResource: "SAMIcon", withExtension: "png") else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        #if os(iOS)
            if let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
        #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            }
        #endif

        return nil
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // App Icon on the left - same as AppIconPreview
            AppIconView()
                .frame(width: 50, height: 50)

            Spacer()

            // Icon buttons evenly spaced
            HStack(spacing: Theme.Spacing.lg) {
                // SAM.gov lookup button (moved to left)
                Button(action: onSAMGovLookup) {
                    if let samIcon = loadSAMIcon() {
                        samIcon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .frame(width: 40, height: 40)
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "text.badge.checkmark")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.aikoPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                            )
                    }
                }

                // Execute all button
                Button(action: onExecuteAll) {
                    Image(systemName: hasSelectedDocuments ? "play.fill" : "play")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.aikoPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                        )
                }
                .disabled(!hasSelectedDocuments)

                // New acquisition button
                Button(action: onNewAcquisition) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.aikoPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                        )
                }

                // Menu button
                Button(action: { showMenu.toggle() }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.aikoPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                        )
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Color.black)
    }
}

public struct DocumentGenerationView: View {
    let store: StoreOf<DocumentGenerationFeature>
    let isChatMode: Bool
    let loadedAcquisition: Acquisition?
    let loadedAcquisitionDisplayName: String?
    let onShowDocumentScanner: () -> Void

    public init(
        store: StoreOf<DocumentGenerationFeature>, 
        isChatMode: Bool = false, 
        loadedAcquisition: Acquisition? = nil, 
        loadedAcquisitionDisplayName: String? = nil,
        onShowDocumentScanner: @escaping () -> Void = {}
    ) {
        self.store = store
        self.isChatMode = isChatMode
        self.loadedAcquisition = loadedAcquisition
        self.loadedAcquisitionDisplayName = loadedAcquisitionDisplayName
        self.onShowDocumentScanner = onShowDocumentScanner
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            mainContent(viewStore)
        }
    }

    @ViewBuilder
    private func mainContent(_ viewStore: ViewStore<DocumentGenerationFeature.State, DocumentGenerationFeature.Action>) -> some View {
        VStack(spacing: 0) {
                // Main Content Area
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        // Chat History (if in chat mode with acquisition)
                        if isChatMode, loadedAcquisition != nil, !viewStore.analysis.conversationHistory.isEmpty {
                            ChatHistoryView(
                                messages: viewStore.analysis.conversationHistory,
                                isLoading: viewStore.analysis.isAnalyzingRequirements
                            )
                        }

                        // Workflow Prompts Section (if workflow is active)
                        if viewStore.analysis.workflowContext != nil {
                            WorkflowPromptsView(
                                store: store.scope(
                                    state: \.analysis,
                                    action: \.analysis
                                )
                            )
                        }

                        // Document Chain View (if chain exists)
                        if viewStore.analysis.documentChain != nil {
                            DocumentChainView(
                                chainProgress: viewStore.analysis.documentChain,
                                validation: viewStore.analysis.chainValidation,
                                onSelectDocument: { documentType in
                                    // Add document to selected types
                                    viewStore.send(.documentTypeToggled(documentType))
                                }
                            )
                        }

                        // Document Types Section
                        DocumentTypesSection(
                            documentTypes: DocumentType.allCases,
                            selectedTypes: viewStore.selectedDocumentTypes,
                            selectedDFTypes: viewStore.status.selectedDFDocumentTypes,
                            documentStatus: viewStore.status.documentReadinessStatus,
                            hasAcquisition: loadedAcquisition != nil,
                            loadedAcquisitionDisplayName: loadedAcquisitionDisplayName,
                            onTypeToggled: { documentType in
                                viewStore.send(.documentTypeToggled(documentType))
                            },
                            onDFTypeToggled: { dfDocumentType in
                                viewStore.send(.status(.dfDocumentTypeToggled(dfDocumentType)))
                            },
                            onExecuteCategory: { category in
                                viewStore.send(.executeCategory(category))
                            }
                        )

                        Spacer(minLength: 100)
                    }
                    .padding(Theme.Spacing.lg)
                }
                .background(Theme.Colors.aikoBackground)
                .scrollContentBackground(.hidden) // iOS 16+
                .scrollDismissesKeyboard(.interactively) // iOS 16+

                // Input Area
                InputArea(
                    requirements: viewStore.requirements,
                    isGenerating: viewStore.isGenerating,
                    uploadedDocuments: viewStore.analysis.uploadedDocuments,
                    isChatMode: isChatMode,
                    isRecording: viewStore.analysis.isRecording,
                    onRequirementsChanged: { requirements in
                        viewStore.send(.requirementsChanged(requirements))
                    },
                    onAnalyzeRequirements: {
                        viewStore.send(.analyzeRequirements)
                    },
                    onEnhancePrompt: {
                        viewStore.send(.analysis(.enhancePrompt))
                    },
                    onStartRecording: {
                        viewStore.send(.analysis(.startVoiceRecording))
                    },
                    onStopRecording: {
                        viewStore.send(.analysis(.stopVoiceRecording))
                    },
                    onShowDocumentPicker: {
                        viewStore.send(.analysis(.showDocumentPicker(true)))
                    },
                    onShowImagePicker: {
                        onShowDocumentScanner()
                    },
                    onRemoveDocument: { documentId in
                        viewStore.send(.analysis(.removeUploadedDocument(documentId)))
                    }
                )
            }
            // Removed LLMConfirmationDialog - now using Agentic Chat Interface
            // when documents need more information
            .sheet(isPresented: .init(
                get: { viewStore.analysis.showingDocumentRecommendation },
                set: { viewStore.send(.analysis(.showDocumentRecommendation($0))) }
            )) {
                DocumentRecommendationDialog(store: store)
            }
            .sheet(isPresented: .init(
                get: { viewStore.delivery.showingDeliveryOptions },
                set: { viewStore.send(.delivery(.showDeliveryOptions($0))) }
            )) {
                DeliveryOptionsDialog(store: store)
            }
            .sheet(isPresented: .init(
                get: { viewStore.delivery.showingEmailConfirmation },
                set: { viewStore.send(.delivery(.showEmailConfirmation($0))) }
            )) {
                EmailConfirmationDialog(store: store)
            }
            .sheet(isPresented: .init(
                get: { viewStore.analysis.showingDocumentPicker },
                set: { viewStore.send(.analysis(.showDocumentPicker($0))) }
            )) {
                DocumentPickerView(store: store)
            }
            .sheet(isPresented: .init(
                get: { viewStore.analysis.showingImagePicker },
                set: { viewStore.send(.analysis(.showImagePicker($0))) }
            )) {
                ImagePickerView(store: store)
            }
            .sheet(isPresented: .init(
                get: { viewStore.analysis.showingAutomationSettings },
                set: { viewStore.send(.analysis(.toggleAutomationSettings($0))) }
            )) {
                AutomationSettingsSheet(
                    settings: .init(
                        get: { viewStore.analysis.automationSettings },
                        set: { viewStore.send(.analysis(.updateAutomationSettings($0))) }
                    ),
                    onDismiss: {
                        viewStore.send(.analysis(.toggleAutomationSettings(false)))
                    }
                )
            }
            .sheet(isPresented: .init(
                get: { viewStore.execution.showingExecutionView },
                set: { viewStore.send(.execution(.showExecutionView($0))) }
            )) {
                DocumentExecutionView(
                    store: store.scope(
                        state: \.execution,
                        action: \.execution
                    )
                )
            }
            .sheet(isPresented: .init(
                get: { viewStore.execution.showingFARUpdatesView },
                set: { viewStore.send(.execution(.showFARUpdatesView($0))) }
            )) {
                FARUpdatesView()
            }
        }
    }

struct DocumentTypesSection: View {
    let documentTypes: [DocumentType]
    let selectedTypes: Set<DocumentType>
    let selectedDFTypes: Set<DFDocumentType>
    let documentStatus: [DocumentType: DocumentStatusFeature.DocumentStatus]
    let hasAcquisition: Bool
    let loadedAcquisitionDisplayName: String?
    let onTypeToggled: (DocumentType) -> Void
    let onDFTypeToggled: (DFDocumentType) -> Void
    let onExecuteCategory: (DocumentCategory) -> Void

    @State private var expandedCategories: Set<DocumentCategory> = []

    func filteredDocumentTypes(for category: DocumentCategory) -> [DocumentType] {
        category.documentTypes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Acquisition name if loaded - centered
            if let acquisitionName = loadedAcquisitionDisplayName {
                HStack {
                    Spacer()
                    Text(acquisitionName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            }

            // Header with search
            HStack(spacing: Theme.Spacing.sm) {
                Label("Document Types", systemImage: "folder")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.aikoPrimary)

                // Status indicator - moved after Document Types
                Circle()
                    .fill(hasAcquisition ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // Category folders
            VStack(spacing: Theme.Spacing.md) {
                ForEach(DocumentCategory.allCases, id: \.self) { category in
                    DocumentCategoryFolder(
                        category: category,
                        isExpanded: expandedCategories.contains(category),
                        documentTypes: filteredDocumentTypes(for: category),
                        selectedTypes: selectedTypes,
                        selectedDFTypes: selectedDFTypes,
                        documentStatus: documentStatus,
                        hasAcquisition: hasAcquisition,
                        onToggleExpanded: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if expandedCategories.contains(category) {
                                    expandedCategories.remove(category)
                                } else {
                                    expandedCategories.insert(category)
                                }
                            }
                        },
                        onTypeToggled: onTypeToggled,
                        onDFTypeToggled: onDFTypeToggled,
                        onExecute: {
                            onExecuteCategory(category)
                        }
                    )
                }
            }
        }
    }
}

struct DocumentCategoryFolder: View {
    let category: DocumentCategory
    let isExpanded: Bool
    let documentTypes: [DocumentType]
    let selectedTypes: Set<DocumentType>
    let selectedDFTypes: Set<DFDocumentType>
    let documentStatus: [DocumentType: DocumentStatusFeature.DocumentStatus]
    let hasAcquisition: Bool
    let onToggleExpanded: () -> Void
    let onTypeToggled: (DocumentType) -> Void
    let onDFTypeToggled: (DFDocumentType) -> Void
    let onExecute: () -> Void

    var selectedCount: Int {
        if category == .determinationFindings {
            selectedDFTypes.count
        } else {
            documentTypes.filter { selectedTypes.contains($0) }.count
        }
    }

    var readyCount: Int {
        documentTypes.filter { documentStatus[$0] == .ready }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Folder header
            Button(action: onToggleExpanded) {
                HStack(spacing: Theme.Spacing.lg) {
                    // Category icon
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(Theme.Colors.aikoPrimary)
                        .frame(width: 32, height: 32)

                    // Category info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            // Status badges
                            if selectedCount > 0 {
                                Text("\(selectedCount) selected")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.Colors.aikoPrimary)
                                    .cornerRadius(8)
                            }

                            if readyCount > 0 {
                                Text("\(readyCount) ready")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }

                            // Execute button (only show if documents are selected)
                            if selectedCount > 0 {
                                Button(action: onExecute) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }

                            // Expand/collapse arrow
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        }

                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)

                        // Document count
                        if category == .determinationFindings {
                            Text("\(DFDocumentType.allCases.count) document types")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(documentTypes.count) document types")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .fill(Theme.Colors.aikoSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                .stroke(selectedCount > 0 ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                if category == .determinationFindings {
                    // Show D&F document type cards
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(DFDocumentType.allCases) { dfDocumentType in
                            DFDocumentTypeCard(
                                dfDocumentType: dfDocumentType,
                                isSelected: selectedDFTypes.contains(dfDocumentType),
                                hasAcquisition: hasAcquisition,
                                onToggle: {
                                    onDFTypeToggled(dfDocumentType)
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .animation(.easeInOut(duration: 0.3), value: DFDocumentType.allCases)
                } else {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(documentTypes) { documentType in
                            DocumentTypeCard(
                                documentType: documentType,
                                isSelected: selectedTypes.contains(documentType),
                                isAvailable: true, // All features unlocked
                                status: documentStatus[documentType] ?? .notReady,
                                onToggle: { onTypeToggled(documentType) }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .animation(.easeInOut(duration: 0.3), value: documentTypes)
                }
            }
        }
    }
}

struct ChatHistoryView: View {
    let messages: [String]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Chat History")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                    ChatMessageBubble(
                        message: message,
                        isUser: message.hasPrefix("User:"),
                        isLoading: isLoading && index == messages.count - 1
                    )
                }

                if isLoading, !messages.isEmpty, !messages.last!.hasPrefix("User:") {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                        Text("AIKO is thinking...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Colors.aikoSecondary.opacity(0.5))
            )
        }
    }
}

struct ChatMessageBubble: View {
    let message: String
    let isUser: Bool
    let isLoading: Bool

    var cleanMessage: String {
        if isUser {
            message.replacingOccurrences(of: "User: ", with: "")
        } else {
            message.replacingOccurrences(of: "AIKO: ", with: "")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "You" : "AIKO")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                DocumentRichTextView(content: cleanMessage)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(isUser ? Theme.Colors.aikoAccent : Theme.Colors.aikoSecondary)
                    )
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if isUser {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.aikoPrimary)
                    .frame(width: 24, height: 24)
            }
        }
    }
}

struct QuickActionsSection: View {
    let onQuickAction: (QuickAction) -> Void

    enum QuickAction: String, CaseIterable {
        case startNewProject = "Start New Project"
        case fullPackage = "Generate Full Package"
        case quickAnalysis = "Quick Analysis"

        var icon: String {
            switch self {
            case .startNewProject: "plus.circle.fill"
            case .fullPackage: "doc.on.doc.fill"
            case .quickAnalysis: "bolt.fill"
            }
        }

        var description: String {
            switch self {
            case .startNewProject: "Begin with requirements gathering"
            case .fullPackage: "Generate all recommended documents"
            case .quickAnalysis: "Quick market & competition check"
            }
        }

        var color: Color {
            switch self {
            case .startNewProject: .blue
            case .fullPackage: .green
            case .quickAnalysis: .orange
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(QuickAction.allCases, id: \.self) { action in
                        QuickActionCard(
                            action: action,
                            onTap: { onQuickAction(action) }
                        )
                    }
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let action: QuickActionsSection.QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(action.color)
                    Spacer()
                }

                Text(action.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(Theme.Spacing.lg)
            .frame(width: 180, height: 100)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Colors.aikoSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .stroke(action.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct DFDocumentTypeCard: View {
    let dfDocumentType: DFDocumentType
    let isSelected: Bool
    let hasAcquisition: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.md) {
                // Status indicator - Red when no acquisition loaded
                Circle()
                    .fill(hasAcquisition ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                // Icon
                Image(systemName: dfDocumentType.icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)

                // Document name only
                Text(dfDocumentType.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // FAR Reference
                Text(dfDocumentType.farReference)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                    .font(.body)
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Fixed single-field height
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Theme.Colors.aikoSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct DocumentTypeCard: View {
    let documentType: DocumentType
    let isSelected: Bool
    let isAvailable: Bool
    let status: DocumentStatusFeature.DocumentStatus
    let onToggle: () -> Void

    var statusColor: Color {
        switch status {
        case .notReady: .red
        case .needsMoreInfo: .yellow
        case .ready: .green
        }
    }

    func statusText(for status: DocumentStatusFeature.DocumentStatus) -> String {
        switch status {
        case .notReady: "Not Ready"
        case .needsMoreInfo: "Needs Info"
        case .ready: "Ready"
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.md) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                // Icon
                Image(systemName: documentType.icon)
                    .font(.body)
                    .foregroundColor(isAvailable ? .blue : .secondary)
                    .frame(width: 20, height: 20)

                // Document name only
                Text(documentType.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // FAR Reference
                Text(documentType.farReference)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                    .font(.body)
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Fixed single-field height
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Theme.Colors.aikoSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(isAvailable ? 1.0 : 0.6)
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct UploadedDocumentCard: View {
    let document: UploadedDocument
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: fileIcon(for: document.fileName))
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(formattedFileSize(document.data.count))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.aikoSecondary)
        )
    }

    func fileIcon(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "jpg", "jpeg", "png": return "photo.fill"
        default: return "doc.fill"
        }
    }

    func formattedFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct InputArea: View {
    let requirements: String
    let isGenerating: Bool
    let uploadedDocuments: [UploadedDocument]
    let isChatMode: Bool
    let isRecording: Bool
    let onRequirementsChanged: (String) -> Void
    let onAnalyzeRequirements: () -> Void
    let onEnhancePrompt: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onShowDocumentPicker: () -> Void
    let onShowImagePicker: () -> Void
    let onRemoveDocument: (UploadedDocument.ID) -> Void

    @State private var showingUploadOptions = false
    @State private var chatMessages: [ChatMessage] = []

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date = .init()
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: Theme.Spacing.md) {
                // Uploaded Documents
                if !uploadedDocuments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(uploadedDocuments) { document in
                                UploadedDocumentCard(
                                    document: document,
                                    onRemove: { onRemoveDocument(document.id) }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                    .frame(height: 60)
                }
                // Input container
                HStack(spacing: 0) {
                    // Text input field with custom placeholder
                    ZStack(alignment: .leading) {
                        TextField("", text: .init(
                            get: { requirements },
                            set: onRequirementsChanged
                        ), prompt: Text("...").foregroundColor(.gray), axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding(.leading, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                            .padding(.trailing, Theme.Spacing.sm)
                            .lineLimit(1 ... 4)
                    }

                    // Action buttons
                    HStack(spacing: Theme.Spacing.sm) {
                        // Enhance prompt button
                        Button(action: {
                            if !requirements.isEmpty {
                                onEnhancePrompt()
                            }
                        }) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundColor(!requirements.isEmpty ? .yellow : .secondary)
                                .frame(width: 32, height: 32)
                                .scaleEffect(!requirements.isEmpty ? 1.0 : 0.9)
                                .animation(.easeInOut(duration: 0.2), value: requirements.isEmpty)
                        }
                        .disabled(requirements.isEmpty || isGenerating)

                        // Upload options
                        Button(action: { showingUploadOptions.toggle() }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                        }
                        .confirmationDialog("Add Content", isPresented: $showingUploadOptions) {
                            Button(" Upload Documents") {
                                onShowDocumentPicker()
                            }
                            #if os(iOS)
                                Button("📷 Scan Document") {
                                    onShowImagePicker()
                                }
                            #endif
                            Button("Cancel", role: .cancel) {}
                        }

                        // Voice input
                        Button(action: {
                            if isRecording {
                                onStopRecording()
                            } else {
                                onStartRecording()
                            }
                        }) {
                            Image(systemName: isRecording ? "mic.fill" : "mic")
                                .font(.title3)
                                .foregroundColor(isRecording ? .red : .secondary)
                                .frame(width: 32, height: 32)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isRecording)
                        }
                        .disabled(isGenerating && !isRecording)

                        // Analyze button
                        Button(action: onAnalyzeRequirements) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: requirements.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(requirements.isEmpty ? .secondary : .white)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .background(
                            Group {
                                if !requirements.isEmpty || !uploadedDocuments.isEmpty, !isGenerating {
                                    Circle()
                                        .fill(Theme.Colors.aikoPrimary)
                                } else {
                                    Circle()
                                        .fill(Color.clear)
                                }
                            }
                        )
                        .disabled((requirements.isEmpty && uploadedDocuments.isEmpty) || isGenerating)
                        .scaleEffect(requirements.isEmpty ? 1.0 : 1.1)
                        .animation(.easeInOut(duration: 0.2), value: requirements.isEmpty)
                    }
                    .padding(.trailing, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.Colors.aikoSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .background(Color.black)
        }
    }
}

// MARK: - Document and Image Picker Views

struct DocumentPickerView: View {
    let store: StoreOf<DocumentGenerationFeature>

    var body: some View {
        DocumentPicker { documents in
            ViewStore(store, observe: { $0 }).send(.analysis(.uploadDocuments(documents)))
        }
    }
}

struct ImagePickerView: View {
    let store: StoreOf<DocumentGenerationFeature>

    var body: some View {
        #if os(iOS)
            if #available(iOS 16.0, *) {
                DocumentScanner { scannedDocuments in
                    ViewStore(store, observe: { $0 }).send(.analysis(.uploadDocuments(scannedDocuments)))
                }
            } else {
                // Fallback for older iOS versions - single image capture
                ImagePicker { imageData in
                    let documents = [(imageData, "Scanned_Document.jpg")]
                    ViewStore(store, observe: { $0 }).send(.analysis(.uploadDocuments(documents)))
                }
            }
        #else
            Text("Document scanning not available on macOS")
        #endif
    }
}

#if os(iOS)
    struct DocumentPicker: UIViewControllerRepresentable {
        let onDocumentsPicked: ([(Data, String)]) -> Void

        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
                .pdf,
                .plainText,
                .rtf,
                UTType("com.microsoft.word.doc") ?? .data,
                UTType("org.openxmlformats.wordprocessingml.document") ?? .data,
            ])
            picker.delegate = context.coordinator
            picker.allowsMultipleSelection = true
            return picker
        }

        func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UIDocumentPickerDelegate {
            let parent: DocumentPicker

            init(_ parent: DocumentPicker) {
                self.parent = parent
            }

            func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                var documents: [(Data, String)] = []

                for url in urls {
                    do {
                        // Start accessing the security-scoped resource
                        guard url.startAccessingSecurityScopedResource() else {
                            print("Failed to access security-scoped resource")
                            continue
                        }

                        defer {
                            url.stopAccessingSecurityScopedResource()
                        }

                        let data = try Data(contentsOf: url)
                        let fileName = url.lastPathComponent
                        documents.append((data, fileName))
                    } catch {
                        print("Error reading document \(url.lastPathComponent): \(error)")
                    }
                }

                if !documents.isEmpty {
                    DispatchQueue.main.async {
                        self.parent.onDocumentsPicked(documents)
                    }
                }
            }
        }
    }

    @available(iOS 16.0, *)
    struct DocumentScanner: UIViewControllerRepresentable {
        let onDocumentsScanned: ([(Data, String)]) -> Void

        func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = context.coordinator
            return scannerViewController
        }

        func updateUIViewController(_: VNDocumentCameraViewController, context _: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
            let parent: DocumentScanner

            init(_ parent: DocumentScanner) {
                self.parent = parent
            }

            func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
                var documents: [(Data, String)] = []

                for pageIndex in 0 ..< scan.pageCount {
                    let scannedImage = scan.imageOfPage(at: pageIndex)
                    if let imageData = scannedImage.jpegData(compressionQuality: 0.8) {
                        let fileName = "Scanned_Document_\(pageIndex + 1).jpg"
                        documents.append((imageData, fileName))
                    }
                }

                if !documents.isEmpty {
                    DispatchQueue.main.async {
                        self.parent.onDocumentsScanned(documents)
                    }
                }

                controller.dismiss(animated: true)
            }

            func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
                controller.dismiss(animated: true)
            }

            func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
                print("Document scanning failed: \(error)")
                controller.dismiss(animated: true)
            }
        }
    }

    // Fallback for older iOS versions
    struct ImagePicker: UIViewControllerRepresentable {
        let onImagePicked: (Data) -> Void

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            picker.allowsEditing = false
            return picker
        }

        func updateUIViewController(_: UIImagePickerController, context _: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker

            init(_ parent: ImagePicker) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let image = info[.originalImage] as? UIImage,
                   let imageData = image.jpegData(compressionQuality: 0.8)
                {
                    DispatchQueue.main.async {
                        self.parent.onImagePicked(imageData)
                    }
                }
                picker.dismiss(animated: true)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }
    }

#else
    // macOS implementations
    struct DocumentPicker: View {
        let onDocumentsPicked: ([(Data, String)]) -> Void

        var body: some View {
            Text("Document picking not yet implemented for macOS")
        }
    }

    struct ImagePicker: View {
        let onImagePicked: (Data) -> Void

        var body: some View {
            Text("Image picking not yet implemented for macOS")
        }
    }
#endif

// MARK: - Menu View

struct MenuView: View {
    let store: StoreOf<AppFeature>
    @Binding var isShowing: Bool
    @Binding var selectedMenuItem: AppFeature.MenuItem?

    #if os(iOS)
        @State private var profileImage: UIImage?
        @State private var showingImagePicker = false
    #else
        @State private var profileImage: NSImage?
    #endif
    @State private var showingImageSourceDialog = false

    // Extract profile button into computed property
    @ViewBuilder
    private var profileButton: some View {
        Button(action: { showingImageSourceDialog = true }) {
            ZStack {
                profileImageView
                cameraIconOverlay
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showingImageSourceDialog) {
            photoSourceButtons
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let image = profileImage {
            #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                    )
            #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                    )
            #endif
        } else {
            Circle()
                .fill(Theme.Colors.aikoSecondary)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var cameraIconOverlay: some View {
        Circle()
            .fill(Theme.Colors.aikoPrimary)
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "camera.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            )
            .offset(x: 20, y: 20)
    }

    @ViewBuilder
    private var photoSourceButtons: some View {
        #if os(iOS)
            Button("Select Photo") {
                showingImagePicker = true
            }
        #endif
        if profileImage != nil {
            Button("Remove Photo", role: .destructive) {
                profileImage = nil
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    private var profileSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            profileButton

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("AIKO User")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    @ViewBuilder
    private var menuContent: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Safe area spacer for Dynamic Island/notch
                Color.black
                    .frame(height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)

                profileSection

                Divider()
                    .background(Color.gray.opacity(0.3))

                menuItemsList

                Spacer()

                // Footer
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Divider()
                        .background(Color.gray.opacity(0.3))

                    Text("AIKO v1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("AI Contract Intelligence Officer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(Theme.Spacing.lg)
                .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(
                Color.black
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.05),
                                Color.clear,
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .edgesIgnoringSafeArea(.vertical)
        }
        .frame(width: 300)
    }

    @ViewBuilder
    private var menuItemsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                WithViewStore(store, observe: { $0 }) { viewStore in
                    ForEach(AppFeature.MenuItem.allCases, id: \.self) { item in
                        if item == .quickReferences {
                            quickReferencesSection(viewStore: viewStore, item: item)
                        } else {
                            regularMenuItem(item: item)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
    }

    @ViewBuilder
    private func quickReferencesSection(viewStore: ViewStore<AppFeature.State, AppFeature.Action>, item: AppFeature.MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            quickReferencesButton(viewStore: viewStore, item: item)

            if viewStore.showingQuickReferences {
                quickReferencesSubmenu(viewStore: viewStore)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewStore.showingQuickReferences)
    }

    private func quickReferencesButton(viewStore: ViewStore<AppFeature.State, AppFeature.Action>, item: AppFeature.MenuItem) -> some View {
        Button(action: {
            viewStore.send(.toggleQuickReferences(!viewStore.showingQuickReferences))
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(Theme.Colors.aikoPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.rawValue)
                        .font(.subheadline)
                        .fontWeight(viewStore.showingQuickReferences ? .semibold : .regular)
                        .foregroundColor(.white)

                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: viewStore.showingQuickReferences ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(viewStore.showingQuickReferences ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func quickReferencesSubmenu(viewStore: ViewStore<AppFeature.State, AppFeature.Action>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ForEach(AppFeature.QuickReference.allCases, id: \.self) { reference in
                quickReferenceButton(reference: reference, viewStore: viewStore)
            }
        }
    }

    private func quickReferenceButton(reference: AppFeature.QuickReference, viewStore: ViewStore<AppFeature.State, AppFeature.Action>) -> some View {
        Button(action: {
            viewStore.send(.selectQuickReference(reference))
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: reference.icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reference.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Text(reference.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.6))
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.leading, Theme.Spacing.xl + Theme.Spacing.md)
            .padding(.trailing, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(Color.blue.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }

    private func regularMenuItem(item: AppFeature.MenuItem) -> some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            MenuItemRow(
                item: item,
                isSelected: selectedMenuItem == item,
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewStore.send(.selectMenuItem(item))
                        isShowing = false
                    }
                }
            )
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Tap outside to close
            Color.black.opacity(0.3)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
                .frame(width: 100)

            // Menu content
            menuContent
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            ProfileImagePicker(
                onImageSelected: { data in
                    if let uiImage = UIImage(data: data) {
                        profileImage = uiImage
                    }
                }
            )
        }
        #endif
    }
}

struct MenuItemRow: View {
    let item: AppFeature.MenuItem
    let isSelected: Bool
    let action: () -> Void

    @ViewBuilder
    var rowContent: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.aikoPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }

    var body: some View {
        Button(action: action) {
            rowContent
        }
        .buttonStyle(.plain)
    }
}

// ProfileImagePicker is imported from ProfileComponents

// MARK: - Download Options Sheet

struct DownloadOptionsSheet: View {
    let acquisition: Acquisition
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedDocuments: Set<UUID> = []
    @State private var isDownloading = false
    @State private var downloadError: String?

    var generatedFiles: [GeneratedFile] {
        acquisition.generatedFilesArray
    }

    var body: some View {
        SwiftUI.NavigationView {
            VStack(spacing: 0) {
                if generatedFiles.isEmpty {
                    DocumentsEmptyStateView()
                } else {
                    List {
                        Section {
                            ForEach(generatedFiles, id: \.id) { file in
                                DocumentDownloadRow(
                                    file: file,
                                    isSelected: selectedDocuments.contains(file.id!),
                                    onToggle: {
                                        if selectedDocuments.contains(file.id!) {
                                            selectedDocuments.remove(file.id!)
                                        } else {
                                            selectedDocuments.insert(file.id!)
                                        }
                                    }
                                )
                            }
                        } header: {
                            HStack {
                                Text("Available Documents")
                                Spacer()
                                Button(selectedDocuments.count == generatedFiles.count ? "Deselect All" : "Select All") {
                                    if selectedDocuments.count == generatedFiles.count {
                                        selectedDocuments.removeAll()
                                    } else {
                                        selectedDocuments = Set(generatedFiles.compactMap(\.id))
                                    }
                                }
                                .font(.caption)
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(InsetGroupedListStyle())
                    #else
                    .listStyle(PlainListStyle())
                    #endif

                    // Download buttons
                    VStack(spacing: Theme.Spacing.md) {
                        if !selectedDocuments.isEmpty {
                            Button(action: downloadSelected) {
                                Label(
                                    selectedDocuments.count == 1 ? "Download Selected Document" : "Download \(selectedDocuments.count) Documents",
                                    systemImage: "arrow.down.doc"
                                )
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.aikoPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(Theme.CornerRadius.md)
                            }
                        }

                        Button(action: downloadAll) {
                            Label("Download All Documents", systemImage: "arrow.down.doc.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.aikoAccent)
                                .foregroundColor(.white)
                                .cornerRadius(Theme.CornerRadius.md)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Download Documents")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .alert("Download Error", isPresented: .init(
                    get: { downloadError != nil },
                    set: { _ in downloadError = nil }
                )) {
                    Button("OK") {}
                } message: {
                    if let error = downloadError {
                        Text(error)
                    }
                }
                .overlay {
                    if isDownloading {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .overlay {
                                ProgressView("Downloading...")
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(Theme.CornerRadius.md)
                            }
                    }
                }
        }
    }

    private func downloadSelected() {
        let filesToDownload = generatedFiles.filter { file in
            selectedDocuments.contains(file.id!)
        }
        downloadDocuments(filesToDownload)
    }

    private func downloadAll() {
        downloadDocuments(generatedFiles)
    }

    private func downloadDocuments(_ documents: [GeneratedFile]) {
        isDownloading = true

        #if os(iOS)
            // Create a temporary directory for the documents
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // Write each document to the temp directory
                for document in documents {
                    guard let data = document.content,
                          let fileName = document.fileName else { continue }

                    let fileURL = tempDir.appendingPathComponent(fileName)
                    try data.write(to: fileURL)
                }

                // Present the share sheet
                let activityVC = UIActivityViewController(
                    activityItems: documents.count == 1
                        ? [tempDir.appendingPathComponent(documents[0].fileName!)]
                        : [tempDir],
                    applicationActivities: nil
                )

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController
                {
                    rootVC.present(activityVC, animated: true) {
                        isDownloading = false
                    }
                }
            } catch {
                downloadError = "Failed to prepare documents: \(error.localizedDescription)"
                isDownloading = false
            }
        #else
            // macOS implementation would use NSSavePanel
            isDownloading = false
        #endif
    }
}

struct DocumentDownloadRow: View {
    let file: GeneratedFile
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .secondary)
                .onTapGesture {
                    onToggle()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(file.fileName ?? "Untitled Document")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack {
                    Text(file.fileType ?? "Unknown Type")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let size = file.content?.count {
                        Text(formatFileSize(size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct DocumentsEmptyStateView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Documents Available")
                .font(.headline)
                .foregroundColor(.primary)

            Text("This acquisition doesn't have any generated documents yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
    }
}

// MARK: - Document Selection Sheet

struct DocumentSelectionSheet: View {
    let acquisitionId: UUID?
    let selectedDocuments: Set<UUID>
    let onToggleDocument: (UUID) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Dependency(\.acquisitionService) var acquisitionService
    @State private var acquisition: Acquisition?
    @State private var isLoading = true

    var body: some View {
        SwiftUI.NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading documents...")
                        .frame(maxHeight: .infinity)
                } else if let acquisition {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        Text("Select Documents to Share")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top)

                        Text(acquisition.title ?? "Untitled Acquisition")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                            .padding(.bottom)

                        // Document list
                        if acquisition.documentsArray.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No documents available")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(acquisition.documentsArray, id: \.id) { document in
                                        DocumentSelectionRow(
                                            document: document,
                                            isSelected: selectedDocuments.contains(document.id ?? UUID()),
                                            onToggle: {
                                                if let docId = document.id {
                                                    onToggleDocument(docId)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                        }

                        // Bottom actions
                        HStack(spacing: 16) {
                            Button("Cancel") {
                                onCancel()
                            }
                            .foregroundColor(.red)

                            Spacer()

                            Text("\(selectedDocuments.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Share") {
                                onConfirm()
                            }
                            .fontWeight(.semibold)
                            .disabled(selectedDocuments.isEmpty)
                        }
                        .padding()
                        .background(Theme.Colors.aikoBackground)
                    }
                } else {
                    Text("Unable to load acquisition")
                        .frame(maxHeight: .infinity)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .background(Color.black)
            .task {
                await loadAcquisition()
            }
        }
    }

    private func loadAcquisition() async {
        guard let acquisitionId else {
            isLoading = false
            return
        }

        do {
            acquisition = try await acquisitionService.fetchAcquisition(acquisitionId)
            isLoading = false
        } catch {
            print("Failed to load acquisition: \(error)")
            isLoading = false
        }
    }
}

struct DocumentSelectionRow: View {
    let document: AcquisitionDocument
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.aikoPrimary : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.documentType ?? "Untitled Document")
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Text(document.documentType ?? "Unknown Type")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let date = document.createdDate {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.aikoPrimary.opacity(0.2) : Theme.Colors.aikoSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if os(iOS)
    struct ShareSheetView: UIViewControllerRepresentable {
        let items: [Any]

        func makeUIViewController(context _: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: items, applicationActivities: nil)
        }

        func updateUIViewController(_: UIActivityViewController, context _: Context) {}
    }
#endif

#if DEBUG
    struct AppView_Previews: PreviewProvider {
        static var previews: some View {
            var state = AppFeature.State()
            state.isOnboardingCompleted = true
            state.isAuthenticated = true

            return AppView(
                store: Store(
                    initialState: state
                ) {
                    AppFeature()
                        .dependency(\.biometricAuthenticationService, .previewValue)
                        .dependency(\.settingsManager, .previewValue)
                }
            )
            .preferredColorScheme(.dark)
        }
    }
#endif

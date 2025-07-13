import ComposableArchitecture
import SwiftUI
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

// MARK: - Enhanced App View with UI/UX Improvements

public struct EnhancedAppView: View {
    let store: StoreOf<AppFeature>

    @StateObject private var hapticManager = HapticManager.shared
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    contentView
                        .navigationBarHidden(true)
                }
                .preferredColorScheme(.dark)
                .tint(.white)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
            } else {
                SwiftUI.NavigationView {
                    contentView
                        .navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .preferredColorScheme(.dark)
                .dynamicTypeSize(.xSmall ... DynamicTypeSize.accessibility3)
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
            ZStack {
                // Animated background gradient
                AnimatedGradientBackground()

                if !viewStore.isOnboardingCompleted {
                    onboardingView
                        .pageTransition(isActive: true, from: .trailing)
                } else if !viewStore.isAuthenticated {
                    authenticationView(viewStore: viewStore)
                        .pageTransition(isActive: true, from: .bottom)
                } else {
                    mainContentView(viewStore: viewStore)
                        .pageTransition(isActive: true, from: .trailing)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert(
            store: store.scope(state: \.$errorAlert, action: \.errorAlert)
        )
        .onVoiceOverStatusChanged { isEnabled in
            if isEnabled {
                AccessibilityAnnouncement.announce("AIKO App is ready. Swipe to navigate.", priority: .high)
            }
        }
    }

    // MARK: - View Components

    private var onboardingView: some View {
        OnboardingView(
            store: store.scope(
                state: \.onboarding,
                action: \.onboarding
            )
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
        .accessibilityElement(
            label: "Onboarding",
            hint: "Complete the setup process"
        )
    }

    private func authenticationView(viewStore: ViewStore<AppFeature.State, AppFeature.Action>) -> some View {
        FaceIDAuthenticationView(
            isAuthenticating: viewStore.isAuthenticating,
            error: viewStore.authenticationError,
            onRetry: {
                HapticManager.shared.impact(.medium)
                viewStore.send(.authenticateWithFaceID)
            }
        )
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
        .accessibilityElement(
            label: "Authentication Required",
            hint: "Use Face ID or enter passcode to continue"
        )
    }

    @ViewBuilder
    private func mainContentView(viewStore: ViewStore<AppFeature.State, AppFeature.Action>) -> some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 0) {
                // Enhanced Header
                EnhancedHeaderView(
                    showMenu: .init(
                        get: { viewStore.showingMenu },
                        set: { viewStore.send(.toggleMenu($0)) }
                    ),
                    loadedAcquisition: viewStore.loadedAcquisition,
                    loadedAcquisitionDisplayName: viewStore.loadedAcquisitionDisplayName,
                    hasSelectedDocuments: viewStore.hasSelectedDocuments,
                    onNewAcquisition: {
                        HapticManager.shared.successAction()
                        viewStore.send(.startNewAcquisition)
                    },
                    onSAMGovLookup: {
                        HapticManager.shared.impact(.light)
                        viewStore.send(.showSAMGovLookup(true))
                    },
                    onExecuteAll: {
                        HapticManager.shared.notification(.success)
                        viewStore.send(.executeAllDocuments)
                    }
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Navigation Header")

                // Enhanced Document Generation View
                EnhancedDocumentGenerationView(
                    store: store.scope(
                        state: \.documentGeneration,
                        action: \.documentGeneration
                    ),
                    isChatMode: viewStore.isChatMode,
                    loadedAcquisition: viewStore.loadedAcquisition,
                    loadedAcquisitionDisplayName: viewStore.loadedAcquisitionDisplayName
                )
            }
            .modifier(NavigationBarHiddenModifier())
            .preferredColorScheme(.dark)
            .ignoresSafeArea(.keyboard)

            // Enhanced Menu overlay with glassmorphism
            if viewStore.showingMenu {
                Rectangle()
                    .fill(SwiftUI.Color(white: 0, opacity: 0.3))
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewStore.send(.toggleMenu(false), animation: AnimationSystem.Spring.smooth)
                    }

                EnhancedMenuView(
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
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? .linear(duration: 0.1) : AnimationSystem.Spring.smooth,
            value: viewStore.showingMenu
        )
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
            .accessibilityAddTraits(.isModal)
        }
        // Add remaining sheets with accessibility support...
    }
}

// MARK: - Enhanced Header View

struct EnhancedHeaderView: View {
    @Binding var showMenu: Bool
    let loadedAcquisition: Acquisition?
    let loadedAcquisitionDisplayName: String?
    let hasSelectedDocuments: Bool
    let onNewAcquisition: () -> Void
    let onSAMGovLookup: () -> Void
    let onExecuteAll: () -> Void

    @State private var logoScale: CGFloat = 1.0
    @Environment(\.sizeCategory) private var sizeCategory

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
        HStack(spacing: 0) {
            // Animated AIKO Logo
            ResponsiveText(content: "AIKO", style: .largeTitle)
                .foregroundStyle(
                    Theme.Colors.aikoPrimary
                )
                .scaleEffect(logoScale)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        logoScale = 1.05
                    }
                }
                .accessibilityLabel("AIKO - AI Contract Intelligence Officer")

            Spacer()

            // Acquisition name with animation
            if let displayName = loadedAcquisitionDisplayName {
                ResponsiveText(content: displayName, style: .headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 200)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Current acquisition: \(displayName)")

                Spacer()
            }

            // Enhanced action buttons
            DynamicStack {
                // Execute all button with pulse animation
                AnimatedButton(action: onExecuteAll) {
                    Image(systemName: hasSelectedDocuments ? "play.fill" : "play")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.aikoPrimary)
                                .shadow(color: Theme.Colors.aikoPrimary.opacity(0.3), radius: hasSelectedDocuments ? 8 : 0)
                        )
                }
                .disabled(!hasSelectedDocuments)
                .opacity(hasSelectedDocuments ? 1.0 : 0.6)
                .accessibleButton(
                    label: "Execute all documents",
                    hint: hasSelectedDocuments ? "Tap to generate selected documents" : "No documents selected"
                )
                .pulse(duration: 2.0, scale: 1.1)
                .opacity(hasSelectedDocuments ? 1.0 : 0.6)

                // New acquisition button
                AnimatedButton(action: onNewAcquisition) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.aikoPrimary)
                        )
                }
                .accessibleButton(
                    label: "New acquisition",
                    hint: "Start a new acquisition"
                )

                // SAM.gov lookup button
                AnimatedButton(action: onSAMGovLookup) {
                    Group {
                        if let samIcon = loadSAMIcon() {
                            samIcon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black)
                                        .overlay(
                                            Circle()
                                                .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                                        )
                                )
                        } else {
                            Text("SAM")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Theme.Colors.aikoPrimary)
                                )
                        }
                    }
                }
                .accessibleButton(
                    label: "SAM.gov lookup",
                    hint: "Search SAM.gov database"
                )

                // Menu button with rotation animation
                AnimatedButton(action: { showMenu.toggle() }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.aikoPrimary)
                        )
                        .rotationEffect(.degrees(showMenu ? 90 : 0))
                }
                .accessibleButton(
                    label: "Menu",
                    hint: showMenu ? "Close menu" : "Open menu"
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            GlassmorphicView {
                Color.black
            }
        )
    }
}

// MARK: - Enhanced Document Generation View

struct EnhancedDocumentGenerationView: View {
    let store: StoreOf<DocumentGenerationFeature>
    let isChatMode: Bool
    let loadedAcquisition: Acquisition?
    let loadedAcquisitionDisplayName: String?

    @State private var scrollOffset: CGFloat = 0
    @Environment(\.sizeCategory) private var sizeCategory

    struct ViewState: Equatable {
        let analysisConversationHistory: [String]
        let analysisIsAnalyzingRequirements: Bool
        let analysisUploadedDocuments: [UploadedDocument]
        let analysisIsRecording: Bool
        let requirements: String
        let isGenerating: Bool
        let selectedDocumentTypes: Set<DocumentType>
        let selectedDFDocumentTypes: Set<DFDocumentType>
        let documentReadinessStatus: [DocumentType: DocumentStatusFeature.DocumentStatus]
        
        init(state: DocumentGenerationFeature.State) {
            self.analysisConversationHistory = state.analysis.conversationHistory
            self.analysisIsAnalyzingRequirements = state.analysis.isAnalyzingRequirements
            self.analysisUploadedDocuments = state.analysis.uploadedDocuments
            self.analysisIsRecording = state.analysis.isRecording
            self.requirements = state.requirements
            self.isGenerating = state.isGenerating
            self.selectedDocumentTypes = state.selectedDocumentTypes
            self.selectedDFDocumentTypes = state.status.selectedDFDocumentTypes
            self.documentReadinessStatus = state.status.documentReadinessStatus
        }
    }
    
    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            VStack(spacing: 0) {
                // Main Content Area with parallax effect
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        // Content sections with enhanced animations
                        Group {
                            if isChatMode, loadedAcquisition != nil, !viewStore.analysisConversationHistory.isEmpty {
                                EnhancedChatHistoryView(
                                    messages: viewStore.analysisConversationHistory,
                                    isLoading: viewStore.analysisIsAnalyzingRequirements
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .scale(scale: 1.1).combined(with: .opacity)
                                ))
                            }

                            // Enhanced document selection
                            EnhancedDocumentTypesSection(
                                documentTypes: DocumentType.allCases,
                                selectedTypes: viewStore.selectedDocumentTypes,
                                selectedDFTypes: viewStore.selectedDFDocumentTypes,
                                documentStatus: viewStore.documentReadinessStatus,
                                hasAcquisition: loadedAcquisition != nil,
                                onTypeToggled: { documentType in
                                    HapticManager.shared.selection()
                                    viewStore.send(.documentTypeToggled(documentType))
                                },
                                onDFTypeToggled: { dfDocumentType in
                                    HapticManager.shared.selection()
                                    viewStore.send(.status(.dfDocumentTypeToggled(dfDocumentType)))
                                },
                                onExecuteCategory: { category in
                                    HapticManager.shared.notification(.success)
                                    viewStore.send(.executeCategory(category))
                                }
                            )
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(Theme.Spacing.lg)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .background(Theme.Colors.aikoBackground)

                // Enhanced Input Area
                InputArea(
                    requirements: viewStore.requirements,
                    isGenerating: viewStore.isGenerating,
                    uploadedDocuments: viewStore.analysisUploadedDocuments,
                    isChatMode: isChatMode,
                    isRecording: viewStore.analysisIsRecording,
                    onRequirementsChanged: { requirements in
                        viewStore.send(.requirementsChanged(requirements))
                    },
                    onAnalyzeRequirements: {
                        HapticManager.shared.impact(.medium)
                        viewStore.send(.analyzeRequirements)
                    },
                    onEnhancePrompt: {
                        HapticManager.shared.impact(.light)
                        viewStore.send(.analysis(.enhancePrompt))
                    },
                    onStartRecording: {
                        HapticManager.shared.impact(.medium)
                        viewStore.send(.analysis(.startVoiceRecording))
                    },
                    onStopRecording: {
                        HapticManager.shared.impact(.light)
                        viewStore.send(.analysis(.stopVoiceRecording))
                    },
                    onShowDocumentPicker: {
                        HapticManager.shared.selection()
                        viewStore.send(.analysis(.showDocumentPicker(true)))
                    },
                    onShowImagePicker: {
                        HapticManager.shared.selection()
                        viewStore.send(.analysis(.showImagePicker(true)))
                    },
                    onRemoveDocument: { documentId in
                        HapticManager.shared.impact(.light)
                        viewStore.send(.analysis(.removeUploadedDocument(documentId)))
                    }
                )
            }
            // Add sheet presentations with transitions...
        }
    }
}

// MARK: - Enhanced Chat History

struct EnhancedChatHistoryView: View {
    let messages: [String]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ResponsiveText(content: "Chat History", style: .headline)
                .accessibleHeader(label: "Chat History", level: .h2)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                    EnhancedChatBubble(
                        message: message,
                        isUser: message.hasPrefix("User:"),
                        isLoading: isLoading && index == messages.count - 1
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: message.hasPrefix("User:") ? .bottomTrailing : .bottomLeading)
                            .combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        LoadingDotsView(dotSize: 8, color: .blue)
                        ResponsiveText(content: "AIKO is thinking...", style: .caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .accessibilityLabel("AIKO is processing your request")
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                EnhancedCard(content: {
                    Color.clear
                }, style: .glassmorphism)
            )
        }
    }
}

// MARK: - Enhanced Chat Bubble

struct EnhancedChatBubble: View {
    let message: String
    let isUser: Bool
    let isLoading: Bool

    @State private var showMessage = false

    var cleanMessage: String {
        if isUser {
            message.replacingOccurrences(of: "User: ", with: "")
        } else {
            message.replacingOccurrences(of: "AIKO: ", with: "")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            if !isUser {
                ZStack {
                    Circle()
                        .fill(
                            Color.blue.opacity(0.3)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .pulse(duration: 2.0, scale: 1.1)
                .accessibilityHidden(true)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                ResponsiveText(
                    content: isUser ? "You" : "AIKO",
                    style: .caption
                )
                .foregroundColor(.secondary)

                ResponsiveText(content: cleanMessage, style: .body)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(isUser ? Theme.Colors.aikoAccent : Theme.Colors.aikoSecondary)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    )
                    .scaleEffect(showMessage ? 1.0 : 0.8)
                    .opacity(showMessage ? 1.0 : 0.0)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if isUser {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }
        }
        .onAppear {
            withAnimation(AnimationSystem.Spring.bouncy.delay(0.1)) {
                showMessage = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "AIKO") said: \(cleanMessage)")
    }
}

// MARK: - Enhanced Document Types Section

struct EnhancedDocumentTypesSection: View {
    let documentTypes: [DocumentType]
    let selectedTypes: Set<DocumentType>
    let selectedDFTypes: Set<DFDocumentType>
    let documentStatus: [DocumentType: DocumentStatusFeature.DocumentStatus]
    let hasAcquisition: Bool
    let onTypeToggled: (DocumentType) -> Void
    let onDFTypeToggled: (DFDocumentType) -> Void
    let onExecuteCategory: (DocumentCategory) -> Void

    @State private var expandedCategories: Set<DocumentCategory> = []
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                Label("Document Types", systemImage: "folder")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.aikoPrimary)
                    .accessibleHeader(label: "Document Types", level: .h2)

                Spacer()

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Theme.Colors.aikoSecondary)
                )
                .frame(maxWidth: 200)
                .transition(.scale.combined(with: .opacity))
            }

            // Category cards with enhanced styling
            VStack(spacing: Theme.Spacing.md) {
                ForEach(DocumentCategory.allCases, id: \.self) { category in
                    EnhancedDocumentCategoryCard(
                        category: category,
                        isExpanded: expandedCategories.contains(category),
                        documentTypes: filteredDocumentTypes(for: category),
                        selectedTypes: selectedTypes,
                        selectedDFTypes: selectedDFTypes,
                        documentStatus: documentStatus,
                        hasAcquisition: hasAcquisition,
                        onToggleExpanded: {
                            withAnimation(AnimationSystem.Spring.snappy) {
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

    func filteredDocumentTypes(for category: DocumentCategory) -> [DocumentType] {
        let types = category.documentTypes
        if searchText.isEmpty {
            return types
        }
        return types.filter { type in
            type.shortName.localizedCaseInsensitiveContains(searchText) ||
                type.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Enhanced Document Category Card

struct EnhancedDocumentCategoryCard: View {
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

    @State private var isHovered = false

    var selectedCount: Int {
        if category == .determinationFindings {
            selectedDFTypes.count
        } else {
            documentTypes.filter { selectedTypes.contains($0) }.count
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced folder header
            Button(action: {
                HapticManager.shared.selection()
                onToggleExpanded()
            }) {
                HStack(spacing: Theme.Spacing.lg) {
                    // Animated category icon
                    ZStack {
                        Circle()
                            .fill(
                                category.color.opacity(0.2)
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundColor(Theme.Colors.aikoPrimary)
                            .rotationEffect(.degrees(isExpanded ? 15 : 0))
                    }
                    .scaleEffect(isHovered ? 1.1 : 1.0)

                    // Category info with dynamic type
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            ResponsiveText(content: category.rawValue, style: .headline)
                                .foregroundColor(.white)

                            Spacer()

                            // Enhanced status badges
                            if selectedCount > 0 {
                                EnhancedStatusBadge(
                                    text: "\(selectedCount) selected",
                                    color: .blue,
                                    icon: "checkmark.circle.fill"
                                )
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Execute button with animation
                            if selectedCount > 0 {
                                AnimatedButton(action: onExecute) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .scaleEffect(1.0)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Animated chevron
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        }

                        ResponsiveText(content: category.description, style: .caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(
                    EnhancedCard(
                        content: {
                            Color.clear
                        },
                        style: selectedCount > 0 ? .gradient : .elevated,
                        isInteractive: true
                    )
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(AnimationSystem.microScale) {
                    isHovered = hovering
                }
            }
            .accessibilityElement(
                label: "\(category.rawValue). \(selectedCount) documents selected",
                hint: isExpanded ? "Tap to collapse" : "Tap to expand",
                traits: .isButton
            )

            // Expanded document list with staggered animation
            if isExpanded {
                if category == .determinationFindings {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(Array(DFDocumentType.allCases.enumerated()), id: \.element) { index, dfType in
                            EnhancedDFDocumentCard(
                                dfDocumentType: dfType,
                                isSelected: selectedDFTypes.contains(dfType),
                                hasAcquisition: hasAcquisition,
                                onToggle: {
                                    onDFTypeToggled(dfType)
                                }
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                        .animation(AnimationSystem.Spring.bouncy.delay(Double(index) * 0.05)),
                                    removal: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                )
                            )
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                } else {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(Array(documentTypes.enumerated()), id: \.element) { index, docType in
                            EnhancedDocumentTypeCard(
                                documentType: docType,
                                isSelected: selectedTypes.contains(docType),
                                isAvailable: true,
                                status: documentStatus[docType] ?? .notReady,
                                onToggle: { onTypeToggled(docType) }
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                        .animation(AnimationSystem.Spring.bouncy.delay(Double(index) * 0.05)),
                                    removal: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                )
                            )
                        }
                    }
                    .padding(.top, Theme.Spacing.sm)
                }
            }
        }
    }
}

// MARK: - Enhanced Status Badge Component

struct EnhancedStatusBadge: View {
    let text: String
    let color: Color
    let icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color)
                .shadow(color: color.opacity(0.3), radius: 4, y: 2)
        )
    }
}

// MARK: - Enhanced Document Cards

struct EnhancedDocumentTypeCard: View {
    let documentType: DocumentType
    let isSelected: Bool
    let isAvailable: Bool
    let status: DocumentStatusFeature.DocumentStatus
    let onToggle: () -> Void

    @State private var isPressed = false

    var body: some View {
        AnimatedButton(action: onToggle) {
            HStack(spacing: Theme.Spacing.md) {
                // Animated status indicator
                StatusIndicator(status: status)
                    .accessibilityLabel("Status: \(status.accessibilityLabel)")

                // Document icon with subtle animation
                Image(systemName: documentType.icon)
                    .font(.body)
                    .foregroundColor(isAvailable ? .blue : .secondary)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isSelected ? 360 : 0))
                    .animation(AnimationSystem.Spring.bouncy, value: isSelected)

                // Document info
                VStack(alignment: .leading, spacing: 2) {
                    ResponsiveText(content: documentType.shortName, style: .subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    ResponsiveText(content: documentType.farReference, style: .caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Animated checkmark
                if isSelected {
                    AnimatedCheckmark(size: 20, color: .green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.body)
                        .frame(width: 20, height: 20)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                EnhancedCard(
                    content: {
                        Color.clear
                    },
                    style: isSelected ? .gradient : .elevated,
                    isInteractive: true
                )
            )
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .accessibilityElement(
            label: "\(documentType.shortName). \(documentType.farReference)",
            hint: isSelected ? "Selected. Tap to deselect" : "Tap to select",
            traits: [.isButton, isSelected ? .isSelected : []].reduce([]) { $0.union($1) }
        )
    }
}

struct EnhancedDFDocumentCard: View {
    let dfDocumentType: DFDocumentType
    let isSelected: Bool
    let hasAcquisition: Bool
    let onToggle: () -> Void

    var body: some View {
        AnimatedButton(action: onToggle) {
            HStack(spacing: Theme.Spacing.md) {
                // Status with pulse animation when no acquisition
                StatusIndicator(
                    status: hasAcquisition ? .ready : .notReady,
                    pulse: !hasAcquisition
                )

                // Icon
                Image(systemName: dfDocumentType.icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)

                // Document info
                VStack(alignment: .leading, spacing: 2) {
                    ResponsiveText(content: dfDocumentType.shortName, style: .subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    ResponsiveText(content: dfDocumentType.farReference, style: .caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    AnimatedCheckmark(size: 20, color: .green)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.body)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                EnhancedCard(
                    content: {
                        Color.clear
                    },
                    style: isSelected ? .gradient : .elevated,
                    isInteractive: true
                )
            )
        }
        .accessibilityElement(
            label: "\(dfDocumentType.shortName). \(dfDocumentType.farReference)",
            hint: hasAcquisition ?
                (isSelected ? "Selected. Tap to deselect" : "Tap to select") :
                "Acquisition required to select this document",
            traits: [.isButton, isSelected ? .isSelected : []].reduce([]) { $0.union($1) }
        )
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: DocumentStatusFeature.DocumentStatus
    var pulse: Bool = false

    var statusColor: Color {
        switch status {
        case .notReady: .red
        case .needsMoreInfo: .yellow
        case .ready: .green
        }
    }

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .shadow(color: statusColor.opacity(0.5), radius: 4)
            .pulse(duration: 1.5, scale: 1.5)
            .opacity(pulse ? 1.0 : 0.8)
    }
}

// MARK: - Enhanced Input Area

struct AppEnhancedInputArea: View {
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
    @State private var inputFieldHeight: CGFloat = 44
    @FocusState private var isInputFocused: Bool

    private var hasContent: Bool {
        !requirements.isEmpty || !uploadedDocuments.isEmpty
    }

    private var canAnalyze: Bool {
        hasContent && !isGenerating
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3 as Double))

            VStack(spacing: Theme.Spacing.md) {
                // Uploaded documents carousel
                if !uploadedDocuments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(uploadedDocuments) { document in
                                EnhancedUploadedDocumentCard(
                                    document: document,
                                    onRemove: { onRemoveDocument(document.id) }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                    .frame(height: 60)
                    .animation(AnimationSystem.Spring.smooth, value: uploadedDocuments)
                }

                // Enhanced input container
                HStack(spacing: 0) {
                    // Animated text input
                    ZStack(alignment: .leading) {
                        if requirements.isEmpty {
                            ResponsiveText(
                                content: isChatMode ?
                                    "How may I assist you with this acquisition?" :
                                    "Describe your project requirements...",
                                style: .body
                            )
                            .foregroundColor(.gray)
                            .padding(.leading, Theme.Spacing.lg)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                        }

                        TextField("", text: .init(
                            get: { requirements },
                            set: onRequirementsChanged
                        ), axis: .vertical)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .padding(.leading, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                            .padding(.trailing, Theme.Spacing.sm)
                            .lineLimit(1 ... 4)
                            .focused($isInputFocused)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: HeightPreferenceKey.self,
                                        value: geometry.size.height
                                    )
                                }
                            )
                    }

                    // Enhanced action buttons
                    HStack(spacing: Theme.Spacing.sm) {
                        // Enhance prompt with sparkle animation
                        AnimatedButton(action: {
                            if !requirements.isEmpty {
                                onEnhancePrompt()
                            }
                        }) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundColor(!requirements.isEmpty ? .yellow : .secondary)
                                .frame(width: 32, height: 32)
                                .shimmer(duration: 1.5, bounce: true)
                                .opacity(!requirements.isEmpty ? 1.0 : 0.6)
                        }
                        .disabled(requirements.isEmpty || isGenerating)
                        .accessibleButton(
                            label: "Enhance prompt",
                            hint: requirements.isEmpty ? "Enter text first" : "Improve your prompt with AI"
                        )

                        // Upload options with animation
                        AnimatedButton(action: { showingUploadOptions.toggle() }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(showingUploadOptions ? 45 : 0))
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
                        .accessibleButton(
                            label: "Add content",
                            hint: "Upload documents or scan"
                        )

                        // Voice input with pulse animation
                        AnimatedButton(action: {
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
                                .pulse(duration: 1.0, scale: 1.2)
                                .opacity(isRecording ? 1.0 : 0.8)
                        }
                        .disabled(isGenerating && !isRecording)
                        .accessibleButton(
                            label: isRecording ? "Stop recording" : "Start voice input",
                            hint: "Dictate your requirements"
                        )

                        // Analyze button with loading animation
                        AnimatedButton(action: onAnalyzeRequirements) {
                            ZStack {
                                if isGenerating {
                                    LoadingDotsView(dotSize: 6, color: .white)
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: requirements.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(requirements.isEmpty ? .secondary : .white)
                                        .frame(width: 32, height: 32)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    canAnalyze ?
                                        Theme.Colors.aikoPrimary :
                                        Color.clear
                                )
                                .shadow(
                                    color: Theme.Colors.aikoPrimary.opacity(0.3),
                                    radius: canAnalyze ? 8 : 0
                                )
                        )
                        .disabled(!canAnalyze)
                        .accessibleButton(
                            label: "Analyze",
                            hint: hasContent ?
                                "Submit for AI analysis" :
                                "Enter requirements or upload documents first"
                        )
                    }
                    .padding(.trailing, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.Colors.aikoSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    isInputFocused ?
                                        Theme.Colors.aikoPrimary :
                                        Color.gray.opacity(0.3),
                                    lineWidth: isInputFocused ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isInputFocused ?
                                Theme.Colors.aikoPrimary.opacity(0.2) :
                                Color.clear,
                            radius: 8
                        )
                )
                .onPreferenceChange(HeightPreferenceKey.self) { height in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        inputFieldHeight = height
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                GlassmorphicView {
                    Color.black
                }
            )
        }
        .animation(AnimationSystem.Spring.smooth, value: isInputFocused)
    }
}

// MARK: - Enhanced Uploaded Document Card

struct EnhancedUploadedDocumentCard: View {
    let document: UploadedDocument
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Animated file icon
            Image(systemName: fileIcon(for: document.fileName))
                .font(.title3)
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isHovered ? 10 : 0))

            VStack(alignment: .leading, spacing: 2) {
                ResponsiveText(content: document.fileName, style: .caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)

                ResponsiveText(
                    content: formattedFileSize(document.data.count),
                    style: .caption2
                )
                .foregroundColor(.secondary)
            }

            // Remove button with animation
            AnimatedButton(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.scale)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            EnhancedCard(content: {
                Color.clear
            }, style: .elevated)
        )
        .onHover { hovering in
            withAnimation(AnimationSystem.microScale) {
                isHovered = hovering
            }
        }
        .accessibilityElement(
            label: "Uploaded file: \(document.fileName), size: \(formattedFileSize(document.data.count))",
            hint: "Swipe to remove"
        )
        .accessibilityCustomActions([
            AccessibilityActionModifier.AccessibilityAction(
                name: "Remove",
                action: onRemove
            ),
        ])
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

// MARK: - Enhanced Menu View

struct EnhancedMenuView: View {
    let store: StoreOf<AppFeature>
    @Binding var isShowing: Bool
    @Binding var selectedMenuItem: AppFeature.MenuItem?

    #if os(iOS)
        @State private var profileImage: UIImage?
    #else
        @State private var profileImage: NSImage?
    #endif
    @State private var menuOffset: CGFloat = 300

    var body: some View {
        HStack(spacing: 0) {
            // Backdrop
            Color.clear
            #if os(iOS)
                .frame(width: UIScreen.main.bounds.width - 300)
            #else
                .frame(width: 1000) // Default width for macOS
            #endif
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(AnimationSystem.Spring.smooth) {
                        isShowing = false
                    }
                }

            // Menu content with glassmorphism
            GlassmorphicView {
                VStack(spacing: 0) {
                    // Profile section
                    EnhancedProfileSection(profileImage: $profileImage)
                        .padding(Theme.Spacing.lg)

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    // Menu items with enhanced styling
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            WithViewStore(store, observe: { $0 }) { viewStore in
                                ForEach(AppFeature.MenuItem.allCases, id: \.self) { item in
                                    EnhancedMenuItemRow(
                                        item: item,
                                        isSelected: selectedMenuItem == item,
                                        action: {
                                            HapticManager.shared.selection()
                                            withAnimation(AnimationSystem.Spring.smooth) {
                                                viewStore.send(.selectMenuItem(item))
                                                isShowing = false
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(Theme.Spacing.md)
                    }

                    Spacer()

                    // Footer with version info
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Divider()
                            .background(Color.gray.opacity(0.3))

                        HStack {
                            VStack(alignment: .leading) {
                                ResponsiveText(content: "AIKO v1.0.0", style: .caption2)
                                    .foregroundColor(.secondary)
                                ResponsiveText(
                                    content: "AI Contract Intelligence Officer",
                                    style: .caption2
                                )
                                .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Theme toggle
                            Image(systemName: "moon.stars.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .frame(width: 300)
            .offset(x: menuOffset)
            .onAppear {
                withAnimation(AnimationSystem.Spring.smooth) {
                    menuOffset = 0
                }
            }
            .onDisappear {
                menuOffset = 300
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation Menu")
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Helper Views and Extensions

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        Color.black.opacity(0.95)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 10.0)
                        .repeatForever(autoreverses: true)
                ) {
                    animateGradient.toggle()
                }
            }
    }
}

// Preference Keys
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 44
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension DocumentCategory {
    var color: Color {
        switch self {
        case .requirements: .blue
        case .marketIntelligence: .orange
        case .planning: .purple
        case .determinationFindings: .yellow
        case .solicitation: .green
        case .award: .red
        case .analytics: .indigo
        case .resourcesTools: .gray
        }
    }
}

extension DocumentStatusFeature.DocumentStatus {
    var accessibilityLabel: String {
        switch self {
        case .notReady: "Not ready"
        case .needsMoreInfo: "Needs more information"
        case .ready: "Ready to generate"
        }
    }
}

// MARK: - Enhanced Profile Section

struct EnhancedProfileSection: View {
    #if os(iOS)
        @Binding var profileImage: UIImage?
    #else
        @Binding var profileImage: NSImage?
    #endif

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Profile image with animation
            ZStack {
                Circle()
                    .fill(
                        Theme.Colors.aikoPrimary.opacity(0.3)
                    )
                    .frame(width: 80, height: 80)

                if let profileImage {
                    #if os(iOS)
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    #else
                        Image(nsImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    #endif
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: Theme.Colors.aikoPrimary.opacity(0.3), radius: 8, y: 4)

            // User info
            VStack(spacing: 4) {
                ResponsiveText(content: "User", style: .title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                ResponsiveText(content: "user@example.com", style: .caption)
                    .foregroundColor(.secondary)
            }

            // Quick stats
            HStack(spacing: Theme.Spacing.xl) {
                VStack {
                    ResponsiveText(content: "12", style: .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    ResponsiveText(content: "Projects", style: .caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    ResponsiveText(content: "48", style: .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    ResponsiveText(content: "Documents", style: .caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile section")
    }
}

// MARK: - Enhanced Menu Item Row

struct EnhancedMenuItemRow: View {
    let item: AppFeature.MenuItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        AnimatedButton(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon with animation
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(isHovered ? 10 : 0))

                // Label
                ResponsiveText(content: item.rawValue, style: .body)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? .white : .gray)

                Spacer()

                // Selection indicator
                if isSelected {
                    Rectangle()
                        .fill(Theme.Colors.aikoPrimary)
                        .frame(width: 3)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.aikoPrimary.opacity(0.2) : Color.clear)
                    .animation(AnimationSystem.Spring.smooth, value: isSelected)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AnimationSystem.microScale) {
                isHovered = hovering
            }
        }
        .accessibilityElement(
            label: item.rawValue,
            hint: isSelected ? "Currently selected" : "Tap to select",
            traits: [.isButton, isSelected ? .isSelected : []].reduce([]) { $0.union($1) }
        )
    }
}

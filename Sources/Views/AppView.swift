import SwiftUI
import AppCore
import Foundation

/// Main AppView using native SwiftUI with @Observable AppViewModel
/// This replaces the TCA-based AppView implementation
public struct AppView: View {
    @State private var appViewModel = AppViewModel()
    
    public init() {}
    
    public var body: some View {
        #if os(iOS)
        iOSAppView(viewModel: appViewModel)
        #elseif os(macOS)
        macOSAppView(viewModel: appViewModel)
        #endif
    }
}

// MARK: - iOS Implementation

#if os(iOS)
import UIKit
import UniformTypeIdentifiers
import VisionKit

public struct iOSAppView: View {
    @Bindable var viewModel: AppViewModel
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            mainContent
                .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $viewModel.showingDocumentScanner) {
            DocumentScannerSheet(viewModel: viewModel.documentScannerViewModel)
        }
        .sheet(isPresented: $viewModel.showingProfile) {
            ProfileSheet(viewModel: viewModel.profileViewModel)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsSheet(viewModel: viewModel.settingsViewModel)
        }
        .sheet(isPresented: $viewModel.showingAcquisitions) {
            AcquisitionsSheet(viewModel: viewModel.acquisitionsListViewModel)
        }
        .sheet(isPresented: $viewModel.showingSAMGovLookup) {
            EnhancedSAMGovInterface(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAcquisitionChat) {
            AgentChatInterface(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .alert("Authentication Error", isPresented: .constant(viewModel.authenticationError != nil)) {
            Button("Retry") {
                viewModel.authenticateWithFaceID()
            }
            Button("Cancel", role: .cancel) {
                viewModel.authenticationError = nil
            }
        } message: {
            Text(viewModel.authenticationError ?? "")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !viewModel.isOnboardingCompleted {
            OnboardingView(viewModel: viewModel.onboardingViewModel)
                .transition(.opacity)
        } else if !viewModel.isAuthenticated {
            AuthenticationView(
                isAuthenticating: viewModel.isAuthenticating,
                error: viewModel.authenticationError,
                onRetry: { viewModel.authenticateWithFaceID() }
            )
            .transition(.opacity)
        } else {
            MainContentView(viewModel: viewModel)
        }
    }
}

// MARK: - Main Content View

struct MainContentView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    showMenu: $viewModel.showingMenu,
                    loadedAcquisition: viewModel.loadedAcquisition,
                    loadedAcquisitionDisplayName: viewModel.loadedAcquisitionDisplayName,
                    hasSelectedDocuments: viewModel.hasSelectedDocuments,
                    onNewAcquisition: { viewModel.startNewAcquisition() },
                    onAgentChat: { viewModel.showingAcquisitionChat = true },
                    onSAMGovLookup: { viewModel.showSAMGovLookup(true) },
                    onExecuteAll: { viewModel.executeAllDocuments() }
                )
                
                // Main Content
                DocumentTypesCardView(viewModel: viewModel)
                
                // Original Input Area at bottom with integrated icons
                InputArea(
                    requirements: viewModel.requirements,
                    isGenerating: viewModel.isGenerating,
                    uploadedDocuments: viewModel.uploadedDocuments,
                    isChatMode: viewModel.isChatMode,
                    isRecording: viewModel.isRecording,
                    onRequirementsChanged: { viewModel.updateRequirements($0) },
                    onAnalyzeRequirements: { viewModel.analyzeRequirements() },
                    onEnhancePrompt: { viewModel.enhancePrompt() },
                    onStartRecording: { viewModel.startRecording() },
                    onStopRecording: { viewModel.stopRecording() },
                    onShowDocumentPicker: { viewModel.showDocumentPicker() },
                    onShowImagePicker: { viewModel.showImagePicker() },
                    onRemoveDocument: { viewModel.removeDocument($0) }
                )
            }
            
            // Side Menu
            if viewModel.showingMenu {
                SideMenuView(
                    viewModel: viewModel,
                    isShowing: $viewModel.showingMenu
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Header View - ORIGINAL EXACT IMPLEMENTATION

struct HeaderView: View {
    @Binding var showMenu: Bool
    let loadedAcquisition: AppCore.Acquisition?
    let loadedAcquisitionDisplayName: String?
    let hasSelectedDocuments: Bool
    let onNewAcquisition: () -> Void
    let onAgentChat: () -> Void
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
        HStack(spacing: Theme.Spacing.large) {
            // App Icon on the left - original design
            AppIconView()
                .frame(width: 50, height: 50)

            Spacer()

            // Icon buttons evenly spaced - ORIGINAL 4 HEADER ICONS
            HStack(spacing: Theme.Spacing.large) {
                // SAM.gov lookup button (first icon)
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

                // Execute all button (second icon)
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

                // New acquisition button (third icon)
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

                // Menu button (fourth icon)
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
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(Color.black)
    }
}

// MARK: - App Icon View Component - ORIGINAL EXACT IMPLEMENTATION

struct AppIconView: View {
    var body: some View {
        #if os(iOS)
            if let appIcon = loadAppIcon() {
                appIcon
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
        #else
            // macOS version
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.blue)
                .overlay(
                    Image(systemName: "scroll")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        #endif
    }
    
    private func loadAppIcon() -> Image? {
        #if os(iOS)
            // Try to load from bundle resources first
            if let image = UIImage(named: "AppIcon", in: Bundle.main, compatibleWith: nil) {
                return Image(uiImage: image)
            }
            
            // Fallback to direct file loading for development
            if let data = try? Data(contentsOf: URL(fileURLWithPath: "/Users/J/aiko/Sources/Resources/AppIcon.png")),
               let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
        #elseif os(macOS)
            // Try to load from bundle resources first
            if let image = NSImage(named: "AppIcon") {
                return Image(nsImage: image)
            }
            
            // Fallback to direct file loading for development
            if let data = try? Data(contentsOf: URL(fileURLWithPath: "/Users/J/aiko/Sources/Resources/AppIcon.png")),
               let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            }
        #endif
        
        return nil
    }
}

// MARK: - Side Menu View

struct SideMenuView: View {
    @Bindable var viewModel: AppViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                // Menu Header
                HStack {
                    Text("Menu")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isShowing = false }) {
                        Image(systemName: "xmark.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom)
                
                // Menu Items
                ForEach(MenuItem.allCases) { item in
                    MenuItemView(
                        item: item,
                        isSelected: viewModel.selectedMenuItem == item,
                        onTap: {
                            viewModel.selectMenuItem(item)
                        }
                    )
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 280)
            .background(Color.black.opacity(0.95))
            .roundedCorner(20, corners: [.topLeft, .bottomLeft])
        }
        .background(Color.black.opacity(0.3))
        .onTapGesture {
            isShowing = false
        }
    }
}

struct MenuItemView: View {
    let item: MenuItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: item.systemImage)
                    .frame(width: 24)
                    .foregroundColor(isSelected ? .blue : .white)
                
                Text(item.rawValue)
                    .foregroundColor(isSelected ? .blue : .white)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    let isAuthenticating: Bool
    let error: String?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon
            if let appIcon = loadAppIcon() {
                appIcon
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to AIKO")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Please authenticate to continue")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            if isAuthenticating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Authenticating...")
                    .font(.body)
                    .foregroundColor(.gray)
            } else {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Authenticate with Face ID")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    private func loadAppIcon() -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(named: "AppIcon") {
            return Image(uiImage: uiImage)
        }
        #endif
        return nil
    }
}

// MARK: - Document Types Card View

struct DocumentTypesCardView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DocumentTypesSection(
                    documentTypes: AppCore.DocumentType.allCases,
                    selectedTypes: viewModel.selectedTypes,
                    selectedDFTypes: viewModel.selectedDFTypes,
                    documentStatus: viewModel.documentStatus,
                    hasAcquisition: viewModel.hasAcquisition,
                    loadedAcquisitionDisplayName: viewModel.loadedAcquisitionDisplayName,
                    onTypeToggled: viewModel.toggleDocumentType,
                    onDFTypeToggled: viewModel.toggleDFDocumentType,
                    onExecuteCategory: viewModel.executeCategory
                )
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Sheet Views (Placeholder implementations)

struct DocumentScannerSheet: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Document Scanner")
                    .font(.title)
                
                if viewModel.isScanning {
                    ProgressView("Scanning...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button("Start Scanning") {
                        Task {
                            await viewModel.startScanning()
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ProfileSheet: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile")
                    .font(.title)
                
                Form {
                    TextField("Name", text: $viewModel.profile.fullName)
                    TextField("Email", text: $viewModel.profile.email)
                    TextField("Organization", text: $viewModel.profile.organizationName)
                }
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SettingsSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $viewModel.enableNotifications)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AcquisitionsSheet: View {
    @Bindable var viewModel: AcquisitionsListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredAcquisitions) { acquisition in
                    VStack(alignment: .leading) {
                        Text(acquisition.title.isEmpty ? "Untitled" : acquisition.title)
                            .font(.headline)
                        
                        if !acquisition.requirements.isEmpty {
                            Text(acquisition.requirements)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Acquisitions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SAMGovLookupSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("SAM.gov Lookup")
                    .font(.title)
                
                Text("Feature coming soon...")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("SAM.gov")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to AIKO")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                .font(.caption)
                .foregroundColor(.gray)
            
            ProgressView(value: Double(viewModel.currentStep) / Double(viewModel.totalSteps - 1))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
            
            Spacer()
            
            Text("Onboarding Step \(viewModel.currentStep + 1)")
                .font(.title2)
                .foregroundColor(.white)
            
            Spacer()
            
            HStack {
                if viewModel.currentStep > 0 {
                    Button("Previous") {
                        viewModel.previousStep()
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(viewModel.currentStep == viewModel.totalSteps - 1 ? "Complete" : "Next") {
                    viewModel.nextStep()
                }
                .foregroundColor(.blue)
                .fontWeight(.medium)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#endif

// MARK: - macOS Implementation

#if os(macOS)
public struct macOSAppView: View {
    @Bindable var viewModel: AppViewModel
    
    public init(viewModel: AppViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationView {
            // Sidebar
            List {
                ForEach(MenuItem.allCases) { item in
                    Button(action: {
                        viewModel.selectMenuItem(item)
                    }) {
                        Label(item.rawValue, systemImage: item.systemImage)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
            
            // Main Content
            if !viewModel.isOnboardingCompleted {
                VStack {
                    Text("Onboarding")
                    Button("Complete Onboarding") {
                        viewModel.onboardingViewModel.completeOnboarding()
                        viewModel.isOnboardingCompleted = true
                    }
                }
            } else if !viewModel.isAuthenticated {
                VStack {
                    Text("Authentication Required")
                    Button("Authenticate") {
                        viewModel.authenticateWithFaceID()
                    }
                }
            } else {
                VStack {
                    Text("Main Content")
                        .font(.title)
                    Text("Document generation will be available here")
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.onAppear()
        }
    }
}
#endif

// MARK: - View Extensions

#if os(iOS)
import UIKit

extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: Foundation.CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: Foundation.CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#else
extension View {
    func roundedCorner(_ radius: CGFloat, corners: String = "allCorners") -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
#endif

// MARK: - Preview

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
            .preferredColorScheme(.dark)
    }
}
#endif

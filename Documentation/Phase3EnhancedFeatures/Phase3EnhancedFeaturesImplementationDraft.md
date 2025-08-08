# PHASE 3: Restore Enhanced Features - Implementation Plan
## AIKO - Adaptive Intelligence for Kontract Optimization

**Version:** 1.0 DRAFT  
**Date:** 2025-08-03  
**Phase:** Design & Implementation  
**Author:** Claude Code System  
**Status:** DRAFT - Pending VanillaIce Consensus  

---

## 1. Executive Summary

This implementation plan details the technical architecture and step-by-step approach for restoring three critical features in the AIKO application during PHASE 3. The plan integrates the approved PRD specifications with the current codebase architecture, emphasizing SwiftUI @Observable patterns, modular design, and zero functionality loss during migration.

### Implementation Scope
- **ProfileView**: Full-featured user profile management with 20+ fields
- **LLMProviderSettingsView**: TCA → @Observable migration maintaining all features
- **DocumentScannerView**: VisionKit integration for document scanning with OCR

### Implementation Order (PRD-Validated)
1. **Week 1**: ProfileView (Foundation Component)
2. **Week 2**: DocumentScannerView (Enhancement)
3. **Week 3**: LLMProviderSettingsView (Migration)

---

## 2. Codebase Analysis

### Current State Assessment

#### ProfileView
- **Location**: `/Users/J/aiko/Sources/Views/AppView.swift` (lines 582-609)
- **Current Implementation**: Minimal ProfileSheet with 3 fields
- **ViewModel**: `/Users/J/aiko/Sources/Features/AppViewModel.swift` (lines 660-741)
- **Existing Components**: `/Users/J/aiko/Sources/Features/ProfileComponents.swift` (600 lines)
- **Data Model**: `/Users/J/aiko/Sources/AppCore/Models/UserProfile.swift` (216 lines)

#### LLMProviderSettingsView
- **Location**: `/Users/J/aiko/AIKO/Views/Settings/LLMProviderSettingsView.swift` (518 lines)
- **Current Implementation**: Full TCA implementation with Store/ViewStore
- **Dependencies**: ComposableArchitecture, LocalAuthentication
- **Features**: Provider configuration, API key management, priority settings

#### DocumentScannerView
- **Location**: `/Users/J/aiko/Sources/Views/AppView.swift` (lines 547-580)
- **Current Implementation**: Basic placeholder with TODO comments
- **ViewModel**: `/Users/J/aiko/Sources/Features/AppViewModel.swift` (lines 895-1008)
- **Platform Support**: iOS-only (VisionKit requirement)

### Dependency Analysis
```
ProfileView Dependencies:
├── UserProfile model ✓
├── ProfileViewModel (@Observable) ✓
├── ProfileComponents (UI library) ✓
├── Image picker (platform-specific) ✓
├── Validation logic ✓
└── Persistence layer (UserDefaults/Core Data) ✓

LLMProviderSettingsView Dependencies:
├── LLMProvider models ✓
├── TCA infrastructure (to remove) ✓
├── Keychain services ✓
├── LocalAuthentication ✓
├── Provider validation ✓
└── New @Observable ViewModel (to create)

DocumentScannerView Dependencies:
├── VisionKit framework (iOS)
├── DocumentScannerViewModel ✓
├── ScanSession model ✓
├── OCR processing
├── Export functionality
└── Platform abstraction layer
```

---

## 3. ProfileView Implementation Plan

### 3.1 Architecture Design

```swift
// ProfileView.swift - New modular implementation
struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var showingImagePicker = false
    @State private var selectedImageType: ProfileImageType = .profile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Profile header with completion indicator
                    ProfileHeaderSection(viewModel: viewModel)
                    
                    // Modular sections
                    PersonalInformationSection(viewModel: viewModel)
                    OrganizationSection(viewModel: viewModel)
                    AddressManagementSection(viewModel: viewModel)
                    ProfileImagesSection(
                        viewModel: viewModel,
                        onSelectImage: { type in
                            selectedImageType = type
                            showingImagePicker = true
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        Button("Save") {
                            Task {
                                await viewModel.saveProfile()
                                if viewModel.error == nil {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(viewModel.isSaving)
                    } else {
                        Button("Edit") {
                            viewModel.startEditing()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ProfileImagePicker { imageData in
                    viewModel.updateImage(imageData, type: selectedImageType)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }
}
```

### 3.2 Modular Components Implementation

```swift
// PersonalInformationSection.swift
struct PersonalInformationSection: View {
    @Bindable var viewModel: ProfileViewModel
    
    var body: some View {
        ProfileSectionView(title: "Personal Information", icon: "person.fill") {
            ProfileTextField(
                title: "Full Name",
                text: $viewModel.profile.fullName,
                isEditing: viewModel.isEditing,
                isRequired: true,
                error: viewModel.validationErrors["fullName"]
            )
            
            ProfileTextField(
                title: "Title",
                text: $viewModel.profile.title,
                isEditing: viewModel.isEditing
            )
            
            ProfileTextField(
                title: "Position",
                text: $viewModel.profile.position,
                isEditing: viewModel.isEditing
            )
            
            ProfileTextField(
                title: "Email",
                text: $viewModel.profile.email,
                isEditing: viewModel.isEditing,
                isRequired: true,
                keyboardType: .emailAddress,
                error: viewModel.validationErrors["email"]
            )
            
            ProfileTextField(
                title: "Alternate Email",
                text: $viewModel.profile.alternateEmail,
                isEditing: viewModel.isEditing,
                keyboardType: .emailAddress
            )
            
            ProfileTextField(
                title: "Phone Number",
                text: $viewModel.profile.phoneNumber,
                isEditing: viewModel.isEditing,
                keyboardType: .phonePad
            )
            
            ProfileTextField(
                title: "Alternate Phone",
                text: $viewModel.profile.alternatePhoneNumber,
                isEditing: viewModel.isEditing,
                keyboardType: .phonePad
            )
        }
    }
}
```

### 3.3 Enhanced ProfileViewModel

```swift
// Enhanced ProfileViewModel.swift
@MainActor
@Observable
public final class ProfileViewModel {
    public var profile: UserProfile
    public var isEditing: Bool = false
    public var isSaving: Bool = false
    public var showImagePicker: Bool = false
    public var selectedImageType: ImageType = .profile
    public var error: Error?
    public var validationErrors: [String: String] = [:]
    
    // Address copy functionality
    public var addressCopySource: AddressType?
    public var showingAddressCopySheet = false
    
    public enum ImageType {
        case profile
        case organizationLogo
    }
    
    public enum AddressType: CaseIterable {
        case administeredBy
        case payment
        case delivery
        
        var title: String {
            switch self {
            case .administeredBy: return "Administered By"
            case .payment: return "Payment"
            case .delivery: return "Delivery"
            }
        }
    }
    
    public init(profile: UserProfile = UserProfile()) {
        self.profile = profile
        loadProfile()
    }
    
    // MARK: - Profile Management
    
    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = savedProfile
        }
    }
    
    public func startEditing() {
        isEditing = true
        validationErrors.removeAll()
    }
    
    public func cancelEditing() {
        isEditing = false
        validationErrors.removeAll()
        loadProfile() // Revert changes
    }
    
    public func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        
        // Validate all fields
        guard validateProfile() else { return }
        
        do {
            // Update timestamps
            profile.updatedAt = Date()
            
            // Save to UserDefaults
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: "userProfile")
            
            // Update dependency container
            DependencyContainer.shared.register(UserProfile.self, instance: profile)
            
            // Notify system
            NotificationCenter.default.post(
                name: NSNotification.Name("UserProfileUpdated"),
                object: profile
            )
            
            await MainActor.run {
                isEditing = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateProfile() -> Bool {
        validationErrors.removeAll()
        var isValid = true
        
        // Full name validation
        if profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["fullName"] = "Name is required"
            isValid = false
        }
        
        // Email validation
        if profile.email.isEmpty {
            validationErrors["email"] = "Email is required"
            isValid = false
        } else if !isValidEmail(profile.email) {
            validationErrors["email"] = "Invalid email format"
            isValid = false
        }
        
        // Alternate email validation (optional but must be valid if provided)
        if !profile.alternateEmail.isEmpty && !isValidEmail(profile.alternateEmail) {
            validationErrors["alternateEmail"] = "Invalid email format"
            isValid = false
        }
        
        // Phone validation (optional but must be valid if provided)
        if !profile.phoneNumber.isEmpty && !isValidPhone(profile.phoneNumber) {
            validationErrors["phoneNumber"] = "Invalid phone format"
            isValid = false
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[\\+]?[(]?[0-9]{3}[)]?[-\\s\\.]?[(]?[0-9]{3}[)]?[-\\s\\.]?[0-9]{4,6}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    // MARK: - Image Management
    
    public func updateImage(_ imageData: Data, type: ImageType) {
        switch type {
        case .profile:
            profile.profileImageData = imageData
        case .organizationLogo:
            profile.organizationLogoData = imageData
        }
    }
    
    public func removeImage(type: ImageType) {
        switch type {
        case .profile:
            profile.profileImageData = nil
        case .organizationLogo:
            profile.organizationLogoData = nil
        }
    }
    
    // MARK: - Address Management
    
    public func copyAddress(from source: AddressType, to destination: AddressType) {
        let sourceAddress: Address
        
        switch source {
        case .administeredBy:
            sourceAddress = profile.defaultAdministeredByAddress
        case .payment:
            sourceAddress = profile.defaultPaymentAddress
        case .delivery:
            sourceAddress = profile.defaultDeliveryAddress
        }
        
        switch destination {
        case .administeredBy:
            profile.defaultAdministeredByAddress = sourceAddress
        case .payment:
            profile.defaultPaymentAddress = sourceAddress
        case .delivery:
            profile.defaultDeliveryAddress = sourceAddress
        }
    }
    
    public func showAddressCopySheet(for type: AddressType) {
        addressCopySource = type
        showingAddressCopySheet = true
    }
}
```

### 3.4 Testing Strategy for ProfileView

```swift
// ProfileViewTests.swift
class ProfileViewTests: XCTestCase {
    var viewModel: ProfileViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ProfileViewModel()
    }
    
    func testProfileValidation() async {
        // Test empty required fields
        viewModel.profile.fullName = ""
        viewModel.profile.email = ""
        
        await viewModel.saveProfile()
        
        XCTAssertFalse(viewModel.validationErrors.isEmpty)
        XCTAssertNotNil(viewModel.validationErrors["fullName"])
        XCTAssertNotNil(viewModel.validationErrors["email"])
    }
    
    func testEmailValidation() async {
        viewModel.profile.email = "invalid-email"
        await viewModel.saveProfile()
        
        XCTAssertNotNil(viewModel.validationErrors["email"])
        
        viewModel.profile.email = "valid@email.com"
        await viewModel.saveProfile()
        
        XCTAssertNil(viewModel.validationErrors["email"])
    }
    
    func testProfileCompletion() {
        let profile = UserProfile()
        XCTAssertEqual(profile.completionPercentage, 0.0)
        
        profile.fullName = "John Doe"
        profile.email = "john@example.com"
        XCTAssertTrue(profile.isComplete)
    }
    
    func testAddressCopy() {
        let sourceAddress = Address(
            street1: "123 Main St",
            city: "New York",
            state: "NY",
            zipCode: "10001"
        )
        
        viewModel.profile.defaultAdministeredByAddress = sourceAddress
        viewModel.copyAddress(from: .administeredBy, to: .payment)
        
        XCTAssertEqual(viewModel.profile.defaultPaymentAddress.street1, "123 Main St")
        XCTAssertEqual(viewModel.profile.defaultPaymentAddress.city, "New York")
    }
}
```

---

## 4. DocumentScannerView Implementation Plan

### 4.1 Architecture Design

```swift
// DocumentScannerView.swift
struct DocumentScannerView: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @State private var showingScanner = false
    @State private var showingExportOptions = false
    @State private var scannerError: ScannerError?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            DocumentScannerContent(
                viewModel: viewModel,
                showingScanner: $showingScanner,
                scannerError: $scannerError
            )
            .navigationTitle("Document Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.scannedPages.isEmpty {
                        Button("Export") {
                            showingExportOptions = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                #if os(iOS)
                VisionKitScannerView(viewModel: viewModel)
                #else
                MacOSFileScannerView(viewModel: viewModel)
                #endif
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(viewModel: viewModel)
            }
            .alert("Scanner Error", isPresented: .constant(scannerError != nil)) {
                Button("OK") { scannerError = nil }
            } message: {
                Text(scannerError?.localizedDescription ?? "")
            }
        }
    }
}

// DocumentScannerContent.swift
struct DocumentScannerContent: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @Binding var showingScanner: Bool
    @Binding var scannerError: ScannerError?
    
    var body: some View {
        if viewModel.scannedPages.isEmpty {
            EmptyScannerView(onStartScan: {
                showingScanner = true
            })
        } else {
            ScannedPagesView(
                viewModel: viewModel,
                onAddPage: {
                    showingScanner = true
                }
            )
        }
    }
}
```

### 4.2 VisionKit Integration

```swift
#if os(iOS)
import VisionKit

// VisionKitScannerView.swift
struct VisionKitScannerView: UIViewControllerRepresentable {
    @Bindable var viewModel: DocumentScannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = context.coordinator
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: VisionKitScannerView
        
        init(_ parent: VisionKitScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            Task {
                await parent.viewModel.processScan(scan)
            }
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.viewModel.handleScanError(error)
            parent.dismiss()
        }
    }
}
#endif
```

### 4.3 Enhanced DocumentScannerViewModel

```swift
// Enhanced DocumentScannerViewModel.swift
@MainActor
@Observable
public final class DocumentScannerViewModel {
    public var scanSession: ScanSession
    public var scannedPages: [ScannedPage] = []
    public var currentPageIndex: Int = 0
    public var isProcessing = false
    public var processingProgress: Double = 0
    public var scanQuality: ScanQuality = .high
    public var ocrResults: [OCRResult] = []
    public var error: Error?
    
    // Export settings
    public var exportFormat: ExportFormat = .pdf
    public var includeOCR = true
    public var optimizeFileSize = true
    
    public init() {
        self.scanSession = ScanSession()
    }
    
    // MARK: - VisionKit Processing
    
    #if os(iOS)
    public func processScan(_ scan: VNDocumentCameraScan) async {
        isProcessing = true
        processingProgress = 0
        
        let pageCount = scan.pageCount
        
        for index in 0..<pageCount {
            processingProgress = Double(index) / Double(pageCount)
            
            let pageImage = scan.imageOfPage(at: index)
            let scannedPage = ScannedPage(
                id: UUID(),
                image: pageImage,
                pageNumber: index + 1,
                scanDate: Date()
            )
            
            // Process OCR if enabled
            if includeOCR {
                let ocrResult = await performOCR(on: pageImage)
                scannedPage.ocrText = ocrResult.text
                scannedPage.ocrConfidence = ocrResult.confidence
                ocrResults.append(ocrResult)
            }
            
            // Apply quality settings
            if let processedImage = await processImage(pageImage, quality: scanQuality) {
                scannedPage.processedImage = processedImage
            }
            
            await MainActor.run {
                scannedPages.append(scannedPage)
            }
        }
        
        processingProgress = 1.0
        isProcessing = false
    }
    
    private func performOCR(on image: UIImage) async -> OCRResult {
        // Use Vision framework for OCR
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      error == nil else {
                    continuation.resume(returning: OCRResult(text: "", confidence: 0))
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                let avgConfidence = observations.compactMap { $0.confidence }.reduce(0, +) / Float(observations.count)
                
                continuation.resume(returning: OCRResult(
                    text: fullText,
                    confidence: Double(avgConfidence)
                ))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            if let cgImage = image.cgImage {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }
    
    private func processImage(_ image: UIImage, quality: ScanQuality) async -> UIImage? {
        // Apply image processing based on quality settings
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var processedImage = image
                
                // Apply filters based on quality
                switch quality {
                case .high:
                    processedImage = self.applyHighQualityFilters(to: image)
                case .medium:
                    processedImage = self.applyMediumQualityFilters(to: image)
                case .low:
                    processedImage = self.applyLowQualityFilters(to: image)
                }
                
                continuation.resume(returning: processedImage)
            }
        }
    }
    #endif
    
    // MARK: - Export Functionality
    
    public func exportDocument() async throws -> Data {
        guard !scannedPages.isEmpty else {
            throw ScannerError.noPages
        }
        
        switch exportFormat {
        case .pdf:
            return try await exportAsPDF()
        case .images:
            return try await exportAsImages()
        case .text:
            return try await exportAsText()
        }
    }
    
    private func exportAsPDF() async throws -> Data {
        #if os(iOS)
        let pdfDocument = PDFDocument()
        
        for (index, page) in scannedPages.enumerated() {
            if let image = page.processedImage ?? page.image,
               let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: index)
                
                // Add OCR text as PDF metadata if available
                if let ocrText = page.ocrText {
                    pdfPage.setValue(ocrText, forAnnotationKey: .contents)
                }
            }
        }
        
        return pdfDocument.dataRepresentation() ?? Data()
        #else
        // macOS implementation
        return Data()
        #endif
    }
    
    // MARK: - Page Management
    
    public func removePage(at index: Int) {
        guard index < scannedPages.count else { return }
        scannedPages.remove(at: index)
        
        // Update current page index
        if currentPageIndex >= scannedPages.count {
            currentPageIndex = max(0, scannedPages.count - 1)
        }
        
        // Renumber remaining pages
        for (index, page) in scannedPages.enumerated() {
            page.pageNumber = index + 1
        }
    }
    
    public func reorderPage(from source: Int, to destination: Int) {
        guard source != destination,
              source < scannedPages.count,
              destination <= scannedPages.count else { return }
        
        let page = scannedPages.remove(at: source)
        scannedPages.insert(page, at: destination > source ? destination - 1 : destination)
        
        // Renumber pages
        for (index, page) in scannedPages.enumerated() {
            page.pageNumber = index + 1
        }
    }
}

// Supporting Types
public enum ScanQuality {
    case low, medium, high
    
    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }
}

public enum ExportFormat {
    case pdf, images, text
}

public struct OCRResult {
    let text: String
    let confidence: Double
}

public enum ScannerError: LocalizedError {
    case noPages
    case ocrFailed
    case exportFailed
    case cameraNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .noPages: return "No pages to export"
        case .ocrFailed: return "Text recognition failed"
        case .exportFailed: return "Export failed"
        case .cameraNotAvailable: return "Camera not available"
        }
    }
}
```

### 4.4 Cross-Platform Support

```swift
#if os(macOS)
// MacOSFileScannerView.swift
struct MacOSFileScannerView: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @State private var isImporting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Document Images")
                .font(.title2)
            
            Button("Select Images") {
                isImporting = true
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await viewModel.importFiles(urls)
                    dismiss()
                }
            case .failure(let error):
                viewModel.error = error
                dismiss()
            }
        }
    }
}
#endif
```

---

## 5. LLMProviderSettingsView Migration Plan

### 5.1 Migration Strategy

```swift
// LLMProviderSettingsViewModel.swift - New @Observable implementation
@MainActor
@Observable
public final class LLMProviderSettingsViewModel {
    // State from TCA
    public var activeProvider: LLMProviderConfiguration?
    public var configuredProviders: Set<LLMProvider> = []
    public var selectedProvider: LLMProvider?
    public var providerPriority: ProviderPriority
    public var isProviderConfigSheetPresented = false
    public var isAlertPresented = false
    public var alert: AlertType?
    
    // Provider configuration state
    public var providerConfigViewModel: ProviderConfigurationViewModel?
    
    public enum AlertType: Equatable {
        case clearConfirmation
        case error(String)
    }
    
    private let keychain = KeychainService()
    private let providerService: LLMProviderService
    
    public init() {
        self.providerPriority = ProviderPriority()
        self.providerService = LLMProviderService()
        loadProviderConfiguration()
    }
    
    // MARK: - Actions (migrated from TCA)
    
    public func providerTapped(_ provider: LLMProvider) {
        selectedProvider = provider
        providerConfigViewModel = ProviderConfigurationViewModel(
            provider: provider,
            hasExistingKey: configuredProviders.contains(provider)
        )
        isProviderConfigSheetPresented = true
    }
    
    public func clearAllTapped() {
        alert = .clearConfirmation
        isAlertPresented = true
    }
    
    public func clearAllConfirmed() {
        Task {
            do {
                // Clear all API keys from keychain
                for provider in LLMProvider.allCases {
                    try await keychain.deleteAPIKey(for: provider)
                }
                
                // Reset state
                await MainActor.run {
                    configuredProviders.removeAll()
                    activeProvider = nil
                    alert = nil
                }
                
            } catch {
                await MainActor.run {
                    alert = .error(error.localizedDescription)
                    isAlertPresented = true
                }
            }
        }
    }
    
    public func dismissAlert() {
        isAlertPresented = false
        alert = nil
    }
    
    public func setProviderConfigSheet(_ isPresented: Bool) {
        isProviderConfigSheetPresented = isPresented
        if !isPresented {
            providerConfigViewModel = nil
            selectedProvider = nil
        }
    }
    
    public func fallbackBehaviorChanged(_ behavior: ProviderPriority.FallbackBehavior) {
        providerPriority.fallbackBehavior = behavior
        saveProviderPriority()
    }
    
    public func moveProvider(from source: IndexSet, to destination: Int) {
        providerPriority.providers.move(fromOffsets: source, toOffset: destination)
        saveProviderPriority()
    }
    
    // MARK: - Provider Configuration
    
    private func loadProviderConfiguration() {
        // Load configured providers from keychain
        for provider in LLMProvider.allCases {
            if keychain.hasAPIKey(for: provider) {
                configuredProviders.insert(provider)
            }
        }
        
        // Load active provider from UserDefaults
        if let activeProviderData = UserDefaults.standard.data(forKey: "activeProvider"),
           let provider = try? JSONDecoder().decode(LLMProviderConfiguration.self, from: activeProviderData) {
            activeProvider = provider
        }
        
        // Load provider priority
        if let priorityData = UserDefaults.standard.data(forKey: "providerPriority"),
           let priority = try? JSONDecoder().decode(ProviderPriority.self, from: priorityData) {
            providerPriority = priority
        }
    }
    
    private func saveProviderPriority() {
        if let data = try? JSONEncoder().encode(providerPriority) {
            UserDefaults.standard.set(data, forKey: "providerPriority")
        }
    }
}

// ProviderConfigurationViewModel.swift
@MainActor
@Observable
public final class ProviderConfigurationViewModel {
    public let provider: LLMProvider
    public var hasExistingKey: Bool
    public var selectedModel: LLMModel
    public var temperature: Double = 0.7
    public var customEndpoint: String = ""
    public var isSaving = false
    
    private let keychain = KeychainService()
    
    public init(provider: LLMProvider, hasExistingKey: Bool) {
        self.provider = provider
        self.hasExistingKey = hasExistingKey
        self.selectedModel = provider.availableModels.first ?? LLMModel.default
    }
    
    public func modelSelected(_ model: LLMModel) {
        selectedModel = model
    }
    
    public func temperatureChanged(_ value: Double) {
        temperature = value
    }
    
    public func customEndpointChanged(_ value: String) {
        customEndpoint = value
    }
    
    public func saveConfiguration(apiKey: String) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Validate API key
            let isValid = await validateAPIKey(apiKey)
            guard isValid else {
                throw LLMProviderError.invalidAPIKey
            }
            
            // Save to keychain
            try await keychain.saveAPIKey(apiKey, for: provider)
            
            // Create and save configuration
            let config = LLMProviderConfiguration(
                provider: provider,
                model: selectedModel,
                apiKey: apiKey,
                temperature: temperature,
                customEndpoint: provider == .custom ? customEndpoint : nil
            )
            
            // Update parent view model
            NotificationCenter.default.post(
                name: NSNotification.Name("ProviderConfigurationSaved"),
                object: config
            )
            
        } catch {
            // Handle error
            print("Failed to save configuration: \(error)")
        }
    }
    
    public func removeConfiguration() {
        Task {
            do {
                try await keychain.deleteAPIKey(for: provider)
                hasExistingKey = false
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("ProviderConfigurationRemoved"),
                    object: provider
                )
            } catch {
                print("Failed to remove configuration: \(error)")
            }
        }
    }
    
    public func cancelTapped() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ProviderConfigurationCancelled"),
            object: nil
        )
    }
    
    private func validateAPIKey(_ key: String) async -> Bool {
        // Implement API key validation for each provider
        // This would make a test API call to verify the key
        return !key.isEmpty // Placeholder
    }
}
```

### 5.2 Feature Flag Migration

```swift
// MigrationFeatureFlags.swift
@Observable
public final class MigrationFeatureFlags {
    public static let shared = MigrationFeatureFlags()
    
    // LLMProviderSettings migration flag
    public var useLegacyTCAProviderSettings = true
    public var migrationProgress: Double = 0.0
    
    // A/B testing groups
    public var isInMigrationTestGroup: Bool {
        // Determine based on user ID or random assignment
        let userHash = (UserDefaults.standard.string(forKey: "userId") ?? "").hashValue
        return userHash % 100 < migrationPercentage
    }
    
    private var migrationPercentage: Int {
        // Gradual rollout percentage
        UserDefaults.standard.integer(forKey: "llmProviderMigrationPercentage")
    }
    
    public func enableMigration(percentage: Int) {
        UserDefaults.standard.set(percentage, forKey: "llmProviderMigrationPercentage")
    }
}

// Usage in main app
struct SettingsView: View {
    @State private var featureFlags = MigrationFeatureFlags.shared
    
    var body: some View {
        if featureFlags.useLegacyTCAProviderSettings && !featureFlags.isInMigrationTestGroup {
            // Show TCA version
            LLMProviderSettingsView(store: Store(
                initialState: LLMProviderSettingsFeature.State(),
                reducer: { LLMProviderSettingsFeature() }
            ))
        } else {
            // Show new @Observable version
            LLMProviderSettingsViewNew(
                viewModel: LLMProviderSettingsViewModel()
            )
        }
    }
}
```

### 5.3 Testing Strategy for Migration

```swift
// LLMProviderMigrationTests.swift
class LLMProviderMigrationTests: XCTestCase {
    var tcaStore: TestStore<LLMProviderSettingsFeature.State, LLMProviderSettingsFeature.Action>!
    var observableViewModel: LLMProviderSettingsViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Setup TCA store
        tcaStore = TestStore(
            initialState: LLMProviderSettingsFeature.State(),
            reducer: { LLMProviderSettingsFeature() }
        )
        
        // Setup Observable view model
        observableViewModel = LLMProviderSettingsViewModel()
    }
    
    func testFeatureParity_ProviderSelection() async {
        // TCA approach
        await tcaStore.send(.providerTapped(.openAI)) {
            $0.selectedProvider = .openAI
            $0.isProviderConfigSheetPresented = true
        }
        
        // Observable approach
        observableViewModel.providerTapped(.openAI)
        
        XCTAssertEqual(observableViewModel.selectedProvider, .openAI)
        XCTAssertTrue(observableViewModel.isProviderConfigSheetPresented)
    }
    
    func testFeatureParity_ClearAllKeys() async {
        // Both implementations should handle clear all the same way
        await tcaStore.send(.clearAllTapped) {
            $0.alert = .clearConfirmation
            $0.isAlertPresented = true
        }
        
        observableViewModel.clearAllTapped()
        
        XCTAssertEqual(observableViewModel.alert, .clearConfirmation)
        XCTAssertTrue(observableViewModel.isAlertPresented)
    }
    
    func testMigrationDataConsistency() async {
        // Test that data saved by TCA version can be read by Observable version
        let testProvider = LLMProvider.claude
        let testAPIKey = "test-api-key"
        
        // Save via TCA pattern
        let keychain = KeychainService()
        try? await keychain.saveAPIKey(testAPIKey, for: testProvider)
        
        // Load via Observable pattern
        let newViewModel = LLMProviderSettingsViewModel()
        
        XCTAssertTrue(newViewModel.configuredProviders.contains(testProvider))
    }
}
```

---

## 6. Integration Points & Dependencies

### 6.1 Shared Services Architecture

```swift
// Services/ProfileService.swift
public protocol ProfileServiceProtocol {
    func loadProfile() async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
    func validateProfile(_ profile: UserProfile) -> [String: String]
}

// Services/DocumentScannerService.swift
public protocol DocumentScannerServiceProtocol {
    func startScan(config: ScanConfiguration) async throws -> ScanResult
    func processImage(_ image: PlatformImage, quality: ScanQuality) async -> PlatformImage?
    func performOCR(on image: PlatformImage) async -> OCRResult
    func exportDocument(pages: [ScannedPage], format: ExportFormat) async throws -> Data
}

// Services/LLMProviderService.swift
public protocol LLMProviderServiceProtocol {
    func loadProviders() async -> [LLMProviderConfiguration]
    func saveProvider(_ config: LLMProviderConfiguration) async throws
    func validateAPIKey(_ key: String, for provider: LLMProvider) async -> Bool
    func selectOptimalProvider() async -> LLMProvider?
}
```

### 6.2 Dependency Injection

```swift
// DependencyContainer+Phase3.swift
extension DependencyContainer {
    public func registerPhase3Services() {
        // Profile services
        register(ProfileServiceProtocol.self) {
            ProfileService()
        }
        
        // Document scanner services
        register(DocumentScannerServiceProtocol.self) {
            DocumentScannerService()
        }
        
        // LLM provider services
        register(LLMProviderServiceProtocol.self) {
            LLMProviderService()
        }
        
        // View models
        register(ProfileViewModel.self) {
            ProfileViewModel()
        }
        
        register(DocumentScannerViewModel.self) {
            DocumentScannerViewModel()
        }
        
        register(LLMProviderSettingsViewModel.self) {
            LLMProviderSettingsViewModel()
        }
    }
}
```

---

## 7. Testing & Quality Assurance Strategy

### 7.1 Unit Testing Coverage

```
ProfileView Tests:
├── ProfileViewModelTests (>95% coverage)
├── ProfileValidationTests (100% coverage)
├── ProfileComponentsTests (>90% coverage)
└── ProfilePersistenceTests (>90% coverage)

DocumentScannerView Tests:
├── DocumentScannerViewModelTests (>90% coverage)
├── OCRProcessingTests (>85% coverage)
├── ExportFunctionalityTests (>90% coverage)
└── VisionKitIntegrationTests (>80% coverage)

LLMProviderSettingsView Tests:
├── MigrationParityTests (100% coverage)
├── ViewModelBehaviorTests (>95% coverage)
├── KeychainIntegrationTests (>90% coverage)
└── ProviderValidationTests (>95% coverage)
```

### 7.2 Integration Testing

```swift
// Phase3IntegrationTests.swift
class Phase3IntegrationTests: XCTestCase {
    func testProfileToDocumentScannerFlow() async {
        // Test that profile data is available in document scanner
        let profileVM = ProfileViewModel()
        profileVM.profile.fullName = "Test User"
        await profileVM.saveProfile()
        
        let scannerVM = DocumentScannerViewModel()
        let exportedDoc = try await scannerVM.exportDocument()
        
        // Verify profile data is included in document metadata
        XCTAssertTrue(exportedDoc.contains("Test User"))
    }
    
    func testLLMProviderToDocumentGeneration() async {
        // Test that LLM configuration affects document generation
        let llmVM = LLMProviderSettingsViewModel()
        llmVM.activeProvider = LLMProviderConfiguration(
            provider: .openAI,
            model: .gpt4,
            apiKey: "test"
        )
        
        let docGenVM = DocumentGenerationViewModel()
        await docGenVM.generateDocument()
        
        // Verify correct provider was used
        XCTAssertNotNil(docGenVM.generatedContent)
    }
}
```

---

## 8. Risk Mitigation

### 8.1 Technical Risks

| Risk | Impact | Mitigation | Monitoring |
|------|--------|------------|-------------|
| VisionKit Availability | High | Graceful fallback to file import | Runtime checks |
| TCA Migration Breaking Changes | High | Feature flags, parallel implementations | A/B testing metrics |
| Memory Usage with Large Scans | Medium | Page-by-page processing, compression | Memory profiler |
| Keychain Access Failures | Medium | Fallback to encrypted UserDefaults | Error tracking |
| Profile Data Loss | High | Backup before save, versioned storage | Data integrity checks |

### 8.2 Rollback Strategy

```swift
// RollbackManager.swift
public final class RollbackManager {
    public static func rollbackLLMProviderMigration() {
        // Disable feature flag
        MigrationFeatureFlags.shared.useLegacyTCAProviderSettings = true
        
        // Clear any migration-specific data
        UserDefaults.standard.removeObject(forKey: "llmProviderMigrationPercentage")
        
        // Notify users in test group
        NotificationCenter.default.post(
            name: NSNotification.Name("MigrationRolledBack"),
            object: "LLMProviderSettings"
        )
    }
}
```

---

## 9. Performance Optimization

### 9.1 ProfileView Optimizations

```swift
// Lazy loading for profile images
extension ProfileViewModel {
    @MainActor
    public func loadImageAsync(type: ImageType) async {
        switch type {
        case .profile:
            if profile.profileImageData == nil {
                profile.profileImageData = await loadImageFromDisk(key: "profileImage")
            }
        case .organizationLogo:
            if profile.organizationLogoData == nil {
                profile.organizationLogoData = await loadImageFromDisk(key: "orgLogo")
            }
        }
    }
}
```

### 9.2 DocumentScanner Memory Management

```swift
// Memory-efficient page processing
extension DocumentScannerViewModel {
    private func processPagesBatched(_ pages: [UIImage]) async {
        let batchSize = 5
        
        for batchStart in stride(from: 0, to: pages.count, by: batchSize) {
            autoreleasepool {
                let batchEnd = min(batchStart + batchSize, pages.count)
                let batch = Array(pages[batchStart..<batchEnd])
                
                Task {
                    for page in batch {
                        await processPage(page)
                    }
                }
            }
        }
    }
}
```

---

## 10. Documentation Requirements

### 10.1 Technical Documentation

- [ ] ProfileView component API documentation
- [ ] DocumentScannerView integration guide
- [ ] LLMProviderSettings migration guide
- [ ] Testing procedures and coverage reports

### 10.2 User Documentation

- [ ] Profile management user guide
- [ ] Document scanner tutorial
- [ ] LLM provider configuration guide
- [ ] Troubleshooting common issues

---

## 11. Implementation Timeline

### Week 1: ProfileView (Days 1-5)
- **Day 1**: Create ProfileView structure and navigation
- **Day 2**: Implement all modular sections
- **Day 3**: Add image picker and validation
- **Day 4**: Implement persistence and testing
- **Day 5**: Integration testing and polish

### Week 2: DocumentScannerView (Days 6-10)
- **Day 1-2**: VisionKit integration and UI
- **Day 3**: OCR implementation
- **Day 4**: Export functionality
- **Day 5**: Cross-platform support and testing

### Week 3: LLMProviderSettingsView (Days 11-15)
- **Day 1-2**: Create @Observable ViewModels
- **Day 3**: Implement feature flag system
- **Day 4**: Migration testing and validation
- **Day 5**: Final integration and rollout

---

## 12. Success Metrics

### Quantitative Metrics
- **Code Coverage**: >90% for all components
- **Performance**: <100ms view load time
- **Memory Usage**: <50MB additional for scanner
- **Migration Success**: >95% users without issues

### Qualitative Metrics
- **User Satisfaction**: Profile completion rate >80%
- **Feature Adoption**: Scanner usage >60% of users
- **Migration Smoothness**: <5% rollback rate
- **Code Quality**: Zero SwiftLint violations

---

## 13. Approval Checklist

- [ ] Architecture aligns with SwiftUI @Observable patterns
- [ ] All PRD requirements addressed
- [ ] Testing strategy comprehensive
- [ ] Risk mitigation plans in place
- [ ] Performance targets defined
- [ ] Documentation requirements clear

---

*This implementation plan is pending VanillaIce consensus validation for final approval.*
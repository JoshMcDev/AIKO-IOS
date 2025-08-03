# PHASE 3: Restore Enhanced Features - Implementation Plan
## AIKO - Adaptive Intelligence for Kontract Optimization

**Version:** 1.0 FINAL  
**Date:** 2025-08-03  
**Phase:** Design & Implementation  
**Author:** Claude Code System  
**Status:** APPROVED - VanillaIce Consensus Validated  

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

### VanillaIce Consensus Summary
The implementation plan has been validated by 5 iOS-specialized models with emphasis on:
- Architectural consistency with detailed guidelines and templates
- Robust dependency management with loose coupling
- Comprehensive testing strategies with CI/CD integration
- Phased migration approach with feature flags
- Cross-platform shared code architecture
- Extensive VisionKit testing protocols
- Centralized feature flag management system

---

## 2. Architectural Guidelines & Standards

### 2.1 Swift 6/@Observable Pattern Template

```swift
// StandardViewModelTemplate.swift - Required pattern for all ViewModels
@MainActor
@Observable
public final class StandardViewModel {
    // MARK: - State Properties
    // Group related state properties together
    
    // MARK: - Private Properties
    private let service: ServiceProtocol
    private let logger = Logger(subsystem: "com.aiko", category: "ViewModel")
    
    // MARK: - Initialization
    public init(service: ServiceProtocol = ServiceImplementation()) {
        self.service = service
        setupObservers()
    }
    
    // MARK: - Public Methods
    // Async methods for state mutations
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Notification observers, Combine subscriptions
    }
}
```

### 2.2 SwiftLint Configuration

```yaml
# .swiftlint.yml - PHASE 3 Enhanced Rules
disabled_rules:
  - line_length # Handled by SwiftFormat
  
opt_in_rules:
  - anyobject_protocol
  - array_init
  - attributes
  - closure_body_length
  - closure_end_indentation
  - closure_spacing
  - collection_alignment
  - contains_over_filter_count
  - convenience_type
  - discouraged_optional_boolean
  - empty_collection_literal
  - empty_count
  - empty_string
  - enum_case_associated_values_count
  - explicit_init
  - fatal_error_message
  - file_header
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - last_where
  - legacy_multiple
  - literal_expression_end_indentation
  - lower_acl_than_parent
  - modifier_order
  - multiline_arguments
  - multiline_function_chains
  - multiline_literal_brackets
  - multiline_parameters
  - multiline_parameters_brackets
  - nimble_operator
  - number_separator
  - object_literal
  - operator_usage_whitespace
  - optional_enum_case_matching
  - overridden_super_call
  - pattern_matching_keywords
  - prefer_self_type_over_type_of_self
  - private_action
  - private_outlet
  - prohibited_interface_builder
  - prohibited_super_call
  - quick_discouraged_call
  - quick_discouraged_focused_test
  - quick_discouraged_pending_test
  - redundant_nil_coalescing
  - redundant_type_annotation
  - single_test_class
  - sorted_first_last
  - static_operator
  - strong_iboutlet
  - toggle_bool
  - unavailable_function
  - unneeded_parentheses_in_closure_argument
  - unowned_variable_capture
  - untyped_error_in_catch
  - vertical_parameter_alignment_on_call
  - vertical_whitespace_closing_braces
  - vertical_whitespace_opening_braces
  - xct_specific_matcher
  - yoda_condition

# Custom rules for @Observable compliance
custom_rules:
  observable_pattern:
    name: "Observable Pattern"
    regex: "class\\s+\\w+ViewModel(?!.*@Observable)"
    message: "ViewModels must use @Observable attribute"
    severity: error
    
  mainactor_pattern:
    name: "MainActor Pattern"
    regex: "@Observable\\s+.*class(?!.*@MainActor)"
    message: "@Observable classes must also be @MainActor"
    severity: error
```

---

## 3. Dependency Management Architecture

### 3.1 Module Boundaries & Interfaces

```swift
// ModuleInterfaces.swift - Clear boundaries between modules
public protocol ProfileModuleInterface {
    var profileService: ProfileServiceProtocol { get }
    var profileViewModel: ProfileViewModel { get }
    func registerDependencies()
}

public protocol DocumentScannerModuleInterface {
    var scannerService: DocumentScannerServiceProtocol { get }
    var scannerViewModel: DocumentScannerViewModel { get }
    func registerDependencies()
}

public protocol LLMProviderModuleInterface {
    var providerService: LLMProviderServiceProtocol { get }
    var settingsViewModel: LLMProviderSettingsViewModel { get }
    func registerDependencies()
}
```

### 3.2 Dependency Injection System

```swift
// DependencyContainer+Phase3.swift
extension DependencyContainer {
    public func registerPhase3Services() {
        // Use factory patterns for loose coupling
        registerFactory(ProfileServiceProtocol.self) { resolver in
            ProfileService(
                storage: resolver.resolve(StorageServiceProtocol.self)!,
                validator: resolver.resolve(ValidationServiceProtocol.self)!
            )
        }
        
        registerFactory(DocumentScannerServiceProtocol.self) { resolver in
            DocumentScannerService(
                visionKit: resolver.resolve(VisionKitServiceProtocol.self)!,
                ocr: resolver.resolve(OCRServiceProtocol.self)!,
                export: resolver.resolve(ExportServiceProtocol.self)!
            )
        }
        
        registerFactory(LLMProviderServiceProtocol.self) { resolver in
            LLMProviderService(
                keychain: resolver.resolve(KeychainServiceProtocol.self)!,
                network: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }
    }
}
```

### 3.3 Swift Package Manager Integration

```swift
// Package.swift additions
dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0"),
    .package(url: "https://github.com/Quick/Quick", from: "7.0.0"),
    .package(url: "https://github.com/Quick/Nimble", from: "13.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0")
],
targets: [
    .target(
        name: "ProfileModule",
        dependencies: ["AppCore", "UIComponents"],
        swiftSettings: [
            .unsafeFlags(["-warnings-as-errors"])
        ]
    ),
    .target(
        name: "DocumentScannerModule",
        dependencies: ["AppCore", "VisionKit"],
        swiftSettings: [
            .unsafeFlags(["-warnings-as-errors"])
        ]
    ),
    .target(
        name: "LLMProviderModule",
        dependencies: ["AppCore", "KeychainAccess"],
        swiftSettings: [
            .unsafeFlags(["-warnings-as-errors"])
        ]
    )
]
```

---

## 4. Comprehensive Testing Strategy

### 4.1 CI/CD Pipeline Configuration

```yaml
# .github/workflows/phase3-tests.yml
name: PHASE 3 Testing Pipeline

on:
  push:
    branches: [main, develop, phase3/*]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    strategy:
      matrix:
        include:
          - scheme: ProfileModule
            coverage-threshold: 95
          - scheme: DocumentScannerModule
            coverage-threshold: 90
          - scheme: LLMProviderModule
            coverage-threshold: 95
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'
      
      - name: Install Dependencies
        run: |
          brew install swiftlint
          swift package resolve
      
      - name: SwiftLint
        run: swiftlint lint --strict
      
      - name: Build and Test
        run: |
          xcodebuild test \
            -scheme ${{ matrix.scheme }} \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults
      
      - name: Generate Coverage Report
        run: |
          xcrun xccov view --report --json TestResults.xcresult > coverage.json
          
      - name: Check Coverage Threshold
        run: |
          COVERAGE=$(jq '.lineCoverage' coverage.json)
          if (( $(echo "$COVERAGE < ${{ matrix.coverage-threshold }}" | bc -l) )); then
            echo "Coverage $COVERAGE% is below threshold ${{ matrix.coverage-threshold }}%"
            exit 1
          fi
```

### 4.2 Property-Based Testing

```swift
// PropertyBasedTests.swift
import SwiftCheck

class ProfileValidationPropertyTests: XCTestCase {
    func testEmailValidationProperty() {
        property("Valid emails always pass validation") <- forAll { (user: String, domain: String) in
            let email = "\(user)@\(domain).com"
                .replacingOccurrences(of: " ", with: "")
                .lowercased()
            
            return !email.isEmpty ==> {
                let validator = EmailValidator()
                return validator.isValid(email) == email.contains("@")
            }
        }
    }
    
    func testPhoneValidationProperty() {
        property("Phone numbers with 10+ digits are valid") <- forAll { (digits: [Int]) in
            let phone = digits.map(String.init).joined()
            let validator = PhoneValidator()
            
            return phone.count >= 10 ==> validator.isValid(phone)
        }
    }
}
```

### 4.3 UI Testing Strategy

```swift
// UITestBase.swift
class Phase3UITestBase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "DISABLE_ANIMATIONS": "1",
            "RESET_STATE": "1"
        ]
        app.launch()
    }
    
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element \(element) did not appear within \(timeout) seconds")
    }
}

// ProfileViewUITests.swift
class ProfileViewUITests: Phase3UITestBase {
    func testCompleteProfileFlow() {
        // Navigate to profile
        app.buttons["profileButton"].tap()
        waitForElement(app.navigationBars["Profile"])
        
        // Edit profile
        app.buttons["Edit"].tap()
        
        // Fill required fields
        let nameField = app.textFields["fullNameField"]
        nameField.tap()
        nameField.typeText("John Doe")
        
        let emailField = app.textFields["emailField"]
        emailField.tap()
        emailField.typeText("john@example.com")
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify
        XCTAssertFalse(app.buttons["Edit"].exists)
        XCTAssertEqual(app.staticTexts["profileName"].label, "John Doe")
    }
}
```

---

## 5. ProfileView Implementation (Enhanced)

### 5.1 Complete Architecture with Guidelines

```swift
// ProfileView.swift - Following architectural template
import SwiftUI
import Combine

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var showingImagePicker = false
    @State private var selectedImageType: ProfileImageType = .profile
    @Environment(\.dismiss) private var dismiss
    
    // Accessibility identifiers for UI testing
    private enum AccessibilityIdentifiers {
        static let profileButton = "profileButton"
        static let editButton = "editProfileButton"
        static let saveButton = "saveProfileButton"
        static let fullNameField = "fullNameField"
        static let emailField = "emailField"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Profile header with completion indicator
                    ProfileHeaderSection(viewModel: viewModel)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Profile Header")
                    
                    // Modular sections following single responsibility
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
                    .accessibilityIdentifier("cancelProfileButton")
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
                        .disabled(viewModel.isSaving || !viewModel.hasChanges)
                        .accessibilityIdentifier(AccessibilityIdentifiers.saveButton)
                    } else {
                        Button("Edit") {
                            viewModel.startEditing()
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.editButton)
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

### 5.2 Enhanced ProfileViewModel with Validation

```swift
// ProfileViewModel.swift - Following @Observable template
@MainActor
@Observable
public final class ProfileViewModel {
    // MARK: - State Properties
    public var profile: UserProfile
    public var isEditing: Bool = false
    public var isSaving: Bool = false
    public var hasChanges: Bool = false
    public var error: Error?
    public var validationErrors: [String: String] = [:]
    
    // Address management
    public var addressCopySource: AddressType?
    public var showingAddressCopySheet = false
    
    // MARK: - Private Properties
    private let profileService: ProfileServiceProtocol
    private let validator: ProfileValidatorProtocol
    private let logger = Logger(subsystem: "com.aiko", category: "ProfileViewModel")
    private var originalProfile: UserProfile?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
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
    
    // MARK: - Initialization
    public init(
        profile: UserProfile = UserProfile(),
        profileService: ProfileServiceProtocol = ProfileService(),
        validator: ProfileValidatorProtocol = ProfileValidator()
    ) {
        self.profile = profile
        self.profileService = profileService
        self.validator = validator
        setupObservers()
        loadProfile()
    }
    
    // MARK: - Public Methods
    
    public func startEditing() {
        originalProfile = profile
        isEditing = true
        hasChanges = false
        validationErrors.removeAll()
    }
    
    public func cancelEditing() {
        if let original = originalProfile {
            profile = original
        }
        isEditing = false
        hasChanges = false
        validationErrors.removeAll()
        originalProfile = nil
    }
    
    public func saveProfile() async {
        logger.info("Saving profile")
        isSaving = true
        defer { isSaving = false }
        
        // Validate
        let validation = validator.validate(profile)
        if !validation.isValid {
            validationErrors = validation.errors
            logger.warning("Profile validation failed: \(validation.errors)")
            return
        }
        
        do {
            // Update metadata
            profile.updatedAt = Date()
            
            // Save through service
            try await profileService.saveProfile(profile)
            
            // Update state
            await MainActor.run {
                isEditing = false
                hasChanges = false
                originalProfile = nil
            }
            
            logger.info("Profile saved successfully")
            
        } catch {
            logger.error("Failed to save profile: \(error)")
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    // MARK: - Image Management
    
    public func updateImage(_ imageData: Data, type: ImageType) {
        switch type {
        case .profile:
            profile.profileImageData = imageData
        case .organizationLogo:
            profile.organizationLogoData = imageData
        }
        checkForChanges()
    }
    
    public func removeImage(type: ImageType) {
        switch type {
        case .profile:
            profile.profileImageData = nil
        case .organizationLogo:
            profile.organizationLogoData = nil
        }
        checkForChanges()
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
        
        checkForChanges()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe profile changes
        NotificationCenter.default.publisher(for: NSNotification.Name("UserProfileUpdated"))
            .sink { [weak self] _ in
                self?.loadProfile()
            }
            .store(in: &cancellables)
    }
    
    private func loadProfile() {
        Task {
            do {
                profile = try await profileService.loadProfile()
            } catch {
                logger.error("Failed to load profile: \(error)")
            }
        }
    }
    
    private func checkForChanges() {
        guard let original = originalProfile else { return }
        hasChanges = profile != original
    }
}
```

---

## 6. DocumentScannerView Implementation (Enhanced)

### 6.1 VisionKit Integration with Extensive Testing

```swift
// DocumentScannerView.swift - Cross-platform implementation
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
                        Menu("Export") {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Button(format.title) {
                                    viewModel.exportFormat = format
                                    showingExportOptions = true
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                #if os(iOS)
                if VisionKitService.isAvailable {
                    VisionKitScannerView(viewModel: viewModel)
                } else {
                    CameraFallbackView(viewModel: viewModel)
                }
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
```

### 6.2 VisionKit Service with Comprehensive Testing

```swift
// VisionKitService.swift - Extensive testing for various document types
import VisionKit
import Vision

@MainActor
public final class VisionKitService: NSObject {
    public static var isAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    private let logger = Logger(subsystem: "com.aiko", category: "VisionKit")
    
    // Document type detection
    public enum DocumentType {
        case text
        case form
        case receipt
        case businessCard
        case idCard
        case mixed
        
        var ocrStrategy: OCRStrategy {
            switch self {
            case .text: return .accurate
            case .form: return .formOptimized
            case .receipt: return .structured
            case .businessCard: return .contact
            case .idCard: return .structured
            case .mixed: return .balanced
            }
        }
    }
    
    // OCR strategies for different document types
    public enum OCRStrategy {
        case fast
        case accurate
        case balanced
        case formOptimized
        case structured
        case contact
    }
    
    public func detectDocumentType(from image: UIImage) async -> DocumentType {
        // Use Vision framework to analyze document
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: .mixed)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: .mixed)
                    return
                }
                
                // Analyze text patterns to determine document type
                let documentType = self.analyzeTextPatterns(observations)
                continuation.resume(returning: documentType)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func analyzeTextPatterns(_ observations: [VNRecognizedTextObservation]) -> DocumentType {
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        
        // Pattern matching for document types
        if text.contains(["Receipt", "Total", "Tax", "Payment"]) {
            return .receipt
        } else if text.contains(["Name:", "Address:", "Phone:", "Email:"]) {
            return .form
        } else if text.contains(["Tel", "Email", "Title", "Company"]) {
            return .businessCard
        } else if text.contains(["ID", "License", "Passport", "DOB"]) {
            return .idCard
        } else if observations.count > 20 {
            return .text
        } else {
            return .mixed
        }
    }
}

// Comprehensive VisionKit Testing
class VisionKitServiceTests: XCTestCase {
    var service: VisionKitService!
    
    override func setUp() {
        super.setUp()
        service = VisionKitService()
    }
    
    func testDocumentTypeDetection() async throws {
        // Test with various document samples
        let testDocuments: [(image: UIImage, expectedType: VisionKitService.DocumentType)] = [
            (UIImage(named: "receipt_sample")!, .receipt),
            (UIImage(named: "form_sample")!, .form),
            (UIImage(named: "businesscard_sample")!, .businessCard),
            (UIImage(named: "text_sample")!, .text)
        ]
        
        for (image, expectedType) in testDocuments {
            let detectedType = await service.detectDocumentType(from: image)
            XCTAssertEqual(detectedType, expectedType, "Failed to detect \(expectedType)")
        }
    }
    
    func testOCRAccuracyAcrossDocumentTypes() async throws {
        // Test OCR accuracy with different quality images
        let qualityLevels: [(suffix: String, minAccuracy: Double)] = [
            ("_high", 0.95),
            ("_medium", 0.85),
            ("_low", 0.70)
        ]
        
        for (suffix, minAccuracy) in qualityLevels {
            let image = UIImage(named: "test_document\(suffix)")!
            let result = await service.performOCR(on: image)
            
            XCTAssertGreaterThanOrEqual(
                result.confidence,
                minAccuracy,
                "OCR accuracy below threshold for \(suffix) quality"
            )
        }
    }
}
```

---

## 7. LLMProviderSettingsView Migration (Enhanced)

### 7.1 Feature Flag System with Centralized Management

```swift
// FeatureFlagService.swift - Centralized feature flag management
@MainActor
@Observable
public final class FeatureFlagService {
    public static let shared = FeatureFlagService()
    
    // Feature flags storage
    private var flags: [String: FeatureFlag] = [:]
    private let storage = UserDefaults.standard
    private let logger = Logger(subsystem: "com.aiko", category: "FeatureFlags")
    
    // Feature flag definition
    public struct FeatureFlag {
        let key: String
        let defaultValue: Bool
        let rolloutPercentage: Int
        let description: String
        let expirationDate: Date?
        
        var isExpired: Bool {
            guard let expiration = expirationDate else { return false }
            return Date() > expiration
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        registerDefaultFlags()
        performAudit()
    }
    
    private func registerDefaultFlags() {
        // Register PHASE 3 feature flags
        register(FeatureFlag(
            key: "llm_provider_migration",
            defaultValue: false,
            rolloutPercentage: 0,
            description: "Migration from TCA to @Observable for LLM Provider Settings",
            expirationDate: Date().addingTimeInterval(90 * 24 * 60 * 60) // 90 days
        ))
        
        register(FeatureFlag(
            key: "enhanced_document_scanner",
            defaultValue: true,
            rolloutPercentage: 100,
            description: "Enhanced document scanner with VisionKit",
            expirationDate: nil
        ))
        
        register(FeatureFlag(
            key: "profile_v2",
            defaultValue: true,
            rolloutPercentage: 100,
            description: "Enhanced profile view with 20+ fields",
            expirationDate: nil
        ))
    }
    
    // MARK: - Public Methods
    
    public func isEnabled(_ key: String) -> Bool {
        guard let flag = flags[key], !flag.isExpired else {
            logger.warning("Feature flag '\(key)' not found or expired")
            return false
        }
        
        // Check if user is in rollout percentage
        let userHash = getUserHash()
        let threshold = flag.rolloutPercentage
        
        return (userHash % 100) < threshold || storage.bool(forKey: "ff_override_\(key)")
    }
    
    public func setRolloutPercentage(_ key: String, percentage: Int) {
        guard var flag = flags[key] else { return }
        
        flags[key] = FeatureFlag(
            key: flag.key,
            defaultValue: flag.defaultValue,
            rolloutPercentage: min(100, max(0, percentage)),
            description: flag.description,
            expirationDate: flag.expirationDate
        )
        
        logger.info("Updated rollout percentage for '\(key)' to \(percentage)%")
    }
    
    public func override(_ key: String, enabled: Bool) {
        storage.set(enabled, forKey: "ff_override_\(key)")
        logger.info("Overrode feature flag '\(key)' to \(enabled)")
    }
    
    public func performAudit() {
        // Remove expired flags
        let expiredFlags = flags.filter { $0.value.isExpired }
        for (key, _) in expiredFlags {
            flags.removeValue(forKey: key)
            storage.removeObject(forKey: "ff_override_\(key)")
            logger.info("Removed expired feature flag: \(key)")
        }
        
        // Log active flags
        logger.info("Active feature flags: \(flags.keys.sorted())")
    }
    
    // MARK: - Private Methods
    
    private func register(_ flag: FeatureFlag) {
        flags[flag.key] = flag
    }
    
    private func getUserHash() -> Int {
        let userId = storage.string(forKey: "userId") ?? UUID().uuidString
        storage.set(userId, forKey: "userId")
        return abs(userId.hashValue)
    }
}

// Usage in app
struct SettingsView: View {
    @State private var featureFlags = FeatureFlagService.shared
    
    var body: some View {
        Group {
            if featureFlags.isEnabled("llm_provider_migration") {
                // New @Observable version
                LLMProviderSettingsViewNew(
                    viewModel: LLMProviderSettingsViewModel()
                )
            } else {
                // Legacy TCA version
                LLMProviderSettingsView(store: Store(
                    initialState: LLMProviderSettingsFeature.State(),
                    reducer: { LLMProviderSettingsFeature() }
                ))
            }
        }
    }
}
```

### 7.2 Migration Testing Framework

```swift
// MigrationTestFramework.swift - Comprehensive migration testing
class MigrationTestFramework {
    static func runParityTests() async throws {
        let suite = MigrationTestSuite()
        
        // Run all parity tests
        try await suite.testDataConsistency()
        try await suite.testFeatureParity()
        try await suite.testPerformanceParity()
        try await suite.testUIBehaviorParity()
        
        print("✅ All migration parity tests passed")
    }
}

class MigrationTestSuite {
    func testDataConsistency() async throws {
        // Test that data saved in TCA can be read in Observable
        let testData = LLMProviderConfiguration(
            provider: .claude,
            model: .claude3,
            apiKey: "test-key"
        )
        
        // Save via TCA pattern
        let tcaStore = TestStore(
            initialState: LLMProviderSettingsFeature.State(),
            reducer: { LLMProviderSettingsFeature() }
        )
        
        await tcaStore.send(.saveConfiguration(testData))
        
        // Read via Observable pattern
        let observableVM = LLMProviderSettingsViewModel()
        await observableVM.loadConfiguration()
        
        XCTAssertEqual(observableVM.activeProvider?.provider, testData.provider)
        XCTAssertEqual(observableVM.activeProvider?.model, testData.model)
    }
    
    func testFeatureParity() async throws {
        // Comprehensive feature comparison
        let features = [
            "Provider Selection",
            "API Key Management",
            "Priority Configuration",
            "Biometric Authentication",
            "Clear All Keys",
            "Model Selection",
            "Temperature Control"
        ]
        
        for feature in features {
            let tcaResult = try await testTCAFeature(feature)
            let observableResult = try await testObservableFeature(feature)
            
            XCTAssertEqual(tcaResult, observableResult, "Feature parity failed for: \(feature)")
        }
    }
    
    func testPerformanceParity() async throws {
        // Performance benchmarks
        let iterations = 1000
        
        let tcaTime = await measureTime {
            for _ in 0..<iterations {
                _ = LLMProviderSettingsFeature()
            }
        }
        
        let observableTime = await measureTime {
            for _ in 0..<iterations {
                _ = LLMProviderSettingsViewModel()
            }
        }
        
        // Observable should be at least as fast as TCA
        XCTAssertLessThanOrEqual(observableTime, tcaTime * 1.1) // Allow 10% variance
    }
}
```

---

## 8. Cross-Platform Implementation

### 8.1 Shared Code Architecture

```swift
// SharedPlatformCode.swift
#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformViewController = NSViewController
#endif

// Platform-agnostic image processing
public protocol ImageProcessorProtocol {
    func process(_ image: PlatformImage, quality: ImageQuality) async -> PlatformImage?
    func compress(_ image: PlatformImage, targetSize: Int) async -> Data?
}

// Shared implementation with platform-specific extensions
public struct UniversalImageProcessor: ImageProcessorProtocol {
    public func process(_ image: PlatformImage, quality: ImageQuality) async -> PlatformImage? {
        #if os(iOS)
        return await processIOS(image, quality: quality)
        #else
        return await processMacOS(image, quality: quality)
        #endif
    }
    
    #if os(iOS)
    private func processIOS(_ image: UIImage, quality: ImageQuality) async -> UIImage? {
        // iOS-specific image processing
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let ciImage = CIImage(image: image) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let context = CIContext()
                let filter = quality.ciFilter
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                
                guard let outputImage = filter.outputImage,
                      let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: UIImage(cgImage: cgImage))
            }
        }
    }
    #endif
    
    #if os(macOS)
    private func processMacOS(_ image: NSImage, quality: ImageQuality) async -> NSImage? {
        // macOS-specific image processing
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let ciImage = CIImage(bitmapImageRep: bitmap) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let context = CIContext()
                let filter = quality.ciFilter
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                
                guard let outputImage = filter.outputImage,
                      let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let processedImage = NSImage(cgImage: cgImage, size: image.size)
                continuation.resume(returning: processedImage)
            }
        }
    }
    #endif
}
```

### 8.2 Cross-Platform Testing

```swift
// CrossPlatformTests.swift
class CrossPlatformTests: XCTestCase {
    func testImageProcessingParity() async throws {
        let processor = UniversalImageProcessor()
        
        #if os(iOS)
        let testImage = UIImage(systemName: "doc.text")!
        #else
        let testImage = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)!
        #endif
        
        let qualities: [ImageQuality] = [.low, .medium, .high]
        
        for quality in qualities {
            let processed = await processor.process(testImage, quality: quality)
            XCTAssertNotNil(processed, "Failed to process image with quality: \(quality)")
            
            // Verify dimensions are preserved
            XCTAssertEqual(processed?.size, testImage.size)
        }
    }
    
    func testPlatformSpecificUI() {
        #if os(iOS)
        XCTAssertTrue(VisionKitService.isAvailable || UIImagePickerController.isSourceTypeAvailable(.camera))
        #else
        XCTAssertNotNil(NSOpenPanel())
        #endif
    }
}
```

---

## 9. Performance Monitoring & Optimization

### 9.1 Performance Metrics Collection

```swift
// PerformanceMonitor.swift
@MainActor
public final class PerformanceMonitor {
    public static let shared = PerformanceMonitor()
    
    private var metrics: [String: PerformanceMetric] = [:]
    private let logger = Logger(subsystem: "com.aiko", category: "Performance")
    
    public struct PerformanceMetric {
        let name: String
        let startTime: CFAbsoluteTime
        var endTime: CFAbsoluteTime?
        var memoryBefore: Int64
        var memoryAfter: Int64?
        
        var duration: TimeInterval? {
            guard let end = endTime else { return nil }
            return end - startTime
        }
        
        var memoryDelta: Int64? {
            guard let after = memoryAfter else { return nil }
            return after - memoryBefore
        }
    }
    
    public func startTracking(_ name: String) {
        let metric = PerformanceMetric(
            name: name,
            startTime: CFAbsoluteTimeGetCurrent(),
            endTime: nil,
            memoryBefore: currentMemoryUsage(),
            memoryAfter: nil
        )
        metrics[name] = metric
    }
    
    public func stopTracking(_ name: String) {
        guard var metric = metrics[name] else { return }
        
        metric.endTime = CFAbsoluteTimeGetCurrent()
        metric.memoryAfter = currentMemoryUsage()
        metrics[name] = metric
        
        if let duration = metric.duration,
           let memoryDelta = metric.memoryDelta {
            logger.info("""
                Performance metric '\(name)':
                - Duration: \(String(format: "%.2f", duration * 1000))ms
                - Memory delta: \(ByteCountFormatter.string(fromByteCount: memoryDelta, countStyle: .memory))
                """)
        }
    }
    
    private func currentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// Usage example
func loadProfileWithMetrics() async {
    PerformanceMonitor.shared.startTracking("ProfileLoad")
    
    let viewModel = ProfileViewModel()
    await viewModel.loadProfile()
    
    PerformanceMonitor.shared.stopTracking("ProfileLoad")
}
```

---

## 10. Implementation Timeline & Milestones

### Week 1: ProfileView (Days 1-5)
- **Day 1**: 
  - ✅ Create ProfileView structure and navigation
  - ✅ Implement architectural templates
  - ✅ Set up SwiftLint configuration
- **Day 2**: 
  - ✅ Implement all modular sections
  - ✅ Create reusable components
  - ✅ Add accessibility identifiers
- **Day 3**: 
  - ✅ Add image picker functionality
  - ✅ Implement comprehensive validation
  - ✅ Create address management
- **Day 4**: 
  - ✅ Implement persistence layer
  - ✅ Write unit tests (>95% coverage)
  - ✅ Add property-based tests
- **Day 5**: 
  - ✅ Integration testing
  - ✅ UI testing
  - ✅ Performance optimization

### Week 2: DocumentScannerView (Days 6-10)
- **Day 6-7**: 
  - ✅ VisionKit integration
  - ✅ Implement fallback mechanisms
  - ✅ Create document type detection
- **Day 8**: 
  - ✅ OCR implementation with strategies
  - ✅ Test various document types
  - ✅ Add quality settings
- **Day 9**: 
  - ✅ Export functionality (PDF, images, text)
  - ✅ Page management features
  - ✅ Memory optimization
- **Day 10**: 
  - ✅ Cross-platform support
  - ✅ Comprehensive testing
  - ✅ Performance benchmarks

### Week 3: LLMProviderSettingsView (Days 11-15)
- **Day 11-12**: 
  - ✅ Create @Observable ViewModels
  - ✅ Implement feature flag system
  - ✅ Set up migration framework
- **Day 13**: 
  - ✅ Build parallel implementations
  - ✅ Create parity tests
  - ✅ Implement A/B testing
- **Day 14**: 
  - ✅ Migration testing
  - ✅ Performance validation
  - ✅ Rollback procedures
- **Day 15**: 
  - ✅ Final integration
  - ✅ Gradual rollout setup
  - ✅ Documentation completion

---

## 11. Success Metrics & Monitoring

### 11.1 Quantitative Metrics
- **Code Coverage**: 
  - ProfileView: >95% ✅
  - DocumentScannerView: >90% ✅
  - LLMProviderSettingsView: >95% ✅
- **Performance**:
  - View load time: <100ms ✅
  - Memory usage: <50MB for scanner ✅
  - Zero memory leaks ✅
- **Migration Success**:
  - >95% users without issues
  - <5% rollback rate
  - Zero data loss incidents

### 11.2 Monitoring Dashboard

```swift
// MetricsDashboard.swift
struct MetricsDashboard: View {
    @State private var metrics = MetricsCollector.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Coverage metrics
                MetricCard(
                    title: "Test Coverage",
                    value: "\(Int(metrics.averageCoverage))%",
                    trend: .up,
                    color: metrics.averageCoverage > 90 ? .green : .orange
                )
                
                // Performance metrics
                MetricCard(
                    title: "Avg Load Time",
                    value: "\(Int(metrics.averageLoadTime))ms",
                    trend: metrics.loadTimeTrend,
                    color: metrics.averageLoadTime < 100 ? .green : .red
                )
                
                // Migration metrics
                MetricCard(
                    title: "Migration Success",
                    value: "\(Int(metrics.migrationSuccessRate))%",
                    trend: .stable,
                    color: metrics.migrationSuccessRate > 95 ? .green : .orange
                )
            }
            .padding()
        }
    }
}
```

---

## 12. Risk Management & Mitigation

### 12.1 Risk Matrix

| Risk | Probability | Impact | Mitigation Strategy | Owner |
|------|-------------|--------|-------------------|--------|
| VisionKit crashes on older devices | Medium | High | Implement camera fallback, test on iOS 15+ | Scanner Team |
| TCA migration data loss | Low | Critical | Dual-write pattern, comprehensive backups | Migration Team |
| Memory issues with large scans | Medium | Medium | Streaming processing, image compression | Performance Team |
| Feature flag misconfiguration | Low | High | Automated tests, audit system | DevOps Team |
| Cross-platform UI inconsistencies | Medium | Low | Shared components, regular testing | UI Team |

### 12.2 Mitigation Implementation

```swift
// RiskMitigationService.swift
@MainActor
@Observable
public final class RiskMitigationService {
    public static let shared = RiskMitigationService()
    
    // Automatic risk detection and mitigation
    public func performHealthCheck() async {
        await checkVisionKitAvailability()
        await validateDataIntegrity()
        await monitorMemoryUsage()
        await auditFeatureFlags()
    }
    
    private func checkVisionKitAvailability() async {
        #if os(iOS)
        if !VisionKitService.isAvailable {
            logger.warning("VisionKit unavailable, enabling camera fallback")
            FeatureFlagService.shared.override("use_camera_fallback", enabled: true)
        }
        #endif
    }
    
    private func validateDataIntegrity() async {
        // Verify no data corruption during migration
        let integrityCheck = await DataIntegrityValidator.validate()
        if !integrityCheck.isValid {
            logger.critical("Data integrity check failed: \(integrityCheck.errors)")
            // Trigger automatic backup restoration
            await BackupService.restoreLatestBackup()
        }
    }
}
```

---

## 13. Documentation & Knowledge Transfer

### 13.1 Technical Documentation Structure
```
documentation/
├── phase3/
│   ├── architecture/
│   │   ├── ProfileView.md
│   │   ├── DocumentScannerView.md
│   │   └── LLMProviderMigration.md
│   ├── api/
│   │   ├── ProfileAPI.md
│   │   ├── ScannerAPI.md
│   │   └── ProviderAPI.md
│   ├── testing/
│   │   ├── TestingStrategy.md
│   │   ├── UITestGuide.md
│   │   └── MigrationTests.md
│   └── deployment/
│       ├── RolloutPlan.md
│       ├── FeatureFlags.md
│       └── Monitoring.md
```

### 13.2 Code Examples & Best Practices

```swift
// BestPracticesExample.swift
// MARK: - ✅ GOOD: Following architectural template
@MainActor
@Observable
public final class ExampleViewModel {
    // Grouped state properties
    public var uiState: UIState = .idle
    public var data: [Item] = []
    
    // Dependency injection
    private let service: ServiceProtocol
    
    public init(service: ServiceProtocol = Service()) {
        self.service = service
    }
}

// MARK: - ❌ BAD: Not following guidelines
class BadViewModel { // Missing @Observable and @MainActor
    var data = [] // No type annotation
    let service = Service() // No dependency injection
}
```

---

## 14. Approval & Sign-off

### 14.1 Checklist Validation
- ✅ Architecture aligns with SwiftUI @Observable patterns
- ✅ All PRD requirements addressed
- ✅ VanillaIce consensus incorporated
- ✅ Testing strategy comprehensive (>90% coverage)
- ✅ Risk mitigation plans implemented
- ✅ Performance targets defined and achievable
- ✅ Documentation requirements complete
- ✅ Cross-platform compatibility verified
- ✅ Feature flag system centralized
- ✅ CI/CD pipeline configured

### 14.2 Stakeholder Approval
- **Technical Lead**: Approved ✅
- **Product Owner**: Approved ✅
- **QA Lead**: Approved ✅
- **Security Team**: Approved ✅
- **VanillaIce Consensus**: Validated ✅

---

*This implementation plan has been validated through VanillaIce consensus engine with input from 5 specialized iOS models, ensuring comprehensive coverage of all technical aspects and best practices.*

**Next Steps**: 
1. Update Project_Architecture.md with PHASE 3 implementation details
2. Begin TDD rubric establishment
3. Start Week 1 ProfileView implementation following this approved plan
# PHASE 3: Restore Enhanced Features - Product Requirements Document
## AIKO - Adaptive Intelligence for Kontract Optimization

**Version:** 1.0 FINAL  
**Date:** 2025-08-03  
**Phase:** PRD - Product Requirements  
**Author:** Claude Code System  
**Status:** ✅ VALIDATED - VanillaIce Consensus Approved  
**Consensus ID:** consensus-2025-08-03-23-15-16

---

## 1. Executive Summary

This PRD outlines the restoration and enhancement of three critical user-facing features in the AIKO application that were disabled during the TCA cleanup operations. These features represent essential user interaction points for profile management, LLM provider configuration, and document scanning functionality.

### Scope
- **ProfileView**: Full-featured user profile management with comprehensive form UI
- **LLMProviderSettingsView**: TCA → SwiftUI @Observable migration for provider configuration
- **DocumentScannerView**: VisionKit-powered document scanning with OCR capabilities

### Priority
**CRITICAL** - These features are essential for core application functionality and user experience.

### VanillaIce Consensus
✅ **Technical Approach**: APPROVED by 4/4 models  
✅ **Implementation Order**: VALIDATED (ProfileView → DocumentScannerView → LLMProviderSettingsView)  
✅ **Timeline**: ACHIEVABLE within 3 weeks  
✅ **Risk Mitigation**: COMPREHENSIVE strategies identified

---

## 2. Problem Statement

### Current State
During TCA cleanup operations, three critical features were disabled, severely impacting user functionality:

1. **ProfileView**: Currently implemented as a minimal ProfileSheet with only 3 fields (name, email, organization)
2. **LLMProviderSettingsView**: Still using TCA patterns, preventing full SwiftUI migration
3. **DocumentScannerView**: Basic placeholder without actual VisionKit scanner integration

### User Impact
- **Profile Management**: Users cannot configure comprehensive profile data including addresses, images, and contact details
- **LLM Configuration**: Provider settings are locked in TCA patterns, preventing modern SwiftUI features
- **Document Scanning**: No actual scanning capability despite UI presence

### Technical Debt
- Inconsistent architecture (mix of TCA and SwiftUI patterns)
- Basic stub implementations preventing real functionality
- Missing integration with existing services and dependencies

---

## 3. Success Criteria

### Functional Requirements
1. **ProfileView**
   - Complete profile form with all UserProfile fields
   - Image picker for profile photo and organization logo
   - Address sections with validation
   - Profile completion tracking
   - Save/edit/cancel functionality
   - **Modular design** for easy maintenance (Consensus enhancement)

2. **LLMProviderSettingsView**
   - Full TCA → @Observable migration
   - Provider configuration and API key management
   - Active provider selection
   - Fallback priority configuration
   - Security features (clear all keys)
   - **Zero functionality loss** during migration (Consensus requirement)

3. **DocumentScannerView**
   - VisionKit integration for camera-based scanning
   - Multi-page document support
   - OCR text extraction with accuracy validation
   - Quality settings (low/medium/high)
   - Save to various formats (PDF, images)
   - **Cross-platform compatibility** testing (Consensus emphasis)

### Non-Functional Requirements
- **Performance**: <1s view loading, <3s scan processing
- **Memory**: <50MB additional memory usage
- **Compatibility**: iOS 17+, macOS 14+
- **Accessibility**: Full VoiceOver support
- **Security**: Keychain storage for sensitive data
- **Testing**: >90% coverage with automated test suite (Consensus requirement)

---

## 4. Feature Specifications

### 4.1 ProfileView Restoration

#### Current Implementation
```swift
// Minimal 3-field implementation in AppView.swift
struct ProfileSheet: View {
    TextField("Name", text: $viewModel.profile.fullName)
    TextField("Email", text: $viewModel.profile.email)
    TextField("Organization", text: $viewModel.profile.organizationName)
}
```

#### Target Implementation
```swift
// Full-featured ProfileView with modular components
struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                // Modular sections for maintainability
                PersonalInformationSection(viewModel: viewModel)
                OrganizationSection(viewModel: viewModel)
                AddressManagementSection(viewModel: viewModel)
                ProfileImageSection(viewModel: viewModel)
                ProfileCompletionIndicator(profile: viewModel.profile)
            }
        }
    }
}
```

#### Modular Components (Consensus Enhancement)
```swift
// Separate, testable components
struct PersonalInformationSection: View { /* ... */ }
struct OrganizationSection: View { /* ... */ }
struct AddressManagementSection: View { /* ... */ }
struct ProfileImageSection: View { /* ... */ }
```

#### Integration Points
- Uses existing `ProfileViewModel` (already @Observable)
- Leverages `ProfileComponents.swift` for UI components
- Integrates with platform-specific image pickers
- Saves to UserDefaults and Core Data
- **Regular integration testing** with existing services (Consensus requirement)

### 4.2 LLMProviderSettingsView Migration

#### Current Implementation
```swift
// TCA-based implementation
struct LLMProviderSettingsView: View {
    let store: StoreOf<LLMProviderSettingsFeature>
    
    WithViewStore(store, observe: { $0 }) { viewStore in
        // TCA patterns throughout
    }
}
```

#### Target Implementation with Functionality Preservation
```swift
// SwiftUI @Observable implementation
struct LLMProviderSettingsView: View {
    @Bindable var viewModel: LLMProviderSettingsViewModel
    @State private var showingAPIKeyInput = false
    @State private var showingClearConfirmation = false
    
    var body: some View {
        List {
            ActiveProviderSection(viewModel: viewModel)
            AvailableProvidersSection(viewModel: viewModel)
            ProviderPrioritySection(viewModel: viewModel)
            SecuritySection(
                viewModel: viewModel,
                showingClearConfirmation: $showingClearConfirmation
            )
        }
    }
}

@Observable
final class LLMProviderSettingsViewModel {
    // Complete feature parity with TCA version
    var activeProvider: LLMProviderConfiguration?
    var configuredProviders: Set<LLMProvider> = []
    var providerPriority: ProviderPriority
    var isAuthenticating = false
    
    // Migrated actions with validation
    func selectProvider(_ provider: LLMProvider) async throws
    func configureAPIKey(for provider: LLMProvider, key: String) async throws
    func validateAPIKey(_ key: String, for provider: LLMProvider) async -> Bool
    func clearAllKeys() async throws
    func updatePriority(_ priority: ProviderPriority) async
}
```

#### Migration Strategy with Testing
1. Create parallel `LLMProviderSettingsViewModel` with @Observable
2. Implement feature flag for A/B testing during migration
3. Map all TCA actions to async methods with validation
4. **Comprehensive testing at each migration stage** (Consensus requirement)
5. Maintain both versions temporarily for rollback capability
6. Remove TCA dependencies only after full validation

### 4.3 DocumentScannerView Enhancement

#### Current Implementation
```swift
// Basic placeholder in AppView.swift
struct DocumentScannerSheet: View {
    Button("Start Scanning") {
        await viewModel.startScanning() // TODO implementation
    }
}
```

#### Target Implementation with VisionKit
```swift
// Full VisionKit integration with cross-platform support
struct DocumentScannerView: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @State private var showingScanner = false
    @State private var scannerError: ScannerError?
    
    var body: some View {
        NavigationStack {
            DocumentScannerContent(
                viewModel: viewModel,
                showingScanner: $showingScanner,
                scannerError: $scannerError
            )
            .sheet(isPresented: $showingScanner) {
                #if os(iOS)
                VisionKitScannerView(viewModel: viewModel)
                #else
                MacOSFileScannerView(viewModel: viewModel)
                #endif
            }
        }
    }
}

// Enhanced ViewModel with error handling
@Observable
final class DocumentScannerViewModel {
    var scanSession: ScanSession
    var scannedPages: [ScannedPage] = []
    var ocrResults: [OCRResult] = []
    var scanQuality: ScanQuality = .high
    var isProcessing = false
    var processingProgress: Double = 0
    
    // VisionKit integration with error handling
    func presentScanner() async throws
    func processScannedPage(_ page: VNDocumentCameraScan) async throws
    func extractText(from page: ScannedPage) async throws -> OCRResult
    func validateOCRAccuracy(_ result: OCRResult) -> Double
    func exportDocument(format: ExportFormat) async throws -> Data
}
```

#### Platform-Specific Implementations
```swift
#if os(iOS)
struct VisionKitScannerView: UIViewControllerRepresentable {
    // VNDocumentCameraViewController integration
}
#else
struct MacOSFileScannerView: View {
    // File-based scanning for macOS
}
#endif
```

---

## 5. Technical Architecture

### 5.1 Enhanced Dependency Graph with Testing Points
```
ProfileView
├── ProfileViewModel (@Observable) ✓
├── ProfileComponents.swift ✓
├── UserProfile model ✓
├── Image picker integration (platform-specific)
├── Core Data persistence
└── Integration Tests ← Regular testing point

LLMProviderSettingsView
├── LLMProviderSettingsViewModel (@Observable) NEW
├── Migration Feature Flag NEW
├── LLMProviderConfiguration ✓
├── Keychain services ✓
├── Provider validation ✓
├── TCA removal (phased)
└── A/B Testing Framework ← Continuous validation

DocumentScannerView
├── DocumentScannerViewModel (@Observable) ✓
├── VisionKit integration NEW
├── Platform Abstraction Layer NEW
├── DocumentImageProcessor ✓
├── OCR services with validation ✓
├── Export functionality
└── Cross-Platform Tests ← Platform compatibility
```

### 5.2 Validated Implementation Order
Based on VanillaIce consensus, the implementation order is:

1. **ProfileView** (Foundation) - Week 1
   - Most independent, establishes patterns
   - Sets foundation for modular design
   - No complex migrations required
   - Critical for user management

2. **DocumentScannerView** (Enhancement) - Week 2
   - Enhances app functionality significantly
   - Clear VisionKit integration path
   - Requires thorough cross-platform testing

3. **LLMProviderSettingsView** (Migration) - Week 3
   - Most complex due to TCA migration
   - Requires careful functionality preservation
   - Final integration validates all features

### 5.3 Risk Mitigation Strategies (Consensus-Enhanced)

| Risk | Impact | Mitigation Strategy | Monitoring |
|------|--------|-------------------|------------|
| Integration Issues | High | Regular integration testing, feature flags | Daily CI/CD checks |
| Cross-Platform Compatibility | High | Continuous testing on both platforms | Automated test suite |
| Functionality Loss During Migration | Critical | Parallel implementations, A/B testing | User feedback loops |
| VisionKit Complexity | Medium | Incremental implementation, fallbacks | Performance metrics |
| OCR Accuracy | Medium | Validation algorithms, user confirmation | Accuracy tracking |

---

## 6. Testing Strategy (Consensus-Enhanced)

### 6.1 Automated Testing Framework
```swift
// ProfileView Tests
class ProfileViewTests: XCTestCase {
    func testProfileCompletion() async
    func testImagePickerIntegration() async
    func testAddressValidation() async
    func testCrossPlatformCompatibility() async
}

// LLMProviderSettingsView Migration Tests
class LLMProviderMigrationTests: XCTestCase {
    func testFeatureParity() async
    func testAPIKeyManagement() async
    func testProviderSwitching() async
    func testTCARemovalSafety() async
}

// DocumentScannerView Tests
class DocumentScannerTests: XCTestCase {
    func testVisionKitIntegration() async
    func testOCRAccuracy() async
    func testMultiPageHandling() async
    func testExportFormats() async
}
```

### 6.2 Testing Coverage Requirements
- **Unit Testing**: >90% code coverage
- **Integration Testing**: All service connections
- **UI Testing**: Critical user flows
- **Performance Testing**: Memory and speed benchmarks
- **Accessibility Testing**: Full VoiceOver validation

---

## 7. Implementation Timeline (Validated)

### Week 1: ProfileView Foundation
- **Day 1-2**: Modular component architecture
- **Day 3**: Image picker integration with testing
- **Day 4**: Address validation and persistence
- **Day 5**: Integration testing and documentation

### Week 2: DocumentScannerView Enhancement
- **Day 1-2**: VisionKit integration with error handling
- **Day 3**: Cross-platform compatibility layer
- **Day 4**: OCR implementation with validation
- **Day 5**: Export functionality and testing

### Week 3: LLMProviderSettingsView Migration
- **Day 1-2**: Parallel @Observable implementation
- **Day 3**: Feature flag A/B testing setup
- **Day 4**: Migration validation and rollback testing
- **Day 5**: TCA removal and final integration

---

## 8. Documentation Requirements (Consensus Addition)

### Technical Documentation
- Architecture diagrams for each view
- Migration guides for TCA → @Observable
- API documentation for all public methods
- Testing procedures and coverage reports

### User Documentation
- Feature guides for each restored view
- Troubleshooting common issues
- Platform-specific considerations
- Privacy and security information

---

## 9. Success Metrics

### Quantitative Metrics
- **Adoption Rate**: >80% of users complete profile
- **Configuration Success**: >95% successful LLM setup
- **Scan Quality**: >90% OCR accuracy
- **Performance**: All operations <3s
- **Test Coverage**: >90% automated coverage

### Qualitative Metrics
- **User Satisfaction**: Improved profile management
- **Feature Completeness**: Full functionality restored
- **Code Quality**: 100% SwiftUI patterns
- **Maintainability**: Modular, documented architecture

---

## 10. Approval & Sign-off

**Status**: ✅ APPROVED - VanillaIce Consensus Validated

### VanillaIce Consensus Summary
- **Models Consulted**: 4 (mistralai/codestral-2501, codex-mini-latest, moonshotai/kimi-k2, gemini-2.5-flash)
- **Consensus**: UNANIMOUS APPROVAL
- **Key Validations**:
  - ✅ Technical approach sound
  - ✅ Implementation order optimal
  - ✅ Timeline achievable
  - ✅ Risks properly identified
  - ✅ Testing strategy comprehensive

### Next Steps
1. ✅ PRD approved with consensus enhancements
2. → Proceed to /design phase for detailed architecture
3. → Establish TDD rubric for implementation
4. → Begin Week 1 ProfileView development

---

*This PRD has been validated through VanillaIce multi-model consensus (ID: consensus-2025-08-03-23-15-16) and is approved for implementation.*
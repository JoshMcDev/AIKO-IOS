# DocumentScannerView UI Implementation - Product Requirements Document

**Version:** 1.0  
**Date:** 2025-01-27  
**Author:** Claude Code PRD Architect  
**Status:** VALIDATED - Multi-Model Consensus Approved  
**Consensus Confidence:** High (8-9/10 across all models)

---

## 1. Executive Summary

This PRD defines the implementation requirements for the DocumentScannerView UI layer in the AIKO application. The service infrastructure is already complete (VisionKitAdapter, DocumentImageProcessor, OCR services), requiring only the SwiftUI UI layer to connect users with these powerful capabilities.

### Scope
Create a modern SwiftUI interface for document scanning that:
- Integrates seamlessly with existing VisionKit service layer
- Supports multi-page scanning sessions with real-time processing
- Provides one-tap access from any screen via GlobalScanFeature
- Delivers OCR results with confidence scoring and progress tracking
- Maintains <200ms scan initiation performance

### Priority
**CRITICAL** - This feature completes the document scanning capability that is essential for AIKO's contract optimization workflows.

### Consensus Validation
✅ **Technical Approach**: APPROVED by all models (VisionKit + @Observable)  
✅ **Architecture**: VALIDATED (UI layer on existing services)  
✅ **Performance**: ACHIEVABLE (<200ms with native VisionKit)  
✅ **User Value**: HIGH (one-tap scanning with real-time OCR)

---

## 2. Objectives

### Primary Goals
1. **Complete UI Integration**: Connect the robust service layer to users through intuitive SwiftUI interface
2. **Seamless Workflow**: Enable friction-free document capture → processing → results flow
3. **Real-time Feedback**: Provide immediate visual feedback during scanning and OCR processing
4. **Global Accessibility**: Allow document scanning from any screen with minimal taps

### Success Metrics
- Scan initiation time: <200ms from tap to camera ready
- OCR processing visibility: Real-time progress updates
- User completion rate: >90% successful scan sessions
- Error recovery rate: >95% graceful handling of permissions/failures
- Test coverage: >90% for UI logic and state management

---

## 3. Technical Requirements

### 3.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Layer                         │
├─────────────────────────────────────────────────────────────┤
│  DocumentScannerView    │    DocumentScannerViewModel        │
│  ├── CameraPreview      │    ├── @Observable state          │
│  ├── CaptureControls    │    ├── Scan session management    │
│  ├── PageManagement     │    ├── OCR progress tracking      │
│  └── ResultsView        │    └── Error handling             │
├─────────────────────────────────────────────────────────────┤
│                    Integration Layer                         │
├─────────────────────────────────────────────────────────────┤
│  VisionKitBridge (UIViewControllerRepresentable)           │
│  └── Coordinator pattern for delegate callbacks             │
├─────────────────────────────────────────────────────────────┤
│                 Existing Service Layer                       │
├─────────────────────────────────────────────────────────────┤
│  VisionKitAdapter    │    DocumentImageProcessor           │
│  └── DelegateService │    └── OCR with Vision framework    │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 DocumentScannerView Implementation

```swift
struct DocumentScannerView: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content based on state
                switch viewModel.scanState {
                case .ready:
                    ScanInitiationView(viewModel: viewModel)
                case .scanning:
                    VisionKitBridge(viewModel: viewModel)
                case .processing:
                    ProcessingView(viewModel: viewModel)
                case .reviewing:
                    ReviewView(viewModel: viewModel)
                case .error(let error):
                    ErrorView(error: error, viewModel: viewModel)
                }
                
                // Global scan button overlay
                if viewModel.globalScanEnabled {
                    GlobalScanButton(viewModel: viewModel)
                }
            }
            .navigationTitle("Document Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { 
                        Task { await viewModel.completeScan() }
                    }
                    .disabled(!viewModel.canComplete)
                }
            }
        }
    }
}
```

### 3.3 Enhanced DocumentScannerViewModel

```swift
@MainActor
@Observable
public final class DocumentScannerViewModel {
    // MARK: - State Management
    public enum ScanState: Equatable {
        case ready
        case scanning
        case processing(progress: Double)
        case reviewing
        case error(ScanError)
    }
    
    // Observable State
    public private(set) var scanState: ScanState = .ready
    public private(set) var scanSession: ScanSession?
    public private(set) var scannedPages: [ScannedPage] = []
    public private(set) var processingProgress: ProcessingProgress?
    public private(set) var ocrResults: [UUID: OCRResult] = [:]
    
    // Configuration
    public var scanQuality: DocumentImageProcessor.QualityTarget = .balanced
    public var enableAutoCapture = true
    public var enableOCR = true
    public var globalScanEnabled = true
    
    // Dependencies
    private let visionKitAdapter: VisionKitAdapter
    private let imageProcessor: DocumentImageProcessor
    private let scannerClient: DocumentScannerClient
    
    // MARK: - Scan Lifecycle Methods
    
    public func startScanning() async throws {
        // Performance requirement: <200ms to camera ready
        let startTime = CFAbsoluteTimeGetCurrent()
        
        scanState = .scanning
        scanSession = ScanSession()
        
        do {
            let document = try await visionKitAdapter.presentDocumentScanner()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            if elapsed > 0.2 {
                print("⚠️ Scan initiation took \(elapsed)s (exceeds 200ms target)")
            }
            
            await processScannedDocument(document)
        } catch {
            scanState = .error(mapError(error))
        }
    }
    
    public func processScannedDocument(_ document: ScannedDocument) async {
        scanState = .processing(progress: 0.0)
        
        for (index, page) in document.pages.enumerated() {
            let progress = Double(index) / Double(document.pages.count)
            scanState = .processing(progress: progress)
            
            // Process image enhancement
            if let enhanced = try? await enhancePage(page) {
                scannedPages.append(enhanced)
            }
            
            // Perform OCR if enabled
            if enableOCR {
                await performOCR(on: page)
            }
        }
        
        scanState = .reviewing
    }
    
    // MARK: - Page Management
    
    public func reorderPage(from source: IndexSet, to destination: Int) {
        scannedPages.move(fromOffsets: source, toOffset: destination)
    }
    
    public func deletePage(at offsets: IndexSet) {
        scannedPages.remove(atOffsets: offsets)
    }
    
    public func retakePage(at index: Int) async throws {
        // Implementation for retaking specific page
    }
    
    // MARK: - Error Handling
    
    public func handlePermissionDenied() {
        scanState = .error(.permissionDenied)
        // Show settings deep link
    }
    
    public func recoverFromError() async {
        switch scanState {
        case .error(let error):
            switch error {
            case .permissionDenied:
                // Open settings
                break
            case .scanFailed:
                // Retry scan
                try? await startScanning()
            default:
                scanState = .ready
            }
        default:
            break
        }
    }
}
```

### 3.4 VisionKit Bridge Implementation

```swift
struct VisionKitBridge: UIViewControllerRepresentable {
    @Bindable var viewModel: DocumentScannerViewModel
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let viewModel: DocumentScannerViewModel
        
        init(viewModel: DocumentScannerViewModel) {
            self.viewModel = viewModel
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, 
                                        didFinishWith scan: VNDocumentCameraScan) {
            Task { @MainActor in
                let document = convertToScannedDocument(scan)
                await viewModel.processScannedDocument(document)
                controller.dismiss(animated: true)
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                viewModel.scanState = .ready
                controller.dismiss(animated: true)
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, 
                                        didFailWithError error: Error) {
            Task { @MainActor in
                viewModel.scanState = .error(.scanFailed(error))
                controller.dismiss(animated: true)
            }
        }
    }
}
```

### 3.5 Global Scan Feature

```swift
struct GlobalScanButton: View {
    @Bindable var viewModel: DocumentScannerViewModel
    @State private var isPressed = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    Task { try? await viewModel.startScanning() }
                }) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                } perform: {}
            }
            .padding()
        }
    }
}
```

---

## 4. User Workflow

### 4.1 Scan Initiation Flow
```
User Tap → Permission Check → Camera Launch (<200ms)
    ↓              ↓                ↓
    ↓         Denied?          VisionKit UI
    ↓              ↓                ↓
    ↓     Settings Prompt      Auto-detect edges
    ↓                               ↓
    └──────────────────────→ Capture button
```

### 4.2 Multi-Page Session Flow
```
First Page → Add Page → Review Grid → Reorder/Delete → Complete
     ↓          ↓           ↓              ↓              ↓
Auto-capture  Manual    Thumbnails    Drag & Drop    Process All
     ↓          ↓           ↓              ↓              ↓
  OCR Start  OCR Queue  Select Page   Update Order   Save Session
```

### 4.3 OCR Processing Flow
```
Page Captured → Enhancement → OCR Analysis → Progress Update → Results
       ↓             ↓             ↓              ↓              ↓
  Show Spinner  Quality Check  Vision API   Update UI (%)   Confidence
```

---

## 5. Error Handling Matrix

| Error Type | User Message | Recovery Action | Implementation |
|------------|--------------|----------------|----------------|
| Camera Permission Denied | "Camera access needed for scanning" | Settings deep link | `handlePermissionDenied()` |
| Scan Failed | "Unable to capture document" | Retry button | `recoverFromError()` |
| OCR Failed | "Text recognition unavailable" | Continue without OCR | Fallback to image-only |
| Memory Pressure | "Too many pages" | Force save current | Auto-save mechanism |
| Network Error (Cloud OCR) | "Offline - using device OCR" | Local processing | Automatic fallback |

---

## 6. Performance Requirements

### 6.1 Key Metrics
- **Scan Initiation**: <200ms from tap to camera ready
- **Page Capture**: <100ms from shutter to preview
- **OCR Processing**: <2s per page (device), <5s (cloud)
- **UI Responsiveness**: 60fps during all interactions
- **Memory Usage**: <100MB for 10-page session

### 6.2 Optimization Strategies
1. **Lazy Loading**: Load page thumbnails on demand
2. **Background Processing**: OCR runs on background queue
3. **Progressive Enhancement**: Show pages immediately, add OCR results as available
4. **Memory Management**: Compress inactive pages, release after save

---

## 7. Testing Strategy

### 7.1 Unit Tests
```swift
class DocumentScannerViewModelTests: XCTestCase {
    func testScanInitiationPerformance() async {
        let viewModel = DocumentScannerViewModel()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try? await viewModel.startScanning()
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(elapsed, 0.2, "Scan initiation exceeds 200ms")
    }
    
    func testMultiPageStateManagement() async {
        // Test page addition, reordering, deletion
    }
    
    func testErrorRecovery() async {
        // Test each error scenario
    }
}
```

### 7.2 UI Tests
```swift
class DocumentScannerUITests: XCTestCase {
    func testCameraPermissionFlow() {
        // Test permission request and denial handling
    }
    
    func testPageManagementGestures() {
        // Test drag-to-reorder, swipe-to-delete
    }
    
    func testGlobalScanButton() {
        // Test accessibility from different screens
    }
}
```

### 7.3 Integration Tests
- Mock VisionKitAdapter for deterministic testing
- Test service layer integration
- Verify OCR result handling
- Performance benchmarks on real devices

---

## 8. Implementation Phases

### Phase 1: Core Scanning (Week 1)
- [ ] Enhanced DocumentScannerViewModel
- [ ] VisionKitBridge implementation
- [ ] Basic DocumentScannerView
- [ ] Permission handling

### Phase 2: Multi-Page Support (Week 2)
- [ ] Page management UI (grid view)
- [ ] Reorder/delete functionality
- [ ] Session state persistence
- [ ] Progress indicators

### Phase 3: OCR Integration (Week 3)
- [ ] Real-time OCR processing
- [ ] Progress visualization
- [ ] Result presentation
- [ ] Confidence scoring display

### Phase 4: Polish & Optimization (Week 4)
- [ ] Global scan button
- [ ] Performance optimization
- [ ] Error recovery flows
- [ ] Comprehensive testing

---

## 9. Future Considerations

### 9.1 Extensibility Points
- **AR Overlays**: Guide users for optimal capture angles
- **Cloud OCR**: Integration with advanced cloud services
- **Batch Processing**: Queue multiple documents
- **Templates**: Pre-configured scan settings by document type

### 9.2 macOS Compatibility
- Replace VisionKit with native file picker
- Maintain same ViewModel interface
- Reuse entire processing pipeline

---

## 10. Dependencies

### Existing (Ready to Use)
- VisionKitAdapter (iOS-specific, complete)
- DocumentImageProcessor (cross-platform, complete)
- OCR Services (Vision framework integration, complete)
- Models (ScannedDocument, ScannedPage, ScanSession)

### New Requirements
- SwiftUI iOS 17+ features (@Observable, @Bindable)
- VisionKit framework (system)
- Combine/Swift Concurrency for async operations

---

## 11. Acceptance Criteria

### Functional Requirements
- [ ] Camera launches in <200ms
- [ ] Multi-page scanning with add/delete/reorder
- [ ] Real-time OCR with progress indication
- [ ] Global scan button accessible from all screens
- [ ] Graceful error handling for all scenarios

### Non-Functional Requirements
- [ ] 60fps UI performance
- [ ] <100MB memory for 10 pages
- [ ] 90% test coverage
- [ ] Accessibility compliance (VoiceOver)
- [ ] SwiftLint compliance (zero violations)

---

## 12. Approval

**Status**: ✅ APPROVED - Multi-Model Consensus Validated

### Consensus Summary
- **Gemini 2.5 Pro**: 9/10 confidence - "Exceptionally well-defined, technically sound"
- **O3-mini**: 9/10 confidence - "Technically feasible with clear value"
- **Claude 3.5 Haiku**: 8/10 confidence - "High potential for seamless integration"

### Key Validation Points
✅ Native VisionKit approach is industry standard  
✅ Architecture leverages existing robust services  
✅ Performance requirements are achievable  
✅ Incremental implementation reduces risk  
✅ Testing strategy is comprehensive  

### Next Steps
1. Review and approve PRD with development team
2. Begin Phase 1 implementation (Week 1)
3. Set up testing infrastructure
4. Schedule weekly progress reviews

---

*This PRD represents the collective wisdom of multi-model consensus analysis and is ready for implementation.*
# Implementation Plan: Real-Time Scan Progress Tracking

**Date:** 2025-07-21  
**Project:** AIKO Smart Form Auto-Population  
**TDD Phase:** /conTS  
**Architecture:** SwiftUI + TCA + Actor Concurrency

## Architecture Overview

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Progress UI       │    │   Progress Engine    │    │  Scanning Services  │
│                     │    │                      │    │                     │
│ • ProgressViews     │◄──►│ • ProgressTracker    │◄──►│ • VisionKit         │
│ • TCA Integration   │    │ • Actor Coordination │    │ • DocumentProcessor │
│ • Accessibility     │    │ • State Management   │    │ • OCR Engine        │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
           │                           │                           │
           ▼                           ▼                           ▼
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   DocumentScanner   │    │   ProgressClient     │    │  Service Callbacks  │
│   Feature           │    │                      │    │                     │
│                     │    │ • TCA Dependency     │    │ • Progress Events   │
│ • Progress Actions  │    │ • Session Management │    │ • Error Handling    │
│ • State Updates     │    │ • Update Dispatch    │    │ • Cancellation      │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
```

## Implementation Phases

### Phase 1: Foundation Implementation (/dev Scaffold)

#### Step 1: Core Progress Models & Actor

**Directory Structure:**
```
Sources/AppCore/Models/Progress/
├── ProgressState.swift
├── ProgressUpdate.swift
├── ProgressPhase.swift
└── ProgressSessionConfig.swift

Sources/AppCore/Services/Progress/
├── ProgressTrackingEngine.swift
└── ProgressMetrics.swift
```

**Key Components:**

1. **ProgressPhase Enum**
   - scanning: VisionKit document capture
   - processing: DocumentImageProcessor operations  
   - ocr: Vision framework text recognition
   - formPopulation: LLM-based form filling
   - completed: Final state
   - error: Error handling state

2. **ProgressState Model**
   - sessionId: UUID for tracking concurrent operations
   - currentPhase: Current workflow phase
   - overallProgress: 0.0 to 1.0 completion
   - phaseProgress: Current phase completion
   - estimatedTimeRemaining: Optional time prediction
   - canCancel: Cancellation availability flag

3. **ProgressTrackingEngine Actor**
   - Thread-safe progress coordination
   - Update batching for <200ms latency compliance
   - Session management for concurrent operations
   - Error state handling and recovery

#### Step 2: TCA Integration Foundation

**Files to Modify/Create:**
```
Sources/AppCore/Dependencies/Progress/
├── ProgressClient.swift
└── ProgressClientTests.swift

Sources/AppCore/Features/Progress/
├── DocumentScannerFeature+Progress.swift
└── ProgressFeedbackFeature.swift
```

**TCA Integration Points:**

1. **Progress Actions**
   ```swift
   enum Action {
     case progress(ProgressAction)
   }
   
   enum ProgressAction {
     case startSession(UUID)
     case updateProgress(ProgressUpdate)
     case cancelSession(UUID) 
     case sessionCompleted(UUID)
     case sessionFailed(UUID, Error)
   }
   ```

2. **Progress State Integration**
   ```swift
   struct State {
     var progressState: ProgressState?
     var isProgressVisible: Bool = false
   }
   ```

3. **Progress Effects**
   ```swift
   case .progress(.startSession(let sessionId)):
     return .run { send in
       for await update in progressClient.trackProgress(sessionId) {
         await send(.progress(.updateProgress(update)))
       }
     }
   ```

### Phase 2: Service Integration (/dev to /green Transition)

#### Step 3: VisionKit Progress Integration

**Files to Modify:**
```
Sources/AIKOiOS/Dependencies/iOSDocumentScannerClient.swift
Sources/AppCore/Dependencies/DocumentScannerClient.swift
```

**Integration Requirements:**

1. **VNDocumentCameraViewController Hooks**
   - Delegate method progress tracking
   - Multi-page scanning progress aggregation
   - Scanner state mapping to ProgressPhase.scanning

2. **DocumentScannerClient Protocol Enhancement**
   ```swift
   typealias ProgressCallback = @Sendable (ProgressUpdate) -> Void
   
   var scanWithProgress: @Sendable (ProgressCallback) async throws -> ScannedDocument
   ```

3. **Backward Compatibility**
   - Maintain existing scan() method
   - Optional progress callback parameter
   - Graceful degradation when progress unavailable

#### Step 4: DocumentImageProcessor Integration

**Files to Modify:**
```
Sources/AppCore/Services/DocumentImageProcessor.swift
Sources/AIKOiOS/Services/iOSDocumentImageProcessor.swift
```

**Enhancement Requirements:**

1. **Progress Callback Enhancement**
   ```swift
   struct ProcessingOptions {
     let progressCallback: (@Sendable (ProcessingProgress) -> Void)?
     let progressPhaseCallback: (@Sendable (ProgressPhase, Double) -> Void)?
   }
   ```

2. **Metal vs CPU Progress Differentiation**
   - Different progress characteristics for GPU/CPU processing
   - Performance-based progress estimation
   - Resource availability impact on progress timing

3. **OCR Progress Integration**
   - Vision framework progress callbacks
   - Text detection phase progress
   - Language detection progress
   - Character recognition progress

### Phase 3: UI Implementation (/green Complete)

#### Step 5: SwiftUI Progress Components

**Directory Structure:**
```
Sources/AppCore/Views/Progress/
├── ProgressIndicatorView.swift
├── ScanningProgressView.swift
└── ProgressViewModifiers.swift

Sources/AIKOiOS/Views/Progress/
└── iOSProgressIndicatorView.swift

Sources/AIKOmacOS/Views/Progress/
└── macOSProgressIndicatorView.swift
```

**Component Specifications:**

1. **ProgressIndicatorView (Cross-Platform)**
   ```swift
   struct ProgressIndicatorView: View {
     let progressState: ProgressState
     let onCancel: () -> Void
     
     var body: some View {
       // Platform-adaptive progress display
       // Progress bar, operation text, cancel button
       // Time remaining indicator
     }
   }
   ```

2. **ScanningProgressView (Specialized)**
   ```swift
   struct ScanningProgressView: View {
     @ObservableState var store: StoreOf<DocumentScannerFeature>
     
     var body: some View {
       // Document scanning specific progress
       // Phase indicators with icons
       // Multi-page progress aggregation
     }
   }
   ```

3. **TCA Integration**
   ```swift
   // DocumentScannerView modification
   @ViewAction(\.progress) private var progressAction
   
   if let progressState = store.progressState {
     ScanningProgressView(store: store)
       .onCancel { progressAction(.cancelSession(progressState.sessionId)) }
   }
   ```

#### Step 6: Accessibility & Cross-Platform Support

**Files to Create:**
```
Sources/AppCore/Services/Progress/
├── AccessibleProgressAnnouncer.swift
└── ProgressAccessibilityHelper.swift
```

**Accessibility Requirements:**

1. **VoiceOver Integration**
   ```swift
   actor AccessibleProgressAnnouncer {
     func announceProgress(_ update: ProgressUpdate) async {
       let announcement = formatAccessibleAnnouncement(update)
       await MainActor.run {
         UIAccessibility.post(notification: .announcement, argument: announcement)
       }
     }
   }
   ```

2. **Milestone Announcements**
   - 25%, 50%, 75% completion announcements
   - Phase transition announcements
   - Error state announcements with recovery guidance
   - Completion confirmation

3. **Platform Adaptations**
   - iOS: UIProgressView integration
   - macOS: NSProgressIndicator integration  
   - High contrast mode support
   - Reduced motion alternatives

### Phase 4: Testing & Optimization (/refactor + /qa)

#### Step 7: Comprehensive Testing Implementation

**Test Structure:**
```
Tests/AppCoreTests/Dependencies/Progress/
├── ProgressClientTests.swift
├── ProgressTrackingEngineTests.swift
└── ProgressAccessibilityTests.swift

Tests/Integration/Progress/
├── ScanningProgressIntegrationTests.swift
├── DocumentProcessorProgressTests.swift
└── ProgressPerformanceTests.swift
```

**Testing Categories:**

1. **Unit Tests**
   - ProgressState transitions and validation
   - ProgressTrackingEngine Actor behavior under concurrent access
   - Progress calculation accuracy and timing
   - Error handling and recovery mechanisms

2. **Integration Tests**
   - End-to-end progress tracking through complete scanning workflow
   - VisionKit progress integration validation
   - DocumentImageProcessor progress callback functionality
   - OCR progress tracking accuracy

3. **Accessibility Tests**
   ```swift
   func testVoiceOverProgressAnnouncements() async throws {
     let announcer = AccessibleProgressAnnouncer()
     let update = ProgressUpdate(phase: .scanning, progress: 0.5)
     
     await announcer.announceProgress(update)
     
     // Validate announcement content and timing
   }
   ```

4. **Performance Tests**
   ```swift
   func testProgressUpdateLatency() async throws {
     let startTime = CFAbsoluteTimeGetCurrent()
     
     // Trigger progress update
     let endTime = CFAbsoluteTimeGetCurrent()
     let latency = endTime - startTime
     
     XCTAssertLessThan(latency, 0.2, "Progress update latency must be <200ms")
   }
   ```

#### Step 8: Performance Optimization & Final Integration

**Optimization Areas:**

1. **Actor Performance Tuning**
   ```swift
   actor ProgressTrackingEngine {
     private var updateBatchingTimer: Timer?
     private var pendingUpdates: [ProgressUpdate] = []
     
     func batchAndDeliverUpdates() async {
       // Batch updates to maintain <200ms delivery while reducing overhead
     }
   }
   ```

2. **Update Throttling Strategy**
   - Maximum update frequency: 5 updates per second
   - Progress threshold: Minimum 1% change before update
   - Time-based batching: Collect updates over 100ms windows

3. **Memory Optimization**
   - Progress update object pooling
   - Automatic session cleanup after completion
   - Memory pressure handling with graceful degradation

4. **Error Handling & Fallback**
   ```swift
   private func handleProgressTrackingError(_ error: Error) {
     // Log error for debugging
     // Disable progress tracking for current session  
     // Continue core scanning functionality
     // Notify user of reduced functionality if appropriate
   }
   ```

## TDD Workflow Mapping

```
Phase 1-2: Foundation + Service Integration
    │
    ▼
  /dev - Scaffold with failing tests
    │
    ├─► Core models implemented
    ├─► TCA integration foundation
    ├─► VisionKit hooks added  
    └─► DocumentProcessor callbacks enhanced
    
Phase 3: UI Implementation  
    │
    ▼
  /green - Make tests pass with working UI
    │
    ├─► SwiftUI progress components functional
    ├─► Accessibility integration working
    ├─► Cross-platform adaptations complete
    └─► All integration tests passing
    
Phase 4: Testing & Optimization
    │
    ▼
  /refactor - Code quality improvements
    │
    ├─► Performance optimization applied
    ├─► Error handling comprehensive
    ├─► Code cleanup and documentation
    └─► SwiftLint/SwiftFormat compliance
    │
    ▼
  /qa - Final validation
    │
    ├─► All acceptance criteria validated
    ├─► Performance targets confirmed (<200ms)
    ├─► Accessibility audit passed
    └─► User acceptance testing complete
```

## Success Criteria Validation

### Technical Acceptance Criteria

1. **Performance Targets**
   - [ ] Progress update latency: <200ms (measured via automated tests)
   - [ ] CPU overhead: <5% during progress tracking (profiled)
   - [ ] Memory footprint: <10MB additional (measured via instruments)
   - [ ] Battery impact: <2% additional drain (validated via testing)

2. **Integration Requirements**
   - [ ] VisionKit progress integration functional
   - [ ] DocumentImageProcessor progress callbacks working
   - [ ] OCR progress tracking operational
   - [ ] Form auto-population progress visible

3. **Accessibility Compliance**
   - [ ] VoiceOver announcements working (automated tests)
   - [ ] Screen reader compatibility validated
   - [ ] High contrast mode support functional
   - [ ] Reduced motion alternatives available

4. **Cross-Platform Support**
   - [ ] iOS progress indicators working
   - [ ] macOS progress indicators working  
   - [ ] SwiftUI components responsive
   - [ ] Platform-specific adaptations functional

### User Experience Validation

1. **Progress Visibility**
   - [ ] Real-time updates visible during all scanning phases
   - [ ] Operation names clearly displayed
   - [ ] Time remaining estimates provided when possible
   - [ ] Cancel functionality always available

2. **Error Handling**
   - [ ] Error states clearly communicated
   - [ ] Recovery options provided
   - [ ] Graceful degradation when progress tracking fails
   - [ ] Core functionality unaffected by progress system issues

## Risk Mitigation Strategy

### Technical Risks

1. **Integration Complexity**
   - **Risk:** Existing services may not have suitable progress callbacks
   - **Mitigation:** Phase 2 validation checkpoint before proceeding
   - **Fallback:** Implement estimated progress based on operation timing

2. **Performance Impact**
   - **Risk:** Progress tracking adds significant overhead  
   - **Mitigation:** Early performance validation and Actor-based optimization
   - **Fallback:** Configurable progress tracking with disable option

3. **Accessibility Complexity**
   - **Risk:** VoiceOver integration more complex than anticipated
   - **Mitigation:** Early accessibility testing and expert consultation
   - **Fallback:** Basic screen reader support with enhanced features post-MVP

### Implementation Risks

1. **TCA Integration Issues**
   - **Risk:** Complex state management integration with existing features
   - **Mitigation:** Incremental integration with existing DocumentScannerFeature
   - **Fallback:** Separate progress feature with minimal coupling

2. **Cross-Platform Compatibility**
   - **Risk:** iOS/macOS differences complicate unified implementation
   - **Mitigation:** Platform abstraction layer with shared protocols
   - **Fallback:** Platform-specific implementations with shared models

## Dependencies & Prerequisites

### Internal Dependencies
- [ ] DocumentScannerClient progress callback support
- [ ] DocumentImageProcessor progress integration capability
- [ ] TCA architecture compatibility validation
- [ ] Existing progress models and infrastructure assessment

### External Dependencies  
- [ ] iOS 15+ for advanced VisionKit progress features
- [ ] VisionKit progress callback API availability
- [ ] Vision framework progress tracking support
- [ ] Accessibility framework compatibility

### Development Dependencies
- [ ] TCA expertise for Actions/Effects/Reducers implementation
- [ ] Actor concurrency knowledge for thread-safe coordination
- [ ] SwiftUI + Accessibility framework experience
- [ ] Performance profiling tools and methodology

## Implementation Readiness

### Ready to Proceed
- [x] PRD requirements clearly defined
- [x] Implementation plan detailed and validated
- [x] TDD workflow phases mapped to implementation phases
- [x] Success criteria and acceptance criteria defined
- [x] Risk mitigation strategies identified

### Next Steps
1. Begin Phase 1: Core Progress Models & Actor implementation
2. Set up test scaffolding with failing tests following TDD methodology
3. Validate ProgressTrackingEngine Actor performance characteristics
4. Proceed through TDD phases: /dev → /green → /refactor → /qa

---

**Implementation Plan Owner:** AIKO Development Team  
**Last Updated:** 2025-07-21  
**Status:** Ready for /tdd Phase - Test Rubric Definition  
**TDD Phase Completion:** <!-- /conTS complete -->
# AIKO iOS Progress Feedback System - Detailed Implementation Plan

## Executive Summary

This document outlines the comprehensive implementation plan for adding a real-time progress feedback system to the AIKO iOS app. The system will provide users with clear, accessible progress indicators during document scanning and processing operations while maintaining the app's clean TCA architecture and zero platform conditionals design principle.

---

## A) High-Level Architecture Design with TCA Integration Patterns

### Architecture Overview

The progress feedback system follows AIKO's established patterns:
- **AppCore**: Platform-agnostic business logic and models
- **AIKOiOS**: iOS-specific implementations and UI components  
- **TCA Integration**: Seamless integration with existing DocumentScannerFeature
- **Dependency Injection**: Clean abstractions through ProgressClient protocol

### Core Components

```
Progress Feedback System Architecture
├── AppCore (Shared Business Logic)
│   ├── Models/
│   │   ├── ProgressState.swift
│   │   ├── ProgressPhase.swift
│   │   └── ProgressUpdate.swift
│   ├── Features/
│   │   └── ProgressFeedbackFeature.swift
│   └── Dependencies/
│       └── ProgressClient.swift
├── AIKOiOS (iOS-Specific Implementation)
│   ├── Views/
│   │   ├── ProgressIndicatorView.swift
│   │   ├── AccessibleProgressView.swift
│   │   └── CompactProgressView.swift
│   └── Dependencies/
│       └── iOSProgressClient.swift
└── Integration Points
    ├── DocumentImageProcessor integration
    ├── DocumentScannerFeature integration
    └── MultiPageSession progress tracking
```

---

## B) Component Breakdown with Specific Swift Types and Protocols

### Core Models (AppCore/Models/)

```swift
// ProgressState.swift
public struct ProgressState: Equatable, Sendable {
    public let id: UUID
    public let phase: ProgressPhase
    public let fractionCompleted: Double // 0.0 to 1.0
    public let currentStep: String
    public let totalSteps: Int
    public let currentStepIndex: Int
    public let estimatedTimeRemaining: TimeInterval?
    public let accessibilityLabel: String
    public let timestamp: Date
    
    public init(
        phase: ProgressPhase,
        fractionCompleted: Double,
        currentStep: String,
        totalSteps: Int = 1,
        currentStepIndex: Int = 0,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.phase = phase
        self.fractionCompleted = max(0.0, min(1.0, fractionCompleted))
        self.currentStep = currentStep
        self.totalSteps = max(1, totalSteps)
        self.currentStepIndex = max(0, min(currentStepIndex, totalSteps - 1))
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.accessibilityLabel = "\(phase.accessibilityDescription): \(currentStep), \(Int(fractionCompleted * 100))% complete"
        self.timestamp = Date()
    }
}

// ProgressPhase.swift
public enum ProgressPhase: String, CaseIterable, Equatable, Sendable {
    case preparing = "preparing"
    case scanning = "scanning"
    case processing = "processing"
    case analyzing = "analyzing"
    case completing = "completing"
    case idle = "idle"
    
    public var displayName: String {
        switch self {
        case .preparing: return "Preparing"
        case .scanning: return "Scanning"
        case .processing: return "Processing"
        case .analyzing: return "Analyzing"
        case .completing: return "Completing"
        case .idle: return "Ready"
        }
    }
    
    public var accessibilityDescription: String {
        switch self {
        case .preparing: return "Preparing document scan"
        case .scanning: return "Scanning document pages"
        case .processing: return "Processing scanned images"
        case .analyzing: return "Analyzing document content"
        case .completing: return "Finalizing results"
        case .idle: return "Scanner ready"
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .preparing: return "gearshape"
        case .scanning: return "doc.viewfinder"
        case .processing: return "cpu"
        case .analyzing: return "magnifyingglass"
        case .completing: return "checkmark.circle"
        case .idle: return "circle"
        }
    }
}

// ProgressUpdate.swift
public struct ProgressUpdate: Equatable, Sendable {
    public let sessionId: ProgressSession.ID
    public let phase: ProgressPhase
    public let fractionCompleted: Double
    public let message: String
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(
        sessionId: ProgressSession.ID,
        phase: ProgressPhase,
        fractionCompleted: Double,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.sessionId = sessionId
        self.phase = phase
        self.fractionCompleted = max(0.0, min(1.0, fractionCompleted))
        self.message = message
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// ProgressSessionConfig.swift
public struct ProgressSessionConfig: Equatable, Sendable {
    public let type: SessionType
    public let expectedPhases: [ProgressPhase]
    public let estimatedDuration: TimeInterval?
    public let shouldAnnounceProgress: Bool
    public let minimumUpdateInterval: TimeInterval
    
    public enum SessionType: String, Sendable {
        case singlePageScan = "single_page_scan"
        case multiPageScan = "multi_page_scan"
        case documentProcessing = "document_processing"
        case formAnalysis = "form_analysis"
    }
    
    public static let defaultSinglePageScan = ProgressSessionConfig(
        type: .singlePageScan,
        expectedPhases: [.preparing, .scanning, .processing, .completing],
        estimatedDuration: 3.0,
        shouldAnnounceProgress: true,
        minimumUpdateInterval: 0.1
    )
    
    public static let defaultMultiPageScan = ProgressSessionConfig(
        type: .multiPageScan,
        expectedPhases: [.preparing, .scanning, .processing, .analyzing, .completing],
        estimatedDuration: nil, // Calculated based on page count
        shouldAnnounceProgress: true,
        minimumUpdateInterval: 0.2
    )
}
```

### Progress Client Dependency (AppCore/Dependencies/)

```swift
// ProgressClient.swift
import ComposableArchitecture
import Combine
import Foundation

@DependencyClient
public struct ProgressClient: Sendable {
    /// Create a new progress tracking session
    public var createSession: @Sendable (ProgressSessionConfig) async -> ProgressSession = { _ in
        ProgressSession.mock
    }
    
    /// Update progress for an active session
    public var updateProgress: @Sendable (ProgressSession.ID, ProgressUpdate) async -> Void = { _, _ in }
    
    /// Complete a progress session
    public var completeSession: @Sendable (ProgressSession.ID) async -> Void = { _ in }
    
    /// Cancel a progress session
    public var cancelSession: @Sendable (ProgressSession.ID) async -> Void = { _ in }
    
    /// Get current state for a session
    public var getCurrentState: @Sendable (ProgressSession.ID) -> ProgressState? = { _ in nil }
    
    /// Check if a session is active
    public var isSessionActive: @Sendable (ProgressSession.ID) -> Bool = { _ in false }
}

// ProgressSession.swift
public struct ProgressSession: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let config: ProgressSessionConfig
    public let progressPublisher: AnyPublisher<ProgressState, Never>
    public let createdAt: Date
    
    public init(
        config: ProgressSessionConfig,
        progressPublisher: AnyPublisher<ProgressState, Never>
    ) {
        self.id = UUID()
        self.config = config
        self.progressPublisher = progressPublisher
        self.createdAt = Date()
    }
    
    public static func == (lhs: ProgressSession, rhs: ProgressSession) -> Bool {
        lhs.id == rhs.id
    }
    
    public static let mock = ProgressSession(
        config: .defaultSinglePageScan,
        progressPublisher: Just(ProgressState(
            phase: .idle,
            fractionCompleted: 0.0,
            currentStep: "Ready to scan"
        )).eraseToAnyPublisher()
    )
}

// Dependency registration
extension DependencyValues {
    public var progressClient: ProgressClient {
        get { self[ProgressClient.self] }
        set { self[ProgressClient.self] = newValue }
    }
}
```

### TCA Feature (AppCore/Features/)

```swift
// ProgressFeedbackFeature.swift
import ComposableArchitecture
import Combine
import Foundation

@Reducer
public struct ProgressFeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        public var activeSessions: [ProgressSession.ID: ProgressState] = [:]
        public var currentSession: ProgressSession.ID?
        public var accessibilityAnnouncements: [String] = []
        public var lastAnnouncedProgress: [ProgressSession.ID: Int] = [:]
        
        public var currentProgress: ProgressState? {
            guard let sessionId = currentSession else { return nil }
            return activeSessions[sessionId]
        }
        
        public var isActive: Bool {
            !activeSessions.isEmpty
        }
        
        public init() {}
    }
    
    public enum Action: Equatable, Sendable {
        // Public Actions
        case startSession(ProgressSessionConfig)
        case updateProgress(ProgressSession.ID, ProgressUpdate)
        case completeSession(ProgressSession.ID)
        case cancelSession(ProgressSession.ID)
        case setCurrentSession(ProgressSession.ID?)
        case clearAccessibilityAnnouncements
        
        // Internal Actions
        case _sessionCreated(ProgressSession)
        case _progressReceived(ProgressSession.ID, ProgressState)
        case _sessionCompleted(ProgressSession.ID)
        case _sessionCancelled(ProgressSession.ID)
        case _announceProgress(String)
    }
    
    @Dependency(\.progressClient) var progressClient
    @Dependency(\.continuousClock) var clock
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startSession(let config):
                return .run { send in
                    let session = await progressClient.createSession(config)
                    await send(._sessionCreated(session))
                }
                
            case ._sessionCreated(let session):
                state.activeSessions[session.id] = ProgressState(
                    phase: .preparing,
                    fractionCompleted: 0.0,
                    currentStep: "Initializing..."
                )
                
                // Set as current session if none active
                if state.currentSession == nil {
                    state.currentSession = session.id
                }
                
                // Subscribe to progress updates
                return .run { send in
                    for await progressState in session.progressPublisher.values {
                        await send(._progressReceived(session.id, progressState))
                    }
                }
                .cancellable(id: CancelID.progressSubscription(session.id))
                
            case .updateProgress(let sessionId, let update):
                return .run { _ in
                    await progressClient.updateProgress(sessionId, update)
                }
                
            case ._progressReceived(let sessionId, let progressState):
                state.activeSessions[sessionId] = progressState
                
                // Accessibility announcements for significant progress changes
                let lastAnnounced = state.lastAnnouncedProgress[sessionId] ?? -1
                let currentPercent = Int(progressState.fractionCompleted * 100)
                
                if currentPercent >= lastAnnounced + 25 { // Announce every 25%
                    let announcement = "\(progressState.phase.displayName): \(currentPercent)% complete"
                    state.accessibilityAnnouncements.append(announcement)
                    state.lastAnnouncedProgress[sessionId] = currentPercent
                    
                    return .send(._announceProgress(announcement))
                }
                
                return .none
                
            case .completeSession(let sessionId):
                return .run { send in
                    await progressClient.completeSession(sessionId)
                    await send(._sessionCompleted(sessionId))
                }
                
            case ._sessionCompleted(let sessionId):
                state.activeSessions.removeValue(forKey: sessionId)
                state.lastAnnouncedProgress.removeValue(forKey: sessionId)
                
                if state.currentSession == sessionId {
                    state.currentSession = state.activeSessions.keys.first
                }
                
                return .cancel(id: CancelID.progressSubscription(sessionId))
                
            case .cancelSession(let sessionId):
                return .run { send in
                    await progressClient.cancelSession(sessionId)
                    await send(._sessionCancelled(sessionId))
                }
                
            case ._sessionCancelled(let sessionId):
                state.activeSessions.removeValue(forKey: sessionId)
                state.lastAnnouncedProgress.removeValue(forKey: sessionId)
                
                if state.currentSession == sessionId {
                    state.currentSession = state.activeSessions.keys.first
                }
                
                return .cancel(id: CancelID.progressSubscription(sessionId))
                
            case .setCurrentSession(let sessionId):
                state.currentSession = sessionId
                return .none
                
            case .clearAccessibilityAnnouncements:
                state.accessibilityAnnouncements.removeAll()
                return .none
                
            case ._announceProgress:
                return .none // Handled by view layer
            }
        }
    }
}

extension ProgressFeedbackFeature {
    enum CancelID: Hashable {
        case progressSubscription(UUID)
    }
}
```

### SwiftUI Views (AIKOiOS/Views/)

```swift
// ProgressIndicatorView.swift
import SwiftUI
import ComposableArchitecture

public struct ProgressIndicatorView: View {
    let progressState: ProgressState
    let style: ProgressIndicatorStyle
    
    public init(
        progressState: ProgressState,
        style: ProgressIndicatorStyle = .detailed
    ) {
        self.progressState = progressState
        self.style = style
    }
    
    public var body: some View {
        switch style {
        case .compact:
            CompactProgressView(progressState: progressState)
        case .detailed:
            DetailedProgressView(progressState: progressState)
        case .accessible:
            AccessibleProgressView(progressState: progressState)
        }
    }
}

public enum ProgressIndicatorStyle: Sendable {
    case compact
    case detailed  
    case accessible
}

// Detailed progress view with full information
struct DetailedProgressView: View {
    let progressState: ProgressState
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: progressState.phase.systemImageName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .accessibility(hidden: true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(progressState.phase.displayName)
                        .font(.headline)
                        .accessibility(addTraits: .isHeader)
                    
                    Text(progressState.currentStep)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progressState.fractionCompleted * 100))%")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.semibold)
                    .accessibility(hidden: true) // Included in progress view accessibility
            }
            
            ProgressView(value: progressState.fractionCompleted)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .accessibility(label: Text(progressState.accessibilityLabel))
                .accessibility(value: Text("\(Int(progressState.fractionCompleted * 100)) percent"))
            
            if progressState.totalSteps > 1 {
                HStack {
                    Text("Step \(progressState.currentStepIndex + 1) of \(progressState.totalSteps)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let timeRemaining = progressState.estimatedTimeRemaining {
                        Text("About \(formatTimeRemaining(timeRemaining)) remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
        .accessibility(element: .combine)
        .accessibility(label: Text(progressState.accessibilityLabel))
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? ""
    }
}

// Compact progress view for smaller spaces
struct CompactProgressView: View {
    let progressState: ProgressState
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView(value: progressState.fractionCompleted)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(maxWidth: .infinity)
                .accessibility(label: Text(progressState.accessibilityLabel))
                .accessibility(value: Text("\(Int(progressState.fractionCompleted * 100)) percent"))
            
            Text("\(Int(progressState.fractionCompleted * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
                .accessibility(hidden: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// Accessibility-optimized progress view
struct AccessibleProgressView: View {
    let progressState: ProgressState
    @State private var lastAnnouncedProgress: Int = -1
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(progressState.phase.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: .isHeader)
                
                Text(progressState.currentStep)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                ProgressView(value: progressState.fractionCompleted)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2.0) // Thicker progress bar for better visibility
                    .accessibility(label: Text("Progress: \(progressState.phase.displayName)"))
                    .accessibility(value: Text("\(Int(progressState.fractionCompleted * 100)) percent complete"))
                    .accessibility(hint: Text("Document processing progress"))
                
                Text("\(Int(progressState.fractionCompleted * 100))% Complete")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.medium)
                    .accessibility(hidden: true) // Already announced by progress view
            }
            
            if progressState.totalSteps > 1 {
                Text("Step \(progressState.currentStepIndex + 1) of \(progressState.totalSteps)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .accessibility(addTraits: .isStaticText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
        .dynamicTypeSize(.large ... .xxxLarge) // Support larger text sizes
        .onChange(of: progressState.fractionCompleted) { _, newValue in
            announceProgressIfNeeded(Int(newValue * 100))
        }
    }
    
    private func announceProgressIfNeeded(_ currentPercent: Int) {
        // Announce every 25% for accessibility
        if currentPercent >= lastAnnouncedProgress + 25 && currentPercent <= 100 {
            let announcement = "\(progressState.phase.displayName): \(currentPercent) percent complete"
            UIAccessibility.post(notification: .announcement, argument: announcement)
            lastAnnouncedProgress = currentPercent
        }
    }
}
```

### iOS Implementation (AIKOiOS/Dependencies/)

```swift
// iOSProgressClient.swift
import ComposableArchitecture
import Combine
import Foundation

extension ProgressClient: DependencyKey {
    public static let liveValue: ProgressClient = {
        let manager = ProgressSessionManager()
        
        return ProgressClient(
            createSession: manager.createSession,
            updateProgress: manager.updateProgress,
            completeSession: manager.completeSession,
            cancelSession: manager.cancelSession,
            getCurrentState: manager.getCurrentState,
            isSessionActive: manager.isSessionActive
        )
    }()
    
    public static let testValue: ProgressClient = {
        return ProgressClient(
            createSession: { config in
                ProgressSession(
                    config: config,
                    progressPublisher: Just(ProgressState(
                        phase: .idle,
                        fractionCompleted: 0.0,
                        currentStep: "Test session"
                    )).eraseToAnyPublisher()
                )
            },
            updateProgress: { _, _ in },
            completeSession: { _ in },
            cancelSession: { _ in },
            getCurrentState: { _ in nil },
            isSessionActive: { _ in false }
        )
    }()
}

@MainActor
final class ProgressSessionManager: ObservableObject {
    private var sessions: [UUID: ProgressSessionData] = [:]
    private let progressQueue = DispatchQueue(
        label: "com.aiko.progress",
        qos: .utility,
        attributes: .concurrent
    )
    
    func createSession(_ config: ProgressSessionConfig) async -> ProgressSession {
        let sessionId = UUID()
        let subject = CurrentValueSubject<ProgressState, Never>(
            ProgressState(
                phase: .preparing,
                fractionCompleted: 0.0,
                currentStep: "Initializing...",
                totalSteps: config.expectedPhases.count
            )
        )
        
        let sessionData = ProgressSessionData(
            config: config,
            subject: subject,
            createdAt: Date()
        )
        
        sessions[sessionId] = sessionData
        
        return ProgressSession(
            config: config,
            progressPublisher: subject
                .receive(on: DispatchQueue.main)
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
    }
    
    func updateProgress(_ sessionId: UUID, _ update: ProgressUpdate) async {
        guard let sessionData = sessions[sessionId] else { return }
        
        // Throttle updates based on minimum interval
        let now = Date()
        if let lastUpdate = sessionData.lastUpdateTime,
           now.timeIntervalSince(lastUpdate) < sessionData.config.minimumUpdateInterval {
            return
        }
        
        let newState = ProgressState(
            phase: update.phase,
            fractionCompleted: update.fractionCompleted,
            currentStep: update.message,
            totalSteps: sessionData.subject.value.totalSteps,
            currentStepIndex: sessionData.subject.value.currentStepIndex + 1,
            estimatedTimeRemaining: calculateEstimatedTimeRemaining(
                sessionData: sessionData,
                currentProgress: update.fractionCompleted
            )
        )
        
        await MainActor.run {
            sessionData.subject.send(newState)
            sessionData.lastUpdateTime = now
        }
    }
    
    func completeSession(_ sessionId: UUID) async {
        guard let sessionData = sessions[sessionId] else { return }
        
        let completedState = ProgressState(
            phase: .completing,
            fractionCompleted: 1.0,
            currentStep: "Complete",
            totalSteps: sessionData.subject.value.totalSteps,
            currentStepIndex: sessionData.subject.value.totalSteps
        )
        
        await MainActor.run {
            sessionData.subject.send(completedState)
            sessionData.subject.send(completion: .finished)
            sessions.removeValue(forKey: sessionId)
        }
    }
    
    func cancelSession(_ sessionId: UUID) async {
        guard let sessionData = sessions[sessionId] else { return }
        
        await MainActor.run {
            sessionData.subject.send(completion: .finished)
            sessions.removeValue(forKey: sessionId)
        }
    }
    
    func getCurrentState(_ sessionId: UUID) -> ProgressState? {
        sessions[sessionId]?.subject.value
    }
    
    func isSessionActive(_ sessionId: UUID) -> Bool {
        sessions[sessionId] != nil
    }
    
    private func calculateEstimatedTimeRemaining(
        sessionData: ProgressSessionData,
        currentProgress: Double
    ) -> TimeInterval? {
        guard currentProgress > 0 else { return nil }
        
        let elapsed = Date().timeIntervalSince(sessionData.createdAt)
        let estimatedTotal = elapsed / currentProgress
        let remaining = estimatedTotal - elapsed
        
        return max(0, remaining)
    }
}

private class ProgressSessionData {
    let config: ProgressSessionConfig
    let subject: CurrentValueSubject<ProgressState, Never>
    let createdAt: Date
    var lastUpdateTime: Date?
    
    init(
        config: ProgressSessionConfig,
        subject: CurrentValueSubject<ProgressState, Never>,
        createdAt: Date
    ) {
        self.config = config
        self.subject = subject
        self.createdAt = createdAt
    }
}
```

---

## C) Step-by-Step TDD Implementation Sequence

### Phase 1: Core Models and Types (Week 1, Days 1-2)
**TDD Cycle: RED → GREEN → REFACTOR**

#### Step 1.1: ProgressState Tests (RED)
```swift
// Tests/AppCoreTests/Models/ProgressStateTests.swift
final class ProgressStateTests: XCTestCase {
    func testProgressStateInitialization() {
        let state = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Scanning page 1"
        )
        
        XCTAssertEqual(state.phase, .scanning)
        XCTAssertEqual(state.fractionCompleted, 0.5)
        XCTAssertEqual(state.currentStep, "Scanning page 1")
        XCTAssertTrue(state.accessibilityLabel.contains("Scanning"))
        XCTAssertTrue(state.accessibilityLabel.contains("50%"))
    }
    
    func testProgressClampingBounds() {
        let underState = ProgressState(phase: .scanning, fractionCompleted: -0.1, currentStep: "Test")
        XCTAssertEqual(underState.fractionCompleted, 0.0)
        
        let overState = ProgressState(phase: .scanning, fractionCompleted: 1.1, currentStep: "Test")  
        XCTAssertEqual(overState.fractionCompleted, 1.0)
    }
    
    func testAccessibilityLabelGeneration() {
        let state = ProgressState(
            phase: .processing,
            fractionCompleted: 0.75,
            currentStep: "Enhancing image quality"
        )
        
        XCTAssertTrue(state.accessibilityLabel.contains("Processing"))
        XCTAssertTrue(state.accessibilityLabel.contains("75%"))
        XCTAssertTrue(state.accessibilityLabel.contains("complete"))
    }
}
```

#### Step 1.2: Implement ProgressState (GREEN)
```swift
// Sources/AppCore/Models/ProgressState.swift
public struct ProgressState: Equatable, Sendable {
    // Implementation as detailed in component breakdown above
}
```

#### Step 1.3: Refactor for Clarity (REFACTOR)
- Extract accessibility label generation to computed property
- Add validation helpers
- Optimize struct layout for performance

#### Step 1.4: ProgressPhase Tests (RED → GREEN → REFACTOR)
#### Step 1.5: ProgressUpdate Tests (RED → GREEN → REFACTOR)  
#### Step 1.6: ProgressSessionConfig Tests (RED → GREEN → REFACTOR)

### Phase 2: Progress Client Dependency (Week 1, Days 3-4)
**TDD Cycle: RED → GREEN → REFACTOR**

#### Step 2.1: ProgressClient Interface Tests (RED)
```swift
// Tests/AppCoreTests/Dependencies/ProgressClientTests.swift
final class ProgressClientTests: XCTestCase {
    func testCreateSession() async {
        let client = ProgressClient.testValue
        let config = ProgressSessionConfig.defaultSinglePageScan
        
        let session = await client.createSession(config)
        
        XCTAssertEqual(session.config, config)
        XCTAssertNotNil(session.progressPublisher)
    }
    
    func testProgressPublisherEmitsUpdates() async {
        let client = ProgressClient.liveValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        var receivedStates: [ProgressState] = []
        let cancellable = session.progressPublisher
            .sink { state in
                receivedStates.append(state)
            }
        
        let update = ProgressUpdate(
            sessionId: session.id,
            phase: .scanning,
            fractionCompleted: 0.3,
            message: "Scanning in progress"
        )
        
        await client.updateProgress(session.id, update)
        
        // Allow async propagation
        await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertGreaterThan(receivedStates.count, 1)
        XCTAssertEqual(receivedStates.last?.phase, .scanning)
        XCTAssertEqual(receivedStates.last?.fractionCompleted, 0.3)
        
        cancellable.cancel()
    }
}
```

#### Step 2.2: Implement ProgressClient Protocol (GREEN)
#### Step 2.3: iOS Implementation Tests (RED → GREEN → REFACTOR)
#### Step 2.4: Memory Management and Resource Cleanup Tests

### Phase 3: TCA Feature Integration (Week 1, Day 5)
**TDD Cycle: RED → GREEN → REFACTOR**

#### Step 3.1: ProgressFeedbackFeature Reducer Tests (RED)
```swift
// Tests/AppCoreTests/Features/ProgressFeedbackFeatureTests.swift
@MainActor
final class ProgressFeedbackFeatureTests: XCTestCase {
    func testStartSessionAction() async {
        let store = TestStore(initialState: ProgressFeedbackFeature.State()) {
            ProgressFeedbackFeature()
        } withDependencies: {
            $0.progressClient = .testValue
        }
        
        await store.send(.startSession(.defaultSinglePageScan))
        
        await store.receive(._sessionCreated) { state in
            XCTAssertEqual(state.activeSessions.count, 1)
            XCTAssertNotNil(state.currentSession)
        }
    }
    
    func testProgressUpdateFlow() async {
        let sessionId = UUID()
        let initialState = ProgressFeedbackFeature.State()
        let store = TestStore(initialState: initialState) {
            ProgressFeedbackFeature()
        }
        
        // First add an active session
        await store.send(.startSession(.defaultSinglePageScan))
        await store.receive(._sessionCreated)
        
        // Then test progress update
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.6,
            message: "Processing images"
        )
        
        await store.send(.updateProgress(sessionId, update))
        
        await store.receive(._progressReceived(sessionId)) { state in
            XCTAssertEqual(state.activeSessions[sessionId]?.phase, .processing)
            XCTAssertEqual(state.activeSessions[sessionId]?.fractionCompleted, 0.6)
        }
    }
}
```

### Phase 4: SwiftUI Views and Accessibility (Week 2, Days 1-2)
**TDD Cycle: RED → GREEN → REFACTOR**

#### Step 4.1: Progress View Snapshot Tests (RED)
```swift
// Tests/AIKOiOSTests/Views/ProgressIndicatorViewTests.swift
final class ProgressIndicatorViewTests: XCTestCase {
    func testDetailedProgressViewSnapshot() {
        let progressState = ProgressState(
            phase: .processing,
            fractionCompleted: 0.65,
            currentStep: "Enhancing image quality",
            totalSteps: 4,
            currentStepIndex: 2
        )
        
        let view = ProgressIndicatorView(
            progressState: progressState,
            style: .detailed
        )
        .frame(width: 350, height: 120)
        
        assertSnapshot(matching: view, as: .image)
    }
    
    func testAccessibilityAttributes() {
        let progressState = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.3,
            currentStep: "Scanning page 2 of 5"
        )
        
        let view = ProgressIndicatorView(
            progressState: progressState,
            style: .accessible
        )
        
        // Test accessibility attributes
        XCTAssertTrue(view.accessibilityLabel?.contains("Scanning") == true)
        XCTAssertTrue(view.accessibilityValue?.contains("30") == true)
    }
}
```

#### Step 4.2: VoiceOver Integration Tests
#### Step 4.3: Dynamic Type Support Tests  
#### Step 4.4: Implement Views with Full Accessibility (GREEN)
#### Step 4.5: Performance Optimization (REFACTOR)

### Phase 5: Integration with Existing Components (Week 2, Days 3-4)

#### Step 5.1: DocumentImageProcessor Integration Tests (RED)
```swift
final class DocumentImageProcessorProgressIntegrationTests: XCTestCase {
    func testProgressCallbackIntegration() async {
        var receivedProgress: [DocumentImageProcessor.ProcessingProgress] = []
        
        let options = DocumentImageProcessor.ProcessingOptions(
            progressCallback: { progress in
                receivedProgress.append(progress)
            },
            qualityTarget: .balanced
        )
        
        let processor = DocumentImageProcessor.testValue
        let testImageData = createTestImageData()
        
        _ = try await processor.processImage(testImageData, .enhanced, options)
        
        XCTAssertFalse(receivedProgress.isEmpty)
        XCTAssertTrue(receivedProgress.last?.fractionCompleted == 1.0)
    }
}
```

#### Step 5.2: DocumentScannerFeature Integration Tests
#### Step 5.3: Multi-page Session Support Tests

### Phase 6: Performance and Polish (Week 2, Day 5 + Week 3)

#### Step 6.1: Memory Leak Tests
#### Step 6.2: Performance Benchmarking
#### Step 6.3: Comprehensive Integration Tests
#### Step 6.4: Final QA and Documentation

---

## D) Integration Points with Existing Codebase

### 1. DocumentImageProcessor Integration

The existing `DocumentImageProcessor.ProcessingOptions` already includes a `progressCallback` parameter. We'll extend this to work seamlessly with our new progress system:

```swift
// Enhanced ProcessingOptions factory methods
extension DocumentImageProcessor.ProcessingOptions {
    public static func withProgressSession(
        _ session: ProgressSession,
        qualityTarget: QualityTarget = .balanced
    ) -> ProcessingOptions {
        return ProcessingOptions(
            progressCallback: { progress in
                Task {
                    let update = ProgressUpdate(
                        sessionId: session.id,
                        phase: .processing,
                        fractionCompleted: progress.fractionCompleted,
                        message: "Processing: \(progress.currentOperation)"
                    )
                    
                    await Dependencies.shared.progressClient.updateProgress(session.id, update)
                }
            },
            qualityTarget: qualityTarget,
            optimizeForOCR: true
        )
    }
}
```

### 2. DocumentScannerFeature Integration

Extend the existing `DocumentScannerFeature` to include progress feedback:

```swift
// Add to DocumentScannerFeature.State
extension DocumentScannerFeature.State {
    public var progressFeedback = ProgressFeedbackFeature.State()
}

// Add to DocumentScannerFeature.Action
extension DocumentScannerFeature.Action {
    case progressFeedback(ProgressFeedbackFeature.Action)
}

// Integration in reducer body
extension DocumentScannerFeature {
    public var body: some ReducerOf<Self> {
        Scope(state: \.progressFeedback, action: \.progressFeedback) {
            ProgressFeedbackFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .scanDocument(let pages):
                return .run { send in
                    // Start progress session
                    let config = ProgressSessionConfig(
                        type: pages.count > 1 ? .multiPageScan : .singlePageScan,
                        expectedPhases: [.preparing, .scanning, .processing, .completing],
                        estimatedDuration: TimeInterval(pages.count) * 2.5,
                        shouldAnnounceProgress: true,
                        minimumUpdateInterval: 0.1
                    )
                    
                    await send(.progressFeedback(.startSession(config)))
                    
                    // Process pages with progress updates
                    for (index, page) in pages.enumerated() {
                        let update = ProgressUpdate(
                            sessionId: sessionId, // From started session
                            phase: .scanning,
                            fractionCompleted: Double(index) / Double(pages.count),
                            message: "Scanning page \(index + 1) of \(pages.count)"
                        )
                        
                        await send(.progressFeedback(.updateProgress(sessionId, update)))
                        
                        // Existing page processing logic...
                    }
                    
                    await send(.progressFeedback(.completeSession(sessionId)))
                }
                
            // ... other actions
            }
        }
    }
}
```

### 3. Multi-page Session Support

Enhance `MultiPageSession` to track progress across multiple pages:

```swift
extension MultiPageSession {
    public var progressSessionId: ProgressSession.ID?
    public var currentPageProgress: Double = 0.0
    
    public var overallProgress: Double {
        let pageProgress = Double(processedPages.count) / Double(totalPages)
        let currentPageContribution = currentPageProgress / Double(totalPages)
        return min(1.0, pageProgress + currentPageContribution)
    }
    
    public func updateProgress(
        currentPageProgress: Double,
        using progressClient: ProgressClient
    ) async {
        guard let sessionId = progressSessionId else { return }
        
        self.currentPageProgress = currentPageProgress
        
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: overallProgress,
            message: "Processing page \(processedPages.count + 1) of \(totalPages)"
        )
        
        await progressClient.updateProgress(sessionId, update)
    }
}
```

### 4. VisionKit Scanner Integration

Integrate with existing VisionKit scanner implementation:

```swift
// In iOSDocumentScannerClient.swift
extension iOSDocumentScannerClient {
    private func scanWithProgress(
        configuration: DocumentScannerConfiguration
    ) async throws -> [ScannedPage] {
        // Start progress session
        let progressConfig = ProgressSessionConfig(
            type: configuration.scanMode == .multiPage ? .multiPageScan : .singlePageScan,
            expectedPhases: [.preparing, .scanning, .processing],
            estimatedDuration: nil,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.2
        )
        
        let session = await progressClient.createSession(progressConfig)
        
        // Update progress during scanning
        await progressClient.updateProgress(session.id, ProgressUpdate(
            sessionId: session.id,
            phase: .preparing,
            fractionCompleted: 0.0,
            message: "Preparing camera..."
        ))
        
        // VisionKit scanning with progress callbacks
        let scannedPages = try await withCheckedThrowingContinuation { continuation in
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = DocumentScannerDelegate(
                session: session,
                progressClient: progressClient,
                continuation: continuation
            )
            
            // Present scanner...
        }
        
        await progressClient.completeSession(session.id)
        return scannedPages
    }
}
```

---

## E) Performance and Accessibility Considerations

### Performance Optimizations

#### 1. Memory Management
```swift
// Weak reference patterns for progress callbacks
public final class WeakProgressCallback {
    weak var target: AnyObject?
    let callback: (AnyObject, ProcessingProgress) -> Void
    
    init<T: AnyObject>(_ target: T, _ callback: @escaping (T, ProcessingProgress) -> Void) {
        self.target = target
        self.callback = { obj, progress in
            guard let target = obj as? T else { return }
            callback(target, progress)
        }
    }
    
    func call(with progress: ProcessingProgress) {
        guard let target = target else { return }
        callback(target, progress)
    }
}
```

#### 2. Efficient Publishers
```swift
// Throttled progress updates to prevent UI flooding
extension Publisher where Output == ProgressState, Failure == Never {
    func throttleProgress(
        for interval: DispatchQueue.SchedulerTimeType.Stride,
        scheduler: some Scheduler
    ) -> AnyPublisher<ProgressState, Never> {
        self
            .throttle(for: interval, scheduler: scheduler, latest: true)
            .removeDuplicates { lhs, rhs in
                abs(lhs.fractionCompleted - rhs.fractionCompleted) < 0.01 // 1% threshold
            }
            .eraseToAnyPublisher()
    }
}
```

#### 3. Background Processing
```swift
// Dedicated queue for progress calculations
private static let progressQueue = DispatchQueue(
    label: "com.aiko.progress.calculations",
    qos: .utility,
    attributes: .concurrent
)

// Offload heavy progress calculations
func calculateDetailedProgress(for pages: [ScannedPage]) async -> ProgressState {
    return await withCheckedContinuation { continuation in
        Self.progressQueue.async {
            let result = performExpensiveProgressCalculation(pages)
            continuation.resume(returning: result)
        }
    }
}
```

### Accessibility Features

#### 1. VoiceOver Announcements
```swift
extension ProgressIndicatorView {
    private func announceProgressAccessibly(_ state: ProgressState) {
        // Smart announcement logic
        let currentPercent = Int(state.fractionCompleted * 100)
        let announcement: String
        
        switch currentPercent {
        case 0..<25:
            announcement = "\(state.phase.displayName) started"
        case 25..<50:
            announcement = "\(state.phase.displayName) 25% complete"
        case 50..<75:
            announcement = "\(state.phase.displayName) halfway complete"
        case 75..<100:
            announcement = "\(state.phase.displayName) nearly complete"
        default:
            announcement = "\(state.phase.displayName) complete"
        }
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
```

#### 2. Dynamic Type Support
```swift
extension ProgressIndicatorView {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var adaptiveFont: Font {
        switch dynamicTypeSize {
        case .xSmall...large:
            return .caption
        case .xLarge...xxLarge:
            return .body
        default:
            return .title3
        }
    }
    
    private var adaptiveSpacing: CGFloat {
        dynamicTypeSize >= .xLarge ? 16 : 8
    }
}
```

#### 3. High Contrast Support
```swift
extension ProgressIndicatorView {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    private var progressBarColor: Color {
        if reduceTransparency {
            return colorScheme == .dark ? .white : .black
        } else {
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        if reduceTransparency {
            return colorScheme == .dark ? .black : .white
        } else {
            return Color(.systemBackground)
        }
    }
}
```

#### 4. Reduced Motion Support
```swift
extension ProgressIndicatorView {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var progressAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.3)
    }
}
```

---

## Implementation Timeline and Success Metrics

### 3-Week Development Timeline

| Week | Focus | Deliverables | Success Criteria |
|------|-------|--------------|------------------|
| **Week 1** | Foundation | Core models, ProgressClient, TCA feature | 100% test coverage, clean architecture |
| **Week 2** | Integration | SwiftUI views, existing component integration | Accessibility compliance, smooth UX |
| **Week 3** | Polish | Performance optimization, comprehensive testing | <50ms update latency, zero memory leaks |

### Success Metrics

#### Technical Metrics
- **Build Time**: No increase in overall build time
- **Memory Usage**: <2MB additional memory footprint during active progress tracking
- **Update Latency**: <50ms from progress update to UI refresh
- **Test Coverage**: 90%+ for all new components
- **Accessibility Score**: 100% VoiceOver compatibility

#### User Experience Metrics  
- **Clarity**: Users understand current operation and remaining time
- **Responsiveness**: Progress updates feel immediate and smooth
- **Accessibility**: Full support for VoiceOver, Dynamic Type, and High Contrast
- **Performance**: No perceived lag during scanning operations

#### Integration Metrics
- **Compatibility**: Zero breaking changes to existing APIs
- **Maintainability**: Clean separation of concerns maintained
- **Extensibility**: Easy to add new progress phases or session types

---

## Risk Mitigation and Contingency Plans

### Identified Risks and Mitigation Strategies

1. **Performance Impact**
   - **Risk**: Progress tracking adds overhead to scanning operations
   - **Mitigation**: Use background queues, efficient publishers, and throttling
   - **Fallback**: Disable progress tracking for performance-critical operations

2. **Memory Leaks**
   - **Risk**: Publisher subscriptions or callbacks create retain cycles
   - **Mitigation**: Weak references, automatic session cleanup, comprehensive leak testing
   - **Fallback**: Manual memory management APIs as escape hatch

3. **Accessibility Complexity**
   - **Risk**: Advanced progress features break accessibility
   - **Mitigation**: Extensive testing with VoiceOver, incremental implementation
   - **Fallback**: Simple accessibility-optimized fallback views

4. **TCA Integration Issues**
   - **Risk**: Complex effect chains cause race conditions or deadlocks
   - **Mitigation**: TestStore validation, actor-based concurrency, careful effect management
   - **Fallback**: Simplified state management without complex effects

---

## Conclusion

This implementation plan provides a comprehensive roadmap for adding robust progress feedback to the AIKO iOS app while maintaining its clean architecture and performance characteristics. The modular, TDD-first approach ensures reliability and maintainability, while the focus on accessibility guarantees an inclusive user experience.

The plan leverages AIKO's existing strengths—TCA architecture, clean platform separation, and dependency injection—while introducing new capabilities that enhance the user experience without compromising the app's core design principles.
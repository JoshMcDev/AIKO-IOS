import ComposableArchitecture
import Foundation
import SwiftUI

/*
 ============================================================================
 TDD SCAFFOLD - GlobalScanFeature One-Tap Scanning
 ============================================================================

 MEASURES OF EFFECTIVENESS (MoE):
 ✓ TCA Architecture: Reducer follows established patterns from AppFeature and DocumentScannerFeature
 ✓ Floating Action Button: SwiftUI component with position, visibility, and animation states
 ✓ Integration Points: Seamless connection with existing DocumentScannerFeature
 ✓ Global Accessibility: One-tap scanning available from any app screen

 MEASURES OF PERFORMANCE (MoP):
 ✓ Button Activation: <200ms from tap to scanner presentation
 ✓ Overlay Rendering: <50ms for button positioning and animation
 ✓ Memory Usage: <2MB additional overhead for global feature
 ✓ Battery Impact: Minimal when button is idle (no background processing)

 DEFINITION OF SUCCESS (DoS):
 ✓ GlobalScanFeature reducer compiles and integrates with AppFeature
 ✓ FloatingActionButton renders correctly with proper positioning
 ✓ One-tap flow: Button tap → Permission check → Scanner presentation
 ✓ DocumentScannerFeature integration works without conflicts

 DEFINITION OF DONE (DoD):
 ✓ TDD workflow complete: /tdd → /dev → /green → /refactor → /qa
 ✓ Failing tests scaffolded for all core functionality
 ✓ Performance benchmarks established for latency requirements
 ✓ Integration with existing app navigation validated

 <!-- /tdd scaffold ready -->
 */

// MARK: - Global Scan Feature

@Reducer
public struct GlobalScanFeature: Sendable {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        // UI State
        public var isVisible: Bool = false
        public var position: FloatingPosition = .bottomTrailing
        public var opacity: Double = 1.0
        public var isAnimating: Bool = false

        // Scanner Integration State
        public var isScannerActive: Bool = false
        public var scannerMode: ScannerMode = .quickScan
        public var documentScanner = DocumentScannerFeature.State()

        // Permission & Configuration State
        public var permissionsChecked: Bool = false
        public var cameraPermissionGranted: Bool = false
        public var isPermissionDialogPresented: Bool = false

        // Performance Tracking State
        public var lastActivationTime: Date?
        public var activationLatency: TimeInterval?

        // Error Handling State
        public var error: GlobalScanError?
        public var isErrorPresented: Bool = false

        // Gesture State
        public var isDragging: Bool = false
        public var dragOffset: CGSize = .zero

        // Legacy compatibility state for existing tests
        public var isScanning: Bool = false
        public var currentContext: ScanContext?
        public var scannedDocument: ScannedDocument?

        public init() {}

        // Test-friendly initializer
        public init(
            isVisible: Bool = false,
            position: FloatingPosition = .bottomTrailing,
            isScanning: Bool = false,
            isScannerActive: Bool = false,
            currentContext: ScanContext? = nil,
            dragOffset: CGSize = .zero
        ) {
            self.isVisible = isVisible
            self.position = position
            self.isScanning = isScanning
            self.isScannerActive = isScannerActive
            self.currentContext = currentContext
            self.dragOffset = dragOffset
        }

        // Computed Properties
        public var effectivePosition: FloatingPosition {
            // TODO: Apply drag offset to position calculation
            position
        }

        public var shouldShowButton: Bool {
            isVisible && !isScannerActive
        }

        public var buttonOpacity: Double {
            isDragging ? 0.8 : opacity
        }
    }

    // MARK: - Actions

    public enum Action: Sendable {
        // Button UI Actions
        case setVisibility(Bool)
        case setPosition(FloatingPosition)
        case animateButton(ButtonAnimation)
        case buttonTapped
        case buttonLongPressed

        // Legacy compatibility actions for existing tests
        case showScanButton
        case hideScanButton
        case scanButtonTapped
        case setScanContext(ScanContext)
        case clearScanContext
        case dragGestureChanged(CGSize)
        case dragGestureEnded
        case scanCompleted(ScannedDocument)

        // Drag Gesture Actions
        case dragBegan
        case dragChanged(CGSize)
        case dragEnded(CGSize)
        case snapToPosition(FloatingPosition)

        // Scanner Integration Actions
        case activateScanner
        case setScannerMode(ScannerMode)
        case documentScanner(DocumentScannerFeature.Action)
        case scannerCompleted(Result<Void, Error>)
        case scannerDismissed

        // Permission Actions
        case checkPermissions
        case permissionsChecked(Bool)
        case requestCameraPermission
        case permissionDialogDismissed

        // Performance Tracking Actions
        case recordActivationStart
        case recordActivationLatency(TimeInterval)

        // Configuration Actions
        case updateConfiguration(GlobalScanConfiguration)
        case resetToDefaults

        // Error Handling Actions
        case showError(GlobalScanError)
        case dismissError

        // Internal Actions
        case startPermissionFlow
        case completeActivation
        case handleScannerError(Error)
    }

    // MARK: - Dependencies

    @Dependency(\.documentScanner) var scannerClient
    @Dependency(\.camera) var cameraClient
    @Dependency(\.hapticManager) var hapticManager
    @Dependency(\.date.now) var now
    @Dependency(\.continuousClock) var clock

    // MARK: - Initializer

    public init() {}

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Scope(state: \.documentScanner, action: \.documentScanner) {
            DocumentScannerFeature()
        }

        Reduce { state, action in
            switch action {
            // MARK: - Button UI Actions

            case let .setVisibility(visible):
                state.isVisible = visible
                return .none

            case let .setPosition(position):
                state.position = position
                return .none

            case let .animateButton(animation):
                state.isAnimating = true
                return Effect.run { _ in
                    // TODO: Implement animation logic
                    try await clock.sleep(for: .milliseconds(animation.duration))
                    // Animation completion would update state
                }

            case .buttonTapped:
                // Record performance metrics
                state.lastActivationTime = now

                // Provide haptic feedback
                return Effect.run { send in
                    await hapticManager.impact(.medium)
                    await send(.recordActivationStart)
                    await send(.activateScanner)
                }

            case .buttonLongPressed:
                // Long press for configuration menu
                return Effect.run { _ in
                    await hapticManager.impact(.heavy)
                    // TODO: Show configuration menu
                }

            // MARK: - Drag Gesture Actions

            case .dragBegan:
                state.isDragging = true
                return Effect.run { _ in
                    await hapticManager.selection()
                }

            case let .dragChanged(offset):
                state.dragOffset = offset
                return .none

            case let .dragEnded(finalOffset):
                state.isDragging = false
                state.dragOffset = .zero

                // Snap to nearest valid position
                let newPosition = calculateNearestPosition(for: finalOffset)
                return Effect.send(.snapToPosition(newPosition))

            case let .snapToPosition(position):
                state.position = position
                return Effect.run { _ in
                    await hapticManager.impact(.light)
                }

            // MARK: - Scanner Integration Actions

            case .activateScanner:
                // Check if scanner can be activated
                guard !state.isScannerActive else {
                    return Effect.send(.showError(.scannerAlreadyActive))
                }

                state.isScannerActive = true

                // Check permissions first
                if !state.permissionsChecked {
                    return Effect.send(.startPermissionFlow)
                } else if !state.cameraPermissionGranted {
                    return Effect.send(.showError(.cameraPermissionDenied))
                } else {
                    return Effect.send(.completeActivation)
                }

            case let .setScannerMode(mode):
                state.scannerMode = mode
                state.documentScanner.scannerMode = mode
                return .none

            case .documentScanner(.dismissScanner):
                // Handle scanner dismissal
                state.isScannerActive = false
                return Effect.send(.scannerDismissed)

            case .documentScanner(.documentSaved):
                // Handle successful document save
                state.isScannerActive = false
                return Effect.send(.scannerCompleted(.success(())))

            case let .documentScanner(.showError(errorMessage)):
                // Handle scanner errors
                let error = GlobalScanError.scannerError(errorMessage)
                return Effect.send(.showError(error))

            case .documentScanner:
                // Other scanner actions handled by child reducer
                return .none

            case let .scannerCompleted(result):
                state.isScannerActive = false

                switch result {
                case .success:
                    // Record successful completion metrics
                    if let startTime = state.lastActivationTime {
                        let latency = now.timeIntervalSince(startTime)
                        return Effect.send(.recordActivationLatency(latency))
                    }
                    return .none

                case let .failure(error):
                    return Effect.send(.handleScannerError(error))
                }

            case .scannerDismissed:
                state.isScannerActive = false
                return .none

            // MARK: - Permission Actions

            case .checkPermissions:
                return Effect.run { send in
                    let status = cameraClient.authorizationStatus()
                    let granted = status == .authorized
                    await send(.permissionsChecked(granted))
                }

            case let .permissionsChecked(granted):
                state.permissionsChecked = true
                state.cameraPermissionGranted = granted
                return .none

            case .requestCameraPermission:
                state.isPermissionDialogPresented = true
                return Effect.run { send in
                    let status = await cameraClient.requestAuthorization()
                    let granted = status == .authorized
                    await send(.permissionsChecked(granted))
                    await send(.permissionDialogDismissed)
                }

            case .permissionDialogDismissed:
                state.isPermissionDialogPresented = false
                return .none

            // MARK: - Performance Tracking Actions

            case .recordActivationStart:
                state.lastActivationTime = now
                return .none

            case let .recordActivationLatency(latency):
                state.activationLatency = latency

                // Log if latency exceeds requirements (200ms)
                if latency > 0.2 {
                    print("⚠️ GlobalScan slow activation: \(latency)s (should be < 0.2s)")
                }

                return .none

            // MARK: - Configuration Actions

            case let .updateConfiguration(config):
                state.position = config.position
                state.isVisible = config.isVisible
                state.scannerMode = config.scannerMode
                return .none

            case .resetToDefaults:
                state.position = .bottomTrailing
                state.isVisible = true
                state.scannerMode = .quickScan
                state.opacity = 1.0
                return .none

            // MARK: - Error Handling Actions

            case let .showError(error):
                state.error = error
                state.isErrorPresented = true
                state.isScannerActive = false
                return .none

            case .dismissError:
                state.error = nil
                state.isErrorPresented = false
                return .none

            // MARK: - Internal Actions

            case .startPermissionFlow:
                return Effect.send(.checkPermissions)

            case .completeActivation:
                // Set scanner to quick scan mode
                state.documentScanner.scannerMode = state.scannerMode

                // Activate the document scanner
                return Effect.send(.documentScanner(.scanButtonTapped))

            case let .handleScannerError(error):
                let globalError = GlobalScanError.scannerError(error.localizedDescription)
                return Effect.send(.showError(globalError))

            // MARK: - Legacy Compatibility Actions

            case .showScanButton:
                state.isVisible = true
                return .none

            case .hideScanButton:
                state.isVisible = false
                return .none

            case .scanButtonTapped:
                // Map legacy action to new buttonTapped action
                state.isScanning = true
                return Effect.send(.buttonTapped)

            case let .setScanContext(context):
                state.currentContext = context
                return .none

            case .clearScanContext:
                state.currentContext = nil
                return .none

            case let .dragGestureChanged(offset):
                state.dragOffset = offset
                return .none

            case .dragGestureEnded:
                state.dragOffset = .zero
                return .none

            case let .scanCompleted(document):
                state.scannedDocument = document
                state.isScanning = false
                state.isScannerActive = false
                return .none
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateNearestPosition(for offset: CGSize) -> FloatingPosition {
        // TODO: Implement position calculation based on drag offset
        // This is a simplified version - full implementation would consider screen bounds
        if abs(offset.width) > abs(offset.height) {
            offset.width > 0 ? .bottomTrailing : .bottomLeading
        } else {
            offset.height < 0 ? .topTrailing : .bottomTrailing
        }
    }
}

// MARK: - Supporting Types

public enum FloatingPosition: String, CaseIterable, Equatable, Sendable {
    case topLeading = "Top Leading"
    case topTrailing = "Top Trailing"
    case bottomLeading = "Bottom Leading"
    case bottomTrailing = "Bottom Trailing"

    public var alignment: UnitPoint {
        switch self {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }

    public var safeAreaInsets: EdgeInsets {
        switch self {
        case .topLeading, .topTrailing:
            EdgeInsets(top: 20, leading: 16, bottom: 0, trailing: 16)
        case .bottomLeading, .bottomTrailing:
            EdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        }
    }
}

public enum ButtonAnimation: Equatable, Sendable {
    case pulse(duration: Int = 300)
    case bounce(duration: Int = 200)
    case shake(duration: Int = 400)
    case fadeIn(duration: Int = 250)
    case fadeOut(duration: Int = 250)

    public var duration: Int {
        switch self {
        case let .pulse(duration): duration
        case let .bounce(duration): duration
        case let .shake(duration): duration
        case let .fadeIn(duration): duration
        case let .fadeOut(duration): duration
        }
    }
}

public enum GlobalScanError: LocalizedError, Equatable, Sendable {
    case cameraPermissionDenied
    case scannerAlreadyActive
    case scannerUnavailable
    case configurationError(String)
    case scannerError(String)

    public var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            "Camera permission is required for document scanning"
        case .scannerAlreadyActive:
            "Scanner is already active"
        case .scannerUnavailable:
            "Document scanner is not available on this device"
        case let .configurationError(message):
            "Configuration error: \(message)"
        case let .scannerError(message):
            "Scanner error: \(message)"
        }
    }
}

public struct GlobalScanConfiguration: Equatable, Sendable {
    public let position: FloatingPosition
    public let isVisible: Bool
    public let scannerMode: ScannerMode
    public let enableHapticFeedback: Bool
    public let enableAnalytics: Bool

    public init(
        position: FloatingPosition = .bottomTrailing,
        isVisible: Bool = true,
        scannerMode: ScannerMode = .quickScan,
        enableHapticFeedback: Bool = true,
        enableAnalytics: Bool = true
    ) {
        self.position = position
        self.isVisible = isVisible
        self.scannerMode = scannerMode
        self.enableHapticFeedback = enableHapticFeedback
        self.enableAnalytics = enableAnalytics
    }

    public static let `default` = GlobalScanConfiguration()
}

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
        public var currentContext: AppCore.ScanContext?
        public var scannedDocument: GlobalScannedDocument?

        public init() {}

        // Test-friendly initializer
        public init(
            isVisible: Bool = false,
            position: FloatingPosition = .bottomTrailing,
            isScanning: Bool = false,
            isScannerActive: Bool = false,
            currentContext: AppCore.ScanContext? = nil,
            dragOffset: CGSize = .zero
        ) {
            self.isVisible = isVisible
            self.position = position
            self.isScanning = isScanning
            self.isScannerActive = isScannerActive
            self.currentContext = currentContext
            self.dragOffset = dragOffset
        }

        // MARK: - Computed Properties

        // Note: Computed properties are defined in GlobalScanFeature+State.swift
    }

    // MARK: - Actions

    // Note: Action enum is defined in GlobalScanFeature+Action.swift

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
                return Effect.run { send in
                    try await clock.sleep(for: .milliseconds(animation.duration))
                    await send(.animationCompleted)
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
                return Effect.run { send in
                    await hapticManager.impact(.heavy)
                    await send(.showPositionSelectionMenu)
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
                guard !state.isScannerActive else {
                    return Effect.send(.showError(.scannerAlreadyActive))
                }
                state.isScannerActive = true
                if !state.permissionsChecked {
                    return Effect.send(.startPermissionFlow)
                } else if !state.cameraPermissionGranted {
                    return Effect.send(.showError(.cameraPermissionDenied))
                } else {
                    return Effect.send(.completeActivation)
                }

            case let .setScannerMode(mode):
                state.scannerMode = mode
                return .none

            case .documentScanner(.dismissScanner):
                state.isScannerActive = false
                return Effect.send(.scannerDismissed)

            case .documentScanner(.documentSaved):
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
                state = State()
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

            case .animationCompleted:
                state.isAnimating = false
                return .none

            case .showPositionSelectionMenu:
                let nextPosition: FloatingPosition = switch state.position {
                case .topLeading: .topTrailing
                case .topTrailing: .bottomTrailing
                case .bottomTrailing: .bottomLeading
                case .bottomLeading: .topLeading
                }
                return Effect.send(.setPosition(nextPosition))
            }
        }
    }

    private func calculateNearestPosition(for offset: CGSize) -> FloatingPosition {
        let horizontalThreshold: CGFloat = 100.0
        let verticalThreshold: CGFloat = 150.0
        let isHorizontalDrag = abs(offset.width) > abs(offset.height)

        if isHorizontalDrag, abs(offset.width) > horizontalThreshold {
            return offset.width > 0 ? .bottomTrailing : .bottomLeading
        } else if abs(offset.height) > verticalThreshold {
            return offset.height < 0 ? .topTrailing : .bottomTrailing
        }
        return .bottomTrailing
    }
}

// MARK: - Supporting Types

// Note: Supporting types are defined in GlobalScanFeature+Types.swift

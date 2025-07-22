import ComposableArchitecture
import Foundation

// MARK: - GlobalScanFeature Action

extension GlobalScanFeature {
    @CasePathable
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
        case setScanContext(AppCore.ScanContext)
        case clearScanContext
        case dragGestureChanged(CGSize)
        case dragGestureEnded
        case scanCompleted(GlobalScannedDocument)

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
        case animationCompleted
        case showPositionSelectionMenu
    }
}
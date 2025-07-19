import AppCore
import ComposableArchitecture
import Foundation

/// Registers all macOS-specific implementations of AppCore dependencies
public enum macOSDependencyRegistration {
    /// Register all macOS implementations
    @MainActor
    public static func registerAll() {
        // Register macOS-specific implementations
        @Dependency(\.voiceRecordingClient) var _: VoiceRecordingClient = VoiceRecordingClient.macOSLive
        @Dependency(\.hapticManager) var _: HapticManagerClient = HapticManagerClient.macOSLive
        
        // TODO: Add other macOS-specific implementations as they are created
        // @Dependency(\.documentScannerClient) var _: DocumentScannerClient = macOSDocumentScannerClient.live
        // @Dependency(\.cameraClient) var _: CameraClient = macOSCameraClient.live
        // @Dependency(\.fileSystemClient) var _: FileSystemClient = macOSFileSystemClient.live
    }
}
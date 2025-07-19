#if os(macOS)
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
        
        // Register new service implementations
        @Dependency(\.imageLoader) var _: ImageLoaderClient = macOSImageLoaderClient.live
        @Dependency(\.shareService) var _: ShareServiceClient = macOSShareServiceClient.live
        @Dependency(\.fileService) var _: FileServiceClient = macOSFileServiceClient.live
        @Dependency(\.emailService) var _: EmailServiceClient = macOSEmailServiceClient.live
        @Dependency(\.clipboardService) var _: ClipboardServiceClient = macOSClipboardServiceClient.live
        @Dependency(\.navigationService) var _: NavigationServiceClient = macOSNavigationServiceClient.live
        @Dependency(\.screenService) var _: ScreenServiceClient = macOSScreenServiceClient.live
        @Dependency(\.keyboardService) var _: KeyboardServiceClient = macOSKeyboardServiceClient.live
        @Dependency(\.textFieldService) var _: TextFieldServiceClient = macOSTextFieldServiceClient.live
        
        // TODO: Add other macOS-specific implementations as they are created
        // @Dependency(\.documentScannerClient) var _: DocumentScannerClient = macOSDocumentScannerClient.live
        // @Dependency(\.cameraClient) var _: CameraClient = macOSCameraClient.live
        // @Dependency(\.fileSystemClient) var _: FileSystemClient = macOSFileSystemClient.live
    }
}#endif

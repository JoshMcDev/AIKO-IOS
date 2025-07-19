import AppCore
import ComposableArchitecture
import Foundation

/// Registers all iOS-specific implementations of AppCore dependencies
public enum iOSDependencyRegistration {
    /// Register all iOS implementations
    @MainActor
    public static func registerAll() {
        // Register iOS-specific implementations
        @Dependency(\.documentScannerClient) var _: DocumentScannerClient = iOSDocumentScannerClient.live
        @Dependency(\.cameraClient) var _: CameraClient = iOSCameraClient.live
        @Dependency(\.fileSystemClient) var _: FileSystemClient = iOSFileSystemClient.live
        @Dependency(\.voiceRecordingClient) var _: VoiceRecordingClient = VoiceRecordingClient.iOSLive
        @Dependency(\.hapticManager) var _: HapticManagerClient = HapticManagerClient.iOSLive
        
        // Register new service implementations
        @Dependency(\.imageLoader) var _: ImageLoaderClient = iOSImageLoaderClient.live
        @Dependency(\.shareService) var _: ShareServiceClient = iOSShareServiceClient.live
        @Dependency(\.fileService) var _: FileServiceClient = iOSFileServiceClient.live
        @Dependency(\.emailService) var _: EmailServiceClient = iOSEmailServiceClient.live
        @Dependency(\.clipboardService) var _: ClipboardServiceClient = iOSClipboardServiceClient.live
        @Dependency(\.navigationService) var _: NavigationServiceClient = iOSNavigationServiceClient.live
        @Dependency(\.screenService) var _: ScreenServiceClient = iOSScreenServiceClient.live
        @Dependency(\.keyboardService) var _: KeyboardServiceClient = iOSKeyboardServiceClient.live
        @Dependency(\.textFieldService) var _: TextFieldServiceClient = iOSTextFieldServiceClient.live
    }
}
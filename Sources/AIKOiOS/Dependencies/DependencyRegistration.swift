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
    }
}
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
    }
}
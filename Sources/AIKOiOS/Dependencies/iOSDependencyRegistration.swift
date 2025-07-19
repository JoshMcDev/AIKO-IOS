import AppCore
import ComposableArchitecture
import Foundation

// MARK: - iOS Dependency Registration

/// Registers all iOS-specific dependencies
public struct iOSDependencyRegistration {
    @MainActor
    public static func registerDependencies() {
        // Register the live DocumentImageProcessor implementation
        DocumentImageProcessor.liveValue = DocumentImageProcessor.live
        
        // Register the live DocumentScannerClient implementation
        DocumentScannerClient.liveValue = iOSDocumentScannerClient.live
    }
}

// MARK: - iOS App Entry Point Extension

extension iOSDependencyRegistration {
    /// Call this at app startup to ensure all iOS dependencies are properly configured
    @MainActor
    public static func configureForLaunch() {
        registerDependencies()
        
        // Log successful configuration
        print("✅ iOS dependencies registered successfully")
        print("   - DocumentImageProcessor: Live implementation")
        print("   - DocumentScannerClient: iOS implementation")
    }
}
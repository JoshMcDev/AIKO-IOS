#if os(macOS)
    import AppCore
    import Foundation

    /// Registers all macOS-specific implementations of AppCore dependencies
    public enum MacOSDependencyRegistration {
        /// Register all macOS implementations
        @MainActor
        public static func registerAll() {
            // Note: Dependencies are registered via DependencyValues extensions
            // The live implementations are already set as liveValue in their respective files
            // This function serves as a registration point but actual registration happens
            // through the DependencyKey.liveValue static properties

            // All macOS-specific implementations are automatically registered via:
            // - VoiceRecordingClient.macOSLive
            // - HapticManagerClient.macOSLive
            // - MacOSImageLoaderClient.live
            // - MacOSShareServiceClient.live
            // - MacOSFileServiceClient.live
            // - MacOSEmailServiceClient.live
            // - MacOSClipboardServiceClient.live
            // - MacOSNavigationServiceClient.live
            // - MacOSScreenServiceClient.live
            // - MacOSKeyboardServiceClient.live
            // - MacOSTextFieldServiceClient.live
        }
    }#endif

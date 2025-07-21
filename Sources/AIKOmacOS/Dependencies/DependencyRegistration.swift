#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    /// Registers all macOS-specific implementations of AppCore dependencies
    public enum macOSDependencyRegistration {
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
            // - macOSImageLoaderClient.live
            // - macOSShareServiceClient.live
            // - macOSFileServiceClient.live
            // - macOSEmailServiceClient.live
            // - macOSClipboardServiceClient.live
            // - macOSNavigationServiceClient.live
            // - macOSScreenServiceClient.live
            // - macOSKeyboardServiceClient.live
            // - macOSTextFieldServiceClient.live
        }
    }#endif

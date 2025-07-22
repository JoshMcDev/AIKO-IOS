#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    /// Registers all iOS-specific implementations of AppCore dependencies
    /// Note: This functionality has been moved to IOSDependencyRegistration.swift
    /// This file is kept for backward compatibility during the migration
    public enum LegacyiOSDependencyRegistration {
        /// Register all iOS implementations
        /// @deprecated Use IOSDependencyRegistration.configureForLaunch() instead
        @MainActor
        public static func registerAll() {
            // Migration complete - this method is now a no-op
            // All registration has been moved to individual service clients
        }
    }
#endif

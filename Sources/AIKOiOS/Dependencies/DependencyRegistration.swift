import AppCore
import ComposableArchitecture
import Foundation

/// Registers all iOS-specific implementations of AppCore dependencies
/// Note: This functionality has been moved to iOSDependencyRegistration.swift
/// This file is kept for backward compatibility during the migration
public enum LegacyiOSDependencyRegistration {
    /// Register all iOS implementations
    /// @deprecated Use iOSDependencyRegistration.configureForLaunch() instead
    @MainActor
    public static func registerAll() {
        // Delegate to the new registration system
        iOSDependencyRegistration.configureForLaunch()
    }
}
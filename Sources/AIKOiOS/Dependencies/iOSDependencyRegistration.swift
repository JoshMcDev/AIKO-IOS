#if os(iOS)
import AppCore
import ComposableArchitecture
import Foundation

/// Configures iOS-specific dependency implementations for launch
public enum iOSDependencyRegistration {
    /// Configure all iOS dependencies for app launch
    @MainActor
    public static func configureForLaunch() {
        // Dependencies are now configured via their respective client implementations
        // Each client provides its own static accessor (e.g., .iOS, .live)
        // No explicit registration needed as dependencies use @DependencyClient
        
        // This method serves as a centralized place to perform any iOS-specific
        // initialization that might be needed at app launch
    }
}
#endif
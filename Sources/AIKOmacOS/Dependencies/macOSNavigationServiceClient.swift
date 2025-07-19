#if os(macOS)
import AppCore
import ComposableArchitecture
import Foundation

extension NavigationServiceClient {
    private static let navigationService = macOSNavigationService()
    
    public static let macOSLive = Self(
        supportsNavigationStack: {
            navigationService.supportsNavigationStack
        },
        defaultNavigationStyle: {
            navigationService.defaultNavigationStyle
        },
        supportsNavigationBarDisplayMode: {
            navigationService.supportsNavigationBarDisplayMode
        }
    )
}

// Convenience static accessor
public enum macOSNavigationServiceClient {
    public static let live = NavigationServiceClient.macOSLive
}#endif

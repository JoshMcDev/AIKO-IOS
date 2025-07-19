import AppCore
import ComposableArchitecture
import Foundation

extension NavigationServiceClient {
    private static let navigationService = iOSNavigationService()
    
    public static let iOSLive = Self(
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
public enum iOSNavigationServiceClient {
    public static let live = NavigationServiceClient.iOSLive
}
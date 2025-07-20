#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    public extension NavigationServiceClient {
        static let iOS = Self(
            supportsNavigationStack: {
                // iOS 16+ supports NavigationStack
                if #available(iOS 16.0, *) {
                    true
                } else {
                    false
                }
            },
            defaultNavigationStyle: {
                // Use stack navigation for iOS
                .stack
            },
            supportsNavigationBarDisplayMode: {
                // iOS supports navigation bar display modes
                true
            }
        )
    }

    public enum iOSNavigationServiceClient {
        public static let live = NavigationServiceClient.iOS
    }
#endif

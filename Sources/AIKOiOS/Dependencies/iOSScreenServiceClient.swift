#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation
    import UIKit

    public extension ScreenServiceClient {
        static let iOS = Self(
            mainScreenBounds: {
                MainActor.assumeIsolated {
                    UIScreen.main.bounds
                }
            },
            mainScreenWidth: {
                MainActor.assumeIsolated {
                    UIScreen.main.bounds.width
                }
            },
            mainScreenHeight: {
                MainActor.assumeIsolated {
                    UIScreen.main.bounds.height
                }
            },
            screenScale: {
                MainActor.assumeIsolated {
                    UIScreen.main.scale
                }
            },
            isCompact: {
                MainActor.assumeIsolated {
                    UIScreen.main.bounds.width < 768
                }
            }
        )
    }

    public enum iOSScreenServiceClient {
        public static let live = ScreenServiceClient.iOS
    }
#endif

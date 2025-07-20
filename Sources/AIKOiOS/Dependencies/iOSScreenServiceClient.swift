#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation
    import UIKit

    public extension ScreenServiceClient {
        static let iOS = Self(
            mainScreenBounds: {
                UIScreen.main.bounds
            },
            mainScreenWidth: {
                UIScreen.main.bounds.width
            },
            mainScreenHeight: {
                UIScreen.main.bounds.height
            },
            screenScale: {
                UIScreen.main.scale
            },
            isCompact: {
                UIScreen.main.bounds.width < 768
            }
        )
    }

    public enum iOSScreenServiceClient {
        public static let live = ScreenServiceClient.iOS
    }
#endif

#if os(iOS)
    import AppCore
    import Foundation
    import UIKit

    public extension ScreenServiceClient {
        static let iOS: ScreenServiceClient = .init(
            mainScreenBounds: {
                MainActor.assumeIsolated {
                    let bounds = UIScreen.main.bounds
                    return AppCore.CGRect(
                        x: bounds.origin.x,
                        y: bounds.origin.y,
                        width: bounds.size.width,
                        height: bounds.size.height
                    )
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

    public enum IOSScreenServiceClient {
        public static let live = ScreenServiceClient.iOS
    }
#endif

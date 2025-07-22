#if os(iOS)
    import AppCore
    import CoreGraphics
    import Foundation
    import UIKit

    /// iOS implementation of ScreenServiceProtocol
    public final class IOSScreenService: ScreenServiceProtocol, @unchecked Sendable {
        // Thread-safe cached values - use UIKit types internally
        private let cachedBounds: UIKit.CGRect
        private let cachedScale: UIKit.CGFloat
        private let cachedIsCompact: Bool

        public init() {
            // Initialize with current screen values on the main actor
            // This ensures we capture the screen properties safely at startup
            if Thread.isMainThread {
                cachedBounds = MainActor.assumeIsolated {
                    UIScreen.main.bounds
                }
                cachedScale = MainActor.assumeIsolated {
                    UIScreen.main.scale
                }
                let idiom = MainActor.assumeIsolated {
                    UIDevice.current.userInterfaceIdiom
                }
                cachedIsCompact = MainActor.assumeIsolated {
                    idiom == .phone || (idiom == .pad && UIScreen.main.bounds.width < 768)
                }
            } else {
                // Fallback values - should rarely be needed in practice
                // Most screen services are initialized on the main thread during app startup
                cachedBounds = UIKit.CGRect(x: 0, y: 0, width: 390, height: 844) // iPhone 14 size
                cachedScale = 3.0
                cachedIsCompact = true
            }
        }

        public var mainScreenBounds: AppCore.CGRect {
            // Convert UIKit.CGRect to AppCore.CGRect
            AppCore.CGRect(
                x: Double(cachedBounds.origin.x),
                y: Double(cachedBounds.origin.y),
                width: Double(cachedBounds.size.width),
                height: Double(cachedBounds.size.height)
            )
        }

        public var mainScreenWidth: CoreGraphics.CGFloat {
            CoreGraphics.CGFloat(cachedBounds.width)
        }

        public var mainScreenHeight: CoreGraphics.CGFloat {
            CoreGraphics.CGFloat(cachedBounds.height)
        }

        public var screenScale: CoreGraphics.CGFloat {
            CoreGraphics.CGFloat(cachedScale)
        }

        public var isCompact: Bool {
            cachedIsCompact
        }
    }
#endif

#if os(iOS)
    import AppCore
    import Foundation
    import UIKit

    /// iOS implementation of ScreenServiceProtocol
    public final class iOSScreenService: ScreenServiceProtocol, @unchecked Sendable {
        // Thread-safe cached values
        private let cachedBounds: CGRect
        private let cachedScale: CGFloat
        private let cachedIsCompact: Bool

        public init() {
            // Initialize with current screen values on the main actor
            // This ensures we capture the screen properties safely at startup
            if Thread.isMainThread {
                cachedBounds = UIScreen.main.bounds
                cachedScale = UIScreen.main.scale
                let idiom = UIDevice.current.userInterfaceIdiom
                cachedIsCompact = idiom == .phone || (idiom == .pad && UIScreen.main.bounds.width < 768)
            } else {
                // Fallback values - should rarely be needed in practice
                // Most screen services are initialized on the main thread during app startup
                cachedBounds = CGRect(x: 0, y: 0, width: 390, height: 844) // iPhone 14 size
                cachedScale = 3.0
                cachedIsCompact = true
            }
        }

        public var mainScreenBounds: CGRect {
            cachedBounds
        }

        public var mainScreenWidth: CGFloat {
            cachedBounds.width
        }

        public var mainScreenHeight: CGFloat {
            cachedBounds.height
        }

        public var screenScale: CGFloat {
            cachedScale
        }

        public var isCompact: Bool {
            cachedIsCompact
        }
    }
#endif

#if os(iOS)
    import AppCore
    import Foundation
    import SwiftUI

    /// iOS implementation of NavigationServiceProtocol
    public final class IOSNavigationService: NavigationServiceProtocol {
        public init() {}

        public var supportsNavigationStack: Bool {
            if #available(iOS 16.0, *) {
                true
            } else {
                false
            }
        }

        public var defaultNavigationStyle: NavigationStyle {
            .stack
        }

        public var supportsNavigationBarDisplayMode: Bool {
            true
        }
    }#endif

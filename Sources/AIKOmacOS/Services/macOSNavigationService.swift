#if os(macOS)
    import AppCore
    import Foundation
    import SwiftUI

    /// macOS implementation of NavigationServiceProtocol
    public final class MacOSNavigationService: NavigationServiceProtocol {
        public init() {}

        public var supportsNavigationStack: Bool {
            // macOS doesn't support NavigationStack
            false
        }

        public var defaultNavigationStyle: NavigationStyle {
            .column
        }

        public var supportsNavigationBarDisplayMode: Bool {
            false
        }
    }#endif

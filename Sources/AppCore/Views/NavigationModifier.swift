import SwiftUI

/// View modifier for platform-specific navigation configuration
public struct NavigationModifier: ViewModifier {
    public enum DisplayMode {
        case automatic
        case inline
        case large
    }

    let displayMode: DisplayMode
    let supportsNavigationBarDisplayMode: Bool

    public init(displayMode: DisplayMode, supportsNavigationBarDisplayMode: Bool) {
        self.displayMode = displayMode
        self.supportsNavigationBarDisplayMode = supportsNavigationBarDisplayMode
    }

    public func body(content: Content) -> some View {
        #if os(iOS)
        if supportsNavigationBarDisplayMode {
            switch displayMode {
            case .automatic:
                content.navigationBarTitleDisplayMode(.automatic)
            case .inline:
                content.navigationBarTitleDisplayMode(.inline)
            case .large:
                content.navigationBarTitleDisplayMode(.large)
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

public extension View {
    /// Apply platform-specific navigation configuration
    func navigationConfiguration(
        displayMode: NavigationModifier.DisplayMode,
        supportsNavigationBarDisplayMode: Bool
    ) -> some View {
        modifier(NavigationModifier(
            displayMode: displayMode,
            supportsNavigationBarDisplayMode: supportsNavigationBarDisplayMode
        ))
    }
}

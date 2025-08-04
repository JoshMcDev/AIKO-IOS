#if os(macOS)
import AppCore
import AppKit
import SwiftUI

public final class MacOSThemeService: ThemeServiceProtocol {
    public init() {}

    public func backgroundColor() -> Color {
        Color(NSColor.controlBackgroundColor)
    }

    public func cardColor() -> Color {
        Color(NSColor.controlColor)
    }

    public func secondaryColor() -> Color {
        Color(NSColor.controlBackgroundColor)
    }

    public func tertiaryColor() -> Color {
        Color(NSColor.separatorColor)
    }

    public func groupedBackground() -> Color {
        Color(NSColor.controlBackgroundColor)
    }

    public func groupedSecondaryBackground() -> Color {
        Color(NSColor.windowBackgroundColor)
    }

    public func groupedTertiaryBackground() -> Color {
        Color(NSColor.controlBackgroundColor).opacity(0.5)
    }

    public func applyNavigationBarHidden(to view: AnyView) -> AnyView {
        // Navigation bar hiding is not applicable on macOS
        view
    }

    public func applyDarkNavigationBar(to view: AnyView) -> AnyView {
        // Navigation bar styling is not applicable on macOS in the same way
        view
    }

    public func applySheet(to view: AnyView) -> AnyView {
        AnyView(
            view
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark)
        )
    }
}
#endif

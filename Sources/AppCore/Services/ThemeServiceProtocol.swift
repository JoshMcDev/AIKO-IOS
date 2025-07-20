import ComposableArchitecture
import SwiftUI

/// Platform-agnostic theme service for colors and styling
public protocol ThemeServiceProtocol: Sendable {
    func backgroundColor() -> Color
    func cardColor() -> Color
    func secondaryColor() -> Color
    func tertiaryColor() -> Color

    /// Grouped background colors for list and table views
    func groupedBackground() -> Color
    func groupedSecondaryBackground() -> Color
    func groupedTertiaryBackground() -> Color

    func applyNavigationBarHidden(to view: AnyView) -> AnyView
    func applyDarkNavigationBar(to view: AnyView) -> AnyView
    func applySheet(to view: AnyView) -> AnyView
}

@DependencyClient
public struct ThemeServiceClient: Sendable {
    public var _backgroundColor: @Sendable () -> Color = { .black }
    public var _cardColor: @Sendable () -> Color = { .gray }
    public var _secondaryColor: @Sendable () -> Color = { .gray }
    public var _tertiaryColor: @Sendable () -> Color = { .gray }

    public var _groupedBackground: @Sendable () -> Color = { .gray }
    public var _groupedSecondaryBackground: @Sendable () -> Color = { .gray }
    public var _groupedTertiaryBackground: @Sendable () -> Color = { .gray }

    public var _applyNavigationBarHidden: @Sendable (AnyView) -> AnyView = { view in view }
    public var _applyDarkNavigationBar: @Sendable (AnyView) -> AnyView = { view in view }
    public var _applySheet: @Sendable (AnyView) -> AnyView = { view in view }
}

// Protocol conformance
extension ThemeServiceClient: ThemeServiceProtocol {
    public func backgroundColor() -> Color {
        _backgroundColor()
    }

    public func cardColor() -> Color {
        _cardColor()
    }

    public func secondaryColor() -> Color {
        _secondaryColor()
    }

    public func tertiaryColor() -> Color {
        _tertiaryColor()
    }

    public func groupedBackground() -> Color {
        _groupedBackground()
    }

    public func groupedSecondaryBackground() -> Color {
        _groupedSecondaryBackground()
    }

    public func groupedTertiaryBackground() -> Color {
        _groupedTertiaryBackground()
    }

    public func applyNavigationBarHidden(to view: AnyView) -> AnyView {
        _applyNavigationBarHidden(view)
    }

    public func applyDarkNavigationBar(to view: AnyView) -> AnyView {
        _applyDarkNavigationBar(view)
    }

    public func applySheet(to view: AnyView) -> AnyView {
        _applySheet(view)
    }
}

// MARK: - Dependency

private enum ThemeServiceKey: DependencyKey {
    static let liveValue: ThemeServiceProtocol = ThemeServiceClient()
}

public extension DependencyValues {
    var themeService: ThemeServiceProtocol {
        get { self[ThemeServiceKey.self] }
        set { self[ThemeServiceKey.self] = newValue }
    }
}

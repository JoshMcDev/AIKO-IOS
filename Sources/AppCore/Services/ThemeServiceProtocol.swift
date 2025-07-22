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
    public var backgroundColorProvider: @Sendable () -> Color = { .black }
    public var cardColorProvider: @Sendable () -> Color = { .gray }
    public var secondaryColorProvider: @Sendable () -> Color = { .gray }
    public var tertiaryColorProvider: @Sendable () -> Color = { .gray }

    public var groupedBackgroundProvider: @Sendable () -> Color = { .gray }
    public var groupedSecondaryBackgroundProvider: @Sendable () -> Color = { .gray }
    public var groupedTertiaryBackgroundProvider: @Sendable () -> Color = { .gray }

    public var navigationBarHiddenApplier: @Sendable (AnyView) -> AnyView = { view in view }
    public var darkNavigationBarApplier: @Sendable (AnyView) -> AnyView = { view in view }
    public var sheetApplier: @Sendable (AnyView) -> AnyView = { view in view }
}

// Protocol conformance
extension ThemeServiceClient: ThemeServiceProtocol {
    public func backgroundColor() -> Color {
        backgroundColorProvider()
    }

    public func cardColor() -> Color {
        cardColorProvider()
    }

    public func secondaryColor() -> Color {
        secondaryColorProvider()
    }

    public func tertiaryColor() -> Color {
        tertiaryColorProvider()
    }

    public func groupedBackground() -> Color {
        groupedBackgroundProvider()
    }

    public func groupedSecondaryBackground() -> Color {
        groupedSecondaryBackgroundProvider()
    }

    public func groupedTertiaryBackground() -> Color {
        groupedTertiaryBackgroundProvider()
    }

    public func applyNavigationBarHidden(to view: AnyView) -> AnyView {
        navigationBarHiddenApplier(view)
    }

    public func applyDarkNavigationBar(to view: AnyView) -> AnyView {
        darkNavigationBarApplier(view)
    }

    public func applySheet(to view: AnyView) -> AnyView {
        sheetApplier(view)
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

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

    public init(
        backgroundColorProvider: @escaping @Sendable () -> Color = { .black },
        cardColorProvider: @escaping @Sendable () -> Color = { .gray },
        secondaryColorProvider: @escaping @Sendable () -> Color = { .gray },
        tertiaryColorProvider: @escaping @Sendable () -> Color = { .gray },
        groupedBackgroundProvider: @escaping @Sendable () -> Color = { .gray },
        groupedSecondaryBackgroundProvider: @escaping @Sendable () -> Color = { .gray },
        groupedTertiaryBackgroundProvider: @escaping @Sendable () -> Color = { .gray },
        navigationBarHiddenApplier: @escaping @Sendable (AnyView) -> AnyView = { view in view },
        darkNavigationBarApplier: @escaping @Sendable (AnyView) -> AnyView = { view in view },
        sheetApplier: @escaping @Sendable (AnyView) -> AnyView = { view in view }
    ) {
        self.backgroundColorProvider = backgroundColorProvider
        self.cardColorProvider = cardColorProvider
        self.secondaryColorProvider = secondaryColorProvider
        self.tertiaryColorProvider = tertiaryColorProvider
        self.groupedBackgroundProvider = groupedBackgroundProvider
        self.groupedSecondaryBackgroundProvider = groupedSecondaryBackgroundProvider
        self.groupedTertiaryBackgroundProvider = groupedTertiaryBackgroundProvider
        self.navigationBarHiddenApplier = navigationBarHiddenApplier
        self.darkNavigationBarApplier = darkNavigationBarApplier
        self.sheetApplier = sheetApplier
    }
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

private enum ThemeServiceKey {
    static let liveValue: ThemeServiceProtocol = ThemeServiceClient()
}

// MARK: - Environment Key

public extension EnvironmentValues {
    var themeService: ThemeServiceProtocol {
        get { self[ThemeServiceEnvironmentKey.self] }
        set { self[ThemeServiceEnvironmentKey.self] = newValue }
    }
}

public struct ThemeServiceEnvironmentKey: EnvironmentKey {
    public static let defaultValue: ThemeServiceProtocol = ThemeServiceKey.liveValue
}

#if os(macOS)
    import AppCore
    import SwiftUI

    public extension ThemeServiceClient {
        static let macOS: Self = {
            let service = MacOSThemeService()
            return Self(
                backgroundColorProvider: { service.backgroundColor() },
                cardColorProvider: { service.cardColor() },
                secondaryColorProvider: { service.secondaryColor() },
                tertiaryColorProvider: { service.tertiaryColor() },
                groupedBackgroundProvider: { service.groupedBackground() },
                groupedSecondaryBackgroundProvider: { service.groupedSecondaryBackground() },
                groupedTertiaryBackgroundProvider: { service.groupedTertiaryBackground() },
                navigationBarHiddenApplier: { view in service.applyNavigationBarHidden(to: view) },
                darkNavigationBarApplier: { view in service.applyDarkNavigationBar(to: view) },
                sheetApplier: { view in service.applySheet(to: view) }
            )
        }()
    }
#endif

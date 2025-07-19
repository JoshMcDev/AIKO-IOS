#if os(macOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension ThemeServiceClient {
    public static let macOS: Self = {
        let service = macOSThemeService()
        return Self(
            _backgroundColor: { service.backgroundColor() },
            _cardColor: { service.cardColor() },
            _secondaryColor: { service.secondaryColor() },
            _tertiaryColor: { service.tertiaryColor() },
            _groupedBackground: { service.groupedBackground() },
            _groupedSecondaryBackground: { service.groupedSecondaryBackground() },
            _groupedTertiaryBackground: { service.groupedTertiaryBackground() },
            _applyNavigationBarHidden: { view in service.applyNavigationBarHidden(to: view) },
            _applyDarkNavigationBar: { view in service.applyDarkNavigationBar(to: view) },
            _applySheet: { view in service.applySheet(to: view) }
        )
    }()
}
#endif
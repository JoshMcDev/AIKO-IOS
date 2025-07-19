#if os(iOS)
import SwiftUI
import UIKit
import AppCore

public final class iOSThemeService: ThemeServiceProtocol {
    public init() {}
    
    public func backgroundColor() -> Color {
        Color.black
    }
    
    public func cardColor() -> Color {
        Color(UIColor.systemGray6)
    }
    
    public func secondaryColor() -> Color {
        Color(UIColor.systemGray6)
    }
    
    public func tertiaryColor() -> Color {
        Color(UIColor.systemGray5)
    }
    
    public func groupedBackground() -> Color {
        Color(UIColor.systemGroupedBackground)
    }
    
    public func groupedSecondaryBackground() -> Color {
        Color(UIColor.secondarySystemGroupedBackground)
    }
    
    public func groupedTertiaryBackground() -> Color {
        Color(UIColor.tertiarySystemGroupedBackground)
    }
    
    public func applyNavigationBarHidden(to view: AnyView) -> AnyView {
        AnyView(view.navigationBarHidden(true))
    }
    
    public func applyDarkNavigationBar(to view: AnyView) -> AnyView {
        AnyView(
            view.onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .black
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
        )
    }
    
    public func applySheet(to view: AnyView) -> AnyView {
        if #available(iOS 16.4, *) {
            return AnyView(
                view
                    .preferredColorScheme(.dark)
                    .environment(\.colorScheme, .dark)
                    .presentationBackground(Color.black)
                    .modifier(DarkNavigationBarModifier())
            )
        } else {
            return AnyView(
                view
                    .preferredColorScheme(.dark)
                    .environment(\.colorScheme, .dark)
                    .modifier(DarkNavigationBarModifier())
            )
        }
    }
}

private struct DarkNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .black
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}
#endif
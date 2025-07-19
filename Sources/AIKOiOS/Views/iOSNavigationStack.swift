#if os(iOS)
import SwiftUI
import UIKit

/// iOS-specific navigation container that provides iPhone and iPad optimizations
public struct iOSNavigationStack<Content: View>: View {
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        NavigationStack {
            content()
        }
        .navigationViewStyle(.automatic)
        .modifier(iOSNavigationBarStyleModifier())
    }
}

/// iOS-specific navigation bar styling
public struct iOSNavigationBarStyleModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                configureNavigationBarAppearance()
            }
    }
    
    private func configureNavigationBarAppearance() {
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

/// iOS-specific tab view implementation
public struct iOSTabView<Content: View>: View {
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        TabView {
            content()
        }
        .modifier(iOSTabBarStyleModifier())
    }
}

/// iOS-specific tab bar styling
public struct iOSTabBarStyleModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                configureTabBarAppearance()
            }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
#endif
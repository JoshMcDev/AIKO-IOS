#if os(iOS)
    import SwiftUI
    import UIKit

    /// iOS-specific navigation container that provides iPhone and iPad optimizations
    public struct IOSNavigationStack<Content: View>: View {
        let content: () -> Content

        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            NavigationStack {
                content()
            }
            .navigationViewStyle(.automatic)
            .modifier(IOSNavigationBarStyleModifier())
        }
    }

    /// iOS-specific navigation bar styling
    public struct IOSNavigationBarStyleModifier: ViewModifier {
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
    public struct IOSTabView<Content: View>: View {
        let content: () -> Content

        public init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content
        }

        public var body: some View {
            TabView {
                content()
            }
            .modifier(IOSTabBarStyleModifier())
        }
    }

    /// iOS-specific tab bar styling
    public struct IOSTabBarStyleModifier: ViewModifier {
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

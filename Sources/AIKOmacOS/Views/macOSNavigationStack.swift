#if os(macOS)
import AppKit
import SwiftUI

/// macOS-specific navigation container that provides desktop optimizations
public struct MacOSNavigationStack<Content: View>: View {
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            content()
        }
        .navigationSplitViewStyle(.automatic)
        .modifier(MacOSWindowStyleModifier())
    }
}

/// macOS-specific window styling
public struct MacOSWindowStyleModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
                configureWindow()
            }
    }

    private func configureWindow() {
        // Configure main window appearance
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
        }
    }
}

/// macOS-specific sidebar navigation
public struct MacOSSidebarNavigation<SidebarContent: View, DetailContent: View>: View {
    let sidebarContent: () -> SidebarContent
    let detailContent: () -> DetailContent

    public init(
        @ViewBuilder sidebar: @escaping () -> SidebarContent,
        @ViewBuilder detail: @escaping () -> DetailContent
    ) {
        sidebarContent = sidebar
        detailContent = detail
    }

    public var body: some View {
        NavigationSplitView {
            sidebarContent()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            detailContent()
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// macOS-specific toolbar configuration
public struct MacOSToolbarModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .windowToolbar)
    }
}

/// macOS-specific window controls overlay
public struct MacOSWindowControlsOverlay: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(
                HStack {
                    // Traffic light controls area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 78, height: 28)
                    Spacer()
                }
                .allowsHitTesting(false),
                alignment: .topLeading
            )
    }
}
#endif

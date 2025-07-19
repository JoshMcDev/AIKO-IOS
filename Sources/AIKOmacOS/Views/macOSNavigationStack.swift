#if os(macOS)
import SwiftUI
import AppKit

/// macOS-specific navigation container that provides desktop optimizations
public struct macOSNavigationStack<Content: View>: View {
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        NavigationStack {
            content()
        }
        .navigationSplitViewStyle(.automatic)
        .modifier(macOSWindowStyleModifier())
    }
}

/// macOS-specific window styling
public struct macOSWindowStyleModifier: ViewModifier {
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
public struct macOSSidebarNavigation<SidebarContent: View, DetailContent: View>: View {
    let sidebarContent: () -> SidebarContent
    let detailContent: () -> DetailContent
    
    public init(
        @ViewBuilder sidebar: @escaping () -> SidebarContent,
        @ViewBuilder detail: @escaping () -> DetailContent
    ) {
        self.sidebarContent = sidebar
        self.detailContent = detail
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
public struct macOSToolbarModifier: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .windowToolbar)
    }
}

/// macOS-specific window controls overlay
public struct macOSWindowControlsOverlay: ViewModifier {
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
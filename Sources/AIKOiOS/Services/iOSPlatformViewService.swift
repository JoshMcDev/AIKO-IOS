#if os(iOS)
import SwiftUI
import AppCore

public final class iOSPlatformViewService: PlatformViewServiceProtocol {
    public init() {}
    
    public func createNavigationStack<Content: View>(@ViewBuilder content: @escaping () -> Content) -> AnyView {
        AnyView(
            iOSNavigationStack(content: content)
        )
    }
    
    public func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView {
        AnyView(
            iOSDocumentPickerView(onDocumentsPicked: onDocumentsPicked)
        )
    }
    
    public func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView {
        AnyView(
            iOSImagePickerView(onImagePicked: onImagePicked)
        )
    }
    
    public func createShareSheet(items: [Any]) -> AnyView {
        AnyView(
            iOSShareButton(items: items)
        )
    }
    
    public func createSidebarNavigation<SidebarContent: View, DetailContent: View>(
        @ViewBuilder sidebar: @escaping () -> SidebarContent,
        @ViewBuilder detail: @escaping () -> DetailContent
    ) -> AnyView {
        // iOS doesn't have true sidebar navigation, fall back to detail view
        AnyView(detail())
    }
    
    public func applyWindowStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .navigationViewStyle(.automatic)
                .modifier(iOSNavigationBarStyleModifier())
        )
    }
    
    public func applyToolbarStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .toolbar(.automatic, for: .navigationBar)
        )
    }
    
    public func createDropZone<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        onItemsDropped: @escaping ([Any]) -> Void
    ) -> AnyView {
        // iOS doesn't support drag and drop in the same way as macOS
        AnyView(content())
    }
}
#endif
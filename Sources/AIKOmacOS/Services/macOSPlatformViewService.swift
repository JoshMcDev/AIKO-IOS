#if os(macOS)
import SwiftUI
import AppCore

public final class macOSPlatformViewService: PlatformViewServiceProtocol {
    public init() {}
    
    public func createNavigationStack<Content: View>(@ViewBuilder content: @escaping () -> Content) -> AnyView {
        AnyView(
            macOSNavigationStack(content: content)
        )
    }
    
    public func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView {
        AnyView(
            macOSDocumentPickerView(onDocumentsPicked: onDocumentsPicked)
        )
    }
    
    public func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView {
        AnyView(
            macOSImagePickerView(onImagePicked: onImagePicked)
        )
    }
    
    public func createShareSheet(items: [Any]) -> AnyView {
        AnyView(
            macOSShareButton(items: items)
        )
    }
    
    public func createSidebarNavigation<SidebarContent: View, DetailContent: View>(
        @ViewBuilder sidebar: @escaping () -> SidebarContent,
        @ViewBuilder detail: @escaping () -> DetailContent
    ) -> AnyView {
        AnyView(
            macOSSidebarNavigation(sidebar: sidebar, detail: detail)
        )
    }
    
    public func applyWindowStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .modifier(macOSWindowStyleModifier())
                .modifier(macOSWindowControlsOverlay())
        )
    }
    
    public func applyToolbarStyle(to view: AnyView) -> AnyView {
        AnyView(
            view
                .modifier(macOSToolbarModifier())
        )
    }
    
    public func createDropZone<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        onItemsDropped: @escaping ([Any]) -> Void
    ) -> AnyView {
        AnyView(
            macOSDocumentDropZone(onDocumentsDropped: { documents in
                onItemsDropped(documents.map { $0 as Any })
            }) {
                content()
            }
        )
    }
}
#endif
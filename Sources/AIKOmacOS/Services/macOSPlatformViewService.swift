#if os(macOS)
    import AppCore
    import SwiftUI

    public final class MacOSPlatformViewService: @unchecked Sendable, PlatformViewServiceProtocol {
        public init() {}

        @MainActor
        public func createNavigationStack(@ViewBuilder content: @escaping () -> some View) -> AnyView {
            AnyView(
                MacOSNavigationStack(content: content)
            )
        }

        @MainActor
        public func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView {
            AnyView(
                MacOSDocumentPickerView(onDocumentsPicked: onDocumentsPicked)
            )
        }

        @MainActor
        public func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView {
            AnyView(
                MacOSImagePickerView(onImagePicked: onImagePicked)
            )
        }

        @MainActor
        public func createShareSheet(items: [Any]) -> AnyView {
            AnyView(
                MacOSShareButton(items: items)
            )
        }

        @MainActor
        public func createSidebarNavigation(
            @ViewBuilder sidebar: @escaping () -> some View,
            @ViewBuilder detail: @escaping () -> some View
        ) -> AnyView {
            AnyView(
                MacOSSidebarNavigation(sidebar: sidebar, detail: detail)
            )
        }

        @MainActor
        public func applyWindowStyle(to view: AnyView) -> AnyView {
            AnyView(
                view
                    .modifier(MacOSWindowStyleModifier())
                    .modifier(MacOSWindowControlsOverlay())
            )
        }

        @MainActor
        public func applyToolbarStyle(to view: AnyView) -> AnyView {
            AnyView(
                view
                    .modifier(MacOSToolbarModifier())
            )
        }

        @MainActor
        public func createDropZone(
            @ViewBuilder content: @escaping () -> some View,
            onItemsDropped: @escaping ([Any]) -> Void
        ) -> AnyView {
            AnyView(
                MacOSDocumentDropZone(onDocumentsDropped: { documents in
                    onItemsDropped(documents.map { $0 as Any })
                }) {
                    content()
                }
            )
        }
    }
#endif

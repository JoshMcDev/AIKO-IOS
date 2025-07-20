#if os(macOS)
    import AppCore
    import SwiftUI

    public final class macOSPlatformViewService: @unchecked Sendable, PlatformViewServiceProtocol {
        public init() {}

        @MainActor
        public func createNavigationStack(@ViewBuilder content: @escaping () -> some View) -> AnyView {
            AnyView(
                macOSNavigationStack(content: content)
            )
        }

        @MainActor
        public func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView {
            AnyView(
                macOSDocumentPickerView(onDocumentsPicked: onDocumentsPicked)
            )
        }

        @MainActor
        public func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView {
            AnyView(
                macOSImagePickerView(onImagePicked: onImagePicked)
            )
        }

        @MainActor
        public func createShareSheet(items: [Any]) -> AnyView {
            AnyView(
                macOSShareButton(items: items)
            )
        }

        @MainActor
        public func createSidebarNavigation(
            @ViewBuilder sidebar: @escaping () -> some View,
            @ViewBuilder detail: @escaping () -> some View
        ) -> AnyView {
            AnyView(
                macOSSidebarNavigation(sidebar: sidebar, detail: detail)
            )
        }

        @MainActor
        public func applyWindowStyle(to view: AnyView) -> AnyView {
            AnyView(
                view
                    .modifier(macOSWindowStyleModifier())
                    .modifier(macOSWindowControlsOverlay())
            )
        }

        @MainActor
        public func applyToolbarStyle(to view: AnyView) -> AnyView {
            AnyView(
                view
                    .modifier(macOSToolbarModifier())
            )
        }

        @MainActor
        public func createDropZone(
            @ViewBuilder content: @escaping () -> some View,
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

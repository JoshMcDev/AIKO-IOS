#if os(macOS)
import SwiftUI
import AppCore
import ComposableArchitecture

extension PlatformViewServiceClient {
    public static let macOS: Self = {
        let service = macOSPlatformViewService()
        return Self(
            _createNavigationStack: { content in service.createNavigationStack(content: content) },
            _createDocumentPicker: { callback in service.createDocumentPicker(onDocumentsPicked: callback) },
            _createImagePicker: { callback in service.createImagePicker(onImagePicked: callback) },
            _createShareSheet: { items in service.createShareSheet(items: items) },
            _createSidebarNavigation: { sidebar, detail in service.createSidebarNavigation(sidebar: sidebar, detail: detail) },
            _applyWindowStyle: { view in service.applyWindowStyle(to: view) },
            _applyToolbarStyle: { view in service.applyToolbarStyle(to: view) },
            _createDropZone: { content, callback in service.createDropZone(content: content, onItemsDropped: callback) }
        )
    }()
}
#endif
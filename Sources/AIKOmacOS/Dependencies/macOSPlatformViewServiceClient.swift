#if os(macOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    public extension PlatformViewServiceClient {
        static let macOS: Self = {
            let service = macOSPlatformViewService()
            return Self(
                _createNavigationStack: { @MainActor content in
                    return service.createNavigationStack(content: content)
                },
                _createDocumentPicker: { @MainActor callback in
                    return service.createDocumentPicker(onDocumentsPicked: callback)
                },
                _createImagePicker: { @MainActor callback in
                    return service.createImagePicker(onImagePicked: callback)
                },
                _createShareSheet: { @MainActor items in
                    return service.createShareSheet(items: items)
                },
                _createSidebarNavigation: { @MainActor sidebar, detail in
                    return service.createSidebarNavigation(sidebar: sidebar, detail: detail)
                },
                _applyWindowStyle: { @MainActor view in
                    return service.applyWindowStyle(to: view)
                },
                _applyToolbarStyle: { @MainActor view in
                    return service.applyToolbarStyle(to: view)
                },
                _createDropZone: { @MainActor content, callback in
                    return service.createDropZone(content: content, onItemsDropped: callback)
                }
            )
        }()
    }
#endif

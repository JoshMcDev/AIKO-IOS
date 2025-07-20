#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    public extension PlatformViewServiceClient {
        @MainActor
        static var iOS: Self {
            let service = iOSPlatformViewService()

            return Self(
                _createNavigationStack: { content in
                    service.createNavigationStack { content() }
                },
                _createDocumentPicker: { callback in
                    service.createDocumentPicker(onDocumentsPicked: callback)
                },
                _createImagePicker: { callback in
                    service.createImagePicker(onImagePicked: callback)
                },
                _createShareSheet: { items in
                    service.createShareSheet(items: items)
                },
                _createSidebarNavigation: { sidebar, detail in
                    service.createSidebarNavigation(sidebar: { sidebar() }, detail: { detail() })
                },
                _applyWindowStyle: { view in
                    service.applyWindowStyle(to: view)
                },
                _applyToolbarStyle: { view in
                    service.applyToolbarStyle(to: view)
                },
                _createDropZone: { content, callback in
                    service.createDropZone(content: { content() }, onItemsDropped: callback)
                }
            )
        }
    }

    public enum iOSPlatformViewServiceClient {
        @MainActor
        public static let live = PlatformViewServiceClient.iOS
    }
#endif

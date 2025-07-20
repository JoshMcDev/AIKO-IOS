import ComposableArchitecture
import SwiftUI

/// Platform-agnostic view service for creating platform-specific UI components
public protocol PlatformViewServiceProtocol: Sendable {
    /// Create a navigation container appropriate for the platform
    @MainActor
    func createNavigationStack(@ViewBuilder content: @escaping () -> some View) -> AnyView

    /// Create a document picker view for the platform
    @MainActor
    func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView

    /// Create an image picker/scanner view for the platform
    @MainActor
    func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView

    /// Create a share sheet view for the platform
    @MainActor
    func createShareSheet(items: [Any]) -> AnyView

    /// Create a sidebar navigation (for platforms that support it)
    @MainActor
    func createSidebarNavigation(
        @ViewBuilder sidebar: @escaping () -> some View,
        @ViewBuilder detail: @escaping () -> some View
    ) -> AnyView

    /// Apply platform-specific window styling
    @MainActor
    func applyWindowStyle(to view: AnyView) -> AnyView

    /// Apply platform-specific toolbar styling
    @MainActor
    func applyToolbarStyle(to view: AnyView) -> AnyView

    /// Create a drop zone for file/image dropping (desktop platforms)
    @MainActor
    func createDropZone(
        @ViewBuilder content: @escaping () -> some View,
        onItemsDropped: @escaping ([Any]) -> Void
    ) -> AnyView
}

@DependencyClient
public struct PlatformViewServiceClient: Sendable {
    public var _createNavigationStack: @MainActor (@escaping () -> AnyView) -> AnyView = { content in content() }
    public var _createDocumentPicker: @MainActor (@escaping ([(Data, String)]) -> Void) -> AnyView = { _ in AnyView(EmptyView()) }
    public var _createImagePicker: @MainActor (@escaping (Data) -> Void) -> AnyView = { _ in AnyView(EmptyView()) }
    public var _createShareSheet: @MainActor ([Any]) -> AnyView = { _ in AnyView(EmptyView()) }
    public var _createSidebarNavigation: @MainActor (@escaping () -> AnyView, @escaping () -> AnyView) -> AnyView = { _, detail in detail() }
    public var _applyWindowStyle: @MainActor (AnyView) -> AnyView = { view in view }
    public var _applyToolbarStyle: @MainActor (AnyView) -> AnyView = { view in view }
    public var _createDropZone: @MainActor (@escaping () -> AnyView, @escaping ([Any]) -> Void) -> AnyView = { content, _ in content() }
}

// Protocol conformance
extension PlatformViewServiceClient: PlatformViewServiceProtocol {
    @MainActor
    public func createNavigationStack(@ViewBuilder content: @escaping () -> some View) -> AnyView {
        _createNavigationStack { AnyView(content()) }
    }

    @MainActor
    public func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView {
        _createDocumentPicker(onDocumentsPicked)
    }

    @MainActor
    public func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView {
        _createImagePicker(onImagePicked)
    }

    @MainActor
    public func createShareSheet(items: [Any]) -> AnyView {
        _createShareSheet(items)
    }

    @MainActor
    public func createSidebarNavigation(
        @ViewBuilder sidebar: @escaping () -> some View,
        @ViewBuilder detail: @escaping () -> some View
    ) -> AnyView {
        _createSidebarNavigation({ AnyView(sidebar()) }, { AnyView(detail()) })
    }

    @MainActor
    public func applyWindowStyle(to view: AnyView) -> AnyView {
        _applyWindowStyle(view)
    }

    @MainActor
    public func applyToolbarStyle(to view: AnyView) -> AnyView {
        _applyToolbarStyle(view)
    }

    @MainActor
    public func createDropZone(
        @ViewBuilder content: @escaping () -> some View,
        onItemsDropped: @escaping ([Any]) -> Void
    ) -> AnyView {
        _createDropZone({ AnyView(content()) }, onItemsDropped)
    }
}

// MARK: - Dependency

private enum PlatformViewServiceKey: DependencyKey {
    static let liveValue: PlatformViewServiceProtocol = PlatformViewServiceClient()
}

public extension DependencyValues {
    var platformViewService: PlatformViewServiceProtocol {
        get { self[PlatformViewServiceKey.self] }
        set { self[PlatformViewServiceKey.self] = newValue }
    }
}

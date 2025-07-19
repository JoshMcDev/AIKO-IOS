import SwiftUI
import ComposableArchitecture

/// Platform-agnostic view service for creating platform-specific UI components
public protocol PlatformViewServiceProtocol {
    /// Create a navigation container appropriate for the platform
    func createNavigationStack<Content: View>(@ViewBuilder content: @escaping () -> Content) -> AnyView
    
    /// Create a document picker view for the platform
    func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView
    
    /// Create an image picker/scanner view for the platform
    func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView
    
    /// Create a share sheet view for the platform
    func createShareSheet(items: [Any]) -> AnyView
    
    /// Create a sidebar navigation (for platforms that support it)
    func createSidebarNavigation<SidebarContent: View, DetailContent: View>(
        @ViewBuilder sidebar: @escaping () -> SidebarContent,
        @ViewBuilder detail: @escaping () -> DetailContent
    ) -> AnyView
    
    /// Apply platform-specific window styling
    func applyWindowStyle(to view: AnyView) -> AnyView
    
    /// Apply platform-specific toolbar styling
    func applyToolbarStyle(to view: AnyView) -> AnyView
    
    /// Create a drop zone for file/image dropping (desktop platforms)
    func createDropZone<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        onItemsDropped: @escaping ([Any]) -> Void
    ) -> AnyView
}

@DependencyClient
public struct PlatformViewServiceClient {
    public var _createNavigationStack: @Sendable (@escaping () -> AnyView) -> AnyView = { content in content() }
    public var _createDocumentPicker: @Sendable (@escaping ([(Data, String)]) -> Void) -> AnyView = { _ in AnyView(EmptyView()) }
    public var _createImagePicker: @Sendable (@escaping (Data) -> Void) -> AnyView = { _ in AnyView(EmptyView()) }
    public var _createShareSheet: @Sendable ([Any]) -> AnyView = { _ in AnyView(EmptyView()) }
    public var _createSidebarNavigation: @Sendable (@escaping () -> AnyView, @escaping () -> AnyView) -> AnyView = { _, detail in detail() }
    public var _applyWindowStyle: @Sendable (AnyView) -> AnyView = { view in view }
    public var _applyToolbarStyle: @Sendable (AnyView) -> AnyView = { view in view }
    public var _createDropZone: @Sendable (@escaping () -> AnyView, @escaping ([Any]) -> Void) -> AnyView = { content, _ in content() }
}

// Protocol conformance
extension PlatformViewServiceClient: PlatformViewServiceProtocol {
    public func createNavigationStack<Content: View>(@ViewBuilder content: @escaping () -> Content) -> AnyView {
        self._createNavigationStack { AnyView(content()) }
    }
    
    public func createDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> AnyView {
        self._createDocumentPicker(onDocumentsPicked)
    }
    
    public func createImagePicker(onImagePicked: @escaping (Data) -> Void) -> AnyView {
        self._createImagePicker(onImagePicked)
    }
    
    public func createShareSheet(items: [Any]) -> AnyView {
        self._createShareSheet(items)
    }
    
    public func createSidebarNavigation<SidebarContent: View, DetailContent: View>(
        @ViewBuilder sidebar: @escaping () -> SidebarContent,
        @ViewBuilder detail: @escaping () -> DetailContent
    ) -> AnyView {
        self._createSidebarNavigation({ AnyView(sidebar()) }, { AnyView(detail()) })
    }
    
    public func applyWindowStyle(to view: AnyView) -> AnyView {
        self._applyWindowStyle(view)
    }
    
    public func applyToolbarStyle(to view: AnyView) -> AnyView {
        self._applyToolbarStyle(view)
    }
    
    public func createDropZone<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        onItemsDropped: @escaping ([Any]) -> Void
    ) -> AnyView {
        self._createDropZone({ AnyView(content()) }, onItemsDropped)
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
import ComposableArchitecture
import SwiftUI

/// Protocol defining the shared interface for AppView across platforms
/// Note: This protocol is for documentation purposes. The actual implementation
/// uses concrete types from the main AIKO module.
public protocol AppViewProtocol: View {
    associatedtype Feature: Reducer
    init(store: StoreOf<Feature>)
}

/// Protocol for platform-specific services that AppView requires
public protocol AppViewPlatformServices {
    associatedtype NavigationStack: View
    associatedtype DocumentPickerView: View
    associatedtype ImagePickerView: View
    associatedtype ShareView: View

    /// Create the navigation container appropriate for the platform
    func makeNavigationStack(@ViewBuilder content: @escaping () -> some View) -> NavigationStack

    /// Create a document picker view for the platform
    @MainActor func makeDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> DocumentPickerView

    /// Create an image picker/scanner view for the platform
    @MainActor func makeImagePicker(onImagePicked: @escaping (Data) -> Void) -> ImagePickerView

    /// Create a share sheet view for the platform
    func makeShareSheet(items: [Any]) -> ShareView?

    /// Load an image from data in a platform-appropriate way
    func loadImage(from data: Data) -> Image?

    /// Get the app icon image for the platform
    func getAppIcon() -> Image?
}

/// Protocol for menu view to abstract platform differences
public protocol MenuViewProtocol: View {
    associatedtype Feature: Reducer
    associatedtype MenuItem
    init(store: StoreOf<Feature>, isShowing: Binding<Bool>, selectedMenuItem: Binding<MenuItem?>)
}

/// Protocol for platform-specific image loading
public protocol PlatformImageLoader {
    func loadImage(named: String, in bundle: Bundle?) -> Image?
    func loadImage(from data: Data) -> Image?
    func loadImage(from url: URL) -> Image?
}

/// View modifier protocol for platform-specific styling
public protocol PlatformViewModifier: ViewModifier where Body: View {
    func body(content: Content) -> Body
}

/// Protocol for platform-specific sheet presentation
public protocol SheetPresentationModifier: ViewModifier {
    associatedtype StyledContent: View
    func applySheetStyle(to content: some View) -> StyledContent
}

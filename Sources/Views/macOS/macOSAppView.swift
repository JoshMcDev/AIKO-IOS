#if os(macOS)
import SwiftUI
import ComposableArchitecture
import AppCore
import AppKit

/// macOS-specific implementation of AppView
public struct macOSAppView: View {
    let store: StoreOf<AppFeature>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            SharedAppView(
                store: store,
                services: macOSAppViewServices()
            )
            .preferredColorScheme(.dark)
            .sheet(isPresented: .init(
                get: { viewStore.showingDocumentScanner },
                set: { viewStore.send(.showDocumentScanner($0)) }
            )) {
                Text("Document scanning is not available on macOS")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aikoSheet()
            }
        }
    }
}

/// macOS implementation of platform services
struct macOSAppViewServices: AppViewPlatformServices {
    typealias NavigationStack = AnyView
    typealias DocumentPickerView = macOSDocumentPicker
    typealias ImagePickerView = macOSImagePicker
    typealias ShareView = EmptyView
    
    func makeNavigationStack<Content: View>(@ViewBuilder content: @escaping () -> Content) -> AnyView {
        AnyView(SwiftUI.NavigationView {
            content()
        })
    }
    
    func makeDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> macOSDocumentPicker {
        macOSDocumentPicker(onDocumentsPicked: onDocumentsPicked)
    }
    
    func makeImagePicker(onImagePicked: @escaping (Data) -> Void) -> macOSImagePicker {
        macOSImagePicker(onImagePicked: onImagePicked)
    }
    
    func makeShareSheet(items: [Any]) -> EmptyView? {
        // macOS doesn't use share sheets in the same way as iOS
        // Would implement NSSharingServicePicker if needed
        return nil
    }
    
    func loadImage(from data: Data) -> Image? {
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        return nil
    }
    
    func getAppIcon() -> Image? {
        // Try multiple loading methods to ensure it works in previews
        
        // Method 1: Try loading from bundle with different approaches
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        
        // Method 2: Try named image loading
        if let nsImage = NSImage(named: "AppIcon") {
            return Image(nsImage: nsImage)
        }
        
        // Method 3: Try from module bundle (for SPM)
        if let bundleURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let data = try? Data(contentsOf: bundleURL),
           let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        
        return nil
    }
}

// MARK: - macOS-specific Image Loading

extension macOSAppViewServices: PlatformImageLoader {
    func loadImage(named name: String, in bundle: Bundle?) -> Image? {
        if let nsImage = NSImage(named: name) {
            return Image(nsImage: nsImage)
        }
        return nil
    }
    
    func loadImage(from url: URL) -> Image? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return loadImage(from: data)
    }
}

// MARK: - macOS Document Picker

struct macOSDocumentPicker: View {
    let onDocumentsPicked: ([(Data, String)]) -> Void
    
    var body: some View {
        Button("Select Documents") {
            selectDocuments()
        }
        .padding()
    }
    
    private func selectDocuments() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.allowedContentTypes = [
            .pdf,
            .plainText,
            .rtf,
            .data // For Word documents
        ]
        
        openPanel.begin { response in
            if response == .OK {
                var documents: [(Data, String)] = []
                
                for url in openPanel.urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let fileName = url.lastPathComponent
                        documents.append((data, fileName))
                    } catch {
                        print("Error reading document \(url.lastPathComponent): \(error)")
                    }
                }
                
                if !documents.isEmpty {
                    DispatchQueue.main.async {
                        onDocumentsPicked(documents)
                    }
                }
            }
        }
    }
}

// MARK: - macOS Image Picker

struct macOSImagePicker: View {
    let onImagePicked: (Data) -> Void
    
    var body: some View {
        Button("Select Image") {
            selectImage()
        }
        .padding()
    }
    
    private func selectImage() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [
            .image,
            .jpeg,
            .png,
            .tiff
        ]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        onImagePicked(data)
                    }
                } catch {
                    print("Error reading image: \(error)")
                }
            }
        }
    }
}
#endif

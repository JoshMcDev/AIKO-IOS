#if os(iOS)
import SwiftUI
import ComposableArchitecture
import AppCore
import UIKit
import UniformTypeIdentifiers
import VisionKit

/// iOS-specific implementation of AppView
public struct iOSAppView: View {
    let store: StoreOf<AppFeature>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            iOSNavigationStack {
                SharedAppView(
                    store: store,
                    services: iOSAppViewServices()
                )
            }
            .preferredColorScheme(.dark)
            .tint(.white)
            .sheet(isPresented: .init(
                get: { viewStore.showingDocumentScanner },
                set: { viewStore.send(.showDocumentScanner($0)) }
            )) {
                DocumentScannerView(
                    store: store.scope(
                        state: \.documentScanner,
                        action: \.documentScanner
                    )
                )
                .aikoSheet()
            }
            .sheet(isPresented: .init(
                get: { viewStore.showingShareSheet },
                set: { _ in viewStore.send(.dismissShareSheet) }
            )) {
                ShareSheetView(items: viewStore.shareItems)
            }
        }
    }
}

/// iOS-specific navigation stack that handles version differences
struct iOSNavigationStack<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content()
                    .navigationBarHidden(true)
            }
        } else {
            SwiftUI.NavigationView {
                content()
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

/// iOS implementation of platform services
struct iOSAppViewServices: AppViewPlatformServices {
    typealias NavigationStack = AnyView
    typealias DocumentPickerView = iOSDocumentPicker
    typealias ImagePickerView = iOSImagePicker
    typealias ShareView = ShareSheetView
    
    func makeNavigationStack<Content: View>(@ViewBuilder content: @escaping () -> Content) -> AnyView {
        AnyView(iOSNavigationStack(content: content))
    }
    
    func makeDocumentPicker(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) -> iOSDocumentPicker {
        iOSDocumentPicker(onDocumentsPicked: onDocumentsPicked)
    }
    
    func makeImagePicker(onImagePicked: @escaping (Data) -> Void) -> iOSImagePicker {
        iOSImagePicker(onImagePicked: onImagePicked)
    }
    
    func makeShareSheet(items: [Any]) -> ShareSheetView? {
        ShareSheetView(items: items)
    }
    
    func loadImage(from data: Data) -> Image? {
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    func getAppIcon() -> Image? {
        // Try multiple loading methods to ensure it works in previews
        
        // Method 1: Try loading from bundle with different approaches
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        
        // Method 2: Try named image loading
        if let uiImage = UIImage(named: "AppIcon", in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: uiImage)
        }
        
        // Method 3: Try without specifying bundle (for previews)
        if let uiImage = UIImage(named: "AppIcon") {
            return Image(uiImage: uiImage)
        }
        
        // Method 4: Try from module bundle (for SPM)
        if let bundleURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let data = try? Data(contentsOf: bundleURL),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        
        return nil
    }
}

// MARK: - iOS-specific Image Loading

extension iOSAppViewServices: PlatformImageLoader {
    func loadImage(named name: String, in bundle: Bundle?) -> Image? {
        if let uiImage = UIImage(named: name, in: bundle ?? Bundle.main, compatibleWith: nil) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    func loadImage(from url: URL) -> Image? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return loadImage(from: data)
    }
}

// MARK: - iOS Document Picker

struct iOSDocumentPicker: UIViewControllerRepresentable {
    let onDocumentsPicked: ([(Data, String)]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .pdf,
            .plainText,
            .rtf,
            UTType("com.microsoft.word.doc") ?? .data,
            UTType("org.openxmlformats.wordprocessingml.document") ?? .data,
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: iOSDocumentPicker
        
        init(_ parent: iOSDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var documents: [(Data, String)] = []
            
            for url in urls {
                do {
                    // Start accessing the security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        print("Failed to access security-scoped resource")
                        continue
                    }
                    
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    let data = try Data(contentsOf: url)
                    let fileName = url.lastPathComponent
                    documents.append((data, fileName))
                } catch {
                    print("Error reading document \(url.lastPathComponent): \(error)")
                }
            }
            
            if !documents.isEmpty {
                DispatchQueue.main.async {
                    self.parent.onDocumentsPicked(documents)
                }
            }
        }
    }
}

// MARK: - iOS Image Picker

struct iOSImagePicker: View {
    let onImagePicked: (Data) -> Void
    
    var body: some View {
        if #available(iOS 16.0, *) {
            iOSDocumentScanner { scannedDocuments in
                // Convert to single image data
                if let firstDocument = scannedDocuments.first {
                    onImagePicked(firstDocument.0)
                }
            }
        } else {
            // Fallback for older iOS versions - single image capture
            iOSCameraImagePicker { imageData in
                onImagePicked(imageData)
            }
        }
    }
}

// MARK: - iOS Document Scanner

@available(iOS 16.0, *)
struct iOSDocumentScanner: UIViewControllerRepresentable {
    let onDocumentsScanned: ([(Data, String)]) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_: VNDocumentCameraViewController, context _: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: iOSDocumentScanner
        
        init(_ parent: iOSDocumentScanner) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var documents: [(Data, String)] = []
            
            for pageIndex in 0 ..< scan.pageCount {
                let scannedImage = scan.imageOfPage(at: pageIndex)
                if let imageData = scannedImage.jpegData(compressionQuality: 0.8) {
                    let fileName = "Scanned_Document_\(pageIndex + 1).jpg"
                    documents.append((imageData, fileName))
                }
            }
            
            if !documents.isEmpty {
                DispatchQueue.main.async {
                    self.parent.onDocumentsScanned(documents)
                }
            }
            
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanning failed: \(error)")
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - iOS Camera Image Picker (Fallback)

struct iOSCameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_: UIImagePickerController, context _: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: iOSCameraImagePicker
        
        init(_ parent: iOSCameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                DispatchQueue.main.async {
                    self.parent.onImagePicked(imageData)
                }
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - iOS Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
#endif

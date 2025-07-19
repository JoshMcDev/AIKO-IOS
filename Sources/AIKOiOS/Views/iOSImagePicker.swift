#if os(iOS)
import SwiftUI
import UIKit
import VisionKit

/// iOS-specific image picker and document scanner
public struct iOSImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (Data) -> Void
    let onCancel: () -> Void
    
    public init(
        sourceType: UIImagePickerController.SourceType = .photoLibrary,
        onImagePicked: @escaping (Data) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
        self.onCancel = onCancel
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: iOSImagePicker
        
        init(_ parent: iOSImagePicker) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                parent.onImagePicked(imageData)
            }
            picker.dismiss(animated: true)
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
            picker.dismiss(animated: true)
        }
    }
}

/// iOS-specific document scanner using VisionKit
@available(iOS 13.0, *)
public struct iOSDocumentScanner: UIViewControllerRepresentable {
    let onDocumentScanned: (Data) -> Void
    let onCancel: () -> Void
    
    public init(
        onDocumentScanned: @escaping (Data) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.onDocumentScanned = onDocumentScanned
        self.onCancel = onCancel
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: iOSDocumentScanner
        
        init(_ parent: iOSDocumentScanner) {
            self.parent = parent
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Convert the first scanned page to data
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    parent.onDocumentScanned(imageData)
                }
            }
            controller.dismiss(animated: true)
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
            controller.dismiss(animated: true)
        }
        
        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel()
            controller.dismiss(animated: true)
        }
    }
}

/// iOS-specific picker view that combines photo library and document scanning
public struct iOSImagePickerView: View {
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    @State private var showingSourceSelector = false
    let onImagePicked: (Data) -> Void
    
    public init(onImagePicked: @escaping (Data) -> Void) {
        self.onImagePicked = onImagePicked
    }
    
    public var body: some View {
        Button("Import Image") {
            showingSourceSelector = true
        }
        .confirmationDialog("Select Image Source", isPresented: $showingSourceSelector) {
            Button("Photo Library") {
                showingImagePicker = true
            }
            
            if VNDocumentCameraViewController.isSupported {
                Button("Scan Document") {
                    showingDocumentScanner = true
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            iOSImagePicker(onImagePicked: onImagePicked) {
                showingImagePicker = false
            }
        }
        .sheet(isPresented: $showingDocumentScanner) {
            if #available(iOS 13.0, *) {
                iOSDocumentScanner(onDocumentScanned: onImagePicked) {
                    showingDocumentScanner = false
                }
            }
        }
    }
}
#endif
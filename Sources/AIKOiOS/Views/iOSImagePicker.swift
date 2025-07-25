#if os(iOS)
    import SwiftUI
    import UIKit

    /// iOS-specific image picker and document scanner
    public struct IOSImagePicker: UIViewControllerRepresentable {
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

        public func updateUIViewController(_: UIImagePickerController, context _: Context) {}

        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: IOSImagePicker

            init(_ parent: IOSImagePicker) {
                self.parent = parent
            }

            public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let image = info[.originalImage] as? UIImage,
                   let imageData = image.jpegData(compressionQuality: 0.8)
                {
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

    /// iOS-specific document scanner using VisionKitAdapter
    @available(iOS 13.0, *)
    public struct IOSDocumentScanner: UIViewControllerRepresentable {
        let onDocumentScanned: (Data) -> Void
        let onCancel: () -> Void

        public init(
            onDocumentScanned: @escaping (Data) -> Void,
            onCancel: @escaping () -> Void = {}
        ) {
            self.onDocumentScanned = onDocumentScanned
            self.onCancel = onCancel
        }

        public func makeUIViewController(context _: Context) -> UIViewController {
            let adapter = VisionKitAdapter()

            // Set up the completion handler
            adapter.uiManager.setCompletion { (result: VisionKitAdapter.ScanResult) in
                switch result {
                case let .success(document):
                    // Convert the first scanned page to data for backward compatibility
                    if let firstPage = document.pages.first {
                        onDocumentScanned(firstPage.imageData)
                    }
                case .cancelled, .failed:
                    onCancel()
                }
            }

            // Create and return the document camera view controller directly
            return adapter.createDocumentCameraViewController()
        }

        public func updateUIViewController(_: UIViewController, context _: Context) {}

        public func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        public class Coordinator: NSObject {
            // Minimal coordinator for compatibility
        }
    }

    /// iOS-specific picker view that combines photo library and document scanning
    public struct IOSImagePickerView: View {
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

                if VisionKitAdapter.isScanningAvailable {
                    Button("Scan Document") {
                        showingDocumentScanner = true
                    }
                }

                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                IOSImagePicker(onImagePicked: onImagePicked) {
                    showingImagePicker = false
                }
            }
            .sheet(isPresented: $showingDocumentScanner) {
                if #available(iOS 13.0, *) {
                    IOSDocumentScanner(onDocumentScanned: onImagePicked) {
                        showingDocumentScanner = false
                    }
                }
            }
        }
    }
#endif

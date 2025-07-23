#if os(macOS)
    import AppKit
    import SwiftUI
    import UniformTypeIdentifiers

    /// macOS-specific image picker implementation
    public struct MacOSImagePicker: NSViewControllerRepresentable {
        let onImagePicked: (Data) -> Void
        let onCancel: () -> Void

        public init(
            onImagePicked: @escaping (Data) -> Void,
            onCancel: @escaping () -> Void = {}
        ) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        public func makeNSViewController(context _: Context) -> ImagePickerViewController {
            let viewController = ImagePickerViewController()
            viewController.onImagePicked = onImagePicked
            viewController.onCancel = onCancel
            return viewController
        }

        public func updateNSViewController(_: ImagePickerViewController, context _: Context) {}
    }

    /// macOS image picker view controller
    public class ImagePickerViewController: NSViewController {
        var onImagePicked: (Data) -> Void = { _ in }
        var onCancel: () -> Void = {}

        override public func loadView() {
            view = NSView()
        }

        override public func viewDidAppear() {
            super.viewDidAppear()
            presentImagePicker()
        }

        private func presentImagePicker() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.image, .jpeg, .png, .tiff, .gif, .bmp]

            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        let data = try Data(contentsOf: url)
                        DispatchQueue.main.async {
                            self.onImagePicked(data)
                        }
                    } catch {
                        print("Error reading image: \(error)")
                        DispatchQueue.main.async {
                            self.onCancel()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.onCancel()
                    }
                }
            }
        }
    }

    /// macOS-specific image capture using connected camera
    public struct MacOSImageCapture: NSViewControllerRepresentable {
        let onImageCaptured: (Data) -> Void
        let onCancel: () -> Void

        public init(
            onImageCaptured: @escaping (Data) -> Void,
            onCancel: @escaping () -> Void = {}
        ) {
            self.onImageCaptured = onImageCaptured
            self.onCancel = onCancel
        }

        public func makeNSViewController(context _: Context) -> ImageCaptureViewController {
            let viewController = ImageCaptureViewController()
            viewController.onImageCaptured = onImageCaptured
            viewController.onCancel = onCancel
            return viewController
        }

        public func updateNSViewController(_: ImageCaptureViewController, context _: Context) {}
    }

    /// macOS image capture view controller
    public class ImageCaptureViewController: NSViewController {
        var onImageCaptured: (Data) -> Void = { _ in }
        var onCancel: () -> Void = {}

        override public func loadView() {
            view = NSView()
        }

        override public func viewDidAppear() {
            super.viewDidAppear()
            // For now, fall back to image picker since camera capture requires more complex setup
            presentImagePicker()
        }

        private func presentImagePicker() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.image]
            panel.message = "Select an image to import"

            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        let data = try Data(contentsOf: url)
                        DispatchQueue.main.async {
                            self.onImageCaptured(data)
                        }
                    } catch {
                        print("Error reading image: \(error)")
                        DispatchQueue.main.async {
                            self.onCancel()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.onCancel()
                    }
                }
            }
        }
    }

    /// macOS-specific picker view for images
    public struct macOSImagePickerView: View {
        @State private var showingImagePicker = false
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
                Button("Choose from Files") {
                    showingImagePicker = true
                }

                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                macOSImagePicker(onImagePicked: onImagePicked) {
                    showingImagePicker = false
                }
                .frame(width: 600, height: 400)
            }
        }
    }

    /// macOS-specific drag and drop image receiver
    public struct macOSImageDropZone<Content: View>: View {
        let content: () -> Content
        let onImageDropped: (Data) -> Void
        @State private var isTargeted = false

        public init(
            onImageDropped: @escaping (Data) -> Void,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.onImageDropped = onImageDropped
            self.content = content
        }

        public var body: some View {
            content()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isTargeted ? Color.blue : Color.clear,
                            style: StrokeStyle(lineWidth: 2, dash: [5])
                        )
                )
                .onDrop(of: [.image], isTargeted: $isTargeted) { providers in
                    handleImageDrop(providers: providers)
                }
        }

        private func handleImageDrop(providers: [NSItemProvider]) -> Bool {
            guard let provider = providers.first else { return false }

            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                if let data {
                    DispatchQueue.main.async {
                        onImageDropped(data)
                    }
                }
            }

            return true
        }
    }
#endif

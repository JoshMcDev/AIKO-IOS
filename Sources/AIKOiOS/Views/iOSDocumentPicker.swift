#if os(iOS)
    import SwiftUI
    import UIKit
    import UniformTypeIdentifiers

    /// iOS-specific document picker implementation
    public struct IOSDocumentPicker: UIViewControllerRepresentable {
        let allowedContentTypes: [UTType]
        let allowsMultipleSelection: Bool
        let onDocumentsPicked: ([(Data, String)]) -> Void
        let onCancel: () -> Void

        public init(
            allowedContentTypes: [UTType] = [.pdf, .plainText, .rtf, .data],
            allowsMultipleSelection: Bool = true,
            onDocumentsPicked: @escaping ([(Data, String)]) -> Void,
            onCancel: @escaping () -> Void = {}
        ) {
            self.allowedContentTypes = allowedContentTypes
            self.allowsMultipleSelection = allowsMultipleSelection
            self.onDocumentsPicked = onDocumentsPicked
            self.onCancel = onCancel
        }

        public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
            picker.allowsMultipleSelection = allowsMultipleSelection
            picker.delegate = context.coordinator
            return picker
        }

        public func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}

        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        public class Coordinator: NSObject, UIDocumentPickerDelegate {
            let parent: IOSDocumentPicker

            init(_ parent: IOSDocumentPicker) {
                self.parent = parent
            }

            public func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                var documents: [(Data, String)] = []

                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }

                    do {
                        let data = try Data(contentsOf: url)
                        let filename = url.lastPathComponent
                        documents.append((data, filename))
                    } catch {
                        print("Error reading document: \(error)")
                    }
                }

                parent.onDocumentsPicked(documents)
            }

            public func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
                parent.onCancel()
            }
        }
    }

    /// iOS-specific wrapper for document picker integration
    public struct IOSDocumentPickerView: View {
        @State private var showingPicker = false
        let onDocumentsPicked: ([(Data, String)]) -> Void

        public init(onDocumentsPicked: @escaping ([(Data, String)]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }

        public var body: some View {
            Button("Import Documents") {
                showingPicker = true
            }
            .sheet(isPresented: $showingPicker) {
                IOSDocumentPicker(onDocumentsPicked: onDocumentsPicked) {
                    showingPicker = false
                }
            }
        }
    }
#endif

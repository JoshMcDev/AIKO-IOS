#if os(macOS)
import AppKit
import os.lock
import SwiftUI
import UniformTypeIdentifiers

/// macOS-specific document picker implementation
public struct MacOSDocumentPicker: NSViewControllerRepresentable {
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

    public func makeNSViewController(context _: Context) -> DocumentPickerViewController {
        let viewController = DocumentPickerViewController()
        viewController.allowedContentTypes = allowedContentTypes
        viewController.allowsMultipleSelection = allowsMultipleSelection
        viewController.onDocumentsPicked = onDocumentsPicked
        viewController.onCancel = onCancel
        return viewController
    }

    public func updateNSViewController(_: DocumentPickerViewController, context _: Context) {}
}

/// macOS document picker view controller
public class DocumentPickerViewController: NSViewController {
    var allowedContentTypes: [UTType] = []
    var allowsMultipleSelection: Bool = true
    var onDocumentsPicked: ([(Data, String)]) -> Void = { _ in }
    var onCancel: () -> Void = {}

    override public func loadView() {
        view = NSView()
    }

    override public func viewDidAppear() {
        super.viewDidAppear()
        presentDocumentPicker()
    }

    private func presentDocumentPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        // Convert UTTypes to allowed file types
        panel.allowedContentTypes = allowedContentTypes

        panel.begin { response in
            if response == .OK {
                var documents: [(Data, String)] = []

                for url in panel.urls {
                    do {
                        let data = try Data(contentsOf: url)
                        let filename = url.lastPathComponent
                        documents.append((data, filename))
                    } catch {
                        print("Error reading document: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    self.onDocumentsPicked(documents)
                }
            } else {
                DispatchQueue.main.async {
                    self.onCancel()
                }
            }
        }
    }
}

/// macOS-specific wrapper for document picker integration
public struct MacOSDocumentPickerView: View {
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
            MacOSDocumentPicker(onDocumentsPicked: onDocumentsPicked) {
                showingPicker = false
            }
            .frame(width: 600, height: 400)
        }
    }
}

/// macOS-specific drag and drop document receiver
public struct MacOSDocumentDropZone<Content: View>: View {
    let content: () -> Content
    let onDocumentsDropped: ([(Data, String)]) -> Void
    @State private var isTargeted = false

    public init(
        onDocumentsDropped: @escaping ([(Data, String)]) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onDocumentsDropped = onDocumentsDropped
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
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let documents = OSAllocatedUnfairLock(initialState: [(Data, String)]())
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                defer { group.leave() }

                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    do {
                        let fileData = try Data(contentsOf: url)
                        let filename = url.lastPathComponent
                        documents.withLock { $0.append((fileData, filename)) }
                    } catch {
                        print("Error reading dropped file: \(error)")
                    }
                }
            }
        }

        group.notify(queue: .main) {
            let finalDocuments = documents.withLock { $0 }
            if !finalDocuments.isEmpty {
                onDocumentsDropped(finalDocuments)
            }
        }

        return true
    }
}
#endif

#if os(macOS)
import AppCore
import AppKit
import Foundation
import SwiftUI

/// macOS implementation of ShareServiceProtocol
public final class MacOSShareService: @unchecked Sendable, ShareServiceProtocol {
    public init() {}

    @MainActor
    public func share(items: ShareableItems) async -> Bool {
        guard let window = NSApplication.shared.keyWindow else {
            return false
        }

        return await withCheckedContinuation { continuation in
            let picker = NSSharingServicePicker(items: items.items)

            // Configure delegate to track completion
            let delegate = SharingDelegate { success in
                continuation.resume(returning: success)
            }
            picker.delegate = delegate

            // Keep delegate alive during presentation
            objc_setAssociatedObject(picker, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // Show picker relative to window content
            if let contentView = window.contentView {
                let rect = CGRect(x: contentView.bounds.midX - 1, y: contentView.bounds.midY - 1, width: 2, height: 2)
                picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
            } else {
                continuation.resume(returning: false)
            }
        }
    }

    public func createShareableFile(from text: String, fileName: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

// Helper delegate for sharing service picker
private class SharingDelegate: NSObject, NSSharingServicePickerDelegate {
    let completion: (@Sendable (Bool) -> Void)?

    init(completion: (@Sendable (Bool) -> Void)?) {
        self.completion = completion
    }

    func sharingServicePicker(_: NSSharingServicePicker, didChoose service: NSSharingService?) {
        completion?(service != nil)
    }
}

/// SwiftUI View for share dialog on macOS
public struct ShareDialog: View {
    let items: [Any]
    @Binding var isPresented: Bool
    let onShare: (Bool) -> Void

    public init(items: [Any], isPresented: Binding<Bool>, onShare: @escaping (Bool) -> Void = { _ in }) {
        self.items = items
        _isPresented = isPresented
        self.onShare = onShare
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Share Report")
                .font(.headline)

            if let text = items.first as? String {
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxHeight: 300)
            }

            HStack {
                Button("Save to File") {
                    if let text = items.first as? String {
                        saveToFile(text: text)
                    }
                }

                Button("Copy to Clipboard") {
                    if let text = items.first as? String {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        onShare(true)
                        isPresented = false
                    }
                }

                Spacer()

                Button("Close") {
                    onShare(false)
                    isPresented = false
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 500, height: 400)
    }

    private func saveToFile(text: String) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "SAM_Report_\(Date().formatted(.dateTime.year().month().day())).txt"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                onShare(true)
                isPresented = false
            } catch {
                print("Error saving file: \(error)")
                onShare(false)
            }
        }
    }
}#endif

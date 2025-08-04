#if os(macOS)
import AppKit
import SwiftUI

/// macOS-specific sharing implementation using NSSharingService
public struct MacOSShareSheet: NSViewControllerRepresentable {
    let items: [Any]
    let onComplete: (Bool) -> Void

    public init(
        items: [Any],
        onComplete: @escaping (Bool) -> Void = { _ in }
    ) {
        self.items = items
        self.onComplete = onComplete
    }

    public func makeNSViewController(context _: Context) -> ShareViewController {
        let viewController = ShareViewController()
        viewController.items = items
        viewController.onComplete = onComplete
        return viewController
    }

    public func updateNSViewController(_: ShareViewController, context _: Context) {}
}

/// macOS share view controller
public class ShareViewController: NSViewController {
    var items: [Any] = []
    var onComplete: (Bool) -> Void = { _ in }

    override public func loadView() {
        view = NSView()
    }

    override public func viewDidAppear() {
        super.viewDidAppear()
        presentSharingMenu()
    }

    private func presentSharingMenu() {
        let picker = NSSharingServicePicker(items: items)

        // Show picker at center of view
        let rect = NSRect(
            x: view.bounds.midX - 50,
            y: view.bounds.midY - 25,
            width: 100,
            height: 50
        )

        picker.show(relativeTo: rect, of: view, preferredEdge: .minY)

        // For now, assume sharing completed successfully
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onComplete(true)
        }
    }
}

/// macOS-specific share button that uses NSSharingServicePicker
public struct MacOSShareButton: View {
    let items: [Any]
    let title: String
    @State private var showingSharePicker = false

    public init(items: [Any], title: String = "Share") {
        self.items = items
        self.title = title
    }

    public var body: some View {
        Button(title) {
            presentNativeSharingPicker()
        }
    }

    private func presentNativeSharingPicker() {
        guard !items.isEmpty else { return }

        let picker = NSSharingServicePicker(items: items)

        // Get the current window and present the picker
        if let window = NSApplication.shared.keyWindow,
           let contentView = window.contentView {
            let rect = NSRect(x: contentView.bounds.midX - 50, y: contentView.bounds.midY, width: 100, height: 50)
            picker.show(relativeTo: rect, of: contentView, preferredEdge: .minY)
        }
    }
}

/// macOS-specific share view with custom services
public struct MacOSShareView: View {
    let items: [Any]
    let subject: String?
    let message: String?
    @Binding var isPresented: Bool

    public init(
        items: [Any],
        subject: String? = nil,
        message: String? = nil,
        isPresented: Binding<Bool>
    ) {
        self.items = items
        self.subject = subject
        self.message = message
        _isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Share")
                .font(.headline)
                .padding(.top)

            // Available sharing services
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ShareServiceButton(
                    title: "Mail",
                    icon: "envelope",
                    action: { shareViaEmail() }
                )

                ShareServiceButton(
                    title: "Messages",
                    icon: "message",
                    action: { shareViaMessages() }
                )

                ShareServiceButton(
                    title: "Copy",
                    icon: "doc.on.clipboard",
                    action: { copyToPasteboard() }
                )

                ShareServiceButton(
                    title: "Save",
                    icon: "square.and.arrow.down",
                    action: { saveToFile() }
                )
            }
            .padding()

            Button("Cancel") {
                isPresented = false
            }
            .padding(.bottom)
        }
        .frame(width: 300, height: 200)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func shareViaEmail() {
        if let emailService = NSSharingService(named: .composeEmail) {
            emailService.perform(withItems: preparedItems)
        }
        isPresented = false
    }

    private func shareViaMessages() {
        if let messageService = NSSharingService(named: .composeMessage) {
            messageService.perform(withItems: preparedItems)
        }
        isPresented = false
    }

    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let textItem = preparedItems.first(where: { $0 is String }) as? String {
            pasteboard.setString(textItem, forType: .string)
        }

        isPresented = false
    }

    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = subject ?? "Shared Content"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let textItem = preparedItems.first(where: { $0 is String }) as? String {
                    try? textItem.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }

        isPresented = false
    }

    private var preparedItems: [Any] {
        var shareItems: [Any] = items

        if let message {
            shareItems.insert(message, at: 0)
        }

        return shareItems
    }
}

/// Individual share service button for macOS
private struct ShareServiceButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(width: 60, height: 60)
            .background(Color(NSColor.controlColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
#endif

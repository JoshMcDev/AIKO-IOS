#if os(iOS)
import AppCore
import Foundation
import SwiftUI
import UIKit

/// iOS implementation of ShareServiceProtocol
public final class IOSShareService: ShareServiceProtocol {
    public init() {}

    @MainActor
    public func share(items: ShareableItems) async -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController
        else {
            return false
        }

        return await withCheckedContinuation { continuation in
            let activityViewController = UIActivityViewController(
                activityItems: items.items,
                applicationActivities: nil
            )

            // Force dark mode
            activityViewController.overrideUserInterfaceStyle = .dark

            // Configure for iPad
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            activityViewController.completionWithItemsHandler = { _, completed, _, _ in
                continuation.resume(returning: completed)
            }

            rootViewController.present(activityViewController, animated: true)
        }
    }
}

/// SwiftUI View wrapper for share sheet
public struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Binding var isPresented: Bool
    var onCompletion: ((Bool) -> Void)?

    public init(items: [Any], isPresented: Binding<Bool>, onCompletion: ((Bool) -> Void)? = nil) {
        self.items = items
        _isPresented = isPresented
        self.onCompletion = onCompletion
    }

    public func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.overrideUserInterfaceStyle = .dark

        controller.completionWithItemsHandler = { _, completed, _, _ in
            isPresented = false
            onCompletion?(completed)
        }

        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context _: Context) {
        uiViewController.overrideUserInterfaceStyle = .dark
    }
}#endif

import Foundation
import SwiftUI
import UIKit
import AppCore

/// iOS implementation of ShareServiceProtocol
public final class iOSShareService: ShareServiceProtocol {
    public init() {}
    
    public func share(items: [Any], completion: ((Bool) -> Void)?) {
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                completion?(false)
                return
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: items,
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
                completion?(completed)
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
        self._isPresented = isPresented
        self.onCompletion = onCompletion
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.overrideUserInterfaceStyle = .dark
        
        controller.completionWithItemsHandler = { _, completed, _, _ in
            isPresented = false
            onCompletion?(completed)
        }
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        uiViewController.overrideUserInterfaceStyle = .dark
    }
}
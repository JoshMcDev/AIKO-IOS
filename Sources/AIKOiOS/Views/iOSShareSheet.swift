#if os(iOS)
    import SwiftUI
    import UIKit

    /// iOS-specific share sheet implementation
    public struct iOSShareSheet: UIViewControllerRepresentable {
        let items: [Any]
        let excludedActivityTypes: [UIActivity.ActivityType]?
        let onComplete: (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void

        public init(
            items: [Any],
            excludedActivityTypes: [UIActivity.ActivityType]? = nil,
            onComplete: @escaping (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void = { _, _, _, _ in }
        ) {
            self.items = items
            self.excludedActivityTypes = excludedActivityTypes
            self.onComplete = onComplete
        }

        public func makeUIViewController(context _: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
            controller.excludedActivityTypes = excludedActivityTypes
            controller.completionWithItemsHandler = onComplete

            // Configure for iPad
            if let popover = controller.popoverPresentationController {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first
                {
                    popover.sourceView = window.rootViewController?.view
                }
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            return controller
        }

        public func updateUIViewController(_: UIActivityViewController, context _: Context) {}
    }

    /// iOS-specific share button view
    public struct iOSShareButton: View {
        let items: [Any]
        let title: String
        @State private var showingShareSheet = false

        public init(items: [Any], title: String = "Share") {
            self.items = items
            self.title = title
        }

        public var body: some View {
            Button(title) {
                showingShareSheet = true
            }
            .sheet(isPresented: $showingShareSheet) {
                iOSShareSheet(items: items) { _, _, _, _ in
                    showingShareSheet = false
                }
            }
        }
    }

    /// iOS-specific share view with more customization options
    public struct iOSShareView: View {
        let items: [Any]
        let subject: String?
        let message: String?
        @State private var showingShareSheet = false
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
            EmptyView()
                .sheet(isPresented: $isPresented) {
                    iOSShareSheet(
                        items: preparedItems,
                        excludedActivityTypes: [
                            .addToReadingList,
                            .assignToContact,
                            .saveToCameraRoll,
                            .postToFlickr,
                            .postToVimeo,
                        ]
                    ) { _, _, _, _ in
                        isPresented = false
                    }
                }
        }

        private var preparedItems: [Any] {
            var shareItems: [Any] = items

            if let message {
                shareItems.insert(message, at: 0)
            }

            return shareItems
        }
    }

    /// iOS-specific activity item provider for custom sharing behavior
    public class iOSActivityItemProvider: UIActivityItemProvider, @unchecked Sendable {
        private let content: String
        private let filename: String?

        public init(content: String, filename: String? = nil) {
            self.content = content
            self.filename = filename
            super.init(placeholderItem: content)
        }

        public func item(forActivityType activityType: UIActivity.ActivityType?) -> Any? {
            // Return different content based on activity type
            switch activityType {
            case .mail:
                content
            case .message:
                content
            case .copyToPasteboard:
                content
            default:
                content
            }
        }

        override public func activityViewController(_: UIActivityViewController, subjectForActivityType _: UIActivity.ActivityType?) -> String {
            filename ?? "Shared Content"
        }
    }
#endif

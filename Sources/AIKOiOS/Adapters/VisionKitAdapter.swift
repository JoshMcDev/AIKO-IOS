#if os(iOS)
    import AppCore
    import Foundation
    import SwiftUI
    import UIKit
    import VisionKit

    /// Unified adapter for all VisionKit interactions in AIKO
    /// Consolidates scattered VisionKit usage into a single, testable interface
    /// Implements async/await patterns for modern concurrency with Swift 6 concurrency
    public final class VisionKitAdapter: DelegateServiceTemplate<VisionKitAdapter.ScanResult> {
        // MARK: - Types

        public enum ScanResult: Sendable {
            case success(ScannedDocument)
            case cancelled
            case failed(Error)
        }

        public struct ScanConfiguration {
            public let presentationMode: PresentationMode
            public let qualityMode: QualityMode

            public enum PresentationMode {
                case modal
                case sheet
            }

            public enum QualityMode {
                case fast
                case balanced
                case high
            }

            public init(
                presentationMode: PresentationMode = .modal,
                qualityMode: QualityMode = .balanced
            ) {
                self.presentationMode = presentationMode
                self.qualityMode = qualityMode
            }
        }

        // MARK: - Properties

        private let configuration: ScanConfiguration

        // MARK: - Initialization

        public init(configuration: ScanConfiguration = ScanConfiguration()) {
            self.configuration = configuration
            super.init()
        }

        // MARK: - Public Interface

        /// Checks if VisionKit document scanning is available on the current device
        public static var isScanningAvailable: Bool {
            VNDocumentCameraViewController.isSupported
        }

        /// Presents the document camera scanner with async/await pattern
        /// - Returns: ScannedDocument containing all scanned pages
        /// - Throws: DocumentScannerError if scanning fails or is not available
        public func presentDocumentScanner() async throws -> ScannedDocument {
            guard Self.isScanningAvailable else {
                throw DocumentScannerError.scanningNotAvailable
            }

            let startTime = Date()

            return try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    // Use template's completion handling
                    self.uiManager.setCompletion { (result: ScanResult) in
                        let processingTime = Date().timeIntervalSince(startTime)

                        switch result {
                        case let .success(document):
                            // Validate TDD requirement: scanner presentation <500ms
                            if processingTime > 0.5 {
                                print("⚠️ VisionKit scanner presentation took \(processingTime)s (exceeds 500ms target)")
                            }
                            continuation.resume(returning: document)
                        case .cancelled:
                            continuation.resume(throwing: DocumentScannerError.userCancelled)
                        case let .failed(error):
                            continuation.resume(throwing: error)
                        }
                    }

                    self.presentScannerViewController()
                }
            }
        }

        /// Creates a VNDocumentCameraViewController configured for the adapter
        /// - Returns: Configured scanner view controller
        public func createDocumentCameraViewController() -> VNDocumentCameraViewController {
            let scanner = VNDocumentCameraViewController()
            scanner.delegate = self
            return scanner
        }

        /// Creates a SwiftUI-compatible document camera view
        /// - Parameter completion: Callback with scan result
        /// - Returns: UIViewControllerRepresentable for SwiftUI integration
        public func createDocumentCameraView(
            completion: @escaping (ScanResult) -> Void
        ) -> DocumentCameraView {
            DocumentCameraView(adapter: self, completion: completion)
        }

        // MARK: - Private Methods

        @MainActor
        private func presentScannerViewController() {
            let scannerViewController = createDocumentCameraViewController()

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController
            else {
                handleDelegateResult(.failed(DocumentScannerError.scanningNotAvailable))
                return
            }

            uiManager.presentViewController(scannerViewController, from: rootViewController)
        }

        @MainActor
        private func convertScanToDocument(pageData: [(image: UIImage, index: Int)]) -> ScannedDocument {
            var pages: [ScannedPage] = []

            for (image, pageIndex) in pageData {

                // Use quality setting from configuration
                let compressionQuality: CGFloat = switch configuration.qualityMode {
                case .fast: 0.7
                case .balanced: 0.85
                case .high: 0.95
                }

                if let imageData = image.jpegData(compressionQuality: compressionQuality) {
                    let page = ScannedPage(
                        id: UUID(),
                        imageData: imageData,
                        pageNumber: pageIndex + 1
                    )
                    pages.append(page)
                }
            }

            return ScannedDocument(
                id: UUID(),
                pages: pages,
                scannedAt: Date()
            )
        }
    }

    // MARK: - VNDocumentCameraViewControllerDelegate

    extension VisionKitAdapter: VNDocumentCameraViewControllerDelegate {
        public nonisolated func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Extract scan data before entering MainActor context to avoid data race
            let pageCount = scan.pageCount
            let pageData: [(image: UIImage, index: Int)] = (0..<pageCount).map { index in
                (scan.imageOfPage(at: index), index)
            }
            
            Task { @MainActor in
                let document = self.convertScanToDocument(pageData: pageData)
                self.handleDelegateDismissal(controller, with: .success(document))
            }
        }

        public nonisolated func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            Task { @MainActor in
                self.handleDelegateDismissal(controller, with: .cancelled)
            }
        }

        public nonisolated func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            Task { @MainActor in
                self.handleDelegateDismissal(controller, with: .failed(error))
            }
        }
    }

    // MARK: - SwiftUI Integration

    /// SwiftUI-compatible document camera view that uses VisionKitAdapter
    public struct DocumentCameraView: UIViewControllerRepresentable {
        private let adapter: VisionKitAdapter
        private let completion: (VisionKitAdapter.ScanResult) -> Void

        init(
            adapter: VisionKitAdapter,
            completion: @escaping (VisionKitAdapter.ScanResult) -> Void
        ) {
            self.adapter = adapter
            self.completion = completion
        }

        public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
            let controller = adapter.createDocumentCameraViewController()

            // Update coordinator completion callback
            context.coordinator.completion = completion

            return controller
        }

        public func updateUIViewController(
            _: VNDocumentCameraViewController,
            context _: Context
        ) {
            // No updates needed
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(completion: completion)
        }

        public class Coordinator: NSObject {
            var completion: (VisionKitAdapter.ScanResult) -> Void

            init(completion: @escaping (VisionKitAdapter.ScanResult) -> Void) {
                self.completion = completion
            }
        }
    }

    // MARK: - Legacy Compatibility

    /// Legacy compatibility layer for existing code
    /// @deprecated Use VisionKitAdapter.presentDocumentScanner() instead
    @available(*, deprecated, message: "Use VisionKitAdapter.presentDocumentScanner() instead")
    public struct LegacyDocumentScanner {
        public static func scan() async throws -> ScannedDocument {
            let adapter = await VisionKitAdapter()
            return try await adapter.presentDocumentScanner()
        }
    }

#endif

import AppCore
import SwiftUI
import VisionKit

// DocumentScannerViewModelProtocol is now defined in AppCore/Protocols

/// SwiftUI view for document scanning using VisionKit
@MainActor
public struct DocumentScannerView<ViewModel: DocumentScannerViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel
    @Binding private var isPresented: Bool

    public init(
        viewModel: ViewModel,
        isPresented: Binding<Bool>
    ) {
        self.viewModel = viewModel
        _isPresented = isPresented
    }

    public var body: some View {
        NavigationView {
            VStack {
                if viewModel.scannedPages.isEmpty {
                    // Initial scanning state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("Ready to Scan")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Tap the button below to start scanning documents")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Start Scanning") {
                            Task {
                                let hasPermission = await viewModel.requestCameraPermissions()
                                if hasPermission {
                                    await viewModel.startScanning()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isScanning)
                    }
                    .padding()
                } else {
                    // Show scanned pages
                    VStack {
                        Text("Scanned Pages: \(viewModel.scannedPages.count)")
                            .font(.headline)
                            .padding()

                        Button("Add More Pages") {
                            Task {
                                await viewModel.startScanning()
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Save Document") {
                            Task {
                                // Export pages instead of saveDocument
                                do {
                                    _ = try await viewModel.exportPages()
                                    isPresented = false
                                } catch {
                                    // Handle error if needed
                                    print("Failed to export document: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }

                if viewModel.isScanning {
                    ProgressView("Scanning...")
                        .padding()
                }
            }
            .navigationTitle("Document Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: .constant(viewModel.isScanning)) {
            VisionKitBridge(viewModel: viewModel, isPresented: .constant(viewModel.isScanning))
        }
    }
}

// MARK: - VisionKit Bridge

/// UIViewControllerRepresentable bridge for VisionKit integration
public struct VisionKitBridge<ViewModel: DocumentScannerViewModelProtocol>: UIViewControllerRepresentable {
    @ObservedObject private var viewModel: ViewModel
    @Binding private var isPresented: Bool

    public init(
        viewModel: ViewModel,
        isPresented: Binding<Bool>
    ) {
        self.viewModel = viewModel
        _isPresented = isPresented
    }

    public func makeUIViewController(context _: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = makeCoordinator()
        return controller
    }

    public func updateUIViewController(
        _: VNDocumentCameraViewController,
        context _: Context
    ) {
        // No updates needed for this implementation
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel, isPresented: $isPresented)
    }

    @MainActor
    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let viewModel: ViewModel
        private let isPresented: Binding<Bool>

        init(viewModel: ViewModel, isPresented: Binding<Bool>) {
            self.viewModel = viewModel
            self.isPresented = isPresented
        }

        nonisolated public func documentCameraViewController(
            _: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Extract all data from scan before entering @MainActor context
            let pageCount = scan.pageCount
            var scannedPages: [ScannedPage] = []

            // Process all pages outside of @MainActor context
            for pageIndex in 0 ..< pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()

                let scannedPage = ScannedPage(
                    imageData: imageData,
                    pageNumber: pageIndex + 1,
                    processingState: .completed
                )

                scannedPages.append(scannedPage)
            }

            // Now send the extracted data to @MainActor
            Task { @MainActor in
                // Add all processed pages
                for scannedPage in scannedPages {
                    viewModel.addPage(scannedPage)
                }

                isPresented.wrappedValue = false
            }
        }

        nonisolated public func documentCameraViewControllerDidCancel(
            _: VNDocumentCameraViewController
        ) {
            Task { @MainActor in
                isPresented.wrappedValue = false
            }
        }

        nonisolated public func documentCameraViewController(
            _: VNDocumentCameraViewController,
            didFailWithError _: Error
        ) {
            Task { @MainActor in
                // Set error on viewModel if it has an error property
                // For minimal implementation, just dismiss
                isPresented.wrappedValue = false
            }
        }
    }
}

// MARK: - Supporting Types

public enum ScanQuality {
    case fast
    case balanced
    case high
}

public enum DocumentScannerError: LocalizedError {
    case scanningNotAvailable
    case userCancelled
    case invalidImageData
    case cameraPermissionDenied
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .scanningNotAvailable:
            return "Document scanning is not available on this device"
        case .userCancelled:
            return "Scanning was cancelled"
        case .invalidImageData:
            return "The image data is invalid or corrupted"
        case .cameraPermissionDenied:
            return "Camera access is required to scan documents"
        case let .unknownError(message):
            return message
        }
    }
}

public struct CameraPermissionError: Error {
    public let message: String

    public init(message: String = "Camera permission required") {
        self.message = message
    }
}

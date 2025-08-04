import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// Use existing DocumentScannerError from DocumentScannerClient
public extension DocumentScannerError {
    // Add necessary cases to match our test requirements
    static var cameraNotAvailable: DocumentScannerError {
        .scanningNotAvailable
    }

    static var scanningFailed: DocumentScannerError {
        .userCancelled
    }
}

@MainActor
public final class DocumentScannerViewModel: ObservableObject {
    @Published public private(set) var isScanning = false
    @Published public var error: DocumentScannerError?
    @Published public private(set) var pages: [ScannedPage] = []

    // Alias for compatibility with tests
    public var scannedPages: [ScannedPage] { pages }

    public init() {}

    public func addPage(_ page: ScannedPage) {
        pages.append(page)
        isScanning = false
    }

    public func startScanning() async {
        isScanning = true
        error = nil
    }

    public func startScanning() {
        isScanning = true
        error = nil
    }

    public func stopScanning() {
        isScanning = false
    }

    public func cancelScanning() {
        isScanning = false
    }

    public func retryScanning() {
        error = nil
        isScanning = false
    }

    public func clearSession() {
        pages.removeAll()
        isScanning = false
        error = nil
    }

    public func checkCameraPermissions() async -> Bool {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("checkCameraPermissions not implemented - RED phase")
    }

    public func requestCameraPermissions() async -> Bool {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("requestCameraPermissions not implemented - RED phase")
    }

    public func processPage(_ page: ScannedPage) async throws -> ScannedPage {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("processPage not implemented - RED phase")
    }

    public func enhanceAllPages() async {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("enhanceAllPages not implemented - RED phase")
    }

    public func exportPages() async throws -> Data {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("exportPages not implemented - RED phase")
    }

    public func saveDocument() async {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("saveDocument not implemented - RED phase")
    }

    public func reorderPages(from: IndexSet, to: Int) {
        // RED phase stub - will be implemented in GREEN phase
        fatalError("reorderPages not implemented - RED phase")
    }
}

public struct DocumentScannerView: View {
    @StateObject private var viewModel: DocumentScannerViewModel

    public init(viewModel: DocumentScannerViewModel = DocumentScannerViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack {
                // Initial State
                if !viewModel.isScanning && viewModel.pages.isEmpty {
                    initialStateView
                }

                // Scanning State
                if viewModel.isScanning {
                    scanningStateView
                }

                // Error State
                if let error = viewModel.error {
                    errorStateView(error)
                }

                // Success State
                if !viewModel.pages.isEmpty {
                    successStateView
                }
            }
            .animation(.default, value: viewModel.isScanning)
            .animation(.default, value: viewModel.error)
            .animation(.default, value: viewModel.pages)
            .dynamicTypeSize(.large)
            #if canImport(UIKit)
            .background(Color(uiColor: .systemBackground))
            #endif
        }
    }

    private var initialStateView: some View {
        VStack {
            Text("Ready to Scan")
                .font(.title)
            Button("Start Scanning") {
                viewModel.startScanning()
            }
            .accessibilityLabel("Start document scanning")
            .accessibilityHint("Activates the camera to scan documents")
        }
    }

    private var scanningStateView: some View {
        VStack {
            ProgressView()
            Text("Scanning...")
            Button("Cancel") {
                viewModel.cancelScanning()
            }
        }
    }

    private func errorStateView(_ error: DocumentScannerError) -> some View {
        VStack {
            switch error {
            case .scanningNotAvailable:
                Text("Camera not available")
            case .userCancelled:
                Text("Scanning failed")
            default:
                Text("Unknown error")
            }
            Button("Retry") {
                viewModel.retryScanning()
            }
        }
    }

    private var successStateView: some View {
        VStack {
            Text("\(viewModel.pages.count) page\(viewModel.pages.count > 1 ? "s" : "")")
            Text("Page 1 of \(viewModel.pages.count)")

            ForEach(viewModel.pages.indices, id: \.self) { _ in
                Image(systemName: "doc.text") // Placeholder for scanned page image
                    .resizable()
                    .scaledToFit()
            }

            HStack {
                Button("Previous") {} // Placeholder
                Button("Next") {} // Placeholder
            }

            Button("Add Page") {
                viewModel.startScanning()
            }

            Button("Save Document") {} // Placeholder
        }
    }
}

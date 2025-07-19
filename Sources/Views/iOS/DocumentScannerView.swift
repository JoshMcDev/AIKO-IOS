#if os(iOS)
import SwiftUI
import ComposableArchitecture
import AppCore
import UIKit
import VisionKit

/// iOS-specific implementation of Document Scanner View
public struct DocumentScannerView: View {
    let store: StoreOf<DocumentScannerFeature>
    @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }
    
    public var body: some View {
        SwiftUI.NavigationView {
            Group {
                if viewStore.hasScannedPages {
                    ScannedPagesListView(store: store)
                } else {
                    EmptyScannerView(store: store)
                }
            }
            .navigationTitle("Document Scanner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewStore.send(.dismissScanner)
                    }
                }
                
                if viewStore.hasScannedPages {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                viewStore.send(.scanButtonTapped)
                            } label: {
                                Label("Scan More Pages", systemImage: "doc.badge.plus")
                            }
                            
                            Button {
                                viewStore.send(.toggleSelectionMode)
                            } label: {
                                Label(
                                    viewStore.isInSelectionMode ? "Done" : "Select",
                                    systemImage: viewStore.isInSelectionMode ? "checkmark.circle" : "checkmark.circle"
                                )
                            }
                            
                            if viewStore.canSaveDocument {
                                Button {
                                    viewStore.send(.saveToDocumentPipeline)
                                } label: {
                                    Label("Save Document", systemImage: "square.and.arrow.down")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: .init(
                get: { viewStore.isScannerPresented },
                set: { viewStore.send(.setScannerPresented($0)) }
            )) {
                DocumentCameraView { result in
                    viewStore.send(.scannerDidFinish(result))
                }
                .ignoresSafeArea()
            }
            .alert(
                "Error",
                isPresented: .init(
                    get: { viewStore.showingError },
                    set: { _ in viewStore.send(.dismissError) }
                ),
                actions: {
                    Button("OK") {
                        viewStore.send(.dismissError)
                    }
                },
                message: {
                    if let error = viewStore.error {
                        Text(error)
                    }
                }
            )
        }
    }
}

// MARK: - Empty Scanner View

struct EmptyScannerView: View {
    let store: StoreOf<DocumentScannerFeature>
    @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>
    
    init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Documents Scanned")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the button below to start scanning documents")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                viewStore.send(.scanButtonTapped)
            }) {
                Label("Scan Document", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

// MARK: - Scanned Pages List View

struct ScannedPagesListView: View {
    let store: StoreOf<DocumentScannerFeature>
    @ObservedObject var viewStore: ViewStoreOf<DocumentScannerFeature>
    
    init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }
    
    var body: some View {
        List {
            // Document Info Section
            Section("Document Information") {
                TextField("Document Title", text: .init(
                    get: { viewStore.documentTitle },
                    set: { viewStore.send(.updateDocumentTitle($0)) }
                ))
                
                Picker("Document Type", selection: .init(
                    get: { viewStore.documentType },
                    set: { if let type = $0 { viewStore.send(.selectDocumentType(type)) } }
                )) {
                    Text("Select Type").tag(nil as DocumentType?)
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        Text(type.shortName).tag(type as DocumentType?)
                    }
                }
            }
            
            // Settings Section
            Section("Processing Options") {
                Toggle("Enhance Images", isOn: .init(
                    get: { viewStore.enableImageEnhancement },
                    set: { viewStore.send(.toggleImageEnhancement($0)) }
                ))
                
                Toggle("Extract Text (OCR)", isOn: .init(
                    get: { viewStore.enableOCR },
                    set: { viewStore.send(.toggleOCR($0)) }
                ))
                
                Picker("Scan Quality", selection: .init(
                    get: { viewStore.scanQuality },
                    set: { viewStore.send(.updateScanQuality($0)) }
                )) {
                    ForEach(DocumentScannerFeature.ScanQuality.allCases, id: \.self) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Scanned Pages Section
            Section(header: HStack {
                Text("Scanned Pages")
                Spacer()
                Text("\(viewStore.processedPagesCount) of \(viewStore.totalPagesCount) processed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }) {
                ForEach(viewStore.scannedPages) { page in
                    ScannedPageRow(
                        page: page,
                        isSelected: viewStore.selectedPages.contains(page.id),
                        isSelectionMode: viewStore.isInSelectionMode,
                        onTap: {
                            if viewStore.isInSelectionMode {
                                viewStore.send(.togglePageSelection(page.id))
                            }
                        },
                        onDelete: {
                            viewStore.send(.deletePage(page.id))
                        },
                        onRetry: {
                            viewStore.send(.retryPageProcessing(page.id))
                        }
                    )
                }
                .onMove { indices, newOffset in
                    viewStore.send(.reorderPages(indices, newOffset))
                }
                .onDelete { indices in
                    for index in indices {
                        if index >= 0 && index < viewStore.scannedPages.count {
                            let page = viewStore.scannedPages[index]
                            viewStore.send(.deletePage(page.id))
                        }
                    }
                }
            }
            
            // Actions Section
            if viewStore.hasScannedPages {
                Section {
                    if viewStore.isInSelectionMode {
                        HStack {
                            Button("Select All") {
                                viewStore.send(.selectAllPages)
                            }
                            
                            Spacer()
                            
                            Button("Delete Selected") {
                                viewStore.send(.deleteSelectedPages)
                            }
                            .foregroundColor(.red)
                            .disabled(viewStore.selectedPages.isEmpty)
                        }
                    }
                    
                    if viewStore.processedPagesCount < viewStore.totalPagesCount {
                        Button {
                            viewStore.send(.processAllPages)
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Process All Pages")
                            }
                        }
                        .disabled(viewStore.isProcessingAllPages)
                    }
                    
                    Button {
                        viewStore.send(.saveToDocumentPipeline)
                    } label: {
                        HStack {
                            Spacer()
                            if viewStore.isSavingToDocumentPipeline {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text("Save to Documents")
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.accentColor)
                    .disabled(!viewStore.canSaveDocument)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .environment(\.editMode, .constant(viewStore.isInSelectionMode ? .active : .inactive))
    }
}

// MARK: - Scanned Page Row

struct ScannedPageRow: View {
    let page: ScannedPage
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .onTapGesture {
                        onTap()
                    }
            }
            
            // Thumbnail
            let imageData = page.thumbnailData ?? page.imageData
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 60, height: 80)
                    .overlay(
                        Image(systemName: "doc")
                            .foregroundColor(.secondary)
                    )
            }
            
            // Page info
            VStack(alignment: .leading, spacing: 4) {
                Text("Page \(page.pageNumber)")
                    .font(.headline)
                
                if case .processing = page.processingState {
                    HStack(spacing: 4) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if case .failed(let error) = page.processingState {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                } else if page.ocrText != nil {
                    Text("Text extracted")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Actions
            if case .failed = page.processingState {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onTap()
            }
        }
    }
}

// MARK: - Document Camera View

struct DocumentCameraView: UIViewControllerRepresentable {
    let completion: (Result<ScannedDocument, Error>) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (Result<ScannedDocument, Error>) -> Void
        
        init(completion: @escaping (Result<ScannedDocument, Error>) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var pages: [ScannedPage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                guard let imageData = image.jpegData(compressionQuality: 0.9) else { continue }
                
                let page = ScannedPage(
                    imageData: imageData,
                    pageNumber: pageIndex + 1
                )
                pages.append(page)
            }
            
            let document = ScannedDocument(
                pages: pages,
                title: "Scanned Document",
                metadata: AppCore.DocumentMetadata(
                    source: AppCore.DocumentMetadata.DocumentSource.camera,
                    deviceInfo: UIDevice.current.model
                )
            )
            
            completion(.success(document))
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completion(.failure(DocumentScannerError.userCancelled))
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            completion(.failure(error))
        }
    }
}

#endif

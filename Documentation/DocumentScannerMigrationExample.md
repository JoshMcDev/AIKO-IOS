# DocumentScanner Migration Example
## Practical Implementation of Triple Architecture

This document demonstrates the step-by-step migration of the DocumentScanner feature from the current conditional-heavy implementation to the clean Triple Architecture.

---

## Step 1: Create AppCore Protocol

```swift
// Sources/AppCore/Dependencies/DocumentScannerClient.swift
import ComposableArchitecture
import Foundation

// MARK: - Platform-Agnostic Models

public struct ScannedDocument: Equatable, Sendable {
    public let id: UUID
    public let pages: [ScannedPage]
    public let title: String
    public let scannedAt: Date
    
    public init(
        id: UUID = UUID(),
        pages: [ScannedPage],
        title: String = "Untitled",
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.pages = pages
        self.title = title
        self.scannedAt = scannedAt
    }
}

public struct ScannedPage: Equatable, Sendable {
    public let id: UUID
    public let imageData: Data
    public let thumbnailData: Data?
    public let ocrText: String?
    public let pageNumber: Int
    
    public init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data? = nil,
        ocrText: String? = nil,
        pageNumber: Int
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.ocrText = ocrText
        self.pageNumber = pageNumber
    }
}

// MARK: - Client Protocol

@DependencyClient
public struct DocumentScannerClient: Sendable {
    public var scan: @Sendable () async throws -> ScannedDocument
    public var enhanceImage: @Sendable (Data) async throws -> Data
    public var performOCR: @Sendable (Data) async throws -> String
    public var generateThumbnail: @Sendable (Data) async throws -> Data
    public var saveToDocumentPipeline: @Sendable ([ScannedPage]) async throws -> Void
}

// MARK: - Dependency Registration

extension DocumentScannerClient: DependencyKey {
    public static var liveValue: Self = Self()  // Will be overridden by platform modules
}

extension DependencyValues {
    public var documentScanner: DocumentScannerClient {
        get { self[DocumentScannerClient.self] }
        set { self[DocumentScannerClient.self] = newValue }
    }
}
```

---

## Step 2: Migrate Feature to AppCore

```swift
// Sources/AppCore/Features/DocumentScannerFeature.swift
import ComposableArchitecture
import Foundation

@Reducer
public struct DocumentScannerFeature: Sendable {
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, Sendable {
        public var isScanning: Bool = false
        public var scannedDocument: ScannedDocument?
        public var selectedPages: Set<UUID> = []
        public var isProcessing: Bool = false
        public var isSaving: Bool = false
        public var error: String?
        
        // Document metadata
        public var documentTitle: String = ""
        public var documentType: DocumentType = .other
        
        // Processing options
        public var enableImageEnhancement: Bool = true
        public var enableOCR: Bool = true
        
        public init() {}
        
        // Computed properties
        public var hasScannedPages: Bool {
            scannedDocument != nil
        }
        
        public var canSave: Bool {
            hasScannedPages && !isProcessing && !isSaving
        }
    }
    
    // MARK: - Actions
    
    public enum Action: Equatable, Sendable {
        // Scanner actions
        case scanButtonTapped
        case scanResponse(Result<ScannedDocument, Error>)
        
        // Page management
        case selectPage(UUID)
        case deselectPage(UUID)
        case deleteSelectedPages
        
        // Processing
        case processPages
        case enhanceImage(UUID)
        case imageEnhanced(UUID, Result<Data, Error>)
        case performOCR(UUID)
        case ocrCompleted(UUID, Result<String, Error>)
        
        // Document management
        case updateTitle(String)
        case updateType(DocumentType)
        case saveDocument
        case documentSaved(Result<Void, Error>)
        
        // UI
        case dismissError
        case dismiss
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.documentScanner) var scanner
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid
    
    // MARK: - Reducer
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .scanButtonTapped:
                state.isScanning = true
                state.error = nil
                
                return .run { send in
                    await send(.scanResponse(
                        await Result { try await scanner.scan() }
                    ))
                }
                
            case let .scanResponse(.success(document)):
                state.isScanning = false
                state.scannedDocument = document
                state.documentTitle = document.title
                
                if state.enableImageEnhancement || state.enableOCR {
                    return .send(.processPages)
                }
                return .none
                
            case let .scanResponse(.failure(error)):
                state.isScanning = false
                state.error = error.localizedDescription
                return .none
                
            case .processPages:
                guard let document = state.scannedDocument else { return .none }
                state.isProcessing = true
                
                return .run { send in
                    for page in document.pages {
                        if self.enableImageEnhancement {
                            await send(.enhanceImage(page.id))
                        }
                        if self.enableOCR {
                            await send(.performOCR(page.id))
                        }
                    }
                }
                
            case let .enhanceImage(pageId):
                guard let page = state.scannedDocument?.pages.first(where: { $0.id == pageId }) else {
                    return .none
                }
                
                return .run { send in
                    await send(.imageEnhanced(
                        pageId,
                        await Result { try await scanner.enhanceImage(page.imageData) }
                    ))
                }
                
            case let .imageEnhanced(pageId, .success(enhancedData)):
                // Update page with enhanced image
                if let pageIndex = state.scannedDocument?.pages.firstIndex(where: { $0.id == pageId }) {
                    state.scannedDocument?.pages[pageIndex] = ScannedPage(
                        id: pageId,
                        imageData: enhancedData,
                        thumbnailData: state.scannedDocument?.pages[pageIndex].thumbnailData,
                        ocrText: state.scannedDocument?.pages[pageIndex].ocrText,
                        pageNumber: state.scannedDocument?.pages[pageIndex].pageNumber ?? 0
                    )
                }
                return .none
                
            case let .performOCR(pageId):
                guard let page = state.scannedDocument?.pages.first(where: { $0.id == pageId }) else {
                    return .none
                }
                
                return .run { send in
                    await send(.ocrCompleted(
                        pageId,
                        await Result { try await scanner.performOCR(page.imageData) }
                    ))
                }
                
            case let .ocrCompleted(pageId, .success(text)):
                // Update page with OCR text
                if let pageIndex = state.scannedDocument?.pages.firstIndex(where: { $0.id == pageId }) {
                    var page = state.scannedDocument!.pages[pageIndex]
                    page = ScannedPage(
                        id: page.id,
                        imageData: page.imageData,
                        thumbnailData: page.thumbnailData,
                        ocrText: text,
                        pageNumber: page.pageNumber
                    )
                    state.scannedDocument?.pages[pageIndex] = page
                }
                
                // Check if all processing is complete
                let allProcessed = state.scannedDocument?.pages.allSatisfy { page in
                    (!state.enableOCR || page.ocrText != nil)
                } ?? true
                
                if allProcessed {
                    state.isProcessing = false
                }
                
                return .none
                
            case .saveDocument:
                guard let pages = state.scannedDocument?.pages else { return .none }
                state.isSaving = true
                
                return .run { send in
                    await send(.documentSaved(
                        await Result { try await scanner.saveToDocumentPipeline(pages) }
                    ))
                }
                
            case .documentSaved(.success):
                state.isSaving = false
                return .run { _ in
                    await dismiss()
                }
                
            case let .documentSaved(.failure(error)):
                state.isSaving = false
                state.error = error.localizedDescription
                return .none
                
            case let .selectPage(pageId):
                state.selectedPages.insert(pageId)
                return .none
                
            case let .deselectPage(pageId):
                state.selectedPages.remove(pageId)
                return .none
                
            case .deleteSelectedPages:
                state.scannedDocument?.pages.removeAll { page in
                    state.selectedPages.contains(page.id)
                }
                state.selectedPages.removeAll()
                
                // Renumber pages
                if var document = state.scannedDocument {
                    document.pages = document.pages.enumerated().map { index, page in
                        ScannedPage(
                            id: page.id,
                            imageData: page.imageData,
                            thumbnailData: page.thumbnailData,
                            ocrText: page.ocrText,
                            pageNumber: index + 1
                        )
                    }
                    state.scannedDocument = document
                }
                
                return .none
                
            case let .updateTitle(title):
                state.documentTitle = title
                return .none
                
            case let .updateType(type):
                state.documentType = type
                return .none
                
            case .dismissError:
                state.error = nil
                return .none
                
            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
                
            default:
                return .none
            }
        }
    }
}

// MARK: - Supporting Types

public enum DocumentType: String, CaseIterable, Sendable {
    case contract = "Contract"
    case invoice = "Invoice"
    case receipt = "Receipt"
    case report = "Report"
    case form = "Form"
    case other = "Other"
}
```

---

## Step 3: iOS Implementation

```swift
// Sources/AIKOiOS/Dependencies/DocumentScannerClient+iOS.swift
import AppCore
import ComposableArchitecture
import VisionKit
import Vision
import UIKit

extension DocumentScannerClient {
    static let liveValue = Self(
        scan: {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    let scanner = DocumentScannerCoordinator { result in
                        continuation.resume(with: result)
                    }
                    scanner.present()
                }
            }
        },
        
        enhanceImage: { imageData in
            guard let uiImage = UIImage(data: imageData),
                  let ciImage = CIImage(image: uiImage) else {
                throw DocumentScannerError.invalidImageData
            }
            
            // Apply enhancement filters
            let enhancer = ImageEnhancer()
            let enhancedCIImage = try await enhancer.enhance(ciImage)
            
            // Convert back to Data
            let context = CIContext()
            guard let cgImage = context.createCGImage(enhancedCIImage, from: enhancedCIImage.extent),
                  let enhancedData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8) else {
                throw DocumentScannerError.enhancementFailed
            }
            
            return enhancedData
        },
        
        performOCR: { imageData in
            guard let uiImage = UIImage(data: imageData),
                  let cgImage = uiImage.cgImage else {
                throw DocumentScannerError.invalidImageData
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                    
                    continuation.resume(returning: text)
                }
                
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-US"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        },
        
        generateThumbnail: { imageData in
            guard let uiImage = UIImage(data: imageData) else {
                throw DocumentScannerError.invalidImageData
            }
            
            let thumbnailSize = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            
            let thumbnail = renderer.image { context in
                uiImage.draw(in: CGRect(origin: .zero, size: thumbnailSize))
            }
            
            guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
                throw DocumentScannerError.thumbnailGenerationFailed
            }
            
            return thumbnailData
        },
        
        saveToDocumentPipeline: { pages in
            // Integration with existing document pipeline
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let scannerFolder = documentsURL.appendingPathComponent("ScannedDocuments")
            
            try FileManager.default.createDirectory(at: scannerFolder, withIntermediateDirectories: true)
            
            for page in pages {
                let filename = "page_\(page.pageNumber).jpg"
                let fileURL = scannerFolder.appendingPathComponent(filename)
                try page.imageData.write(to: fileURL)
            }
        }
    )
}

// MARK: - Scanner Coordinator

@MainActor
private class DocumentScannerCoordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    let completion: (Result<ScannedDocument, Error>) -> Void
    var scannerViewController: VNDocumentCameraViewController?
    
    init(completion: @escaping (Result<ScannedDocument, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func present() {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure(DocumentScannerError.presentationFailed))
            return
        }
        
        self.scannerViewController = scanner
        rootViewController.present(scanner, animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var pages: [ScannedPage] = []
        
        for pageIndex in 0..<scan.pageCount {
            let scannedImage = scan.imageOfPage(at: pageIndex)
            guard let imageData = scannedImage.jpegData(compressionQuality: 0.8) else { continue }
            
            let page = ScannedPage(
                imageData: imageData,
                pageNumber: pageIndex + 1
            )
            pages.append(page)
        }
        
        let document = ScannedDocument(
            pages: pages,
            title: "Scanned Document"
        )
        
        controller.dismiss(animated: true) {
            self.completion(.success(document))
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            self.completion(.failure(DocumentScannerError.userCancelled))
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true) {
            self.completion(.failure(error))
        }
    }
}

// MARK: - Image Enhancer

private struct ImageEnhancer {
    func enhance(_ image: CIImage) async throws -> CIImage {
        var enhanced = image
        
        // Auto-adjust
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            filter.setValue(1.1, forKey: kCIInputContrastKey)
            filter.setValue(0.05, forKey: kCIInputBrightnessKey)
            enhanced = filter.outputImage ?? enhanced
        }
        
        // Sharpen
        if let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            filter.setValue(0.4, forKey: kCIInputSharpnessKey)
            enhanced = filter.outputImage ?? enhanced
        }
        
        return enhanced
    }
}

// MARK: - Errors

enum DocumentScannerError: LocalizedError {
    case invalidImageData
    case enhancementFailed
    case thumbnailGenerationFailed
    case presentationFailed
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .enhancementFailed:
            return "Failed to enhance image"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .presentationFailed:
            return "Failed to present scanner"
        case .userCancelled:
            return "Scanning cancelled"
        }
    }
}
```

---

## Step 4: macOS Implementation

```swift
// Sources/AIKOmacOS/Dependencies/DocumentScannerClient+macOS.swift
import AppCore
import ComposableArchitecture
import AppKit
import Vision

extension DocumentScannerClient {
    static let liveValue = Self(
        scan: {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = true
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.image, .pdf]
                    panel.message = "Select documents to import"
                    
                    if panel.runModal() == .OK {
                        var pages: [ScannedPage] = []
                        
                        for (index, url) in panel.urls.enumerated() {
                            if let imageData = try? Data(contentsOf: url) {
                                let page = ScannedPage(
                                    imageData: imageData,
                                    pageNumber: index + 1
                                )
                                pages.append(page)
                            }
                        }
                        
                        let document = ScannedDocument(
                            pages: pages,
                            title: "Imported Document"
                        )
                        
                        continuation.resume(returning: document)
                    } else {
                        continuation.resume(throwing: DocumentScannerError.userCancelled)
                    }
                }
            }
        },
        
        enhanceImage: { imageData in
            guard let nsImage = NSImage(data: imageData),
                  let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw DocumentScannerError.invalidImageData
            }
            
            let ciImage = CIImage(cgImage: cgImage)
            
            // Apply same enhancement as iOS
            var enhanced = ciImage
            
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(enhanced, forKey: kCIInputImageKey)
                filter.setValue(1.1, forKey: kCIInputContrastKey)
                filter.setValue(0.05, forKey: kCIInputBrightnessKey)
                enhanced = filter.outputImage ?? enhanced
            }
            
            let context = CIContext()
            guard let enhancedCGImage = context.createCGImage(enhanced, from: enhanced.extent) else {
                throw DocumentScannerError.enhancementFailed
            }
            
            let enhancedNSImage = NSImage(cgImage: enhancedCGImage, size: NSSize(width: enhancedCGImage.width, height: enhancedCGImage.height))
            
            guard let tiffData = enhancedNSImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
                throw DocumentScannerError.enhancementFailed
            }
            
            return jpegData
        },
        
        performOCR: { imageData in
            // Vision framework works on macOS too!
            guard let nsImage = NSImage(data: imageData),
                  let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw DocumentScannerError.invalidImageData
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                    
                    continuation.resume(returning: text)
                }
                
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-US"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        },
        
        generateThumbnail: { imageData in
            guard let nsImage = NSImage(data: imageData) else {
                throw DocumentScannerError.invalidImageData
            }
            
            let thumbnailSize = NSSize(width: 200, height: 200)
            let thumbnail = NSImage(size: thumbnailSize)
            
            thumbnail.lockFocus()
            nsImage.draw(in: NSRect(origin: .zero, size: thumbnailSize))
            thumbnail.unlockFocus()
            
            guard let tiffData = thumbnail.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
                throw DocumentScannerError.thumbnailGenerationFailed
            }
            
            return jpegData
        },
        
        saveToDocumentPipeline: { pages in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let scannerFolder = documentsURL.appendingPathComponent("ImportedDocuments")
            
            try FileManager.default.createDirectory(at: scannerFolder, withIntermediateDirectories: true)
            
            for page in pages {
                let filename = "page_\(page.pageNumber).jpg"
                let fileURL = scannerFolder.appendingPathComponent(filename)
                try page.imageData.write(to: fileURL)
            }
        }
    )
}
```

---

## Step 5: Platform-Specific Views

### iOS View
```swift
// Sources/AIKOiOS/Views/DocumentScannerView.swift
import SwiftUI
import AppCore
import ComposableArchitecture

public struct DocumentScannerView: View {
    @Bindable var store: StoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            // Clean iOS UI without any platform conditionals!
            content
                .navigationTitle("Document Scanner")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            store.send(.dismiss)
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            store.send(.saveDocument)
                        }
                        .disabled(!store.canSave)
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if store.isScanning {
            ProgressView("Scanning...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let document = store.scannedDocument {
            DocumentPagesView(
                document: document,
                selectedPages: store.selectedPages,
                onPageTap: { pageId in
                    if store.selectedPages.contains(pageId) {
                        store.send(.deselectPage(pageId))
                    } else {
                        store.send(.selectPage(pageId))
                    }
                }
            )
        } else {
            EmptyStateView(
                onScan: {
                    store.send(.scanButtonTapped)
                }
            )
        }
    }
}
```

### macOS View
```swift
// Sources/AIKOmacOS/Views/DocumentScannerView.swift
import SwiftUI
import AppCore
import ComposableArchitecture

public struct DocumentScannerView: View {
    @Bindable var store: StoreOf<DocumentScannerFeature>
    
    public init(store: StoreOf<DocumentScannerFeature>) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // macOS-style toolbar
            HStack {
                Text("Document Scanner")
                    .font(.headline)
                
                Spacer()
                
                Button("Import Files") {
                    store.send(.scanButtonTapped)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Save") {
                    store.send(.saveDocument)
                }
                .disabled(!store.canSave)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    @ViewBuilder
    private var content: some View {
        // Same structure, different styling
        if store.isScanning {
            ProgressView("Importing...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let document = store.scannedDocument {
            MacDocumentPagesView(
                document: document,
                selectedPages: store.selectedPages,
                onPageSelect: { pageId in
                    store.send(.selectPage(pageId))
                },
                onPageDeselect: { pageId in
                    store.send(.deselectPage(pageId))
                }
            )
        } else {
            MacEmptyStateView(
                onImport: {
                    store.send(.scanButtonTapped)
                }
            )
        }
    }
}
```

---

## Migration Results

### Before (Conditional-Heavy)
```swift
struct DocumentScannerView: View {
    var body: some View {
        #if os(iOS)
        NavigationStack {
            // iOS-specific implementation
            if VNDocumentCameraViewController.isSupported {
                // Camera UI
            }
        }
        #else
        VStack {
            // macOS-specific implementation
            Button("Import from File") {
                // File picker
            }
        }
        #endif
    }
}
```

### After (Clean Architecture)
- **Zero conditionals** in business logic
- **Type-safe** platform abstractions
- **Testable** with dependency injection
- **Maintainable** with clear separation
- **Scalable** to new platforms

---

## Key Takeaways

1. **Protocol-First Design**: Define capabilities, not implementations
2. **Data Over Types**: Use `Data` instead of `UIImage`/`NSImage`
3. **Dependency Injection**: Let platforms provide their implementations
4. **Clean Boundaries**: Each layer has a specific responsibility
5. **No Leaky Abstractions**: Platform details never escape their module
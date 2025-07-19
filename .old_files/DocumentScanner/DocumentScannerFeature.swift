import ComposableArchitecture
import Foundation
#if os(iOS)
import UIKit
import VisionKit
#endif

// MARK: - Scanned Page Model

public struct ScannedPage: Equatable, Identifiable {
    public let id: UUID
    #if os(iOS)
    public let originalImage: UIImage
    public var enhancedImage: UIImage?
    #else
    public let originalImage: Data
    public var enhancedImage: Data?
    #endif
    public var ocrText: String?
    public var isProcessing: Bool
    public var processingError: String?
    public var pageNumber: Int
    
    public init(
        id: UUID = UUID(),
        #if os(iOS)
        originalImage: UIImage,
        enhancedImage: UIImage? = nil,
        #else
        originalImage: Data,
        enhancedImage: Data? = nil,
        #endif
        ocrText: String? = nil,
        isProcessing: Bool = false,
        processingError: String? = nil,
        pageNumber: Int
    ) {
        self.id = id
        self.originalImage = originalImage
        self.enhancedImage = enhancedImage
        self.ocrText = ocrText
        self.isProcessing = isProcessing
        self.processingError = processingError
        self.pageNumber = pageNumber
    }
}

// MARK: - Document Scanner Feature

@Reducer
public struct DocumentScannerFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var isScannerPresented: Bool = false
        public var scannedPages: IdentifiedArrayOf<ScannedPage> = []
        public var isProcessingAllPages: Bool = false
        public var currentProcessingPage: ScannedPage.ID?
        public var error: String?
        public var showingError: Bool = false
        
        // Multi-page management
        public var selectedPages: Set<ScannedPage.ID> = []
        public var isInSelectionMode: Bool = false
        
        // Integration state
        public var isSavingToDocumentPipeline: Bool = false
        public var documentTitle: String = ""
        public var documentType: DocumentType?
        
        // Scanner configuration
        public var enableImageEnhancement: Bool = true
        public var enableOCR: Bool = true
        public var scanQuality: ScanQuality = .high
        
        public init() {}
        
        // Computed properties
        public var hasScannedPages: Bool {
            !scannedPages.isEmpty
        }
        
        public var canSaveDocument: Bool {
            hasScannedPages && !isProcessingAllPages && !isSavingToDocumentPipeline
        }
        
        public var processedPagesCount: Int {
            scannedPages.filter { !$0.isProcessing && $0.processingError == nil }.count
        }
        
        public var totalPagesCount: Int {
            scannedPages.count
        }
    }
    
    // MARK: - Actions
    
    public enum Action: Equatable {
        // Scanner presentation
        case scanButtonTapped
        case setScannerPresented(Bool)
        case scannerDidCancel
        
        // Scanner results
        #if os(iOS)
        case scannerDidFinish(Result<[UIImage], Error>)
        case processScanResults([UIImage])
        #else
        case scannerDidFinish(Result<[Data], Error>)
        case processScanResults([Data])
        #endif
        
        // Page management
        case deletePage(ScannedPage.ID)
        case deleteSelectedPages
        case reorderPages(IndexSet, Int)
        case togglePageSelection(ScannedPage.ID)
        case toggleSelectionMode
        case selectAllPages
        case deselectAllPages
        
        // Page processing
        case processPage(ScannedPage.ID)
        case pageEnhancementCompleted(ScannedPage.ID, Result<UIImage, Error>)
        case pageOCRCompleted(ScannedPage.ID, Result<String, Error>)
        case processAllPages
        case retryPageProcessing(ScannedPage.ID)
        
        // Document management
        case updateDocumentTitle(String)
        case selectDocumentType(DocumentType)
        case saveToDocumentPipeline
        case documentSaved(Result<Void, Error>)
        
        // Settings
        case toggleImageEnhancement(Bool)
        case toggleOCR(Bool)
        case updateScanQuality(ScanQuality)
        
        // Error handling
        case showError(String)
        case dismissError
        
        // Navigation
        case dismissScanner
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.documentScannerClient) var scannerClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid
    
    // MARK: - Reducer
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            // MARK: Scanner Presentation
                
            case .scanButtonTapped:
                state.isScannerPresented = true
                return .none
                
            case let .setScannerPresented(isPresented):
                state.isScannerPresented = isPresented
                return .none
                
            case .scannerDidCancel:
                state.isScannerPresented = false
                return .none
                
            // MARK: Scanner Results
                
            case let .scannerDidFinish(.success(images)):
                return .send(.processScanResults(images))
                
            case let .scannerDidFinish(.failure(error)):
                state.isScannerPresented = false
                return .send(.showError(error.localizedDescription))
                
            case let .processScanResults(images):
                state.isScannerPresented = false
                
                // Create scanned pages
                let pages = images.enumerated().map { index, image in
                    ScannedPage(
                        id: uuid(),
                        originalImage: image,
                        isProcessing: state.enableImageEnhancement || state.enableOCR,
                        pageNumber: state.scannedPages.count + index + 1
                    )
                }
                
                state.scannedPages.append(contentsOf: pages)
                
                // Process pages if enhancement or OCR is enabled
                if state.enableImageEnhancement || state.enableOCR {
                    return .run { send in
                        for page in pages {
                            await send(.processPage(page.id))
                        }
                    }
                }
                
                return .none
                
            // MARK: Page Management
                
            case let .deletePage(pageId):
                state.scannedPages.remove(id: pageId)
                state.selectedPages.remove(pageId)
                
                // Renumber remaining pages
                for (index, page) in state.scannedPages.enumerated() {
                    state.scannedPages[id: page.id]?.pageNumber = index + 1
                }
                
                return .none
                
            case .deleteSelectedPages:
                for pageId in state.selectedPages {
                    state.scannedPages.remove(id: pageId)
                }
                state.selectedPages.removeAll()
                state.isInSelectionMode = false
                
                // Renumber remaining pages
                for (index, page) in state.scannedPages.enumerated() {
                    state.scannedPages[id: page.id]?.pageNumber = index + 1
                }
                
                return .none
                
            case let .reorderPages(source, destination):
                state.scannedPages.move(fromOffsets: source, toOffset: destination)
                
                // Renumber pages after reordering
                for (index, page) in state.scannedPages.enumerated() {
                    state.scannedPages[id: page.id]?.pageNumber = index + 1
                }
                
                return .none
                
            case let .togglePageSelection(pageId):
                if state.selectedPages.contains(pageId) {
                    state.selectedPages.remove(pageId)
                } else {
                    state.selectedPages.insert(pageId)
                }
                return .none
                
            case .toggleSelectionMode:
                state.isInSelectionMode.toggle()
                if !state.isInSelectionMode {
                    state.selectedPages.removeAll()
                }
                return .none
                
            case .selectAllPages:
                state.selectedPages = Set(state.scannedPages.ids)
                return .none
                
            case .deselectAllPages:
                state.selectedPages.removeAll()
                return .none
                
            // MARK: Page Processing
                
            case let .processPage(pageId):
                guard var page = state.scannedPages[id: pageId] else { return .none }
                
                page.isProcessing = true
                page.processingError = nil
                state.scannedPages[id: pageId] = page
                state.currentProcessingPage = pageId
                
                return .run { [enableEnhancement = state.enableImageEnhancement, enableOCR = state.enableOCR] send in
                    // Enhancement
                    if enableEnhancement {
                        await send(.pageEnhancementCompleted(
                            pageId,
                            await Result {
                                try await scannerClient.enhanceImage(page.originalImage)
                            }
                        ))
                    }
                    
                    // OCR
                    if enableOCR {
                        let imageForOCR = page.enhancedImage ?? page.originalImage
                        await send(.pageOCRCompleted(
                            pageId,
                            await Result {
                                try await scannerClient.performOCR(imageForOCR)
                            }
                        ))
                    }
                }
                
            case let .pageEnhancementCompleted(pageId, .success(enhancedImage)):
                state.scannedPages[id: pageId]?.enhancedImage = enhancedImage
                
                // Check if all processing is complete for this page
                if !state.enableOCR || state.scannedPages[id: pageId]?.ocrText != nil {
                    state.scannedPages[id: pageId]?.isProcessing = false
                    if state.currentProcessingPage == pageId {
                        state.currentProcessingPage = nil
                    }
                }
                
                return .none
                
            case let .pageEnhancementCompleted(pageId, .failure(error)):
                state.scannedPages[id: pageId]?.isProcessing = false
                state.scannedPages[id: pageId]?.processingError = error.localizedDescription
                if state.currentProcessingPage == pageId {
                    state.currentProcessingPage = nil
                }
                return .none
                
            case let .pageOCRCompleted(pageId, .success(text)):
                state.scannedPages[id: pageId]?.ocrText = text
                
                // Check if all processing is complete for this page
                if !state.enableImageEnhancement || state.scannedPages[id: pageId]?.enhancedImage != nil {
                    state.scannedPages[id: pageId]?.isProcessing = false
                    if state.currentProcessingPage == pageId {
                        state.currentProcessingPage = nil
                    }
                }
                
                return .none
                
            case let .pageOCRCompleted(pageId, .failure(error)):
                state.scannedPages[id: pageId]?.isProcessing = false
                state.scannedPages[id: pageId]?.processingError = error.localizedDescription
                if state.currentProcessingPage == pageId {
                    state.currentProcessingPage = nil
                }
                return .none
                
            case .processAllPages:
                state.isProcessingAllPages = true
                
                return .run { send in
                    for page in state.scannedPages where !page.isProcessing && page.processingError == nil {
                        await send(.processPage(page.id))
                    }
                    await send(.action(.setProcessingAllPages(false)))
                }
                
            case let .retryPageProcessing(pageId):
                return .send(.processPage(pageId))
                
            // MARK: Document Management
                
            case let .updateDocumentTitle(title):
                state.documentTitle = title
                return .none
                
            case let .selectDocumentType(type):
                state.documentType = type
                return .none
                
            case .saveToDocumentPipeline:
                state.isSavingToDocumentPipeline = true
                
                let processedDocuments = state.scannedPages.map { page in
                    ProcessedDocument(
                        id: page.id,
                        image: page.enhancedImage ?? page.originalImage,
                        ocrText: page.ocrText,
                        pageNumber: page.pageNumber,
                        title: state.documentTitle,
                        type: state.documentType
                    )
                }
                
                return .run { send in
                    await send(.documentSaved(
                        await Result {
                            try await scannerClient.saveToDocumentPipeline(processedDocuments)
                        }
                    ))
                }
                
            case .documentSaved(.success):
                state.isSavingToDocumentPipeline = false
                return .run { _ in
                    await dismiss()
                }
                
            case let .documentSaved(.failure(error)):
                state.isSavingToDocumentPipeline = false
                return .send(.showError(error.localizedDescription))
                
            // MARK: Settings
                
            case let .toggleImageEnhancement(enabled):
                state.enableImageEnhancement = enabled
                return .none
                
            case let .toggleOCR(enabled):
                state.enableOCR = enabled
                return .none
                
            case let .updateScanQuality(quality):
                state.scanQuality = quality
                return .none
                
            // MARK: Error Handling
                
            case let .showError(message):
                state.error = message
                state.showingError = true
                return .none
                
            case .dismissError:
                state.error = nil
                state.showingError = false
                return .none
                
            // MARK: Navigation
                
            case .dismissScanner:
                return .run { _ in
                    await dismiss()
                }
                
            // MARK: Internal Actions
                
            case .action(.setProcessingAllPages(let isProcessing)):
                state.isProcessingAllPages = isProcessing
                return .none
            }
        }
    }
    
    // MARK: - Supporting Types
    
    public enum ScanQuality: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        public var compressionQuality: CGFloat {
            switch self {
            case .low: return 0.5
            case .medium: return 0.7
            case .high: return 0.9
            }
        }
    }
    
    public struct ProcessedDocument {
        public let id: UUID
        #if os(iOS)
        public let image: UIImage
        #else
        public let image: Data
        #endif
        public let ocrText: String?
        public let pageNumber: Int
        public let title: String
        public let type: DocumentType?
    }
    
    // Internal actions
    fileprivate enum InternalAction: Equatable {
        case setProcessingAllPages(Bool)
    }
}

// MARK: - Action Extension

extension DocumentScannerFeature.Action {
    fileprivate static func action(_ action: DocumentScannerFeature.InternalAction) -> Self {
        switch action {
        case .setProcessingAllPages(let isProcessing):
            return .processAllPages // This is a workaround, in real implementation use proper internal action handling
        }
    }
}
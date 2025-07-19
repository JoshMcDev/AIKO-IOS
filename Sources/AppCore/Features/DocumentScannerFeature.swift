import ComposableArchitecture
import Foundation

// MARK: - Document Scanner Feature (Platform-Agnostic)

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
        
        // Phase 4.1: Advanced Processing Features
        public var processingMode: ProcessingMode = .basic
        public var showProcessingProgress: Bool = false
        public var pageProcessingProgress: PageProcessingProgress?
        public var showEnhancementPreview: Bool = false
        public var enhancementPreviewPageId: ScannedPage.ID?
        public var pageProcessingTimes: [ScannedPage.ID: ProcessingTime] = [:]
        
        // Phase 4.2: Enhanced OCR Features
        public var useEnhancedOCR: Bool = true
        public var autoExtractContext: Bool = true
        public var extractedDocumentContext: ComprehensiveDocumentContext?
        public var isExtractingContext: Bool = false
        
        public init() {}
        
        // Computed properties
        public var hasScannedPages: Bool {
            !scannedPages.isEmpty
        }
        
        public var canSaveDocument: Bool {
            hasScannedPages && !isProcessingAllPages && !isSavingToDocumentPipeline
        }
        
        public var processedPagesCount: Int {
            scannedPages.filter { $0.processingState == .completed }.count
        }
        
        public var totalPagesCount: Int {
            scannedPages.count
        }
        
        // Phase 4.1: Advanced Processing Computed Properties
        public var estimatedProcessingTime: TimeInterval {
            let unprocessedPages = scannedPages.filter { 
                $0.processingState == .pending || $0.processingState.isFailed 
            }
            
            let baseTimePerPage: TimeInterval = processingMode == .enhanced ? 8.0 : 3.0
            let ocrMultiplier: TimeInterval = enableOCR ? 1.5 : 1.0
            
            return Double(unprocessedPages.count) * baseTimePerPage * ocrMultiplier
        }
        
        public var averageQualityScore: Double {
            let pagesWithQuality = scannedPages.compactMap { $0.qualityScore }
            guard !pagesWithQuality.isEmpty else { return 0.0 }
            return pagesWithQuality.reduce(0, +) / Double(pagesWithQuality.count)
        }
        
        public var canReprocessWithEnhanced: Bool {
            processingMode == .basic && hasScannedPages
        }
    }
    
    // MARK: - Actions
    
    public enum Action {
        // Scanner presentation
        case scanButtonTapped
        case setScannerPresented(Bool)
        case scannerDidCancel
        
        // Scanner results
        case scannerDidFinish(Result<ScannedDocument, Error>)
        case processScanResults(ScannedDocument)
        
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
        case pageEnhancementCompleted(ScannedPage.ID, Result<Data, Error>)
        case pageOCRCompleted(ScannedPage.ID, Result<String, Error>)
        case pageEnhancedOCRCompleted(ScannedPage.ID, Result<OCRResult, Error>)
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
        
        // Phase 4.1: Advanced Processing Actions
        case updateProcessingMode(ProcessingMode)
        case startProcessingProgress(ScannedPage.ID)
        case updateProcessingProgress(PageProcessingProgress)
        case finishProcessingProgress(ScannedPage.ID, ProcessingTime)
        case showEnhancementPreview(ScannedPage.ID)
        case hideEnhancementPreview
        case reprocessWithEnhanced([ScannedPage.ID])
        case reprocessAllWithEnhanced
        
        // Phase 4.2: Enhanced OCR Actions
        case toggleEnhancedOCR(Bool)
        case toggleAutoExtractContext(Bool)
        case extractDocumentContext
        case documentContextExtracted(Result<ComprehensiveDocumentContext, Error>)
        
        // Error handling
        case showError(String)
        case dismissError
        
        // Navigation
        case dismissScanner
        
        // Internal
        case _setProcessingAllPages(Bool)
        case _setProcessingComplete(ScannedPage.ID)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.documentScanner) var scannerClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.uuid) var uuid
    @Dependency(\.documentContextExtractor) var contextExtractor
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Reducer
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            // MARK: Scanner Presentation
                
            case .scanButtonTapped:
                guard scannerClient.isScanningAvailable() else {
                    return .send(.showError("Document scanning is not available on this device"))
                }
                state.isScannerPresented = true
                return .none
                
            case let .setScannerPresented(isPresented):
                state.isScannerPresented = isPresented
                return .none
                
            case .scannerDidCancel:
                state.isScannerPresented = false
                return .none
                
            // MARK: Scanner Results
                
            case let .scannerDidFinish(.success(document)):
                return .send(.processScanResults(document))
                
            case let .scannerDidFinish(.failure(error)):
                state.isScannerPresented = false
                if case DocumentScannerError.userCancelled = error {
                    return .none
                }
                return .send(.showError(error.localizedDescription))
                
            case let .processScanResults(document):
                state.isScannerPresented = false
                
                // Add the scanned pages to our state
                state.scannedPages.append(contentsOf: document.pages)
                
                // Process pages if enhancement or OCR is enabled
                if state.enableImageEnhancement || state.enableOCR {
                    return .run { send in
                        for page in document.pages {
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
                
                page.processingState = .processing
                state.scannedPages[id: pageId] = page
                state.currentProcessingPage = pageId
                
                // Capture page data for use in the async context
                let pageImageData = page.imageData
                let pageEnhancedImageData = page.enhancedImageData
                
                return .run { [enableEnhancement = state.enableImageEnhancement, enableOCR = state.enableOCR, useEnhancedOCR = state.useEnhancedOCR] send in
                    // Enhancement
                    if enableEnhancement {
                        await send(.pageEnhancementCompleted(
                            pageId,
                            await Result {
                                try await scannerClient.enhanceImage(pageImageData)
                            }
                        ))
                    }
                    
                    // OCR - Use enhanced OCR if enabled
                    if enableOCR {
                        let imageForOCR = pageEnhancedImageData ?? pageImageData
                        
                        if useEnhancedOCR {
                            await send(.pageEnhancedOCRCompleted(
                                pageId,
                                await Result {
                                    try await scannerClient.performEnhancedOCR(imageForOCR)
                                }
                            ))
                        } else {
                            // Fallback to legacy OCR
                            await send(.pageOCRCompleted(
                                pageId,
                                await Result {
                                    try await scannerClient.performOCR(imageForOCR)
                                }
                            ))
                        }
                    }
                    
                    // Mark as completed if no processing was needed
                    if !enableEnhancement && !enableOCR {
                        await send(._setProcessingComplete(pageId))
                    }
                }
                
            case let .pageEnhancementCompleted(pageId, .success(enhancedData)):
                state.scannedPages[id: pageId]?.enhancedImageData = enhancedData
                
                // Check if all processing is complete for this page
                if !state.enableOCR || state.scannedPages[id: pageId]?.ocrText != nil {
                    state.scannedPages[id: pageId]?.processingState = .completed
                    if state.currentProcessingPage == pageId {
                        state.currentProcessingPage = nil
                    }
                }
                
                return .none
                
            case let .pageEnhancementCompleted(pageId, .failure(error)):
                state.scannedPages[id: pageId]?.processingState = .failed(error.localizedDescription)
                if state.currentProcessingPage == pageId {
                    state.currentProcessingPage = nil
                }
                return .none
                
            case let .pageOCRCompleted(pageId, .success(text)):
                state.scannedPages[id: pageId]?.ocrText = text
                
                // Check if all processing is complete for this page
                if !state.enableImageEnhancement || state.scannedPages[id: pageId]?.enhancedImageData != nil {
                    state.scannedPages[id: pageId]?.processingState = .completed
                    if state.currentProcessingPage == pageId {
                        state.currentProcessingPage = nil
                    }
                }
                
                return .none
                
            case let .pageOCRCompleted(pageId, .failure(error)):
                state.scannedPages[id: pageId]?.processingState = .failed(error.localizedDescription)
                if state.currentProcessingPage == pageId {
                    state.currentProcessingPage = nil
                }
                return .none
                
            case let .pageEnhancedOCRCompleted(pageId, .success(ocrResult)):
                state.scannedPages[id: pageId]?.ocrText = ocrResult.fullText
                state.scannedPages[id: pageId]?.ocrResult = ocrResult
                
                // Check if all processing is complete for this page
                if !state.enableImageEnhancement || state.scannedPages[id: pageId]?.enhancedImageData != nil {
                    state.scannedPages[id: pageId]?.processingState = .completed
                    if state.currentProcessingPage == pageId {
                        state.currentProcessingPage = nil
                    }
                }
                
                // Auto-extract document context if enabled and all pages are processed
                if state.autoExtractContext && state.processedPagesCount == state.totalPagesCount {
                    return .send(.extractDocumentContext)
                }
                
                return .none
                
            case let .pageEnhancedOCRCompleted(pageId, .failure(error)):
                state.scannedPages[id: pageId]?.processingState = .failed(error.localizedDescription)
                if state.currentProcessingPage == pageId {
                    state.currentProcessingPage = nil
                }
                return .none
                
            case .processAllPages:
                state.isProcessingAllPages = true
                
                let pagesToProcess = state.scannedPages.filter { 
                    $0.processingState == .pending || $0.processingState.isFailed
                }
                
                return .run { send in
                    for page in pagesToProcess {
                        await send(.processPage(page.id))
                    }
                    await send(._setProcessingAllPages(false))
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
                
                let pages = Array(state.scannedPages)
                
                return .run { send in
                    await send(.documentSaved(
                        await Result {
                            try await scannerClient.saveToDocumentPipeline(pages)
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
                
            // MARK: Phase 4.1 Advanced Processing
                
            case let .updateProcessingMode(mode):
                state.processingMode = mode
                return .none
                
            case let .startProcessingProgress(pageId):
                state.showProcessingProgress = true
                state.pageProcessingProgress = PageProcessingProgress(
                    pageId: pageId,
                    processingProgress: ProcessingProgress(
                        currentStep: .preprocessing,
                        stepProgress: 0.0,
                        overallProgress: 0.0
                    ),
                    startTime: Date()
                )
                return .none
                
            case let .updateProcessingProgress(progress):
                state.pageProcessingProgress = progress
                return .none
                
            case let .finishProcessingProgress(pageId, processingTime):
                state.showProcessingProgress = false
                state.pageProcessingProgress = nil
                state.pageProcessingTimes[pageId] = processingTime
                return .none
                
            case let .showEnhancementPreview(pageId):
                state.showEnhancementPreview = true
                state.enhancementPreviewPageId = pageId
                return .none
                
            case .hideEnhancementPreview:
                state.showEnhancementPreview = false
                state.enhancementPreviewPageId = nil
                return .none
                
            case let .reprocessWithEnhanced(pageIds):
                _ = state.processingMode
                state.processingMode = .enhanced
                
                return .run { send in
                    for pageId in pageIds {
                        await send(.processPage(pageId))
                    }
                }
                
            case .reprocessAllWithEnhanced:
                _ = state.processingMode
                state.processingMode = .enhanced
                
                let pageIds = state.scannedPages.map { $0.id }
                
                return .run { send in
                    for pageId in pageIds {
                        await send(.processPage(pageId))
                    }
                }
                
            // MARK: Phase 4.2 Enhanced OCR
                
            case let .toggleEnhancedOCR(enabled):
                state.useEnhancedOCR = enabled
                return .none
                
            case let .toggleAutoExtractContext(enabled):
                state.autoExtractContext = enabled
                return .none
                
            case .extractDocumentContext:
                state.isExtractingContext = true
                
                // Collect all OCR results from processed pages
                let ocrResults = state.scannedPages.compactMap { page in
                    page.ocrResult
                }
                
                // Collect enhanced image data for adaptive learning
                let pageImageData = state.scannedPages.compactMap { page in
                    page.enhancedImageData ?? page.imageData
                }
                
                return .run { [contextExtractor = self.contextExtractor] send in
                    await send(.documentContextExtracted(
                        await Result {
                            // Use the DocumentContextExtractionService for Phase 4.2 integration
                            try await contextExtractor.extractComprehensiveContext(
                                from: ocrResults,
                                pageImageData: pageImageData,
                                withHints: [
                                    "document_scanner": true,
                                    "enhanced_ocr": true,
                                    "processing_mode": "scanner_integration"
                                ]
                            )
                        }
                    ))
                }
                
            case let .documentContextExtracted(.success(context)):
                state.isExtractingContext = false
                state.extractedDocumentContext = context
                return .none
                
            case let .documentContextExtracted(.failure(error)):
                state.isExtractingContext = false
                return .send(.showError("Context extraction failed: \(error.localizedDescription)"))
                
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
                
            case let ._setProcessingAllPages(isProcessing):
                state.isProcessingAllPages = isProcessing
                return .none
                
            case let ._setProcessingComplete(pageId):
                state.scannedPages[id: pageId]?.processingState = .completed
                if state.currentProcessingPage == pageId {
                    state.currentProcessingPage = nil
                }
                return .none
            }
        }
    }
    
    // MARK: - Supporting Types
    
    public enum ScanQuality: String, CaseIterable, Equatable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        public var compressionQuality: Double {
            switch self {
            case .low: return 0.5
            case .medium: return 0.7
            case .high: return 0.9
            }
        }
    }
    
    // MARK: - Phase 4.1 Supporting Types
    
    public struct PageProcessingProgress: Equatable {
        public let pageId: ScannedPage.ID
        public let processingProgress: ProcessingProgress
        public let startTime: Date
        
        public init(pageId: ScannedPage.ID, processingProgress: ProcessingProgress, startTime: Date) {
            self.pageId = pageId
            self.processingProgress = processingProgress
            self.startTime = startTime
        }
        
        public var elapsedTime: TimeInterval {
            Date().timeIntervalSince(startTime)
        }
        
        public var estimatedRemainingTime: TimeInterval {
            processingProgress.estimatedTimeRemaining ?? 0
        }
    }
    
    public struct ProcessingTime: Equatable {
        public let totalTime: TimeInterval
        public let enhancementTime: TimeInterval?
        public let ocrTime: TimeInterval?
        public let qualityAnalysisTime: TimeInterval?
        
        public init(totalTime: TimeInterval, enhancementTime: TimeInterval? = nil, ocrTime: TimeInterval? = nil, qualityAnalysisTime: TimeInterval? = nil) {
            self.totalTime = totalTime
            self.enhancementTime = enhancementTime
            self.ocrTime = ocrTime
            self.qualityAnalysisTime = qualityAnalysisTime
        }
        
        public var formattedTotalTime: String {
            if totalTime < 1.0 {
                return String(format: "%.1fs", totalTime)
            } else {
                return String(format: "%.0fs", totalTime)
            }
        }
    }
}

// MARK: - Extensions

extension ScannedPage.ProcessingState {
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

// MARK: - Action Equatable Conformance

extension DocumentScannerFeature.Action: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.scanButtonTapped, .scanButtonTapped),
             (.scannerDidCancel, .scannerDidCancel),
             (.toggleSelectionMode, .toggleSelectionMode),
             (.selectAllPages, .selectAllPages),
             (.deselectAllPages, .deselectAllPages),
             (.deleteSelectedPages, .deleteSelectedPages),
             (.processAllPages, .processAllPages),
             (.saveToDocumentPipeline, .saveToDocumentPipeline),
             (.dismissError, .dismissError),
             (.dismissScanner, .dismissScanner):
            return true
            
        case let (.setScannerPresented(l), .setScannerPresented(r)):
            return l == r
            
        case let (.processScanResults(l), .processScanResults(r)):
            return l == r
            
        case let (.deletePage(l), .deletePage(r)):
            return l == r
            
        case let (.reorderPages(l1, l2), .reorderPages(r1, r2)):
            return l1 == r1 && l2 == r2
            
        case let (.togglePageSelection(l), .togglePageSelection(r)):
            return l == r
            
        case let (.processPage(l), .processPage(r)):
            return l == r
            
        case let (.retryPageProcessing(l), .retryPageProcessing(r)):
            return l == r
            
        case let (.updateDocumentTitle(l), .updateDocumentTitle(r)):
            return l == r
            
        case let (.selectDocumentType(l), .selectDocumentType(r)):
            return l == r
            
        case let (.toggleImageEnhancement(l), .toggleImageEnhancement(r)):
            return l == r
            
        case let (.toggleOCR(l), .toggleOCR(r)):
            return l == r
            
        case let (.updateScanQuality(l), .updateScanQuality(r)):
            return l == r
            
        case let (.showError(l), .showError(r)):
            return l == r
            
        case let (._setProcessingAllPages(l), ._setProcessingAllPages(r)):
            return l == r
            
        case let (._setProcessingComplete(l), ._setProcessingComplete(r)):
            return l == r
            
        // Result comparisons
        case let (.scannerDidFinish(l), .scannerDidFinish(r)):
            switch (l, r) {
            case let (.success(lVal), .success(rVal)):
                return lVal == rVal
            case let (.failure(lErr), .failure(rErr)):
                return (lErr as NSError) == (rErr as NSError)
            default:
                return false
            }
            
        case let (.pageEnhancementCompleted(lId, lResult), .pageEnhancementCompleted(rId, rResult)):
            guard lId == rId else { return false }
            switch (lResult, rResult) {
            case let (.success(lVal), .success(rVal)):
                return lVal == rVal
            case let (.failure(lErr), .failure(rErr)):
                return (lErr as NSError) == (rErr as NSError)
            default:
                return false
            }
            
        case let (.pageOCRCompleted(lId, lResult), .pageOCRCompleted(rId, rResult)):
            guard lId == rId else { return false }
            switch (lResult, rResult) {
            case let (.success(lVal), .success(rVal)):
                return lVal == rVal
            case let (.failure(lErr), .failure(rErr)):
                return (lErr as NSError) == (rErr as NSError)
            default:
                return false
            }
            
        case let (.documentSaved(l), .documentSaved(r)):
            switch (l, r) {
            case (.success, .success):
                return true
            case let (.failure(lErr), .failure(rErr)):
                return (lErr as NSError) == (rErr as NSError)
            default:
                return false
            }
            
        default:
            return false
        }
    }
}

// MARK: - Phase 4.2 Helper Functions

extension DocumentScannerFeature {
    // Helper functions have been moved to UnifiedDocumentContextExtractor
    // for enhanced integration and sophisticated analysis capabilities
}
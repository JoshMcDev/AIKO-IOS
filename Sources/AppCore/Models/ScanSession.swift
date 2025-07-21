import ComposableArchitecture
import Foundation

// MARK: - Scan Session Models

/// Immutable session state for multi-page scanning
public struct ScanSession: Equatable, Sendable {
    public let id: UUID
    public var pages: IdentifiedArrayOf<SessionPage>
    public var status: SessionStatus
    public var batchOperationState: BatchOperationState
    public var lastError: ScanError?
    public var metadata: ScanSessionMetadata
    
    public init(
        id: UUID = UUID(),
        pages: IdentifiedArrayOf<SessionPage> = [],
        status: SessionStatus = .ready,
        batchOperationState: BatchOperationState = .idle,
        lastError: ScanError? = nil,
        metadata: ScanSessionMetadata = ScanSessionMetadata()
    ) {
        self.id = id
        self.pages = pages
        self.status = status
        self.batchOperationState = batchOperationState
        self.lastError = lastError
        self.metadata = metadata
    }
}

/// Individual page within a scan session
public struct SessionPage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var documentID: String?
    public var imageData: Data
    public var thumbnailData: Data?
    public var enhancedImageData: Data?
    public var ocrText: String?
    public var ocrResult: OCRResult?
    public var pageMetadata: PageMetadata
    public var processingStatus: PageProcessingStatus
    public var order: Int
    
    public init(
        id: UUID = UUID(),
        documentID: String? = nil,
        imageData: Data,
        thumbnailData: Data? = nil,
        enhancedImageData: Data? = nil,
        ocrText: String? = nil,
        ocrResult: OCRResult? = nil,
        pageMetadata: PageMetadata = PageMetadata(),
        processingStatus: PageProcessingStatus = .pending,
        order: Int
    ) {
        self.id = id
        self.documentID = documentID
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.enhancedImageData = enhancedImageData
        self.ocrText = ocrText
        self.ocrResult = ocrResult
        self.pageMetadata = pageMetadata
        self.processingStatus = processingStatus
        self.order = order
    }
}

// MARK: - SessionPage Codable Implementation
extension SessionPage: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, documentID, imageData, thumbnailData, enhancedImageData, ocrText, pageMetadata, processingStatus, order
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        documentID = try container.decodeIfPresent(String.self, forKey: .documentID)
        imageData = try container.decode(Data.self, forKey: .imageData)
        thumbnailData = try container.decodeIfPresent(Data.self, forKey: .thumbnailData)
        enhancedImageData = try container.decodeIfPresent(Data.self, forKey: .enhancedImageData)
        ocrText = try container.decodeIfPresent(String.self, forKey: .ocrText)
        pageMetadata = try container.decode(PageMetadata.self, forKey: .pageMetadata)
        processingStatus = try container.decode(PageProcessingStatus.self, forKey: .processingStatus)
        order = try container.decode(Int.self, forKey: .order)
        // Skip ocrResult as it's not Codable due to CGRect dependencies
        ocrResult = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(documentID, forKey: .documentID)
        try container.encode(imageData, forKey: .imageData)
        try container.encodeIfPresent(thumbnailData, forKey: .thumbnailData)
        try container.encodeIfPresent(enhancedImageData, forKey: .enhancedImageData)
        try container.encodeIfPresent(ocrText, forKey: .ocrText)
        try container.encode(pageMetadata, forKey: .pageMetadata)
        try container.encode(processingStatus, forKey: .processingStatus)
        try container.encode(order, forKey: .order)
        // Skip ocrResult as it's not Codable due to CGRect dependencies
    }
}

// MARK: - ScanSession Codable Implementation
extension ScanSession: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, pages, status, batchOperationState, metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pages = try container.decode(IdentifiedArrayOf<SessionPage>.self, forKey: .pages)
        status = try container.decode(SessionStatus.self, forKey: .status)
        batchOperationState = try container.decode(BatchOperationState.self, forKey: .batchOperationState)
        metadata = try container.decode(ScanSessionMetadata.self, forKey: .metadata)
        // Skip lastError as ScanError is not easily Codable
        lastError = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pages, forKey: .pages)
        try container.encode(status, forKey: .status)
        try container.encode(batchOperationState, forKey: .batchOperationState)
        try container.encode(metadata, forKey: .metadata)
        // Skip lastError as ScanError is not easily Codable
    }
}

/// Session status enumeration
public enum SessionStatus: String, CaseIterable, Equatable, Sendable, Codable {
    case ready = "Ready"
    case capturing = "Capturing"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case recovered = "Recovered"
    
    public var displayName: String {
        rawValue
    }
    
    public var isActive: Bool {
        switch self {
        case .ready, .capturing, .processing, .recovered:
            return true
        case .completed, .failed:
            return false
        }
    }
}

/// Batch operation state
public enum BatchOperationState: Equatable, Sendable, Codable {
    case idle
    case inProgress(completedCount: Int, total: Int)
    case paused(completedCount: Int, total: Int)
    case failed(completedCount: Int, total: Int, error: String)
    case completed(total: Int)
    
    public var progress: Double {
        switch self {
        case .idle:
            return 0.0
        case .inProgress(let completed, let total),
             .paused(let completed, let total),
             .failed(let completed, let total, _):
            return total > 0 ? Double(completed) / Double(total) : 0.0
        case .completed:
            return 1.0
        }
    }
    
    public var isProcessing: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }
}

/// Page processing status
public enum PageProcessingStatus: Equatable, Sendable, Codable {
    case pending
    case processing
    case processed
    case failed(String)
    
    public var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .processed:
            return "Processed"
        case .failed:
            return "Failed"
        }
    }
    
    public var isCompleted: Bool {
        switch self {
        case .processed:
            return true
        default:
            return false
        }
    }
}

/// Session metadata
public struct ScanSessionMetadata: Equatable, Sendable, Codable {
    public let creationDate: Date
    public var modificationDate: Date
    public var jobID: String?
    public var documentType: ScannerDocumentType?
    public var lastAutosaveCheckpoint: Date?
    public var sessionTags: [String]
    public var customFields: [String: String]
    
    public init(
        creationDate: Date = Date(),
        modificationDate: Date = Date(),
        jobID: String? = nil,
        documentType: ScannerDocumentType? = nil,
        lastAutosaveCheckpoint: Date? = nil,
        sessionTags: [String] = [],
        customFields: [String: String] = [:]
    ) {
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.jobID = jobID
        self.documentType = documentType
        self.lastAutosaveCheckpoint = lastAutosaveCheckpoint
        self.sessionTags = sessionTags
        self.customFields = customFields
    }
}

/// Page metadata
public struct PageMetadata: Equatable, Sendable, Codable {
    public let captureDate: Date
    public var captureSource: CaptureSource
    public var qualityScore: Double?
    public var detectedFeatures: [String]
    public var processingNotes: String?
    
    public init(
        captureDate: Date = Date(),
        captureSource: CaptureSource = .camera,
        qualityScore: Double? = nil,
        detectedFeatures: [String] = [],
        processingNotes: String? = nil
    ) {
        self.captureDate = captureDate
        self.captureSource = captureSource
        self.qualityScore = qualityScore
        self.detectedFeatures = detectedFeatures
        self.processingNotes = processingNotes
    }
}

/// Capture source enumeration
public enum CaptureSource: String, CaseIterable, Equatable, Sendable, Codable {
    case camera = "Camera"
    case fileImport = "File Import"
    case scanner = "Scanner"
    case unknown = "Unknown"
    
    public var displayName: String {
        rawValue
    }
}

/// Scan session errors
public enum ScanError: LocalizedError, Equatable, Sendable, Codable {
    case sessionNotFound
    case pageNotFound(UUID)
    case processingFailed(String)
    case batchOperationFailed(String)
    case recoveryFailed(String)
    case storageError(String)
    case invalidPageOrder
    case sessionCorrupted
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Scan session not found"
        case .pageNotFound(let id):
            return "Page with ID \(id) not found in session"
        case .processingFailed(let reason):
            return "Page processing failed: \(reason)"
        case .batchOperationFailed(let reason):
            return "Batch operation failed: \(reason)"
        case .recoveryFailed(let reason):
            return "Session recovery failed: \(reason)"
        case .storageError(let reason):
            return "Storage error: \(reason)"
        case .invalidPageOrder:
            return "Invalid page order specified"
        case .sessionCorrupted:
            return "Scan session data is corrupted"
        }
    }
}

// MARK: - Session Extensions

public extension ScanSession {
    /// Total number of pages in the session
    var pageCount: Int {
        pages.count
    }
    
    /// Number of processed pages
    var processedPageCount: Int {
        pages.count { $0.processingStatus.isCompleted }
    }
    
    /// Session completion percentage
    var completionProgress: Double {
        pageCount > 0 ? Double(processedPageCount) / Double(pageCount) : 0.0
    }
    
    /// Check if all pages are processed
    var isFullyProcessed: Bool {
        !pages.isEmpty && pages.allSatisfy { $0.processingStatus.isCompleted }
    }
    
    /// Get pages by processing status
    func pages(withStatus status: PageProcessingStatus) -> [SessionPage] {
        pages.filter { $0.processingStatus == status }
    }
    
    /// Get next page to process
    var nextPageToProcess: SessionPage? {
        pages.first { $0.processingStatus == .pending }
    }
    
    /// Update modification date
    mutating func touch() {
        metadata.modificationDate = Date()
    }
}

public extension SessionPage {
    /// Convert to ScannedPage for compatibility
    func toScannedPage() -> ScannedPage {
        ScannedPage(
            id: id,
            imageData: imageData,
            thumbnailData: thumbnailData,
            enhancedImageData: enhancedImageData,
            ocrText: ocrText,
            ocrResult: ocrResult,
            pageNumber: order + 1,
            processingState: processingStatus.toProcessingState()
        )
    }
}

public extension PageProcessingStatus {
    /// Convert to ScannedPage.ProcessingState for compatibility
    func toProcessingState() -> ScannedPage.ProcessingState {
        switch self {
        case .pending:
            return .pending
        case .processing:
            return .processing
        case .processed:
            return .completed
        case .failed(let reason):
            return .failed(reason)
        }
    }
}
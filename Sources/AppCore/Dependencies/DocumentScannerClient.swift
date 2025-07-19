import ComposableArchitecture
import Foundation

// MARK: - Platform-Agnostic Models

/// Represents a scanned document with multiple pages
public struct ScannedDocument: Equatable, Sendable {
    public let id: UUID
    public let pages: [ScannedPage]
    public let title: String
    public let scannedAt: Date
    public let metadata: DocumentMetadata
    
    public init(
        id: UUID = UUID(),
        pages: [ScannedPage],
        title: String = "Untitled Document",
        scannedAt: Date = Date(),
        metadata: DocumentMetadata = DocumentMetadata()
    ) {
        self.id = id
        self.pages = pages
        self.title = title
        self.scannedAt = scannedAt
        self.metadata = metadata
    }
}

/// Represents a single page in a scanned document
public struct ScannedPage: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let imageData: Data  // Platform-agnostic image representation
    public var thumbnailData: Data?
    public var enhancedImageData: Data?
    public var ocrText: String?
    public var pageNumber: Int
    public var processingState: ProcessingState
    
    public init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data? = nil,
        enhancedImageData: Data? = nil,
        ocrText: String? = nil,
        pageNumber: Int,
        processingState: ProcessingState = .pending
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.enhancedImageData = enhancedImageData
        self.ocrText = ocrText
        self.pageNumber = pageNumber
        self.processingState = processingState
    }
    
    public enum ProcessingState: Equatable, Sendable {
        case pending
        case processing
        case completed
        case failed(String)
    }
}

/// Document metadata
public struct DocumentMetadata: Equatable, Sendable {
    public let source: DocumentSource
    public let captureDate: Date
    public let deviceInfo: String?
    
    public init(
        source: DocumentSource = .unknown,
        captureDate: Date = Date(),
        deviceInfo: String? = nil
    ) {
        self.source = source
        self.captureDate = captureDate
        self.deviceInfo = deviceInfo
    }
    
    public enum DocumentSource: String, Equatable, Sendable {
        case camera = "Camera"
        case fileImport = "File Import"
        case scanner = "Scanner"
        case unknown = "Unknown"
    }
}

// MARK: - Document Scanner Client Protocol

/// Platform-agnostic protocol for document scanning capabilities
@DependencyClient
public struct DocumentScannerClient: Sendable {
    /// Initiates the document scanning process
    public var scan: @Sendable () async throws -> ScannedDocument
    
    /// Enhances a scanned image (contrast, brightness, etc.)
    public var enhanceImage: @Sendable (Data) async throws -> Data
    
    /// Performs Optical Character Recognition on image data
    public var performOCR: @Sendable (Data) async throws -> String
    
    /// Generates a thumbnail from image data
    public var generateThumbnail: @Sendable (Data, CGSize) async throws -> Data
    
    /// Saves scanned documents to the document pipeline
    public var saveToDocumentPipeline: @Sendable ([ScannedPage]) async throws -> Void
    
    /// Checks if scanning is available on the current platform
    public var isScanningAvailable: @Sendable () -> Bool = { false }
}

// MARK: - Dependency Registration

extension DocumentScannerClient: DependencyKey {
    public static var liveValue: Self = Self()
    
    public static var testValue: Self = Self(
        scan: { 
            ScannedDocument(
                pages: [
                    ScannedPage(
                        imageData: Data(),
                        pageNumber: 1
                    )
                ],
                title: "Test Document"
            )
        },
        enhanceImage: { data in data },
        performOCR: { _ in "Test OCR Text" },
        generateThumbnail: { data, _ in data },
        saveToDocumentPipeline: { _ in },
        isScanningAvailable: { true }
    )
}

extension DependencyValues {
    public var documentScanner: DocumentScannerClient {
        get { self[DocumentScannerClient.self] }
        set { self[DocumentScannerClient.self] = newValue }
    }
}

// MARK: - Supporting Types

/// Errors that can occur during document scanning
public enum DocumentScannerError: LocalizedError, Equatable {
    case scanningNotAvailable
    case userCancelled
    case invalidImageData
    case enhancementFailed
    case ocrFailed(String)
    case saveFailed(String)
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .scanningNotAvailable:
            return "Document scanning is not available on this device"
        case .userCancelled:
            return "Scanning was cancelled"
        case .invalidImageData:
            return "The image data is invalid or corrupted"
        case .enhancementFailed:
            return "Failed to enhance the image"
        case .ocrFailed(let reason):
            return "Text recognition failed: \(reason)"
        case .saveFailed(let reason):
            return "Failed to save document: \(reason)"
        case .unknownError(let message):
            return message
        }
    }
}
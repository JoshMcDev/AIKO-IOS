import Foundation

// MARK: - Document Parsing Types

/// Type of parsed document
public enum ParsedDocumentType: String, Codable, CaseIterable {
    case pdf
    case word
    case excel
    case text
    case rtf
    case png
    case jpg
    case jpeg
    case heic
    case ocr // Phase 4.2: OCR-processed document
    case unknown
    
    public init(from mimeType: String) {
        switch mimeType.lowercased() {
        case "application/pdf":
            self = .pdf
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
             "application/msword":
            self = .word
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
             "application/vnd.ms-excel":
            self = .excel
        case "text/plain":
            self = .text
        case "text/rtf", "application/rtf":
            self = .rtf
        case "image/png":
            self = .png
        case "image/jpeg", "image/jpg":
            self = .jpg
        case "image/heic", "image/heif":
            self = .heic
        default:
            self = .unknown
        }
    }
    
    public var isImage: Bool {
        switch self {
        case .png, .jpg, .jpeg, .heic:
            return true
        default:
            return false
        }
    }
}

/// Parsed document data structure
public struct ParsedDocument: Codable, Equatable {
    public let id: UUID
    public let sourceType: ParsedDocumentType
    public let extractedText: String
    public let metadata: ParsedDocumentMetadata
    public let extractedData: ExtractedData
    public let confidence: Double
    public let parseDate: Date
    
    public init(
        id: UUID = UUID(),
        sourceType: ParsedDocumentType,
        extractedText: String,
        metadata: ParsedDocumentMetadata,
        extractedData: ExtractedData,
        confidence: Double,
        parseDate: Date = Date()
    ) {
        self.id = id
        self.sourceType = sourceType
        self.extractedText = extractedText
        self.metadata = metadata
        self.extractedData = extractedData
        self.confidence = confidence
        self.parseDate = parseDate
    }
}

/// Document parsing metadata
public struct ParsedDocumentMetadata: Codable, Equatable {
    public let fileName: String?
    public let fileSize: Int
    public let pageCount: Int?
    public let author: String?
    public let creationDate: Date?
    public let modificationDate: Date?
    
    public init(
        fileName: String? = nil,
        fileSize: Int,
        pageCount: Int? = nil,
        author: String? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil
    ) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.author = author
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}

/// Extracted data from document
public struct ExtractedData: Codable, Equatable {
    public let entities: [ExtractedEntity]
    public let relationships: [ExtractedRelationship]
    public let tables: [ExtractedTable]
    public let summary: String?
    
    public init(
        entities: [ExtractedEntity] = [],
        relationships: [ExtractedRelationship] = [],
        tables: [ExtractedTable] = [],
        summary: String? = nil
    ) {
        self.entities = entities
        self.relationships = relationships
        self.tables = tables
        self.summary = summary
    }
}

/// Extracted entity from document
public struct ExtractedEntity: Codable, Equatable {
    public let type: EntityType
    public let value: String
    public let confidence: Double
    public let location: ExtractedLocation?
    
    public enum EntityType: String, Codable {
        case vendor
        case price
        case date
        case quantity
        case partNumber
        case address
        case email
        case phone
        case person
        case organization
        case unknown
    }
    
    public init(
        type: EntityType,
        value: String,
        confidence: Double,
        location: ExtractedLocation? = nil
    ) {
        self.type = type
        self.value = value
        self.confidence = confidence
        self.location = location
    }
}

/// Relationship between extracted entities
public struct ExtractedRelationship: Codable, Equatable {
    public let from: ExtractedEntity
    public let to: ExtractedEntity
    public let type: RelationshipType
    
    public enum RelationshipType: String, Codable {
        case suppliedBy
        case pricedAt
        case deliveredOn
        case contains
        case partOf
        case relatedTo
    }
    
    public init(from: ExtractedEntity, to: ExtractedEntity, type: RelationshipType) {
        self.from = from
        self.to = to
        self.type = type
    }
}

/// Extracted table from document
public struct ExtractedTable: Codable, Equatable {
    public let headers: [String]
    public let rows: [[String]]
    public let confidence: Double
    
    public init(headers: [String], rows: [[String]], confidence: Double) {
        self.headers = headers
        self.rows = rows
        self.confidence = confidence
    }
}

/// Location information for extracted data
public struct ExtractedLocation: Codable, Equatable {
    public let pageNumber: Int
    public let boundingBox: CGRect?
    
    public init(pageNumber: Int, boundingBox: CGRect? = nil) {
        self.pageNumber = pageNumber
        self.boundingBox = boundingBox
    }
}

// MARK: - Document Parser Error

public enum DocumentParserError: Error {
    case invalidPDFData
    case invalidImageData
    case invalidTextEncoding
    case unsupportedFormat
    case ocrFailed
    case extractionFailed
}


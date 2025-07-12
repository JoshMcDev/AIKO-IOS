import Foundation
import PDFKit
import Vision
import CoreGraphics
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Enhanced Document Parser

public class DocumentParserEnhanced {
    private let validator: DocumentParserValidator
    private let documentParser: DocumentParser
    
    public init() {
        self.validator = DocumentParserValidator()
        self.documentParser = DocumentParser()
    }
    
    /// Parse a document and return structured data
    public func parse(_ data: Data, type: ParsedDocumentType) async throws -> ParsedDocument {
        // Validate the document first
        let validationResult = await validator.validate(data, expectedType: type.toDocumentValidationType())
        
        guard validationResult.isValid else {
            throw DocumentParserError.invalidTextEncoding // Use existing error case
        }
        
        // Parse based on type
        let extractedText: String
        let metadata: ParsedDocumentMetadata
        
        switch type {
        case .pdf:
            extractedText = try await parsePDF(data)
            metadata = extractPDFMetadata(data)
            
        case .word:
            extractedText = try await parseWord(data)
            metadata = extractWordMetadata(data)
            
        case .png, .jpg, .jpeg, .heic:
            extractedText = try await parseImage(data)
            metadata = ParsedDocumentMetadata(fileSize: data.count)
            
        case .text:
            extractedText = String(data: data, encoding: .utf8) ?? ""
            metadata = ParsedDocumentMetadata(fileSize: data.count)
            
        default:
            throw DocumentParserError.unsupportedFormat
        }
        
        // Extract structured data using data extractor
        let dataExtractor = DataExtractor()
        let structuredData = try await dataExtractor.extract(from: extractedText)
        
        // Convert DataExtractor's ExtractedData to DocumentParserEnhanced's ExtractedData
        let entities = convertToEntities(from: structuredData)
        let relationships = extractRelationships(from: structuredData)
        let tables: [ExtractedTable] = [] // TODO: Extract tables from structured data
        
        let enhancedExtractedData = ExtractedData(
            entities: entities,
            relationships: relationships,
            tables: tables,
            summary: nil
        )
        
        // Calculate confidence based on extraction results
        let confidence = calculateConfidence(extractedData: enhancedExtractedData, textLength: extractedText.count)
        
        return ParsedDocument(
            sourceType: type,
            extractedText: extractedText,
            metadata: metadata,
            extractedData: enhancedExtractedData,
            confidence: confidence
        )
    }
    
    // MARK: - Private Parsing Methods
    
    private func parsePDF(_ data: Data) async throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw DocumentParserError.invalidPDFData
        }
        
        var fullText = ""
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Try to get text directly
            if let pageText = page.string, !pageText.isEmpty {
                fullText += pageText + "\n"
            } else {
                // Use OCR for scanned pages
                let pageImage = try await renderPDFPageToImage(page)
                let ocrText = try await performOCR(on: pageImage)
                fullText += ocrText + "\n"
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseWord(_ data: Data) async throws -> String {
        let parser = WordDocumentParser()
        let type = UTType(filenameExtension: "docx") ?? .data
        return try await parser.parse(data, type: type)
    }
    
    private func parseImage(_ data: Data) async throws -> String {
        #if os(iOS)
        guard let image = UIImage(data: data) else {
            throw DocumentParserError.invalidImageData
        }
        #else
        guard let image = NSImage(data: data) else {
            throw DocumentParserError.invalidImageData
        }
        #endif
        
        return try await performOCR(on: image)
    }
    
    private func renderPDFPageToImage(_ page: PDFPage) async throws -> PlatformImage {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0 // Higher resolution for better OCR
        
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        ))
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: context.format.bounds.size))
            
            context.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        return image
        #else
        let image = NSImage(size: NSSize(width: pageRect.width * scale, height: pageRect.height * scale))
        image.lockFocus()
        
        NSColor.white.setFill()
        NSRect(origin: .zero, size: image.size).fill()
        
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        
        image.unlockFocus()
        return image
        #endif
    }
    
    #if os(iOS)
    private func performOCR(on image: UIImage) async throws -> String {
        try await documentParser.parseImage(image.pngData() ?? Data())
    }
    #else
    private func performOCR(on image: NSImage) async throws -> String {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw DocumentParserError.invalidImageData
        }
        return try await documentParser.parseImage(pngData)
    }
    #endif
    
    // MARK: - Metadata Extraction
    
    private func extractPDFMetadata(_ data: Data) -> ParsedDocumentMetadata {
        guard let document = PDFDocument(data: data) else {
            return ParsedDocumentMetadata(fileSize: data.count)
        }
        
        let attributes = document.documentAttributes ?? [:]
        
        return ParsedDocumentMetadata(
            fileName: nil,
            fileSize: data.count,
            pageCount: document.pageCount,
            author: attributes[PDFDocumentAttribute.authorAttribute] as? String,
            creationDate: attributes[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attributes[PDFDocumentAttribute.modificationDateAttribute] as? Date
        )
    }
    
    private func extractWordMetadata(_ data: Data) -> ParsedDocumentMetadata {
        // Basic metadata for Word documents
        // In a full implementation, would parse document properties
        return ParsedDocumentMetadata(
            fileName: nil,
            fileSize: data.count,
            pageCount: nil
        )
    }
    
    private func calculateConfidence(extractedData: ExtractedData, textLength: Int) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Increase confidence based on extracted entities
        if !extractedData.entities.isEmpty {
            confidence += 0.1
        }
        
        // Increase confidence for vendor information
        if extractedData.entities.contains(where: { $0.type == .vendor }) {
            confidence += 0.15
        }
        
        // Increase confidence for pricing information
        if extractedData.entities.contains(where: { $0.type == .price }) {
            confidence += 0.15
        }
        
        // Increase confidence based on text length (more content = more context)
        if textLength > 500 {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Conversion Helpers
    
    private func convertToEntities(from data: DataExtractorResult) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []
        
        if let vendorName = data.vendorName {
            entities.append(ExtractedEntity(
                type: .vendor,
                value: vendorName,
                confidence: 0.9,
                location: nil
            ))
        }
        
        if let email = data.vendorEmail {
            entities.append(ExtractedEntity(
                type: .email,
                value: email,
                confidence: 0.95,
                location: nil
            ))
        }
        
        if let phone = data.vendorPhone {
            entities.append(ExtractedEntity(
                type: .phone,
                value: phone,
                confidence: 0.9,
                location: nil
            ))
        }
        
        if let address = data.vendorAddress {
            entities.append(ExtractedEntity(
                type: .address,
                value: address,
                confidence: 0.85,
                location: nil
            ))
        }
        
        if let totalPrice = data.totalPrice {
            entities.append(ExtractedEntity(
                type: .price,
                value: "$\(totalPrice)",
                confidence: 0.95,
                location: nil
            ))
        }
        
        if let quoteDate = data.quoteDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            entities.append(ExtractedEntity(
                type: .date,
                value: formatter.string(from: quoteDate),
                confidence: 0.9,
                location: nil
            ))
        }
        
        return entities
    }
    
    private func extractRelationships(from data: DataExtractorResult) -> [ExtractedRelationship] {
        var relationships: [ExtractedRelationship] = []
        
        // Add vendor-price relationship
        if let vendorName = data.vendorName, let totalPrice = data.totalPrice {
            let vendorEntity = ExtractedEntity(type: .vendor, value: vendorName, confidence: 0.9)
            let priceEntity = ExtractedEntity(type: .price, value: "$\(totalPrice)", confidence: 0.95)
            
            relationships.append(ExtractedRelationship(
                from: vendorEntity,
                to: priceEntity,
                type: .pricedAt
            ))
        }
        
        // Add vendor-delivery date relationship
        if let vendorName = data.vendorName, let validUntilDate = data.validUntilDate {
            let vendorEntity = ExtractedEntity(type: .vendor, value: vendorName, confidence: 0.9)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateEntity = ExtractedEntity(type: .date, value: formatter.string(from: validUntilDate), confidence: 0.9)
            
            relationships.append(ExtractedRelationship(
                from: vendorEntity,
                to: dateEntity,
                type: .deliveredOn
            ))
        }
        
        return relationships
    }
}

// MARK: - Type Conversion Extension

// Removed - using DocumentTypeMapping.swift instead

// MARK: - Platform Type Aliases

#if os(iOS)
typealias PlatformImage = UIImage
#else
typealias PlatformImage = NSImage
#endif

// Note: DocumentParserError is already defined in DocumentParser.swift

// MARK: - Supporting Types

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
    
    public init(type: EntityType, value: String, confidence: Double, location: ExtractedLocation? = nil) {
        self.type = type
        self.value = value
        self.confidence = confidence
        self.location = location
    }
}

/// Relationship between entities
public struct ExtractedRelationship: Codable, Equatable {
    public let from: ExtractedEntity
    public let to: ExtractedEntity
    public let type: RelationshipType
    
    public enum RelationshipType: String, Codable {
        case suppliedBy
        case pricedAt
        case deliveredOn
        case referencedIn
        case unknown
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
    public let location: ExtractedLocation?
    
    public init(headers: [String], rows: [[String]], location: ExtractedLocation? = nil) {
        self.headers = headers
        self.rows = rows
        self.location = location
    }
}

/// Location in document
public struct ExtractedLocation: Codable, Equatable {
    public let page: Int
    public let boundingBox: CGRect?
    
    public init(page: Int, boundingBox: CGRect? = nil) {
        self.page = page
        self.boundingBox = boundingBox
    }
}

/// Financial/pricing information
public struct FinancialInfo: Codable, Equatable {
    public let totalPrice: Decimal?
    public let currency: String?
    public let lineItems: [LineItem]
    public let paymentTerms: String?
    public let deliveryTerms: String?
    
    public init(
        totalPrice: Decimal? = nil,
        currency: String? = nil,
        lineItems: [LineItem] = [],
        paymentTerms: String? = nil,
        deliveryTerms: String? = nil
    ) {
        self.totalPrice = totalPrice
        self.currency = currency
        self.lineItems = lineItems
        self.paymentTerms = paymentTerms
        self.deliveryTerms = deliveryTerms
    }
}

// Removed - now using LineItem from DataExtractor.swift
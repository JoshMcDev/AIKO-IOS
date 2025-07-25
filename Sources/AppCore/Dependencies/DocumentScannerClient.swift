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
    public let imageData: Data // Platform-agnostic image representation
    public var thumbnailData: Data?
    public var enhancedImageData: Data?
    public var ocrText: String?
    public var ocrResult: OCRResult?
    public var pageNumber: Int
    public var processingState: ProcessingState

    // Phase 4.1: Quality and Processing Tracking
    public var qualityMetrics: DocumentImageProcessor.QualityMetrics?
    public var enhancementApplied: Bool = false
    public var processingMode: DocumentImageProcessor.ProcessingMode?
    public var processingResult: DocumentImageProcessor.ProcessingResult?

    public init(
        id: UUID = UUID(),
        imageData: Data,
        thumbnailData: Data? = nil,
        enhancedImageData: Data? = nil,
        ocrText: String? = nil,
        ocrResult: OCRResult? = nil,
        pageNumber: Int,
        processingState: ProcessingState = .pending,
        qualityMetrics: DocumentImageProcessor.QualityMetrics? = nil,
        enhancementApplied: Bool = false,
        processingMode: DocumentImageProcessor.ProcessingMode? = nil,
        processingResult: DocumentImageProcessor.ProcessingResult? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.enhancedImageData = enhancedImageData
        self.ocrText = ocrText
        self.ocrResult = ocrResult
        self.pageNumber = pageNumber
        self.processingState = processingState
        self.qualityMetrics = qualityMetrics
        self.enhancementApplied = enhancementApplied
        self.processingMode = processingMode
        self.processingResult = processingResult
    }

    /// Quality score computed from processing result or OCR result
    public var qualityScore: Double? {
        if let result = processingResult {
            return result.qualityMetrics.overallConfidence
        } else if let ocrResult {
            return ocrResult.confidence
        }
        return nil
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
public struct DocumentScannerClient: Sendable {
    /// Initiates the document scanning process
    public var scan: @Sendable () async throws -> ScannedDocument

    /// Enhances a scanned image (contrast, brightness, etc.)
    public var enhanceImage: @Sendable (Data) async throws -> Data

    /// Enhances a scanned image with advanced processing modes and progress callbacks
    public var enhanceImageAdvanced: @Sendable (Data, DocumentImageProcessor.ProcessingMode, DocumentImageProcessor.ProcessingOptions) async throws -> DocumentImageProcessor.ProcessingResult

    /// Performs Optical Character Recognition on image data (legacy)
    public var performOCR: @Sendable (Data) async throws -> String

    /// Performs enhanced OCR with structured results and metadata extraction
    public var performEnhancedOCR: @Sendable (Data) async throws -> OCRResult

    /// Generates a thumbnail from image data
    public var generateThumbnail: @Sendable (Data, CGSize) async throws -> Data

    /// Saves scanned documents to the document pipeline
    public var saveToDocumentPipeline: @Sendable ([ScannedPage]) async throws -> Void

    /// Checks if scanning is available on the current platform
    public var isScanningAvailable: @Sendable () -> Bool = { false }

    /// Estimates processing time for given image and mode
    public var estimateProcessingTime: @Sendable (Data, DocumentImageProcessor.ProcessingMode) async throws -> TimeInterval = { _, _ in 1.0 }

    /// Checks if a processing mode is available
    public var isProcessingModeAvailable: @Sendable (DocumentImageProcessor.ProcessingMode) -> Bool = { _ in false }

    /// Checks camera permissions for document scanning
    public var checkCameraPermissions: @Sendable () async -> Bool = { false }
}

// MARK: - Dependency Registration

public extension DocumentScannerClient {
    static let liveValue: Self = .init(
        scan: {
            ScannedDocument(
                pages: [
                    ScannedPage(
                        imageData: Data(),
                        pageNumber: 1
                    ),
                ],
                title: "Live Document"
            )
        },
        enhanceImage: { data in data },
        enhanceImageAdvanced: { data, _, _ in
            DocumentImageProcessor.ProcessingResult(
                processedImageData: data,
                qualityMetrics: DocumentImageProcessor.QualityMetrics(
                    overallConfidence: 0.85,
                    sharpnessScore: 0.8,
                    contrastScore: 0.9,
                    noiseLevel: 0.2,
                    textClarity: 0.85,
                    recommendedForOCR: true
                ),
                processingTime: 0.1,
                appliedFilters: ["live"]
            )
        },
        performOCR: { _ in "Live OCR Text" },
        performEnhancedOCR: { _ in
            OCRResult(
                fullText: "Live OCR Text",
                confidence: 0.85,
                recognizedFields: [],
                documentStructure: DocumentStructure(),
                extractedMetadata: ExtractedMetadata(),
                processingTime: 0.1
            )
        },
        generateThumbnail: { data, _ in data },
        saveToDocumentPipeline: { _ in }
    )

    static let testValue: Self = .init(
        scan: {
            ScannedDocument(
                pages: [
                    ScannedPage(
                        imageData: Data(),
                        pageNumber: 1
                    ),
                ],
                title: "Test Document"
            )
        },
        enhanceImage: { data in data },
        enhanceImageAdvanced: { data, _, _ in
            DocumentImageProcessor.ProcessingResult(
                processedImageData: data,
                qualityMetrics: DocumentImageProcessor.QualityMetrics(
                    overallConfidence: 0.85,
                    sharpnessScore: 0.8,
                    contrastScore: 0.9,
                    noiseLevel: 0.2,
                    textClarity: 0.85,
                    recommendedForOCR: true
                ),
                processingTime: 0.1,
                appliedFilters: ["test"]
            )
        },
        performOCR: { _ in "Test OCR Text" },
        performEnhancedOCR: { _ in
            OCRResult(
                fullText: "Test OCR Text",
                confidence: 0.85,
                recognizedFields: [
                    DocumentFormField(
                        label: "Test Field",
                        value: "Test Value",
                        confidence: 0.9,
                        boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20),
                        fieldType: .text
                    ),
                ],
                documentStructure: DocumentStructure(
                    paragraphs: [
                        TextRegion(
                            text: "Test paragraph",
                            boundingBox: CGRect(x: 0, y: 0, width: 200, height: 40),
                            confidence: 0.85,
                            textType: .body
                        ),
                    ],
                    layout: .document
                ),
                extractedMetadata: ExtractedMetadata(),
                processingTime: 0.1
            )
        },
        generateThumbnail: { data, _ in data },
        saveToDocumentPipeline: { _ in },
        isScanningAvailable: { true },
        estimateProcessingTime: { _, _ in 1.0 },
        isProcessingModeAvailable: { _ in true },
        checkCameraPermissions: { true }
    )
}

// MARK: - OCR Enhancement Types

/// Structured OCR result with confidence scoring and document analysis
public struct OCRResult: Equatable, Sendable {
    public let fullText: String
    public let confidence: Double // Overall OCR confidence 0.0 to 1.0
    public let recognizedFields: [DocumentFormField]
    public let documentStructure: DocumentStructure
    public let extractedMetadata: ExtractedMetadata
    public let processingTime: TimeInterval

    public init(
        fullText: String,
        confidence: Double,
        recognizedFields: [DocumentFormField] = [],
        documentStructure: DocumentStructure = DocumentStructure(),
        extractedMetadata: ExtractedMetadata = ExtractedMetadata(),
        processingTime: TimeInterval = 0
    ) {
        self.fullText = fullText
        self.confidence = confidence
        self.recognizedFields = recognizedFields
        self.documentStructure = documentStructure
        self.extractedMetadata = extractedMetadata
        self.processingTime = processingTime
    }
}

/// Detected form field with position and confidence (from document scanning)
public struct DocumentFormField: Equatable, Sendable {
    public let label: String
    public let value: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let fieldType: FieldType

    public init(
        label: String,
        value: String,
        confidence: Double,
        boundingBox: CGRect,
        fieldType: FieldType = .text
    ) {
        self.label = label
        self.value = value
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.fieldType = fieldType
    }

    public enum FieldType: String, CaseIterable, Sendable {
        case text
        case number
        case date
        case currency
        case email
        case phone
        case address
        case checkbox
        case signature
    }
}

/// Document structure analysis
public struct DocumentStructure: Equatable, Sendable {
    public let paragraphs: [TextRegion]
    public let tables: [Table]
    public let lists: [List]
    public let headers: [TextRegion]
    public let layout: LayoutType

    public init(
        paragraphs: [TextRegion] = [],
        tables: [Table] = [],
        lists: [List] = [],
        headers: [TextRegion] = [],
        layout: LayoutType = .document
    ) {
        self.paragraphs = paragraphs
        self.tables = tables
        self.lists = lists
        self.headers = headers
        self.layout = layout
    }

    public enum LayoutType: String, CaseIterable, Sendable {
        case document
        case form
        case table
        case receipt
        case invoice
        case letter
        case unknown
    }
}

/// Text region with position and confidence
public struct TextRegion: Equatable, Sendable {
    public let text: String
    public let boundingBox: CGRect
    public let confidence: Double
    public let textType: TextType

    public init(
        text: String,
        boundingBox: CGRect,
        confidence: Double,
        textType: TextType = .body
    ) {
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.textType = textType
    }

    public enum TextType: String, CaseIterable, Sendable {
        case title
        case header
        case body
        case footer
        case caption
    }
}

/// Table structure with cells
public struct Table: Equatable, Sendable {
    public let rows: [[TableCell]]
    public let boundingBox: CGRect
    public let confidence: Double

    public init(
        rows: [[TableCell]],
        boundingBox: CGRect,
        confidence: Double
    ) {
        self.rows = rows
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

/// Table cell with content
public struct TableCell: Equatable, Sendable {
    public let content: String
    public let boundingBox: CGRect
    public let confidence: Double
    public let isHeader: Bool

    public init(
        content: String,
        boundingBox: CGRect,
        confidence: Double,
        isHeader: Bool = false
    ) {
        self.content = content
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.isHeader = isHeader
    }
}

/// List structure
public struct List: Equatable, Sendable {
    public let items: [ListItem]
    public let boundingBox: CGRect
    public let listType: ListType

    public init(
        items: [ListItem],
        boundingBox: CGRect,
        listType: ListType = .unordered
    ) {
        self.items = items
        self.boundingBox = boundingBox
        self.listType = listType
    }

    public enum ListType: String, CaseIterable, Sendable {
        case ordered
        case unordered
    }
}

/// List item
public struct ListItem: Equatable, Sendable {
    public let text: String
    public let boundingBox: CGRect
    public let confidence: Double
    public let level: Int // Indentation level

    public init(
        text: String,
        boundingBox: CGRect,
        confidence: Double,
        level: Int = 0
    ) {
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.level = level
    }
}

/// Extracted metadata from OCR
public struct ExtractedMetadata: Equatable, Sendable {
    public let dates: [ExtractedDate]
    public let numbers: [ExtractedNumber]
    public let addresses: [ExtractedAddress]
    public let phoneNumbers: [String]
    public let emailAddresses: [String]
    public let urls: [String]
    public let currencies: [ExtractedCurrency]

    public init(
        dates: [ExtractedDate] = [],
        numbers: [ExtractedNumber] = [],
        addresses: [ExtractedAddress] = [],
        phoneNumbers: [String] = [],
        emailAddresses: [String] = [],
        urls: [String] = [],
        currencies: [ExtractedCurrency] = []
    ) {
        self.dates = dates
        self.numbers = numbers
        self.addresses = addresses
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
        self.urls = urls
        self.currencies = currencies
    }
}

/// Extracted date with context
public struct ExtractedDate: Equatable, Sendable {
    public let date: Date
    public let originalText: String
    public let confidence: Double
    public let context: String? // Surrounding text for context

    public init(
        date: Date,
        originalText: String,
        confidence: Double,
        context: String? = nil
    ) {
        self.date = date
        self.originalText = originalText
        self.confidence = confidence
        self.context = context
    }
}

/// Extracted number with type
public struct ExtractedNumber: Equatable, Sendable {
    public let value: Double
    public let originalText: String
    public let numberType: NumberType
    public let confidence: Double

    public init(
        value: Double,
        originalText: String,
        numberType: NumberType,
        confidence: Double
    ) {
        self.value = value
        self.originalText = originalText
        self.numberType = numberType
        self.confidence = confidence
    }

    public enum NumberType: String, CaseIterable, Sendable {
        case integer
        case decimal
        case percentage
        case identifier // Like ID numbers
    }
}

/// Extracted address
public struct ExtractedAddress: Equatable, Sendable {
    public let fullAddress: String
    public let components: AddressComponents
    public let confidence: Double

    public init(
        fullAddress: String,
        components: AddressComponents = AddressComponents(),
        confidence: Double
    ) {
        self.fullAddress = fullAddress
        self.components = components
        self.confidence = confidence
    }
}

/// Address components
public struct AddressComponents: Equatable, Sendable {
    public let street: String?
    public let city: String?
    public let state: String?
    public let zipCode: String?
    public let country: String?

    public init(
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        country: String? = nil
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
}

/// Extracted currency value
public struct ExtractedCurrency: Equatable, Sendable {
    public let amount: Decimal
    public let currency: String // Currency code like "USD"
    public let originalText: String
    public let confidence: Double

    public init(
        amount: Decimal,
        currency: String,
        originalText: String,
        confidence: Double
    ) {
        self.amount = amount
        self.currency = currency
        self.originalText = originalText
        self.confidence = confidence
    }
}

// MARK: - Processing Types

// MARK: - Additional Processing Types for Document Scanner Context

/// Enhanced document type classification for scanner context
public enum ScannerDocumentType: String, CaseIterable, Equatable, Sendable, Codable {
    case contract = "Contract"
    case solicitation = "Solicitation"
    case amendment = "Amendment"
    case invoice = "Invoice"
    case receipt = "Receipt"
    case specification = "Specification"
    case statement = "Statement of Work"
    case evaluation = "Evaluation"
    case correspondence = "Correspondence"
    case certification = "Certification"
    case unknown = "Unknown"

    public var displayName: String {
        rawValue
    }

    public var category: DocumentCategory {
        switch self {
        case .contract, .amendment:
            .award
        case .solicitation:
            .solicitation
        case .invoice, .receipt:
            .financial
        case .specification, .statement:
            .technical
        case .evaluation:
            .evaluation
        case .correspondence, .certification:
            .administrative
        case .unknown:
            .unknown
        }
    }

    public enum DocumentCategory: String, CaseIterable, Sendable {
        case planning = "Planning"
        case solicitation = "Solicitation"
        case award = "Award"
        case technical = "Technical"
        case financial = "Financial"
        case evaluation = "Evaluation"
        case administrative = "Administrative"
        case unknown = "Unknown"
    }
}

// MARK: - Document Context Extraction Types

/// Scanner-specific document context extracted through advanced analysis
public struct ScannerDocumentContext: Equatable, Sendable {
    public let documentType: ScannerDocumentType
    public let extractedEntities: [DocumentEntity]
    public let relationships: [EntityRelationship]
    public let compliance: ComplianceAnalysis
    public let riskFactors: [RiskFactor]
    public let recommendations: [Recommendation]
    public let confidence: Double
    public let processingTime: TimeInterval

    public init(
        documentType: ScannerDocumentType = .unknown,
        extractedEntities: [DocumentEntity] = [],
        relationships: [EntityRelationship] = [],
        compliance: ComplianceAnalysis = ComplianceAnalysis(),
        riskFactors: [RiskFactor] = [],
        recommendations: [Recommendation] = [],
        confidence: Double = 0.0,
        processingTime: TimeInterval = 0
    ) {
        self.documentType = documentType
        self.extractedEntities = extractedEntities
        self.relationships = relationships
        self.compliance = compliance
        self.riskFactors = riskFactors
        self.recommendations = recommendations
        self.confidence = confidence
        self.processingTime = processingTime
    }
}

/// Document entity extracted from context analysis
public struct DocumentEntity: Equatable, Sendable {
    public let id: String
    public let type: EntityType
    public let value: String
    public let confidence: Double
    public let sourceLocation: CGRect?
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        type: EntityType,
        value: String,
        confidence: Double,
        sourceLocation: CGRect? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.confidence = confidence
        self.sourceLocation = sourceLocation
        self.metadata = metadata
    }

    public enum EntityType: String, CaseIterable, Sendable {
        case vendor = "Vendor"
        case contract = "Contract"
        case amount = "Amount"
        case date = "Date"
        case requirement = "Requirement"
        case clause = "Clause"
        case specification = "Specification"
        case deliverable = "Deliverable"
        case contact = "Contact"
        case location = "Location"
        case certification = "Certification"
        case other = "Other"
    }
}

/// Relationship between document entities
public struct EntityRelationship: Equatable, Sendable {
    public let id: String
    public let fromEntityId: String
    public let toEntityId: String
    public let relationshipType: RelationshipType
    public let confidence: Double

    public init(
        id: String = UUID().uuidString,
        fromEntityId: String,
        toEntityId: String,
        relationshipType: RelationshipType,
        confidence: Double
    ) {
        self.id = id
        self.fromEntityId = fromEntityId
        self.toEntityId = toEntityId
        self.relationshipType = relationshipType
        self.confidence = confidence
    }

    public enum RelationshipType: String, CaseIterable, Sendable {
        case contractedBy = "Contracted By"
        case requirementFor = "Requirement For"
        case deliveredBy = "Delivered By"
        case dependsOn = "Depends On"
        case governs = "Governs"
        case references = "References"
        case modifies = "Modifies"
        case supersedes = "Supersedes"
        case other = "Other"
    }
}

/// Compliance analysis for documents
public struct ComplianceAnalysis: Equatable, Sendable {
    public let overallCompliance: ComplianceLevel
    public let farCompliance: RegulationCompliance
    public let dfarsCompliance: RegulationCompliance
    public let agencyCompliance: RegulationCompliance
    public let identifiedIssues: [ComplianceIssue]
    public let recommendations: [ComplianceRecommendation]

    public init(
        overallCompliance: ComplianceLevel = .unknown,
        farCompliance: RegulationCompliance = RegulationCompliance(),
        dfarsCompliance: RegulationCompliance = RegulationCompliance(),
        agencyCompliance: RegulationCompliance = RegulationCompliance(),
        identifiedIssues: [ComplianceIssue] = [],
        recommendations: [ComplianceRecommendation] = []
    ) {
        self.overallCompliance = overallCompliance
        self.farCompliance = farCompliance
        self.dfarsCompliance = dfarsCompliance
        self.agencyCompliance = agencyCompliance
        self.identifiedIssues = identifiedIssues
        self.recommendations = recommendations
    }

    public enum ComplianceLevel: String, CaseIterable, Sendable {
        case compliant = "Compliant"
        case partiallyCompliant = "Partially Compliant"
        case nonCompliant = "Non-Compliant"
        case unknown = "Unknown"
        case notApplicable = "Not Applicable"
    }
}

/// Regulation-specific compliance information
public struct RegulationCompliance: Equatable, Sendable {
    public let regulation: String
    public let compliance: ComplianceAnalysis.ComplianceLevel
    public let applicableClauses: [String]
    public let missingClauses: [String]
    public let conflictingClauses: [String]
    public let confidence: Double

    public init(
        regulation: String = "",
        compliance: ComplianceAnalysis.ComplianceLevel = .unknown,
        applicableClauses: [String] = [],
        missingClauses: [String] = [],
        conflictingClauses: [String] = [],
        confidence: Double = 0.0
    ) {
        self.regulation = regulation
        self.compliance = compliance
        self.applicableClauses = applicableClauses
        self.missingClauses = missingClauses
        self.conflictingClauses = conflictingClauses
        self.confidence = confidence
    }
}

/// Compliance issue identified in analysis
public struct ComplianceIssue: Equatable, Sendable {
    public let id: String
    public let severity: Severity
    public let category: Category
    public let description: String
    public let regulation: String
    public let clause: String?
    public let recommendation: String?

    public init(
        id: String = UUID().uuidString,
        severity: Severity,
        category: Category,
        description: String,
        regulation: String,
        clause: String? = nil,
        recommendation: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.category = category
        self.description = description
        self.regulation = regulation
        self.clause = clause
        self.recommendation = recommendation
    }

    public enum Severity: String, CaseIterable, Sendable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case informational = "Informational"
    }

    public enum Category: String, CaseIterable, Sendable {
        case clause = "Missing Clause"
        case format = "Format Issue"
        case content = "Content Issue"
        case procedure = "Procedure Violation"
        case documentation = "Documentation Issue"
        case other = "Other"
    }
}

/// Compliance recommendation
public struct ComplianceRecommendation: Equatable, Sendable {
    public let id: String
    public let priority: Priority
    public let action: String
    public let rationale: String
    public let regulation: String
    public let estimatedImpact: Impact

    public init(
        id: String = UUID().uuidString,
        priority: Priority,
        action: String,
        rationale: String,
        regulation: String,
        estimatedImpact: Impact
    ) {
        self.id = id
        self.priority = priority
        self.action = action
        self.rationale = rationale
        self.regulation = regulation
        self.estimatedImpact = estimatedImpact
    }

    public enum Priority: String, CaseIterable, Sendable {
        case immediate = "Immediate"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case optional = "Optional"
    }

    public enum Impact: String, CaseIterable, Sendable {
        case high = "High Impact"
        case medium = "Medium Impact"
        case low = "Low Impact"
        case minimal = "Minimal Impact"
    }
}

/// Risk factor identified in document analysis
public struct RiskFactor: Equatable, Sendable {
    public let id: String
    public let type: RiskType
    public let severity: RiskSeverity
    public let description: String
    public let mitigation: String?
    public let probability: Double // 0.0 to 1.0
    public let impact: Double // 0.0 to 1.0

    public init(
        id: String = UUID().uuidString,
        type: RiskType,
        severity: RiskSeverity,
        description: String,
        mitigation: String? = nil,
        probability: Double = 0.5,
        impact: Double = 0.5
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.description = description
        self.mitigation = mitigation
        self.probability = probability
        self.impact = impact
    }

    public enum RiskType: String, CaseIterable, Sendable {
        case financial = "Financial"
        case schedule = "Schedule"
        case performance = "Performance"
        case compliance = "Compliance"
        case technical = "Technical"
        case operational = "Operational"
        case legal = "Legal"
        case reputation = "Reputation"
        case other = "Other"
    }

    public enum RiskSeverity: String, CaseIterable, Sendable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case negligible = "Negligible"
    }

    /// Calculated risk score based on probability and impact
    public var riskScore: Double {
        probability * impact
    }
}

/// General recommendation from document analysis
public struct Recommendation: Equatable, Sendable {
    public let id: String
    public let type: RecommendationType
    public let priority: Priority
    public let title: String
    public let description: String
    public let action: String
    public let rationale: String
    public let estimatedEffort: EstimatedEffort

    public init(
        id: String = UUID().uuidString,
        type: RecommendationType,
        priority: Priority,
        title: String,
        description: String,
        action: String,
        rationale: String,
        estimatedEffort: EstimatedEffort = .medium
    ) {
        self.id = id
        self.type = type
        self.priority = priority
        self.title = title
        self.description = description
        self.action = action
        self.rationale = rationale
        self.estimatedEffort = estimatedEffort
    }

    public enum RecommendationType: String, CaseIterable, Sendable {
        case process = "Process Improvement"
        case compliance = "Compliance Enhancement"
        case efficiency = "Efficiency Gain"
        case riskMitigation = "Risk Mitigation"
        case costSaving = "Cost Saving"
        case qualityImprovement = "Quality Improvement"
        case documentation = "Documentation"
        case automation = "Automation Opportunity"
        case other = "Other"
    }

    public enum Priority: String, CaseIterable, Sendable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case optional = "Optional"
    }

    public enum EstimatedEffort: String, CaseIterable, Sendable {
        case minimal = "Minimal (< 1 hour)"
        case low = "Low (1-4 hours)"
        case medium = "Medium (1-2 days)"
        case high = "High (3-5 days)"
        case extensive = "Extensive (> 1 week)"
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
            "Document scanning is not available on this device"
        case .userCancelled:
            "Scanning was cancelled"
        case .invalidImageData:
            "The image data is invalid or corrupted"
        case .enhancementFailed:
            "Failed to enhance the image"
        case let .ocrFailed(reason):
            "Text recognition failed: \(reason)"
        case let .saveFailed(reason):
            "Failed to save document: \(reason)"
        case let .unknownError(message):
            message
        }
    }
}

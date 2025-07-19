import Foundation
import AppCore

// MARK: - Form Types

/// Government form types supported by the application
public enum FormType: String, CaseIterable, Identifiable, Codable {
    case sf18 = "SF18"
    case sf1449 = "SF1449"
    case sf30 = "SF30"
    case sf26 = "SF26"
    case sf36 = "SF36"
    case sf44 = "SF44"
    case sf252 = "SF252"
    case sf1408 = "SF1408"

    public var id: String { rawValue }

    public var fullName: String {
        switch self {
        case .sf18: "Standard Form 18 - Request for Quotations"
        case .sf1449: "Standard Form 1449 - Solicitation/Contract/Order"
        case .sf30: "Standard Form 30 - Amendment of Solicitation/Modification"
        case .sf26: "Standard Form 26 - Award/Contract"
        case .sf36: "Standard Form 36 - Continuation Sheet"
        case .sf44: "Standard Form 44 - Purchase Order-Invoice-Voucher"
        case .sf252: "Standard Form 252 - Architect-Engineer Contract"
        case .sf1408: "Standard Form 1408 - Pre-Award Survey"
        }
    }

    public var shortName: String {
        switch self {
        case .sf18: "SF 18"
        case .sf1449: "SF 1449"
        case .sf30: "SF 30"
        case .sf26: "SF 26"
        case .sf36: "SF 36"
        case .sf44: "SF 44"
        case .sf252: "SF 252"
        case .sf1408: "SF 1408"
        }
    }

    public var description: String {
        switch self {
        case .sf18: "Used for simplified acquisitions to request quotations from vendors"
        case .sf1449: "Multi-purpose form for commercial product and service acquisitions"
        case .sf30: "Used to amend solicitations or modify existing contracts"
        case .sf26: "Award document for negotiated procurements"
        case .sf36: "Continuation sheet for any standard form needing additional space"
        case .sf44: "Simplified purchase order for micro-purchases under $10,000"
        case .sf252: "Standard contract form for architect-engineer services"
        case .sf1408: "Survey to determine prospective contractor responsibility"
        }
    }

    public var icon: String {
        switch self {
        case .sf18: "doc.badge.plus"
        case .sf1449: "doc.on.doc"
        case .sf30: "doc.badge.arrow.up"
        case .sf26: "checkmark.seal"
        case .sf36: "doc.append"
        case .sf44: "cart"
        case .sf252: "building.2"
        case .sf1408: "magnifyingglass.circle"
        }
    }
}

// MARK: - Form Definition

/// Complete definition of a government form including metadata and requirements
public struct FormDefinition: Identifiable, Codable {
    public let formType: FormType
    public let formNumber: String
    public let title: String
    public let revision: String
    public let agency: String
    public let description: String
    public let supportedTemplates: [DocumentType]
    public let requiredFields: [String]
    public let farReference: String
    public let downloadURL: URL?
    public let threshold: Double?

    public var id: String { formType.rawValue }
}

// MARK: - Template Data

/// Data structure for template information to be mapped to forms
public struct TemplateData: Codable {
    public let documentType: DocumentType
    public let data: [String: Any]
    public let metadata: TemplateMetadata?

    // Custom Codable implementation for [String: Any]
    private enum CodingKeys: String, CodingKey {
        case documentType, data, metadata
    }

    public init(documentType: DocumentType, data: [String: Any], metadata: TemplateMetadata? = nil) {
        self.documentType = documentType
        self.data = data
        self.metadata = metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documentType = try container.decode(DocumentType.self, forKey: .documentType)
        metadata = try container.decodeIfPresent(TemplateMetadata.self, forKey: .metadata)

        // Decode [String: Any] using JSONSerialization
        if let dataDict = try? container.decode([String: JSONValue].self, forKey: .data) {
            data = dataDict.mapValues { $0.value }
        } else {
            data = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(documentType, forKey: .documentType)
        try container.encodeIfPresent(metadata, forKey: .metadata)

        // Encode [String: Any] using JSONValue wrapper
        let jsonData = data.compactMapValues { JSONValue(value: $0) }
        try container.encode(jsonData, forKey: .data)
    }
}

/// Metadata for template information
public struct TemplateMetadata: Codable {
    public let templateId: String
    public let version: String
    public let createdDate: Date
    public let lastModified: Date
    public let author: String?

    public init(templateId: String, version: String, createdDate: Date = Date(), lastModified: Date = Date(), author: String? = nil) {
        self.templateId = templateId
        self.version = version
        self.createdDate = createdDate
        self.lastModified = lastModified
        self.author = author
    }
}

// MARK: - Form Selection

/// Model for form selection in the UI
public struct FormSelection: Identifiable {
    public let id = UUID()
    public let formType: FormType
    public let isRecommended: Bool
    public let complianceScore: Double
    public let notes: String?

    public init(formType: FormType, isRecommended: Bool = false, complianceScore: Double = 1.0, notes: String? = nil) {
        self.formType = formType
        self.isRecommended = isRecommended
        self.complianceScore = complianceScore
        self.notes = notes
    }
}

// MARK: - Form Output Options

/// Options for form output generation
public struct FormOutputOptions: Codable {
    public var format: OutputFormat
    public var includeInstructions: Bool
    public var includeAttachments: Bool
    public var digitalSignature: Bool

    public init(
        format: OutputFormat = .pdf,
        includeInstructions: Bool = false,
        includeAttachments: Bool = true,
        digitalSignature: Bool = false
    ) {
        self.format = format
        self.includeInstructions = includeInstructions
        self.includeAttachments = includeAttachments
        self.digitalSignature = digitalSignature
    }

    public enum OutputFormat: String, CaseIterable, Codable {
        case pdf = "PDF"
        case docx = "DOCX"
        case fillablePDF = "Fillable PDF"
        case xml = "XML"
    }
}

// MARK: - Helper Types

/// JSON value wrapper for Codable support of [String: Any]
private enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init?(value: Any) {
        switch value {
        case let string as String:
            self = .string(string)
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
        case let bool as Bool:
            self = .bool(bool)
        case let dict as [String: Any]:
            var object: [String: JSONValue] = [:]
            for (key, value) in dict {
                if let jsonValue = JSONValue(value: value) {
                    object[key] = jsonValue
                }
            }
            self = .object(object)
        case let array as [Any]:
            self = .array(array.compactMap { JSONValue(value: $0) })
        case is NSNull:
            self = .null
        default:
            return nil
        }
    }

    var value: Any {
        switch self {
        case let .string(string): string
        case let .int(int): int
        case let .double(double): double
        case let .bool(bool): bool
        case let .object(object): object.mapValues { $0.value }
        case let .array(array): array.map(\.value)
        case .null: NSNull()
        }
    }
}

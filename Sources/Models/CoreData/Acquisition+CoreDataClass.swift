import CoreData
import Foundation

@objc(Acquisition)
public class Acquisition: NSManagedObject {
    override public func awakeFromInsert() {
        super.awakeFromInsert()

        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdDate")
        setPrimitiveValue(Date(), forKey: "lastModifiedDate")
        setPrimitiveValue("draft", forKey: "status")
    }

    public var documentsArray: [AcquisitionDocument] {
        let set = documents as? Set<AcquisitionDocument> ?? []
        return set.sorted(by: { $0.createdDate ?? Date() < $1.createdDate ?? Date() })
    }

    public var uploadedFilesArray: [UploadedFile] {
        let set = uploadedFiles as? Set<UploadedFile> ?? []
        return set.sorted(by: { $0.uploadDate ?? Date() < $1.uploadDate ?? Date() })
    }

    public var generatedFilesArray: [GeneratedFile] {
        let set = generatedFiles as? Set<GeneratedFile> ?? []
        return set.sorted(by: { $0.createdDate ?? Date() < $1.createdDate ?? Date() })
    }
}

// MARK: - Acquisition Status

public extension Acquisition {
    enum Status: String, CaseIterable {
        case draft
        case inProgress = "in_progress"
        case underReview = "under_review"
        case approved
        case awarded
        case cancelled
        case archived

        public var displayName: String {
            switch self {
            case .draft: "Draft"
            case .inProgress: "In Progress"
            case .underReview: "Under Review"
            case .approved: "Approved"
            case .awarded: "Awarded"
            case .cancelled: "Cancelled"
            case .archived: "Archived"
            }
        }

        public var icon: String {
            switch self {
            case .draft: "pencil.circle"
            case .inProgress: "arrow.right.circle"
            case .underReview: "magnifyingglass.circle"
            case .approved: "checkmark.circle"
            case .awarded: "rosette"
            case .cancelled: "xmark.circle"
            case .archived: "archivebox"
            }
        }

        public var color: String {
            switch self {
            case .draft: "gray"
            case .inProgress: "blue"
            case .underReview: "orange"
            case .approved: "green"
            case .awarded: "purple"
            case .cancelled: "red"
            case .archived: "secondary"
            }
        }
    }

    var statusEnum: Status {
        get {
            Status(rawValue: status ?? "draft") ?? .draft
        }
        set {
            status = newValue.rawValue
        }
    }
}

// MARK: - Document Chain Metadata

public extension Acquisition {
    /// Store document chain metadata as JSON data
    func setDocumentChain(_ chain: [String: Any]) throws {
        documentChainMetadata = try JSONSerialization.data(withJSONObject: chain, options: .prettyPrinted)
        lastModifiedDate = Date()
    }

    /// Retrieve document chain metadata from JSON data
    func getDocumentChain() -> [String: Any]? {
        guard let data = documentChainMetadata else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }

    /// Store codable document chain data
    func setDocumentChainCodable(_ chain: some Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        documentChainMetadata = try encoder.encode(chain)
        lastModifiedDate = Date()
    }

    /// Retrieve codable document chain data
    func getDocumentChainCodable<T: Decodable>(_ type: T.Type) throws -> T? {
        guard let data = documentChainMetadata else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

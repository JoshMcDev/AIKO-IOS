import Foundation
import CoreData

@objc(Acquisition)
public class Acquisition: NSManagedObject {
    
    public override func awakeFromInsert() {
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
extension Acquisition {
    public enum Status: String, CaseIterable {
        case draft = "draft"
        case inProgress = "in_progress"
        case underReview = "under_review"
        case approved = "approved"
        case awarded = "awarded"
        case cancelled = "cancelled"
        case archived = "archived"
        
        public var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .inProgress: return "In Progress"
            case .underReview: return "Under Review"
            case .approved: return "Approved"
            case .awarded: return "Awarded"
            case .cancelled: return "Cancelled"
            case .archived: return "Archived"
            }
        }
        
        public var icon: String {
            switch self {
            case .draft: return "pencil.circle"
            case .inProgress: return "arrow.right.circle"
            case .underReview: return "magnifyingglass.circle"
            case .approved: return "checkmark.circle"
            case .awarded: return "rosette"
            case .cancelled: return "xmark.circle"
            case .archived: return "archivebox"
            }
        }
        
        public var color: String {
            switch self {
            case .draft: return "gray"
            case .inProgress: return "blue"
            case .underReview: return "orange"
            case .approved: return "green"
            case .awarded: return "purple"
            case .cancelled: return "red"
            case .archived: return "secondary"
            }
        }
    }
    
    public var statusEnum: Status {
        get {
            Status(rawValue: status ?? "draft") ?? .draft
        }
        set {
            status = newValue.rawValue
        }
    }
}

// MARK: - Document Chain Metadata
extension Acquisition {
    /// Store document chain metadata as JSON data
    public func setDocumentChain(_ chain: [String: Any]) throws {
        self.documentChainMetadata = try JSONSerialization.data(withJSONObject: chain, options: .prettyPrinted)
        self.lastModifiedDate = Date()
    }
    
    /// Retrieve document chain metadata from JSON data
    public func getDocumentChain() -> [String: Any]? {
        guard let data = documentChainMetadata else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
    
    /// Store codable document chain data
    public func setDocumentChainCodable<T: Encodable>(_ chain: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        self.documentChainMetadata = try encoder.encode(chain)
        self.lastModifiedDate = Date()
    }
    
    /// Retrieve codable document chain data
    public func getDocumentChainCodable<T: Decodable>(_ type: T.Type) throws -> T? {
        guard let data = documentChainMetadata else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}
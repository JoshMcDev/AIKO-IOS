import Foundation
import CoreData

@objc(GovernmentFormData)
public class GovernmentFormData: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Create a new GovernmentFormData instance
    static func create(
        formType: String,
        formNumber: String,
        revision: String?,
        formData: Data,
        in context: NSManagedObjectContext
    ) -> GovernmentFormData {
        let formDataEntity = GovernmentFormData(context: context)
        formDataEntity.id = UUID()
        formDataEntity.formType = formType
        formDataEntity.formNumber = formNumber
        formDataEntity.revision = revision
        formDataEntity.formData = formData
        formDataEntity.createdDate = Date()
        formDataEntity.lastModifiedDate = Date()
        formDataEntity.status = "draft"
        return formDataEntity
    }
    
    /// Update the form data
    func updateFormData(_ data: Data) {
        self.formData = data
        self.lastModifiedDate = Date()
    }
    
    /// Update the status
    func updateStatus(_ status: String) {
        self.status = status
        self.lastModifiedDate = Date()
    }
    
    /// Decode the form data to a specific form type
    func decodeForm<T: Decodable>(_ type: T.Type) throws -> T {
        guard let data = formData else {
            throw NSError(domain: "GovernmentFormData", code: 1, userInfo: [NSLocalizedDescriptionKey: "No form data available"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
    
    /// Encode a form to data
    static func encodeForm<T: Encodable>(_ form: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(form)
    }
}

// MARK: - Form Type Constants
extension GovernmentFormData {
    struct FormType {
        static let sf1449 = "SF1449"
        static let sf33 = "SF33"
        static let sf30 = "SF30"
        static let sf18 = "SF18"
        static let sf26 = "SF26"
        static let sf44 = "SF44"
        static let dd1155 = "DD1155"
    }
}

// MARK: - Status Constants
extension GovernmentFormData {
    struct Status {
        static let draft = "draft"
        static let submitted = "submitted"
        static let approved = "approved"
        static let rejected = "rejected"
        static let completed = "completed"
        static let cancelled = "cancelled"
    }
}
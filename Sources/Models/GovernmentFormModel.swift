import AppCore
import Foundation

// MARK: - Government Form Model

/// Sendable domain model representing government form data
public struct GovernmentFormModel: Identifiable, Codable, Sendable {
    public let id: UUID
    public let formType: String
    public let formNumber: String
    public let revision: String?
    public let formData: Data
    public let status: String
    public let acquisitionId: UUID?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        formType: String,
        formNumber: String,
        revision: String? = nil,
        formData: Data,
        status: String = "draft",
        acquisitionId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.formType = formType
        self.formNumber = formNumber
        self.revision = revision
        self.formData = formData
        self.status = status
        self.acquisitionId = acquisitionId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Extensions

public extension GovernmentFormModel {
    /// Get the form data as a JSON object
    var formDataAsJSON: [String: Any]? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: formData) as? [String: Any] else {
            return nil
        }
        return jsonObject
    }

    /// Get fields from the form data
    var fields: [String: String] {
        guard let jsonObject = formDataAsJSON,
              let fields = jsonObject["fields"] as? [String: String]
        else {
            return [:]
        }
        return fields
    }

    /// Get metadata from the form data
    var metadata: FormMetadata? {
        guard let jsonObject = formDataAsJSON,
              let metadataDict = jsonObject["metadata"] as? [String: Any]
        else {
            return nil
        }

        return FormMetadata(
            createdBy: metadataDict["createdBy"] as? String ?? "",
            createdDate: Date(), // Would parse from stored data in real implementation
            agency: metadataDict["agency"] as? String ?? "",
            purpose: metadataDict["purpose"] as? String ?? "",
            authority: metadataDict["authority"] as? String
        )
    }
}

// MARK: - Core Data Conversion

extension GovernmentFormModel {
    /// Create from Core Data entity
    init?(from entity: GovernmentFormData) {
        guard let id = entity.id,
              let formType = entity.formType,
              let formNumber = entity.formNumber,
              let formData = entity.formData,
              let status = entity.status,
              let createdDate = entity.createdDate,
              let lastModifiedDate = entity.lastModifiedDate
        else {
            return nil
        }

        self.init(
            id: id,
            formType: formType,
            formNumber: formNumber,
            revision: entity.revision,
            formData: formData,
            status: status,
            acquisitionId: entity.acquisition?.id,
            createdAt: createdDate,
            updatedAt: lastModifiedDate
        )
    }

    /// Update Core Data entity from model
    func updateEntity(_ entity: GovernmentFormData) {
        entity.formType = formType
        entity.formNumber = formNumber
        entity.revision = revision
        entity.formData = formData
        entity.status = status
        entity.lastModifiedDate = updatedAt
    }
}

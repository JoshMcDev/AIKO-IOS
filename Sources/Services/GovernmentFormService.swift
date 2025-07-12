import Foundation
import CoreData

/// Service for managing government forms in the system
public final class GovernmentFormService: DomainService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private let formFactory = FormFactoryRegistry.shared
    
    // MARK: - Initialization
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Form Creation
    
    /// Create a new form for an acquisition
    public func createForm(
        type: String,
        formData: FormData,
        for acquisitionId: UUID
    ) async throws -> GovernmentFormData {
        
        // Create the form using the factory
        let form = try formFactory.createForm(with: formData)
        
        // Serialize the form using export
        let exported = form.export()
        let serializedData = try JSONSerialization.data(withJSONObject: exported, options: .prettyPrinted)
        
        // Create Core Data entity
        let formDataEntity = GovernmentFormData.create(
            formType: type,
            formNumber: formData.formNumber,
            revision: formData.revision,
            formData: serializedData,
            in: context
        )
        
        // Associate with acquisition
        if let acquisition = try await fetchAcquisition(id: acquisitionId) {
            formDataEntity.acquisition = acquisition
        }
        
        // Save context
        try context.save()
        
        return formDataEntity
    }
    
    // MARK: - Form Retrieval
    
    /// Get all forms for an acquisition
    public func getForms(for acquisitionId: UUID) async throws -> [GovernmentFormData] {
        return await context.perform {
            GovernmentFormData.fetchForAcquisition(acquisitionId, in: self.context)
        }
    }
    
    /// Get forms by type
    public func getForms(ofType type: String) async throws -> [GovernmentFormData] {
        return await context.perform {
            GovernmentFormData.fetchByType(type, in: self.context)
        }
    }
    
    /// Get a specific form
    public func getForm(id: UUID) async throws -> GovernmentFormData? {
        return await context.perform {
            GovernmentFormData.fetchById(id, in: self.context)
        }
    }
    
    // MARK: - Form Updates
    
    /// Update form data
    public func updateForm(
        id: UUID,
        with formData: FormData
    ) async throws {
        
        guard let formEntity = try await getForm(id: id) else {
            throw ServiceError.notFound("Form not found")
        }
        
        // Create updated form using factory
        let updatedForm = try formFactory.createForm(with: formData)
        
        // Serialize the updated form using export
        let exported = updatedForm.export()
        let serializedData = try JSONSerialization.data(withJSONObject: exported, options: .prettyPrinted)
        
        // Update entity
        await context.perform {
            formEntity.updateFormData(serializedData)
        }
        
        try context.save()
    }
    
    /// Update form status
    public func updateFormStatus(
        id: UUID,
        status: String
    ) async throws {
        
        guard let formEntity = try await getForm(id: id) else {
            throw ServiceError.notFound("Form not found")
        }
        
        await context.perform {
            formEntity.updateStatus(status)
        }
        
        try context.save()
    }
    
    // MARK: - Form Deletion
    
    /// Delete a form
    public func deleteForm(id: UUID) async throws {
        guard let formEntity = try await getForm(id: id) else {
            throw ServiceError.notFound("Form not found")
        }
        
        await context.perform {
            self.context.delete(formEntity)
        }
        
        try context.save()
    }
    
    // MARK: - Form Conversion
    
    /// Convert form entity to specific form type
    public func convertToForm<T: GovernmentForm>(
        _ formEntity: GovernmentFormData,
        type: T.Type
    ) throws -> T {
        guard let data = formEntity.formData else {
            throw ServiceError.invalidData("No form data available")
        }
        
        // Deserialize the data
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.invalidData("Invalid form data format")
        }
        
        // Create FormData from the deserialized object
        let formData = FormData(
            formNumber: jsonObject["formNumber"] as? String ?? "",
            revision: jsonObject["revision"] as? String,
            fields: jsonObject as? [String: String] ?? [:],
            metadata: FormMetadata(
                createdBy: (jsonObject["metadata"] as? [String: Any])?["createdBy"] as? String ?? "",
                agency: (jsonObject["metadata"] as? [String: Any])?["agency"] as? String ?? "",
                purpose: (jsonObject["metadata"] as? [String: Any])?["purpose"] as? String ?? ""
            )
        )
        
        // Use factory to create the form
        return try formFactory.createForm(with: formData) as! T
    }
    
    // MARK: - Private Helpers
    
    private func fetchAcquisition(id: UUID) async throws -> Acquisition? {
        return await context.perform {
            let request: NSFetchRequest<Acquisition> = Acquisition.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            return try? self.context.fetch(request).first
        }
    }
    
}

// MARK: - Service Errors

extension GovernmentFormService {
    enum ServiceError: LocalizedError {
        case notFound(String)
        case invalidData(String)
        case saveFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .notFound(let message):
                return "Not found: \(message)"
            case .invalidData(let message):
                return "Invalid data: \(message)"
            case .saveFailed(let message):
                return "Save failed: \(message)"
            }
        }
    }
}

// MARK: - Form Templates

extension GovernmentFormService {
    
    /// Create a blank form template
    public func createBlankForm(type: String) throws -> any GovernmentForm {
        switch type {
        case GovernmentFormData.FormType.sf1449:
            return SF1449Factory().createBlank()
        case GovernmentFormData.FormType.sf33:
            return SF33Factory().createBlank()
        case GovernmentFormData.FormType.sf30:
            return SF30Factory().createBlank()
        case GovernmentFormData.FormType.sf18:
            return SF18Factory().createBlank()
        case GovernmentFormData.FormType.sf26:
            return SF26Factory().createBlank()
        case GovernmentFormData.FormType.sf44:
            return SF44Factory().createBlank()
        case GovernmentFormData.FormType.dd1155:
            return DD1155Factory().createBlank()
        default:
            throw ServiceError.invalidData("Unknown form type: \(type)")
        }
    }
    
    /// Get available form types
    public func availableFormTypes() -> [String] {
        return [
            GovernmentFormData.FormType.sf1449,
            GovernmentFormData.FormType.sf33,
            GovernmentFormData.FormType.sf30,
            GovernmentFormData.FormType.sf18,
            GovernmentFormData.FormType.sf26,
            GovernmentFormData.FormType.sf44,
            GovernmentFormData.FormType.dd1155
        ]
    }
}
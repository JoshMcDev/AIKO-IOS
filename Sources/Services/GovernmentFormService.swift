@preconcurrency import CoreData
import Foundation

/// Service for managing government forms in the system
public actor GovernmentFormService: DomainService {
    // MARK: - Properties

    private let coreDataActor: CoreDataActor
    private let formFactory = FormFactoryRegistry.shared

    // MARK: - Initialization

    public init(context: CoreDataActor) {
        coreDataActor = context
    }

    // MARK: - Form Creation

    /// Create a new form for an acquisition
    public func createForm(
        type: String,
        formData: FormData,
        for acquisitionId: UUID
    ) async throws -> GovernmentFormModel {
        // Create the form using the factory
        let form = try formFactory.createForm(with: formData)

        // Serialize the form using export
        let exported = form.export()
        let serializedData = try JSONSerialization.data(withJSONObject: exported, options: .prettyPrinted)

        // Create Core Data entity in a transaction and return domain model
        return try await coreDataActor.performBackgroundTask { context in
            let entity = GovernmentFormData.create(
                formType: type,
                formNumber: formData.formNumber,
                revision: formData.revision,
                formData: serializedData,
                in: context
            )

            // Associate with acquisition
            let acquisitionRequest: NSFetchRequest<CoreDataAcquisition> = CoreDataAcquisition.fetchRequest()
            acquisitionRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)
            acquisitionRequest.fetchLimit = 1
            if let acquisition = try context.fetch(acquisitionRequest).first {
                entity.acquisition = acquisition
            }

            try context.save()

            // Convert to Sendable domain model before returning
            guard let model = GovernmentFormModel(from: entity) else {
                throw ServiceError.saveFailed("Failed to create domain model from entity")
            }

            return model
        }
    }

    // MARK: - Form Retrieval

    /// Get all forms for an acquisition
    public func getForms(for acquisitionId: UUID) async throws -> [GovernmentFormModel] {
        try await coreDataActor.performViewContextTask { context in
            let entities = GovernmentFormData.fetchForAcquisition(acquisitionId, in: context)
            return entities.compactMap { GovernmentFormModel(from: $0) }
        }
    }

    /// Get forms by type
    public func getForms(ofType type: String) async throws -> [GovernmentFormModel] {
        try await coreDataActor.performViewContextTask { context in
            let entities = GovernmentFormData.fetchByType(type, in: context)
            return entities.compactMap { GovernmentFormModel(from: $0) }
        }
    }

    /// Get a specific form
    public func getForm(id: UUID) async throws -> GovernmentFormModel? {
        try await coreDataActor.performViewContextTask { context in
            let entity = GovernmentFormData.fetchById(id, in: context)
            return entity.flatMap { GovernmentFormModel(from: $0) }
        }
    }

    // MARK: - Form Updates

    /// Update form data
    public func updateForm(
        id: UUID,
        with formData: FormData
    ) async throws {
        guard try await getForm(id: id) != nil else {
            throw ServiceError.notFound("Form not found")
        }

        // Create updated form using factory
        let updatedForm = try formFactory.createForm(with: formData)

        // Serialize the updated form using export
        let exported = updatedForm.export()
        let serializedData = try JSONSerialization.data(withJSONObject: exported, options: .prettyPrinted)

        // Update entity in Core Data
        try await coreDataActor.performBackgroundTask { context in
            let entity = GovernmentFormData.fetchById(id, in: context)
            guard let formEntity = entity else {
                throw ServiceError.notFound("Form entity not found")
            }

            formEntity.updateFormData(serializedData)
            try context.save()
        }
    }

    /// Update form status
    public func updateFormStatus(
        id: UUID,
        status: String
    ) async throws {
        guard try await getForm(id: id) != nil else {
            throw ServiceError.notFound("Form not found")
        }

        try await coreDataActor.performBackgroundTask { context in
            let entity = GovernmentFormData.fetchById(id, in: context)
            guard let formEntity = entity else {
                throw ServiceError.notFound("Form entity not found")
            }

            formEntity.updateStatus(status)
            try context.save()
        }
    }

    // MARK: - Form Deletion

    /// Delete a form
    public func deleteForm(id: UUID) async throws {
        guard try await getForm(id: id) != nil else {
            throw ServiceError.notFound("Form not found")
        }

        try await coreDataActor.performBackgroundTask { context in
            let entity = GovernmentFormData.fetchById(id, in: context)
            guard let formEntity = entity else {
                throw ServiceError.notFound("Form entity not found")
            }

            context.delete(formEntity)
            try context.save()
        }
    }

    // MARK: - Form Conversion

    /// Convert form entity to specific form type
    public func convertToForm<T: GovernmentForm>(
        _ formEntity: GovernmentFormData,
        type _: T.Type
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
        let createdForm = try formFactory.createForm(with: formData)
        guard let typedForm = createdForm as? T else {
            throw ServiceError.invalidData("Form factory returned incorrect type for \(T.self)")
        }
        return typedForm
    }

    // MARK: - Private Helpers

    private func fetchAcquisition(id: UUID, in context: NSManagedObjectContext) throws -> CoreDataAcquisition? {
        let request: NSFetchRequest<CoreDataAcquisition> = CoreDataAcquisition.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
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
            case let .notFound(message):
                "Not found: \(message)"
            case let .invalidData(message):
                "Invalid data: \(message)"
            case let .saveFailed(message):
                "Save failed: \(message)"
            }
        }
    }
}

// MARK: - Form Templates

public extension GovernmentFormService {
    /// Create a blank form template
    func createBlankForm(type: String) throws -> any GovernmentForm {
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
    func availableFormTypes() -> [String] {
        [
            GovernmentFormData.FormType.sf1449,
            GovernmentFormData.FormType.sf33,
            GovernmentFormData.FormType.sf30,
            GovernmentFormData.FormType.sf18,
            GovernmentFormData.FormType.sf26,
            GovernmentFormData.FormType.sf44,
            GovernmentFormData.FormType.dd1155,
        ]
    }
}

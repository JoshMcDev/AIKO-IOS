import AppCore
import CoreData
import Foundation


/// Repository for Acquisition domain aggregate
public final class AcquisitionRepository: @unchecked Sendable {
    // MARK: - Private Properties

    private let coreDataActor: CoreDataActor

    // MARK: - Initialization

    public init(coreDataActor: CoreDataActor) {
        self.coreDataActor = coreDataActor
    }

    // MARK: - Factory Method

    private func createAggregate(from entity: Acquisition) -> AcquisitionAggregate {
        AcquisitionAggregate(managedObject: entity)
    }

    // MARK: - Basic Repository Operations

    /// Find all acquisitions
    public func findAll() async throws -> [AppCore.Acquisition] {
        try await coreDataActor.performViewContextTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]

            let entities = try context.fetch(request)
            return entities.map { $0.toAppCoreModel() }
        }
    }

    /// Find acquisition by ID
    public func findById(_ id: UUID) async throws -> AppCore.Acquisition? {
        try await coreDataActor.performViewContextTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            if let entity = try context.fetch(request).first {
                return entity.toAppCoreModel()
            } else {
                return nil
            }
        }
    }

    /// Update an acquisition
    public func update(_ acquisition: AppCore.Acquisition) async throws {
        try await coreDataActor.performBackgroundTask { context in
            // Fetch the acquisition in this context
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", acquisition.id as CVarArg)

            guard let entity = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }

            // Apply changes
            acquisition.applyTo(entity)
            try context.save()
        }
    }

    /// Delete an acquisition by ID
    public func delete(_ id: UUID) async throws {
        try await coreDataActor.performBackgroundTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    // MARK: - Specialized Queries

    /// Find acquisitions by status
    public func findByStatus(_ status: AcquisitionStatus) async throws -> [AppCore.Acquisition] {
        try await coreDataActor.performViewContextTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "status == %@", status.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]

            let entities = try context.fetch(request)
            return entities.map { $0.toAppCoreModel() }
        }
    }

    /// Find acquisitions by project number
    public func findByProjectNumber(_ projectNumber: String) async throws -> AppCore.Acquisition? {
        try await coreDataActor.performViewContextTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "projectNumber == %@", projectNumber)
            request.fetchLimit = 1

            if let entity = try context.fetch(request).first {
                return entity.toAppCoreModel()
            } else {
                return nil
            }
        }
    }

    /// Find acquisitions created within date range
    public func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [AppCore.Acquisition] {
        try await coreDataActor.performViewContextTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(
                format: "createdDate >= %@ AND createdDate <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]

            let entities = try context.fetch(request)
            return entities.map { $0.toAppCoreModel() }
        }
    }

    /// Search acquisitions by title or requirements
    public func search(query: String) async throws -> [AppCore.Acquisition] {
        try await coreDataActor.performViewContextTask { context in
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(
                format: "title CONTAINS[cd] %@ OR requirements CONTAINS[cd] %@",
                query, query
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.map { $0.toAppCoreModel() }
        }
    }

    // MARK: - Business Operations

    /// Create a new acquisition with uploaded documents
    public func createWithDocuments(
        title: String,
        requirements: String,
        uploadedDocuments: [(fileName: String, data: Data, contentSummary: String?)]
    ) async throws -> AppCore.Acquisition {
        try await coreDataActor.performBackgroundTask { context in
            // Create acquisition entity
            let acquisition = CoreDataAcquisition(context: context)
            acquisition.title = title
            acquisition.requirements = requirements
            acquisition.projectNumber = self.generateProjectNumber()

            // Convert uploaded document data to Core Data UploadedFile
            for doc in uploadedDocuments {
                let uploadedFile = UploadedFile(context: context)
                uploadedFile.fileName = doc.fileName
                uploadedFile.data = doc.data
                uploadedFile.contentSummary = doc.contentSummary
                acquisition.addToUploadedFiles(uploadedFile)
            }

            // Save and return domain model
            try context.save()
            return acquisition.toAppCoreModel()
        }
    }

    /// Add generated documents to acquisition
    public func addGeneratedDocuments(
        to acquisitionId: UUID,
        documents: [(title: String, content: String, documentCategory: DocumentCategory)]
    ) async throws {
        try await coreDataActor.performBackgroundTask { context in
            // Fetch the acquisition in this context
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

            guard let acquisition = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }

            for doc in documents {
                let generatedFile = GeneratedFile(context: context)
                generatedFile.fileName = doc.title
                generatedFile.content = doc.content.data(using: String.Encoding.utf8)
                generatedFile.fileType = doc.documentCategory.rawValue
                acquisition.addToGeneratedFiles(generatedFile)
            }

            acquisition.lastModifiedDate = Date()
            try context.save()
        }
    }

    /// Update acquisition status with business rule validation
    public func updateStatus(
        acquisitionId: UUID,
        to newStatus: AcquisitionStatus
    ) async throws {
        try await coreDataActor.performBackgroundTask { context in
            // Fetch the acquisition in this context
            let request = CoreDataAcquisition.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

            guard let acquisition = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }

            // Create aggregate for this context
            let contextAggregate = self.createAggregate(from: acquisition)

            // Use domain model's business logic
            try contextAggregate.transitionTo(newStatus)
            try context.save()
        }
    }

    // MARK: - Private Helpers

    private func generateProjectNumber() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        let randomNumber = Int.random(in: 1000 ... 9999)
        return "ACQ-\(dateString)-\(randomNumber)"
    }
}

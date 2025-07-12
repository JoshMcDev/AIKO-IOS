import ComposableArchitecture
import CoreData
import Foundation

public struct AcquisitionService {
    public var createAcquisition: (String, String, [UploadedDocument]) async throws -> Acquisition
    public var fetchAcquisitions: () async throws -> [Acquisition]
    public var fetchAcquisition: (UUID) async throws -> Acquisition?
    public var updateAcquisition: (UUID, (Acquisition) -> Void) async throws -> Void
    public var deleteAcquisition: (UUID) async throws -> Void
    public var addUploadedFiles: (UUID, [UploadedDocument]) async throws -> Void
    public var addGeneratedDocuments: (UUID, [GeneratedDocument]) async throws -> Void
    public var updateStatus: (UUID, Acquisition.Status) async throws -> Void

    public init(
        createAcquisition: @escaping (String, String, [UploadedDocument]) async throws -> Acquisition,
        fetchAcquisitions: @escaping () async throws -> [Acquisition],
        fetchAcquisition: @escaping (UUID) async throws -> Acquisition?,
        updateAcquisition: @escaping (UUID, (Acquisition) -> Void) async throws -> Void,
        deleteAcquisition: @escaping (UUID) async throws -> Void,
        addUploadedFiles: @escaping (UUID, [UploadedDocument]) async throws -> Void,
        addGeneratedDocuments: @escaping (UUID, [GeneratedDocument]) async throws -> Void,
        updateStatus: @escaping (UUID, Acquisition.Status) async throws -> Void
    ) {
        self.createAcquisition = createAcquisition
        self.fetchAcquisitions = fetchAcquisitions
        self.fetchAcquisition = fetchAcquisition
        self.updateAcquisition = updateAcquisition
        self.deleteAcquisition = deleteAcquisition
        self.addUploadedFiles = addUploadedFiles
        self.addGeneratedDocuments = addGeneratedDocuments
        self.updateStatus = updateStatus
    }
}

extension AcquisitionService: DependencyKey {
    public static var liveValue: AcquisitionService {
        // Always use repository-based implementation as part of Phase 4 migration
        return .repositoryBased
    }
    
    // Keep the old implementation as a backup/reference
    static var directCoreDataValue: AcquisitionService {
        let coreDataStack = CoreDataStack.shared

        return AcquisitionService(
            createAcquisition: { title, requirements, uploadedDocuments in
                let context = coreDataStack.viewContext

                let acquisition = Acquisition(context: context)
                acquisition.title = title
                acquisition.requirements = requirements
                acquisition.projectNumber = generateProjectNumber()

                // Convert UploadedDocument to Core Data UploadedFile
                for doc in uploadedDocuments {
                    let uploadedFile = UploadedFile(context: context)
                    uploadedFile.fileName = doc.fileName
                    uploadedFile.data = doc.data
                    uploadedFile.contentSummary = doc.contentSummary
                    acquisition.addToUploadedFiles(uploadedFile)
                }

                try coreDataStack.save()
                return acquisition
            },

            fetchAcquisitions: {
                do {
                    let context = coreDataStack.viewContext
                    let request = Acquisition.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]

                    return try context.fetch(request)
                } catch {
                    print("Error fetching acquisitions: \(error)")
                    throw error
                }
            },

            fetchAcquisition: { id in
                let context = coreDataStack.viewContext
                let request = Acquisition.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                request.fetchLimit = 1

                return try context.fetch(request).first
            },

            updateAcquisition: { id, update in
                let context = coreDataStack.viewContext
                let request = Acquisition.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

                guard let acquisition = try context.fetch(request).first else {
                    throw AcquisitionError.notFound
                }

                update(acquisition)
                acquisition.lastModifiedDate = Date()
                try coreDataStack.save()
            },

            deleteAcquisition: { id in
                let context = coreDataStack.viewContext
                let request = Acquisition.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

                if let acquisition = try context.fetch(request).first {
                    context.delete(acquisition)
                    try coreDataStack.save()
                }
            },

            addUploadedFiles: { acquisitionId, uploadedDocuments in
                let context = coreDataStack.viewContext
                let request = Acquisition.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

                guard let acquisition = try context.fetch(request).first else {
                    throw AcquisitionError.notFound
                }

                for doc in uploadedDocuments {
                    let uploadedFile = UploadedFile(context: context)
                    uploadedFile.fileName = doc.fileName
                    uploadedFile.data = doc.data
                    uploadedFile.contentSummary = doc.contentSummary
                    acquisition.addToUploadedFiles(uploadedFile)
                }

                acquisition.lastModifiedDate = Date()
                try coreDataStack.save()
            },

            addGeneratedDocuments: { acquisitionId, generatedDocuments in
                let context = coreDataStack.viewContext
                let request = Acquisition.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

                guard let acquisition = try context.fetch(request).first else {
                    throw AcquisitionError.notFound
                }

                for doc in generatedDocuments {
                    let generatedFile = GeneratedFile(context: context)
                    generatedFile.fileName = doc.title
                    generatedFile.content = doc.content.data(using: .utf8)
                    generatedFile.fileType = doc.documentCategory.displayName
                    acquisition.addToGeneratedFiles(generatedFile)
                }

                acquisition.lastModifiedDate = Date()
                try coreDataStack.save()
            },

            updateStatus: { acquisitionId, status in
                let context = coreDataStack.viewContext
                let request = Acquisition.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

                guard let acquisition = try context.fetch(request).first else {
                    throw AcquisitionError.notFound
                }

                acquisition.statusEnum = status
                acquisition.lastModifiedDate = Date()
                try coreDataStack.save()
            }
        )
    }

    public static var testValue: AcquisitionService {
        liveValue
    }
}

// MARK: - Helper Functions

private func generateProjectNumber() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let dateString = formatter.string(from: date)
    let randomNumber = Int.random(in: 1000 ... 9999)
    return "ACQ-\(dateString)-\(randomNumber)"
}

// MARK: - Errors

enum AcquisitionError: LocalizedError {
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notFound:
            "Acquisition not found"
        case .invalidData:
            "Invalid acquisition data"
        }
    }
}

public extension DependencyValues {
    var acquisitionService: AcquisitionService {
        get { self[AcquisitionService.self] }
        set { self[AcquisitionService.self] = newValue }
    }
}

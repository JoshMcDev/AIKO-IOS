import AppCore
@preconcurrency import CoreData
import Foundation

/// Repository for document management with domain-driven design
public final class DocumentRepository: @unchecked Sendable {
    // MARK: - Private Properties

    private let coreDataActor: CoreDataActor

    // MARK: - Initialization

    public init(coreDataActor: CoreDataActor) {
        self.coreDataActor = coreDataActor
    }

    // MARK: - Document Operations

    /// Create a new document
    public func create(
        title _: String,
        content: String,
        type: DocumentType,
        acquisitionId: UUID
    ) async throws -> DocumentInfo {
        try await coreDataActor.performBackgroundTask { context in
            let documentId = UUID()
            let createdDate = Date()
            let document = AcquisitionDocument(context: context)
            document.id = documentId
            // Note: AcquisitionDocument doesn't have a title property
            document.content = content
            document.documentType = type.rawValue
            document.createdDate = createdDate
            // Note: AcquisitionDocument doesn't have lastModifiedDate

            // Link to acquisition
            let acquisitionRequest = CoreDataAcquisition.fetchRequest()
            acquisitionRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

            if let acquisition = try context.fetch(acquisitionRequest).first {
                document.acquisition = acquisition
                acquisition.addToDocuments(document)
            } else {
                throw DocumentRepositoryError.acquisitionNotFound
            }

            try context.save()

            // Convert to Sendable type
            let documentInfo = DocumentInfo(
                id: documentId,
                content: content,
                documentType: type.rawValue,
                createdDate: createdDate,
                acquisitionId: acquisitionId
            )
            return documentInfo
        }
    }

    /// Find all documents for an acquisition
    public func findByAcquisition(_ acquisitionId: UUID) async throws -> [DocumentInfo] {
        let request = AcquisitionDocument.fetchRequest()
        request.predicate = NSPredicate(format: "acquisition.id == %@", acquisitionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]

        let documents = try await coreDataActor.performViewContextTask { context in
            try context.fetch(request)
        }

        // Convert to Sendable types
        return documents.map { document in
            DocumentInfo(
                id: document.id ?? UUID(),
                content: document.content ?? "",
                documentType: document.documentType ?? "",
                createdDate: document.createdDate ?? Date(),
                acquisitionId: document.acquisition?.id ?? acquisitionId
            )
        }
    }

    /// Find documents by type
    public func findByType(_ type: DocumentType) async throws -> [DocumentInfo] {
        let request = AcquisitionDocument.fetchRequest()
        request.predicate = NSPredicate(format: "documentType == %@", type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]

        let documents = try await coreDataActor.performViewContextTask { context in
            try context.fetch(request)
        }

        // Convert to Sendable types
        return documents.map { document in
            DocumentInfo(
                id: document.id ?? UUID(),
                content: document.content ?? "",
                documentType: document.documentType ?? "",
                createdDate: document.createdDate ?? Date(),
                acquisitionId: document.acquisition?.id ?? UUID()
            )
        }
    }

    /// Update document content
    public func updateContent(documentId: UUID, newContent: String) async throws {
        try await coreDataActor.performBackgroundTask { context in
            let request = AcquisitionDocument.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", documentId as CVarArg)

            guard let document = try context.fetch(request).first else {
                throw DocumentRepositoryError.documentNotFound
            }

            document.content = newContent
            // Note: AcquisitionDocument doesn't have lastModifiedDate

            try context.save()
        }
    }

    /// Delete a document
    public func delete(_ documentId: UUID) async throws {
        try await coreDataActor.performBackgroundTask { context in
            let request = AcquisitionDocument.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", documentId as CVarArg)

            if let document = try context.fetch(request).first {
                context.delete(document)
                try context.save()
            }
        }
    }

    /// Batch create documents
    public func batchCreate(
        documents: [(title: String, content: String, type: DocumentType)],
        for acquisitionId: UUID
    ) async throws -> [DocumentInfo] {
        try await coreDataActor.performBackgroundTask { context in
            // Find acquisition first
            let acquisitionRequest = CoreDataAcquisition.fetchRequest()
            acquisitionRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)

            guard let acquisition = try context.fetch(acquisitionRequest).first else {
                throw DocumentRepositoryError.acquisitionNotFound
            }

            var createdDocumentInfos: [DocumentInfo] = []

            for doc in documents {
                let documentId = UUID()
                let createdDate = Date()
                let document = AcquisitionDocument(context: context)
                document.id = documentId
                // Note: AcquisitionDocument doesn't have a title property - title is lost
                document.content = doc.content
                document.documentType = doc.type.rawValue
                document.createdDate = createdDate
                // Note: AcquisitionDocument doesn't have lastModifiedDate
                document.acquisition = acquisition

                acquisition.addToDocuments(document)

                // Convert to Sendable type
                let documentInfo = DocumentInfo(
                    id: documentId,
                    content: doc.content,
                    documentType: doc.type.rawValue,
                    createdDate: createdDate,
                    acquisitionId: acquisitionId
                )
                createdDocumentInfos.append(documentInfo)
            }

            try context.save()
            return createdDocumentInfos
        }
    }

    /// Search documents by content
    public func search(query: String, in acquisitionId: UUID? = nil) async throws -> [DocumentInfo] {
        let request = AcquisitionDocument.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "content CONTAINS[cd] %@", query),
        ]

        if let acquisitionId {
            predicates.append(NSPredicate(format: "acquisition.id == %@", acquisitionId as CVarArg))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]

        let documents = try await coreDataActor.performViewContextTask { context in
            try context.fetch(request)
        }

        // Convert to Sendable types
        return documents.map { document in
            DocumentInfo(
                id: document.id ?? UUID(),
                content: document.content ?? "",
                documentType: document.documentType ?? "",
                createdDate: document.createdDate ?? Date(),
                acquisitionId: document.acquisition?.id ?? UUID()
            )
        }
    }

    /// Get recent documents
    public func findRecent(limit: Int = 10) async throws -> [DocumentInfo] {
        let request = AcquisitionDocument.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]
        request.fetchLimit = limit

        let documents = try await coreDataActor.performViewContextTask { context in
            try context.fetch(request)
        }

        // Convert to Sendable types
        return documents.map { document in
            DocumentInfo(
                id: document.id ?? UUID(),
                content: document.content ?? "",
                documentType: document.documentType ?? "",
                createdDate: document.createdDate ?? Date(),
                acquisitionId: document.acquisition?.id ?? UUID()
            )
        }
    }
}

// MARK: - Sendable DocumentInfo Type

/// Sendable representation of document data for crossing concurrency boundaries
public struct DocumentInfo: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let content: String
    public let documentType: String
    public let createdDate: Date
    public let acquisitionId: UUID

    public init(id: UUID, content: String, documentType: String, createdDate: Date, acquisitionId: UUID) {
        self.id = id
        self.content = content
        self.documentType = documentType
        self.createdDate = createdDate
        self.acquisitionId = acquisitionId
    }
}

// MARK: - Errors

public enum DocumentRepositoryError: LocalizedError, Sendable {
    case documentNotFound
    case acquisitionNotFound
    case invalidDocumentType

    public var errorDescription: String? {
        switch self {
        case .documentNotFound:
            "Document not found"
        case .acquisitionNotFound:
            "Associated acquisition not found"
        case .invalidDocumentType:
            "Invalid document type"
        }
    }
}

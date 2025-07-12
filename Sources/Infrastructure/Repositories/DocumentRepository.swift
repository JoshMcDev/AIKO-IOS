import Foundation
import CoreData

/// Repository for document management with domain-driven design
public final class DocumentRepository {
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Document Operations
    
    /// Create a new document
    public func create(
        title: String,
        content: String,
        type: DocumentType,
        acquisitionId: UUID
    ) async throws -> AcquisitionDocument {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let document = AcquisitionDocument(context: self.context)
                    document.id = UUID()
                    // Note: AcquisitionDocument doesn't have a title property
                    document.content = content
                    document.documentType = type.rawValue
                    document.createdDate = Date()
                    // Note: AcquisitionDocument doesn't have lastModifiedDate
                    
                    // Link to acquisition
                    let acquisitionRequest = Acquisition.fetchRequest()
                    acquisitionRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)
                    
                    if let acquisition = try self.context.fetch(acquisitionRequest).first {
                        document.acquisition = acquisition
                        acquisition.addToDocuments(document)
                    } else {
                        throw DocumentRepositoryError.acquisitionNotFound
                    }
                    
                    try self.context.save()
                    continuation.resume(returning: document)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Find all documents for an acquisition
    public func findByAcquisition(_ acquisitionId: UUID) async throws -> [AcquisitionDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = AcquisitionDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "acquisition.id == %@", acquisitionId as CVarArg)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]
                    
                    let documents = try self.context.fetch(request)
                    continuation.resume(returning: documents)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Find documents by type
    public func findByType(_ type: DocumentType) async throws -> [AcquisitionDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = AcquisitionDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "documentType == %@", type.rawValue)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]
                    
                    let documents = try self.context.fetch(request)
                    continuation.resume(returning: documents)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update document content
    public func updateContent(documentId: UUID, newContent: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    let request = AcquisitionDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", documentId as CVarArg)
                    
                    guard let document = try self.context.fetch(request).first else {
                        throw DocumentRepositoryError.documentNotFound
                    }
                    
                    document.content = newContent
                    // Note: AcquisitionDocument doesn't have lastModifiedDate
                    
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete a document
    public func delete(_ documentId: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    let request = AcquisitionDocument.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", documentId as CVarArg)
                    
                    if let document = try self.context.fetch(request).first {
                        self.context.delete(document)
                        try self.context.save()
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Batch create documents
    public func batchCreate(
        documents: [(title: String, content: String, type: DocumentType)],
        for acquisitionId: UUID
    ) async throws -> [AcquisitionDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Find acquisition first
                    let acquisitionRequest = Acquisition.fetchRequest()
                    acquisitionRequest.predicate = NSPredicate(format: "id == %@", acquisitionId as CVarArg)
                    
                    guard let acquisition = try self.context.fetch(acquisitionRequest).first else {
                        throw DocumentRepositoryError.acquisitionNotFound
                    }
                    
                    var createdDocuments: [AcquisitionDocument] = []
                    
                    for doc in documents {
                        let document = AcquisitionDocument(context: self.context)
                        document.id = UUID()
                        // Note: AcquisitionDocument doesn't have a title property - title is lost
                        document.content = doc.content
                        document.documentType = doc.type.rawValue
                        document.createdDate = Date()
                        // Note: AcquisitionDocument doesn't have lastModifiedDate
                        document.acquisition = acquisition
                        
                        acquisition.addToDocuments(document)
                        createdDocuments.append(document)
                    }
                    
                    try self.context.save()
                    continuation.resume(returning: createdDocuments)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Search documents by content
    public func search(query: String, in acquisitionId: UUID? = nil) async throws -> [AcquisitionDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = AcquisitionDocument.fetchRequest()
                    
                    var predicates: [NSPredicate] = [
                        NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query)
                    ]
                    
                    if let acquisitionId = acquisitionId {
                        predicates.append(NSPredicate(format: "acquisition.id == %@", acquisitionId as CVarArg))
                    }
                    
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]
                    
                    let documents = try self.context.fetch(request)
                    continuation.resume(returning: documents)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Get recent documents
    public func findRecent(limit: Int = 10) async throws -> [AcquisitionDocument] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = AcquisitionDocument.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \AcquisitionDocument.createdDate, ascending: false)]
                    request.fetchLimit = limit
                    
                    let documents = try self.context.fetch(request)
                    continuation.resume(returning: documents)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Errors

public enum DocumentRepositoryError: LocalizedError {
    case documentNotFound
    case acquisitionNotFound
    case invalidDocumentType
    
    public var errorDescription: String? {
        switch self {
        case .documentNotFound:
            return "Document not found"
        case .acquisitionNotFound:
            return "Associated acquisition not found"
        case .invalidDocumentType:
            return "Invalid document type"
        }
    }
}
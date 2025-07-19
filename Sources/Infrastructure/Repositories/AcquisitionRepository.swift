import Foundation
import AppCore
import CoreData

/// Repository for Acquisition domain aggregate
public final class AcquisitionRepository {
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Factory Method
    
    private func createAggregate(from entity: Acquisition) -> AcquisitionAggregate {
        return AcquisitionAggregate(managedObject: entity)
    }
    
    // MARK: - Basic Repository Operations
    
    /// Find all acquisitions
    public func findAll() async throws -> [AcquisitionAggregate] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]
                    
                    let entities = try self.context.fetch(request)
                    let aggregates = entities.map { self.createAggregate(from: $0) }
                    continuation.resume(returning: aggregates)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Find acquisition by ID
    public func findById(_ id: UUID) async throws -> AcquisitionAggregate? {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    
                    if let entity = try self.context.fetch(request).first {
                        continuation.resume(returning: self.createAggregate(from: entity))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update an acquisition aggregate
    public func update(_ aggregate: AcquisitionAggregate) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete an acquisition by ID
    public func delete(_ id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    
                    if let entity = try self.context.fetch(request).first {
                        self.context.delete(entity)
                        try self.context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Specialized Queries
    
    /// Find acquisitions by status
    public func findByStatus(_ status: AcquisitionStatus) async throws -> [AcquisitionAggregate] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.predicate = NSPredicate(format: "status == %@", status.rawValue)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]
                    
                    let entities = try self.context.fetch(request)
                    let aggregates = entities.map { self.createAggregate(from: $0) }
                    continuation.resume(returning: aggregates)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Find acquisitions by project number
    public func findByProjectNumber(_ projectNumber: String) async throws -> AcquisitionAggregate? {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.predicate = NSPredicate(format: "projectNumber == %@", projectNumber)
                    request.fetchLimit = 1
                    
                    if let entity = try self.context.fetch(request).first {
                        continuation.resume(returning: self.createAggregate(from: entity))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Find acquisitions created within date range
    public func findByDateRange(from startDate: Date, to endDate: Date) async throws -> [AcquisitionAggregate] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "createdDate >= %@ AND createdDate <= %@",
                        startDate as NSDate,
                        endDate as NSDate
                    )
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]
                    
                    let entities = try self.context.fetch(request)
                    let aggregates = entities.map { self.createAggregate(from: $0) }
                    continuation.resume(returning: aggregates)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Search acquisitions by title or requirements
    public func search(query: String) async throws -> [AcquisitionAggregate] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = Acquisition.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "title CONTAINS[cd] %@ OR requirements CONTAINS[cd] %@",
                        query, query
                    )
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \Acquisition.createdDate, ascending: false)]
                    
                    let entities = try self.context.fetch(request)
                    let aggregates = entities.map { self.createAggregate(from: $0) }
                    continuation.resume(returning: aggregates)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Business Operations
    
    /// Create a new acquisition with uploaded documents
    public func createWithDocuments(
        title: String,
        requirements: String,
        uploadedDocuments: [(fileName: String, data: Data, contentSummary: String?)]
    ) async throws -> AcquisitionAggregate {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Create acquisition entity
                    let acquisition = Acquisition(context: self.context)
                    acquisition.title = title
                    acquisition.requirements = requirements
                    acquisition.projectNumber = self.generateProjectNumber()
                    
                    // Convert uploaded document data to Core Data UploadedFile
                    for doc in uploadedDocuments {
                        let uploadedFile = UploadedFile(context: self.context)
                        uploadedFile.fileName = doc.fileName
                        uploadedFile.data = doc.data
                        uploadedFile.contentSummary = doc.contentSummary
                        acquisition.addToUploadedFiles(uploadedFile)
                    }
                    
                    // Save and create aggregate
                    try self.context.save()
                    let aggregate = self.createAggregate(from: acquisition)
                    
                    continuation.resume(returning: aggregate)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Add generated documents to acquisition
    public func addGeneratedDocuments(
        to acquisitionId: UUID,
        documents: [(title: String, content: String, documentCategory: DocumentCategory)]
    ) async throws {
        guard let aggregate = try await findById(acquisitionId) else {
            throw RepositoryError.notFound
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    for doc in documents {
                        let generatedFile = GeneratedFile(context: self.context)
                        generatedFile.fileName = doc.title
                        generatedFile.content = doc.content.data(using: String.Encoding.utf8)
                        generatedFile.fileType = doc.documentCategory.rawValue
                        aggregate.managedObject.addToGeneratedFiles(generatedFile)
                    }
                    
                    aggregate.updateLastModified()
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update acquisition status with business rule validation
    public func updateStatus(
        acquisitionId: UUID,
        to newStatus: AcquisitionStatus
    ) async throws {
        guard let aggregate = try await findById(acquisitionId) else {
            throw RepositoryError.notFound
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    // Use domain model's business logic
                    try aggregate.transitionTo(newStatus)
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func generateProjectNumber() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        let randomNumber = Int.random(in: 1000...9999)
        return "ACQ-\(dateString)-\(randomNumber)"
    }
}



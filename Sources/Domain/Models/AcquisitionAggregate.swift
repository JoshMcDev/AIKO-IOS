import Foundation
import AppCore
import CoreData

/// Rich domain model for Acquisition aggregate root
public final class AcquisitionAggregate: AggregateRoot<Acquisition> {
    
    // MARK: - Properties
    
    public override var id: UUID {
        managedObject.id ?? UUID()
    }
    
    public override var createdDate: Date {
        managedObject.createdDate ?? Date()
    }
    
    public override var lastModifiedDate: Date {
        get { managedObject.lastModifiedDate ?? Date() }
        set { managedObject.lastModifiedDate = newValue }
    }
    
    public var title: String {
        get { managedObject.title ?? "" }
        set {
            managedObject.title = newValue
            updateLastModified()
        }
    }
    
    public var requirements: String {
        get { managedObject.requirements ?? "" }
        set {
            managedObject.requirements = newValue
            updateLastModified()
        }
    }
    
    public var projectNumber: String? {
        get { managedObject.projectNumber }
        set {
            managedObject.projectNumber = newValue
            updateLastModified()
        }
    }
    
    public var status: AcquisitionStatus {
        get {
            guard let statusString = managedObject.status,
                  let status = AcquisitionStatus(rawValue: statusString) else {
                return .draft
            }
            return status
        }
        set {
            managedObject.status = newValue.rawValue
            updateLastModified()
        }
    }
    
    public var documents: [AcquisitionDocumentEntity] {
        let documents = managedObject.documentsArray
        return documents.map { AcquisitionDocumentEntity(managedObject: $0) }
    }
    
    public var uploadedFiles: [UploadedFileEntity] {
        let files = managedObject.uploadedFilesArray
        return files.map { UploadedFileEntity(managedObject: $0) }
    }
    
    public var estimatedValue: Money? {
        // Would be stored in metadata or computed
        return nil
    }
    
    // MARK: - Business Logic
    
    /// Add a document to the acquisition
    public func addDocument(_ document: AcquisitionDocument) throws {
        // Business rule: Cannot add documents to cancelled acquisitions
        guard status != .cancelled else {
            throw DomainError.businessRule("Cannot add documents to cancelled acquisitions")
        }
        
        // Business rule: Cannot add duplicate documents
        let existingDocs = managedObject.documentsArray
        guard !existingDocs.contains(where: { $0.id == document.id }) else {
            throw DomainError.businessRule("Document already exists in acquisition")
        }
        
        managedObject.addToDocuments(document)
        updateLastModified()
        
        // Raise domain event
        raiseEvent(DocumentAddedEvent(
            acquisitionId: id,
            documentId: document.id ?? UUID(),
            documentType: document.documentType ?? ""
        ))
    }
    
    /// Remove a document from the acquisition
    public func removeDocument(_ document: AcquisitionDocument) throws {
        // Business rule: Cannot modify approved acquisitions
        guard status != .approved && status != .awarded else {
            throw DomainError.businessRule("Cannot remove documents from \(status.displayName) acquisitions")
        }
        
        managedObject.removeFromDocuments(document)
        updateLastModified()
        
        // Raise domain event
        raiseEvent(DocumentRemovedEvent(
            acquisitionId: id,
            documentId: document.id ?? UUID()
        ))
    }
    
    /// Transition to a new status
    public func transitionTo(_ newStatus: AcquisitionStatus) throws {
        // Validate transition
        guard canTransitionTo(newStatus) else {
            throw DomainError.businessRule(
                "Cannot transition from \(status.displayName) to \(newStatus.displayName)"
            )
        }
        
        // Additional validation for specific transitions
        switch newStatus {
        case .underReview:
            guard !documents.isEmpty else {
                throw DomainError.businessRule("Cannot submit for review without documents")
            }
        case .approved:
            guard status == .underReview else {
                throw DomainError.businessRule("Can only approve acquisitions under review")
            }
        case .awarded:
            guard status == .approved else {
                throw DomainError.businessRule("Can only award approved acquisitions")
            }
        default:
            break
        }
        
        let oldStatus = status
        status = newStatus
        
        // Raise domain event
        raiseEvent(AcquisitionStatusChangedEvent(
            acquisitionId: id,
            fromStatus: oldStatus,
            toStatus: newStatus
        ))
    }
    
    /// Check if can transition to a specific status
    public func canTransitionTo(_ targetStatus: AcquisitionStatus) -> Bool {
        switch (status, targetStatus) {
        // From Draft
        case (.draft, .inProgress): return true
        case (.draft, .cancelled): return true
        
        // From In Progress
        case (.inProgress, .underReview): return true
        case (.inProgress, .draft): return true
        case (.inProgress, .cancelled): return true
        
        // From Under Review
        case (.underReview, .approved): return true
        case (.underReview, .inProgress): return true
        case (.underReview, .cancelled): return true
        
        // From Approved
        case (.approved, .awarded): return true
        case (.approved, .cancelled): return true
        
        // From Awarded
        case (.awarded, .archived): return true
        
        // From Cancelled
        case (.cancelled, .draft): return true
        
        // Same status transitions allowed
        case _ where status == targetStatus: return true
        
        // All other transitions not allowed
        default: return false
        }
    }
    
    /// Update requirements with validation
    public func updateRequirements(_ newRequirements: String) throws {
        guard !newRequirements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.validation("Requirements cannot be empty")
        }
        
        guard newRequirements.count >= 10 else {
            throw DomainError.validation("Requirements must be at least 10 characters")
        }
        
        requirements = newRequirements
    }
    
    /// Calculate completeness percentage
    public var completenessPercentage: Percentage {
        var score = 0
        let totalChecks = 5
        
        if !title.isEmpty { score += 1 }
        if !requirements.isEmpty { score += 1 }
        if projectNumber != nil { score += 1 }
        if !documents.isEmpty { score += 1 }
        if estimatedValue != nil { score += 1 }
        
        let percentage = Decimal(score) / Decimal(totalChecks) * 100
        return try! Percentage(percentage)
    }
    
    // MARK: - Validation
    
    public override func validate() throws {
        try super.validate()
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.validation("Title is required")
        }
        
        guard title.count <= 200 else {
            throw DomainError.validation("Title must be 200 characters or less")
        }
        
        if status != .draft {
            guard !requirements.isEmpty else {
                throw DomainError.validation("Requirements are required for non-draft acquisitions")
            }
        }
    }
    
    // MARK: - Internal Methods
    
    internal func updateLastModified() {
        lastModifiedDate = Date()
    }
}

// MARK: - Domain Events

public struct DocumentAddedEvent: DomainEvent {
    public let eventId = UUID()
    public let occurredAt = Date()
    public let aggregateId: UUID
    public let documentId: UUID
    public let documentType: String
    
    init(acquisitionId: UUID, documentId: UUID, documentType: String) {
        self.aggregateId = acquisitionId
        self.documentId = documentId
        self.documentType = documentType
    }
}

public struct DocumentRemovedEvent: DomainEvent {
    public let eventId = UUID()
    public let occurredAt = Date()
    public let aggregateId: UUID
    public let documentId: UUID
    
    init(acquisitionId: UUID, documentId: UUID) {
        self.aggregateId = acquisitionId
        self.documentId = documentId
    }
}

public struct AcquisitionStatusChangedEvent: DomainEvent {
    public let eventId = UUID()
    public let occurredAt = Date()
    public let aggregateId: UUID
    public let fromStatus: AcquisitionStatus
    public let toStatus: AcquisitionStatus
    
    init(acquisitionId: UUID, fromStatus: AcquisitionStatus, toStatus: AcquisitionStatus) {
        self.aggregateId = acquisitionId
        self.fromStatus = fromStatus
        self.toStatus = toStatus
    }
}

// MARK: - Supporting Domain Entities

public final class AcquisitionDocumentEntity: CoreDataDomainEntity<AcquisitionDocument> {
    public override var id: UUID {
        managedObject.id ?? UUID()
    }
    
    public override var createdDate: Date {
        managedObject.createdDate ?? Date()
    }
    
    public override var lastModifiedDate: Date {
        // AcquisitionDocument doesn't have lastModifiedDate, using createdDate
        managedObject.createdDate ?? Date()
    }
    
    public var documentType: String {
        managedObject.documentType ?? ""
    }
    
    public var content: String {
        managedObject.content ?? ""
    }
    
    public var status: String {
        managedObject.status ?? "draft"
    }
}

public final class UploadedFileEntity: CoreDataDomainEntity<UploadedFile> {
    public override var id: UUID {
        managedObject.id ?? UUID()
    }
    
    public override var createdDate: Date {
        managedObject.uploadDate ?? Date()
    }
    
    public override var lastModifiedDate: Date {
        managedObject.uploadDate ?? Date()
    }
    
    public var fileName: String {
        managedObject.fileName ?? ""
    }
    
    public var uploadDate: Date {
        managedObject.uploadDate ?? Date()
    }
    
    public var contentSummary: String? {
        managedObject.contentSummary
    }
    
    public var data: Data? {
        managedObject.data
    }
}

// MARK: - Acquisition Status Enhancement

extension Acquisition.Status {
    // Note: displayName is already defined in Acquisition+CoreDataClass.swift
    
    public var canEdit: Bool {
        switch self {
        case .draft, .inProgress:
            return true
        case .underReview, .approved, .awarded, .cancelled, .archived:
            return false
        }
    }
}


import Foundation

// MARK: - Acquisition Event Handlers

/// Handler for when documents are added to acquisitions
public struct DocumentAddedEventHandler: DomainEventHandler {
    public typealias Event = DocumentAddedEvent

    private let notificationService: NotificationService?
    private let auditService: AuditService?

    public init(
        notificationService: NotificationService? = nil,
        auditService: AuditService? = nil
    ) {
        self.notificationService = notificationService
        self.auditService = auditService
    }

    public func handle(_ event: DocumentAddedEvent) async {
        // Log audit trail
        await auditService?.log(
            action: "DOCUMENT_ADDED",
            entityId: event.aggregateId,
            details: [
                "documentId": event.documentId.uuidString,
                "documentType": event.documentType,
            ]
        )

        // Send notification
        await notificationService?.notify(
            title: "Document Added",
            message: "A new \(event.documentType) document has been added to the acquisition",
            type: .info
        )

        // Update search index
        // await searchService?.index(documentId: event.documentId)

        print("[DocumentAdded] Document \(event.documentId) of type \(event.documentType) added to acquisition \(event.aggregateId)")
    }
}

/// Handler for acquisition status changes
public struct AcquisitionStatusChangedEventHandler: DomainEventHandler {
    public typealias Event = AcquisitionStatusChangedEvent

    private let workflowService: WorkflowService?
    private let notificationService: NotificationService?
    private let auditService: AuditService?

    public init(
        workflowService: WorkflowService? = nil,
        notificationService: NotificationService? = nil,
        auditService: AuditService? = nil
    ) {
        self.workflowService = workflowService
        self.notificationService = notificationService
        self.auditService = auditService
    }

    public func handle(_ event: AcquisitionStatusChangedEvent) async {
        // Log audit trail
        await auditService?.log(
            action: "STATUS_CHANGED",
            entityId: event.aggregateId,
            details: [
                "fromStatus": event.fromStatus.rawValue,
                "toStatus": event.toStatus.rawValue,
            ]
        )

        // Trigger workflow actions based on status
        switch event.toStatus {
        case .underReview:
            await workflowService?.startReviewProcess(acquisitionId: event.aggregateId)
            await notificationService?.notify(
                title: "Acquisition Under Review",
                message: "The acquisition has been submitted for review",
                type: .info
            )

        case .approved:
            await workflowService?.startApprovalProcess(acquisitionId: event.aggregateId)
            await notificationService?.notify(
                title: "Acquisition Approved",
                message: "The acquisition has been approved",
                type: .success
            )

        case .cancelled:
            await workflowService?.cancelRelatedProcesses(acquisitionId: event.aggregateId)
            await notificationService?.notify(
                title: "Acquisition Cancelled",
                message: "The acquisition has been cancelled",
                type: .warning
            )

        default:
            break
        }

        print("[StatusChanged] Acquisition \(event.aggregateId) changed from \(event.fromStatus.displayName) to \(event.toStatus.displayName)")
    }
}

/// Handler for document removal events
public struct DocumentRemovedEventHandler: DomainEventHandler {
    public typealias Event = DocumentRemovedEvent

    private let auditService: AuditService?

    public init(auditService: AuditService? = nil) {
        self.auditService = auditService
    }

    public func handle(_ event: DocumentRemovedEvent) async {
        // Log audit trail
        await auditService?.log(
            action: "DOCUMENT_REMOVED",
            entityId: event.aggregateId,
            details: [
                "documentId": event.documentId.uuidString,
            ]
        )

        // Remove from search index
        // await searchService?.removeFromIndex(documentId: event.documentId)

        print("[DocumentRemoved] Document \(event.documentId) removed from acquisition \(event.aggregateId)")
    }
}

// MARK: - Projection Handlers

/// Update read model when acquisition status changes
public struct AcquisitionStatusProjectionHandler: DomainEventHandler {
    public typealias Event = AcquisitionStatusChangedEvent

    public func handle(_ event: AcquisitionStatusChangedEvent) async {
        // Update denormalized status in read model
        print("[Projection] Updating acquisition \(event.aggregateId) status to \(event.toStatus.rawValue)")
    }
}

/// Update read model when documents are added
public struct DocumentAddedProjectionHandler: DomainEventHandler {
    public typealias Event = DocumentAddedEvent

    public func handle(_ event: DocumentAddedEvent) async {
        // Update document count in read model
        print("[Projection] Updating document count for acquisition \(event.aggregateId) - document added")
    }
}

/// Update read model when documents are removed
public struct DocumentRemovedProjectionHandler: DomainEventHandler {
    public typealias Event = DocumentRemovedEvent

    public func handle(_ event: DocumentRemovedEvent) async {
        // Update document count in read model
        print("[Projection] Updating document count for acquisition \(event.aggregateId) - document removed")
    }
}

// MARK: - Integration Event Publishers

/// Publish approval events to external systems
public struct ApprovalIntegrationEventPublisher: DomainEventHandler {
    public typealias Event = AcquisitionStatusChangedEvent

    public let priority = -10 // Low priority, runs after other handlers

    public func handle(_ event: AcquisitionStatusChangedEvent) async {
        switch event.toStatus {
        case .approved:
            // Publish to message queue, event bus, or external API
            print("[Integration] Publishing acquisition approval event for \(event.aggregateId)")

        case .awarded:
            // Publish to contract management system
            print("[Integration] Publishing acquisition award event for \(event.aggregateId)")

        default:
            break
        }
    }
}

// MARK: - Mock Services

/// Mock notification service
public protocol NotificationService {
    func notify(title: String, message: String, type: NotificationType) async
}

public enum NotificationType {
    case info, success, warning, error
}

/// Mock audit service
public protocol AuditService {
    func log(action: String, entityId: UUID, details: [String: String]) async
}

/// Mock workflow service
public protocol WorkflowService {
    func startReviewProcess(acquisitionId: UUID) async
    func startApprovalProcess(acquisitionId: UUID) async
    func cancelRelatedProcesses(acquisitionId: UUID) async
}

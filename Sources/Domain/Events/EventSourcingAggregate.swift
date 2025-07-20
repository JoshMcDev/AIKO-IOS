import AppCore
import CoreData
import Foundation

/// Protocol for event-sourced aggregates
public protocol EventSourcedAggregate: AnyObject {
    /// Apply an event to update aggregate state
    func apply(_ event: DomainEvent)
}

/// Base class for event-sourced aggregates
open class EventSourcedAggregateRoot<T: NSManagedObject>: AggregateRoot<T>, EventSourcedAggregate, @unchecked Sendable {
    // MARK: - Properties

    private var version: Int = 0
    private var uncommittedEvents: [DomainEvent] = []

    // MARK: - Event Sourcing

    /// Apply an event and update state
    open func apply(_: DomainEvent) {
        // Default implementation - subclasses should override
        version += 1
    }

    /// Apply and record a new event
    func applyChange(_ event: DomainEvent) {
        apply(event)
        uncommittedEvents.append(event)
        raiseEvent(event)
    }

    /// Get uncommitted events
    public func getUncommittedEvents() -> [DomainEvent] {
        uncommittedEvents
    }

    /// Mark events as committed
    public func markEventsAsCommitted() {
        uncommittedEvents.removeAll()
    }

    /// Load from event history
    public static func loadFromHistory(
        _ events: [DomainEvent],
        managedObject: T
    ) -> EventSourcedAggregateRoot<T> {
        let aggregate = EventSourcedAggregateRoot<T>(managedObject: managedObject)

        for event in events {
            aggregate.apply(event)
            aggregate.version += 1
        }

        return aggregate
    }
}

// MARK: - Event-Sourced Acquisition Example

/// Event-sourced version of AcquisitionAggregate
public final class EventSourcedAcquisition: EventSourcedAggregateRoot<Acquisition>, @unchecked Sendable {
    // MARK: - Properties (computed from events)

    private var _title: String = ""
    private var _requirements: String = ""
    private var _status: AcquisitionStatus = .draft
    private var _projectNumber: String?
    private var _documentIds: Set<UUID> = []

    override public var id: UUID {
        managedObject.id ?? UUID()
    }

    override public var createdDate: Date {
        managedObject.createdDate ?? Date()
    }

    override public var lastModifiedDate: Date {
        managedObject.lastModifiedDate ?? Date()
    }

    // MARK: - Event Application

    override public func apply(_ event: DomainEvent) {
        super.apply(event)

        switch event {
        case let created as AcquisitionCreatedEvent:
            applyCreated(created)

        case let updated as AcquisitionUpdatedEvent:
            applyUpdated(updated)

        case let statusChanged as AcquisitionStatusChangedEvent:
            applyStatusChanged(statusChanged)

        case let documentAdded as DocumentAddedEvent:
            applyDocumentAdded(documentAdded)

        case let documentRemoved as DocumentRemovedEvent:
            applyDocumentRemoved(documentRemoved)

        default:
            break
        }
    }

    private func applyCreated(_ event: AcquisitionCreatedEvent) {
        _title = event.title
        _requirements = event.requirements
        _status = .draft
    }

    private func applyUpdated(_ event: AcquisitionUpdatedEvent) {
        if let title = event.title {
            _title = title
        }
        if let requirements = event.requirements {
            _requirements = requirements
        }
        if let projectNumber = event.projectNumber {
            _projectNumber = projectNumber
        }
    }

    private func applyStatusChanged(_ event: AcquisitionStatusChangedEvent) {
        _status = event.toStatus
    }

    private func applyDocumentAdded(_ event: DocumentAddedEvent) {
        _documentIds.insert(event.documentId)
    }

    private func applyDocumentRemoved(_ event: DocumentRemovedEvent) {
        _documentIds.remove(event.documentId)
    }

    // MARK: - Commands (that generate events)

    public static func create(
        title: String,
        requirements: String,
        in context: NSManagedObjectContext
    ) throws -> EventSourcedAcquisition {
        // Validate
        guard !title.isEmpty else {
            throw DomainError.validation("Title is required")
        }
        guard !requirements.isEmpty else {
            throw DomainError.validation("Requirements are required")
        }

        // Create managed object
        let acquisition = CoreDataAcquisition(context: context)
        acquisition.id = UUID()
        acquisition.createdDate = Date()
        acquisition.lastModifiedDate = Date()
        acquisition.status = AcquisitionStatus.draft.rawValue

        // Create aggregate
        let aggregate = EventSourcedAcquisition(managedObject: acquisition)

        // Apply creation event
        let event = AcquisitionCreatedEvent(
            aggregateId: aggregate.id,
            title: title,
            requirements: requirements
        )
        aggregate.applyChange(event)

        return aggregate
    }

    public func update(title: String? = nil, requirements: String? = nil, projectNumber: String? = nil) throws {
        // Validate
        if let title, title.isEmpty {
            throw DomainError.validation("Title cannot be empty")
        }
        if let requirements, requirements.isEmpty {
            throw DomainError.validation("Requirements cannot be empty")
        }

        // Apply update event
        let event = AcquisitionUpdatedEvent(
            aggregateId: id,
            title: title,
            requirements: requirements,
            projectNumber: projectNumber
        )
        applyChange(event)
    }

    public func transitionTo(_ newStatus: AcquisitionStatus) throws {
        // Validate transition (reuse logic from non-event-sourced version)
        guard canTransitionTo(newStatus) else {
            throw DomainError.businessRule(
                "Cannot transition from \(_status.displayName) to \(newStatus.displayName)"
            )
        }

        // Apply status change event
        let event = AcquisitionStatusChangedEvent(
            acquisitionId: id,
            fromStatus: _status,
            toStatus: newStatus
        )
        applyChange(event)
    }

    private func canTransitionTo(_ targetStatus: AcquisitionStatus) -> Bool {
        // Reuse transition logic
        switch (_status, targetStatus) {
        case (.draft, .inProgress), (.draft, .cancelled),
             (.inProgress, .underReview), (.inProgress, .draft), (.inProgress, .cancelled),
             (.underReview, .approved), (.underReview, .inProgress), (.underReview, .cancelled),
             (.approved, .awarded), (.approved, .cancelled),
             (.awarded, .archived),
             (.cancelled, .draft):
            true
        case _ where _status == targetStatus:
            true
        default:
            false
        }
    }
}

// MARK: - Additional Domain Events

public struct AcquisitionCreatedEvent: DomainEvent, Codable {
    public let eventId: UUID
    public let occurredAt: Date
    public let aggregateId: UUID
    public let title: String
    public let requirements: String

    init(aggregateId: UUID, title: String, requirements: String) {
        eventId = UUID()
        occurredAt = Date()
        self.aggregateId = aggregateId
        self.title = title
        self.requirements = requirements
    }
}

public struct AcquisitionUpdatedEvent: DomainEvent, Codable {
    public let eventId: UUID
    public let occurredAt: Date
    public let aggregateId: UUID
    public let title: String?
    public let requirements: String?
    public let projectNumber: String?

    init(aggregateId: UUID, title: String?, requirements: String?, projectNumber: String?) {
        eventId = UUID()
        occurredAt = Date()
        self.aggregateId = aggregateId
        self.title = title
        self.requirements = requirements
        self.projectNumber = projectNumber
    }
}

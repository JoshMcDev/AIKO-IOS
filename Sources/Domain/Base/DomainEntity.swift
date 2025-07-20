import CoreData
import Foundation

/// Base class for all domain entities providing common functionality
public protocol DomainEntity: AnyObject {
    associatedtype ID: Hashable

    var id: ID { get }
    var createdDate: Date { get }
    var lastModifiedDate: Date { get }

    /// Validate the entity's current state
    func validate() throws

    /// Check if this entity equals another of the same type
    func isEqual(to other: Any) -> Bool
}

/// Base implementation for Core Data backed domain entities
open class CoreDataDomainEntity<T: NSManagedObject>: DomainEntity, @unchecked Sendable {
    public typealias ID = UUID

    /// The underlying Core Data managed object
    let managedObject: T

    /// The managed object context
    var context: NSManagedObjectContext? {
        managedObject.managedObjectContext
    }

    public var id: UUID {
        fatalError("Subclasses must override id property")
    }

    public var createdDate: Date {
        fatalError("Subclasses must override createdDate property")
    }

    public var lastModifiedDate: Date {
        fatalError("Subclasses must override lastModifiedDate property")
    }

    /// Initialize with a managed object
    public init(managedObject: T) {
        self.managedObject = managedObject
    }

    /// Default validation - subclasses should override
    open func validate() throws {
        // Base validation logic
        if id == UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
            throw DomainError.validation("Invalid ID")
        }
    }

    /// Default equality check
    open func isEqual(to other: Any) -> Bool {
        guard let other = other as? CoreDataDomainEntity<T> else { return false }
        return id == other.id
    }

    /// Save changes to the managed object context
    public func save() throws {
        guard let context, context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            throw DomainError.persistence("Failed to save changes: \(error.localizedDescription)")
        }
    }
}

/// Domain errors
public enum DomainError: LocalizedError {
    case validation(String)
    case businessRule(String)
    case persistence(String)
    case invalidState(String)
    case notFound

    public var errorDescription: String? {
        switch self {
        case let .validation(message):
            "Validation error: \(message)"
        case let .businessRule(message):
            "Business rule violation: \(message)"
        case let .persistence(message):
            "Persistence error: \(message)"
        case let .invalidState(message):
            "Invalid state: \(message)"
        case .notFound:
            "Entity not found"
        }
    }
}

/// Base class for aggregate roots
open class AggregateRoot<T: NSManagedObject>: CoreDataDomainEntity<T>, @unchecked Sendable {
    /// Domain events raised by this aggregate
    private var domainEvents: [DomainEvent] = []

    /// Raise a domain event
    func raiseEvent(_ event: DomainEvent) {
        domainEvents.append(event)
    }

    /// Get and clear all domain events
    public func pullDomainEvents() -> [DomainEvent] {
        let events = domainEvents
        domainEvents.removeAll()
        return events
    }

    /// Check if there are any unpublished events
    public var hasUnpublishedEvents: Bool {
        !domainEvents.isEmpty
    }
}

/// Protocol for domain events
public protocol DomainEvent: Sendable {
    var eventId: UUID { get }
    var occurredAt: Date { get }
    var aggregateId: UUID { get }
}

/// Base implementation of domain event
public struct BaseDomainEvent: DomainEvent, Sendable {
    public let eventId: UUID
    public let occurredAt: Date
    public let aggregateId: UUID

    public init(aggregateId: UUID) {
        eventId = UUID()
        occurredAt = Date()
        self.aggregateId = aggregateId
    }
}

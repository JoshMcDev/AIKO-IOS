import Foundation
import CoreData

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
open class CoreDataDomainEntity<T: NSManagedObject>: DomainEntity {
    public typealias ID = UUID
    
    /// The underlying Core Data managed object
    internal let managedObject: T
    
    /// The managed object context
    internal var context: NSManagedObjectContext? {
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
        return self.id == other.id
    }
    
    /// Save changes to the managed object context
    public func save() throws {
        guard let context = context, context.hasChanges else { return }
        
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
        case .validation(let message):
            return "Validation error: \(message)"
        case .businessRule(let message):
            return "Business rule violation: \(message)"
        case .persistence(let message):
            return "Persistence error: \(message)"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .notFound:
            return "Entity not found"
        }
    }
}

/// Base class for aggregate roots
open class AggregateRoot<T: NSManagedObject>: CoreDataDomainEntity<T> {
    /// Domain events raised by this aggregate
    private var domainEvents: [DomainEvent] = []
    
    /// Raise a domain event
    internal func raiseEvent(_ event: DomainEvent) {
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
public protocol DomainEvent {
    var eventId: UUID { get }
    var occurredAt: Date { get }
    var aggregateId: UUID { get }
}

/// Base implementation of domain event
public struct BaseDomainEvent: DomainEvent {
    public let eventId: UUID
    public let occurredAt: Date
    public let aggregateId: UUID
    
    public init(aggregateId: UUID) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.aggregateId = aggregateId
    }
}
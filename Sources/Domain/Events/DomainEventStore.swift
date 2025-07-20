import CoreData
import Foundation

/// Protocol for domain event storage
public protocol DomainEventStore {
    /// Store a domain event
    func store(_ event: DomainEvent) async throws

    /// Retrieve events for an aggregate
    func eventsForAggregate(id: UUID, after: Date?) async throws -> [StoredDomainEvent]

    /// Retrieve all events of a specific type
    func eventsOfType(_ type: (some DomainEvent).Type, after: Date?) async throws -> [StoredDomainEvent]

    /// Retrieve all events within a time range
    func events(from startDate: Date, to endDate: Date) async throws -> [StoredDomainEvent]

    /// Delete events older than a specific date
    func deleteEventsBefore(_ date: Date) async throws
}

/// Stored domain event with metadata
public struct StoredDomainEvent: Sendable {
    public let id: UUID
    public let aggregateId: UUID
    public let eventType: String
    public let eventData: Data
    public let occurredAt: Date
    public let storedAt: Date
    public let version: Int

    /// Deserialize the event data
    public func deserialize<T: DomainEvent & Codable>(as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: eventData)
    }
}

/// Core Data implementation of domain event store
public final class CoreDataEventStore: DomainEventStore {
    // MARK: - Properties

    private let container: NSPersistentContainer
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    public init(container: NSPersistentContainer) {
        self.container = container

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - DomainEventStore Implementation

    public func store(_ event: DomainEvent) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            // Create event entity
            let eventEntity = NSEntityDescription.insertNewObject(
                forEntityName: "StoredEvent",
                into: context
            )

            // Set properties
            eventEntity.setValue(event.eventId, forKey: "id")
            eventEntity.setValue(event.aggregateId, forKey: "aggregateId")
            eventEntity.setValue(String(describing: type(of: event)), forKey: "eventType")
            eventEntity.setValue(event.occurredAt, forKey: "occurredAt")
            eventEntity.setValue(Date(), forKey: "storedAt")
            eventEntity.setValue(1, forKey: "version")

            // Serialize event data if event is Codable
            if let codableEvent = event as? (DomainEvent & Codable) {
                let mirror = Mirror(reflecting: codableEvent)
                let data = try self.encodeEvent(codableEvent, mirror: mirror)
                eventEntity.setValue(data, forKey: "eventData")
            }

            // Save context
            try context.save()
        }
    }

    public func eventsForAggregate(id: UUID, after: Date?) async throws -> [StoredDomainEvent] {
        let context = container.newBackgroundContext()

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "StoredEvent")

            var predicates = [NSPredicate(format: "aggregateId == %@", id as CVarArg)]
            if let after {
                predicates.append(NSPredicate(format: "occurredAt > %@", after as CVarArg))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: true)]

            let results = try context.fetch(request)
            return try results.map { try self.mapToStoredEvent($0) }
        }
    }

    public func eventsOfType(_ type: (some DomainEvent).Type, after: Date?) async throws -> [StoredDomainEvent] {
        let context = container.newBackgroundContext()

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "StoredEvent")

            var predicates = [NSPredicate(format: "eventType == %@", String(describing: type))]
            if let after {
                predicates.append(NSPredicate(format: "occurredAt > %@", after as CVarArg))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: true)]

            let results = try context.fetch(request)
            return try results.map { try self.mapToStoredEvent($0) }
        }
    }

    public func events(from startDate: Date, to endDate: Date) async throws -> [StoredDomainEvent] {
        let context = container.newBackgroundContext()

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "StoredEvent")

            request.predicate = NSPredicate(
                format: "occurredAt >= %@ AND occurredAt <= %@",
                startDate as CVarArg,
                endDate as CVarArg
            )
            request.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: true)]

            let results = try context.fetch(request)
            return try results.map { try self.mapToStoredEvent($0) }
        }
    }

    public func deleteEventsBefore(_ date: Date) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "StoredEvent")
            request.predicate = NSPredicate(format: "occurredAt < %@", date as CVarArg)

            let results = try context.fetch(request)
            for event in results {
                context.delete(event)
            }

            try context.save()
        }
    }

    // MARK: - Private Methods

    private func encodeEvent(_ event: some Codable, mirror _: Mirror) throws -> Data {
        // For now, use JSON encoding
        // In production, could use more efficient encoding
        try encoder.encode(event)
    }

    private func mapToStoredEvent(_ managedObject: NSManagedObject) throws -> StoredDomainEvent {
        guard let id = managedObject.value(forKey: "id") as? UUID,
              let aggregateId = managedObject.value(forKey: "aggregateId") as? UUID,
              let eventType = managedObject.value(forKey: "eventType") as? String,
              let eventData = managedObject.value(forKey: "eventData") as? Data,
              let occurredAt = managedObject.value(forKey: "occurredAt") as? Date,
              let storedAt = managedObject.value(forKey: "storedAt") as? Date,
              let version = managedObject.value(forKey: "version") as? Int
        else {
            throw DomainError.persistence("Invalid stored event data")
        }

        return StoredDomainEvent(
            id: id,
            aggregateId: aggregateId,
            eventType: eventType,
            eventData: eventData,
            occurredAt: occurredAt,
            storedAt: storedAt,
            version: version
        )
    }
}

// MARK: - In-Memory Event Store for Testing

public final class InMemoryEventStore: DomainEventStore, @unchecked Sendable {
    private var events: [StoredDomainEvent] = []
    private let queue = DispatchQueue(label: "com.aiko.inmemory.eventstore", attributes: .concurrent)

    public init() {}

    public func store(_ event: DomainEvent) async throws {
        let storedEvent = StoredDomainEvent(
            id: event.eventId,
            aggregateId: event.aggregateId,
            eventType: String(describing: type(of: event)),
            eventData: Data(), // Simplified for in-memory
            occurredAt: event.occurredAt,
            storedAt: Date(),
            version: 1
        )

        queue.async(flags: .barrier) {
            self.events.append(storedEvent)
        }
    }

    public func eventsForAggregate(id: UUID, after: Date?) async throws -> [StoredDomainEvent] {
        queue.sync {
            events.filter { event in
                event.aggregateId == id &&
                    (after == nil || event.occurredAt > after!)
            }.sorted { $0.occurredAt < $1.occurredAt }
        }
    }

    public func eventsOfType(_ type: (some DomainEvent).Type, after: Date?) async throws -> [StoredDomainEvent] {
        let typeName = String(describing: type)
        return queue.sync {
            events.filter { event in
                event.eventType == typeName &&
                    (after == nil || event.occurredAt > after!)
            }.sorted { $0.occurredAt < $1.occurredAt }
        }
    }

    public func events(from startDate: Date, to endDate: Date) async throws -> [StoredDomainEvent] {
        queue.sync {
            events.filter { event in
                event.occurredAt >= startDate && event.occurredAt <= endDate
            }.sorted { $0.occurredAt < $1.occurredAt }
        }
    }

    public func deleteEventsBefore(_ date: Date) async throws {
        queue.async(flags: .barrier) {
            self.events.removeAll { $0.occurredAt < date }
        }
    }
}

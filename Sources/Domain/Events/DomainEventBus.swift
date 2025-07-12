import Foundation
import Combine

/// Domain event bus for decoupled event communication
public final class DomainEventBus {
    
    // MARK: - Singleton
    
    public static let shared = DomainEventBus()
    
    // MARK: - Properties
    
    private let dispatcher: DomainEventDispatcher
    private let eventStore: DomainEventStore?
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        dispatcher: DomainEventDispatcher = .shared,
        eventStore: DomainEventStore? = nil
    ) {
        self.dispatcher = dispatcher
        self.eventStore = eventStore
    }
    
    // MARK: - Publishing
    
    /// Publish a domain event
    public func publish(_ event: DomainEvent) async {
        // Store event if event store is configured
        if let eventStore = eventStore {
            do {
                try await eventStore.store(event)
            } catch {
                // Log error but don't fail - events should still be dispatched
                print("Failed to store event: \(error)")
            }
        }
        
        // Dispatch to handlers
        await dispatcher.dispatch(event)
    }
    
    /// Publish multiple events
    public func publish(_ events: [DomainEvent]) async {
        for event in events {
            await publish(event)
        }
    }
    
    /// Publish events from an aggregate
    public func publishFrom<T>(_ aggregate: AggregateRoot<T>) async {
        let events = aggregate.pullDomainEvents()
        await publish(events)
    }
    
    // MARK: - Subscription
    
    /// Subscribe to events of a specific type
    public func subscribe<Event: DomainEvent>(
        to eventType: Event.Type,
        priority: Int = 0,
        handler: @escaping (Event) async -> Void
    ) {
        dispatcher.on(eventType, priority: priority, handler: handler)
    }
    
    /// Subscribe to events with Combine
    public func publisher<Event: DomainEvent>(
        for eventType: Event.Type
    ) -> AnyPublisher<Event, Never> {
        dispatcher.eventPublisher
            .compactMap { $0 as? Event }
            .eraseToAnyPublisher()
    }
    
    /// Subscribe to all events
    public var allEventsPublisher: AnyPublisher<DomainEvent, Never> {
        dispatcher.eventPublisher
    }
    
    // MARK: - Event Replay
    
    /// Replay events for an aggregate
    public func replayEvents(
        forAggregate aggregateId: UUID,
        after: Date? = nil
    ) async throws {
        guard let eventStore = eventStore else {
            throw DomainError.invalidState("Event store not configured")
        }
        
        let events = try await eventStore.eventsForAggregate(id: aggregateId, after: after)
        
        // Note: This is simplified - in production, you'd deserialize and dispatch
        // the actual event objects
        print("Would replay \(events.count) events for aggregate \(aggregateId)")
    }
}

// MARK: - Event Handler Registration

public extension DomainEventBus {
    
    /// Register multiple event handlers at once
    func registerHandlers(_ handlers: [any DomainEventHandler]) {
        for handler in handlers {
            dispatcher.register(handler)
        }
    }
    
    /// Auto-register handlers using reflection (simplified version)
    func autoRegisterHandlers(in namespace: String = "AIKO") {
        // In a real implementation, this would use runtime inspection
        // to find all types conforming to DomainEventHandler
        print("Auto-registration would scan for handlers in \(namespace)")
    }
}

// MARK: - Common Event Handlers

/// Generic event logger using closure-based handling
public final class DomainEventLogger {
    
    public let priority = 100 // High priority to log first
    
    public init() {}
    
    /// Register logger with event bus
    public func register(with dispatcher: DomainEventDispatcher) {
        // Register handlers for common event types
        dispatcher.on(AcquisitionStatusChangedEvent.self, priority: priority) { event in
            print("[DomainEvent] AcquisitionStatusChangedEvent - ID: \(event.eventId) - Aggregate: \(event.aggregateId)")
        }
        
        dispatcher.on(DocumentAddedEvent.self, priority: priority) { event in
            print("[DomainEvent] DocumentAddedEvent - ID: \(event.eventId) - Aggregate: \(event.aggregateId)")
        }
        
        dispatcher.on(DocumentRemovedEvent.self, priority: priority) { event in
            print("[DomainEvent] DocumentRemovedEvent - ID: \(event.eventId) - Aggregate: \(event.aggregateId)")
        }
    }
}

/// Performance monitoring for specific event types
public struct AcquisitionEventPerformanceMonitor: DomainEventHandler {
    public typealias Event = AcquisitionStatusChangedEvent
    
    public let priority = 90
    
    public init() {}
    
    public func handle(_ event: AcquisitionStatusChangedEvent) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Let other handlers process
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        if timeElapsed > 0.1 { // Log slow events (>100ms)
            print("[Performance] Slow event handling: AcquisitionStatusChangedEvent took \(timeElapsed)s")
        }
    }
}
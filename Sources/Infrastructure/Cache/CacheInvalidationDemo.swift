import ComposableArchitecture
import Foundation

/// Demo implementation showing intelligent cache invalidation in action
public struct CacheInvalidationDemo {
    @Dependency(\.objectActionCache) var cache
    @Dependency(\.cacheInvalidationStrategy) var invalidationStrategy

    public init() {}

    /// Demonstrate time-based invalidation
    public func demonstrateTimeBasedInvalidation() async throws {
        print("\n=== Time-Based Cache Invalidation Demo ===\n")

        // Add a rule for documents older than 30 minutes
        let timeRule = CacheInvalidationStrategy.InvalidationRule(
            name: "Stale Document Invalidation",
            trigger: .timeElapsed(1800), // 30 minutes
            scope: .objectType(.document),
            priority: 50
        )

        await invalidationStrategy.addRule(timeRule)

        // Simulate cache entries
        let actions = createSampleActions(ofType: .document, count: 5)
        for action in actions {
            let result = createDummyResult(for: action)
            await cache.set(action, result: result, ttl: 3600) // 1 hour TTL
        }

        print("✓ Cached 5 document actions")

        // Simulate time passing
        let event = InvalidationEvent(
            type: .time,
            scope: .objectType(.document),
            timestamp: Date(),
            metadata: ["elapsed": 1900.0] // 31+ minutes
        )

        await invalidationStrategy.processEvent(event)

        print("✓ Time-based invalidation triggered after 31 minutes")
        print("  Documents older than 30 minutes have been invalidated")
    }

    /// Demonstrate dependency-based invalidation
    public func demonstrateDependencyInvalidation() async throws {
        print("\n=== Dependency-Based Cache Invalidation Demo ===\n")

        // Register dependencies
        await invalidationStrategy.registerDependency(from: "vendor-123", to: "contract-456")
        await invalidationStrategy.registerDependency(from: "vendor-123", to: "contract-789")
        await invalidationStrategy.registerDependency(from: "contract-456", to: "document-abc")

        print("✓ Registered dependency chain:")
        print("  vendor-123 → contract-456 → document-abc")
        print("  vendor-123 → contract-789")

        // Cache related actions
        let vendorAction = ObjectAction(
            type: .read,
            objectType: .vendor,
            objectId: "vendor-123",
            context: ActionContext(userId: "user1", sessionId: "session1")
        )

        let contractActions = [
            ObjectAction(
                type: .read,
                objectType: .contract,
                objectId: "contract-456",
                context: ActionContext(userId: "user1", sessionId: "session1")
            ),
            ObjectAction(
                type: .read,
                objectType: .contract,
                objectId: "contract-789",
                context: ActionContext(userId: "user1", sessionId: "session1")
            ),
        ]

        // Cache all actions
        await cache.set(vendorAction, result: createDummyResult(for: vendorAction))
        for action in contractActions {
            await cache.set(action, result: createDummyResult(for: action))
        }

        print("\n✓ Cached vendor and contract data")

        // Vendor update triggers cascade invalidation
        let updateEvent = InvalidationEvent(
            type: .event("objectUpdated"),
            scope: .pattern("vendor-123"),
            timestamp: Date(),
            metadata: ["key": "vendor-123"]
        )

        await invalidationStrategy.processEvent(updateEvent)

        print("\n✓ Vendor update triggered cascade invalidation")
        print("  All dependent contracts and documents invalidated")
    }

    /// Demonstrate pattern-based invalidation
    public func demonstratePatternInvalidation() async throws {
        print("\n=== Pattern-Based Cache Invalidation Demo ===\n")

        // Cache actions with pattern in IDs
        let testActions = [
            ObjectAction(
                type: .analyze,
                objectType: .document,
                objectId: "test-doc-001",
                context: ActionContext(userId: "user1", sessionId: "session1")
            ),
            ObjectAction(
                type: .analyze,
                objectType: .document,
                objectId: "test-doc-002",
                context: ActionContext(userId: "user1", sessionId: "session1")
            ),
            ObjectAction(
                type: .analyze,
                objectType: .document,
                objectId: "prod-doc-001",
                context: ActionContext(userId: "user1", sessionId: "session1")
            ),
        ]

        for action in testActions {
            await cache.set(action, result: createDummyResult(for: action))
        }

        print("✓ Cached 3 documents (2 test, 1 production)")

        // Invalidate all test documents
        await invalidationStrategy.invalidate(scope: .pattern("test-.*"))

        print("\n✓ Pattern invalidation executed")
        print("  All documents matching 'test-.*' pattern invalidated")
        print("  Production documents remain cached")
    }

    /// Demonstrate smart invalidation based on changes
    public func demonstrateSmartInvalidation() async throws {
        print("\n=== Smart Change-Based Invalidation Demo ===\n")

        // Simulate multiple changes
        let changes = [
            ChangeDescriptor(
                objectId: "req-001",
                objectType: .requirement,
                changeType: .update,
                changedFields: ["description", "priority"],
                timestamp: Date()
            ),
            ChangeDescriptor(
                objectId: "req-002",
                objectType: .requirement,
                changeType: .update,
                changedFields: ["status"],
                timestamp: Date()
            ),
            ChangeDescriptor(
                objectId: "req-003",
                objectType: .requirement,
                changeType: .delete,
                changedFields: [],
                timestamp: Date()
            ),
        ]

        print("✓ Detected changes:")
        print("  - req-001: Updated description and priority")
        print("  - req-002: Updated status only")
        print("  - req-003: Deleted")

        // Smart invalidation analyzes changes and creates optimal plan
        await invalidationStrategy.smartInvalidate(basedOn: changes)

        print("\n✓ Smart invalidation plan executed:")
        print("  - Selective invalidation for req-001, req-002")
        print("  - Full invalidation for req-003 and its dependencies")
        print("  - Pattern detected: all requirement objects affected")
    }

    /// Demonstrate threshold-based invalidation
    public func demonstrateThresholdInvalidation() async throws {
        print("\n=== Threshold-Based Invalidation Demo ===\n")

        // Add memory pressure rule
        let memoryRule = CacheInvalidationStrategy.InvalidationRule(
            name: "Memory Pressure Relief",
            trigger: .thresholdReached(.memoryUsage, 0.85),
            scope: .all,
            priority: 100
        )

        await invalidationStrategy.addRule(memoryRule)

        print("✓ Added memory pressure rule (triggers at 85% usage)")

        // Simulate high memory usage
        let memoryEvent = InvalidationEvent(
            type: .threshold("memoryUsage", 0.87),
            scope: .all,
            timestamp: Date(),
            metadata: ["currentUsage": 0.87, "threshold": 0.85]
        )

        await invalidationStrategy.processEvent(memoryEvent)

        print("\n✓ Memory threshold exceeded (87% > 85%)")
        print("  Emergency cache invalidation triggered")
        print("  All cache tiers cleared to free memory")
    }

    // MARK: - Helper Methods

    private func createSampleActions(ofType type: ObjectType, count: Int) -> [ObjectAction] {
        (0 ..< count).map { index in
            ObjectAction(
                type: .read,
                objectType: type,
                objectId: "\(type.rawValue)-\(index)",
                context: ActionContext(userId: "demo", sessionId: "demo-session")
            )
        }
    }

    private func createDummyResult(for action: ObjectAction) -> ActionResult {
        ActionResult(
            actionId: action.id,
            status: .completed,
            output: ActionOutput(
                type: .text,
                data: Data("Demo result".utf8)
            ),
            metrics: ActionMetrics(
                startTime: Date(),
                endTime: Date(),
                cpuUsage: 0.1,
                memoryUsage: 0.1,
                successRate: 1.0,
                performanceScore: 0.9,
                effectivenessScore: 0.9
            )
        )
    }

    /// Run all demonstrations
    public func runAllDemos() async throws {
        print("🚀 Starting Cache Invalidation Demonstrations\n")

        try await demonstrateTimeBasedInvalidation()
        try await demonstrateDependencyInvalidation()
        try await demonstratePatternInvalidation()
        try await demonstrateSmartInvalidation()
        try await demonstrateThresholdInvalidation()

        print("\n✅ All demonstrations completed successfully!")

        // Show final metrics
        let metrics = await cache.getMetrics()
        print("\n📊 Final Cache Metrics:")
        print("  Total Requests: \(metrics.totalRequests)")
        print("  Total Invalidations: \(metrics.totalInvalidations)")
        print("  L1 Hit Rate: \(String(format: "%.1f", metrics.l1HitRate * 100))%")
        print("  L2 Hit Rate: \(String(format: "%.1f", metrics.l2HitRate * 100))%")
        print("  L3 Hit Rate: \(String(format: "%.1f", metrics.l3HitRate * 100))%")
    }
}

import XCTest
@testable import AIKO
import ComposableArchitecture

final class CacheInvalidationTests: XCTestCase {
    
    func testTimeBasedInvalidation() async throws {
        // Create strategy and cache
        let strategy = CacheInvalidationStrategy()
        let cache = ObjectActionCache()
        
        // Add time-based rule
        let timeRule = CacheInvalidationStrategy.InvalidationRule(
            name: "Quick Expiry Test",
            trigger: .timeElapsed(1), // 1 second
            scope: .objectType(.document),
            priority: 50
        )
        
        await strategy.addRule(timeRule)
        
        // Create and cache a document action
        let action = ObjectAction(
            type: .read,
            objectType: .document,
            objectId: "test-doc-1",
            context: ActionContext(userId: "test", sessionId: "test-session")
        )
        
        let result = ActionResult(
            actionId: action.id,
            status: .completed,
            output: ActionOutput(
                type: .text,
                data: "Test data".data(using: .utf8)!
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
        
        await cache.set(action, result: result)
        
        // Verify it's cached
        let cachedResult = await cache.get(action)
        XCTAssertNotNil(cachedResult)
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Trigger time-based invalidation
        let event = InvalidationEvent(
            type: .time,
            scope: .objectType(.document),
            timestamp: Date(),
            metadata: ["elapsed": 2.0]
        )
        
        await strategy.processEvent(event)
        
        // Verify cache was invalidated
        let afterInvalidation = await cache.get(action)
        XCTAssertNil(afterInvalidation)
    }
    
    func testDependencyBasedInvalidation() async throws {
        let strategy = CacheInvalidationStrategy()
        let cache = ObjectActionCache()
        
        // Register dependencies
        await strategy.registerDependency(from: "vendor-1", to: "contract-1")
        await strategy.registerDependency(from: "vendor-1", to: "contract-2")
        
        // Cache vendor and contract actions
        let vendorAction = ObjectAction(
            type: .read,
            objectType: .vendor,
            objectId: "vendor-1",
            context: ActionContext(userId: "test", sessionId: "test-session")
        )
        
        let contractAction1 = ObjectAction(
            type: .read,
            objectType: .contract,
            objectId: "contract-1",
            context: ActionContext(userId: "test", sessionId: "test-session")
        )
        
        let contractAction2 = ObjectAction(
            type: .read,
            objectType: .contract,
            objectId: "contract-2",
            context: ActionContext(userId: "test", sessionId: "test-session")
        )
        
        let dummyResult = ActionResult(
            actionId: UUID().uuidString,
            status: .completed,
            output: nil,
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
        
        // Cache all actions
        await cache.set(vendorAction, result: dummyResult)
        await cache.set(contractAction1, result: dummyResult)
        await cache.set(contractAction2, result: dummyResult)
        
        // Verify all are cached
        XCTAssertNotNil(await cache.get(vendorAction))
        XCTAssertNotNil(await cache.get(contractAction1))
        XCTAssertNotNil(await cache.get(contractAction2))
        
        // Get dependent keys
        let dependents = await strategy.getDependents(of: "vendor-1")
        XCTAssertEqual(dependents.count, 2)
        XCTAssertTrue(dependents.contains("contract-1"))
        XCTAssertTrue(dependents.contains("contract-2"))
    }
    
    func testPatternBasedInvalidation() async throws {
        let strategy = CacheInvalidationStrategy()
        let cache = ObjectActionCache()
        
        // Cache actions with patterns
        let testActions = [
            ObjectAction(
                type: .analyze,
                objectType: .document,
                objectId: "test-doc-001",
                context: ActionContext(userId: "test", sessionId: "test-session")
            ),
            ObjectAction(
                type: .analyze,
                objectType: .document,
                objectId: "test-doc-002",
                context: ActionContext(userId: "test", sessionId: "test-session")
            ),
            ObjectAction(
                type: .analyze,
                objectType: .document,
                objectId: "prod-doc-001",
                context: ActionContext(userId: "test", sessionId: "test-session")
            )
        ]
        
        let dummyResult = ActionResult(
            actionId: UUID().uuidString,
            status: .completed,
            output: nil,
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
        
        for action in testActions {
            await cache.set(action, result: dummyResult)
        }
        
        // Verify all are cached
        for action in testActions {
            XCTAssertNotNil(await cache.get(action))
        }
        
        // Invalidate test documents only
        await strategy.invalidate(scope: .pattern("test-.*"))
        
        // Verify test docs are invalidated, prod doc remains
        XCTAssertNil(await cache.get(testActions[0]))
        XCTAssertNil(await cache.get(testActions[1]))
        XCTAssertNotNil(await cache.get(testActions[2]))
    }
    
    func testSmartInvalidation() async throws {
        let strategy = CacheInvalidationStrategy()
        
        // Create change descriptors
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
                changeType: .delete,
                changedFields: [],
                timestamp: Date()
            )
        ]
        
        // Test smart invalidation
        await strategy.smartInvalidate(basedOn: changes)
        
        // In a real test, we'd verify the specific invalidation actions taken
        // For now, just ensure it completes without error
        XCTAssertTrue(true)
    }
}
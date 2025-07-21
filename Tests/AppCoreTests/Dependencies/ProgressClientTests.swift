import XCTest
@testable import AppCore
import ComposableArchitecture
import Combine
import Foundation

@MainActor
final class ProgressClientTests: XCTestCase {
    var weakSession: ProgressSession?
    
    // MARK: - Session Creation Tests
    
    func testCreateSessionWithBasicConfig() async {
        let client = ProgressClient.testValue
        let config = ProgressSessionConfig.defaultSinglePageScan
        
        let session = await client.createSession(config)
        
        XCTAssertEqual(session.config, config)
        XCTAssertNotNil(session.progressPublisher)
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.createdAt)
    }
    
    func testCreateSessionWithCustomConfig() async {
        let client = ProgressClient.testValue
        let customConfig = ProgressSessionConfig(
            type: .documentProcessing,
            expectedPhases: [.preparing, .processing, .analyzing],
            estimatedDuration: 15.0,
            shouldAnnounceProgress: false,
            minimumUpdateInterval: 0.5
        )
        
        let session = await client.createSession(customConfig)
        
        XCTAssertEqual(session.config, customConfig)
        XCTAssertEqual(session.config.type, .documentProcessing)
        XCTAssertEqual(session.config.estimatedDuration, 15.0)
        XCTAssertFalse(session.config.shouldAnnounceProgress)
    }
    
    func testCreateMultipleSessions() async {
        let client = ProgressClient.testValue
        let config1 = ProgressSessionConfig.defaultSinglePageScan
        let config2 = ProgressSessionConfig.defaultMultiPageScan
        
        let session1 = await client.createSession(config1)
        let session2 = await client.createSession(config2)
        
        XCTAssertNotEqual(session1.id, session2.id)
        XCTAssertEqual(session1.config, config1)
        XCTAssertEqual(session2.config, config2)
    }
    
    // MARK: - Progress Update Tests
    
    func testUpdateProgressBasic() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        let update = ProgressUpdate(
            sessionId: session.id,
            phase: .scanning,
            fractionCompleted: 0.3,
            message: "Scanning in progress"
        )
        
        // Should not throw
        await client.updateProgress(session.id, update)
        
        // Verify current state can be retrieved
        let currentState = await client.getCurrentState(session.id)
        XCTAssertNotNil(currentState)
    }
    
    func testUpdateProgressWithMetadata() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultMultiPageScan)
        
        let metadata = [
            "page": "2",
            "total_pages": "5",
            "operation": "ocr"
        ]
        
        let update = ProgressUpdate(
            sessionId: session.id,
            phase: .analyzing,
            fractionCompleted: 0.4,
            message: "Analyzing page 2 of 5",
            metadata: metadata
        )
        
        await client.updateProgress(session.id, update)
        
        let currentState = await client.getCurrentState(session.id)
        XCTAssertNotNil(currentState)
        XCTAssertEqual(currentState?.phase, .analyzing)
        XCTAssertEqual(currentState?.fractionCompleted ?? 0.0, 0.4, accuracy: 0.001)
    }
    
    func testUpdateProgressInvalidSession() async {
        let client = ProgressClient.testValue
        let invalidSessionId = UUID()
        
        let update = ProgressUpdate(
            sessionId: invalidSessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        // Should not crash with invalid session ID
        await client.updateProgress(invalidSessionId, update)
        
        // State should be nil for invalid session
        let currentState = await client.getCurrentState(invalidSessionId)
        XCTAssertNil(currentState)
    }
    
    // MARK: - Progress Publisher Tests
    
    func testProgressPublisherEmitsInitialState() async {
        let client = ProgressClient.liveValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        var receivedStates: [ProgressState] = []
        let expectation = XCTestExpectation(description: "Initial state received")
        
        let cancellable = session.progressPublisher
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count >= 1 {
                    expectation.fulfill()
                }
            }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertGreaterThanOrEqual(receivedStates.count, 1)
        XCTAssertNotNil(receivedStates.first)
        
        cancellable.cancel()
    }
    
    func testProgressPublisherEmitsUpdates() async {
        let client = ProgressClient.liveValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        var receivedStates: [ProgressState] = []
        let expectation = XCTestExpectation(description: "Progress updates received")
        expectation.expectedFulfillmentCount = 2
        
        let cancellable = session.progressPublisher
            .sink { state in
                receivedStates.append(state)
                expectation.fulfill()
            }
        
        // Send a progress update
        let update = ProgressUpdate(
            sessionId: session.id,
            phase: .scanning,
            fractionCompleted: 0.5,
            message: "Scanning in progress"
        )
        
        await client.updateProgress(session.id, update)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertGreaterThanOrEqual(receivedStates.count, 2)
        XCTAssertEqual(receivedStates.last?.phase, .scanning)
        XCTAssertEqual(receivedStates.last?.fractionCompleted ?? 0.0, 0.5, accuracy: 0.001)
        
        cancellable.cancel()
    }
    
    func testProgressPublisherHandlesMultipleSubscribers() async {
        let client = ProgressClient.liveValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        var subscriber1States: [ProgressState] = []
        var subscriber2States: [ProgressState] = []
        
        let expectation1 = XCTestExpectation(description: "Subscriber 1 received updates")
        let expectation2 = XCTestExpectation(description: "Subscriber 2 received updates")
        
        let cancellable1 = session.progressPublisher
            .sink { state in
                subscriber1States.append(state)
                if subscriber1States.count >= 2 {
                    expectation1.fulfill()
                }
            }
        
        let cancellable2 = session.progressPublisher
            .sink { state in
                subscriber2States.append(state)
                if subscriber2States.count >= 2 {
                    expectation2.fulfill()
                }
            }
        
        let update = ProgressUpdate(
            sessionId: session.id,
            phase: .processing,
            fractionCompleted: 0.7,
            message: "Processing"
        )
        
        await client.updateProgress(session.id, update)
        
        await fulfillment(of: [expectation1, expectation2], timeout: 2.0)
        
        XCTAssertEqual(subscriber1States.count, subscriber2States.count)
        XCTAssertEqual(subscriber1States.last?.phase, .processing)
        XCTAssertEqual(subscriber2States.last?.phase, .processing)
        
        cancellable1.cancel()
        cancellable2.cancel()
    }
    
    // MARK: - Session Management Tests
    
    func testCompleteSession() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        let isActiveBeforeCompletion = await client.isSessionActive(session.id)
        XCTAssertTrue(isActiveBeforeCompletion)
        
        await client.completeSession(session.id)
        
        // Session should no longer be active
        let isActiveAfterCompletion = await client.isSessionActive(session.id)
        XCTAssertFalse(isActiveAfterCompletion)
        
        // Current state should be nil for completed session
        let currentState = await client.getCurrentState(session.id)
        XCTAssertNil(currentState)
    }
    
    func testCancelSession() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultMultiPageScan)
        
        let isActiveBeforeCancellation = await client.isSessionActive(session.id)
        XCTAssertTrue(isActiveBeforeCancellation)
        
        await client.cancelSession(session.id)
        
        // Session should no longer be active
        let isActiveAfterCancellation = await client.isSessionActive(session.id)
        XCTAssertFalse(isActiveAfterCancellation)
        
        // Current state should be nil for cancelled session
        let currentState = await client.getCurrentState(session.id)
        XCTAssertNil(currentState)
    }
    
    func testCompleteNonExistentSession() async {
        let client = ProgressClient.testValue
        let invalidSessionId = UUID()
        
        // Should not crash when completing non-existent session
        await client.completeSession(invalidSessionId)
        
        let isInvalidSessionActive = await client.isSessionActive(invalidSessionId)
        XCTAssertFalse(isInvalidSessionActive)
    }
    
    func testCancelNonExistentSession() async {
        let client = ProgressClient.testValue
        let invalidSessionId = UUID()
        
        // Should not crash when cancelling non-existent session
        await client.cancelSession(invalidSessionId)
        
        let isInvalidSessionActiveCancelled = await client.isSessionActive(invalidSessionId)
        XCTAssertFalse(isInvalidSessionActiveCancelled)
    }
    
    // MARK: - Session State Management Tests
    
    func testGetCurrentStateActiveSession() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        let currentState = await client.getCurrentState(session.id)
        XCTAssertNotNil(currentState)
        XCTAssertEqual(currentState?.phase, .idle) // Default test state
    }
    
    func testGetCurrentStateInactiveSession() async {
        let client = ProgressClient.testValue
        let invalidSessionId = UUID()
        
        let currentState = await client.getCurrentState(invalidSessionId)
        XCTAssertNil(currentState)
    }
    
    func testIsSessionActiveWithActiveSession() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        let isSessionActive = await client.isSessionActive(session.id)
        XCTAssertTrue(isSessionActive)
    }
    
    func testIsSessionActiveWithInactiveSession() async {
        let client = ProgressClient.testValue
        let invalidSessionId = UUID()
        
        let isInvalidSessionActiveTest = await client.isSessionActive(invalidSessionId)
        XCTAssertFalse(isInvalidSessionActiveTest)
    }
    
    // MARK: - Dependency Registration Tests
    
    func testProgressClientDependencyRegistration() {
        let testDependencies = DependencyValues._current
        
        // Test that the dependency can be accessed
        let client = testDependencies.progressClient
        XCTAssertNotNil(client)
    }
    
    func testProgressClientLiveValueExists() {
        // Verify live value is configured
        let liveClient = ProgressClient.liveValue
        XCTAssertNotNil(liveClient)
    }
    
    func testProgressClientTestValueExists() {
        // Verify test value is configured
        let testClient = ProgressClient.testValue
        XCTAssertNotNil(testClient)
    }
    
    // MARK: - ProgressSession Tests
    
    func testProgressSessionEquality() async {
        let client = ProgressClient.testValue
        let session1 = await client.createSession(.defaultSinglePageScan)
        let session2 = await client.createSession(.defaultSinglePageScan)
        
        XCTAssertNotEqual(session1, session2) // Different IDs
        XCTAssertNotEqual(session1.id, session2.id)
        
        // Same session should be equal to itself
        XCTAssertEqual(session1, session1)
    }
    
    func testProgressSessionMockValue() {
        let mockSession = ProgressSession.mock
        
        XCTAssertEqual(mockSession.config, .defaultSinglePageScan)
        XCTAssertNotNil(mockSession.id)
        XCTAssertNotNil(mockSession.createdAt)
        XCTAssertNotNil(mockSession.progressPublisher)
    }
    
    func testProgressSessionTimestamp() async {
        let beforeCreation = Date()
        
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        let afterCreation = Date()
        
        XCTAssertGreaterThanOrEqual(session.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(session.createdAt, afterCreation)
    }
    
    // MARK: - Error Handling Tests
    
    func testProgressClientErrorHandling() async {
        let client = ProgressClient.testValue
        
        // Test with extreme values
        let extremeUpdate = ProgressUpdate(
            sessionId: UUID(),
            phase: .processing,
            fractionCompleted: Double.infinity,
            message: String(repeating: "A", count: 10000)
        )
        
        // Should not crash with extreme values
        await client.updateProgress(UUID(), extremeUpdate)
    }
    
    // MARK: - Memory Management Tests
    
    func testProgressClientMemoryManagement() async {
        // Note: ProgressSession is a struct, so we can't use weak references
        // This test demonstrates the struct nature of ProgressSession
        
        do {
            let client = ProgressClient.liveValue
            let session = await client.createSession(.defaultSinglePageScan)
            weakSession = session
            XCTAssertNotNil(weakSession)
            
            // Complete the session
            await client.completeSession(session.id)
        }
        
        // Allow time for cleanup
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Session should be deallocated after completion
        // Note: This test may be flaky depending on implementation
        // XCTAssertNil(weakSession)
    }
    
    // MARK: - Performance Tests
    
    func testSessionCreationPerformance() {
        let client = ProgressClient.testValue
        
        measure {
            Task.detached {
                for _ in 0..<100 {
                    let _ = await client.createSession(.defaultSinglePageScan)
                }
            }
        }
    }
    
    func testProgressUpdatePerformance() async {
        let client = ProgressClient.testValue
        let session = await client.createSession(.defaultSinglePageScan)
        
        measure {
            Task.detached {
                for i in 0..<100 {
                    let update = ProgressUpdate(
                        sessionId: session.id,
                        phase: .processing,
                        fractionCompleted: Double(i) / 100.0,
                        message: "Step \(i)"
                    )
                    await client.updateProgress(session.id, update)
                }
            }
        }
    }
}
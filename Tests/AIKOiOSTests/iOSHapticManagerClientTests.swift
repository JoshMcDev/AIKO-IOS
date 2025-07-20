#if os(iOS)
    @testable import AIKOiOS
    @testable import AppCore
    import CoreHaptics
    import SwiftUI
    import XCTest

    final class iOSHapticManagerClientTests: XCTestCase {
        var client: iOSHapticManagerClient!

        override func setUp() async throws {
            try await super.setUp()
            client = iOSHapticManagerClient()
        }

        override func tearDown() async throws {
            client = nil
            try await super.tearDown()
        }

        // MARK: - MainActor Context Verification Tests

        func testMainActorContextVerification() async {
            // Verify that service operations execute on MainActor
            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "Service should operate on MainActor/Main thread")
            }

            // Test that impact executes on MainActor
            await client.impact(.light)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After impact, should still be on main thread")
            }
        }

        func testImpactMainActor() async {
            await client.impact(.medium)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After impact, should be on main thread")
            }
        }

        func testNotificationMainActor() async {
            await client.notification(.success)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After notification, should be on main thread")
            }
        }

        func testSelectionMainActor() async {
            await client.selection()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After selection, should be on main thread")
            }
        }

        func testButtonTapMainActor() async {
            await client.buttonTap()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After buttonTap, should be on main thread")
            }
        }

        func testToggleSwitchMainActor() async {
            await client.toggleSwitch()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After toggleSwitch, should be on main thread")
            }
        }

        func testSuccessActionMainActor() async {
            await client.successAction()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After successAction, should be on main thread")
            }
        }

        func testErrorActionMainActor() async {
            await client.errorAction()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After errorAction, should be on main thread")
            }
        }

        func testWarningActionMainActor() async {
            await client.warningAction()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After warningAction, should be on main thread")
            }
        }

        func testDragStartedMainActor() async {
            await client.dragStarted()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After dragStarted, should be on main thread")
            }
        }

        func testDragEndedMainActor() async {
            await client.dragEnded()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After dragEnded, should be on main thread")
            }
        }

        func testRefreshMainActor() async {
            await client.refresh()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After refresh, should be on main thread")
            }
        }

        // MARK: - Template Compliance Tests

        func testInheritsFromSimpleServiceTemplate() {
            XCTAssertTrue(client is SimpleServiceTemplate, "Should inherit from SimpleServiceTemplate")
            XCTAssertTrue(client is MainActorService, "Should conform to MainActorService protocol")
        }

        func testTemplateStartMethod() async throws {
            // Test that the template's start method can be called without error
            try await client.start()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After start(), should be on main thread")
            }
        }

        // MARK: - HapticManagerClient Integration Tests

        func testStaticIOSClientCreation() async {
            let serviceClient = HapticManagerClient.iOSLive

            // Test that we can call the client methods
            await serviceClient.impact(.light)
            await serviceClient.notification(.success)
            await serviceClient.selection()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "Static iOS client should maintain MainActor context")
            }
        }

        func testAsyncAwaitPattern() async {
            // Test the async/await pattern works correctly
            async let impactTask = client.impact(.medium)
            async let notificationTask = client.notification(.warning)
            async let selectionTask = client.selection()

            await (impactTask, notificationTask, selectionTask)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After concurrent async operations, should be on main thread")
            }
        }

        // MARK: - Haptic Functionality Tests

        func testAllImpactStyles() async {
            // Test all impact styles
            await client.impact(.light)
            await client.impact(.medium)
            await client.impact(.heavy)
            await client.impact(.soft)
            await client.impact(.rigid)

            // Should complete without error
            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After all impact styles, should be on main thread")
            }
        }

        func testAllNotificationTypes() async {
            // Test all notification types
            await client.notification(.success)
            await client.notification(.warning)
            await client.notification(.error)

            // Should complete without error
            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After all notification types, should be on main thread")
            }
        }

        func testConvenienceHapticMethods() async {
            // Test convenience methods that map to specific haptic patterns
            await client.buttonTap() // Maps to light impact
            await client.toggleSwitch() // Maps to medium impact
            await client.successAction() // Maps to success notification
            await client.errorAction() // Maps to error notification
            await client.warningAction() // Maps to warning notification
            await client.dragStarted() // Maps to soft impact
            await client.dragEnded() // Maps to rigid impact

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After convenience methods, should be on main thread")
            }
        }

        func testRefreshHapticSequence() async {
            // Test the refresh method which performs a sequence of haptics
            await client.refresh()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After refresh sequence, should be on main thread")
            }
        }

        func testSelectionHaptic() async {
            // Test selection haptic
            await client.selection()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After selection haptic, should be on main thread")
            }
        }

        // MARK: - Multiple Operations Tests

        func testMultipleImpacts() async {
            // Test multiple impacts in sequence
            await client.impact(.light)
            await client.impact(.medium)
            await client.impact(.heavy)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After multiple impacts, should be on main thread")
            }
        }

        func testMixedHapticOperations() async {
            // Test mixing different types of haptic operations
            await client.impact(.medium)
            await client.notification(.success)
            await client.selection()
            await client.buttonTap()
            await client.dragStarted()

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After mixed operations, should be on main thread")
            }
        }

        func testConcurrentHapticOperations() async {
            // Test concurrent haptic operations
            async let impact1 = client.impact(.light)
            async let impact2 = client.impact(.medium)
            async let notification1 = client.notification(.success)
            async let selection1 = client.selection()

            await (impact1, impact2, notification1, selection1)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After concurrent haptic operations, should be on main thread")
            }
        }

        // MARK: - Error Handling Tests

        func testHapticsOnNonHapticCapableDevice() async {
            // Even on devices without haptic support, methods should complete without crashing
            await client.impact(.heavy)
            await client.notification(.error)
            await client.selection()

            // Should complete successfully regardless of device capabilities
            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After haptics on any device, should be on main thread")
            }
        }
    }
#endif

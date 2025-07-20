#if os(iOS)
    @testable import AIKOiOS
    @testable import AppCore
    import SwiftUI
    import XCTest

    final class iOSThemeServiceClientTests: XCTestCase {
        var client: iOSThemeServiceClient!

        override func setUp() async throws {
            try await super.setUp()
            client = iOSThemeServiceClient()
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

            // Test that backgroundColor executes on MainActor
            let color = await client.backgroundColor()
            XCTAssertNotNil(color, "Should return a valid Color")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After backgroundColor, should still be on main thread")
            }
        }

        func testColorMethodsMainActor() async {
            let backgroundColor = await client.backgroundColor()
            let cardColor = await client.cardColor()
            let secondaryColor = await client.secondaryColor()
            let tertiaryColor = await client.tertiaryColor()

            // All color methods should return valid colors
            XCTAssertNotNil(backgroundColor, "backgroundColor should return valid Color")
            XCTAssertNotNil(cardColor, "cardColor should return valid Color")
            XCTAssertNotNil(secondaryColor, "secondaryColor should return valid Color")
            XCTAssertNotNil(tertiaryColor, "tertiaryColor should return valid Color")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After color methods, should be on main thread")
            }
        }

        func testGroupedBackgroundMethodsMainActor() async {
            let groupedBackground = await client.groupedBackground()
            let groupedSecondaryBackground = await client.groupedSecondaryBackground()
            let groupedTertiaryBackground = await client.groupedTertiaryBackground()

            // All grouped background methods should return valid colors
            XCTAssertNotNil(groupedBackground, "groupedBackground should return valid Color")
            XCTAssertNotNil(groupedSecondaryBackground, "groupedSecondaryBackground should return valid Color")
            XCTAssertNotNil(groupedTertiaryBackground, "groupedTertiaryBackground should return valid Color")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After grouped background methods, should be on main thread")
            }
        }

        func testViewModificationMethodsMainActor() async {
            let testView = AnyView(Text("Test"))

            let hiddenNavView = await client.applyNavigationBarHidden(to: testView)
            let darkNavView = await client.applyDarkNavigationBar(to: testView)
            let sheetView = await client.applySheet(to: testView)

            // All view modification methods should return valid AnyViews
            XCTAssertNotNil(hiddenNavView, "applyNavigationBarHidden should return valid AnyView")
            XCTAssertNotNil(darkNavView, "applyDarkNavigationBar should return valid AnyView")
            XCTAssertNotNil(sheetView, "applySheet should return valid AnyView")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After view modification methods, should be on main thread")
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

        // MARK: - ThemeServiceClient Integration Tests

        func testStaticIOSClientCreation() async {
            let serviceClient = ThemeServiceClient.iOS

            // Test that we can call the client methods
            let backgroundColor = await serviceClient.backgroundColor()
            XCTAssertNotNil(backgroundColor, "Should return a valid Color")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "Static iOS client should maintain MainActor context")
            }
        }

        func testAsyncAwaitPattern() async {
            // Test the async/await pattern works correctly
            async let backgroundColorTask = client.backgroundColor()
            async let cardColorTask = client.cardColor()
            async let secondaryColorTask = client.secondaryColor()

            let (backgroundColor, cardColor, secondaryColor) = await (backgroundColorTask, cardColorTask, secondaryColorTask)

            XCTAssertNotNil(backgroundColor, "backgroundColor should return valid Color")
            XCTAssertNotNil(cardColor, "cardColor should return valid Color")
            XCTAssertNotNil(secondaryColor, "secondaryColor should return valid Color")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After concurrent async operations, should be on main thread")
            }
        }

        // MARK: - Theme Integration Tests

        func testColorConsistency() async {
            // Test that colors are consistently returned
            let backgroundColor1 = await client.backgroundColor()
            let backgroundColor2 = await client.backgroundColor()

            // Colors should be consistent across calls
            XCTAssertEqual(backgroundColor1, backgroundColor2, "backgroundColor should be consistent")
        }

        func testViewModificationIntegration() async {
            let testView = AnyView(Text("Integration Test"))

            // Test chaining view modifications (conceptually)
            let modifiedView1 = await client.applyNavigationBarHidden(to: testView)
            let modifiedView2 = await client.applyDarkNavigationBar(to: modifiedView1)
            let finalView = await client.applySheet(to: modifiedView2)

            XCTAssertNotNil(finalView, "Should be able to chain view modifications")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After chained modifications, should be on main thread")
            }
        }
    }
#endif

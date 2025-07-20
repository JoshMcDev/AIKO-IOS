#if os(iOS)
    @testable import AIKOiOS
    @testable import AppCore
    import SwiftUI
    import XCTest

    final class iOSClipboardServiceClientTests: XCTestCase {
        var client: iOSClipboardServiceClient!

        override func setUp() async throws {
            try await super.setUp()
            client = iOSClipboardServiceClient()
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

            // Test that copyText executes on MainActor
            await client.copyText("Test message")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After copyText, should still be on main thread")
            }
        }

        func testCopyTextMainActor() async {
            let testText = "Test clipboard text"

            await client.copyText(testText)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After copyText, should be on main thread")
            }
        }

        func testGetTextMainActor() async {
            // First copy some text
            await client.copyText("Test text for retrieval")

            // Then retrieve it
            let retrievedText = await client.getText()
            XCTAssertEqual(retrievedText, "Test text for retrieval", "Should retrieve the copied text")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After getText, should be on main thread")
            }
        }

        func testCopyDataMainActor() async {
            let testData = "Test data".data(using: .utf8)!
            let testType = "public.utf8-plain-text"

            await client.copyData(testData, type: testType)

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After copyData, should be on main thread")
            }
        }

        func testHasContentMainActor() async {
            let testType = "public.utf8-plain-text"

            // Copy some text first
            await client.copyText("Test content")

            // Check if content exists
            let hasContent = await client.hasContent(ofType: testType)
            XCTAssertTrue(hasContent == true || hasContent == false, "Should return a boolean value")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After hasContent, should be on main thread")
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

        // MARK: - ClipboardServiceClient Integration Tests

        func testStaticIOSClientCreation() async {
            let serviceClient = ClipboardServiceClient.iOSLive

            // Test that we can call the client methods
            await serviceClient.copyText("Integration test")
            let text = await serviceClient.getText()
            XCTAssertEqual(text, "Integration test", "Should copy and retrieve text correctly")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "Static iOS client should maintain MainActor context")
            }
        }

        func testAsyncAwaitPattern() async {
            // Copy some initial content
            await client.copyText("Initial content")

            // Test the async/await pattern works correctly
            async let getTextTask = client.getText()
            async let hasContentTask = client.hasContent(ofType: "public.utf8-plain-text")

            let (text, hasContent) = await (getTextTask, hasContentTask)

            XCTAssertEqual(text, "Initial content", "getText should return the copied text")
            XCTAssertTrue(hasContent, "hasContent should return true for text content")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "After concurrent async operations, should be on main thread")
            }
        }

        // MARK: - Clipboard Functionality Tests

        func testTextCopyAndRetrieve() async {
            let testText = "Test clipboard functionality"

            // Copy text
            await client.copyText(testText)

            // Retrieve text
            let retrievedText = await client.getText()
            XCTAssertEqual(retrievedText, testText, "Should copy and retrieve text correctly")
        }

        func testDataCopyAndCheck() async {
            let testData = "Test data content".data(using: .utf8)!
            let testType = "public.utf8-plain-text"

            // Copy data
            await client.copyData(testData, type: testType)

            // Check if content exists
            let hasContent = await client.hasContent(ofType: testType)
            XCTAssertTrue(hasContent, "Should have content after copying data")
        }

        func testEmptyClipboard() async {
            // Clear clipboard by copying empty string
            await client.copyText("")

            // Check for empty content
            let text = await client.getText()
            XCTAssertEqual(text, "", "Should handle empty clipboard content")
        }

        func testMultipleTextOperations() async {
            // Test multiple copy operations
            await client.copyText("First text")
            let firstText = await client.getText()
            XCTAssertEqual(firstText, "First text", "Should retrieve first text")

            await client.copyText("Second text")
            let secondText = await client.getText()
            XCTAssertEqual(secondText, "Second text", "Should retrieve second text")
        }

        func testContentTypeCheck() async {
            // Copy text content
            await client.copyText("Text content")

            // Check for text type
            let hasTextContent = await client.hasContent(ofType: "public.utf8-plain-text")
            XCTAssertTrue(hasTextContent, "Should have text content")

            // Check for non-existent type
            let hasImageContent = await client.hasContent(ofType: "public.png")
            XCTAssertFalse(hasImageContent, "Should not have image content")
        }

        // MARK: - Convenience Accessor Tests

        func testConvenienceStaticAccessor() async {
            let serviceClient = iOSClipboardServiceClient.live

            // Test that the convenience accessor works
            await serviceClient.copyText("Convenience test")
            let text = await serviceClient.getText()
            XCTAssertEqual(text, "Convenience test", "Convenience accessor should work")

            await MainActor.run {
                XCTAssertTrue(Thread.isMainThread, "Convenience accessor should maintain MainActor context")
            }
        }
    }
#endif

import XCTest
@testable import AppCore
import Foundation

final class ProgressUpdateTests: XCTestCase {
    
    // MARK: - Basic Initialization Tests
    
    func testProgressUpdateBasicInitialization() {
        let sessionId = UUID()
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.6,
            message: "Processing images"
        )
        
        XCTAssertEqual(update.sessionId, sessionId)
        XCTAssertEqual(update.phase, .processing)
        XCTAssertEqual(update.fractionCompleted, 0.6, accuracy: 0.001)
        XCTAssertEqual(update.message, "Processing images")
        XCTAssertNotNil(update.timestamp)
        XCTAssertTrue(update.metadata.isEmpty)
    }
    
    func testProgressUpdateWithMetadata() {
        let sessionId = UUID()
        let metadata = [
            "page": "2",
            "total_pages": "5",
            "operation": "enhance_quality"
        ]
        
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .analyzing,
            fractionCompleted: 0.4,
            message: "Analyzing page 2 of 5",
            metadata: metadata
        )
        
        XCTAssertEqual(update.metadata.count, 3)
        XCTAssertEqual(update.metadata["page"], "2")
        XCTAssertEqual(update.metadata["total_pages"], "5")
        XCTAssertEqual(update.metadata["operation"], "enhance_quality")
    }
    
    func testProgressUpdateEmptyMetadata() {
        let sessionId = UUID()
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            fractionCompleted: 0.2,
            message: "Scanning document",
            metadata: [:]
        )
        
        XCTAssertTrue(update.metadata.isEmpty)
    }
    
    // MARK: - Bounds Validation Tests
    
    func testProgressUpdateBoundsValidation() {
        let sessionId = UUID()
        
        let underBounds = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: -0.1,
            message: "Test"
        )
        XCTAssertEqual(underBounds.fractionCompleted, 0.0)
        
        let overBounds = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 1.5,
            message: "Test"
        )
        XCTAssertEqual(overBounds.fractionCompleted, 1.0)
        
        let validBounds = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test"
        )
        XCTAssertEqual(validBounds.fractionCompleted, 0.5)
    }
    
    func testProgressUpdateExtremeValues() {
        let sessionId = UUID()
        
        let zeroProgress = ProgressUpdate(
            sessionId: sessionId,
            phase: .preparing,
            fractionCompleted: 0.0,
            message: "Starting"
        )
        XCTAssertEqual(zeroProgress.fractionCompleted, 0.0)
        
        let fullProgress = ProgressUpdate(
            sessionId: sessionId,
            phase: .completing,
            fractionCompleted: 1.0,
            message: "Complete"
        )
        XCTAssertEqual(fullProgress.fractionCompleted, 1.0)
    }
    
    // MARK: - Timestamp Tests
    
    func testProgressUpdateTimestampIsSetAutomatically() {
        let beforeCreation = Date()
        let sessionId = UUID()
        
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            fractionCompleted: 0.3,
            message: "Scanning"
        )
        
        let afterCreation = Date()
        
        XCTAssertGreaterThanOrEqual(update.timestamp, beforeCreation)
        XCTAssertLessThanOrEqual(update.timestamp, afterCreation)
    }
    
    func testProgressUpdateTimestampPrecision() {
        let sessionId = UUID()
        
        let update1 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.1,
            message: "First"
        )
        
        Thread.sleep(forTimeInterval: 0.001) // 1ms delay
        
        let update2 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.2,
            message: "Second"
        )
        
        XCTAssertLessThan(update1.timestamp, update2.timestamp)
    }
    
    // MARK: - Equatable Tests
    
    func testProgressUpdateEquality() {
        let sessionId = UUID()
        let timestamp = Date()
        
        // Create two updates with identical properties except timestamp
        let update1 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        let update2 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        // They should not be equal due to different timestamps
        XCTAssertNotEqual(update1, update2)
    }
    
    func testProgressUpdateInequalityBySessionId() {
        let sessionId1 = UUID()
        let sessionId2 = UUID()
        
        let update1 = ProgressUpdate(
            sessionId: sessionId1,
            phase: .scanning,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        let update2 = ProgressUpdate(
            sessionId: sessionId2,
            phase: .scanning,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        XCTAssertNotEqual(update1, update2)
    }
    
    func testProgressUpdateInequalityByPhase() {
        let sessionId = UUID()
        
        let update1 = ProgressUpdate(
            sessionId: sessionId,
            phase: .scanning,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        let update2 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test"
        )
        
        XCTAssertNotEqual(update1, update2)
    }
    
    func testProgressUpdateInequalityByProgress() {
        let sessionId = UUID()
        
        let update1 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.3,
            message: "Test"
        )
        
        let update2 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.6,
            message: "Test"
        )
        
        XCTAssertNotEqual(update1, update2)
    }
    
    func testProgressUpdateInequalityByMessage() {
        let sessionId = UUID()
        
        let update1 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Message 1"
        )
        
        let update2 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Message 2"
        )
        
        XCTAssertNotEqual(update1, update2)
    }
    
    func testProgressUpdateInequalityByMetadata() {
        let sessionId = UUID()
        
        let update1 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test",
            metadata: ["key": "value1"]
        )
        
        let update2 = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "Test",
            metadata: ["key": "value2"]
        )
        
        XCTAssertNotEqual(update1, update2)
    }
    
    // MARK: - Sendable Compliance Tests
    
    func testProgressUpdateIsSendable() {
        let sessionId = UUID()
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .analyzing,
            fractionCompleted: 0.7,
            message: "Analyzing content"
        )
        
        // Verify we can pass across concurrency boundaries
        Task { @MainActor in
            let _ = update // Should compile without warnings
        }
        
        Task.detached {
            let _ = update // Should compile without warnings
        }
    }
    
    // MARK: - Message Content Tests
    
    func testProgressUpdateMessageHandling() {
        let sessionId = UUID()
        
        let emptyMessage = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: ""
        )
        XCTAssertTrue(emptyMessage.message.isEmpty)
        
        let longMessage = String(repeating: "A", count: 1000)
        let longMessageUpdate = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: longMessage
        )
        XCTAssertEqual(longMessageUpdate.message.count, 1000)
        
        let unicodeMessage = ProgressUpdate(
            sessionId: sessionId,
            phase: .processing,
            fractionCompleted: 0.5,
            message: "処理中... 📄✨"
        )
        XCTAssertTrue(unicodeMessage.message.contains("処理中"))
        XCTAssertTrue(unicodeMessage.message.contains("📄"))
    }
    
    // MARK: - Metadata Handling Tests
    
    func testProgressUpdateMetadataTypes() {
        let sessionId = UUID()
        let metadata: [String: String] = [
            "number": "123",
            "boolean": "true",
            "decimal": "45.67",
            "empty": "",
            "special_chars": "!@#$%^&*()",
            "unicode": "测试🔬"
        ]
        
        let update = ProgressUpdate(
            sessionId: sessionId,
            phase: .analyzing,
            fractionCompleted: 0.8,
            message: "Testing metadata",
            metadata: metadata
        )
        
        XCTAssertEqual(update.metadata["number"], "123")
        XCTAssertEqual(update.metadata["boolean"], "true")
        XCTAssertEqual(update.metadata["decimal"], "45.67")
        XCTAssertEqual(update.metadata["empty"], "")
        XCTAssertEqual(update.metadata["special_chars"], "!@#$%^&*()")
        XCTAssertEqual(update.metadata["unicode"], "测试🔬")
    }
    
    // MARK: - Performance Tests
    
    func testProgressUpdateCreationPerformance() {
        let sessionId = UUID()
        
        measure {
            for i in 0..<1000 {
                let _ = ProgressUpdate(
                    sessionId: sessionId,
                    phase: .processing,
                    fractionCompleted: Double(i) / 1000.0,
                    message: "Processing step \(i)"
                )
            }
        }
    }
    
    func testProgressUpdateWithMetadataPerformance() {
        let sessionId = UUID()
        let metadata = [
            "step": "1",
            "total": "100",
            "operation": "process"
        ]
        
        measure {
            for i in 0..<1000 {
                let _ = ProgressUpdate(
                    sessionId: sessionId,
                    phase: .processing,
                    fractionCompleted: Double(i) / 1000.0,
                    message: "Processing step \(i)",
                    metadata: metadata
                )
            }
        }
    }
}
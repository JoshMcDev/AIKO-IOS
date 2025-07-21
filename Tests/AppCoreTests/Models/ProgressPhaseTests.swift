import XCTest
@testable import AppCore
import Foundation

final class ProgressPhaseTests: XCTestCase {
    
    // MARK: - Basic Enum Tests
    
    func testAllProgressPhaseCases() {
        let allCases = ProgressPhase.allCases
        let expectedCases: [ProgressPhase] = [.preparing, .scanning, .processing, .analyzing, .completing, .idle]
        
        XCTAssertEqual(allCases.count, expectedCases.count)
        for expectedCase in expectedCases {
            XCTAssertTrue(allCases.contains(expectedCase))
        }
    }
    
    func testProgressPhaseRawValues() {
        XCTAssertEqual(ProgressPhase.preparing.rawValue, "preparing")
        XCTAssertEqual(ProgressPhase.scanning.rawValue, "scanning")
        XCTAssertEqual(ProgressPhase.processing.rawValue, "processing")
        XCTAssertEqual(ProgressPhase.analyzing.rawValue, "analyzing")
        XCTAssertEqual(ProgressPhase.completing.rawValue, "completing")
        XCTAssertEqual(ProgressPhase.idle.rawValue, "idle")
    }
    
    func testProgressPhaseInitFromRawValue() {
        XCTAssertEqual(ProgressPhase(rawValue: "preparing"), .preparing)
        XCTAssertEqual(ProgressPhase(rawValue: "scanning"), .scanning)
        XCTAssertEqual(ProgressPhase(rawValue: "processing"), .processing)
        XCTAssertEqual(ProgressPhase(rawValue: "analyzing"), .analyzing)
        XCTAssertEqual(ProgressPhase(rawValue: "completing"), .completing)
        XCTAssertEqual(ProgressPhase(rawValue: "idle"), .idle)
        XCTAssertNil(ProgressPhase(rawValue: "invalid"))
    }
    
    // MARK: - Display Name Tests
    
    func testProgressPhaseDisplayNames() {
        XCTAssertEqual(ProgressPhase.preparing.displayName, "Preparing")
        XCTAssertEqual(ProgressPhase.scanning.displayName, "Scanning")
        XCTAssertEqual(ProgressPhase.processing.displayName, "Processing")
        XCTAssertEqual(ProgressPhase.analyzing.displayName, "Analyzing")
        XCTAssertEqual(ProgressPhase.completing.displayName, "Completing")
        XCTAssertEqual(ProgressPhase.idle.displayName, "Ready")
    }
    
    func testDisplayNamesAreUserFriendly() {
        for phase in ProgressPhase.allCases {
            let displayName = phase.displayName
            XCTAssertFalse(displayName.isEmpty, "Display name should not be empty for \(phase)")
            XCTAssertTrue(displayName.first?.isUppercase == true, "Display name should start with capital letter for \(phase)")
            XCTAssertFalse(displayName.contains("_"), "Display name should not contain underscores for \(phase)")
        }
    }
    
    // MARK: - Accessibility Description Tests
    
    func testProgressPhaseAccessibilityDescriptions() {
        XCTAssertEqual(ProgressPhase.preparing.accessibilityDescription, "Preparing document scan")
        XCTAssertEqual(ProgressPhase.scanning.accessibilityDescription, "Scanning document pages")
        XCTAssertEqual(ProgressPhase.processing.accessibilityDescription, "Processing scanned images")
        XCTAssertEqual(ProgressPhase.analyzing.accessibilityDescription, "Analyzing document content")
        XCTAssertEqual(ProgressPhase.completing.accessibilityDescription, "Finalizing results")
        XCTAssertEqual(ProgressPhase.idle.accessibilityDescription, "Scanner ready")
    }
    
    func testAccessibilityDescriptionsAreDescriptive() {
        for phase in ProgressPhase.allCases {
            let description = phase.accessibilityDescription
            XCTAssertFalse(description.isEmpty, "Accessibility description should not be empty for \(phase)")
            XCTAssertGreaterThan(description.count, phase.displayName.count, "Accessibility description should be more detailed than display name for \(phase)")
        }
    }
    
    func testAccessibilityDescriptionsFollowVoiceOverBestPractices() {
        for phase in ProgressPhase.allCases {
            let description = phase.accessibilityDescription
            // Should not end with punctuation for better VoiceOver flow
            XCTAssertFalse(description.hasSuffix("."), "Accessibility description should not end with period for \(phase)")
            XCTAssertFalse(description.hasSuffix("!"), "Accessibility description should not end with exclamation for \(phase)")
            // Should be in present tense for active operations
            if phase != .idle {
                XCTAssertTrue(description.contains("ing"), "Active phases should use present continuous tense for \(phase)")
            }
        }
    }
    
    // MARK: - System Image Name Tests
    
    func testProgressPhaseSystemImageNames() {
        XCTAssertEqual(ProgressPhase.preparing.systemImageName, "gearshape")
        XCTAssertEqual(ProgressPhase.scanning.systemImageName, "doc.viewfinder")
        XCTAssertEqual(ProgressPhase.processing.systemImageName, "cpu")
        XCTAssertEqual(ProgressPhase.analyzing.systemImageName, "magnifyingglass")
        XCTAssertEqual(ProgressPhase.completing.systemImageName, "checkmark.circle")
        XCTAssertEqual(ProgressPhase.idle.systemImageName, "circle")
    }
    
    func testSystemImageNamesAreValid() {
        for phase in ProgressPhase.allCases {
            let imageName = phase.systemImageName
            XCTAssertFalse(imageName.isEmpty, "System image name should not be empty for \(phase)")
            XCTAssertFalse(imageName.contains(" "), "System image name should not contain spaces for \(phase)")
            // All provided names should be valid SF Symbols
            XCTAssertTrue(isValidSFSymbolName(imageName), "System image name should be valid SF Symbol for \(phase)")
        }
    }
    
    func testSystemImageNamesAreSemanticallAppropriate() {
        // Test that the image names make sense for their phases
        XCTAssertTrue(ProgressPhase.preparing.systemImageName.contains("gear"), "Preparing should use gear-related icon")
        XCTAssertTrue(ProgressPhase.scanning.systemImageName.contains("doc"), "Scanning should use document-related icon")
        XCTAssertTrue(ProgressPhase.processing.systemImageName.contains("cpu"), "Processing should use processing-related icon")
        XCTAssertTrue(ProgressPhase.analyzing.systemImageName.contains("magnify"), "Analyzing should use magnification-related icon")
        XCTAssertTrue(ProgressPhase.completing.systemImageName.contains("check"), "Completing should use completion-related icon")
        XCTAssertEqual(ProgressPhase.idle.systemImageName, "circle", "Idle should use neutral icon")
    }
    
    // MARK: - Equatable and Sendable Tests
    
    func testProgressPhaseEquality() {
        XCTAssertEqual(ProgressPhase.scanning, ProgressPhase.scanning)
        XCTAssertNotEqual(ProgressPhase.scanning, ProgressPhase.processing)
        
        let phase1 = ProgressPhase.processing
        let phase2 = ProgressPhase.processing
        XCTAssertEqual(phase1, phase2)
    }
    
    func testProgressPhaseIsSendable() {
        let phase = ProgressPhase.scanning
        
        // Verify we can pass across concurrency boundaries
        Task { @MainActor in
            let _ = phase // Should compile without warnings
        }
        
        Task.detached {
            let _ = phase // Should compile without warnings
        }
    }
    
    // MARK: - Performance Tests
    
    func testDisplayNamePerformance() {
        let phase = ProgressPhase.processing
        
        measure {
            for _ in 0..<1000 {
                let _ = phase.displayName
            }
        }
    }
    
    func testAccessibilityDescriptionPerformance() {
        let phase = ProgressPhase.analyzing
        
        measure {
            for _ in 0..<1000 {
                let _ = phase.accessibilityDescription
            }
        }
    }
    
    func testSystemImageNamePerformance() {
        let phase = ProgressPhase.completing
        
        measure {
            for _ in 0..<1000 {
                let _ = phase.systemImageName
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testAllCasesIteration() {
        var count = 0
        for phase in ProgressPhase.allCases {
            count += 1
            // Each phase should have valid computed properties
            XCTAssertFalse(phase.displayName.isEmpty)
            XCTAssertFalse(phase.accessibilityDescription.isEmpty)
            XCTAssertFalse(phase.systemImageName.isEmpty)
        }
        XCTAssertEqual(count, 6) // Should match expected number of phases
    }
    
    // MARK: - Helper Methods
    
    private func isValidSFSymbolName(_ name: String) -> Bool {
        // Basic validation for SF Symbol names
        let validSymbols = [
            "gearshape", "doc.viewfinder", "cpu", "magnifyingglass", 
            "checkmark.circle", "circle"
        ]
        return validSymbols.contains(name)
    }
}
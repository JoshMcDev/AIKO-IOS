import XCTest
@testable import AppCore
import Foundation

final class ProgressStateTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testProgressStateBasicInitialization() {
        let state = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Scanning page 1"
        )
        
        XCTAssertEqual(state.phase, .scanning)
        XCTAssertEqual(state.fractionCompleted, 0.5, accuracy: 0.001)
        XCTAssertEqual(state.currentStep, "Scanning page 1")
        XCTAssertNotNil(state.id)
        XCTAssertNotNil(state.timestamp)
    }
    
    func testProgressStateFullInitialization() {
        let state = ProgressState(
            phase: .processing,
            fractionCompleted: 0.75,
            currentStep: "Enhancing image quality",
            totalSteps: 4,
            currentStepIndex: 2,
            estimatedTimeRemaining: 30.0
        )
        
        XCTAssertEqual(state.totalSteps, 4)
        XCTAssertEqual(state.currentStepIndex, 2)
        XCTAssertEqual(state.estimatedTimeRemaining ?? 0.0, 30.0, accuracy: 0.1)
    }
    
    func testProgressStateDefaults() {
        let state = ProgressState(
            phase: .idle,
            fractionCompleted: 0.0,
            currentStep: "Ready"
        )
        
        XCTAssertEqual(state.totalSteps, 1)
        XCTAssertEqual(state.currentStepIndex, 0)
        XCTAssertNil(state.estimatedTimeRemaining)
    }
    
    // MARK: - Bounds Validation Tests
    
    func testProgressStateBoundsValidation() {
        let underBounds = ProgressState(
            phase: .scanning,
            fractionCompleted: -0.1,
            currentStep: "Test"
        )
        XCTAssertEqual(underBounds.fractionCompleted, 0.0)
        
        let overBounds = ProgressState(
            phase: .scanning,
            fractionCompleted: 1.5,
            currentStep: "Test"
        )
        XCTAssertEqual(overBounds.fractionCompleted, 1.0)
        
        let validBounds = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Test"
        )
        XCTAssertEqual(validBounds.fractionCompleted, 0.5)
    }
    
    func testTotalStepsValidation() {
        let invalidSteps = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Test",
            totalSteps: 0
        )
        XCTAssertEqual(invalidSteps.totalSteps, 1)
        
        let negativeSteps = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Test",
            totalSteps: -5
        )
        XCTAssertEqual(negativeSteps.totalSteps, 1)
    }
    
    func testCurrentStepIndexValidation() {
        let negativeIndex = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Test",
            totalSteps: 3,
            currentStepIndex: -1
        )
        XCTAssertEqual(negativeIndex.currentStepIndex, 0)
        
        let overIndex = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Test",
            totalSteps: 3,
            currentStepIndex: 5
        )
        XCTAssertEqual(overIndex.currentStepIndex, 2) // totalSteps - 1
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabelGeneration() {
        let state = ProgressState(
            phase: .processing,
            fractionCompleted: 0.75,
            currentStep: "Enhancing image quality"
        )
        
        XCTAssertTrue(state.accessibilityLabel.contains("Processing"))
        XCTAssertTrue(state.accessibilityLabel.contains("75"))
        XCTAssertTrue(state.accessibilityLabel.contains("complete"))
        XCTAssertTrue(state.accessibilityLabel.contains("Enhancing image quality"))
    }
    
    func testAccessibilityLabelForDifferentPhases() {
        let phases: [(ProgressPhase, String)] = [
            (.preparing, "Preparing"),
            (.scanning, "Scanning"),
            (.processing, "Processing"),
            (.analyzing, "Analyzing"),
            (.completing, "Completing"),
            (.idle, "Ready")
        ]
        
        for (phase, expectedText) in phases {
            let state = ProgressState(
                phase: phase,
                fractionCompleted: 0.5,
                currentStep: "Test step"
            )
            XCTAssertTrue(state.accessibilityLabel.contains(expectedText))
        }
    }
    
    func testAccessibilityLabelProgressPercentages() {
        let percentages = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for percentage in percentages {
            let state = ProgressState(
                phase: .processing,
                fractionCompleted: percentage,
                currentStep: "Test"
            )
            let expectedPercent = Int(percentage * 100)
            XCTAssertTrue(state.accessibilityLabel.contains("\(expectedPercent)"))
        }
    }
    
    // MARK: - Equatable Tests
    
    func testProgressStateEquality() {
        let state1 = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Test"
        )
        
        let state2 = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Test"
        )
        
        // Should not be equal because IDs are different
        XCTAssertNotEqual(state1, state2)
        XCTAssertNotEqual(state1.id, state2.id)
    }
    
    func testProgressStateInequalityByPhase() {
        let state1 = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Test"
        )
        
        let state2 = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Test"
        )
        
        XCTAssertNotEqual(state1, state2)
    }
    
    // MARK: - Sendable Compliance Tests
    
    func testProgressStateIsSendable() {
        let state = ProgressState(
            phase: .scanning,
            fractionCompleted: 0.5,
            currentStep: "Test"
        )
        
        // Verify we can pass across concurrency boundaries
        Task { @MainActor in
            let _ = state // Should compile without warnings
        }
        
        Task.detached {
            let _ = state // Should compile without warnings
        }
    }
    
    // MARK: - Performance Tests
    
    func testProgressStateInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = ProgressState(
                    phase: .processing,
                    fractionCompleted: Double.random(in: 0...1),
                    currentStep: "Performance test step",
                    totalSteps: Int.random(in: 1...10),
                    currentStepIndex: Int.random(in: 0...9),
                    estimatedTimeRemaining: Double.random(in: 0...100)
                )
            }
        }
    }
    
    func testAccessibilityLabelPerformance() {
        let state = ProgressState(
            phase: .processing,
            fractionCompleted: 0.5,
            currentStep: "Performance test"
        )
        
        measure {
            for _ in 0..<1000 {
                let _ = state.accessibilityLabel
            }
        }
    }
}
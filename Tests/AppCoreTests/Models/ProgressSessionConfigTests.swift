import XCTest
@testable import AppCore
import Foundation

final class ProgressSessionConfigTests: XCTestCase {
    
    // MARK: - SessionType Tests
    
    func testSessionTypeRawValues() {
        XCTAssertEqual(ProgressSessionConfig.SessionType.singlePageScan.rawValue, "single_page_scan")
        XCTAssertEqual(ProgressSessionConfig.SessionType.multiPageScan.rawValue, "multi_page_scan")
        XCTAssertEqual(ProgressSessionConfig.SessionType.documentProcessing.rawValue, "document_processing")
        XCTAssertEqual(ProgressSessionConfig.SessionType.formAnalysis.rawValue, "form_analysis")
    }
    
    func testSessionTypeInitFromRawValue() {
        XCTAssertEqual(ProgressSessionConfig.SessionType(rawValue: "single_page_scan"), .singlePageScan)
        XCTAssertEqual(ProgressSessionConfig.SessionType(rawValue: "multi_page_scan"), .multiPageScan)
        XCTAssertEqual(ProgressSessionConfig.SessionType(rawValue: "document_processing"), .documentProcessing)
        XCTAssertEqual(ProgressSessionConfig.SessionType(rawValue: "form_analysis"), .formAnalysis)
        XCTAssertNil(ProgressSessionConfig.SessionType(rawValue: "invalid_type"))
    }
    
    func testSessionTypeIsSendable() {
        let sessionType = ProgressSessionConfig.SessionType.multiPageScan
        
        // Verify we can pass across concurrency boundaries
        Task { @MainActor in
            let _ = sessionType // Should compile without warnings
        }
        
        Task.detached {
            let _ = sessionType // Should compile without warnings
        }
    }
    
    // MARK: - Basic Configuration Tests
    
    func testProgressSessionConfigBasicInitialization() {
        let config = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.preparing, .scanning, .processing],
            estimatedDuration: 5.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertEqual(config.type, .singlePageScan)
        XCTAssertEqual(config.expectedPhases.count, 3)
        XCTAssertEqual(config.expectedPhases, [.preparing, .scanning, .processing])
        XCTAssertEqual(config.estimatedDuration ?? 0, 5.0, accuracy: 0.001)
        XCTAssertTrue(config.shouldAnnounceProgress)
        XCTAssertEqual(config.minimumUpdateInterval, 0.1, accuracy: 0.001)
    }
    
    func testProgressSessionConfigWithNilDuration() {
        let config = ProgressSessionConfig(
            type: .multiPageScan,
            expectedPhases: [.preparing, .scanning, .processing, .analyzing],
            estimatedDuration: nil,
            shouldAnnounceProgress: false,
            minimumUpdateInterval: 0.2
        )
        
        XCTAssertEqual(config.type, .multiPageScan)
        XCTAssertNil(config.estimatedDuration)
        XCTAssertFalse(config.shouldAnnounceProgress)
    }
    
    func testProgressSessionConfigEmptyPhases() {
        let config = ProgressSessionConfig(
            type: .documentProcessing,
            expectedPhases: [],
            estimatedDuration: 1.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.05
        )
        
        XCTAssertTrue(config.expectedPhases.isEmpty)
    }
    
    // MARK: - Default Configuration Tests
    
    func testDefaultSinglePageScanConfiguration() {
        let config = ProgressSessionConfig.defaultSinglePageScan
        
        XCTAssertEqual(config.type, .singlePageScan)
        XCTAssertEqual(config.expectedPhases, [.preparing, .scanning, .processing, .completing])
        XCTAssertEqual(config.estimatedDuration ?? 0, 3.0, accuracy: 0.001)
        XCTAssertTrue(config.shouldAnnounceProgress)
        XCTAssertEqual(config.minimumUpdateInterval, 0.1, accuracy: 0.001)
    }
    
    func testDefaultMultiPageScanConfiguration() {
        let config = ProgressSessionConfig.defaultMultiPageScan
        
        XCTAssertEqual(config.type, .multiPageScan)
        XCTAssertEqual(config.expectedPhases, [.preparing, .scanning, .processing, .analyzing, .completing])
        XCTAssertNil(config.estimatedDuration) // Should be calculated based on page count
        XCTAssertTrue(config.shouldAnnounceProgress)
        XCTAssertEqual(config.minimumUpdateInterval, 0.2, accuracy: 0.001)
    }
    
    func testDefaultConfigurationsAreConsistent() {
        let singlePage = ProgressSessionConfig.defaultSinglePageScan
        let multiPage = ProgressSessionConfig.defaultMultiPageScan
        
        // Both should announce progress
        XCTAssertTrue(singlePage.shouldAnnounceProgress)
        XCTAssertTrue(multiPage.shouldAnnounceProgress)
        
        // Multi-page should have longer minimum interval (less frequent updates)
        XCTAssertGreaterThan(multiPage.minimumUpdateInterval, singlePage.minimumUpdateInterval)
        
        // Multi-page should have more phases
        XCTAssertGreaterThan(multiPage.expectedPhases.count, singlePage.expectedPhases.count)
        
        // Both should start with preparing and end with completing
        XCTAssertEqual(singlePage.expectedPhases.first, .preparing)
        XCTAssertEqual(singlePage.expectedPhases.last, .completing)
        XCTAssertEqual(multiPage.expectedPhases.first, .preparing)
        XCTAssertEqual(multiPage.expectedPhases.last, .completing)
    }
    
    // MARK: - Phase Validation Tests
    
    func testProgressSessionConfigWithAllPhases() {
        let allPhases = ProgressPhase.allCases
        let config = ProgressSessionConfig(
            type: .formAnalysis,
            expectedPhases: allPhases,
            estimatedDuration: 10.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertEqual(config.expectedPhases.count, allPhases.count)
        for phase in allPhases {
            XCTAssertTrue(config.expectedPhases.contains(phase))
        }
    }
    
    func testProgressSessionConfigPhaseOrder() {
        let phases: [ProgressPhase] = [.scanning, .preparing, .completing, .processing]
        let config = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: phases,
            estimatedDuration: 3.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        // Order should be preserved as provided
        XCTAssertEqual(config.expectedPhases, phases)
        XCTAssertEqual(config.expectedPhases[0], .scanning)
        XCTAssertEqual(config.expectedPhases[1], .preparing)
        XCTAssertEqual(config.expectedPhases[2], .completing)
        XCTAssertEqual(config.expectedPhases[3], .processing)
    }
    
    func testProgressSessionConfigDuplicatePhases() {
        let phasesWithDuplicates: [ProgressPhase] = [.scanning, .processing, .scanning, .completing]
        let config = ProgressSessionConfig(
            type: .documentProcessing,
            expectedPhases: phasesWithDuplicates,
            estimatedDuration: 5.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        // Should preserve duplicates as provided (up to implementation)
        XCTAssertEqual(config.expectedPhases.count, 4)
        XCTAssertEqual(config.expectedPhases, phasesWithDuplicates)
    }
    
    // MARK: - Timing Validation Tests
    
    func testProgressSessionConfigValidTimingIntervals() {
        let config = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 0.5,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.01
        )
        
        XCTAssertEqual(config.estimatedDuration ?? 0, 0.5, accuracy: 0.001)
        XCTAssertEqual(config.minimumUpdateInterval, 0.01, accuracy: 0.001)
    }
    
    func testProgressSessionConfigZeroTimingIntervals() {
        let config = ProgressSessionConfig(
            type: .documentProcessing,
            expectedPhases: [.processing],
            estimatedDuration: 0.0,
            shouldAnnounceProgress: false,
            minimumUpdateInterval: 0.0
        )
        
        XCTAssertEqual(config.estimatedDuration, 0.0)
        XCTAssertEqual(config.minimumUpdateInterval, 0.0)
    }
    
    func testProgressSessionConfigLargeTimingValues() {
        let config = ProgressSessionConfig(
            type: .formAnalysis,
            expectedPhases: [.analyzing],
            estimatedDuration: 3600.0, // 1 hour
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 1.0 // 1 second
        )
        
        XCTAssertEqual(config.estimatedDuration ?? 0, 3600.0, accuracy: 0.1)
        XCTAssertEqual(config.minimumUpdateInterval, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Equatable Tests
    
    func testProgressSessionConfigEquality() {
        let config1 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning, .processing],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        let config2 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning, .processing],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertEqual(config1, config2)
    }
    
    func testProgressSessionConfigInequalityByType() {
        let config1 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        let config2 = ProgressSessionConfig(
            type: .multiPageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testProgressSessionConfigInequalityByPhases() {
        let config1 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning, .processing],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        let config2 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning, .analyzing],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testProgressSessionConfigInequalityByDuration() {
        let config1 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        let config2 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 3.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testProgressSessionConfigInequalityByAnnouncement() {
        let config1 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        let config2 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: false,
            minimumUpdateInterval: 0.1
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testProgressSessionConfigInequalityByInterval() {
        let config1 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.1
        )
        
        let config2 = ProgressSessionConfig(
            type: .singlePageScan,
            expectedPhases: [.scanning],
            estimatedDuration: 2.0,
            shouldAnnounceProgress: true,
            minimumUpdateInterval: 0.2
        )
        
        XCTAssertNotEqual(config1, config2)
    }
    
    // MARK: - Sendable Compliance Tests
    
    func testProgressSessionConfigIsSendable() {
        let config = ProgressSessionConfig.defaultSinglePageScan
        
        // Verify we can pass across concurrency boundaries
        Task { @MainActor in
            let _ = config // Should compile without warnings
        }
        
        Task.detached {
            let _ = config // Should compile without warnings
        }
    }
    
    // MARK: - Performance Tests
    
    func testProgressSessionConfigCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let _ = ProgressSessionConfig(
                    type: .singlePageScan,
                    expectedPhases: [.preparing, .scanning, .processing],
                    estimatedDuration: Double(i) / 100.0,
                    shouldAnnounceProgress: i % 2 == 0,
                    minimumUpdateInterval: 0.1
                )
            }
        }
    }
    
    func testDefaultConfigurationAccessPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = ProgressSessionConfig.defaultSinglePageScan
                let _ = ProgressSessionConfig.defaultMultiPageScan
            }
        }
    }
}
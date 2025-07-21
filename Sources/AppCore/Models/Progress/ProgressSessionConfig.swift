import Foundation

/// Configuration for progress tracking sessions
public struct ProgressSessionConfig: Equatable, Sendable {
    public let type: SessionType
    public let expectedPhases: [ProgressPhase]
    public let estimatedDuration: TimeInterval?
    public let shouldAnnounceProgress: Bool
    public let minimumUpdateInterval: TimeInterval

    public enum SessionType: String, Sendable {
        case singlePageScan = "single_page_scan"
        case multiPageScan = "multi_page_scan"
        case documentProcessing = "document_processing"
        case formAnalysis = "form_analysis"
    }

    public init(
        type: SessionType,
        expectedPhases: [ProgressPhase],
        estimatedDuration: TimeInterval?,
        shouldAnnounceProgress: Bool,
        minimumUpdateInterval: TimeInterval
    ) {
        // STUB IMPLEMENTATION - Basic assignment, no validation
        self.type = type
        self.expectedPhases = expectedPhases
        self.estimatedDuration = estimatedDuration
        self.shouldAnnounceProgress = shouldAnnounceProgress
        self.minimumUpdateInterval = minimumUpdateInterval
    }

    public static let defaultSinglePageScan = ProgressSessionConfig(
        type: .singlePageScan,
        expectedPhases: [.preparing, .scanning, .processing, .completing],
        estimatedDuration: 3.0,
        shouldAnnounceProgress: true,
        minimumUpdateInterval: 0.1
    )

    public static let defaultMultiPageScan = ProgressSessionConfig(
        type: .multiPageScan,
        expectedPhases: [.preparing, .scanning, .processing, .analyzing, .completing],
        estimatedDuration: nil, // Calculated based on page count
        shouldAnnounceProgress: true,
        minimumUpdateInterval: 0.2
    )
}

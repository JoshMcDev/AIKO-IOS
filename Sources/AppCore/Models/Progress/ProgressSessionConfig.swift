import Foundation

/// Configuration for progress tracking behavior
public struct ProgressSessionConfig: Equatable, Sendable {
    /// Maximum update frequency in Hz (updates per second)
    public let maxUpdateFrequency: Double
    
    /// Minimum progress change threshold before sending update
    public let minProgressDelta: Double
    
    /// Maximum session timeout in seconds
    public let sessionTimeout: TimeInterval
    
    /// Whether to enable time estimation
    public let enableTimeEstimation: Bool
    
    /// Whether to track processing speed metrics
    public let trackProcessingSpeed: Bool
    
    /// Whether to enable accessibility announcements
    public let enableAccessibilityAnnouncements: Bool
    
    /// Custom announcement milestones (percentages: 0.0 to 1.0)
    public let announcementMilestones: [Double]
    
    /// Batch update window in milliseconds
    public let batchUpdateWindow: TimeInterval
    
    /// Whether to persist progress state
    public let persistState: Bool
    
    /// Custom metadata for the session
    public let metadata: [String: String]
    
    public init(
        maxUpdateFrequency: Double = 5.0, // 5 Hz max
        minProgressDelta: Double = 0.01,  // 1% minimum change
        sessionTimeout: TimeInterval = 300.0, // 5 minutes
        enableTimeEstimation: Bool = true,
        trackProcessingSpeed: Bool = true,
        enableAccessibilityAnnouncements: Bool = true,
        announcementMilestones: [Double] = [0.25, 0.5, 0.75, 1.0],
        batchUpdateWindow: TimeInterval = 0.1, // 100ms batching
        persistState: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.maxUpdateFrequency = max(0.1, min(10.0, maxUpdateFrequency))
        self.minProgressDelta = max(0.001, min(0.1, minProgressDelta))
        self.sessionTimeout = max(10.0, sessionTimeout)
        self.enableTimeEstimation = enableTimeEstimation
        self.trackProcessingSpeed = trackProcessingSpeed
        self.enableAccessibilityAnnouncements = enableAccessibilityAnnouncements
        self.announcementMilestones = announcementMilestones.filter { $0 >= 0.0 && $0 <= 1.0 }.sorted()
        self.batchUpdateWindow = max(0.05, min(1.0, batchUpdateWindow))
        self.persistState = persistState
        self.metadata = metadata
    }
}

// MARK: - Preset Configurations

public extension ProgressSessionConfig {
    /// Fast updates with minimal batching for real-time feedback
    static let realTime = ProgressSessionConfig(
        maxUpdateFrequency: 10.0,
        minProgressDelta: 0.005,
        enableTimeEstimation: true,
        trackProcessingSpeed: true,
        batchUpdateWindow: 0.05
    )
    
    /// Balanced performance with standard settings
    static let balanced = ProgressSessionConfig(
        maxUpdateFrequency: 5.0,
        minProgressDelta: 0.01,
        enableTimeEstimation: true,
        trackProcessingSpeed: true,
        batchUpdateWindow: 0.1
    )
    
    /// Battery-optimized with reduced update frequency
    static let batteryOptimized = ProgressSessionConfig(
        maxUpdateFrequency: 2.0,
        minProgressDelta: 0.02,
        enableTimeEstimation: false,
        trackProcessingSpeed: false,
        batchUpdateWindow: 0.2
    )
    
    /// Accessibility-focused with enhanced announcements
    static let accessibility = ProgressSessionConfig(
        maxUpdateFrequency: 3.0,
        minProgressDelta: 0.01,
        enableTimeEstimation: true,
        trackProcessingSpeed: false,
        enableAccessibilityAnnouncements: true,
        announcementMilestones: [0.1, 0.25, 0.5, 0.75, 0.9, 1.0],
        batchUpdateWindow: 0.15
    )
    
    /// Testing configuration with high frequency updates
    static let testing = ProgressSessionConfig(
        maxUpdateFrequency: 20.0,
        minProgressDelta: 0.001,
        sessionTimeout: 30.0,
        batchUpdateWindow: 0.01,
        persistState: false,
        metadata: ["environment": "testing"]
    )
}

// MARK: - Validation

public extension ProgressSessionConfig {
    /// Validate configuration parameters
    var isValid: Bool {
        maxUpdateFrequency > 0 &&
        minProgressDelta > 0 &&
        sessionTimeout > 0 &&
        batchUpdateWindow > 0 &&
        announcementMilestones.allSatisfy { $0 >= 0.0 && $0 <= 1.0 }
    }
    
    /// Create a validated copy with corrected parameters
    func validated() -> ProgressSessionConfig {
        return ProgressSessionConfig(
            maxUpdateFrequency: maxUpdateFrequency,
            minProgressDelta: minProgressDelta,
            sessionTimeout: sessionTimeout,
            enableTimeEstimation: enableTimeEstimation,
            trackProcessingSpeed: trackProcessingSpeed,
            enableAccessibilityAnnouncements: enableAccessibilityAnnouncements,
            announcementMilestones: announcementMilestones,
            batchUpdateWindow: batchUpdateWindow,
            persistState: persistState,
            metadata: metadata
        )
    }
    
    /// Update frequency constraint for batching
    var updateInterval: TimeInterval {
        1.0 / maxUpdateFrequency
    }
    
    /// Whether updates should be batched based on frequency settings
    var shouldBatchUpdates: Bool {
        batchUpdateWindow > updateInterval
    }
}
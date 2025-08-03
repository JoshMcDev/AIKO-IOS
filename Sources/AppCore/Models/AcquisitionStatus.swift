import Foundation

/// Value object representing the status of an acquisition
public enum AcquisitionStatus: String, CaseIterable, Codable, Sendable, Hashable {
    case draft
    case inProgress = "in_progress"
    case underReview = "under_review"
    case approved
    case completed
    case cancelled
    case onHold = "on_hold"
    case awarded
    case archived

    public var displayName: String {
        switch self {
        case .draft: "Draft"
        case .inProgress: "In Progress"
        case .underReview: "Under Review"
        case .approved: "Approved"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        case .onHold: "On Hold"
        case .awarded: "Awarded"
        case .archived: "Archived"
        }
    }

    public var icon: String {
        switch self {
        case .draft: "pencil.circle"
        case .inProgress: "arrow.right.circle"
        case .underReview: "magnifyingglass.circle"
        case .approved: "checkmark.circle"
        case .completed: "checkmark.seal"
        case .cancelled: "xmark.circle"
        case .onHold: "pause.circle"
        case .awarded: "rosette"
        case .archived: "archivebox"
        }
    }

    public var color: String {
        switch self {
        case .draft: "gray"
        case .inProgress: "blue"
        case .underReview: "orange"
        case .approved: "green"
        case .completed: "mint"
        case .cancelled: "red"
        case .onHold: "yellow"
        case .awarded: "purple"
        case .archived: "secondary"
        }
    }

    /// Determines if this status represents an active acquisition
    public var isActive: Bool {
        switch self {
        case .draft, .inProgress, .underReview, .approved, .onHold:
            true
        case .completed, .cancelled, .awarded, .archived:
            false
        }
    }

    /// Determines if this status allows editing
    public var allowsEditing: Bool {
        switch self {
        case .draft, .inProgress:
            true
        case .underReview, .approved, .completed, .cancelled, .onHold, .awarded, .archived:
            false
        }
    }

    /// Determines valid transitions from this status
    public func canTransition(to targetStatus: AcquisitionStatus) -> Bool {
        switch (self, targetStatus) {
        // From Draft
        case (.draft, .inProgress): true
        case (.draft, .cancelled): true
        // From In Progress
        case (.inProgress, .underReview): true
        case (.inProgress, .draft): true
        case (.inProgress, .cancelled): true
        case (.inProgress, .onHold): true
        // From Under Review
        case (.underReview, .approved): true
        case (.underReview, .inProgress): true
        case (.underReview, .cancelled): true
        // From Approved
        case (.approved, .awarded): true
        case (.approved, .cancelled): true
        case (.approved, .completed): true
        // From On Hold
        case (.onHold, .inProgress): true
        case (.onHold, .cancelled): true
        // From Awarded
        case (.awarded, .completed): true
        case (.awarded, .archived): true
        // From Completed
        case (.completed, .archived): true
        // From Cancelled
        case (.cancelled, .draft): true // Allow restart
        case (.cancelled, .archived): true
        // Same status transitions allowed
        case _ where self == targetStatus: true
        // All other transitions not allowed
        default: false
        }
    }
}

// MARK: - Status Groups

public extension AcquisitionStatus {
    /// Groups statuses by lifecycle phase
    enum Phase: String, CaseIterable, Sendable {
        case planning = "Planning"
        case execution = "Execution"
        case completion = "Completion"

        var statuses: [AcquisitionStatus] {
            switch self {
            case .planning:
                [.draft]
            case .execution:
                [.inProgress, .underReview, .approved, .onHold]
            case .completion:
                [.awarded, .completed, .cancelled, .archived]
            }
        }

        public var icon: String {
            switch self {
            case .planning: "lightbulb"
            case .execution: "gearshape"
            case .completion: "checkmark.seal"
            }
        }
    }

    var phase: Phase {
        if Phase.planning.statuses.contains(self) {
            .planning
        } else if Phase.execution.statuses.contains(self) {
            .execution
        } else {
            .completion
        }
    }
}

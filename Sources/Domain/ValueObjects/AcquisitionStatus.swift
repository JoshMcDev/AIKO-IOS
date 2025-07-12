import Foundation

/// Value object representing the status of an acquisition
public enum AcquisitionStatus: String, CaseIterable, Codable {
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
        case .draft: return "Draft"
        case .inProgress: return "In Progress"
        case .underReview: return "Under Review"
        case .approved: return "Approved"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .onHold: return "On Hold"
        case .awarded: return "Awarded"
        case .archived: return "Archived"
        }
    }
    
    public var icon: String {
        switch self {
        case .draft: return "pencil.circle"
        case .inProgress: return "arrow.right.circle"
        case .underReview: return "magnifyingglass.circle"
        case .approved: return "checkmark.circle"
        case .completed: return "checkmark.seal"
        case .cancelled: return "xmark.circle"
        case .onHold: return "pause.circle"
        case .awarded: return "rosette"
        case .archived: return "archivebox"
        }
    }
    
    public var color: String {
        switch self {
        case .draft: return "gray"
        case .inProgress: return "blue"
        case .underReview: return "orange"
        case .approved: return "green"
        case .completed: return "mint"
        case .cancelled: return "red"
        case .onHold: return "yellow"
        case .awarded: return "purple"
        case .archived: return "secondary"
        }
    }
    
    /// Determines if this status represents an active acquisition
    public var isActive: Bool {
        switch self {
        case .draft, .inProgress, .underReview, .approved, .onHold:
            return true
        case .completed, .cancelled, .awarded, .archived:
            return false
        }
    }
    
    /// Determines if this status allows editing
    public var allowsEditing: Bool {
        switch self {
        case .draft, .inProgress:
            return true
        case .underReview, .approved, .completed, .cancelled, .onHold, .awarded, .archived:
            return false
        }
    }
    
    /// Determines valid transitions from this status
    public func canTransition(to targetStatus: AcquisitionStatus) -> Bool {
        switch (self, targetStatus) {
        // From Draft
        case (.draft, .inProgress): return true
        case (.draft, .cancelled): return true
        
        // From In Progress
        case (.inProgress, .underReview): return true
        case (.inProgress, .draft): return true
        case (.inProgress, .cancelled): return true
        case (.inProgress, .onHold): return true
        
        // From Under Review
        case (.underReview, .approved): return true
        case (.underReview, .inProgress): return true
        case (.underReview, .cancelled): return true
        
        // From Approved
        case (.approved, .awarded): return true
        case (.approved, .cancelled): return true
        case (.approved, .completed): return true
        
        // From On Hold
        case (.onHold, .inProgress): return true
        case (.onHold, .cancelled): return true
        
        // From Awarded
        case (.awarded, .completed): return true
        case (.awarded, .archived): return true
        
        // From Completed
        case (.completed, .archived): return true
        
        // From Cancelled
        case (.cancelled, .draft): return true // Allow restart
        case (.cancelled, .archived): return true
        
        // Same status transitions allowed
        case _ where self == targetStatus: return true
        
        // All other transitions not allowed
        default: return false
        }
    }
}

// MARK: - Status Groups

public extension AcquisitionStatus {
    /// Groups statuses by lifecycle phase
    enum Phase: String, CaseIterable {
        case planning = "Planning"
        case execution = "Execution"
        case completion = "Completion"
        
        var statuses: [AcquisitionStatus] {
            switch self {
            case .planning:
                return [.draft]
            case .execution:
                return [.inProgress, .underReview, .approved, .onHold]
            case .completion:
                return [.awarded, .completed, .cancelled, .archived]
            }
        }
        
        var icon: String {
            switch self {
            case .planning: return "lightbulb"
            case .execution: return "gearshape"
            case .completion: return "checkmark.seal"
            }
        }
    }
    
    var phase: Phase {
        if Phase.planning.statuses.contains(self) {
            return .planning
        } else if Phase.execution.statuses.contains(self) {
            return .execution
        } else {
            return .completion
        }
    }
}
import Foundation

/// Document readiness status
public enum DocumentStatus: Equatable, CaseIterable {
    case notReady
    case needsMoreInfo
    case ready
    
    public var description: String {
        switch self {
        case .notReady:
            return "Not Ready"
        case .needsMoreInfo:
            return "Needs More Information"
        case .ready:
            return "Ready"
        }
    }
}
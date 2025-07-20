import Foundation

/// Document readiness status
public enum DocumentStatus: Equatable, CaseIterable {
    case notReady
    case needsMoreInfo
    case ready

    public var description: String {
        switch self {
        case .notReady:
            "Not Ready"
        case .needsMoreInfo:
            "Needs More Information"
        case .ready:
            "Ready"
        }
    }
}

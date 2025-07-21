import Foundation

/// Represents different phases of document processing progress
public enum ProgressPhase: String, CaseIterable, Equatable, Sendable {
    case preparing = "preparing"
    case scanning = "scanning"
    case processing = "processing"
    case analyzing = "analyzing"
    case completing = "completing"
    case idle = "idle"

    public var displayName: String {
        switch self {
        case .preparing: return "Preparing"
        case .scanning: return "Scanning"
        case .processing: return "Processing"
        case .analyzing: return "Analyzing"
        case .completing: return "Completing"
        case .idle: return "Ready"
        }
    }

    public var accessibilityDescription: String {
        switch self {
        case .preparing: return "Preparing document scan"
        case .scanning: return "Scanning document pages"
        case .processing: return "Processing scanned images"
        case .analyzing: return "Analyzing document content"
        case .completing: return "Finalizing results"
        case .idle: return "Scanner ready"
        }
    }

    public var systemImageName: String {
        switch self {
        case .preparing: return "gearshape"
        case .scanning: return "doc.viewfinder"
        case .processing: return "cpu"
        case .analyzing: return "magnifyingglass"
        case .completing: return "checkmark.circle"
        case .idle: return "circle"
        }
    }
}

import Foundation

/// Phases in the document scanning and processing workflow
public enum ProgressPhase: String, CaseIterable, Equatable, Sendable {
    case initializing = "initializing"
    case scanning = "scanning"
    case processing = "processing"
    case ocr = "ocr"
    case formPopulation = "form_population"
    case finalizing = "finalizing"
    case completed = "completed"
    case error = "error"
    
    /// Human-readable display name for the phase
    public var displayName: String {
        switch self {
        case .initializing:
            "Initializing"
        case .scanning:
            "Scanning Document"
        case .processing:
            "Processing Image"
        case .ocr:
            "Recognizing Text"
        case .formPopulation:
            "Populating Form"
        case .finalizing:
            "Finalizing"
        case .completed:
            "Completed"
        case .error:
            "Error"
        }
    }
    
    /// User-friendly operation description
    public var operationDescription: String {
        switch self {
        case .initializing:
            "Setting up document scanning..."
        case .scanning:
            "Capturing document with camera..."
        case .processing:
            "Enhancing image quality..."
        case .ocr:
            "Extracting text from document..."
        case .formPopulation:
            "Auto-filling form fields..."
        case .finalizing:
            "Completing processing..."
        case .completed:
            "Document processing complete"
        case .error:
            "An error occurred"
        }
    }
    
    /// Expected relative duration for progress estimation
    public var relativeDuration: Double {
        switch self {
        case .initializing:
            0.05  // 5%
        case .scanning:
            0.25  // 25%
        case .processing:
            0.20  // 20%
        case .ocr:
            0.30  // 30%
        case .formPopulation:
            0.15  // 15%
        case .finalizing:
            0.05  // 5%
        case .completed, .error:
            0.0
        }
    }
    
    /// Whether this phase can be cancelled by the user
    public var canCancel: Bool {
        switch self {
        case .completed, .error:
            false
        default:
            true
        }
    }
    
    /// Whether this phase is a terminal state
    public var isTerminal: Bool {
        self == .completed || self == .error
    }
    
    /// SF Symbol name for visual representation
    public var systemImageName: String {
        switch self {
        case .initializing:
            "gearshape"
        case .scanning:
            "camera.viewfinder"
        case .processing:
            "wand.and.rays"
        case .ocr:
            "text.viewfinder"
        case .formPopulation:
            "square.and.pencil"
        case .finalizing:
            "checkmark.circle"
        case .completed:
            "checkmark.circle.fill"
        case .error:
            "exclamationmark.triangle"
        }
    }
}
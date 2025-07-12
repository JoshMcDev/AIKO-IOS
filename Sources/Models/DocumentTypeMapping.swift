import Foundation

// MARK: - Document Type Mapping

/// Maps between validation document types and parsed document types
public enum DocumentValidationType: String, CaseIterable {
    case pdf
    case word
    case plainText
    case rtf
    case image
    case excel
    case unknown
}

extension ParsedDocumentType {
    func toDocumentValidationType() -> DocumentValidationType {
        switch self {
        case .pdf: return .pdf
        case .word: return .word
        case .text: return .plainText
        case .rtf: return .rtf
        case .png, .jpg, .jpeg, .heic: return .image
        case .excel: return .excel
        case .unknown: return .unknown
        }
    }
}
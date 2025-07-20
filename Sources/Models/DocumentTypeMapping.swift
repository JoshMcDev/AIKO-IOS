import AppCore
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
        case .pdf: .pdf
        case .word: .word
        case .text: .plainText
        case .rtf: .rtf
        case .png, .jpg, .jpeg, .heic: .image
        case .excel: .excel
        case .ocr: .image // OCR documents are treated as images for validation
        case .unknown: .unknown
        }
    }
}

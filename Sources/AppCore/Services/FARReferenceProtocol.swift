import Foundation

public protocol FARReferenceProtocol: Sendable {
    static func getFARReference(for documentType: String) -> ComprehensiveFARReference?
    static func formatFARReferences(for documentType: String) -> String
}

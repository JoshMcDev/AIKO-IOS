import Foundation

/// Structure to hold comprehensive FAR/DFAR reference information
public struct ComprehensiveFARReference {
    public let primary: String
    public let related: [String]
    public let dfar: [String]
    public let description: String

    public init(primary: String, related: [String] = [], dfar: [String] = [], description: String) {
        self.primary = primary
        self.related = related
        self.dfar = dfar
        self.description = description
    }
}

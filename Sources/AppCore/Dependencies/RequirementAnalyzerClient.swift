import Foundation

public struct RequirementAnalyzerClient: Sendable {
    public var analyzeRequirements: @Sendable (String) async throws -> (String, [DocumentType])
    public var analyzeDocumentContent: @Sendable (Data, String) async throws -> (String, [DocumentType])
    public var enhancePrompt: @Sendable (String) async throws -> String
}

public extension RequirementAnalyzerClient {
    static let testValue = Self(
        analyzeRequirements: { _ in ("", []) },
        analyzeDocumentContent: { _, _ in ("", []) },
        enhancePrompt: { _ in "" }
    )
}

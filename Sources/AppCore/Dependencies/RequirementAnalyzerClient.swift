import ComposableArchitecture
import Foundation

@DependencyClient
public struct RequirementAnalyzerClient {
    public var analyzeRequirements: @Sendable (String) async throws -> (String, [DocumentType])
    public var analyzeDocumentContent: @Sendable (Data, String) async throws -> (String, [DocumentType])
    public var enhancePrompt: @Sendable (String) async throws -> String
}

extension RequirementAnalyzerClient: TestDependencyKey {
    public static let testValue = Self()
}

public extension DependencyValues {
    var requirementAnalyzer: RequirementAnalyzerClient {
        get { self[RequirementAnalyzerClient.self] }
        set { self[RequirementAnalyzerClient.self] = newValue }
    }
}

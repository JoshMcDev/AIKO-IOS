import Foundation

public protocol RequirementAnalyzerProtocol {
    func analyzeRequirements(_ requirements: String) async throws -> (String, [DocumentType])
    func analyzeDocumentContent(_ data: Data, _ fileName: String) async throws -> (String, [DocumentType])
    func enhancePrompt(_ prompt: String) async throws -> String
}

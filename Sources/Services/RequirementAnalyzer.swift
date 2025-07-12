import ComposableArchitecture
import Foundation
import SwiftAnthropic

public struct RequirementAnalyzer {
    public var analyzeRequirements: (String) async throws -> (response: String, recommendedDocuments: [DocumentType])
    public var analyzeDocumentContent: (Data, String) async throws -> (response: String, recommendedDocuments: [DocumentType])
    public var enhancePrompt: (String) async throws -> String

    public init(
        analyzeRequirements: @escaping (String) async throws -> (response: String, recommendedDocuments: [DocumentType]),
        analyzeDocumentContent: @escaping (Data, String) async throws -> (response: String, recommendedDocuments: [DocumentType]),
        enhancePrompt: @escaping (String) async throws -> String
    ) {
        self.analyzeRequirements = analyzeRequirements
        self.analyzeDocumentContent = analyzeDocumentContent
        self.enhancePrompt = enhancePrompt
    }
}

extension RequirementAnalyzer: DependencyKey {
    public static var liveValue: RequirementAnalyzer {
        RequirementAnalyzer(
            analyzeRequirements: { requirements in
                let anthropicService = AnthropicServiceFactory.service(
                    apiKey: APIConfiguration.getAnthropicKey(),
                    betaHeaders: nil
                )

                let analysisPrompt = """
                Analyze the following acquisition requirements:

                Requirements: \(requirements)

                Specific Task:
                Review these requirements and provide a comprehensive acquisition analysis that includes:

                1. REQUIREMENTS ANALYSIS: Summarize your understanding of the acquisition needs
                2. REGULATORY COMPLIANCE: Identify applicable FAR/DFARS requirements based on the type and value
                3. ACQUISITION APPROACH: Recommend the appropriate procurement method
                4. MISSING INFORMATION: List specific details needed for a compliant acquisition
                5. RISK ASSESSMENT: Identify potential procurement risks
                6. RECOMMENDATIONS: Which contract documents should be generated

                Available document types include all standard federal acquisition documents:
                - Market Research Report (FAR Part 10)
                - Requirements Document (RRD)
                - Statement of Work (SOW) / Performance Work Statement (PWS)
                - Independent Government Cost Estimate (IGCE)
                - Acquisition Plan (FAR Part 7)
                - Source Selection Plan
                - Quality Assurance Surveillance Plan (QASP)
                - Request for Quote/Proposal (RFQ/RFP)
                - And others as appropriate

                Format your response following the structure specified in the task analysis instructions.
                """

                let messages = [
                    MessageParameter.Message(
                        role: .user,
                        content: .text(analysisPrompt)
                    ),
                ]

                let parameters = MessageParameter(
                    model: .other("claude-sonnet-4-20250514"),
                    messages: messages,
                    maxTokens: 2048,
                    system: .text(GovernmentAcquisitionPrompts.generateCompletePrompt(for: analysisPrompt)),
                    metadata: nil,
                    stopSequences: nil,
                    stream: false,
                    temperature: nil,
                    topK: nil,
                    topP: nil,
                    tools: nil,
                    toolChoice: nil
                )

                let result = try await anthropicService.createMessage(parameters)

                let content: String
                switch result.content.first {
                case let .text(text, _): // Ignore citations
                    content = text
                default:
                    throw RequirementAnalyzerError.noResponse
                }

                // Parse the response to extract recommendations
                let recommendedTypes = parseRecommendations(from: content)

                return (response: content, recommendedDocuments: recommendedTypes)
            },
            analyzeDocumentContent: { documentData, fileName in
                // Parse document content first
                let parser = DocumentParser()
                let documentContent: String = if fileName.lowercased().hasSuffix(".pdf") {
                    try await parser.parseDocument(documentData, type: .pdf)
                } else if fileName.lowercased().hasSuffix(".txt") || fileName.lowercased().hasSuffix(".docx") {
                    try await parser.parseDocument(documentData, type: .plainText)
                } else {
                    // Assume it's an image
                    try await parser.parseImage(documentData)
                }

                // Now analyze the parsed content
                let anthropicService = AnthropicServiceFactory.service(
                    apiKey: APIConfiguration.getAnthropicKey(),
                    betaHeaders: nil
                )

                let analysisPrompt = """
                Analyze the following uploaded document for federal acquisition requirements:

                Document: \(fileName)
                Content: \(documentContent)

                Specific Task:
                Review this document and provide a comprehensive acquisition analysis that includes:

                1. COMPLETENESS ASSESSMENT: Rate from 1-10 how complete this requirement document is for federal contracting purposes
                2. REGULATORY ANALYSIS: Identify which FAR/DFARS clauses and requirements apply based on the content
                3. ACQUISITION STRATEGY: Recommend the appropriate acquisition approach (simplified, negotiated, sealed bid, etc.)
                4. MISSING INFORMATION: List specific details needed to comply with federal acquisition regulations
                5. RISK ASSESSMENT: Identify procurement risks and compliance concerns
                6. RECOMMENDATIONS: Which contract documents should be generated, including:
                   - Market Research Report (FAR Part 10)
                   - Requirements Document (RRD)
                   - Statement of Work (SOW) or Performance Work Statement (PWS)
                   - Independent Government Cost Estimate (IGCE)
                   - Acquisition Plan (FAR Part 7)
                   - Source Selection Plan
                   - Quality Assurance Surveillance Plan (QASP)
                   - Other relevant documents

                Provide your analysis following the response format specified in the instructions.
                """

                let messages = [
                    MessageParameter.Message(
                        role: .user,
                        content: .text(analysisPrompt)
                    ),
                ]

                let parameters = MessageParameter(
                    model: .other("claude-sonnet-4-20250514"),
                    messages: messages,
                    maxTokens: 2048,
                    system: .text(GovernmentAcquisitionPrompts.generateCompletePrompt(for: analysisPrompt)),
                    metadata: nil,
                    stopSequences: nil,
                    stream: false,
                    temperature: nil,
                    topK: nil,
                    topP: nil,
                    tools: nil,
                    toolChoice: nil
                )

                let result = try await anthropicService.createMessage(parameters)

                let content: String
                switch result.content.first {
                case let .text(text, _): // Ignore citations
                    content = text
                default:
                    throw RequirementAnalyzerError.noResponse
                }

                // Parse the response to extract recommendations
                let recommendedTypes = parseRecommendations(from: content)

                return (response: content, recommendedDocuments: recommendedTypes)
            },
            enhancePrompt: { prompt in
                let anthropicService = AnthropicServiceFactory.service(
                    apiKey: APIConfiguration.getAnthropicKey(),
                    betaHeaders: nil
                )

                let messages = [
                    MessageParameter.Message(
                        role: .user,
                        content: .text("""
                        Please enhance and improve the following acquisition requirements prompt to make it more specific, comprehensive, and actionable for generating government contract documents. Keep the enhanced version clear and concise:

                        Original prompt: \(prompt)

                        Enhanced prompt:
                        """)
                    ),
                ]

                let parameters = MessageParameter(
                    model: .other("claude-sonnet-4-20250514"),
                    messages: messages,
                    maxTokens: 500,
                    system: .text("You are an expert at refining government acquisition requirements. Enhance prompts to be more specific about scope, deliverables, timeline, and technical requirements while maintaining clarity."),
                    metadata: nil,
                    stopSequences: nil,
                    stream: false,
                    temperature: 0.3,
                    topK: nil,
                    topP: nil,
                    tools: nil,
                    toolChoice: nil
                )

                let result = try await anthropicService.createMessage(parameters)

                switch result.content.first {
                case let .text(text, _): // Ignore citations
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                default:
                    throw RequirementAnalyzerError.noResponse
                }
            }
        )
    }

    public static var testValue: RequirementAnalyzer {
        RequirementAnalyzer(
            analyzeRequirements: { requirements in
                let mockResponse = """
                ANALYSIS: Based on your requirements for \(requirements), I can help generate the appropriate contract documents.

                I understand you need documentation for a software development project. To create comprehensive contract documents, I recommend the following:

                RECOMMENDATIONS: SOW, PWS
                """

                let recommendedTypes: [DocumentType] = [.sow, .pws]
                return (response: mockResponse, recommendedDocuments: recommendedTypes)
            },
            analyzeDocumentContent: { _, fileName in
                let mockResponse = """
                COMPLETENESS ASSESSMENT: 7/10

                ANALYSIS: The uploaded document (\(fileName)) contains basic project requirements. This appears to be a well-structured requirement document with clear objectives.

                MISSING INFORMATION: Additional details needed for timeline, budget constraints, and specific deliverable formats.

                RECOMMENDATIONS: SOW, PWS
                """

                let recommendedTypes: [DocumentType] = [.sow, .pws]
                return (response: mockResponse, recommendedDocuments: recommendedTypes)
            },
            enhancePrompt: { prompt in
                // Simple test implementation that adds some basic enhancements
                "Enhanced: \(prompt) - Including specific scope, timeline, deliverables, and technical requirements for government acquisition."
            }
        )
    }

    private static func parseRecommendations(from content: String) -> [DocumentType] {
        let lowercaseContent = content.lowercased()
        var recommendations: [DocumentType] = []

        // Parse recommendations section
        if let recommendationsRange = content.range(of: "RECOMMENDATIONS:", options: .caseInsensitive) {
            let recommendationsText = String(content[recommendationsRange.upperBound...])
            let lines = recommendationsText.components(separatedBy: .newlines)
            let firstLine = lines.first ?? ""

            // Extract document type abbreviations
            if firstLine.contains("SOW") || lowercaseContent.contains("statement of work") {
                recommendations.append(.sow)
            }
            if firstLine.contains("PWS") || lowercaseContent.contains("performance work") {
                recommendations.append(.pws)
            }
            if firstLine.contains("QASP") || lowercaseContent.contains("quality assurance") {
                recommendations.append(.qasp)
            }
            if firstLine.contains("Scaffold") || lowercaseContent.contains("acquisition strategy") {
                recommendations.append(.acquisitionPlan)
            }
            if firstLine.contains("IGCE") || lowercaseContent.contains("cost estimate") {
                recommendations.append(.costEstimate)
            }
        }

        // Fallback: Always recommend basic documents if none found
        if recommendations.isEmpty {
            recommendations = [.sow, .pws]
        }

        return recommendations
    }
}

public enum RequirementAnalyzerError: Error {
    case noResponse
    case invalidResponse
    case analysisError
}

public extension DependencyValues {
    var requirementAnalyzer: RequirementAnalyzer {
        get { self[RequirementAnalyzer.self] }
        set { self[RequirementAnalyzer.self] = newValue }
    }
}

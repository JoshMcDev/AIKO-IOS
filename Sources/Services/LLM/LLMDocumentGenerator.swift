import Foundation
import AppCore
import ComposableArchitecture

// MARK: - LLM Document Generator

/// Generates context-aware documents using LLM providers
@MainActor
public final class LLMDocumentGenerator {
    
    // MARK: - Properties
    
    public static let shared = LLMDocumentGenerator()
    
    private let llmManager = LLMManager.shared
    private let conversationManager = LLMConversationManager.shared
    private let templates = DocumentTemplateLibrary()
    
    // MARK: - Public Methods
    
    /// Generate a document based on template and context
    public func generateDocument(
        type: DocumentType,
        context: LLMDocumentGenerationContext,
        template: LLMDocumentTemplate? = nil
    ) async throws -> LLMGeneratedDocument {
        
        // Get or create template
        let selectedTemplate = template ?? templates.getTemplate(for: type)
        
        // Build prompt
        let prompt = buildPrompt(
            template: selectedTemplate,
            context: context
        )
        
        // Create conversation for generation
        var conversation = conversationManager.createConversation(
            title: "Generate \(type.displayName)",
            context: context.conversationContext
        )
        
        // Set appropriate system prompt
        conversation.systemPrompt = selectedTemplate.systemPrompt
        conversation.temperature = selectedTemplate.temperature
        conversation.maxTokens = selectedTemplate.maxTokens
        
        // Generate content
        let response = try await conversationManager.sendMessage(
            prompt,
            to: conversation,
            model: selectedTemplate.preferredModel
        )
        
        // Parse and structure the response
        let document = try parseGeneratedContent(
            response.content,
            type: type,
            template: selectedTemplate
        )
        
        // Apply post-processing
        let finalDocument = applyPostProcessing(
            document: document,
            context: context
        )
        
        return finalDocument
    }
    
    /// Generate document sections incrementally
    public func generateDocumentSections(
        type: DocumentType,
        context: LLMDocumentGenerationContext,
        template: LLMDocumentTemplate? = nil
    ) -> AsyncThrowingStream<LLMDocumentSection, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let selectedTemplate = template ?? templates.getTemplate(for: type)
                    
                    // Generate each section
                    for sectionTemplate in selectedTemplate.sections {
                        let sectionPrompt = buildSectionPrompt(
                            section: sectionTemplate,
                            context: context,
                            previousSections: []
                        )
                        
                        var conversation = conversationManager.createConversation(
                            title: "Generate \(sectionTemplate.title)",
                            context: context.conversationContext
                        )
                        
                        conversation.systemPrompt = selectedTemplate.systemPrompt
                        conversation.temperature = sectionTemplate.temperature ?? selectedTemplate.temperature
                        
                        let response = try await conversationManager.sendMessage(
                            sectionPrompt,
                            to: conversation
                        )
                        
                        let section = LLMDocumentSection(
                            id: UUID(),
                            title: sectionTemplate.title,
                            content: response.content,
                            metadata: sectionTemplate.metadata
                        )
                        
                        continuation.yield(section)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Review and improve existing document
    public func reviewDocument(
        _ document: String,
        type: DocumentType,
        improvements: [ImprovementType]
    ) async throws -> ReviewedDocument {
        
        let reviewPrompt = buildReviewPrompt(
            document: document,
            type: type,
            improvements: improvements
        )
        
        var conversation = conversationManager.createConversation(
            title: "Review \(type.displayName)"
        )
        
        conversation.systemPrompt = """
        You are an expert government contracting officer reviewing acquisition documents.
        Provide specific, actionable feedback to improve the document.
        Focus on compliance, clarity, and completeness.
        """
        
        conversation.temperature = 0.3 // Lower temperature for consistent review
        
        let response = try await conversationManager.sendMessage(
            reviewPrompt,
            to: conversation
        )
        
        return parseReviewResponse(response.content)
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(
        template: LLMDocumentTemplate,
        context: LLMDocumentGenerationContext
    ) -> String {
        var prompt = template.basePrompt
        
        // Add context information
        if let acquisitionType = context.acquisitionType {
            prompt += "\n\nAcquisition Type: \(acquisitionType.rawValue)"
        }
        
        if let vendor = context.vendorInfo {
            prompt += "\n\nVendor Information:"
            prompt += "\n- Name: \(vendor.name ?? "TBD")"
            prompt += "\n- UEI: \(vendor.uei ?? "TBD")"
            prompt += "\n- CAGE: \(vendor.cage ?? "TBD")"
        }
        
        if let pricing = context.pricing {
            prompt += "\n\nPricing:"
            prompt += "\n- Total: $\(pricing.totalPrice ?? 0)"
        }
        
        // Add specific requirements
        if !context.requirements.isEmpty {
            prompt += "\n\nSpecific Requirements:"
            for req in context.requirements {
                prompt += "\n- \(req)"
            }
        }
        
        // Add any extracted data
        if !context.extractedData.isEmpty {
            prompt += "\n\nExtracted Information:"
            for (key, value) in context.extractedData {
                prompt += "\n- \(key): \(value)"
            }
        }
        
        // Add output format instructions
        prompt += "\n\n" + template.outputInstructions
        
        return prompt
    }
    
    private func buildSectionPrompt(
        section: DocumentSectionTemplate,
        context: LLMDocumentGenerationContext,
        previousSections: [LLMDocumentSection]
    ) -> String {
        var prompt = section.prompt
        
        // Add context from previous sections
        if !previousSections.isEmpty {
            prompt += "\n\nPrevious sections for context:"
            for prev in previousSections {
                prompt += "\n\n## \(prev.title)\n\(prev.content.prefix(500))..."
            }
        }
        
        // Add section-specific context
        if let specifics = section.contextRequirements {
            prompt += "\n\nSection-specific requirements:"
            for req in specifics {
                prompt += "\n- \(req)"
            }
        }
        
        return prompt
    }
    
    private func buildReviewPrompt(
        document: String,
        type: DocumentType,
        improvements: [ImprovementType]
    ) -> String {
        var prompt = "Please review the following \(type.displayName) document:\n\n"
        prompt += document
        prompt += "\n\n---\n\nReview Focus Areas:"
        
        for improvement in improvements {
            switch improvement {
            case .compliance:
                prompt += "\n- FAR/DFAR compliance check"
            case .clarity:
                prompt += "\n- Language clarity and readability"
            case .completeness:
                prompt += "\n- Missing sections or information"
            case .consistency:
                prompt += "\n- Internal consistency and accuracy"
            case .formatting:
                prompt += "\n- Professional formatting and structure"
            }
        }
        
        prompt += "\n\nProvide specific feedback with line references where applicable."
        
        return prompt
    }
    
    private func parseGeneratedContent(
        _ content: String,
        type: DocumentType,
        template: LLMDocumentTemplate
    ) throws -> LLMGeneratedDocument {
        // Parse based on expected format
        // This is a simplified version - real implementation would be more sophisticated
        
        let sections = content.components(separatedBy: "\n## ")
            .dropFirst()
            .map { section -> LLMDocumentSection in
                let lines = section.split(separator: "\n", maxSplits: 1)
                let title = String(lines.first ?? "")
                let content = lines.count > 1 ? String(lines[1]) : ""
                
                return LLMDocumentSection(
                    id: UUID(),
                    title: title,
                    content: content,
                    metadata: [:]
                )
            }
        
        return LLMGeneratedDocument(
            id: UUID(),
            type: type,
            title: template.documentTitle,
            sections: sections,
            rawContent: content,
            metadata: [
                "template": template.id,
                "generatedAt": ISO8601DateFormatter().string(from: Date())
            ]
        )
    }
    
    private func applyPostProcessing(
        document: LLMGeneratedDocument,
        context: LLMDocumentGenerationContext
    ) -> LLMGeneratedDocument {
        var processed = document
        
        // Apply any placeholders
        processed.rawContent = processed.rawContent
            .replacingOccurrences(of: "[VENDOR_NAME]", with: context.vendorInfo?.name ?? "[Vendor Name]")
            .replacingOccurrences(of: "[DATE]", with: Date().formatted(date: .abbreviated, time: .omitted))
            .replacingOccurrences(of: "[AMOUNT]", with: "$\(context.pricing?.totalPrice ?? 0)")
        
        // Update sections
        processed.sections = processed.sections.map { section in
            var updated = section
            updated.content = updated.content
                .replacingOccurrences(of: "[VENDOR_NAME]", with: context.vendorInfo?.name ?? "[Vendor Name]")
                .replacingOccurrences(of: "[DATE]", with: Date().formatted(date: .abbreviated, time: .omitted))
                .replacingOccurrences(of: "[AMOUNT]", with: "$\(context.pricing?.totalPrice ?? 0)")
            return updated
        }
        
        return processed
    }
    
    private func parseReviewResponse(_ content: String) -> ReviewedDocument {
        // Parse review feedback
        // This is simplified - real implementation would extract structured feedback
        
        let lines = content.split(separator: "\n")
        var feedback: [ReviewFeedback] = []
        var suggestions: [String] = []
        
        for line in lines {
            if line.hasPrefix("- ") {
                suggestions.append(String(line.dropFirst(2)))
            } else if line.contains("Issue:") || line.contains("Error:") {
                feedback.append(ReviewFeedback(
                    type: .error,
                    message: String(line),
                    lineNumber: nil
                ))
            } else if line.contains("Warning:") || line.contains("Consider:") {
                feedback.append(ReviewFeedback(
                    type: .warning,
                    message: String(line),
                    lineNumber: nil
                ))
            }
        }
        
        return ReviewedDocument(
            feedback: feedback,
            suggestions: suggestions,
            overallAssessment: content
        )
    }
}

// MARK: - Supporting Types

public struct LLMDocumentGenerationContext {
    public let conversationContext: LLMConversationContext
    public let acquisitionType: AcquisitionType?
    public let vendorInfo: APEVendorInfo?
    public let pricing: PricingInfo?
    public let requirements: [String]
    public let extractedData: [String: String]
    
    public init(
        conversationContext: LLMConversationContext = LLMConversationContext(),
        acquisitionType: AcquisitionType? = nil,
        vendorInfo: APEVendorInfo? = nil,
        pricing: PricingInfo? = nil,
        requirements: [String] = [],
        extractedData: [String: String] = [:]
    ) {
        self.conversationContext = conversationContext
        self.acquisitionType = acquisitionType
        self.vendorInfo = vendorInfo
        self.pricing = pricing
        self.requirements = requirements
        self.extractedData = extractedData
    }
}

public struct LLMGeneratedDocument: Identifiable {
    public let id: UUID
    public let type: DocumentType
    public let title: String
    public var sections: [LLMDocumentSection]
    public var rawContent: String
    public let metadata: [String: String]
}

public struct LLMDocumentSection: Identifiable {
    public let id: UUID
    public let title: String
    public var content: String
    public let metadata: [String: String]
}

public enum ImprovementType {
    case compliance
    case clarity
    case completeness
    case consistency
    case formatting
}

public struct ReviewedDocument {
    public let feedback: [ReviewFeedback]
    public let suggestions: [String]
    public let overallAssessment: String
}

public struct ReviewFeedback {
    public let type: FeedbackType
    public let message: String
    public let lineNumber: Int?
    
    public enum FeedbackType {
        case error
        case warning
        case suggestion
    }
}

// MARK: - Document Template Library

public class DocumentTemplateLibrary {
    
    private var templates: [DocumentType: LLMDocumentTemplate] = [:]
    
    init() {
        loadDefaultTemplates()
    }
    
    func getTemplate(for type: DocumentType) -> LLMDocumentTemplate {
        return templates[type] ?? createDefaultTemplate(for: type)
    }
    
    private func loadDefaultTemplates() {
        // Load predefined templates
        templates[.requestForQuote] = createRFQTemplate()
        templates[.sow] = createSOWTemplate()
        templates[.justificationApproval] = createJustificationTemplate()
    }
    
    private func createRFQTemplate() -> LLMDocumentTemplate {
        LLMDocumentTemplate(
            id: "rfq-standard",
            documentTitle: "Request for Quote",
            systemPrompt: """
            You are a government contracting specialist creating a Request for Quote (RFQ).
            Follow FAR Part 13 simplified acquisition procedures.
            Be clear, concise, and include all required elements.
            """,
            basePrompt: "Generate a Request for Quote document with the following information:",
            outputInstructions: """
            Format the output as a professional RFQ with clear sections:
            1. Description of Supplies/Services
            2. Delivery Requirements
            3. Evaluation Criteria
            4. Submission Instructions
            5. Terms and Conditions
            """,
            sections: [
                DocumentSectionTemplate(
                    title: "Description of Supplies/Services",
                    prompt: "Describe the supplies or services being requested",
                    contextRequirements: ["item descriptions", "quantities", "specifications"]
                ),
                DocumentSectionTemplate(
                    title: "Delivery Requirements",
                    prompt: "Specify delivery or performance requirements",
                    contextRequirements: ["delivery date", "location", "schedule"]
                )
            ],
            temperature: 0.7,
            maxTokens: 2000
        )
    }
    
    private func createSOWTemplate() -> LLMDocumentTemplate {
        LLMDocumentTemplate(
            id: "sow-standard",
            documentTitle: "Statement of Work",
            systemPrompt: """
            You are a government contracting specialist creating a Statement of Work (SOW).
            Ensure clarity, measurability, and compliance with acquisition regulations.
            """,
            basePrompt: "Generate a Statement of Work document with the following scope:",
            outputInstructions: """
            Format as a professional SOW with:
            1. Scope
            2. Requirements
            3. Deliverables
            4. Performance Standards
            5. Schedule
            """,
            sections: [],
            temperature: 0.7,
            maxTokens: 3000
        )
    }
    
    private func createJustificationTemplate() -> LLMDocumentTemplate {
        LLMDocumentTemplate(
            id: "justification-standard",
            documentTitle: "Justification Document",
            systemPrompt: """
            You are creating a justification document for government acquisition.
            Provide clear rationale and supporting evidence for the procurement decision.
            """,
            basePrompt: "Generate a justification document for the following acquisition:",
            outputInstructions: """
            Include:
            1. Background
            2. Requirement Description
            3. Market Research
            4. Justification
            5. Recommendation
            """,
            sections: [],
            temperature: 0.6,
            maxTokens: 2500
        )
    }
    
    private func createDefaultTemplate(for type: DocumentType) -> LLMDocumentTemplate {
        LLMDocumentTemplate(
            id: "\(type.rawValue)-default",
            documentTitle: type.displayName,
            systemPrompt: "You are creating a government acquisition document.",
            basePrompt: "Generate a \(type.displayName) with the provided information:",
            outputInstructions: "Format the output professionally with clear sections.",
            sections: [],
            temperature: 0.7,
            maxTokens: 2000
        )
    }
}

public struct LLMDocumentTemplate {
    public let id: String
    public let documentTitle: String
    public let systemPrompt: String
    public let basePrompt: String
    public let outputInstructions: String
    public let sections: [DocumentSectionTemplate]
    public let temperature: Double
    public let maxTokens: Int
    public let preferredModel: String?
    
    public init(
        id: String,
        documentTitle: String,
        systemPrompt: String,
        basePrompt: String,
        outputInstructions: String,
        sections: [DocumentSectionTemplate],
        temperature: Double = 0.7,
        maxTokens: Int = 2000,
        preferredModel: String? = nil
    ) {
        self.id = id
        self.documentTitle = documentTitle
        self.systemPrompt = systemPrompt
        self.basePrompt = basePrompt
        self.outputInstructions = outputInstructions
        self.sections = sections
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.preferredModel = preferredModel
    }
}

public struct DocumentSectionTemplate {
    public let title: String
    public let prompt: String
    public let contextRequirements: [String]?
    public let temperature: Double?
    public let metadata: [String: String]
    
    public init(
        title: String,
        prompt: String,
        contextRequirements: [String]? = nil,
        temperature: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.title = title
        self.prompt = prompt
        self.contextRequirements = contextRequirements
        self.temperature = temperature
        self.metadata = metadata
    }
}

// MARK: - Extensions

extension DocumentType {
    var displayName: String {
        return self.rawValue
    }
}

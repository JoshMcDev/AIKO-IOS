import Foundation

// MARK: - Claude API Integration for Natural Conversation

/// Manages integration with Claude API for natural language conversations
/// Note: This is a mock implementation for demonstration purposes
@MainActor
public class ClaudeAPIIntegration {
    
    // MARK: - Types
    
    public struct ConversationRequest {
        public let prompt: String
        public let context: ConversationContext
        public let extractedData: [String: String]
        public let userPatterns: [String: String]
        public let systemPrompt: String?
    }
    
    public struct ConversationResponse {
        public let message: String
        public let suggestedActions: [SuggestedAction]
        public let extractedFields: [String: String]
        public let confidence: Double
        public let requiresFollowUp: Bool
    }
    
    public struct SuggestedAction {
        public let action: String
        public let reason: String
        public let priority: ActionPriority
        
        public enum ActionPriority {
            case high, medium, low
        }
    }
    
    public struct ConversationContext {
        public let userId: String
        public let sessionId: String
        public let documentType: DocumentType
        public let conversationHistory: [ConversationTurn]
        public let metadata: [String: String]
    }
    
    public struct ConversationTurn {
        public let role: Role
        public let message: String
        public let timestamp: Date
        
        public enum Role {
            case user, assistant
        }
    }
    
    // MARK: - Properties
    
    private let apiKey: String?
    private let modelVersion = "claude-3-opus"
    private let maxTokens = 4096
    private let temperature = 0.7
    
    // MARK: - Initialization
    
    public init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["CLAUDE_API_KEY"]
    }
    
    // MARK: - Public Methods
    
    /// Send a conversation request to Claude
    public func sendConversation(_ request: ConversationRequest) async throws -> ConversationResponse {
        // In production, this would make an actual API call
        // For now, we'll simulate intelligent responses
        
        let response = await generateMockResponse(for: request)
        
        // Log for analytics
        await logConversation(request: request, response: response)
        
        return response
    }
    
    /// Stream a conversation for real-time interaction
    public func streamConversation(
        _ request: ConversationRequest,
        onChunk: @escaping (String) -> Void
    ) async throws {
        // Simulate streaming response
        let fullResponse = await generateMockResponse(for: request)
        
        // Break into chunks and stream
        let words = fullResponse.message.split(separator: " ")
        for word in words {
            onChunk(String(word) + " ")
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        }
    }
    
    /// Generate a system prompt optimized for acquisition context
    public func generateSystemPrompt(
        for documentType: DocumentType,
        with context: ConversationContext
    ) -> String {
        """
        You are AIKO, an intelligent acquisition assistant for government procurement.
        
        Your role is to:
        1. Guide users through the acquisition process with minimal questions
        2. Extract maximum information from uploaded documents
        3. Apply smart defaults based on patterns and context
        4. Ensure FAR/DFAR compliance
        5. Provide clear, concise guidance
        
        Current context:
        - Document Type: \(documentType.rawValue)
        - User Organization: \(context.metadata["organization"] ?? "Unknown")
        - Acquisition Phase: \(context.metadata["phase"] ?? "Initial")
        
        Guidelines:
        - Ask only essential questions that cannot be inferred
        - Provide confidence levels for extracted/inferred data
        - Explain compliance requirements when relevant
        - Suggest next steps proactively
        - Learn from user corrections
        
        Response style:
        - Professional but conversational
        - Clear and concise
        - Action-oriented
        - Compliance-aware
        """
    }
    
    // MARK: - Private Methods
    
    private func generateMockResponse(for request: ConversationRequest) async -> ConversationResponse {
        // Analyze the request to determine appropriate response
        let analysis = analyzeRequest(request)
        
        // Generate contextual response
        let message = generateContextualMessage(
            for: analysis,
            request: request
        )
        
        // Extract any fields mentioned in the conversation
        let extractedFields = extractFieldsFromConversation(
            request.prompt,
            context: request.context
        )
        
        // Generate suggested actions
        let suggestedActions = generateSuggestedActions(
            for: analysis,
            extractedData: request.extractedData
        )
        
        // Determine if follow-up is needed
        let requiresFollowUp = determineFollowUpNeed(
            analysis: analysis,
            extractedData: request.extractedData
        )
        
        return ConversationResponse(
            message: message,
            suggestedActions: suggestedActions,
            extractedFields: extractedFields,
            confidence: analysis.confidence,
            requiresFollowUp: requiresFollowUp
        )
    }
    
    private func analyzeRequest(_ request: ConversationRequest) -> RequestAnalysis {
        var analysis = RequestAnalysis()
        
        // Analyze intent
        let prompt = request.prompt.lowercased()
        if prompt.contains("quote") || prompt.contains("price") {
            analysis.intent = .priceInquiry
        } else if prompt.contains("delivery") || prompt.contains("when") {
            analysis.intent = .deliveryInquiry
        } else if prompt.contains("vendor") || prompt.contains("supplier") {
            analysis.intent = .vendorInquiry
        } else if prompt.contains("approve") || prompt.contains("approval") {
            analysis.intent = .approvalProcess
        } else {
            analysis.intent = .general
        }
        
        // Calculate completeness
        let requiredFields = getRequiredFields(for: request.context.documentType)
        let providedFields = Set(request.extractedData.keys)
        analysis.completeness = Double(providedFields.count) / Double(requiredFields.count)
        
        // Set confidence based on data quality
        analysis.confidence = min(0.95, analysis.completeness + 0.2)
        
        // Identify missing critical information
        analysis.missingFields = requiredFields.subtracting(providedFields)
        
        return analysis
    }
    
    private func generateContextualMessage(
        for analysis: RequestAnalysis,
        request: ConversationRequest
    ) -> String {
        switch analysis.intent {
        case .priceInquiry:
            if let price = request.extractedData["totalPrice"] {
                return """
                I see the total price is \(price). This appears to be within the simplified \
                acquisition threshold. Based on your patterns, I recommend using your standard \
                Fixed Price contract vehicle. Would you like me to prepare the purchase request \
                with this pricing?
                """
            } else {
                return "I don't see pricing information in the uploaded document. Could you provide the quote amount?"
            }
            
        case .deliveryInquiry:
            if let delivery = request.extractedData["delivery"] {
                return """
                The vendor quotes \(delivery) delivery. Based on your requirement date and \
                current date, this timeline works well. I'll note this in the purchase request. \
                Do you need any special delivery instructions for Joint Communications Unit?
                """
            } else {
                return "What's your required delivery date? I'll check if the vendor can meet this timeline."
            }
            
        case .vendorInquiry:
            if let vendor = request.extractedData["vendor"] {
                return """
                \(vendor) is the vendor on this quote. I've verified their registration in SAM.gov \
                and they have an active CAGE code. They're approved for government contracts. \
                Shall I proceed with them as the selected vendor?
                """
            } else {
                return "Which vendor would you like to use for this acquisition?"
            }
            
        case .approvalProcess:
            let amount = request.extractedData["totalPrice"] ?? "unknown amount"
            return """
            Based on the \(amount) value, this will route to Col. Smith for approval \
            (your usual approver). I'll include all necessary justification documents. \
            The approval chain typically takes 2-3 days. Ready to submit?
            """
            
        case .general:
            if analysis.completeness > 0.8 {
                return """
                I have most of the information needed from your uploaded document. \
                Let me just confirm: Is this for expanding capability at Joint Communications Unit? \
                Once confirmed, I can generate all required acquisition documents.
                """
            } else {
                return """
                I've extracted some information from your document, but I need a few more details \
                to complete the acquisition package. What type of requirement is this for?
                """
            }
        }
    }
    
    private func extractFieldsFromConversation(
        _ prompt: String,
        context: ConversationContext
    ) -> [String: String] {
        var extracted: [String: String] = [:]
        
        // Simple extraction logic - in production this would use NLP
        if prompt.contains("expand capability") {
            extracted["justification"] = "Capability expansion for mission requirements"
            extracted["acquisitionType"] = "New Requirement"
        }
        
        if prompt.contains("secure facility") {
            extracted["specialRequirements"] = "Secure facility installation required"
            extracted["securityLevel"] = "High"
        }
        
        if prompt.contains("cleared personnel") {
            extracted["installationRequirements"] = "Cleared personnel required for setup"
        }
        
        return extracted
    }
    
    private func generateSuggestedActions(
        for analysis: RequestAnalysis,
        extractedData: [String: String]
    ) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []
        
        // Always suggest document generation when ready
        if analysis.completeness > 0.7 {
            actions.append(SuggestedAction(
                action: "Generate acquisition documents",
                reason: "Sufficient information available",
                priority: .high
            ))
        }
        
        // Suggest compliance check for certain items
        if let product = extractedData["product"],
           product.lowercased().contains("haipe") || product.lowercased().contains("classified") {
            actions.append(SuggestedAction(
                action: "Run security compliance check",
                reason: "Security-sensitive equipment detected",
                priority: .high
            ))
        }
        
        // Suggest vendor verification
        if extractedData["vendor"] != nil {
            actions.append(SuggestedAction(
                action: "Verify vendor in SAM.gov",
                reason: "Ensure active registration",
                priority: .medium
            ))
        }
        
        // Suggest funding verification for high-value items
        if let price = extractedData["totalPrice"],
           let amount = parseAmount(price),
           amount > 50000 {
            actions.append(SuggestedAction(
                action: "Verify funding availability",
                reason: "High-value acquisition",
                priority: .high
            ))
        }
        
        return actions
    }
    
    private func determineFollowUpNeed(
        analysis: RequestAnalysis,
        extractedData: [String: String]
    ) -> Bool {
        // Need follow-up if critical fields are missing
        let criticalFields = ["vendor", "totalPrice", "product", "quantity"]
        for field in criticalFields {
            if extractedData[field] == nil {
                return true
            }
        }
        
        // Need follow-up if completeness is low
        return analysis.completeness < 0.7
    }
    
    private func getRequiredFields(for documentType: DocumentType) -> Set<String> {
        switch documentType {
        case .requestForQuote:
            return ["vendor", "product", "quantity", "totalPrice", "deliveryDate", "justification"]
        case .requestForProposal:
            return ["requirements", "evaluationCriteria", "submissionDeadline", "setAside"]
        case .contractScaffold:
            return ["vendor", "amount", "period", "deliverables", "terms"]
        default:
            return ["description", "amount", "vendor"]
        }
    }
    
    private func parseAmount(_ value: String) -> Double? {
        let cleanValue = value
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleanValue)
    }
    
    private func logConversation(request: ConversationRequest, response: ConversationResponse) async {
        // Log for analytics and learning
        print("📊 Conversation Analytics:")
        print("  Intent: \(request.prompt.prefix(50))...")
        print("  Confidence: \(Int(response.confidence * 100))%")
        print("  Follow-up needed: \(response.requiresFollowUp)")
        print("  Actions suggested: \(response.suggestedActions.count)")
    }
    
    // MARK: - Supporting Types
    
    private struct RequestAnalysis {
        var intent: ConversationIntent = .general
        var completeness: Double = 0.0
        var confidence: Double = 0.0
        var missingFields: Set<String> = []
        
        enum ConversationIntent {
            case priceInquiry
            case deliveryInquiry
            case vendorInquiry
            case approvalProcess
            case general
        }
    }
}

// MARK: - Mock API Response Examples

extension ClaudeAPIIntegration {
    /// Example responses for different scenarios
    public static let exampleResponses = [
        "initial_upload": """
        I've successfully extracted key information from your quote. I found the vendor \
        (Morgan Technical Offerings), pricing ($114,439.38), and delivery timeline (120 days). \
        Based on your history, this looks like equipment for Joint Communications Unit. \
        Is this to replace existing equipment or expand capability?
        """,
        
        "missing_justification": """
        I have most of the required information, but I need to understand the justification \
        for this acquisition. What operational need does this equipment address?
        """,
        
        "ready_to_generate": """
        Perfect! I have all the information needed. I'll generate:
        - Purchase Request (DD Form 1348-6)
        - Sole Source Justification (for specialized HAIPE equipment)
        - Funding Certification
        - Technical Requirements document
        
        This will route to Col. Smith for approval. Shall I proceed?
        """,
        
        "compliance_alert": """
        I notice this is HAIPE-compatible equipment which requires special handling. \
        I'll include the security requirements addendum and ensure proper COMSEC \
        procedures are documented. The vendor is cleared for this type of equipment.
        """
    ]
}
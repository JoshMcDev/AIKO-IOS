import ComposableArchitecture
import Foundation
import SwiftAnthropic

// MARK: - Enhanced Acquisition Chat Feature with Adaptive Prompting

@Reducer
public struct AcquisitionChatFeatureEnhanced {
    @ObservableState
    public struct State: Equatable {
        // Existing chat state
        public var messages: [EnhancedChatMessage] = []
        public var currentInput: String = ""
        public var isProcessing: Bool = false
        public var acquisitionId: UUID?
        public var showingCloseConfirmation: Bool = false
        
        // Document handling
        public var showingDocumentPicker: Bool = false
        public var uploadedDocuments: [EnhancedUploadedDocument] = []
        public var parsedDocuments: [ParsedDocument] = []
        
        // Adaptive prompting state
        public var conversationSession: ConversationSession?
        public var extractedContext: ExtractedContext?
        public var currentQuestion: DynamicQuestion?
        public var collectedData: RequirementsData = .init()
        public var confidence: ConfidenceLevel = .low
        
        // Document readiness
        public var recommendedDocuments: Set<DocumentType> = []
        public var documentReadiness: [DocumentType: Bool] = [:]
        
        public init() {
            // Add initial greeting
            messages.append(EnhancedChatMessage(
                role: .assistant,
                content: """
                # Welcome to AIKO Acquisition Assistant
                
                I'll help you create a new acquisition by gathering the essential information needed. 
                
                **You can:**
                - Upload documents (quotes, specs, invoices) and I'll extract information automatically
                - Describe your requirements in natural language
                - Answer my adaptive questions to fill in any gaps
                
                Would you like to start by uploading a document or describing what you need?
                """
            ))
        }
        
        public var inputPlaceholder: String {
            if let question = currentQuestion {
                return question.contextualPlaceholder ?? "Enter your response..."
            }
            return "Upload a document or describe what you need..."
        }
    }
    
    public enum Action {
        case onAppear
        case sendMessage
        case updateInput(String)
        case documentPicked(EnhancedUploadedDocument)
        case documentsParsed([ParsedDocument])
        case showDocumentPicker
        case dismissDocumentPicker
        case closeChat
        case confirmClose
        case cancelClose
        case generateDocuments
        
        // Adaptive prompting actions
        case startAdaptiveConversation
        case conversationStarted(ConversationSession)
        case processUserResponse
        case nextPromptReceived(NextPrompt?)
        case contextExtracted(ExtractedContext)
        case smartDefaultsReceived(FieldDefault?)
        case updateConfidence(ConfidenceLevel)
        case recommendDocuments(Set<DocumentType>)
        case saveAcquisition
        case acquisitionSaved(UUID)
        case error(String)
    }
    
    @Dependency(\.adaptivePromptingEngine) var promptingEngine
    @Dependency(\.documentParserEnhanced) var documentParser
    @Dependency(\.acquisitionService) var acquisitionService
    @Dependency(\.continuousClock) var clock
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action -> Effect<Action> in
            switch action {
            case .onAppear:
                return .send(.startAdaptiveConversation)
                
            case .startAdaptiveConversation:
                state.isProcessing = true
                
                return .run { [uploadedDocs = state.parsedDocuments, promptingEngine = self.promptingEngine] send in
                    // Create conversation context
                    let context = ConversationContext(
                        acquisitionType: .supplies, // Will be refined based on user input
                        uploadedDocuments: uploadedDocs,
                        userProfile: nil, // TODO: Load from profile service
                        historicalData: [] // TODO: Load from acquisition service
                    )
                    
                    // Start adaptive conversation
                    let session = await promptingEngine.startConversation(with: context)
                    await send(.conversationStarted(session))
                }
                
            case let .conversationStarted(session):
                state.conversationSession = session
                state.collectedData = session.collectedData
                state.confidence = session.confidence
                
                // Show first question if available
                if let firstQuestion = session.remainingQuestions.first {
                    state.currentQuestion = firstQuestion
                    
                    // Add question to chat
                    state.messages.append(EnhancedChatMessage(
                        role: .assistant,
                        content: AcquisitionChatFeatureEnhanced.formatQuestionForChat(firstQuestion)
                    ))
                }
                
                state.isProcessing = false
                return .none
                
            case .sendMessage:
                guard !state.currentInput.isEmpty else { return .none }
                
                // Add user message
                state.messages.append(EnhancedChatMessage(
                    role: .user,
                    content: state.currentInput
                ))
                
                state.currentInput = ""
                
                return .send(.processUserResponse)
                
            case .processUserResponse:
                guard let session = state.conversationSession,
                      let currentQuestion = state.currentQuestion else { return .none }
                
                state.isProcessing = true
                let lastUserMessage = state.messages.last { $0.role == .user }?.content ?? ""
                
                return .run { [promptingEngine = self.promptingEngine] send in
                    // Create user response
                    let response = UserResponse(
                        questionId: currentQuestion.id.uuidString,
                        responseType: .text,
                        value: lastUserMessage
                    )
                    
                    // Process response and get next prompt
                    if let nextPrompt = try await promptingEngine.processUserResponse(response, in: session) {
                        await send(.nextPromptReceived(nextPrompt))
                    } else {
                        // No more questions, ready to generate
                        await send(.nextPromptReceived(nil))
                    }
                }
                
            case let .nextPromptReceived(nextPrompt):
                state.isProcessing = false
                
                if let prompt = nextPrompt {
                    // Update current question
                    state.currentQuestion = prompt.question
                    
                    // Show the question with any smart defaults
                    var message = AcquisitionChatFeatureEnhanced.formatQuestionForChat(prompt.question)
                    
                    if let suggestion = prompt.suggestedAnswer {
                        message += "\n\n💡 **Suggested answer**: \(suggestion)"
                        message += "\n*Confidence: \(Int(prompt.confidenceInSuggestion * 100))%*"
                    }
                    
                    state.messages.append(EnhancedChatMessage(
                        role: .assistant,
                        content: message
                    ))
                } else {
                    // All questions answered, show summary
                    state.currentQuestion = nil
                    state.messages.append(EnhancedChatMessage(
                        role: .assistant,
                        content: """
                        # Information Gathering Complete! ✅
                        
                        I've collected all the necessary information for your acquisition:
                        
                        **Project**: \(state.collectedData.projectTitle ?? "Untitled")
                        **Estimated Value**: $\(state.collectedData.estimatedValue ?? 0)
                        **Vendor**: \(state.collectedData.vendorInfo?.name ?? "TBD")
                        **Confidence**: \(state.confidence.description)
                        
                        **Recommended Documents**:
                        \(state.recommendedDocuments.map { "- \($0.shortName)" }.joined(separator: "\n"))
                        
                        Would you like to:
                        - Generate the recommended documents
                        - Review and modify the information
                        - Add additional details
                        """
                    ))
                    
                    // Update document readiness
                    for doc in state.recommendedDocuments {
                        state.documentReadiness[doc] = true
                    }
                }
                
                return .none
                
            case let .updateInput(input):
                state.currentInput = input
                return .none
                
            case let .documentPicked(uploadedDoc):
                state.uploadedDocuments.append(uploadedDoc)
                state.isProcessing = true
                
                // Show upload confirmation
                state.messages.append(EnhancedChatMessage(
                    role: .assistant,
                    content: "📄 Processing \(uploadedDoc.fileName)..."
                ))
                
                return .run { [data = uploadedDoc.data, fileName = uploadedDoc.fileName, documentParser = self.documentParser] send in
                    do {
                        // Determine document type
                        let type = AcquisitionChatFeatureEnhanced.determineDocumentType(from: fileName)
                        
                        // Parse document
                        let parsedDoc = try await documentParser.parse(data, type: type)
                        await send(.documentsParsed([parsedDoc]))
                    } catch {
                        await send(.error("Failed to parse document: \(error.localizedDescription)"))
                    }
                }
                
            case let .documentsParsed(parsedDocs):
                state.parsedDocuments.append(contentsOf: parsedDocs)
                state.isProcessing = true
                
                return .run { [docs = parsedDocs, promptingEngine = self.promptingEngine] send in
                    // Extract context from documents
                    let context = try await promptingEngine.extractContextFromDocuments(docs)
                    await send(.contextExtracted(context))
                }
                
            case let .contextExtracted(context):
                state.extractedContext = context
                
                // Show what was extracted
                var extractedInfo = "✅ **Successfully extracted information:**\n"
                
                if let vendor = context.vendorInfo {
                    extractedInfo += "\n**Vendor**: \(vendor.name ?? "Unknown")"
                    if let uei = vendor.uei {
                        extractedInfo += " (UEI: \(uei))"
                    }
                    state.collectedData.vendorInfo = APEVendorInfo(
                        name: vendor.name,
                        uei: vendor.uei,
                        cage: vendor.cage,
                        email: vendor.email,
                        phone: vendor.phone
                    )
                }
                
                if let pricing = context.pricing {
                    if let total = pricing.totalPrice {
                        extractedInfo += "\n**Total Price**: $\(total)"
                        state.collectedData.estimatedValue = total
                    }
                    extractedInfo += "\n**Line Items**: \(pricing.unitPrices.count)"
                }
                
                if !context.technicalDetails.isEmpty {
                    extractedInfo += "\n**Technical Details**: Found \(context.technicalDetails.count) specifications"
                    state.collectedData.technicalRequirements = context.technicalDetails
                }
                
                state.messages.append(EnhancedChatMessage(
                    role: .assistant,
                    content: extractedInfo + "\n\nI'll use this information to minimize the questions I need to ask."
                ))
                
                // Update conversation session with extracted data
                if state.conversationSession != nil {
                    let collectedData = state.collectedData
                    state.conversationSession?.collectedData = collectedData
                    state.conversationSession?.confidence = .medium
                }
                
                state.isProcessing = false
                
                // Continue with adaptive questions for missing info
                return .send(.processUserResponse)
                
            case .showDocumentPicker:
                state.showingDocumentPicker = true
                return .none
                
            case .dismissDocumentPicker:
                state.showingDocumentPicker = false
                return .none
                
            case .closeChat:
                state.showingCloseConfirmation = true
                return .none
                
            case .confirmClose:
                // Save acquisition before closing
                return .send(.saveAcquisition)
                
            case .cancelClose:
                state.showingCloseConfirmation = false
                return .none
                
            case .generateDocuments:
                // Save acquisition and trigger document generation
                return .send(.saveAcquisition)
                
            case .saveAcquisition:
                state.isProcessing = true
                
                return .run { [data = state.collectedData, acquisitionService = self.acquisitionService] send in
                    do {
                        // Create acquisition from collected data
                        let acquisition = try await acquisitionService.createAcquisition(
                            data.projectTitle ?? "Untitled",
                            AcquisitionChatFeatureEnhanced.formatRequirements(data),
                            [] // No uploaded documents for now
                        )
                        
                        await send(.acquisitionSaved(acquisition.id ?? UUID()))
                    } catch {
                        await send(.error("Failed to save acquisition: \(error.localizedDescription)"))
                    }
                }
                
            case let .acquisitionSaved(id):
                state.acquisitionId = id
                state.isProcessing = false
                
                // Record user patterns for learning
                if let session = state.conversationSession {
                    return .run { [promptingEngine = self.promptingEngine, session = session, parsedDocuments = state.parsedDocuments, collectedData = state.collectedData] send in
                        // Learn from this interaction
                        for question in session.questionHistory {
                            let interaction = APEUserInteraction(
                                sessionId: session.id,
                                field: question.question.field,
                                suggestedValue: nil, // TODO: Track suggestions
                                acceptedSuggestion: false,
                                finalValue: collectedData.value(for: question.question.field) as Any,
                                timeToRespond: 0, // TODO: Track timing
                                documentContext: !parsedDocuments.isEmpty
                            )
                            await promptingEngine.learnFromInteraction(interaction)
                        }
                    }
                }
                
                return .none
                
            case let .recommendDocuments(documents):
                state.recommendedDocuments = documents
                return .none
                
            case let .updateConfidence(confidence):
                state.confidence = confidence
                return .none
                
            case let .error(message):
                state.isProcessing = false
                state.messages.append(EnhancedChatMessage(
                    role: .assistant,
                    content: "❌ **Error**: \(message)\n\nPlease try again or contact support if the issue persists."
                ))
                return .none
                
            case .smartDefaultsReceived(_):
                // Handle smart defaults if needed
                // For now, just ignore as defaults are handled in nextPromptReceived
                return .none
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private static func formatQuestionForChat(_ question: DynamicQuestion) -> String {
        var message = "### \(question.prompt)\n"
        
        if let help = question.helpText {
            message += "\n*\(help)*\n"
        }
        
        if !question.examples.isEmpty {
            message += "\n**Examples**:\n"
            for example in question.examples {
                message += "- \(example)\n"
            }
        }
        
        if question.isRequired {
            message += "\n⚠️ *This information is required*"
        } else {
            message += "\n💡 *Optional - you can skip this if not applicable*"
        }
        
        return message
    }
    
    private static func determineDocumentType(from fileName: String) -> ParsedDocumentType {
        let lowercased = fileName.lowercased()
        
        if lowercased.hasSuffix(".pdf") { return .pdf }
        if lowercased.hasSuffix(".doc") || lowercased.hasSuffix(".docx") { return .word }
        if lowercased.hasSuffix(".txt") { return .text }
        if lowercased.hasSuffix(".png") { return .png }
        if lowercased.hasSuffix(".jpg") || lowercased.hasSuffix(".jpeg") { return .jpg }
        if lowercased.hasSuffix(".heic") { return .heic }
        
        return .unknown
    }
    
    private static func formatRequirements(_ data: RequirementsData) -> String {
        var requirements = ""
        
        if let title = data.projectTitle {
            requirements += "Project: \(title)\n"
        }
        
        if let value = data.estimatedValue {
            requirements += "Estimated Value: $\(value)\n"
        }
        
        if let vendor = data.vendorInfo {
            requirements += "\nVendor Information:\n"
            requirements += "- Name: \(vendor.name ?? "Unknown")\n"
            if let uei = vendor.uei {
                requirements += "- UEI: \(uei)\n"
            }
        }
        
        if let type = data.acquisitionType {
            requirements += "\nType: \(type)\n"
        }
        
        if !data.technicalRequirements.isEmpty {
            requirements += "\nTechnical Requirements:\n"
            for req in data.technicalRequirements {
                requirements += "- \(req)\n"
            }
        }
        
        return requirements
    }
    
    private static func generateProjectNumber() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        let random = Int.random(in: 1000...9999)
        return "AIKO-\(dateString)-\(random)"
    }
}

// MARK: - Supporting Types

public struct EnhancedUploadedDocument: Equatable, Identifiable {
    public let id = UUID()
    public let fileName: String
    public let data: Data
    public let uploadDate: Date
    
    public init(fileName: String, data: Data) {
        self.fileName = fileName
        self.data = data
        self.uploadDate = Date()
    }
}

public struct EnhancedChatMessage: Equatable, Identifiable {
    public let id = UUID()
    public let role: EnhancedChatRole
    public let content: String
    public let timestamp: Date
    
    public init(role: EnhancedChatRole, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

public enum EnhancedChatRole: Equatable {
    case user
    case assistant
}

// MARK: - Dependencies

extension DependencyValues {
    public var adaptivePromptingEngine: AdaptivePromptingEngine {
        get { self[AdaptivePromptingEngineKey.self] }
        set { self[AdaptivePromptingEngineKey.self] = newValue }
    }
    
    public var documentParserEnhanced: DocumentParserEnhanced {
        get { self[DocumentParserEnhancedKey.self] }
        set { self[DocumentParserEnhancedKey.self] = newValue }
    }
}

private enum AdaptivePromptingEngineKey: DependencyKey {
    @MainActor
    static var liveValue: AdaptivePromptingEngine {
        AdaptivePromptingEngine()
    }
}

private enum DocumentParserEnhancedKey: DependencyKey {
    static let liveValue = DocumentParserEnhanced()
}

// MARK: - Extensions

extension RequirementsData {
    func value(for field: RequirementField) -> Any? {
        switch field {
        case .projectTitle: return projectTitle
        case .description: return description
        case .estimatedValue: return estimatedValue
        case .vendorName: return vendorInfo?.name
        case .vendorUEI: return vendorInfo?.uei
        case .vendorCAGE: return vendorInfo?.cage
        case .performanceLocation: return placeOfPerformance
        case .contractType: return acquisitionType
        case .setAsideType: return setAsideType
        case .technicalSpecs: return technicalRequirements
        case .requiredDate: return requiredDate
        case .specialConditions: return specialConditions
        case .justification: return businessJustification
        case .fundingSource, .requisitionNumber, .costCenter, .accountingCode,
             .qualityRequirements, .deliveryInstructions, .packagingRequirements,
             .inspectionRequirements, .paymentTerms, .warrantyRequirements, .pointOfContact:
            return nil // These fields are not yet in the data model
        case .attachments: return attachments
        }
    }
}

extension ConfidenceLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
}
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Core Protocol

public protocol AdaptivePromptingEngineProtocol {
    func startConversation(with context: ConversationContext) async -> ConversationSession
    func processUserResponse(_ response: UserResponse, in session: ConversationSession) async throws -> NextPrompt?
    func extractContextFromDocuments(_ documents: [ParsedDocument]) async throws -> ExtractedContext
    func learnFromInteraction(_ interaction: APEUserInteraction) async
    func getSmartDefaults(for field: RequirementField) async -> FieldDefault?
}

// MARK: - Data Models

public struct ConversationContext {
    public let acquisitionType: APEAcquisitionType
    public let uploadedDocuments: [ParsedDocument]
    public let userProfile: ConversationUserProfile?
    public let historicalData: [HistoricalAcquisition]
    
    public init(
        acquisitionType: APEAcquisitionType,
        uploadedDocuments: [ParsedDocument] = [],
        userProfile: ConversationUserProfile? = nil,
        historicalData: [HistoricalAcquisition] = []
    ) {
        self.acquisitionType = acquisitionType
        self.uploadedDocuments = uploadedDocuments
        self.userProfile = userProfile
        self.historicalData = historicalData
    }
}

public struct ConversationSession: Identifiable, Equatable {
    public let id = UUID()
    public let startTime = Date()
    public var state: ConversationState
    public var collectedData: RequirementsData
    public var questionHistory: [AskedQuestion]
    public var remainingQuestions: [DynamicQuestion]
    public var confidence: ConfidenceLevel
    public var suggestedAnswers: [RequirementField: Any]?
    public var autoFillResult: ConfidenceBasedAutoFillEngine.AutoFillResult?
    
    public init(
        state: ConversationState = .starting,
        collectedData: RequirementsData = RequirementsData(),
        questionHistory: [AskedQuestion] = [],
        remainingQuestions: [DynamicQuestion] = [],
        confidence: ConfidenceLevel = .low,
        suggestedAnswers: [RequirementField: Any]? = nil,
        autoFillResult: ConfidenceBasedAutoFillEngine.AutoFillResult? = nil
    ) {
        self.state = state
        self.collectedData = collectedData
        self.questionHistory = questionHistory
        self.remainingQuestions = remainingQuestions
        self.confidence = confidence
        self.suggestedAnswers = suggestedAnswers
        self.autoFillResult = autoFillResult
    }
    
    public static func == (lhs: ConversationSession, rhs: ConversationSession) -> Bool {
        lhs.id == rhs.id &&
        lhs.startTime == rhs.startTime &&
        lhs.state == rhs.state &&
        lhs.collectedData == rhs.collectedData &&
        lhs.questionHistory == rhs.questionHistory &&
        lhs.remainingQuestions == rhs.remainingQuestions &&
        lhs.confidence == rhs.confidence
        // Note: suggestedAnswers is not compared due to Any type
    }
}

public enum ConversationState: Equatable {
    case starting
    case gatheringBasicInfo
    case extractingFromDocuments
    case fillingGaps
    case confirmingDetails
    case complete
}

public struct RequirementsData: Equatable {
    public var projectTitle: String?
    public var description: String?
    public var estimatedValue: Decimal?
    public var requiredDate: Date?
    public var technicalRequirements: [String]
    public var vendorInfo: APEVendorInfo?
    public var specialConditions: [String]
    public var attachments: [DocumentReference]
    public var performancePeriod: DateInterval?
    public var placeOfPerformance: String?
    public var businessJustification: String?
    public var acquisitionType: String?
    public var competitionMethod: String?
    public var setAsideType: String?
    public var evaluationCriteria: [String]
    
    public init(
        projectTitle: String? = nil,
        description: String? = nil,
        estimatedValue: Decimal? = nil,
        requiredDate: Date? = nil,
        technicalRequirements: [String] = [],
        vendorInfo: APEVendorInfo? = nil,
        specialConditions: [String] = [],
        attachments: [DocumentReference] = [],
        performancePeriod: DateInterval? = nil,
        placeOfPerformance: String? = nil,
        businessJustification: String? = nil,
        acquisitionType: String? = nil,
        competitionMethod: String? = nil,
        setAsideType: String? = nil,
        evaluationCriteria: [String] = []
    ) {
        self.projectTitle = projectTitle
        self.description = description
        self.estimatedValue = estimatedValue
        self.requiredDate = requiredDate
        self.technicalRequirements = technicalRequirements
        self.vendorInfo = vendorInfo
        self.specialConditions = specialConditions
        self.attachments = attachments
        self.performancePeriod = performancePeriod
        self.placeOfPerformance = placeOfPerformance
        self.businessJustification = businessJustification
        self.acquisitionType = acquisitionType
        self.competitionMethod = competitionMethod
        self.setAsideType = setAsideType
        self.evaluationCriteria = evaluationCriteria
    }
}

public struct APEVendorInfo: Equatable {
    public var name: String?
    public var uei: String?
    public var cage: String?
    public var email: String?
    public var phone: String?
    public var address: String?
    
    public init(name: String? = nil, uei: String? = nil, cage: String? = nil, email: String? = nil, phone: String? = nil, address: String? = nil) {
        self.name = name
        self.uei = uei
        self.cage = cage
        self.email = email
        self.phone = phone
        self.address = address
    }
}

public struct DocumentReference: Identifiable, Equatable {
    public let id = UUID()
    public let fileName: String
    public let documentType: DocumentType
    
    public init(fileName: String, documentType: DocumentType) {
        self.fileName = fileName
        self.documentType = documentType
    }
}

public struct UserResponse: Equatable {
    public let questionId: String
    public let responseType: ResponseType
    public let value: Any
    public let confidence: Float
    public let timestamp: Date
    
    public enum ResponseType: Equatable {
        case text
        case selection
        case numeric
        case date
        case boolean
        case document
        case skip
    }
    
    public init(questionId: String, responseType: ResponseType, value: Any, confidence: Float = 1.0) {
        self.questionId = questionId
        self.responseType = responseType
        self.value = value
        self.confidence = confidence
        self.timestamp = Date()
    }
    
    public static func == (lhs: UserResponse, rhs: UserResponse) -> Bool {
        // Basic comparison without value since Any isn't Equatable
        lhs.questionId == rhs.questionId &&
        lhs.responseType == rhs.responseType &&
        lhs.confidence == rhs.confidence &&
        lhs.timestamp == rhs.timestamp
    }
}

public struct NextPrompt {
    public let question: DynamicQuestion
    public let suggestedAnswer: Any?
    public let confidenceInSuggestion: Float
    public let isRequired: Bool
    public let helpText: String?
    
    public init(
        question: DynamicQuestion,
        suggestedAnswer: Any? = nil,
        confidenceInSuggestion: Float = 0,
        isRequired: Bool = true,
        helpText: String? = nil
    ) {
        self.question = question
        self.suggestedAnswer = suggestedAnswer
        self.confidenceInSuggestion = confidenceInSuggestion
        self.isRequired = isRequired
        self.helpText = helpText
    }
}

public struct DynamicQuestion: Identifiable, Equatable {
    public let id = UUID()
    public let field: RequirementField
    public let prompt: String
    public let responseType: UserResponse.ResponseType
    public let options: [String]?
    public let validation: ValidationRule?
    public let priority: QuestionPriority
    public let contextualPlaceholder: String?
    public let helpText: String?
    public let examples: [String]
    public let isRequired: Bool
    
    public enum QuestionPriority: Int, Comparable, Equatable {
        case critical = 0
        case high = 1
        case medium = 2
        case low = 3
        
        public static func < (lhs: QuestionPriority, rhs: QuestionPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    public init(
        field: RequirementField,
        prompt: String,
        responseType: UserResponse.ResponseType,
        options: [String]? = nil,
        validation: ValidationRule? = nil,
        priority: QuestionPriority = .medium,
        contextualPlaceholder: String? = nil,
        helpText: String? = nil,
        examples: [String] = [],
        isRequired: Bool = true
    ) {
        self.field = field
        self.prompt = prompt
        self.responseType = responseType
        self.options = options
        self.validation = validation
        self.priority = priority
        self.contextualPlaceholder = contextualPlaceholder
        self.helpText = helpText
        self.examples = examples
        self.isRequired = isRequired
    }
}

public enum RequirementField: String, CaseIterable, Equatable, Sendable {
    case projectTitle
    case description
    case estimatedValue
    case requiredDate
    case vendorName
    case vendorUEI
    case vendorCAGE
    case technicalSpecs
    case performanceLocation
    case contractType
    case setAsideType
    case specialConditions
    case justification
    case fundingSource
    case requisitionNumber
    case costCenter
    case accountingCode
    case qualityRequirements
    case deliveryInstructions
    case packagingRequirements
    case inspectionRequirements
    case paymentTerms
    case warrantyRequirements
    case attachments
    case pointOfContact
}

public struct ValidationRule: Equatable {
    public let type: ValidationType
    public let errorMessage: String
    
    public enum ValidationType: Equatable {
        case required
        case minLength(Int)
        case maxLength(Int)
        case regex(String)
        case range(min: Decimal, max: Decimal)
        case futureDate
        case custom(String) // Changed from closure to identifier for Equatable
        
        public static func == (lhs: ValidationType, rhs: ValidationType) -> Bool {
            switch (lhs, rhs) {
            case (.required, .required): return true
            case let (.minLength(a), .minLength(b)): return a == b
            case let (.maxLength(a), .maxLength(b)): return a == b
            case let (.regex(a), .regex(b)): return a == b
            case let (.range(minA, maxA), .range(minB, maxB)): return minA == minB && maxA == maxB
            case (.futureDate, .futureDate): return true
            case let (.custom(a), .custom(b)): return a == b
            default: return false
            }
        }
    }
    
    public init(type: ValidationType, errorMessage: String) {
        self.type = type
        self.errorMessage = errorMessage
    }
}

public struct AskedQuestion: Equatable {
    public let question: DynamicQuestion
    public let response: UserResponse?
    public let timestamp: Date
    public let skipped: Bool
    
    public init(question: DynamicQuestion, response: UserResponse?, skipped: Bool = false) {
        self.question = question
        self.response = response
        self.timestamp = Date()
        self.skipped = skipped
    }
}

public enum ConfidenceLevel: Float, Equatable {
    case low = 0.3
    case medium = 0.6
    case high = 0.8
    case veryHigh = 0.95
}

public struct ExtractedContext: Equatable {
    public let vendorInfo: APEVendorInfo?
    public let pricing: PricingInfo?
    public let technicalDetails: [String]
    public let dates: ExtractedDates?
    public let specialTerms: [String]
    public let confidence: [RequirementField: Float]
    
    public init(
        vendorInfo: APEVendorInfo? = nil,
        pricing: PricingInfo? = nil,
        technicalDetails: [String] = [],
        dates: ExtractedDates? = nil,
        specialTerms: [String] = [],
        confidence: [RequirementField: Float] = [:]
    ) {
        self.vendorInfo = vendorInfo
        self.pricing = pricing
        self.technicalDetails = technicalDetails
        self.dates = dates
        self.specialTerms = specialTerms
        self.confidence = confidence
    }
}

public struct PricingInfo: Equatable {
    public let totalPrice: Decimal?
    public let unitPrices: [APELineItem]
    public let currency: String
    
    public init(totalPrice: Decimal? = nil, unitPrices: [APELineItem] = [], currency: String = "USD") {
        self.totalPrice = totalPrice
        self.unitPrices = unitPrices
        self.currency = currency
    }
}

public struct APELineItem: Identifiable, Equatable {
    public let id: UUID
    public let description: String
    public let quantity: Int
    public let unitPrice: Decimal
    public let totalPrice: Decimal
    
    public init(id: UUID = UUID(), description: String, quantity: Int, unitPrice: Decimal, totalPrice: Decimal) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
    }
}

public struct ExtractedDates: Equatable {
    public var quoteDate: Date?
    public var validUntil: Date?
    public var deliveryDate: Date?
    public var performancePeriod: DateInterval?
    
    public init(
        quoteDate: Date? = nil,
        validUntil: Date? = nil,
        deliveryDate: Date? = nil,
        performancePeriod: DateInterval? = nil
    ) {
        self.quoteDate = quoteDate
        self.validUntil = validUntil
        self.deliveryDate = deliveryDate
        self.performancePeriod = performancePeriod
    }
}

public struct APEUserInteraction {
    public let sessionId: UUID
    public let field: RequirementField
    public let suggestedValue: Any?
    public let acceptedSuggestion: Bool
    public let finalValue: Any
    public let timeToRespond: TimeInterval
    public let documentContext: Bool
    
    public init(
        sessionId: UUID,
        field: RequirementField,
        suggestedValue: Any? = nil,
        acceptedSuggestion: Bool = false,
        finalValue: Any,
        timeToRespond: TimeInterval,
        documentContext: Bool = false
    ) {
        self.sessionId = sessionId
        self.field = field
        self.suggestedValue = suggestedValue
        self.acceptedSuggestion = acceptedSuggestion
        self.finalValue = finalValue
        self.timeToRespond = timeToRespond
        self.documentContext = documentContext
    }
}

public struct FieldDefault {
    public let value: Any
    public let confidence: Float
    public let source: DefaultSource
    
    public enum DefaultSource {
        case historical
        case userPattern
        case documentContext
        case systemDefault
        case contextual  // Advanced context-aware defaults
    }
    
    public init(value: Any, confidence: Float, source: DefaultSource) {
        self.value = value
        self.confidence = confidence
        self.source = source
    }
}

public struct HistoricalAcquisition {
    public let id: UUID
    public let date: Date
    public let type: APEAcquisitionType
    public let data: RequirementsData
    public let vendor: APEVendorInfo?
    
    public init(id: UUID = UUID(), date: Date, type: APEAcquisitionType, data: RequirementsData, vendor: APEVendorInfo? = nil) {
        self.id = id
        self.date = date
        self.type = type
        self.data = data
        self.vendor = vendor
    }
}

public enum APEAcquisitionType: String, Codable {
    case supplies
    case services
    case construction
    case researchAndDevelopment
}

// MARK: - Extensions

extension ExtractedContext {
    func toFieldMapping() -> [String: String] {
        var mapping: [String: String] = [:]
        
        // Add vendor info
        if let vendor = vendorInfo {
            if let name = vendor.name { mapping["vendorName"] = name }
            if let uei = vendor.uei { mapping["vendorUEI"] = uei }
            if let cage = vendor.cage { mapping["vendorCAGE"] = cage }
            if let email = vendor.email { mapping["vendorEmail"] = email }
            if let phone = vendor.phone { mapping["vendorPhone"] = phone }
            if let address = vendor.address { mapping["vendorAddress"] = address }
        }
        
        // Add pricing info
        if let pricing = pricing {
            if let total = pricing.totalPrice {
                mapping["estimatedValue"] = String(describing: total)
            }
        }
        
        // Add dates
        if let dates = dates {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            
            if let quoteDate = dates.quoteDate {
                mapping["quoteDate"] = formatter.string(from: quoteDate)
            }
            if let validUntil = dates.validUntil {
                mapping["validUntil"] = formatter.string(from: validUntil)
            }
            if let deliveryDate = dates.deliveryDate {
                mapping["deliveryDate"] = formatter.string(from: deliveryDate)
                mapping["requiredDate"] = formatter.string(from: deliveryDate)
            }
        }
        
        // Add technical details
        if !technicalDetails.isEmpty {
            mapping["technicalSpecs"] = technicalDetails.joined(separator: "; ")
        }
        
        // Add special terms
        if !specialTerms.isEmpty {
            mapping["specialConditions"] = specialTerms.joined(separator: "; ")
        }
        
        return mapping
    }
}

extension ConversationUserProfile {
    var organizationUnit: String {
        // Default organization unit - could be extended later
        return "Default Organization"
    }
}

// MARK: - Main Implementation

@MainActor
public class AdaptivePromptingEngine: AdaptivePromptingEngineProtocol {
    private let documentParser: DocumentParserEnhanced
    private let learningEngine: UserPatternLearningEngine
    private let smartDefaultsEngine: SmartDefaultsEngine
    private let contextExtractor: DocumentContextExtractor
    private var unifiedExtractor: UnifiedDocumentContextExtractor?
    private let questionGenerator: DynamicQuestionGenerator
    private let autoFillEngine: ConfidenceBasedAutoFillEngine
    
    public init() {
        self.documentParser = DocumentParserEnhanced()
        self.learningEngine = UserPatternLearningEngine()
        self.contextExtractor = DocumentContextExtractor()
        self.questionGenerator = DynamicQuestionGenerator()
        
        // Initialize UnifiedDocumentContextExtractor
        self.unifiedExtractor = UnifiedDocumentContextExtractor()
        
        // Initialize SmartDefaultsEngine with all dependencies
        self.smartDefaultsEngine = SmartDefaultsEngine(
            smartDefaultsProvider: SmartDefaultsProvider(),
            patternLearningEngine: self.learningEngine,
            contextExtractor: self.unifiedExtractor!
        )
        
        // Initialize ConfidenceBasedAutoFillEngine
        self.autoFillEngine = ConfidenceBasedAutoFillEngine(
            configuration: ConfidenceBasedAutoFillEngine.AutoFillConfiguration(
                autoFillThreshold: 0.85,
                suggestionThreshold: 0.65,
                autoFillCriticalFields: false,
                maxAutoFillFields: 20
            ),
            smartDefaultsEngine: self.smartDefaultsEngine
        )
    }
    
    public func startConversation(with context: ConversationContext) async -> ConversationSession {
        // Extract context from uploaded documents
        let extractedContext = try? await extractContextFromDocuments(context.uploadedDocuments)
        
        // Generate initial questions based on context
        let questions = await questionGenerator.generateQuestions(
            for: context.acquisitionType,
            with: extractedContext,
            historicalData: context.historicalData
        )
        
        // Build smart defaults context
        let defaultsContext = SmartDefaultContext(
            sessionId: UUID(),
            userId: context.userProfile?.id.uuidString ?? "",
            organizationUnit: context.userProfile?.organizationUnit ?? "",
            acquisitionType: convertToAcquisitionType(context.acquisitionType),
            extractedData: extractedContext?.toFieldMapping() ?? [:],
            fiscalYear: String(Calendar.current.component(.year, from: Date())),
            fiscalQuarter: getCurrentFiscalQuarter(),
            isEndOfFiscalYear: isEndOfFiscalYear(),
            daysUntilFYEnd: daysUntilFiscalYearEnd(),
            autoFillThreshold: 0.8
        )
        
        // Get confidence-based auto-fill results
        let allFields = questions.map { $0.field }
        let autoFillResult = await autoFillEngine.analyzeFieldsForAutoFill(
            fields: allFields,
            context: defaultsContext
        )
        
        // Create session with only the questions we must ask
        var session = ConversationSession(
            state: .gatheringBasicInfo,
            remainingQuestions: questions.filter { question in
                !autoFillResult.autoFilledFields.keys.contains(question.field)
            }.sorted { $0.priority < $1.priority }
        )
        
        // Pre-fill data from auto-fill results
        session.collectedData = prefillDataFromAutoFillResults(
            extractedContext: extractedContext,
            autoFillResult: autoFillResult
        )
        
        // Store auto-fill result for UI display
        session.autoFillResult = autoFillResult
        
        // Calculate confidence based on auto-fill results
        let totalFields = Float(allFields.count)
        let filledFields = Float(autoFillResult.summary.autoFilledCount)
        let suggestedFields = Float(autoFillResult.summary.suggestedCount)
        let confidenceScore = (filledFields + suggestedFields * 0.5) / totalFields
        
        session.confidence = confidenceScore > 0.7 ? .high : 
                           confidenceScore > 0.4 ? .medium : .low
        
        return session
    }
    
    public func processUserResponse(_ response: UserResponse, in session: ConversationSession) async throws -> NextPrompt? {
        var updatedSession = session
        
        // Record the response
        let question = session.remainingQuestions.first { $0.id.uuidString == response.questionId }
        if let question = question {
            updatedSession.questionHistory.append(AskedQuestion(question: question, response: response))
            updatedSession.remainingQuestions.removeAll { $0.id == question.id }
            
            // Update collected data
            updateCollectedData(&updatedSession.collectedData, field: question.field, value: response.value)
            
            // Learn from this interaction
            let suggestedValue = session.suggestedAnswers?[question.field]
            let acceptedSuggestion = suggestedValue != nil && 
                String(describing: suggestedValue!) == String(describing: response.value)
            
            let interaction = APEUserInteraction(
                sessionId: session.id,
                field: question.field,
                suggestedValue: suggestedValue,
                acceptedSuggestion: acceptedSuggestion,
                finalValue: response.value,
                timeToRespond: Date().timeIntervalSince(response.timestamp),
                documentContext: !session.collectedData.attachments.isEmpty
            )
            await learnFromInteraction(interaction)
        }
        
        // Determine next question or complete
        if let nextQuestion = selectNextQuestion(from: updatedSession) {
            let suggestion = await getSmartDefaults(for: nextQuestion.field)
            
            // Store suggestion for learning
            if updatedSession.suggestedAnswers == nil {
                updatedSession.suggestedAnswers = [:]
            }
            updatedSession.suggestedAnswers?[nextQuestion.field] = suggestion?.value
            
            return NextPrompt(
                question: nextQuestion,
                suggestedAnswer: suggestion?.value,
                confidenceInSuggestion: suggestion?.confidence ?? 0,
                isRequired: nextQuestion.priority == .critical,
                helpText: generateHelpText(for: nextQuestion.field, suggestion: suggestion)
            )
        } else {
            updatedSession.state = .complete
            return nil
        }
    }
    
    public func extractContextFromDocuments(_ documents: [ParsedDocument]) async throws -> ExtractedContext {
        try await contextExtractor.extract(from: documents)
    }
    
    /// Enhanced document context extraction using unified extractor
    /// This method handles raw document data and performs comprehensive extraction
    public func extractContextFromRawDocuments(
        _ documentData: [(data: Data, type: UTType)],
        withHints: [String: Any]? = nil
    ) async throws -> ExtractedContext {
        guard let extractor = unifiedExtractor else {
            throw DocumentParserError.unsupportedFormat
        }
        
        let comprehensiveContext = try await extractor.extractComprehensiveContext(
            from: documentData,
            withHints: withHints
        )
        
        // Log extraction summary for debugging
        print("Document extraction completed: \(comprehensiveContext.summary)")
        
        // Store parsed documents for future reference
        // This could be used for learning patterns
        for result in comprehensiveContext.adaptiveResults {
            for pattern in result.appliedPatterns {
                print("Applied pattern: \(pattern)")
            }
        }
        
        return comprehensiveContext.extractedContext
    }
    
    public func learnFromInteraction(_ interaction: APEUserInteraction) async {
        await learningEngine.learn(from: interaction)
    }
    
    public func getSmartDefaults(for field: RequirementField) async -> FieldDefault? {
        // Build context for smart defaults
        let context = SmartDefaultContext(
            fiscalYear: String(Calendar.current.component(.year, from: Date())),
            fiscalQuarter: getCurrentFiscalQuarter(),
            isEndOfFiscalYear: isEndOfFiscalYear(),
            daysUntilFYEnd: daysUntilFiscalYearEnd()
        )
        
        return await smartDefaultsEngine.getSmartDefault(for: field, context: context)
    }
    
    // MARK: - Helper Methods for Fiscal Context
    
    private func getCurrentFiscalQuarter() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 10...12: return "Q1"
        case 1...3: return "Q2"
        case 4...6: return "Q3"
        default: return "Q4"
        }
    }
    
    private func isEndOfFiscalYear() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month >= 8 && month <= 9
    }
    
    private func daysUntilFiscalYearEnd() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        // Federal fiscal year ends September 30
        var components = DateComponents()
        components.year = currentYear
        components.month = 9
        components.day = 30
        
        // If we're past September, next FY end is next year
        if calendar.component(.month, from: now) >= 10 {
            components.year = currentYear + 1
        }
        
        if let fyEnd = calendar.date(from: components) {
            return calendar.dateComponents([.day], from: now, to: fyEnd).day ?? 0
        }
        
        return 0
    }
    
    // MARK: - Private Helpers
    
    private func prefillDataFromMultipleSources(
        extractedContext: ExtractedContext?,
        autoFillDefaults: [RequirementField: FieldDefault],
        suggestedDefaults: [RequirementField: FieldDefault]
    ) -> RequirementsData {
        var data = RequirementsData()
        
        // First, apply extracted context
        if let context = extractedContext {
            data = prefillData(from: context)
        }
        
        // Then apply auto-fill defaults
        for (field, defaultValue) in autoFillDefaults {
            applyDefaultToData(&data, field: field, value: defaultValue.value)
        }
        
        // Store suggested defaults separately (not applied automatically)
        // These will be shown as suggestions in the UI
        
        return data
    }
    
    private func applyDefaultToData(_ data: inout RequirementsData, field: RequirementField, value: Any) {
        switch field {
        case .projectTitle:
            data.projectTitle = value as? String
        case .description:
            data.description = value as? String
        case .estimatedValue:
            if let decimal = value as? Decimal {
                data.estimatedValue = decimal
            } else if let string = value as? String,
                      let double = Double(string.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
                data.estimatedValue = Decimal(double)
            }
        case .requiredDate:
            if let date = value as? Date {
                data.requiredDate = date
            } else if let string = value as? String {
                data.requiredDate = DateFormatter.mmddyyyy.date(from: string)
            }
        case .vendorName:
            if data.vendorInfo == nil {
                data.vendorInfo = APEVendorInfo(name: value as? String)
            } else {
                data.vendorInfo?.name = value as? String
            }
        case .performanceLocation:
            data.placeOfPerformance = value as? String
        case .contractType:
            data.acquisitionType = value as? String
        case .setAsideType:
            data.setAsideType = value as? String
        case .specialConditions:
            if let conditions = value as? [String] {
                data.specialConditions = conditions
            } else if let condition = value as? String {
                data.specialConditions.append(condition)
            }
        case .justification:
            data.businessJustification = value as? String
        default:
            // Fields not in current data model are ignored
            break
        }
    }
    
    private func generateHelpText(for field: RequirementField, suggestion: FieldDefault?) -> String? {
        var helpTexts: [String] = []
        
        // Add field-specific help
        switch field {
        case .estimatedValue:
            helpTexts.append("Enter the total estimated value including all options")
        case .requiredDate:
            helpTexts.append("When do you need the goods/services delivered?")
        case .vendorName:
            helpTexts.append("Preferred vendor or 'Open Competition' if none")
        case .fundingSource:
            helpTexts.append("Budget line or appropriation code")
        default:
            break
        }
        
        // Add suggestion confidence info
        if let suggestion = suggestion {
            let confidence = Int(suggestion.confidence * 100)
            switch suggestion.source {
            case .documentContext:
                helpTexts.append("Extracted from your document (\(confidence)% confidence)")
            case .userPattern:
                helpTexts.append("Based on your previous selections (\(confidence)% confidence)")
            case .historical:
                helpTexts.append("Based on historical data (\(confidence)% confidence)")
            case .systemDefault:
                helpTexts.append("Recommended value (\(confidence)% confidence)")
            case .contextual:
                helpTexts.append("Based on contextual analysis (\(confidence)% confidence)")
            }
        }
        
        return helpTexts.isEmpty ? nil : helpTexts.joined(separator: ". ")
    }
    
    private func prefillData(from context: ExtractedContext) -> RequirementsData {
        var data = RequirementsData()
        
        if let vendorInfo = context.vendorInfo {
            data.vendorInfo = vendorInfo
        }
        
        if let pricing = context.pricing {
            data.estimatedValue = pricing.totalPrice
        }
        
        if let dates = context.dates {
            data.requiredDate = dates.deliveryDate
        }
        
        data.technicalRequirements = context.technicalDetails
        data.specialConditions = context.specialTerms
        
        return data
    }
    
    private func calculateOverallConfidence(_ fieldConfidences: [RequirementField: Float]) -> ConfidenceLevel {
        guard !fieldConfidences.isEmpty else { return .low }
        
        let average = fieldConfidences.values.reduce(0, +) / Float(fieldConfidences.count)
        
        switch average {
        case 0.8...: return .veryHigh
        case 0.6..<0.8: return .high
        case 0.3..<0.6: return .medium
        default: return .low
        }
    }
    
    private func selectNextQuestion(from session: ConversationSession) -> DynamicQuestion? {
        // Skip questions we already have high-confidence answers for
        let answeredFields = Set(session.questionHistory.compactMap { $0.question.field })
        
        return session.remainingQuestions.first { question in
            !answeredFields.contains(question.field) &&
            !hasHighConfidenceValue(for: question.field, in: session.collectedData)
        }
    }
    
    private func hasHighConfidenceValue(for field: RequirementField, in data: RequirementsData) -> Bool {
        switch field {
        case .projectTitle: return data.projectTitle != nil
        case .description: return data.description != nil
        case .estimatedValue: return data.estimatedValue != nil
        case .requiredDate: return data.requiredDate != nil
        case .vendorName: return data.vendorInfo?.name != nil
        case .vendorUEI: return data.vendorInfo?.uei != nil
        case .vendorCAGE: return data.vendorInfo?.cage != nil
        case .technicalSpecs: return !data.technicalRequirements.isEmpty
        case .performanceLocation: return data.placeOfPerformance != nil
        case .contractType: return data.acquisitionType != nil
        case .setAsideType: return data.setAsideType != nil
        case .specialConditions: return !data.specialConditions.isEmpty
        case .justification: return data.businessJustification != nil
        case .fundingSource: return false // Not in current data model
        case .requisitionNumber: return false // Not in current data model
        case .costCenter: return false // Not in current data model
        case .accountingCode: return false // Not in current data model
        case .qualityRequirements: return false // Not in current data model
        case .deliveryInstructions: return false // Not in current data model
        case .packagingRequirements: return false // Not in current data model
        case .inspectionRequirements: return false // Not in current data model
        case .paymentTerms: return false // Not in current data model
        case .warrantyRequirements: return false // Not in current data model
        case .attachments: return !data.attachments.isEmpty
        case .pointOfContact: return false // Not in current data model
        }
    }
    
    private func updateCollectedData(_ data: inout RequirementsData, field: RequirementField, value: Any) {
        switch field {
        case .projectTitle:
            data.projectTitle = value as? String
        case .description:
            data.description = value as? String
        case .estimatedValue:
            if let decimal = value as? Decimal {
                data.estimatedValue = decimal
            } else if let double = value as? Double {
                data.estimatedValue = Decimal(double)
            }
        case .requiredDate:
            data.requiredDate = value as? Date
        case .vendorName:
            if data.vendorInfo == nil {
                data.vendorInfo = APEVendorInfo()
            }
            data.vendorInfo?.name = value as? String
        case .vendorUEI:
            if data.vendorInfo == nil {
                data.vendorInfo = APEVendorInfo()
            }
            data.vendorInfo?.uei = value as? String
        case .vendorCAGE:
            if data.vendorInfo == nil {
                data.vendorInfo = APEVendorInfo()
            }
            data.vendorInfo?.cage = value as? String
        case .technicalSpecs:
            if let specs = value as? String {
                data.technicalRequirements.append(specs)
            }
        case .performanceLocation:
            data.placeOfPerformance = value as? String
        case .contractType:
            if let string = value as? String {
                data.acquisitionType = string
            }
        case .setAsideType:
            data.setAsideType = value as? String
        case .specialConditions:
            if let condition = value as? String {
                data.specialConditions.append(condition)
            }
        case .justification:
            data.businessJustification = value as? String
        case .fundingSource, .requisitionNumber, .costCenter, .accountingCode,
             .qualityRequirements, .deliveryInstructions, .packagingRequirements,
             .inspectionRequirements, .paymentTerms, .warrantyRequirements:
            // These fields are not yet in the data model
            // Would need to extend RequirementsData to support them
            break
        case .attachments:
            // Attachments are handled differently
            break
        case .pointOfContact:
            // Point of contact not yet in data model
            break
        }
    }
    
    private func prefillDataFromAutoFillResults(
        extractedContext: ExtractedContext?,
        autoFillResult: ConfidenceBasedAutoFillEngine.AutoFillResult
    ) -> RequirementsData {
        var data = RequirementsData()
        
        // First, apply extracted context
        if let context = extractedContext {
            data = prefillData(from: context)
        }
        
        // Then apply auto-filled values
        for (field, value) in autoFillResult.autoFilledFields {
            applyDefaultToData(&data, field: field, value: value)
        }
        
        // Note: Suggested fields are not automatically applied
        // They will be shown in the UI for user confirmation
        
        return data
    }
    
    /// Process user feedback on auto-filled values
    public func processAutoFillFeedback(
        field: RequirementField,
        autoFilledValue: Any,
        userValue: Any,
        wasAccepted: Bool,
        session: ConversationSession
    ) async {
        // Build context
        let context = SmartDefaultContext(
            sessionId: session.id,
            userId: "", // Would come from user profile
            organizationUnit: "", // Would come from user profile
            autoFillThreshold: 0.85
        )
        
        // Process feedback
        await autoFillEngine.processUserFeedback(
            field: field,
            autoFilledValue: autoFilledValue,
            userValue: userValue,
            wasAccepted: wasAccepted,
            context: context
        )
    }
    
    /// Get auto-fill metrics
    public func getAutoFillMetrics() -> ConfidenceBasedAutoFillEngine.AutoFillMetrics {
        return autoFillEngine.getMetrics()
    }
    
    private func convertToAcquisitionType(_ type: APEAcquisitionType) -> AcquisitionType? {
        switch type {
        case .supplies:
            return .commercialItem
        case .services:
            return .nonCommercialService
        case .construction:
            return .constructionProject
        case .researchAndDevelopment:
            return .researchDevelopment
        }
    }
}


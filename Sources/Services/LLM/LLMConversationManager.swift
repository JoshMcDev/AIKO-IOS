import Foundation
import AppCore
import ComposableArchitecture

// MARK: - LLM Conversation Manager

/// Manages conversation state across all LLM providers
@MainActor
public final class LLMConversationManager: ObservableObject {
    
    // MARK: - Properties
    
    public static let shared = LLMConversationManager()
    
    @Published public private(set) var conversations: [LLMConversation] = []
    @Published public private(set) var activeConversation: LLMConversation?
    
    private let llmManager = LLMManager.shared
    private let maxConversationHistory = 50
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "com.aiko.llm.conversations"
    
    // MARK: - Initialization
    
    private init() {
        loadConversations()
    }
    
    // MARK: - Public Methods
    
    /// Create a new conversation
    public func createConversation(
        title: String? = nil,
        context: LLMConversationContext? = nil
    ) -> LLMConversation {
        let conversation = LLMConversation(
            title: title ?? "New Conversation",
            context: context ?? LLMConversationContext()
        )
        
        conversations.insert(conversation, at: 0)
        activeConversation = conversation
        saveConversations()
        
        return conversation
    }
    
    /// Set active conversation
    public func setActiveConversation(_ conversation: LLMConversation) {
        activeConversation = conversation
    }
    
    /// Add message to conversation
    public func addMessage(
        _ message: LLMMessage,
        to conversation: LLMConversation
    ) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            return
        }
        
        conversations[index].messages.append(message)
        conversations[index].lastMessageDate = Date()
        
        // Trim old messages if needed
        if conversations[index].messages.count > maxConversationHistory {
            let trimCount = conversations[index].messages.count - maxConversationHistory
            conversations[index].messages.removeFirst(trimCount)
        }
        
        saveConversations()
    }
    
    /// Send message and get response
    public func sendMessage(
        _ content: String,
        to conversation: LLMConversation,
        model: String? = nil
    ) async throws -> LLMMessage {
        // Add user message
        let userMessage = LLMMessage(role: .user, content: content)
        addMessage(userMessage, to: conversation)
        
        // Prepare request
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
            throw ConversationError.conversationNotFound
        }
        
        let messages = conversations[index].messages
        let systemPrompt = buildSystemPrompt(for: conversations[index])
        
        let request = LLMChatRequest(
            messages: messages,
            model: model ?? getDefaultModel(),
            temperature: conversation.temperature,
            maxTokens: conversation.maxTokens,
            systemPrompt: systemPrompt
        )
        
        // Get response
        let response = try await llmManager.chatCompletion(request)
        
        // Add assistant message
        addMessage(response.message, to: conversation)
        
        // Update token usage
        conversations[index].totalTokensUsed += response.usage.totalTokens
        
        return response.message
    }
    
    /// Stream message response
    public func streamMessage(
        _ content: String,
        to conversation: LLMConversation,
        model: String? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Add user message
                    let userMessage = LLMMessage(role: .user, content: content)
                    addMessage(userMessage, to: conversation)
                    
                    // Prepare request
                    guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else {
                        throw ConversationError.conversationNotFound
                    }
                    
                    let messages = conversations[index].messages
                    let systemPrompt = buildSystemPrompt(for: conversations[index])
                    
                    let request = LLMChatRequest(
                        messages: messages,
                        model: model ?? getDefaultModel(),
                        temperature: conversation.temperature,
                        maxTokens: conversation.maxTokens,
                        systemPrompt: systemPrompt
                    )
                    
                    // Stream response
                    var fullResponse = ""
                    
                    for try await chunk in llmManager.streamChatCompletion(request) {
                        fullResponse += chunk.delta
                        continuation.yield(chunk.delta)
                        
                        if chunk.finishReason != nil {
                            // Add complete assistant message
                            let assistantMessage = LLMMessage(role: .assistant, content: fullResponse)
                            addMessage(assistantMessage, to: conversation)
                            
                            continuation.finish()
                            break
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Delete conversation
    public func deleteConversation(_ conversation: LLMConversation) {
        conversations.removeAll { $0.id == conversation.id }
        
        if activeConversation?.id == conversation.id {
            activeConversation = conversations.first
        }
        
        saveConversations()
    }
    
    /// Clear all conversations
    public func clearAllConversations() {
        conversations.removeAll()
        activeConversation = nil
        saveConversations()
    }
    
    /// Export conversation
    public func exportConversation(_ conversation: LLMConversation) -> String {
        var export = "# \(conversation.title)\n\n"
        export += "Created: \(conversation.createdDate.formatted())\n"
        export += "Model: \(conversation.preferredModel ?? "Default")\n\n"
        
        for message in conversation.messages {
            switch message.role {
            case .user:
                export += "## User\n\(message.content)\n\n"
            case .assistant:
                export += "## Assistant\n\(message.content)\n\n"
            case .system:
                export += "## System\n\(message.content)\n\n"
            case .function:
                export += "## Function\n\(message.content)\n\n"
            }
        }
        
        return export
    }
    
    // MARK: - Private Methods
    
    private func buildSystemPrompt(for conversation: LLMConversation) -> String? {
        var prompt = ""
        
        // Add base context
        if let basePrompt = conversation.systemPrompt {
            prompt = basePrompt
        }
        
        // Add acquisition context if available
        if let acquisitionType = conversation.context.acquisitionType {
            prompt += "\n\nContext: Working on \(acquisitionType.rawValue) acquisition."
        }
        
        // Add document context if available
        if !conversation.context.uploadedDocuments.isEmpty {
            prompt += "\n\nRelevant documents have been uploaded and analyzed."
        }
        
        return prompt.isEmpty ? nil : prompt
    }
    
    private func getDefaultModel() -> String {
        guard let activeProvider = llmManager.activeProvider else {
            return "gpt-3.5-turbo"
        }
        
        // Return first available model for the provider
        return activeProvider.capabilities.supportedModels.first?.id ?? "default"
    }
    
    private func loadConversations() {
        guard let data = userDefaults.data(forKey: conversationsKey),
              let decoded = try? JSONDecoder().decode([LLMConversation].self, from: data) else {
            return
        }
        
        conversations = decoded
        activeConversation = conversations.first
    }
    
    private func saveConversations() {
        // Only save recent conversations
        let toSave = Array(conversations.prefix(20))
        
        if let encoded = try? JSONEncoder().encode(toSave) {
            userDefaults.set(encoded, forKey: conversationsKey)
        }
    }
}

// MARK: - Conversation Model

public struct LLMConversation: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var messages: [LLMMessage]
    public var context: LLMConversationContext
    public var systemPrompt: String?
    public var temperature: Double
    public var maxTokens: Int?
    public var preferredModel: String?
    public var createdDate: Date
    public var lastMessageDate: Date
    public var totalTokensUsed: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        messages: [LLMMessage] = [],
        context: LLMConversationContext = LLMConversationContext(),
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        preferredModel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.context = context
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.preferredModel = preferredModel
        self.createdDate = Date()
        self.lastMessageDate = Date()
        self.totalTokensUsed = 0
    }
}

// MARK: - Conversation Context

public struct LLMConversationContext: Codable, Equatable {
    public var acquisitionType: AcquisitionType?
    public var uploadedDocuments: [LLMDocumentReference]
    public var extractedData: [String: String]
    public var userProfile: LLMUserProfile?
    public var organizationalContext: OrganizationalContext?
    
    public init(
        acquisitionType: AcquisitionType? = nil,
        uploadedDocuments: [LLMDocumentReference] = [],
        extractedData: [String: String] = [:],
        userProfile: LLMUserProfile? = nil,
        organizationalContext: OrganizationalContext? = nil
    ) {
        self.acquisitionType = acquisitionType
        self.uploadedDocuments = uploadedDocuments
        self.extractedData = extractedData
        self.userProfile = userProfile
        self.organizationalContext = organizationalContext
    }
}

public struct LLMDocumentReference: Codable, Equatable {
    public let id: UUID
    public let name: String
    public let type: String
    public let uploadDate: Date
    
    public init(name: String, type: String) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.uploadDate = Date()
    }
}

public struct LLMUserProfile: Codable, Equatable {
    public let userId: String
    public let organizationUnit: String
    public let role: String
    public let preferences: [String: String]
    
    public init(
        userId: String,
        organizationUnit: String,
        role: String,
        preferences: [String: String] = [:]
    ) {
        self.userId = userId
        self.organizationUnit = organizationUnit
        self.role = role
        self.preferences = preferences
    }
}

public struct OrganizationalContext: Codable, Equatable {
    public let fiscalYear: String
    public let department: String
    public let location: String
    public let contractingOffice: String
    
    public init(
        fiscalYear: String,
        department: String,
        location: String,
        contractingOffice: String
    ) {
        self.fiscalYear = fiscalYear
        self.department = department
        self.location = location
        self.contractingOffice = contractingOffice
    }
}

// MARK: - Errors

public enum ConversationError: LocalizedError {
    case conversationNotFound
    case noActiveProvider
    
    public var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "Conversation not found"
        case .noActiveProvider:
            return "No LLM provider configured"
        }
    }
}

// MARK: - TCA Dependency

extension DependencyValues {
    public var conversationManager: LLMConversationManager {
        get { self[ConversationManagerKey.self] }
        set { self[ConversationManagerKey.self] = newValue }
    }
}

private enum ConversationManagerKey: DependencyKey {
    static var liveValue: LLMConversationManager {
        MainActor.assumeIsolated {
            LLMConversationManager.shared
        }
    }
}

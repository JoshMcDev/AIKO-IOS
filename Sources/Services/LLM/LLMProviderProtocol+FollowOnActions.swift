import Foundation
import ComposableArchitecture

// MARK: - LLM Provider Follow-On Action Extension

/// Extension to add follow-on action generation capabilities to LLM providers
public extension LLMProviderProtocol {
    /// Generate follow-on actions based on the current context
    func generateFollowOnActions(
        context: FollowOnActionContext
    ) async throws -> FollowOnActionSet {
        // Build the system prompt for follow-on action generation
        let systemPrompt = buildFollowOnActionSystemPrompt(context: context)
        
        // Build the user prompt with context
        let userPrompt = buildFollowOnActionUserPrompt(context: context)
        
        // Create the chat request
        let request = LLMChatRequest(
            messages: [
                LLMMessage(role: .system, content: systemPrompt),
                LLMMessage(role: .user, content: userPrompt)
            ],
            model: context.preferredModel ?? getSettings().apiEndpoint ?? "default",
            temperature: 0.3, // Lower temperature for consistent action generation
            maxTokens: 2000,
            responseFormat: .json
        )
        
        // Send the request
        let response = try await chatCompletion(request)
        
        // Parse the response into follow-on actions
        return try parseFollowOnActionResponse(response.message.content, context: context)
    }
    
    /// Generate contextual suggestions for the user
    func generateContextualSuggestions(
        messages: [LLMMessage],
        currentState: AcquisitionState
    ) async throws -> [String] {
        let systemPrompt = """
        You are an AI assistant helping with government acquisition workflows.
        Generate 3-5 contextual suggestions for what the user might want to do next.
        Keep suggestions concise (under 10 words each) and actionable.
        Consider the current conversation and acquisition state.
        Return suggestions as a JSON array of strings.
        """
        
        let contextSummary = """
        Current Phase: \(currentState.phase)
        Documents Ready: \(currentState.readyDocuments.count)
        Active Tasks: \(currentState.activeTasks.count)
        Last Action: \(currentState.lastCompletedAction ?? "None")
        """
        
        let request = LLMChatRequest(
            messages: [
                LLMMessage(role: .system, content: systemPrompt),
                LLMMessage(role: .user, content: "Based on this context, suggest next actions: \(contextSummary)")
            ],
            model: getSettings().apiEndpoint ?? "default",
            temperature: 0.5,
            maxTokens: 500,
            responseFormat: .json
        )
        
        let response = try await chatCompletion(request)
        
        // Parse JSON array of suggestions
        guard let data = response.message.content.data(using: .utf8),
              let suggestions = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return ["Continue with document generation", "Review requirements", "Check acquisition status"]
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types

/// Context for generating follow-on actions
public struct FollowOnActionContext: Equatable {
    public let currentPhase: AcquisitionPhase
    public let completedActions: [FollowOnAction]
    public let pendingTasks: [AgentTask]
    public let requirements: RequirementsData
    public let documentChain: DocumentChain?
    public let reviewMode: ReviewMode
    public let userPreferences: UserPreferences?
    public let conversationHistory: [LLMMessage]
    public let preferredModel: String?
    
    public init(
        currentPhase: AcquisitionPhase,
        completedActions: [FollowOnAction] = [],
        pendingTasks: [AgentTask] = [],
        requirements: RequirementsData,
        documentChain: DocumentChain? = nil,
        reviewMode: ReviewMode = .iterative,
        userPreferences: UserPreferences? = nil,
        conversationHistory: [LLMMessage] = [],
        preferredModel: String? = nil
    ) {
        self.currentPhase = currentPhase
        self.completedActions = completedActions
        self.pendingTasks = pendingTasks
        self.requirements = requirements
        self.documentChain = documentChain
        self.reviewMode = reviewMode
        self.userPreferences = userPreferences
        self.conversationHistory = conversationHistory
        self.preferredModel = preferredModel
    }
}

/// User preferences for action generation
public struct UserPreferences: Equatable {
    public let preferredAutomationLevel: AutomationLevel
    public let maxConcurrentTasks: Int
    public let notificationSettings: NotificationSettings
    
    public init(
        preferredAutomationLevel: AutomationLevel = .semiAutomated,
        maxConcurrentTasks: Int = 3,
        notificationSettings: NotificationSettings = .init()
    ) {
        self.preferredAutomationLevel = preferredAutomationLevel
        self.maxConcurrentTasks = maxConcurrentTasks
        self.notificationSettings = notificationSettings
    }
}

/// Notification settings
public struct NotificationSettings: Equatable {
    public let notifyOnTaskCompletion: Bool
    public let notifyOnApprovalRequired: Bool
    public let notifyOnErrors: Bool
    
    public init(
        notifyOnTaskCompletion: Bool = true,
        notifyOnApprovalRequired: Bool = true,
        notifyOnErrors: Bool = true
    ) {
        self.notifyOnTaskCompletion = notifyOnTaskCompletion
        self.notifyOnApprovalRequired = notifyOnApprovalRequired
        self.notifyOnErrors = notifyOnErrors
    }
}

/// Current acquisition state
public struct AcquisitionState: Equatable {
    public let phase: String
    public let readyDocuments: Set<DocumentType>
    public let activeTasks: [AgentTask]
    public let lastCompletedAction: String?
    
    public init(
        phase: String,
        readyDocuments: Set<DocumentType> = [],
        activeTasks: [AgentTask] = [],
        lastCompletedAction: String? = nil
    ) {
        self.phase = phase
        self.readyDocuments = readyDocuments
        self.activeTasks = activeTasks
        self.lastCompletedAction = lastCompletedAction
    }
}

// MARK: - Private Helper Functions

private extension LLMProviderProtocol {
    func buildFollowOnActionSystemPrompt(context: FollowOnActionContext) -> String {
        """
        You are an expert government acquisition assistant that always provides helpful next steps.
        Your role is to guide users through the acquisition process by suggesting logical follow-on actions.
        
        Current Context:
        - Acquisition Phase: \(context.currentPhase.rawValue)
        - Review Mode: \(context.reviewMode.rawValue)
        - Completed Actions: \(context.completedActions.count)
        - Pending Tasks: \(context.pendingTasks.count)
        
        Guidelines:
        1. Always suggest 3-5 relevant follow-on actions
        2. Prioritize actions based on acquisition phase and dependencies
        3. Consider user's automation preferences
        4. Ensure actions move the acquisition process forward
        5. Include both immediate and planning actions
        6. Consider parallel workflows when beneficial
        
        Return actions as a JSON object with this structure:
        {
            "context": "Brief description of why these actions are suggested",
            "actions": [
                {
                    "id": "unique-id",
                    "title": "Action Title",
                    "description": "Detailed description",
                    "category": "documentGeneration|requirementGathering|vendorManagement|etc",
                    "priority": "critical|high|medium|low",
                    "estimatedDuration": 300,
                    "requiresUserInput": true|false,
                    "automationLevel": "manual|semiAutomated|fullyAutomated",
                    "dependencies": ["id-of-dependent-action"],
                    "metadata": {
                        "documentTypes": ["sow", "qasp"],
                        "complianceStandards": ["FAR 15.304"]
                    }
                }
            ],
            "recommendedPath": ["action-id-1", "action-id-2"],
            "expiresAt": "2024-12-31T23:59:59Z"
        }
        """
    }
    
    func buildFollowOnActionUserPrompt(context: FollowOnActionContext) -> String {
        var prompt = "Based on the current acquisition state, suggest appropriate follow-on actions.\n\n"
        
        // Add requirements summary
        prompt += "Requirements Summary:\n"
        prompt += "- Project Title: \(context.requirements.projectTitle ?? "Not specified")\n"
        prompt += "- Description: \(context.requirements.description ?? "Not specified")\n"
        prompt += "- Estimated Value: \(context.requirements.estimatedValue ?? 0)\n"
        prompt += "- Business Justification: \(context.requirements.businessJustification ?? "Not specified")\n"
        
        // Add document chain info if available
        if let chain = context.documentChain {
            prompt += "\n\nDocument Chain:\n"
            prompt += "- Title: \(chain.title)\n"
            prompt += "- Type: \(chain.acquisitionType.rawValue)\n"
            prompt += "- Documents: \(chain.nodes.count)\n"
            prompt += "- Review Mode: \(chain.reviewMode.rawValue)\n"
        }
        
        // Add completed actions context
        if !context.completedActions.isEmpty {
            prompt += "\n\nRecently Completed Actions:\n"
            for action in context.completedActions.suffix(3) {
                prompt += "- \(action.title)\n"
            }
        }
        
        // Add user preferences
        if let prefs = context.userPreferences {
            prompt += "\n\nUser Preferences:\n"
            prompt += "- Automation Level: \(prefs.preferredAutomationLevel.rawValue)\n"
            prompt += "- Max Concurrent Tasks: \(prefs.maxConcurrentTasks)\n"
        }
        
        prompt += "\n\nGenerate appropriate follow-on actions in JSON format."
        
        return prompt
    }
    
    func parseFollowOnActionResponse(_ response: String, context: FollowOnActionContext) throws -> FollowOnActionSet {
        guard let data = response.data(using: .utf8) else {
            throw LLMProviderError.invalidResponse("Failed to convert response to data")
        }
        
        do {
            // First try to decode the JSON response
            let decoder = JSONDecoder()
            let actionResponse = try decoder.decode(FollowOnActionResponse.self, from: data)
            
            // Convert to FollowOnActionSet
            let actions = actionResponse.actions.map { actionData in
                FollowOnAction(
                    id: UUID(),
                    title: actionData.title,
                    description: actionData.description,
                    category: ActionCategory(rawValue: actionData.category) ?? .documentGeneration,
                    priority: ActionPriority(rawValue: actionData.priority) ?? .medium,
                    estimatedDuration: TimeInterval(actionData.estimatedDuration),
                    requiresUserInput: actionData.requiresUserInput,
                    automationLevel: AutomationLevel(rawValue: actionData.automationLevel) ?? .semiAutomated,
                    dependencies: actionData.dependencies.compactMap { UUID(uuidString: $0) },
                    metadata: parseActionMetadata(actionData.metadata)
                )
            }
            
            return FollowOnActionSet(
                context: actionResponse.context,
                actions: actions,
                recommendedPath: actionResponse.recommendedPath?.compactMap { UUID(uuidString: $0) },
                expiresAt: actionResponse.expiresAt.flatMap { ISO8601DateFormatter().date(from: $0) }
            )
        } catch {
            // Fallback to default actions if parsing fails
            return generateDefaultFollowOnActions(context: context)
        }
    }
    
    func parseActionMetadata(_ metadata: [String: String]?) -> ActionMetadata? {
        guard let metadata = metadata else { return nil }
        
        return ActionMetadata(
            documentTypes: metadata["documentTypes"]?.components(separatedBy: ",").compactMap { DocumentType(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines)) },
            complianceStandards: metadata["complianceStandards"]?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            customData: metadata
        )
    }
    
    func generateDefaultFollowOnActions(context: FollowOnActionContext) -> FollowOnActionSet {
        var actions: [FollowOnAction] = []
        
        // Generate phase-specific default actions
        switch context.currentPhase {
        case .planning:
            actions.append(contentsOf: [
                FollowOnAction(
                    title: "Complete Market Research",
                    description: "Gather market intelligence to inform acquisition strategy",
                    category: .marketResearch,
                    priority: .high,
                    estimatedDuration: 1800
                ),
                FollowOnAction(
                    title: "Define Requirements",
                    description: "Finalize technical and performance requirements",
                    category: .requirementGathering,
                    priority: .critical,
                    estimatedDuration: 3600
                )
            ])
            
        case .solicitation:
            actions.append(contentsOf: [
                FollowOnAction(
                    title: "Generate Solicitation Documents",
                    description: "Create RFP/RFQ with all required clauses",
                    category: .documentGeneration,
                    priority: .critical,
                    estimatedDuration: 2400,
                    metadata: ActionMetadata(documentTypes: [.requestForProposal])
                ),
                FollowOnAction(
                    title: "Identify Potential Vendors",
                    description: "Research and compile vendor list",
                    category: .vendorManagement,
                    priority: .high,
                    estimatedDuration: 1200
                )
            ])
            
        default:
            // Generic actions for other phases
            actions.append(FollowOnAction(
                title: "Review Current Status",
                description: "Assess progress and identify next steps",
                category: .reviewApproval,
                priority: .medium,
                estimatedDuration: 600
            ))
        }
        
        return FollowOnActionSet(
            context: "Default actions for \(context.currentPhase.rawValue) phase",
            actions: actions
        )
    }
}

// MARK: - JSON Response Structure

private struct FollowOnActionResponse: Codable {
    let context: String
    let actions: [ActionData]
    let recommendedPath: [String]?
    let expiresAt: String?
    
    struct ActionData: Codable {
        let id: String
        let title: String
        let description: String
        let category: String
        let priority: String
        let estimatedDuration: Int
        let requiresUserInput: Bool
        let automationLevel: String
        let dependencies: [String]
        let metadata: [String: String]?
        
        enum CodingKeys: String, CodingKey {
            case id, title, description, category, priority
            case estimatedDuration, requiresUserInput, automationLevel
            case dependencies, metadata
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            description = try container.decode(String.self, forKey: .description)
            category = try container.decode(String.self, forKey: .category)
            priority = try container.decode(String.self, forKey: .priority)
            estimatedDuration = try container.decode(Int.self, forKey: .estimatedDuration)
            requiresUserInput = try container.decode(Bool.self, forKey: .requiresUserInput)
            automationLevel = try container.decode(String.self, forKey: .automationLevel)
            dependencies = try container.decode([String].self, forKey: .dependencies)
            
            // Handle metadata as optional string dictionary
            metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(description, forKey: .description)
            try container.encode(category, forKey: .category)
            try container.encode(priority, forKey: .priority)
            try container.encode(estimatedDuration, forKey: .estimatedDuration)
            try container.encode(requiresUserInput, forKey: .requiresUserInput)
            try container.encode(automationLevel, forKey: .automationLevel)
            try container.encode(dependencies, forKey: .dependencies)
            // Encode metadata if present
            try container.encodeIfPresent(metadata, forKey: .metadata)
        }
    }
}
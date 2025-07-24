import Foundation

/// PersonalizationEngine - Unified user personalization core
/// Week 1-2 deliverable: Skeleton with actor isolation and basic structure
///
/// Consolidates functionality from multiple personalization systems into
/// a single, unified engine with:
/// - Actor isolation for thread safety
/// - User behavior tracking and analysis
/// - Template and prompt personalization
/// - Learning insights and recommendations
/// - GraphRAG integration for context awareness
public actor PersonalizationEngine {
    // MARK: - Singleton

    public static let shared = PersonalizationEngine()

    // MARK: - Dependencies

    private let userProfileManager: UserProfileManager
    private let behaviorAnalyzer: BehaviorAnalyzer
    private let recommendationEngine: RecommendationEngine
    private let graphRAG: GraphRAGEngine
    private let personalizationCache: PersonalizationCache

    // MARK: - State

    private var isInitialized = false
    private var activePersonalizations: [String: Task<PersonalizedRecommendations, Error>] = [:]
    private var userProfiles: [String: AIUserProfile] = [:]

    // MARK: - Initialization

    private init() {
        userProfileManager = UserProfileManager()
        behaviorAnalyzer = BehaviorAnalyzer()
        recommendationEngine = RecommendationEngine()
        graphRAG = GraphRAGEngine()
        personalizationCache = PersonalizationCache()

        Task {
            await self.initialize()
        }
    }

    private func initialize() async {
        // Initialize personalization engines and load user data
        await userProfileManager.loadUserProfiles()
        await behaviorAnalyzer.initializeBehaviorModels()
        await graphRAG.initializeKnowledgeGraph()
        isInitialized = true
    }

    // MARK: - Public API

    /// Adapt recommendations for user based on context and history
    /// - Parameters:
    ///   - context: Current acquisition context
    ///   - history: Array of user actions for analysis
    /// - Returns: Personalized recommendations tailored to user
    public func adaptForUser(
        _ context: AcquisitionContext,
        history: [UserAction]
    ) async -> PersonalizedRecommendations {
        guard isInitialized else {
            return PersonalizedRecommendations() // Empty recommendations if not initialized
        }

        // Generate personalization key
        let personalizationKey = generatePersonalizationKey(context: context, history: history)

        // Check cache first
        if let cachedRecommendations = await personalizationCache.getRecommendations(key: personalizationKey) {
            return cachedRecommendations
        }

        // Check if personalization is already in progress
        if let existingTask = activePersonalizations[personalizationKey] {
            do {
                return try await existingTask.value
            } catch {
                // If task failed, continue with new personalization
            }
        }

        // Start new personalization task
        let personalizationTask = Task<PersonalizedRecommendations, Error> {
            try await performPersonalization(context: context, history: history)
        }

        activePersonalizations[personalizationKey] = personalizationTask

        do {
            let recommendations = try await personalizationTask.value
            await personalizationCache.storeRecommendations(key: personalizationKey, recommendations: recommendations)
            activePersonalizations.removeValue(forKey: personalizationKey)
            return recommendations
        } catch {
            activePersonalizations.removeValue(forKey: personalizationKey)
            // Return basic recommendations on error
            return await generateBasicRecommendations(context: context)
        }
    }

    /// Update user profile with new action
    /// - Parameters:
    ///   - userId: User identifier
    ///   - action: User action to record
    public func updateUserProfile(userId: String, action: UserAction) async {
        guard isInitialized else { return }

        // Get or create user profile
        var profile = userProfiles[userId] ?? AIUserProfile(userId: userId)

        // Add action to history
        profile = await userProfileManager.addAction(to: profile, action: action)

        // Analyze behavior patterns
        let behaviorInsights = await behaviorAnalyzer.analyzeBehavior(profile.actionHistory)
        profile = await userProfileManager.updateInsights(profile: profile, insights: behaviorInsights)

        // Store updated profile
        userProfiles[userId] = profile
        await userProfileManager.saveUserProfile(profile)
    }

    /// Get personalized templates for user and context
    /// - Parameters:
    ///   - userId: User identifier
    ///   - documentType: Type of document
    ///   - context: Acquisition context
    /// - Returns: Array of recommended template IDs
    public func getPersonalizedTemplates(
        userId: String,
        documentType: AIDocumentType,
        context: AcquisitionContext
    ) async -> [String] {
        guard isInitialized else { return [] }

        // Get user profile
        guard let profile = userProfiles[userId] else {
            return await getDefaultTemplates(for: documentType)
        }

        // Get recommendations based on user behavior
        let recommendations = await recommendationEngine.getTemplateRecommendations(
            profile: profile,
            documentType: documentType,
            context: context
        )

        return recommendations.suggestedTemplates
    }

    /// Get learning insights for user improvement
    /// - Parameter userId: User identifier
    /// - Returns: Personalized learning insights
    public func getLearningInsights(userId: String) async -> [String] {
        guard isInitialized else { return [] }

        guard let profile = userProfiles[userId] else {
            return await getDefaultLearningInsights()
        }

        return await behaviorAnalyzer.generateLearningInsights(profile)
    }

    /// Get user efficiency metrics
    /// - Parameter userId: User identifier
    /// - Returns: User efficiency analysis
    public func getUserEfficiencyMetrics(userId: String) async -> AIUserEfficiencyMetrics {
        guard isInitialized else {
            return AIUserEfficiencyMetrics()
        }

        guard let profile = userProfiles[userId] else {
            return AIUserEfficiencyMetrics()
        }

        return await behaviorAnalyzer.calculateEfficiencyMetrics(profile)
    }

    // MARK: - Private Implementation

    private func performPersonalization(
        context: AcquisitionContext,
        history: [UserAction]
    ) async throws -> PersonalizedRecommendations {
        // Analyze user behavior patterns
        let behaviorInsights = await behaviorAnalyzer.analyzeBehavior(history)

        // Get contextual recommendations from GraphRAG
        let contextualInsights = await graphRAG.getContextualInsights(
            context: context,
            userHistory: history
        )

        // Generate template recommendations
        let templateRecommendations = await recommendationEngine.generateTemplateRecommendations(
            behaviorInsights: behaviorInsights,
            contextualInsights: contextualInsights,
            context: context
        )

        // Generate optimization suggestions
        let optimizations = await recommendationEngine.generateOptimizations(
            behaviorInsights: behaviorInsights,
            context: context
        )

        // Generate learning insights
        let learningInsights = await behaviorAnalyzer.generatePersonalizedLearningInsights(
            behaviorInsights: behaviorInsights,
            context: context
        )

        return PersonalizedRecommendations(
            suggestedTemplates: templateRecommendations,
            optimizations: optimizations,
            learningInsights: learningInsights
        )
    }

    private func generateBasicRecommendations(
        context: AcquisitionContext
    ) async -> PersonalizedRecommendations {
        // Provide basic recommendations based on context only
        let basicTemplates = await getBasicTemplatesForProgram(context.programName)
        let basicOptimizations = ["Use standard government templates", "Include all required compliance sections"]
        let basicInsights = ["Consider using templates for similar programs", "Review FAR requirements for your document type"]

        return PersonalizedRecommendations(
            suggestedTemplates: basicTemplates,
            optimizations: basicOptimizations,
            learningInsights: basicInsights
        )
    }

    private func getDefaultTemplates(for documentType: AIDocumentType) async -> [String] {
        switch documentType {
        case .sf1449:
            ["standard-sf1449", "commercial-items-sf1449", "simplified-sf1449"]
        case .sf18:
            ["standard-sf18", "services-sf18", "supplies-sf18"]
        case .sf26:
            ["standard-sf26", "award-sf26", "modification-sf26"]
        case .sf30:
            ["standard-sf30", "amendment-sf30", "change-order-sf30"]
        case .sf33:
            ["standard-sf33", "complex-sf33", "services-sf33"]
        case .sf44:
            ["standard-sf44", "simple-purchase-sf44", "recurring-sf44"]
        case .dd1155:
            ["standard-dd1155", "supplies-dd1155", "services-dd1155"]
        }
    }

    private func getDefaultLearningInsights() async -> [String] {
        [
            "Start with standard templates and customize as needed",
            "Review similar documents from your agency for best practices",
            "Ensure all FAR compliance requirements are included",
            "Consider using document automation for repetitive sections",
        ]
    }

    private func getBasicTemplatesForProgram(_ programName: String) async -> [String] {
        // Basic template selection based on program name keywords
        let lowerProgramName = programName.lowercased()

        if lowerProgramName.contains("software") || lowerProgramName.contains("it") {
            return ["software-acquisition-template", "it-services-template"]
        } else if lowerProgramName.contains("construction") || lowerProgramName.contains("building") {
            return ["construction-template", "infrastructure-template"]
        } else if lowerProgramName.contains("research") || lowerProgramName.contains("development") {
            return ["research-template", "development-services-template"]
        } else {
            return ["general-acquisition-template", "standard-services-template"]
        }
    }

    private func generatePersonalizationKey(
        context: AcquisitionContext,
        history: [UserAction]
    ) -> String {
        let contextHash = "\(context.programName)-\(context.agency ?? "")"
        let historyHash = history.map { "\($0.type)-\($0.documentType?.rawValue ?? "")" }.joined(separator: "-")
        return "\(contextHash.hashValue)-\(historyHash.hashValue)"
    }
}

// MARK: - Supporting Types

public struct AIUserProfile: Sendable {
    public let userId: String
    public let createdAt: Date
    public let lastActive: Date
    public let actionHistory: [UserAction]
    public let preferences: UserPreferences
    public let insights: BehaviorInsights

    public init(
        userId: String,
        createdAt: Date = Date(),
        lastActive: Date = Date(),
        actionHistory: [UserAction] = [],
        preferences: UserPreferences = UserPreferences(),
        insights: BehaviorInsights = BehaviorInsights()
    ) {
        self.userId = userId
        self.createdAt = createdAt
        self.lastActive = lastActive
        self.actionHistory = actionHistory
        self.preferences = preferences
        self.insights = insights
    }
}

public struct UserPreferences: Sendable {
    public let preferredTemplates: [String]
    public let favoriteDocumentTypes: [AIDocumentType]
    public let workflowPreferences: AIWorkflowPreferences
    public let notificationSettings: AINotificationSettings

    public init(
        preferredTemplates: [String] = [],
        favoriteDocumentTypes: [AIDocumentType] = [],
        workflowPreferences: AIWorkflowPreferences = AIWorkflowPreferences(),
        notificationSettings: AINotificationSettings = AINotificationSettings()
    ) {
        self.preferredTemplates = preferredTemplates
        self.favoriteDocumentTypes = favoriteDocumentTypes
        self.workflowPreferences = workflowPreferences
        self.notificationSettings = notificationSettings
    }
}

public struct AIWorkflowPreferences: Sendable {
    public let autoSave: Bool
    public let showAdvancedOptions: Bool
    public let preferredComplexity: AIDocumentComplexity

    public init(
        autoSave: Bool = true,
        showAdvancedOptions: Bool = false,
        preferredComplexity: AIDocumentComplexity = .standard
    ) {
        self.autoSave = autoSave
        self.showAdvancedOptions = showAdvancedOptions
        self.preferredComplexity = preferredComplexity
    }
}

public struct AINotificationSettings: Sendable {
    public let complianceAlerts: Bool
    public let templateUpdates: Bool
    public let learningInsights: Bool

    public init(
        complianceAlerts: Bool = true,
        templateUpdates: Bool = true,
        learningInsights: Bool = true
    ) {
        self.complianceAlerts = complianceAlerts
        self.templateUpdates = templateUpdates
        self.learningInsights = learningInsights
    }
}

public struct BehaviorInsights: Sendable {
    public let mostUsedTemplates: [String]
    public let preferredDocumentTypes: [AIDocumentType]
    public let averageCompletionTime: TimeInterval
    public let errorPatterns: [String]
    public let efficiencyScore: Double

    public init(
        mostUsedTemplates: [String] = [],
        preferredDocumentTypes: [AIDocumentType] = [],
        averageCompletionTime: TimeInterval = 0,
        errorPatterns: [String] = [],
        efficiencyScore: Double = 0.5
    ) {
        self.mostUsedTemplates = mostUsedTemplates
        self.preferredDocumentTypes = preferredDocumentTypes
        self.averageCompletionTime = averageCompletionTime
        self.errorPatterns = errorPatterns
        self.efficiencyScore = efficiencyScore
    }
}

public struct AIUserEfficiencyMetrics: Sendable {
    public let documentsPerHour: Double
    public let averageRevisions: Double
    public let complianceScore: Double
    public let templateUsageEfficiency: Double

    public init(
        documentsPerHour: Double = 0,
        averageRevisions: Double = 0,
        complianceScore: Double = 0,
        templateUsageEfficiency: Double = 0
    ) {
        self.documentsPerHour = documentsPerHour
        self.averageRevisions = averageRevisions
        self.complianceScore = complianceScore
        self.templateUsageEfficiency = templateUsageEfficiency
    }
}

public enum AIDocumentComplexity: Sendable {
    case simple
    case standard
    case complex
    case expert
}

// MARK: - Placeholder Dependencies (Will be implemented in GREEN phase)

public struct UserProfileManager: Sendable {
    public init() {}

    public func loadUserProfiles() async {
        // Load user profiles from storage
    }

    public func addAction(to profile: AIUserProfile, action: UserAction) async -> AIUserProfile {
        // Add action to profile and return updated profile
        var updatedHistory = profile.actionHistory
        updatedHistory.append(action)

        return AIUserProfile(
            userId: profile.userId,
            createdAt: profile.createdAt,
            lastActive: Date(),
            actionHistory: updatedHistory,
            preferences: profile.preferences,
            insights: profile.insights
        )
    }

    public func updateInsights(profile: AIUserProfile, insights: BehaviorInsights) async -> AIUserProfile {
        AIUserProfile(
            userId: profile.userId,
            createdAt: profile.createdAt,
            lastActive: profile.lastActive,
            actionHistory: profile.actionHistory,
            preferences: profile.preferences,
            insights: insights
        )
    }

    public func saveUserProfile(_: AIUserProfile) async {
        // Save profile to storage
    }
}

public struct BehaviorAnalyzer: Sendable {
    public init() {}

    public func initializeBehaviorModels() async {
        // Initialize ML models for behavior analysis
    }

    public func analyzeBehavior(_: [UserAction]) async -> BehaviorInsights {
        // Placeholder behavior analysis
        BehaviorInsights()
    }

    public func generateLearningInsights(_: AIUserProfile) async -> [String] {
        ["Continue using your preferred templates", "Consider exploring advanced features"]
    }

    public func generatePersonalizedLearningInsights(
        behaviorInsights _: BehaviorInsights,
        context: AcquisitionContext
    ) async -> [String] {
        [
            "Based on your usage patterns, consider using automated workflows",
            "Your compliance score is improving - keep up the good work",
            "Try the new template suggestion feature for \(context.programName)",
        ]
    }

    public func calculateEfficiencyMetrics(_: AIUserProfile) async -> AIUserEfficiencyMetrics {
        AIUserEfficiencyMetrics()
    }
}

public struct RecommendationEngine: Sendable {
    public init() {}

    public func getTemplateRecommendations(
        profile _: AIUserProfile,
        documentType _: AIDocumentType,
        context _: AcquisitionContext
    ) async -> PersonalizedRecommendations {
        PersonalizedRecommendations()
    }

    public func generateTemplateRecommendations(
        behaviorInsights _: BehaviorInsights,
        contextualInsights _: [String],
        context _: AcquisitionContext
    ) async -> [String] {
        ["recommended-template-1", "recommended-template-2"]
    }

    public func generateOptimizations(
        behaviorInsights _: BehaviorInsights,
        context _: AcquisitionContext
    ) async -> [String] {
        [
            "Use keyboard shortcuts to improve efficiency",
            "Enable auto-save for better workflow",
            "Consider batch processing for similar documents",
        ]
    }
}

public struct GraphRAGEngine: Sendable {
    public init() {}

    public func initializeKnowledgeGraph() async {
        // Initialize GraphRAG knowledge graph
    }

    public func getContextualInsights(
        context _: AcquisitionContext,
        userHistory _: [UserAction]
    ) async -> [String] {
        [
            "Similar programs have used these templates successfully",
            "Your agency typically prefers this document structure",
        ]
    }
}

public struct PersonalizationCache: Sendable {
    public init() {}

    public func getRecommendations(key _: String) async -> PersonalizedRecommendations? {
        nil // No cache during RED phase
    }

    public func storeRecommendations(key _: String, recommendations _: PersonalizedRecommendations) async {
        // Cache storage will be implemented in GREEN phase
    }
}

# AgenticOrchestrator with Local RL Agent Implementation Plan

**Project**: AIKO (Adaptive Intelligence for Kontract Optimization)  
**Version**: 1.0  
**Date**: August 3, 2025  
**Author**: Design Architect  
**Status**: Implementation Design

---

## Overview

This implementation plan details the technical approach for integrating an AgenticOrchestrator with Local Reinforcement Learning capabilities into AIKO's existing architecture. The system leverages Contextual Multi-Armed Bandits with Thompson Sampling to enable intelligent, confidence-based decision-making for acquisition workflows while maintaining Swift 6 strict concurrency compliance.

## Architecture Impact

### Current State Analysis

The AIKO architecture currently features:
- **5 Core Engines Architecture**: AIOrchestrator, DocumentEngine, PromptRegistry, ComplianceValidator, PersonalizationEngine
- **Learning Infrastructure**: LearningLoop, AdaptiveIntelligenceService, UserHistory tracking
- **SwiftUI @Observable**: Modern state management with TCA migration complete
- **Swift 6 Compliance**: Strict concurrency with actor-based services
- **Core Data**: Local persistence layer for user data and patterns

### Proposed Changes

The AgenticOrchestrator will integrate as a new coordination layer that:
1. **Enhances AIOrchestrator**: Adds RL-based decision-making capabilities
2. **Extends Learning Infrastructure**: Integrates with existing LearningLoop for continuous improvement
3. **Preserves Architecture**: Maintains 5 Core Engines pattern while adding intelligent routing
4. **Complements Existing Services**: Works alongside AdaptiveIntelligenceService for enhanced personalization

### Integration Points

```mermaid
graph TB
    subgraph "New Components"
        AO[AgenticOrchestrator<br/>@MainActor]
        LRL[LocalRLAgent<br/>Actor]
        FSE[FeatureStateEncoder<br/>Sendable]
        RC[RewardCalculator<br/>Sendable]
    end
    
    subgraph "Existing Core Engines"
        AI[AIOrchestrator]
        DE[DocumentEngine]
        PR[PromptRegistry]
        CV[ComplianceValidator]
        PE[PersonalizationEngine]
    end
    
    subgraph "Learning Infrastructure"
        LL[LearningLoop]
        AIS[AdaptiveIntelligenceService]
        CD[Core Data]
    end
    
    AO --> LRL
    AO --> AI
    AO --> LL
    LRL --> FSE
    LRL --> RC
    LRL --> CD
    AI --> DE
    AI --> PR
    AI --> CV
    AI --> PE
    AIS --> AO
```

## Implementation Details

### Components

#### 1. AgenticOrchestrator Actor

**Location**: `Sources/Services/AgenticOrchestrator.swift`

```swift
import Foundation
import AppCore

@MainActor
public actor AgenticOrchestrator: ObservableObject {
    // MARK: - Properties
    
    private let localRLAgent: LocalRLAgent
    private let aiOrchestrator: AIOrchestrator
    private let learningLoop: LearningLoop
    private let adaptiveService: AdaptiveIntelligenceService
    private let persistenceManager: RLPersistenceManager
    
    // Published state for UI binding
    @Published public private(set) var currentDecisionMode: DecisionMode = .deferred
    @Published public private(set) var averageConfidence: Double = 0.0
    @Published public private(set) var recentDecisions: [DecisionResponse] = []
    
    // Configuration
    private let confidenceThresholds = ConfidenceThresholds(
        autonomous: 0.85,
        assisted: 0.65
    )
    
    // MARK: - Initialization
    
    public init(
        aiOrchestrator: AIOrchestrator,
        learningLoop: LearningLoop,
        adaptiveService: AdaptiveIntelligenceService,
        coreDataStack: CoreDataStack
    ) async throws {
        self.aiOrchestrator = aiOrchestrator
        self.learningLoop = learningLoop
        self.adaptiveService = adaptiveService
        
        // Initialize RL components
        self.persistenceManager = RLPersistenceManager(coreDataStack: coreDataStack)
        self.localRLAgent = try await LocalRLAgent(
            persistenceManager: persistenceManager,
            initialBandits: await persistenceManager.loadBandits()
        )
        
        // Start continuous learning
        await startLearningCycle()
    }
    
    // MARK: - Public Interface
    
    public func makeDecision(_ request: DecisionRequest) async throws -> DecisionResponse {
        // Extract features from context
        let features = FeatureStateEncoder.encode(request.context)
        
        // Get RL recommendation
        let rlRecommendation = try await localRLAgent.selectAction(
            context: features,
            actions: request.possibleActions
        )
        
        // Determine decision mode based on confidence
        let decisionMode = determineDecisionMode(confidence: rlRecommendation.confidence)
        
        // Create response
        let response = DecisionResponse(
            selectedAction: rlRecommendation.action,
            confidence: rlRecommendation.confidence,
            decisionMode: decisionMode,
            reasoning: rlRecommendation.reasoning,
            alternativeActions: rlRecommendation.alternatives
        )
        
        // Update state
        updateDecisionState(response)
        
        // Execute based on mode
        switch decisionMode {
        case .autonomous:
            await executeAutonomously(response)
        case .assisted:
            await presentForAssistance(response)
        case .deferred:
            await deferToUser(response)
        }
        
        return response
    }
    
    public func provideFeedback(
        for decision: DecisionResponse,
        feedback: UserFeedback
    ) async throws {
        // Calculate reward
        let reward = RewardCalculator.calculate(
            decision: decision,
            feedback: feedback,
            context: decision.context
        )
        
        // Update RL agent
        await localRLAgent.updateReward(
            for: decision.selectedAction,
            reward: reward,
            context: decision.context
        )
        
        // Record in learning loop
        await recordLearningEvent(decision: decision, feedback: feedback)
        
        // Persist updated state
        try await persistenceManager.saveBandits(localRLAgent.currentBandits)
    }
}
```

#### 2. LocalRLAgent Implementation

**Location**: `Sources/Services/RL/LocalRLAgent.swift`

```swift
import Foundation

public actor LocalRLAgent {
    // MARK: - Properties
    
    private var contextualBandits: [ActionIdentifier: ContextualBandit]
    private let featureExtractor: FeatureExtractor
    private let explorationRate: Double = 0.1
    private let learningRate: Double = 0.01
    
    // Thompson Sampling parameters
    private let priorAlpha: Double = 1.0
    private let priorBeta: Double = 1.0
    
    // MARK: - Types
    
    public struct ActionRecommendation {
        let action: WorkflowAction
        let confidence: Double
        let reasoning: String
        let alternatives: [AlternativeAction]
        let thompsonSample: Double
    }
    
    // MARK: - Public Methods
    
    public func selectAction(
        context: FeatureVector,
        actions: [WorkflowAction]
    ) async throws -> ActionRecommendation {
        var bestAction: WorkflowAction?
        var bestSample: Double = -1.0
        var actionSamples: [(WorkflowAction, Double)] = []
        
        // Thompson Sampling for each action
        for action in actions {
            let bandit = getBandit(for: action, context: context)
            let sample = bandit.sampleThompson()
            actionSamples.append((action, sample))
            
            if sample > bestSample {
                bestSample = sample
                bestAction = action
            }
        }
        
        guard let selectedAction = bestAction else {
            throw RLError.noValidAction
        }
        
        // Calculate confidence based on posterior distribution
        let confidence = calculateConfidence(for: selectedAction, context: context)
        
        // Generate reasoning
        let reasoning = generateReasoning(
            action: selectedAction,
            sample: bestSample,
            context: context
        )
        
        // Get alternatives
        let alternatives = actionSamples
            .sorted { $0.1 > $1.1 }
            .dropFirst()
            .prefix(3)
            .map { AlternativeAction(action: $0.0, confidence: $0.1) }
        
        return ActionRecommendation(
            action: selectedAction,
            confidence: confidence,
            reasoning: reasoning,
            alternatives: Array(alternatives),
            thompsonSample: bestSample
        )
    }
    
    public func updateReward(
        for action: WorkflowAction,
        reward: RewardSignal,
        context: AcquisitionContext
    ) async {
        let features = FeatureStateEncoder.encode(context)
        var bandit = getBandit(for: action, context: features)
        
        // Update posterior distribution
        bandit.updatePosterior(reward: reward.totalReward)
        
        // Store updated bandit
        let key = ActionIdentifier(action: action, contextHash: features.hash)
        contextualBandits[key] = bandit
        
        // Decay exploration over time
        await adjustExplorationRate()
    }
}

// MARK: - ContextualBandit

public struct ContextualBandit: Codable {
    let contextFeatures: FeatureVector
    var successCount: Double  // Beta distribution α
    var failureCount: Double  // Beta distribution β
    var lastUpdate: Date
    var totalSamples: Int
    
    mutating func updatePosterior(reward: Double) {
        if reward > 0 {
            successCount += reward
        } else {
            failureCount += 1.0 - reward
        }
        totalSamples += 1
        lastUpdate = Date()
    }
    
    func sampleThompson() -> Double {
        // Sample from Beta distribution
        return BetaDistribution.sample(alpha: successCount, beta: failureCount)
    }
    
    func expectedValue() -> Double {
        return successCount / (successCount + failureCount)
    }
    
    func variance() -> Double {
        let n = successCount + failureCount
        return (successCount * failureCount) / ((n * n) * (n + 1))
    }
}
```

#### 3. Feature State Encoder

**Location**: `Sources/Services/RL/FeatureStateEncoder.swift`

```swift
import Foundation
import AppCore

public struct FeatureStateEncoder: Sendable {
    // MARK: - Feature Extraction
    
    public static func encode(_ context: AcquisitionContext) -> FeatureVector {
        var features: [String: Double] = [:]
        
        // Document type features (one-hot encoding)
        features["docType_\(context.documentType.rawValue)"] = 1.0
        
        // Acquisition value features (normalized)
        features["value_normalized"] = normalizeValue(context.acquisitionValue)
        features["value_log"] = log10(max(1.0, context.acquisitionValue))
        
        // Complexity features
        features["complexity_score"] = context.complexity.score
        features["num_requirements"] = Double(context.regulatoryRequirements.count)
        
        // Time constraint features
        features["days_remaining"] = Double(context.timeConstraints.daysRemaining)
        features["is_urgent"] = context.timeConstraints.isUrgent ? 1.0 : 0.0
        
        // Historical features
        features["past_success_rate"] = context.historicalSuccess
        features["user_experience_level"] = context.userProfile.experienceLevel
        
        // Regulatory features
        for requirement in context.regulatoryRequirements.prefix(10) {
            features["has_\(requirement.clauseNumber)"] = 1.0
        }
        
        // Workflow state features
        features["workflow_progress"] = context.workflowProgress
        features["documents_completed"] = Double(context.completedDocuments.count)
        
        return FeatureVector(features: features)
    }
    
    private static func normalizeValue(_ value: Double) -> Double {
        // Normalize to 0-1 range using log scaling
        let maxValue = 10_000_000.0 // $10M
        let normalized = log10(max(1.0, value)) / log10(maxValue)
        return min(1.0, normalized)
    }
}

public struct FeatureVector: Hashable, Codable {
    let features: [String: Double]
    
    var hash: Int {
        // Create stable hash for context matching
        var hasher = Hasher()
        for (key, value) in features.sorted(by: { $0.key < $1.key }) {
            hasher.combine(key)
            hasher.combine(Int(value * 1000)) // Quantize for stability
        }
        return hasher.finalize()
    }
}
```

#### 4. Reward Calculator

**Location**: `Sources/Services/RL/RewardCalculator.swift`

```swift
import Foundation
import AppCore

public struct RewardCalculator: Sendable {
    // MARK: - Reward Calculation
    
    public static func calculate(
        decision: DecisionResponse,
        feedback: UserFeedback,
        context: AcquisitionContext
    ) -> RewardSignal {
        let immediateReward = calculateImmediateReward(feedback)
        let delayedReward = calculateDelayedReward(feedback, context: context)
        let complianceReward = calculateComplianceReward(decision, context: context)
        let efficiencyReward = calculateEfficiencyReward(feedback, context: context)
        
        return RewardSignal(
            immediateReward: immediateReward,
            delayedReward: delayedReward,
            complianceReward: complianceReward,
            efficiencyReward: efficiencyReward
        )
    }
    
    private static func calculateImmediateReward(_ feedback: UserFeedback) -> Double {
        switch feedback.outcome {
        case .accepted:
            return 1.0
        case .acceptedWithModifications:
            return 0.7
        case .rejected:
            return 0.0
        case .deferred:
            return 0.3
        }
    }
    
    private static func calculateDelayedReward(
        _ feedback: UserFeedback,
        context: AcquisitionContext
    ) -> Double {
        // User satisfaction score (0-1)
        let satisfaction = feedback.satisfactionScore ?? 0.5
        
        // Workflow completion bonus
        let completionBonus = feedback.workflowCompleted ? 0.2 : 0.0
        
        // Quality metrics
        let qualityScore = feedback.qualityMetrics.average
        
        return (satisfaction * 0.6 + qualityScore * 0.4) + completionBonus
    }
    
    private static func calculateComplianceReward(
        _ decision: DecisionResponse,
        context: AcquisitionContext
    ) -> Double {
        // Check FAR/DFARS compliance
        let requiredClauses = context.regulatoryRequirements
        let includedClauses = decision.selectedAction.complianceChecks
            .compactMap { $0.farClause }
        
        let coverage = Double(requiredClauses.intersection(includedClauses).count) /
                      Double(max(1, requiredClauses.count))
        
        // Penalty for missing critical clauses
        let criticalMissing = requiredClauses
            .filter { $0.isCritical }
            .subtracting(includedClauses)
            .count
        
        let penalty = Double(criticalMissing) * 0.2
        
        return max(0, coverage - penalty)
    }
    
    private static func calculateEfficiencyReward(
        _ feedback: UserFeedback,
        context: AcquisitionContext
    ) -> Double {
        guard let timeTaken = feedback.timeTaken else { return 0.5 }
        
        let expectedTime = context.timeConstraints.expectedDuration
        let efficiency = expectedTime / max(1.0, timeTaken)
        
        // Normalize to 0-1 range
        return min(1.0, efficiency)
    }
}
```

### Data Models

#### Decision Models

**Location**: `Sources/Models/AgenticModels.swift`

```swift
import Foundation
import AppCore

// MARK: - Decision Request/Response

public struct DecisionRequest: Sendable {
    public let context: AcquisitionContext
    public let possibleActions: [WorkflowAction]
    public let historicalData: [InteractionHistory]
    public let userPreferences: UserPreferences
    public let requestId: UUID
    public let timestamp: Date
    
    public init(
        context: AcquisitionContext,
        possibleActions: [WorkflowAction],
        historicalData: [InteractionHistory],
        userPreferences: UserPreferences
    ) {
        self.context = context
        self.possibleActions = possibleActions
        self.historicalData = historicalData
        self.userPreferences = userPreferences
        self.requestId = UUID()
        self.timestamp = Date()
    }
}

public struct DecisionResponse: Sendable, Identifiable {
    public let id = UUID()
    public let selectedAction: WorkflowAction
    public let confidence: Double
    public let decisionMode: DecisionMode
    public let reasoning: String
    public let alternativeActions: [AlternativeAction]
    public let context: AcquisitionContext
    public let timestamp: Date
    
    public var requiresUserIntervention: Bool {
        decisionMode != .autonomous
    }
}

public enum DecisionMode: String, Codable, Sendable {
    case autonomous  // confidence ≥ 0.85
    case assisted    // 0.65 ≤ confidence < 0.85
    case deferred    // confidence < 0.65
    
    public var description: String {
        switch self {
        case .autonomous:
            return "Proceeding automatically with high confidence"
        case .assisted:
            return "Recommendation provided, user confirmation requested"
        case .deferred:
            return "Insufficient confidence, user input required"
        }
    }
}

// MARK: - Workflow Actions

public struct WorkflowAction: Identifiable, Codable, Sendable {
    public let id = UUID()
    public let actionType: ActionType
    public let documentTemplates: [DocumentTemplate]
    public let automationLevel: AutomationLevel
    public let complianceChecks: [ComplianceCheck]
    public let estimatedDuration: TimeInterval
    
    public enum ActionType: String, Codable, Sendable {
        case generateDocument
        case requestApproval
        case performCompliance
        case automateWorkflow
        case gatherRequirements
        case validateData
        
        public var description: String {
            switch self {
            case .generateDocument:
                return "Generate acquisition document"
            case .requestApproval:
                return "Request approval from authority"
            case .performCompliance:
                return "Perform compliance validation"
            case .automateWorkflow:
                return "Automate workflow execution"
            case .gatherRequirements:
                return "Gather additional requirements"
            case .validateData:
                return "Validate input data"
            }
        }
    }
}

public enum AutomationLevel: String, Codable, Sendable {
    case manual
    case semiAutomated
    case fullyAutomated
    
    public var automationScore: Double {
        switch self {
        case .manual: return 0.0
        case .semiAutomated: return 0.5
        case .fullyAutomated: return 1.0
        }
    }
}

// MARK: - Learning Models

public struct InteractionHistory: Codable, Sendable {
    public let timestamp: Date
    public let action: WorkflowAction
    public let outcome: InteractionOutcome
    public let context: AcquisitionContext
    public let userFeedback: UserFeedback?
}

public struct UserFeedback: Codable, Sendable {
    public let outcome: FeedbackOutcome
    public let satisfactionScore: Double?
    public let workflowCompleted: Bool
    public let qualityMetrics: QualityMetrics
    public let timeTaken: TimeInterval?
    public let comments: String?
    
    public enum FeedbackOutcome: String, Codable, Sendable {
        case accepted
        case acceptedWithModifications
        case rejected
        case deferred
    }
}

public struct QualityMetrics: Codable, Sendable {
    public let accuracy: Double
    public let completeness: Double
    public let compliance: Double
    
    public var average: Double {
        (accuracy + completeness + compliance) / 3.0
    }
}
```

### Core Data Integration

#### Persistence Manager

**Location**: `Sources/Services/RL/RLPersistenceManager.swift`

```swift
import CoreData
import Foundation

public actor RLPersistenceManager {
    private let coreDataStack: CoreDataStack
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }
    
    public func saveBandits(_ bandits: [ActionIdentifier: ContextualBandit]) async throws {
        let context = coreDataStack.backgroundContext
        
        try await context.perform {
            // Clear existing bandits
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RLBandit")
            let existing = try context.fetch(fetchRequest)
            existing.forEach { context.delete($0) }
            
            // Save new bandits
            for (identifier, bandit) in bandits {
                let entity = NSEntityDescription.entity(
                    forEntityName: "RLBandit",
                    in: context
                )!
                let banditObject = NSManagedObject(entity: entity, insertInto: context)
                
                banditObject.setValue(identifier.actionId, forKey: "actionId")
                banditObject.setValue(identifier.contextHash, forKey: "contextHash")
                banditObject.setValue(bandit.successCount, forKey: "successCount")
                banditObject.setValue(bandit.failureCount, forKey: "failureCount")
                banditObject.setValue(bandit.lastUpdate, forKey: "lastUpdate")
                banditObject.setValue(bandit.totalSamples, forKey: "totalSamples")
                
                // Encode feature vector
                let featuresData = try self.encoder.encode(bandit.contextFeatures)
                banditObject.setValue(featuresData, forKey: "contextFeatures")
            }
            
            try context.save()
        }
    }
    
    public func loadBandits() async throws -> [ActionIdentifier: ContextualBandit] {
        let context = coreDataStack.backgroundContext
        
        return try await context.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "RLBandit")
            let results = try context.fetch(fetchRequest)
            
            var bandits: [ActionIdentifier: ContextualBandit] = [:]
            
            for result in results {
                guard let actionId = result.value(forKey: "actionId") as? String,
                      let contextHash = result.value(forKey: "contextHash") as? Int,
                      let successCount = result.value(forKey: "successCount") as? Double,
                      let failureCount = result.value(forKey: "failureCount") as? Double,
                      let lastUpdate = result.value(forKey: "lastUpdate") as? Date,
                      let totalSamples = result.value(forKey: "totalSamples") as? Int,
                      let featuresData = result.value(forKey: "contextFeatures") as? Data
                else { continue }
                
                let features = try self.decoder.decode(FeatureVector.self, from: featuresData)
                let identifier = ActionIdentifier(actionId: actionId, contextHash: contextHash)
                
                bandits[identifier] = ContextualBandit(
                    contextFeatures: features,
                    successCount: successCount,
                    failureCount: failureCount,
                    lastUpdate: lastUpdate,
                    totalSamples: totalSamples
                )
            }
            
            return bandits
        }
    }
}
```

### API Design

#### View Model Integration

**Location**: `Sources/ViewModels/AgenticOrchestratorViewModel.swift`

```swift
import SwiftUI
import Foundation

@MainActor
@Observable
public final class AgenticOrchestratorViewModel {
    // MARK: - Properties
    
    private let orchestrator: AgenticOrchestrator
    
    // Observable state
    public private(set) var currentDecision: DecisionResponse?
    public private(set) var isProcessing = false
    public private(set) var decisionHistory: [DecisionResponse] = []
    public private(set) var confidenceTrend: [Double] = []
    
    // UI State
    public var showAssistanceUI = false
    public var assistanceMessage = ""
    public var alternativeActions: [AlternativeAction] = []
    
    // MARK: - Public Methods
    
    public func processAcquisitionWorkflow(
        _ acquisition: Acquisition,
        availableActions: [WorkflowAction]
    ) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let context = AcquisitionContext(from: acquisition)
            let request = DecisionRequest(
                context: context,
                possibleActions: availableActions,
                historicalData: await loadHistoricalData(for: acquisition),
                userPreferences: await loadUserPreferences()
            )
            
            let decision = try await orchestrator.makeDecision(request)
            
            currentDecision = decision
            decisionHistory.append(decision)
            confidenceTrend.append(decision.confidence)
            
            // Handle UI based on decision mode
            switch decision.decisionMode {
            case .autonomous:
                // No UI intervention needed
                break
                
            case .assisted:
                showAssistanceUI = true
                assistanceMessage = decision.reasoning
                alternativeActions = decision.alternativeActions
                
            case .deferred:
                // Full manual control
                showManualWorkflowUI(for: acquisition)
            }
            
        } catch {
            handleError(error)
        }
    }
    
    public func confirmAssistedDecision() async {
        guard let decision = currentDecision else { return }
        
        await provideFeedback(
            for: decision,
            feedback: UserFeedback(
                outcome: .accepted,
                satisfactionScore: 0.8,
                workflowCompleted: false,
                qualityMetrics: QualityMetrics(
                    accuracy: 0.9,
                    completeness: 0.85,
                    compliance: 1.0
                ),
                timeTaken: nil,
                comments: nil
            )
        )
        
        showAssistanceUI = false
    }
    
    public func selectAlternativeAction(_ action: AlternativeAction) async {
        // Implementation for selecting alternative
    }
}
```

### Testing Strategy

#### Unit Tests

**Location**: `Tests/Services/AgenticOrchestratorTests.swift`

```swift
import XCTest
@testable import AIKO

final class AgenticOrchestratorTests: XCTestCase {
    var orchestrator: AgenticOrchestrator!
    var mockCoreDataStack: MockCoreDataStack!
    
    override func setUp() async throws {
        mockCoreDataStack = MockCoreDataStack()
        
        orchestrator = try await AgenticOrchestrator(
            aiOrchestrator: MockAIOrchestrator(),
            learningLoop: MockLearningLoop(),
            adaptiveService: MockAdaptiveIntelligenceService(),
            coreDataStack: mockCoreDataStack
        )
    }
    
    func testAutonomousDecision() async throws {
        // Given: High confidence context
        let context = createHighConfidenceContext()
        let actions = createStandardActions()
        
        let request = DecisionRequest(
            context: context,
            possibleActions: actions,
            historicalData: [],
            userPreferences: UserPreferences.default
        )
        
        // When: Making decision
        let decision = try await orchestrator.makeDecision(request)
        
        // Then: Should be autonomous
        XCTAssertEqual(decision.decisionMode, .autonomous)
        XCTAssertGreaterThanOrEqual(decision.confidence, 0.85)
        XCTAssertNotNil(decision.selectedAction)
    }
    
    func testThompsonSamplingConvergence() async throws {
        // Test that repeated positive feedback increases confidence
        let context = createTestContext()
        let action = createTestAction()
        
        // Simulate 50 interactions
        for i in 0..<50 {
            let request = DecisionRequest(
                context: context,
                possibleActions: [action],
                historicalData: [],
                userPreferences: UserPreferences.default
            )
            
            let decision = try await orchestrator.makeDecision(request)
            
            // Provide positive feedback
            await orchestrator.provideFeedback(
                for: decision,
                feedback: createPositiveFeedback()
            )
            
            if i > 30 {
                // After sufficient learning, confidence should be high
                XCTAssertGreaterThan(decision.confidence, 0.8)
            }
        }
    }
}
```

#### Integration Tests

**Location**: `Tests/Integration/RLIntegrationTests.swift`

```swift
final class RLIntegrationTests: XCTestCase {
    func testEndToEndWorkflow() async throws {
        // Test complete workflow from decision request to feedback
        let app = try await createTestApp()
        let acquisition = createTestAcquisition()
        
        // 1. Request decision
        let viewModel = app.agenticOrchestratorViewModel
        await viewModel.processAcquisitionWorkflow(
            acquisition,
            availableActions: WorkflowAction.standardSet
        )
        
        // 2. Verify decision made
        XCTAssertNotNil(viewModel.currentDecision)
        
        // 3. Simulate user interaction
        if viewModel.showAssistanceUI {
            await viewModel.confirmAssistedDecision()
        }
        
        // 4. Verify learning occurred
        let bandits = try await app.orchestrator.exportBandits()
        XCTAssertGreaterThan(bandits.count, 0)
    }
}
```

## Implementation Steps

### Phase 1: Core Infrastructure (Week 1)

1. **Day 1-2**: Create base actor structure
   - [ ] Implement `AgenticOrchestrator` actor
   - [ ] Create `LocalRLAgent` actor
   - [ ] Set up Core Data schema for RL persistence

2. **Day 3-4**: Implement Thompson Sampling
   - [ ] Create `ContextualBandit` struct
   - [ ] Implement Beta distribution sampling
   - [ ] Add feature extraction logic

3. **Day 5**: Integration with existing services
   - [ ] Connect to `AIOrchestrator`
   - [ ] Integrate with `LearningLoop`
   - [ ] Wire up `AdaptiveIntelligenceService`

### Phase 2: Decision Framework (Week 2)

1. **Day 1-2**: Decision routing
   - [ ] Implement confidence threshold logic
   - [ ] Create decision mode determination
   - [ ] Add alternative action ranking

2. **Day 3-4**: Reward system
   - [ ] Implement `RewardCalculator`
   - [ ] Create feedback processing
   - [ ] Add reward signal composition

3. **Day 5**: Persistence layer
   - [ ] Implement `RLPersistenceManager`
   - [ ] Create migration for Core Data
   - [ ] Add backup/restore functionality

### Phase 3: UI Integration (Week 3)

1. **Day 1-2**: View model implementation
   - [ ] Create `AgenticOrchestratorViewModel`
   - [ ] Add Observable properties
   - [ ] Implement UI state management

2. **Day 3-4**: SwiftUI views
   - [ ] Create assistance UI components
   - [ ] Add confidence visualization
   - [ ] Implement decision history view

3. **Day 5**: Testing and refinement
   - [ ] Complete unit test suite
   - [ ] Add integration tests
   - [ ] Performance optimization

### Phase 4: Production Readiness (Week 4)

1. **Day 1-2**: Performance optimization
   - [ ] Profile and optimize hot paths
   - [ ] Add caching where appropriate
   - [ ] Minimize Core Data operations

2. **Day 3-4**: Error handling and recovery
   - [ ] Implement graceful degradation
   - [ ] Add fallback mechanisms
   - [ ] Create error recovery flows

3. **Day 5**: Documentation and deployment
   - [ ] Complete API documentation
   - [ ] Create usage guides
   - [ ] Prepare for production release

## Risk Assessment

### Technical Risks

1. **Convergence Speed**
   - **Risk**: Thompson Sampling may converge slowly for rare contexts
   - **Mitigation**: Implement transfer learning between similar contexts

2. **Memory Usage**
   - **Risk**: Storing bandits for all context-action pairs
   - **Mitigation**: Implement LRU cache with Core Data backing

3. **Concurrency Complexity**
   - **Risk**: Actor isolation may complicate UI updates
   - **Mitigation**: Use `@MainActor` for UI-facing components

### Mitigation Strategies

1. **Feature Flag Deployment**
   ```swift
   if FeatureFlags.shared.isRLOrchestratorEnabled {
       // Use new RL-based orchestrator
   } else {
       // Fall back to existing logic
   }
   ```

2. **Gradual Rollout**
   - Start with low-stakes decisions
   - Monitor confidence scores and user feedback
   - Gradually increase automation threshold

3. **Continuous Monitoring**
   - Track decision accuracy metrics
   - Monitor user satisfaction scores
   - Alert on confidence degradation

## Timeline Estimate

### Development Phases
- **Phase 1**: Core Infrastructure - 5 days
- **Phase 2**: Decision Framework - 5 days
- **Phase 3**: UI Integration - 5 days
- **Phase 4**: Production Readiness - 5 days

### Testing Phases
- **Unit Testing**: Concurrent with development
- **Integration Testing**: 3 days after Phase 3
- **User Acceptance Testing**: 5 days after Phase 4

### Review Checkpoints
- **Week 1**: Core algorithm implementation review
- **Week 2**: Decision framework validation
- **Week 3**: UI/UX review
- **Week 4**: Production readiness assessment

## Success Metrics

1. **Technical Metrics**
   - Decision latency < 100ms (99th percentile)
   - Memory usage < 50MB for RL components
   - 95%+ test coverage for critical paths

2. **Business Metrics**
   - 85%+ confidence on routine workflows within 50 interactions
   - 70% reduction in manual intervention for standard acquisitions
   - User satisfaction score > 4.5/5.0

3. **Learning Metrics**
   - Confidence improvement rate > 2% per week
   - Reward signal correlation with user satisfaction > 0.8
   - Successful action prediction accuracy > 80%

---

**Implementation Authority**: Design Architect
**Validation**: Pending consensus review
**Next Steps**: Begin Phase 1 implementation upon approval
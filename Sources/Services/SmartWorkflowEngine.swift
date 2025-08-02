import AppCore
import Foundation
import SwiftUI

// MARK: - Smart Workflow Engine

/// Intelligent workflow engine that analyzes user actions and provides contextual guidance
@MainActor
@Observable
public final class SmartWorkflowEngine {
    public static let shared = SmartWorkflowEngine()
    
    // MARK: - Properties
    
    public var shouldTriggerAgentChat: Bool = false
    public var workflowGuidanceMessage: String = ""
    public var missingRequirements: [RequirementGap] = []
    public var confidenceScore: Double = 0.0
    public var lastAnalysisTimestamp: Date?
    
    private var documentSelectionHistory: [DocumentSelectionEvent] = []
    private var userInteractionPatterns: [UserInteractionPattern] = []
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Analyze current state and determine if agent chat should be triggered
    public func analyzeWorkflowState(
        selectedTypes: Set<AppCore.DocumentType>,
        selectedDFTypes: Set<AppCore.DFDocumentType>,
        hasAcquisition: Bool,
        loadedAcquisition: AppCore.Acquisition?,
        documentStatus: [AppCore.DocumentType: DocumentStatus]
    ) -> WorkflowAnalysis {
        
        let analysis = performIntelligentAnalysis(
            selectedTypes: selectedTypes,
            selectedDFTypes: selectedDFTypes,
            hasAcquisition: hasAcquisition,
            loadedAcquisition: loadedAcquisition,
            documentStatus: documentStatus
        )
        
        // Update internal state
        confidenceScore = analysis.confidenceScore
        missingRequirements = analysis.missingRequirements
        shouldTriggerAgentChat = analysis.shouldTriggerAgentChat
        workflowGuidanceMessage = analysis.guidanceMessage
        lastAnalysisTimestamp = Date()
        
        // Record user interaction pattern
        recordInteractionPattern(analysis)
        
        return analysis
    }
    
    /// Check if document execution should proceed or if more info is needed
    public func shouldProceedWithExecution(
        selectedTypes: Set<AppCore.DocumentType>,
        loadedAcquisition: AppCore.Acquisition?
    ) -> ExecutionDecision {
        
        let criticalInfo = analyzeCriticalInformation(
            selectedTypes: selectedTypes,
            acquisition: loadedAcquisition
        )
        
        if criticalInfo.missingCriticalInfo.isEmpty {
            return ExecutionDecision(
                shouldProceed: true,
                reason: "All required information is available for document generation.",
                suggestedActions: []
            )
        } else {
            return ExecutionDecision(
                shouldProceed: false,
                reason: "Missing critical information: \(criticalInfo.missingCriticalInfo.joined(separator: ", "))",
                suggestedActions: [
                    .triggerAgentChat("I need help gathering missing requirements"),
                    .openRequirementsGathering,
                    .suggestTemplates(criticalInfo.suggestedTemplates)
                ]
            )
        }
    }
    
    /// Record document selection event for pattern analysis
    public func recordDocumentSelection(
        documentType: AppCore.DocumentType,
        isSelected: Bool,
        timestamp: Date = Date()
    ) {
        let event = DocumentSelectionEvent(
            documentType: documentType,
            isSelected: isSelected,
            timestamp: timestamp
        )
        
        documentSelectionHistory.append(event)
        
        // Keep only recent history (last 100 events)
        if documentSelectionHistory.count > 100 {
            documentSelectionHistory.removeFirst()
        }
        
        // Analyze patterns after each selection
        analyzeSelectionPatterns()
    }
    
    /// Get personalized document recommendations based on user patterns
    public func getPersonalizedRecommendations(
        currentSelection: Set<AppCore.DocumentType>
    ) -> [SmartDocumentRecommendation] {
        
        var recommendations: [SmartDocumentRecommendation] = []
        
        // Analyze frequently selected document combinations
        let frequentCombinations = analyzeFrequentCombinations()
        
        for combination in frequentCombinations {
            let missingFromCombination = combination.subtracting(currentSelection)
            
            for docType in missingFromCombination {
                let recommendation = SmartDocumentRecommendation(
                    documentType: docType,
                    reason: "Frequently selected together with your current choices",
                    confidenceScore: calculateRecommendationConfidence(docType, currentSelection),
                    priority: .medium
                )
                recommendations.append(recommendation)
            }
        }
        
        // Add complementary document recommendations
        recommendations.append(contentsOf: getComplementaryRecommendations(currentSelection))
        
        // Sort by confidence score
        return recommendations.sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    // MARK: - Private Methods
    
    private func performIntelligentAnalysis(
        selectedTypes: Set<AppCore.DocumentType>,
        selectedDFTypes: Set<AppCore.DFDocumentType>,
        hasAcquisition: Bool,
        loadedAcquisition: AppCore.Acquisition?,
        documentStatus: [AppCore.DocumentType: DocumentStatus]
    ) -> WorkflowAnalysis {
        
        var gaps: [RequirementGap] = []
        var confidence: Double = 1.0
        var shouldTrigger = false
        var message = ""
        
        // Analyze acquisition status
        if !hasAcquisition || loadedAcquisition == nil {
            gaps.append(RequirementGap(
                category: .acquisition,
                description: "No acquisition loaded",
                severity: .critical,
                suggestedAction: "Load or create an acquisition to provide context for document generation"
            ))
            confidence -= 0.4
        } else if let acquisition = loadedAcquisition {
            // Analyze acquisition completeness
            if acquisition.title.isEmpty {
                gaps.append(RequirementGap(
                    category: .acquisition,
                    description: "Acquisition title missing",
                    severity: .medium,
                    suggestedAction: "Provide a descriptive title for your acquisition"
                ))
                confidence -= 0.1
            }
            
            if acquisition.requirements.count < 100 { // Basic requirement length check
                gaps.append(RequirementGap(
                    category: .requirements,
                    description: "Requirements appear incomplete or too brief",
                    severity: .high,
                    suggestedAction: "Expand your requirements with more detail about objectives, scope, and success criteria"
                ))
                confidence -= 0.3
            }
        }
        
        // Analyze document selection coherence
        let selectionCoherence = analyzeDocumentSelectionCoherence(selectedTypes)
        confidence *= selectionCoherence.coherenceScore
        
        if !selectionCoherence.isCoherent {
            gaps.append(RequirementGap(
                category: .documentSelection,
                description: selectionCoherence.issue,
                severity: .medium,
                suggestedAction: selectionCoherence.suggestion
            ))
        }
        
        // Analyze document readiness
        let readyCount = selectedTypes.count { documentStatus[$0] == .ready }
        let totalSelected = selectedTypes.count
        
        if totalSelected > 0 {
            let readinessRatio = Double(readyCount) / Double(totalSelected)
            confidence *= readinessRatio
            
            if readinessRatio < 0.5 {
                gaps.append(RequirementGap(
                    category: .documentation,
                    description: "Many selected documents are not ready for generation",
                    severity: .high,
                    suggestedAction: "Review document requirements and gather missing information"
                ))
            }
        }
        
        // Determine if agent chat should be triggered
        shouldTrigger = confidence < 0.6 || gaps.contains { $0.severity == .critical }
        
        // Generate guidance message
        if shouldTrigger {
            message = generateGuidanceMessage(gaps: gaps, confidence: confidence)
        }
        
        return WorkflowAnalysis(
            confidenceScore: max(0.0, min(1.0, confidence)),
            missingRequirements: gaps,
            shouldTriggerAgentChat: shouldTrigger,
            guidanceMessage: message,
            recommendedActions: generateRecommendedActions(gaps)
        )
    }
    
    private func analyzeDocumentSelectionCoherence(_ selectedTypes: Set<AppCore.DocumentType>) -> SelectionCoherence {
        // Check for logical document combinations
        let hasSOW = selectedTypes.contains(.sow)
        let hasPWS = selectedTypes.contains(.pws)
        let hasRFP = selectedTypes.contains(.requestForProposal)
        let hasRFQ = selectedTypes.contains(.requestForQuote)
        let hasContract = selectedTypes.contains(.contractScaffold)
        
        // Check for conflicting selections
        if hasSOW && hasPWS {
            return SelectionCoherence(
                isCoherent: false,
                coherenceScore: 0.7,
                issue: "Both Statement of Work (SOW) and Performance Work Statement (PWS) selected",
                suggestion: "Typically, you would use either SOW or PWS, not both. Choose based on whether you want performance-based (PWS) or task-based (SOW) approach."
            )
        }
        
        if hasRFP && hasRFQ {
            return SelectionCoherence(
                isCoherent: false,
                coherenceScore: 0.6,
                issue: "Both Request for Proposal (RFP) and Request for Quote (RFQ) selected",
                suggestion: "RFP is for complex procurements requiring proposals, while RFQ is for simple price quotes. Choose the appropriate method for your acquisition."
            )
        }
        
        // Check for missing essential documents
        if hasContract && !hasSOW && !hasPWS {
            return SelectionCoherence(
                isCoherent: false,
                coherenceScore: 0.8,
                issue: "Contract scaffold selected without a work statement",
                suggestion: "Consider adding either a Statement of Work (SOW) or Performance Work Statement (PWS) to define the work requirements."
            )
        }
        
        return SelectionCoherence(
            isCoherent: true,
            coherenceScore: 1.0,
            issue: "",
            suggestion: ""
        )
    }
    
    private func analyzeCriticalInformation(
        selectedTypes: Set<AppCore.DocumentType>,
        acquisition: AppCore.Acquisition?
    ) -> CriticalInfoAnalysis {
        
        var missingInfo: [String] = []
        var templates: [String] = []
        
        guard let acquisition = acquisition else {
            return CriticalInfoAnalysis(
                missingCriticalInfo: ["No acquisition loaded"],
                suggestedTemplates: ["Basic Acquisition Template"]
            )
        }
        
        // Check for budget information
        if !acquisition.requirements.localizedCaseInsensitiveContains("budget") &&
           !acquisition.requirements.localizedCaseInsensitiveContains("cost") &&
           !acquisition.requirements.localizedCaseInsensitiveContains("price") {
            missingInfo.append("Budget/cost information")
            templates.append("Budget Planning Template")
        }
        
        // Check for timeline information
        if !acquisition.requirements.localizedCaseInsensitiveContains("timeline") &&
           !acquisition.requirements.localizedCaseInsensitiveContains("schedule") &&
           !acquisition.requirements.localizedCaseInsensitiveContains("deadline") {
            missingInfo.append("Timeline/schedule information")
            templates.append("Project Timeline Template")
        }
        
        // Check for performance criteria
        if selectedTypes.contains(.pws) || selectedTypes.contains(.qasp) {
            if !acquisition.requirements.localizedCaseInsensitiveContains("performance") &&
               !acquisition.requirements.localizedCaseInsensitiveContains("metrics") &&
               !acquisition.requirements.localizedCaseInsensitiveContains("criteria") {
                missingInfo.append("Performance metrics and success criteria")
                templates.append("Performance Metrics Template")
            }
        }
        
        // Check for compliance requirements
        if selectedTypes.contains(.requestForProposal) || selectedTypes.contains(.contractScaffold) {
            let hasComplianceInfo = acquisition.requirements.localizedCaseInsensitiveContains("compliance") ||
                                  acquisition.requirements.localizedCaseInsensitiveContains("regulation") ||
                                  acquisition.requirements.localizedCaseInsensitiveContains("standard")
            
            if !hasComplianceInfo {
                missingInfo.append("Compliance and regulatory requirements")
                templates.append("Compliance Checklist Template")
            }
        }
        
        return CriticalInfoAnalysis(
            missingCriticalInfo: missingInfo,
            suggestedTemplates: templates
        )
    }
    
    private func generateGuidanceMessage(gaps: [RequirementGap], confidence: Double) -> String {
        let criticalGaps = gaps.filter { $0.severity == .critical }
        let highGaps = gaps.filter { $0.severity == .high }
        
        if !criticalGaps.isEmpty {
            return "Critical information is missing for successful document generation. I strongly recommend addressing these issues before proceeding: \(criticalGaps.map(\.description).joined(separator: ", "))"
        } else if !highGaps.isEmpty {
            return "I've identified some important gaps that could affect document quality. Let me help you gather this information: \(highGaps.map(\.description).joined(separator: ", "))"
        } else {
            return "Your acquisition setup looks good, but I can help optimize your document selection and requirements for even better results."
        }
    }
    
    private func generateRecommendedActions(_ gaps: [RequirementGap]) -> [RecommendedAction] {
        return gaps.map { gap in
            RecommendedAction(
                title: gap.suggestedAction,
                category: gap.category,
                priority: gap.severity.priority
            )
        }
    }
    
    private func recordInteractionPattern(_ analysis: WorkflowAnalysis) {
        let pattern = UserInteractionPattern(
            timestamp: Date(),
            confidenceScore: analysis.confidenceScore,
            gapCount: analysis.missingRequirements.count,
            triggeredAgentChat: analysis.shouldTriggerAgentChat
        )
        
        userInteractionPatterns.append(pattern)
        
        // Keep only recent patterns (last 50)
        if userInteractionPatterns.count > 50 {
            userInteractionPatterns.removeFirst()
        }
    }
    
    private func analyzeSelectionPatterns() {
        // This would analyze user selection patterns for future recommendations
        // Implementation would include clustering, frequency analysis, etc.
    }
    
    private func analyzeFrequentCombinations() -> [Set<AppCore.DocumentType>] {
        // Analyze historical selections to find frequent combinations
        // This is a simplified implementation
        return [
            [.sow, .requestForProposal, .evaluationPlan],
            [.pws, .qasp, .contractScaffold],
            [.marketResearch, .acquisitionPlan, .requestForProposal]
        ]
    }
    
    private func getComplementaryRecommendations(_ currentSelection: Set<AppCore.DocumentType>) -> [SmartDocumentRecommendation] {
        var recommendations: [SmartDocumentRecommendation] = []
        
        // If they have SOW, suggest evaluation plan
        if currentSelection.contains(.sow) && !currentSelection.contains(.evaluationPlan) {
            recommendations.append(SmartDocumentRecommendation(
                documentType: .evaluationPlan,
                reason: "Evaluation Plan commonly pairs with Statement of Work",
                confidenceScore: 0.8,
                priority: .high
            ))
        }
        
        // If they have PWS, suggest QASP
        if currentSelection.contains(.pws) && !currentSelection.contains(.qasp) {
            recommendations.append(SmartDocumentRecommendation(
                documentType: .qasp,
                reason: "Quality Assurance Surveillance Plan is essential for Performance Work Statements",
                confidenceScore: 0.9,
                priority: .high
            ))
        }
        
        return recommendations
    }
    
    private func calculateRecommendationConfidence(_ docType: AppCore.DocumentType, _ currentSelection: Set<AppCore.DocumentType>) -> Double {
        // Simplified confidence calculation
        // In practice, this would use machine learning or statistical models
        return 0.7 + (Double.random(in: 0...0.3))
    }
}

// MARK: - Supporting Types

public struct WorkflowAnalysis {
    public let confidenceScore: Double
    public let missingRequirements: [RequirementGap]
    public let shouldTriggerAgentChat: Bool
    public let guidanceMessage: String
    public let recommendedActions: [RecommendedAction]
}

public struct RequirementGap {
    public let category: GapCategory
    public let description: String
    public let severity: GapSeverity
    public let suggestedAction: String
    
    public enum GapCategory {
        case acquisition, requirements, documentation, documentSelection, budget, timeline, compliance
    }
    
    public enum GapSeverity {
        case low, medium, high, critical
        
        var priority: RecommendedAction.Priority {
            switch self {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            case .critical: return .critical
            }
        }
    }
}

public struct ExecutionDecision {
    public let shouldProceed: Bool
    public let reason: String
    public let suggestedActions: [SuggestedAction]
    
    public enum SuggestedAction {
        case triggerAgentChat(String)
        case openRequirementsGathering
        case suggestTemplates([String])
    }
}

public struct SmartDocumentRecommendation {
    public let documentType: AppCore.DocumentType
    public let reason: String
    public let confidenceScore: Double
    public let priority: Priority
    
    public enum Priority {
        case low, medium, high, critical
    }
}

public struct RecommendedAction {
    public let title: String
    public let category: RequirementGap.GapCategory
    public let priority: Priority
    
    public enum Priority {
        case low, medium, high, critical
    }
}

private struct SelectionCoherence {
    let isCoherent: Bool
    let coherenceScore: Double
    let issue: String
    let suggestion: String
}

private struct CriticalInfoAnalysis {
    let missingCriticalInfo: [String]
    let suggestedTemplates: [String]
}

private struct DocumentSelectionEvent {
    let documentType: AppCore.DocumentType
    let isSelected: Bool
    let timestamp: Date
}

private struct UserInteractionPattern {
    let timestamp: Date
    let confidenceScore: Double
    let gapCount: Int
    let triggeredAgentChat: Bool
}
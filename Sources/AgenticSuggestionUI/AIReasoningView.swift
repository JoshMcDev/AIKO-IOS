import AppCore
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// Expandable view for displaying AI reasoning with SHAP explanations and regulatory context
/// Shows detailed decision factors, compliance references, and audit trail information
public struct AIReasoningView: View {
    // MARK: - Properties

    private let decisionResponse: DecisionResponse
    private let complianceContext: ComplianceContext?

    @State private var isExpanded: Bool = false
    @State private var showingDetailedFactors: Bool = false

    // MARK: - Initialization

    public init(decisionResponse: DecisionResponse, complianceContext: ComplianceContext?) {
        self.decisionResponse = decisionResponse
        self.complianceContext = complianceContext
    }

    // MARK: - Body

    public var body: some View {
        // RED PHASE: Basic placeholder implementation
        VStack(alignment: .leading, spacing: 12) {
            // Summary reasoning (always visible)
            summaryReasoningView

            // Expansion toggle
            expansionToggleView

            // Expanded content (when toggled)
            if isExpanded {
                expandedContentView
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - View Components

    private var summaryReasoningView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Reasoning", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                confidenceBadge
            }

            Text(decisionResponse.reasoning)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(isExpanded ? nil : 3)
        }
    }

    private var confidenceBadge: some View {
        Text("\(Int(decisionResponse.confidence * 100))%")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.2))
            .foregroundColor(confidenceColor)
            .cornerRadius(8)
    }

    private var confidenceColor: Color {
        switch decisionResponse.confidence {
        case 0.85...:
            .green
        case 0.65 ..< 0.85:
            .orange
        default:
            .red
        }
    }

    private var expansionToggleView: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Text(isExpanded ? "Show Less" : "Show Detailed Analysis")
                    .font(.caption)
                    .foregroundColor(.blue)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(.plain)
    }

    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // RED PHASE: Placeholder sections - full implementation pending

            redPhaseSection(title: "SHAP Explanations", content: "Individual factor contributions not implemented")

            redPhaseSection(title: "Regulatory References", content: "FAR/DFARS references display not implemented")

            redPhaseSection(title: "Audit Trail", content: "Audit trail information not implemented")

            redPhaseSection(title: "Historical Precedents", content: "Historical precedent display not implemented")
        }
    }

    private func redPhaseSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(content)
                .font(.caption)
                .foregroundColor(.red)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

// MARK: - Supporting Types

/// Compliance context for regulatory references and validation
public struct ComplianceContext: Sendable {
    let farReferences: [AgenticFARReference]
    let dfarsReferences: [AgenticDFARSReference]
    let complianceScore: Double
    let riskFactors: [String]

    public init(farReferences: [AgenticFARReference], dfarsReferences: [AgenticDFARSReference], complianceScore: Double, riskFactors: [String]) {
        self.farReferences = farReferences
        self.dfarsReferences = dfarsReferences
        self.complianceScore = complianceScore
        self.riskFactors = riskFactors
    }
}

/// Federal Acquisition Regulation reference for agentic UI
public struct AgenticFARReference: Sendable {
    let section: String
    let title: String
    let url: String

    public init(section: String, title: String, url: String) {
        self.section = section
        self.title = title
        self.url = url
    }
}

/// Defense Federal Acquisition Regulation Supplement reference for agentic UI
public struct AgenticDFARSReference: Sendable {
    let section: String
    let title: String
    let url: String

    public init(section: String, title: String, url: String) {
        self.section = section
        self.title = title
        self.url = url
    }
}

// MARK: - Preview

#Preview {
    let mockDecision = DecisionResponse(
        selectedAction: WorkflowAction.placeholder,
        confidence: 0.87,
        decisionMode: .autonomous,
        reasoning: "This comprehensive recommendation integrates multiple analysis vectors including acquisition value assessment, regulatory compliance validation, historical performance patterns, stakeholder requirements, and risk mitigation strategies. The decision incorporates advanced machine learning insights from similar procurement scenarios.",
        alternativeActions: [],
        context: PreviewData.sampleAcquisitionContext,
        timestamp: Date()
    )

    let mockComplianceContext = ComplianceContext(
        farReferences: [
            AgenticFARReference(section: "52.212-1", title: "Instructions to Offerors", url: "https://example.com"),
            AgenticFARReference(section: "52.215-1", title: "Proposal Preparation", url: "https://example.com"),
        ],
        dfarsReferences: [
            AgenticDFARSReference(section: "252.212-7001", title: "Contract Terms", url: "https://example.com"),
        ],
        complianceScore: 0.94,
        riskFactors: ["procurement value", "timeline constraints"]
    )

    AIReasoningView(
        decisionResponse: mockDecision,
        complianceContext: mockComplianceContext
    )
    .padding()
}

// MARK: - Preview Data

private enum PreviewData {
    static let sampleAcquisitionContext = AcquisitionContext(
        acquisitionId: UUID(),
        documentType: .requestForProposal,
        acquisitionValue: 250_000.0,
        complexity: TestComplexityLevel(score: 3.0, factors: ["technical", "regulatory"]),
        timeConstraints: TestTimeConstraints(daysRemaining: 45, isUrgent: false, expectedDuration: 3_888_000),
        regulatoryRequirements: [TestFARClause(clauseNumber: "52.212-1", isCritical: true)],
        historicalSuccess: 0.87,
        userProfile: TestUserProfile(experienceLevel: 0.8),
        workflowProgress: 0.4,
        completedDocuments: ["requirements"]
    )
}

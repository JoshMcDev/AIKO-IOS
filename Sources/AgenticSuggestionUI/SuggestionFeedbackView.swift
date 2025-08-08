import AppCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Three-state feedback interface (Accept/Modify/Decline) with learning integration
/// Supports contextual feedback categories and batch feedback operations
public struct SuggestionFeedbackView: View {
    // MARK: - Properties

    private let suggestion: DecisionResponse
    private let onFeedback: (AgenticUserFeedback) -> Void
    private let isEnabled: Bool
    private let isProcessing: Bool

    @State private var showingModificationInput: Bool = false
    @State private var modificationText: String = ""
    @State private var showingDeclineReasons: Bool = false
    @State private var selectedDeclineReason: DeclineReason?

    // MARK: - Initialization

    public init(
        suggestion: DecisionResponse,
        onFeedback: @escaping (AgenticUserFeedback) -> Void,
        isEnabled: Bool = true,
        isProcessing: Bool = false
    ) {
        self.suggestion = suggestion
        self.onFeedback = onFeedback
        self.isEnabled = isEnabled
        self.isProcessing = isProcessing
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 16) {
            // Feedback prompt
            feedbackPromptView

            // Action buttons
            actionButtonsView

            // Modification input (when shown)
            if showingModificationInput {
                modificationInputView
            }

            // Decline reasons (when shown)
            if showingDeclineReasons {
                declineReasonsView
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .disabled(!isEnabled || isProcessing)
        .opacity(isEnabled && !isProcessing ? 1.0 : 0.6)
    }

    // MARK: - View Components

    private var feedbackPromptView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Provide Feedback", systemImage: "questionmark.bubble")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if isProcessing {
                    SwiftUI.ProgressView()
                        .scaleEffect(0.8)
                }
            }

            Text("How would you like to proceed with this suggestion?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Accept button (primary action)
            Button(action: handleAccept) {
                Label("Accept", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            // Modify button (secondary action)
            Button(action: handleModify) {
                Label("Modify", systemImage: "pencil.circle")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            // Decline button (secondary action)
            Button(action: handleDecline) {
                Label("Decline", systemImage: "xmark.circle")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .foregroundColor(.red)
        }
    }

    private var modificationInputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Modification Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel", action: {
                    showingModificationInput = false
                    modificationText = ""
                })
                .font(.caption)
                .foregroundColor(.blue)
            }

            TextField("Describe the changes you'd like to see...", text: $modificationText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3 ... 6)

            HStack {
                Spacer()

                Button("Submit Modification", action: submitModification)
                    .buttonStyle(.borderedProminent)
                    .disabled(modificationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var declineReasonsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Decline Reason")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel", action: {
                    showingDeclineReasons = false
                    selectedDeclineReason = nil
                })
                .font(.caption)
                .foregroundColor(.blue)
            }

            // RED PHASE: Decline reason categories not implemented
            VStack(alignment: .leading, spacing: 8) {
                Text("RED PHASE: Decline reason categories not implemented")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)

                Button("Submit Decline", action: submitDecline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Handlers

    private func handleAccept() {
        let feedback = AgenticUserFeedback(
            outcome: .success,
            satisfactionScore: 0.9, // Default high satisfaction for accept
            workflowCompleted: true
        )
        onFeedback(feedback)
    }

    private func handleModify() {
        showingModificationInput = true
        showingDeclineReasons = false
    }

    private func handleDecline() {
        showingDeclineReasons = true
        showingModificationInput = false
    }

    private func submitModification() {
        guard !modificationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let feedback = AgenticUserFeedback(
            outcome: .partial,
            satisfactionScore: 0.7, // Moderate satisfaction for modifications
            workflowCompleted: false
        )
        onFeedback(feedback)

        // Reset state
        showingModificationInput = false
        modificationText = ""
    }

    private func submitDecline() {
        let feedback = AgenticUserFeedback(
            outcome: .failure,
            satisfactionScore: 0.3, // Low satisfaction for decline
            workflowCompleted: false
        )
        onFeedback(feedback)

        // Reset state
        showingDeclineReasons = false
        selectedDeclineReason = nil
    }
}

// MARK: - Supporting Types

/// Reasons for declining a suggestion
public enum DeclineReason: String, CaseIterable, Sendable {
    case inaccurateAnalysis = "Inaccurate Analysis"
    case missingInformation = "Missing Information"
    case incorrectCompliance = "Incorrect Compliance"
    case timelineIssues = "Timeline Issues"
    case budgetConcerns = "Budget Concerns"
    case otherReason = "Other"

    var description: String {
        rawValue
    }
}

// MARK: - Preview

#Preview {
    let mockSuggestion = DecisionResponse(
        selectedAction: WorkflowAction.placeholder,
        confidence: 0.78,
        decisionMode: .assisted,
        reasoning: "Recommended approach based on acquisition value and regulatory requirements",
        alternativeActions: [
            AlternativeAction(action: WorkflowAction.placeholder, confidence: 0.65),
        ],
        context: PreviewData.sampleAcquisitionContext,
        timestamp: Date()
    )

    return VStack(spacing: 20) {
        // Normal state
        SuggestionFeedbackView(
            suggestion: mockSuggestion,
            onFeedback: { feedback in
                print("Feedback received: \(feedback)")
            }
        )

        // Processing state
        SuggestionFeedbackView(
            suggestion: mockSuggestion,
            onFeedback: { _ in },
            isProcessing: true
        )

        // Disabled state
        SuggestionFeedbackView(
            suggestion: mockSuggestion,
            onFeedback: { _ in },
            isEnabled: false
        )
    }
    .padding()
}

// MARK: - Preview Data

private enum PreviewData {
    static let sampleAcquisitionContext = AcquisitionContext(
        acquisitionId: UUID(),
        documentType: .requestForProposal,
        acquisitionValue: 150_000.0,
        complexity: TestComplexityLevel(score: 2.5, factors: ["technical", "regulatory"]),
        timeConstraints: TestTimeConstraints(daysRemaining: 30, isUrgent: false, expectedDuration: 2_592_000),
        regulatoryRequirements: [TestFARClause(clauseNumber: "52.212-1", isCritical: true)],
        historicalSuccess: 0.80,
        userProfile: TestUserProfile(experienceLevel: 0.75),
        workflowProgress: 0.5,
        completedDocuments: ["requirements"]
    )
}

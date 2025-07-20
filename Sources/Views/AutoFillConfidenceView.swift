import ComposableArchitecture
import SwiftUI

// MARK: - Auto-Fill Confidence View

/// Visual component showing confidence levels and auto-fill status
struct AutoFillConfidenceView: View {
    let field: RequirementField
    let confidence: Float
    let isAutoFilled: Bool
    let isSuggested: Bool
    @Binding var acceptAutoFill: Bool

    @State private var showDetails = false

    var body: some View {
        HStack(spacing: 12) {
            // Confidence indicator
            ConfidenceIndicator(confidence: confidence)
                .frame(width: 24, height: 24)

            // Field name
            Text(field.displayName)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            // Status badge
            if isAutoFilled {
                AutoFillBadge(type: .autoFilled)
            } else if isSuggested {
                AutoFillBadge(type: .suggested)
            }

            // Info button
            Button(action: { showDetails.toggle() }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .imageScale(.medium)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showDetails) {
            ConfidenceDetailsView(
                field: field,
                confidence: confidence,
                isAutoFilled: isAutoFilled
            )
        }
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: Float

    private var color: Color {
        switch confidence {
        case 0.9...: .green
        case 0.8 ..< 0.9: .blue
        case 0.65 ..< 0.8: .orange
        default: .gray
        }
    }

    private var fillAmount: CGFloat {
        CGFloat(confidence)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)

            // Confidence arc
            Circle()
                .trim(from: 0, to: fillAmount)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: fillAmount)

            // Percentage text
            Text("\(Int(confidence * 100))")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

// MARK: - Auto-Fill Badge

struct AutoFillBadge: View {
    enum BadgeType {
        case autoFilled
        case suggested

        var text: String {
            switch self {
            case .autoFilled: "Auto-filled"
            case .suggested: "Suggested"
            }
        }

        var color: Color {
            switch self {
            case .autoFilled: .green
            case .suggested: .blue
            }
        }

        var icon: String {
            switch self {
            case .autoFilled: "checkmark.circle.fill"
            case .suggested: "lightbulb.fill"
            }
        }
    }

    let type: BadgeType

    var body: some View {
        Label {
            Text(type.text)
                .font(.caption)
                .fontWeight(.medium)
        } icon: {
            Image(systemName: type.icon)
                .imageScale(.small)
        }
        .foregroundColor(type.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(type.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Confidence Details View

struct ConfidenceDetailsView: View {
    let field: RequirementField
    let confidence: Float
    let isAutoFilled: Bool

    @Environment(\.dismiss) private var dismiss

    private var confidenceDescription: String {
        switch confidence {
        case 0.9...: "Very High Confidence"
        case 0.8 ..< 0.9: "High Confidence"
        case 0.65 ..< 0.8: "Moderate Confidence"
        case 0.5 ..< 0.65: "Low Confidence"
        default: "Very Low Confidence"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Large confidence indicator
                ConfidenceIndicator(confidence: confidence)
                    .frame(width: 120, height: 120)

                // Confidence description
                VStack(spacing: 8) {
                    Text(confidenceDescription)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(Int(confidence * 100))% confidence")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Explanation
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How we determined this value", systemImage: "brain")
                            .font(.headline)

                        Text(generateExplanation())
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Status
                if isAutoFilled {
                    Label {
                        Text("This field was automatically filled based on high confidence predictions.")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.callout)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(field.displayName)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateExplanation() -> String {
        var explanation = "The value for this field was determined based on:\n\n"

        if confidence > 0.9 {
            explanation += "• Strong historical patterns from your previous entries\n"
            explanation += "• Consistent usage across similar documents\n"
            explanation += "• Organizational policies and rules\n"
        } else if confidence > 0.8 {
            explanation += "• Historical patterns from your previous work\n"
            explanation += "• Common values used in your organization\n"
            explanation += "• Document context and related fields\n"
        } else if confidence > 0.65 {
            explanation += "• Some patterns detected in previous entries\n"
            explanation += "• Partial matches with organizational defaults\n"
            explanation += "• General trends in similar acquisitions\n"
        } else {
            explanation += "• Limited historical data available\n"
            explanation += "• Basic organizational defaults\n"
            explanation += "• General system recommendations\n"
        }

        if isAutoFilled {
            explanation += "\nThe confidence was high enough to auto-fill this value, saving you time while maintaining accuracy."
        }

        return explanation
    }
}

// MARK: - Auto-Fill Summary Card

struct AutoFillSummaryCard: View {
    let summary: ConfidenceBasedAutoFillEngine.AutoFillSummary
    let onReviewSuggestions: () -> Void

    @State private var isExpanded = false

    private var timeSavedText: String {
        let minutes = Int(summary.timeSaved / 60)
        if minutes > 0 {
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        } else {
            return "\(Int(summary.timeSaved)) seconds"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Smart Defaults Applied", systemImage: "wand.and.stars")
                    .font(.headline)

                Spacer()

                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .imageScale(.small)
                        .foregroundColor(.secondary)
                }
            }

            // Summary stats
            HStack(spacing: 20) {
                StatItem(
                    value: "\(summary.autoFilledCount)",
                    label: "Auto-filled",
                    color: .green
                )

                StatItem(
                    value: "\(summary.suggestedCount)",
                    label: "Suggested",
                    color: .blue
                )

                StatItem(
                    value: timeSavedText,
                    label: "Time saved",
                    color: .purple
                )
            }

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Confidence distribution
                    Text("Confidence Distribution")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ConfidenceDistributionView(distribution: summary.confidenceDistribution)

                    // Average confidence
                    HStack {
                        Text("Average Confidence")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(summary.averageConfidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorForConfidence(summary.averageConfidence))
                    }

                    // Action button
                    if summary.suggestedCount > 0 {
                        Button(action: onReviewSuggestions) {
                            Label("Review Suggestions", systemImage: "list.bullet.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func colorForConfidence(_ confidence: Float) -> Color {
        switch confidence {
        case 0.9...: .green
        case 0.8 ..< 0.9: .blue
        case 0.65 ..< 0.8: .orange
        default: .gray
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ConfidenceDistributionView: View {
    let distribution: ConfidenceBasedAutoFillEngine.ConfidenceDistribution

    private var total: Int {
        distribution.veryHigh + distribution.high + distribution.medium + distribution.low
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                if distribution.veryHigh > 0 {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: barWidth(distribution.veryHigh, in: geometry.size.width))
                }

                if distribution.high > 0 {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: barWidth(distribution.high, in: geometry.size.width))
                }

                if distribution.medium > 0 {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: barWidth(distribution.medium, in: geometry.size.width))
                }

                if distribution.low > 0 {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: barWidth(distribution.low, in: geometry.size.width))
                }
            }
            .cornerRadius(4)
        }
        .frame(height: 8)
    }

    private func barWidth(_ count: Int, in totalWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return (CGFloat(count) / CGFloat(total)) * totalWidth
    }
}

// MARK: - Field Extensions

extension RequirementField {
    var displayName: String {
        switch self {
        case .projectTitle: "Project Title"
        case .description: "Description"
        case .estimatedValue: "Estimated Value"
        case .requiredDate: "Required Date"
        case .vendorName: "Vendor Name"
        case .vendorUEI: "Vendor UEI"
        case .vendorCAGE: "Vendor CAGE"
        case .technicalSpecs: "Technical Specifications"
        case .performanceLocation: "Performance Location"
        case .contractType: "Contract Type"
        case .setAsideType: "Set-Aside Type"
        case .specialConditions: "Special Conditions"
        case .justification: "Justification"
        case .fundingSource: "Funding Source"
        case .requisitionNumber: "Requisition Number"
        case .costCenter: "Cost Center"
        case .accountingCode: "Accounting Code"
        case .qualityRequirements: "Quality Requirements"
        case .deliveryInstructions: "Delivery Instructions"
        case .packagingRequirements: "Packaging Requirements"
        case .inspectionRequirements: "Inspection Requirements"
        case .paymentTerms: "Payment Terms"
        case .warrantyRequirements: "Warranty Requirements"
        case .attachments: "Attachments"
        case .pointOfContact: "Point of Contact"
        }
    }
}

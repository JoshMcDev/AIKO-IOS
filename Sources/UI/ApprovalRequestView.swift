import SwiftUI
#if os(iOS)
    import UIKit
#endif

// MARK: - Enhanced Approval Request View

public struct ApprovalRequestView: View {
    let request: ApprovalRequest
    let onApprove: () -> Void
    let onReject: () -> Void

    @State private var showDetails = false
    @State private var animateImpact = false

    public init(request: ApprovalRequest, onApprove: @escaping () -> Void, onReject: @escaping () -> Void) {
        self.request = request
        self.onApprove = onApprove
        self.onReject = onReject
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with impact indicator
            HStack(alignment: .top) {
                // Impact visualization
                ImpactIndicator(level: request.impact)
                    .scaleEffect(animateImpact ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: animateImpact
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Approval Required")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(impactDescription)
                        .font(.caption)
                        .foregroundColor(impactColor)
                }

                Spacer()

                // Share button
                ShareButton(
                    content: generateApprovalShareContent(),
                    fileName: DocumentShareHelper.generateFileName(for: .approvalRequest),
                    buttonStyle: .icon
                )
                .scaleEffect(0.9)

                Button(action: { withAnimation { showDetails.toggle() } }) {
                    Image(systemName: showDetails ? "chevron.up.circle.fill" : "info.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.aikoAccent)
                }
            }

            // Main message
            Text(request.message)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Action details (expandable)
            if showDetails {
                ActionDetailsView(action: request.action)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }

            // Action buttons
            HStack(spacing: 12) {
                // Reject button
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Reject")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.1))
                    )
                }

                // Approve button
                Button(action: {
                    withAnimation(.spring()) {
                        onApprove()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Approve")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(approveButtonColor)
                            .shadow(color: approveButtonColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
            }

            // Risk disclaimer for high impact
            if request.impact == .high {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("This action has significant impact and cannot be easily reversed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.aikoSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(impactColor.opacity(0.3), lineWidth: 2)
                )
        )
        .onAppear {
            if request.impact != .low {
                animateImpact = true
            }
        }
    }

    private var impactDescription: String {
        switch request.impact {
        case .low:
            "Low impact • Easily reversible"
        case .medium:
            "Medium impact • Some consequences"
        case .high:
            "High impact • Significant consequences"
        }
    }

    private var impactColor: Color {
        switch request.impact {
        case .low:
            .green
        case .medium:
            .orange
        case .high:
            .red
        }
    }

    private var approveButtonColor: Color {
        switch request.impact {
        case .low:
            .green
        case .medium:
            .orange
        case .high:
            Theme.Colors.aikoAccent
        }
    }

    private func generateApprovalShareContent() -> String {
        """
        Approval Request
        Generated: \(Date().formatted())

        IMPACT LEVEL: \(impactDescription)

        REQUEST:
        \(request.message)

        ACTION DETAILS:
        \(request.action.description)

        STATUS: Pending Approval
        """
    }
}

// MARK: - Impact Indicator

struct ImpactIndicator: View {
    let level: ApprovalRequest.ImpactLevel

    var body: some View {
        ZStack {
            // Background circles
            ForEach(0 ..< 3) { index in
                Circle()
                    .stroke(
                        impactColor.opacity(0.3 - Double(index) * 0.1),
                        lineWidth: 2
                    )
                    .frame(
                        width: 40 + CGFloat(index) * 10,
                        height: 40 + CGFloat(index) * 10
                    )
            }

            // Center icon
            Image(systemName: impactIcon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(impactColor)
        }
        .frame(width: 60, height: 60)
    }

    private var impactIcon: String {
        switch level {
        case .low:
            "checkmark.shield"
        case .medium:
            "exclamationmark.shield"
        case .high:
            "exclamationmark.triangle"
        }
    }

    private var impactColor: Color {
        switch level {
        case .low:
            .green
        case .medium:
            .orange
        case .high:
            .red
        }
    }
}

// MARK: - Action Details View

struct ActionDetailsView: View {
    let action: AgentAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Action Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            // Action type
            HStack {
                Label("Type", systemImage: "gearshape.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(actionTypeDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.aikoAccent.opacity(0.1))
                    )
            }

            // Description
            HStack(alignment: .top) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }

            // Expected outcome
            VStack(alignment: .leading, spacing: 4) {
                Label("Expected Outcome", systemImage: "target")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(expectedOutcome)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
        }
    }

    private var actionTypeDescription: String {
        switch action.type {
        case .gatherMarketResearch:
            "Market Research"
        case .generateDocuments:
            "Document Generation"
        case .identifyVendors:
            "Vendor Search"
        case .scheduleReviews:
            "Schedule Reviews"
        case .submitForApproval:
            "Submit for Approval"
        case .monitorCompliance:
            "Compliance Check"
        }
    }

    private var expectedOutcome: String {
        switch action.type {
        case .gatherMarketResearch:
            "Will search multiple databases and compile market analysis report with pricing trends and vendor capabilities"
        case .generateDocuments:
            "Will create all required acquisition documents based on gathered requirements"
        case .identifyVendors:
            "Will search SAM.gov and other databases to find qualified vendors"
        case .scheduleReviews:
            "Will coordinate with stakeholders and schedule review meetings"
        case .submitForApproval:
            "Will submit the acquisition package through the approval workflow"
        case .monitorCompliance:
            "Will continuously monitor compliance status and alert on any issues"
        }
    }
}

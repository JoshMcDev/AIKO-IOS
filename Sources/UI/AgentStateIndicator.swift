import SwiftUI
import AppCore

// MARK: - Agent State Indicator

/// An animated indicator showing the current state of the AI agent with pulse effects
public struct AgentStateIndicator: View, Sendable {
    let state: AgentState
    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0

    public init(state: AgentState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Animated icon
            ZStack {
                // Background pulse effect
                Circle()
                    .fill(stateColor.opacity(0.2))
                    .frame(width: isPulsing ? 40 : 30, height: isPulsing ? 40 : 30)
                    .animation(
                        state == .idle ? nil : Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                // Main icon
                Image(systemName: stateIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(stateColor)
                    .rotationEffect(.degrees(state == .executing ? rotationAngle : 0))
                    .animation(
                        state == .executing ? Animation.linear(duration: 2.0).repeatForever(autoreverses: false) : nil,
                        value: rotationAngle
                    )
            }
            .frame(width: 40, height: 40)

            // State text
            VStack(alignment: .leading, spacing: 2) {
                Text(stateTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                if let subtitle = stateSubtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.Colors.aikoSecondary)
                .shadow(color: stateColor.opacity(0.3), radius: state == .idle ? 0 : 8)
        )
        .onAppear {
            if state != .idle {
                isPulsing = true
                if state == .executing {
                    rotationAngle = 360
                }
            }
        }
        .onChange(of: state) { newState in
            if newState == .idle {
                isPulsing = false
                rotationAngle = 0
            } else {
                isPulsing = true
                if newState == .executing {
                    rotationAngle = 360
                }
            }
        }
    }

    private var stateIcon: String {
        switch state {
        case .idle:
            "circle.fill"
        case .thinking:
            "brain"
        case .executing:
            "gearshape.2.fill"
        case .waitingForApproval:
            "hourglass"
        case .monitoring:
            "eye.fill"
        }
    }

    private var stateColor: Color {
        switch state {
        case .idle:
            .gray
        case .thinking:
            .blue
        case .executing:
            .green
        case .waitingForApproval:
            .orange
        case .monitoring:
            .purple
        }
    }

    private var stateTitle: String {
        switch state {
        case .idle:
            "Ready"
        case .thinking:
            "Thinking"
        case .executing:
            "Working"
        case .waitingForApproval:
            "Awaiting Approval"
        case .monitoring:
            "Monitoring"
        }
    }

    private var stateSubtitle: String? {
        switch state {
        case .idle:
            "Ask me anything"
        case .thinking:
            "Processing your request"
        case .executing:
            "Executing tasks"
        case .waitingForApproval:
            "Review required"
        case .monitoring:
            "Tracking progress"
        }
    }
}

// MARK: - Preview

struct AgentStateIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AgentStateIndicator(state: .idle)
            AgentStateIndicator(state: .thinking)
            AgentStateIndicator(state: .executing)
            AgentStateIndicator(state: .waitingForApproval)
            AgentStateIndicator(state: .monitoring)
        }
        .padding()
        .background(Theme.Colors.aikoBackground)
    }
}

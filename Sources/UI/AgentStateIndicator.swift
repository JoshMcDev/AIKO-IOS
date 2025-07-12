import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Agent State Indicator
/// An animated indicator showing the current state of the AI agent with pulse effects
public struct AgentStateIndicator: View {
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
            return "circle.fill"
        case .thinking:
            return "brain"
        case .executing:
            return "gearshape.2.fill"
        case .waitingForApproval:
            return "hourglass"
        case .monitoring:
            return "eye.fill"
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .idle:
            return .gray
        case .thinking:
            return .blue
        case .executing:
            return .green
        case .waitingForApproval:
            return .orange
        case .monitoring:
            return .purple
        }
    }
    
    private var stateTitle: String {
        switch state {
        case .idle:
            return "Ready"
        case .thinking:
            return "Thinking"
        case .executing:
            return "Working"
        case .waitingForApproval:
            return "Awaiting Approval"
        case .monitoring:
            return "Monitoring"
        }
    }
    
    private var stateSubtitle: String? {
        switch state {
        case .idle:
            return "Ask me anything"
        case .thinking:
            return "Processing your request"
        case .executing:
            return "Executing tasks"
        case .waitingForApproval:
            return "Review required"
        case .monitoring:
            return "Tracking progress"
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
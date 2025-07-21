import SwiftUI
import ComposableArchitecture
import AppCore

/// Main progress indicator view that switches between different presentation styles
public struct ProgressIndicatorView: View {
    let progressState: ProgressState
    let style: ProgressIndicatorStyle

    public init(
        progressState: ProgressState,
        style: ProgressIndicatorStyle = .detailed
    ) {
        self.progressState = progressState
        self.style = style
    }

    public var body: some View {
        switch style {
        case .compact:
            CompactProgressView(progressState: progressState)
        case .detailed:
            DetailedProgressView(progressState: progressState)
        case .accessible:
            AccessibleProgressView(progressState: progressState)
        }
    }
}

/// Style options for progress indicator presentation
public enum ProgressIndicatorStyle: Sendable {
    case compact
    case detailed
    case accessible
}

// MARK: - Sub-views (STUB IMPLEMENTATIONS)

struct DetailedProgressView: View {
    let progressState: ProgressState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phase and current step
            HStack {
                Image(systemName: progressState.phase.systemImageName)
                    .foregroundColor(.accentColor)
                Text(progressState.phase.displayName)
                    .font(.headline)
                Spacer()
                Text("\(Int(progressState.fractionCompleted * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            ProgressView(value: progressState.fractionCompleted)
                .progressViewStyle(LinearProgressViewStyle())

            // Current step description
            Text(progressState.currentStep)
                .font(.caption)
                .foregroundColor(.secondary)

            // Step counter
            if progressState.totalSteps > 1 {
                Text("Step \(progressState.currentStepIndex + 1) of \(progressState.totalSteps)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressState.accessibilityLabel)
    }
}

struct CompactProgressView: View {
    let progressState: ProgressState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: progressState.phase.systemImageName)
                .foregroundColor(.accentColor)
                .frame(width: 16, height: 16)

            ProgressView(value: progressState.fractionCompleted)
                .frame(height: 4)

            Text("\(Int(progressState.fractionCompleted * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(minWidth: 30, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressState.accessibilityLabel)
    }
}

struct AccessibleProgressView: View {
    let progressState: ProgressState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Large, high-contrast phase indicator
            HStack {
                Image(systemName: progressState.phase.systemImageName)
                    .font(.title)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(progressState.phase.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(Int(progressState.fractionCompleted * 100))% Complete")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Large progress bar
            ProgressView(value: progressState.fractionCompleted)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .progressViewStyle(LinearProgressViewStyle())

            // Clear step description
            Text(progressState.currentStep)
                .font(.body)
                .foregroundColor(.primary)

            // Step information
            if progressState.totalSteps > 1 {
                Text("Step \(progressState.currentStepIndex + 1) of \(progressState.totalSteps)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressState.accessibilityLabel)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

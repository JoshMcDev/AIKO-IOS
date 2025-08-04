#if os(iOS)
import UIKit
#endif
import AppCore
import SwiftUI

// MARK: - Color Compatibility

#if os(iOS)
private var backgroundColorCompat: Color {
    Color(UIColor.systemBackground)
}

private var strokeColorCompat: Color {
    Color(UIColor.systemGray4)
}
#else
private var backgroundColorCompat: Color {
    Color.primary.opacity(0.05)
}

private var strokeColorCompat: Color {
    Color.gray.opacity(0.3)
}
#endif

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
                Image(systemName: progressState.currentPhase.systemImageName)
                    .foregroundColor(.accentColor)
                Text(progressState.currentPhase.displayName)
                    .font(.headline)
                Spacer()
                Text("\(Int(progressState.overallProgress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            ProgressView(value: progressState.overallProgress)
                .progressViewStyle(LinearProgressViewStyle())

            // Current step description
            Text(progressState.currentOperation)
                .font(.caption)
                .foregroundColor(.secondary)

            // Phase progress indicator
            if progressState.phaseProgress < 1.0 {
                Text("Phase Progress: \(Int(progressState.phaseProgress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(backgroundColorCompat)
        .cornerRadius(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressState.accessibilityLabel)
    }
}

struct CompactProgressView: View {
    let progressState: ProgressState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: progressState.currentPhase.systemImageName)
                .foregroundColor(.accentColor)
                .frame(width: 16, height: 16)

            ProgressView(value: progressState.overallProgress)
                .frame(height: 4)

            Text("\(Int(progressState.overallProgress * 100))%")
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
                Image(systemName: progressState.currentPhase.systemImageName)
                    .font(.title)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(progressState.currentPhase.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(Int(progressState.overallProgress * 100))% Complete")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Large progress bar
            ProgressView(value: progressState.overallProgress)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .progressViewStyle(LinearProgressViewStyle())

            // Clear step description
            Text(progressState.currentOperation)
                .font(.body)
                .foregroundColor(.primary)

            // Phase progress information
            if progressState.phaseProgress < 1.0 {
                Text("Phase Progress: \(Int(progressState.phaseProgress * 100))%")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .background(backgroundColorCompat)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(strokeColorCompat, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressState.accessibilityLabel)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

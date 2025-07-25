import AppCore
import ComposableArchitecture
import SwiftUI

#if os(iOS)
    import AIKOiOS
#elseif os(macOS)
    import AIKOmacOS
#endif

// MARK: - Follow-On Action Card View

struct FollowOnActionCardView: View {
    let action: FollowOnAction
    let isExecuting: Bool
    let onTap: () -> Void
    @Dependency(\.themeService) var themeService

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: action.category.icon)
                        .font(.title3)
                        .foregroundColor(.accentColor)

                    Text(action.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if isExecuting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        PriorityBadge(priority: action.priority)
                    }
                }

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Label(formatDuration(action.estimatedDuration), systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    AutomationLevelBadge(level: action.automationLevel)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeService.groupedSecondaryBackground())
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isExecuting ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isExecuting)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours) hr"
        }
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: ActionPriority

    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(priorityColor.opacity(0.2))
            )
            .foregroundColor(priorityColor)
    }

    private var priorityColor: Color {
        switch priority {
        case .critical:
            .red
        case .high:
            .orange
        case .medium:
            .yellow
        case .low:
            .green
        }
    }
}

// MARK: - Automation Level Badge

struct AutomationLevelBadge: View {
    let level: AutomationLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)

            Text(level.rawValue)
                .font(.caption2)
        }
        .foregroundColor(.secondary)
    }

    private var iconName: String {
        switch level {
        case .manual:
            "person.fill"
        case .semiAutomated:
            "person.and.arrow.left.and.arrow.right"
        case .fullyAutomated:
            "gear"
        }
    }
}

// MARK: - Follow-On Actions List View

struct FollowOnActionsListView: View {
    let actions: [FollowOnAction]
    let executingActionIds: Set<UUID>
    let completedActionIds: Set<UUID>
    let onActionTap: (FollowOnAction) -> Void
    @Dependency(\.themeService) var themeService

    var availableActions: [FollowOnAction] {
        actions.filter { action in
            !completedActionIds.contains(action.id) &&
                action.dependencies.allSatisfy { completedActionIds.contains($0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Suggested Actions", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(availableActions.count) available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableActions.prefix(5)) { action in
                        FollowOnActionCardView(
                            action: action,
                            isExecuting: executingActionIds.contains(action.id),
                            onTap: { onActionTap(action) }
                        )
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(themeService.groupedBackground())
    }
}

// MARK: - Inline Action Suggestion View

struct InlineActionSuggestion: View {
    let action: FollowOnAction
    let isExecuting: Bool
    let onAccept: () -> Void
    let onDismiss: () -> Void
    @Dependency(\.themeService) var themeService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.category.icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isExecuting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                HStack(spacing: 8) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(themeService.groupedTertiaryBackground())
                            )
                    }

                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.accentColor)
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeService.groupedSecondaryBackground())
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Action Progress View

struct ActionProgressView: View {
    let action: FollowOnAction
    let progress: Double
    @Dependency(\.themeService) var themeService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: action.category.icon)
                    .font(.caption)
                    .foregroundColor(.accentColor)

                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeService.groupedTertiaryBackground())
        )
    }
}

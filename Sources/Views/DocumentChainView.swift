import SwiftUI

// MARK: - Document Chain View

struct DocumentChainView: View {
    let chainProgress: DocumentChainProgress?
    let validation: ChainValidation?
    let onSelectDocument: (DocumentType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text("Document Chain")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if let chainProgress {
                    Text("\(Int(chainProgress.progress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let chainProgress {
                // Chain visualization
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(Array(chainProgress.plannedDocuments.enumerated()), id: \.offset) { index, document in
                            DocumentChainNode(
                                document: document,
                                isCompleted: chainProgress.completedDocuments[document] != nil,
                                isCurrent: index == chainProgress.currentIndex,
                                hasError: validation?.missingData[document] != nil,
                                onTap: { onSelectDocument(document) }
                            )

                            if index < chainProgress.plannedDocuments.count - 1 {
                                ChainConnector(
                                    isActive: chainProgress.completedDocuments[document] != nil
                                )
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }

                // Validation messages
                if let validation {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        if !validation.brokenLinks.isEmpty {
                            ForEach(validation.brokenLinks, id: \.from.rawValue) { link in
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)

                                    Text(link.reason)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }

                        ForEach(validation.recommendations, id: \.self) { recommendation in
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                Text(recommendation)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } else {
                // Empty state
                Text("No document chain created yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.aikoSecondary)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Document Chain Node

struct DocumentChainNode: View {
    let document: DocumentType
    let isCompleted: Bool
    let isCurrent: Bool
    let hasError: Bool
    let onTap: () -> Void

    var nodeColor: Color {
        if hasError {
            .orange
        } else if isCompleted {
            .green
        } else if isCurrent {
            Color(red: 0.6, green: 0.4, blue: 1.0)
        } else {
            .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(nodeColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(nodeColor)
                    } else {
                        Image(systemName: document.icon)
                            .font(.body)
                            .foregroundColor(nodeColor)
                    }
                }

                Text(document.shortName)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)

                if isCurrent {
                    Text("Current")
                        .font(.caption2)
                        .foregroundColor(nodeColor)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chain Connector

struct ChainConnector: View {
    let isActive: Bool

    var body: some View {
        Rectangle()
            .fill(isActive ? Color.green : Color.gray)
            .frame(width: 30, height: 2)
            .overlay(
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(isActive ? .green : .gray)
            )
    }
}

// MARK: - Document Chain Progress Bar

struct DocumentChainProgressBar: View {
    let chainProgress: DocumentChainProgress

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text("Chain Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(chainProgress.completedDocuments.count) of \(chainProgress.plannedDocuments.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.6, green: 0.4, blue: 1.0),
                                Color(red: 0.4, green: 0.2, blue: 0.8),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(chainProgress.progress), height: 8)
                        .animation(.easeInOut, value: chainProgress.progress)
                }
            }
            .frame(height: 8)
        }
    }
}

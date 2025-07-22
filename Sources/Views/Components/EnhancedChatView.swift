import AppCore
import ComposableArchitecture
import SwiftUI

// MARK: - Enhanced Chat History

struct EnhancedChatHistoryView: View {
    let messages: [String]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            ResponsiveText(content: "Chat History", style: .headline)
                .accessibleHeader(label: "Chat History", level: .heading2)

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                    EnhancedChatBubble(
                        message: message,
                        isUser: message.hasPrefix("User:"),
                        isLoading: isLoading && index == messages.count - 1
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: message.hasPrefix("User:") ? .bottomTrailing : .bottomLeading)
                            .combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                if isLoading {
                    HStack(spacing: Theme.Spacing.small) {
                        LoadingDotsView(dotSize: 8, color: .blue)
                        ResponsiveText(content: "AIKO is thinking...", style: .caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.small)
                    .accessibilityLabel("AIKO is processing your request")
                }
            }
            .padding(Theme.Spacing.large)
            .background(
                EnhancedCard(content: {
                    Color.clear
                }, style: .glassmorphism)
            )
        }
    }
}

// MARK: - Enhanced Chat Bubble

struct EnhancedChatBubble: View {
    let message: String
    let isUser: Bool
    let isLoading: Bool

    @State private var showMessage = false

    var cleanMessage: String {
        if isUser {
            message.replacingOccurrences(of: "User: ", with: "")
        } else {
            message.replacingOccurrences(of: "AIKO: ", with: "")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.small) {
            if !isUser {
                ZStack {
                    Circle()
                        .fill(
                            Color.blue.opacity(0.3)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .pulse(duration: 2.0, scale: 1.1)
                .accessibilityHidden(true)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                ResponsiveText(
                    content: isUser ? "You" : "AIKO",
                    style: .caption
                )
                .foregroundColor(.secondary)

                ResponsiveText(content: cleanMessage, style: .body)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(isUser ? Theme.Colors.aikoAccent : Theme.Colors.aikoSecondary)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    )
                    .scaleEffect(showMessage ? 1.0 : 0.8)
                    .opacity(showMessage ? 1.0 : 0.0)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if isUser {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }
        }
        .onAppear {
            withAnimation(AnimationSystem.Spring.bouncy.delay(0.1)) {
                showMessage = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "AIKO") said: \(cleanMessage)")
    }
}
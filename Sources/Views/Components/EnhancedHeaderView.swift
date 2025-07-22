import AppCore
import ComposableArchitecture
import SwiftUI

// MARK: - Enhanced Header View

struct EnhancedHeaderView: View {
    @Binding var showMenu: Bool
    let loadedAcquisition: AppCore.Acquisition?
    let loadedAcquisitionDisplayName: String?
    let hasSelectedDocuments: Bool
    let onNewAcquisition: () -> Void
    let onSAMGovLookup: () -> Void
    let onExecuteAll: () -> Void

    @State private var logoScale: CGFloat = 1.0
    @Environment(\.sizeCategory) private var sizeCategory

    @Dependency(\.imageLoader) var imageLoader

    private func loadSAMIcon() -> Image? {
        // For Swift Package, load from module bundle
        guard let url = Bundle.module.url(forResource: "SAMIcon", withExtension: "png") else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return imageLoader.loadImage(data)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Animated AIKO Logo
            ResponsiveText(content: "AIKO", style: .largeTitle)
                .foregroundStyle(
                    Theme.Colors.aikoPrimary
                )
                .scaleEffect(logoScale)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        logoScale = 1.05
                    }
                }
                .accessibilityLabel("AIKO - AI Contract Intelligence Officer")

            Spacer()

            // Acquisition name with animation
            if let displayName = loadedAcquisitionDisplayName {
                ResponsiveText(content: displayName, style: .headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 200)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Current acquisition: \(displayName)")

                Spacer()
            }

            // Enhanced action buttons
            DynamicStack {
                // Execute all button with pulse animation
                AnimatedButton(action: onExecuteAll) {
                    Image(systemName: hasSelectedDocuments ? "play.fill" : "play")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.aikoPrimary)
                                .shadow(color: Theme.Colors.aikoPrimary.opacity(0.3), radius: hasSelectedDocuments ? 8 : 0)
                        )
                }
                .disabled(!hasSelectedDocuments)
                .opacity(hasSelectedDocuments ? 1.0 : 0.6)
                .accessibleButton(
                    label: "Execute all documents",
                    hint: hasSelectedDocuments ? "Tap to generate selected documents" : "No documents selected"
                )
                .pulse(duration: 2.0, scale: 1.1)
                .opacity(hasSelectedDocuments ? 1.0 : 0.6)

                // New acquisition button
                AnimatedButton(action: onNewAcquisition) {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.aikoPrimary)
                        )
                }
                .accessibleButton(
                    label: "New acquisition",
                    hint: "Start a new acquisition"
                )

                // SAM.gov lookup button
                AnimatedButton(action: onSAMGovLookup) {
                    Group {
                        if let samIcon = loadSAMIcon() {
                            samIcon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black)
                                        .overlay(
                                            Circle()
                                                .stroke(Theme.Colors.aikoPrimary, lineWidth: 2)
                                        )
                                )
                        } else {
                            Text("SAM")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Theme.Colors.aikoPrimary)
                                )
                        }
                    }
                }
                .accessibleButton(
                    label: "SAM.gov lookup",
                    hint: "Search SAM.gov database"
                )

                // Menu button with rotation animation
                AnimatedButton(action: { showMenu.toggle() }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Theme.Colors.aikoPrimary)
                        )
                        .rotationEffect(.degrees(showMenu ? 90 : 0))
                }
                .accessibleButton(
                    label: "Menu",
                    hint: showMenu ? "Close menu" : "Open menu"
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(
            GlassmorphicView {
                Color.black
            }
        )
    }
}
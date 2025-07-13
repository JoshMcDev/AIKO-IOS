import SwiftUI

struct FaceIDAuthenticationView: View {
    let isAuthenticating: Bool
    let error: String?
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.aikoBackground
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Logo or App Icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.aikoAccent)

                Text("AIKO")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                // Face ID Icon and Status
                VStack(spacing: Theme.Spacing.lg) {
                    if isAuthenticating {
                        Image(systemName: "faceid")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.aikoAccent)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.aikoAccent))
                                    .scaleEffect(1.5)
                            )

                        Text("Authenticating...")
                            .font(.headline)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "faceid")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.aikoAccent)

                        Text("Use Face ID to unlock AIKO")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.aikoError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()

                // Retry Button or Unlock Button
                if !isAuthenticating {
                    Button(action: onRetry) {
                        Label(error != nil ? "Try Again" : "Unlock with Face ID",
                              systemImage: error != nil ? "arrow.clockwise" : "faceid")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: 200)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.aikoPrimary)
                            .cornerRadius(Theme.CornerRadius.sm)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Automatically trigger Face ID authentication when view appears
            if !isAuthenticating, error == nil {
                onRetry()
            }
        }
    }
}

import AppCore
import ComposableArchitecture
import SwiftUI

struct AppIconPreview: View, @unchecked Sendable {
    @Dependency(\.imageLoader) var imageLoader
    var body: some View {
        VStack(spacing: 30) {
            Text("AIKO App Icon")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Try to load from bundle first, then from file paths
            if let image = loadAppIcon() {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .cornerRadius(44)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            } else {
                // Fallback if image not found
                RoundedRectangle(cornerRadius: 44)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Text("AppIcon.png\nnot found")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    )
            }

            Text("AI Contract Intelligence Officer")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(systemBackground)
    }

    private func loadAppIcon() -> Image? {
        // Try loading from file paths
        let paths = [
            "/Users/J/Documents/GitHub/AIKO-IOS/Sources/Resources/AppIcon.png",
            "/Users/J/Documents/GitHub/AIKO-IOS/Sources/UI/AppIcon.png",
            "/Users/J/Documents/GitHub/AIKO-IOS/AIKO/AIKO/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        ]

        for path in paths {
            if let platformImage = imageLoader.loadImageFromFile(path) {
                return imageLoader.convertToSwiftUIImage(platformImage)
            }
        }

        return nil
    }

    private var systemBackground: Color {
        Theme.Colors.aikoBackground
    }
}

struct AppIconPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AppIconPreview()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            AppIconPreview()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
        }
    }
}

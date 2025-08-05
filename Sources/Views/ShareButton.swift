import SwiftUI

#if os(iOS)
import AIKOiOS
#elseif os(macOS)
import AIKOmacOS
#endif

/// Unified cross-platform share button
public struct ShareButton: View {
    let content: String
    let fileName: String
    let buttonStyle: ShareButtonStyle

    public enum ShareButtonStyle {
        case icon
        case text
        case iconAndText
    }

    public init(
        content: String,
        fileName: String,
        buttonStyle: ShareButtonStyle = .iconAndText
    ) {
        self.content = content
        self.fileName = fileName
        self.buttonStyle = buttonStyle
    }

    public var body: some View {
        #if os(iOS)
        IOSShareButton(
            items: [content],
            title: buttonTitle
        )
        #elseif os(macOS)
        MacOSShareButton(
            items: [content],
            title: buttonTitle
        )
        #else
        Button(buttonTitle) {
            // Fallback for other platforms
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(content, forType: .string)
            #elseif canImport(UIKit)
            UIPasteboard.general.string = content
            #endif
        }
        #endif
    }

    private var buttonTitle: String {
        switch buttonStyle {
        case .icon:
            "􀈂" // SF Symbol for share
        case .text:
            "Share"
        case .iconAndText:
            "Share"
        }
    }
}

#if DEBUG
struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ShareButton(
                content: "Sample content to share",
                fileName: "sample.txt",
                buttonStyle: .icon
            )

            ShareButton(
                content: "Sample content to share",
                fileName: "sample.txt",
                buttonStyle: .text
            )

            ShareButton(
                content: "Sample content to share",
                fileName: "sample.txt",
                buttonStyle: .iconAndText
            )
        }
        .padding()
    }
}
#endif

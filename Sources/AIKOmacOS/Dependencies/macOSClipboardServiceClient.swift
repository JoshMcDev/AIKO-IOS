#if os(macOS)
import AppCore
import Foundation

public extension ClipboardServiceClient {
    static let macOSLive = Self(
        copyText: { text in
            MacOSClipboardService().copyText(text)
        },
        copyData: { data, type in
            MacOSClipboardService().copyData(data, type: type)
        },
        getText: {
            MacOSClipboardService().getText()
        },
        hasContent: { type in
            MacOSClipboardService().hasContent(ofType: type)
        }
    )
}

// Convenience static accessor
public enum MacOSClipboardServiceClient {
    public static let live = ClipboardServiceClient.macOSLive
}#endif

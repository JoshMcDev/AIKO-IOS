import AppCore
import ComposableArchitecture
import Foundation

extension ClipboardServiceClient {
    public static let macOSLive = Self(
        copyText: { text in
            macOSClipboardService().copyText(text)
        },
        copyData: { data, type in
            macOSClipboardService().copyData(data, type: type)
        },
        getText: {
            macOSClipboardService().getText()
        },
        hasContent: { type in
            macOSClipboardService().hasContent(ofType: type)
        }
    )
}

// Convenience static accessor
public enum macOSClipboardServiceClient {
    public static let live = ClipboardServiceClient.macOSLive
}
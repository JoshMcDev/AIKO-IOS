import AppCore
import ComposableArchitecture
import Foundation

extension ClipboardServiceClient {
    public static let iOSLive = Self(
        copyText: { text in
            iOSClipboardService().copyText(text)
        },
        copyData: { data, type in
            iOSClipboardService().copyData(data, type: type)
        },
        getText: {
            iOSClipboardService().getText()
        },
        hasContent: { type in
            iOSClipboardService().hasContent(ofType: type)
        }
    )
}

// Convenience static accessor
public enum iOSClipboardServiceClient {
    public static let live = ClipboardServiceClient.iOSLive
}
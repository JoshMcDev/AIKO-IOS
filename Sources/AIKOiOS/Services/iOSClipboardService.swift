import Foundation
import UIKit
import AppCore

/// iOS implementation of ClipboardServiceProtocol
public final class iOSClipboardService: ClipboardServiceProtocol {
    public init() {}
    
    public func copyText(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    public func copyData(_ data: Data, type: String) {
        UIPasteboard.general.setData(data, forPasteboardType: type)
    }
    
    public func getText() -> String? {
        return UIPasteboard.general.string
    }
    
    public func hasContent(ofType type: String) -> Bool {
        return UIPasteboard.general.contains(pasteboardTypes: [type])
    }
}
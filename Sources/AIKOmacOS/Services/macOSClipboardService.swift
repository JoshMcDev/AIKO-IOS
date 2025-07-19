import Foundation
import AppKit
import AppCore

/// macOS implementation of ClipboardServiceProtocol
public final class macOSClipboardService: ClipboardServiceProtocol {
    public init() {}
    
    public func copyText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    public func copyData(_ data: Data, type: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: NSPasteboard.PasteboardType(type))
    }
    
    public func getText() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
    
    public func hasContent(ofType type: String) -> Bool {
        let types = NSPasteboard.general.types ?? []
        return types.contains(NSPasteboard.PasteboardType(type))
    }
}
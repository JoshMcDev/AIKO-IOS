import SwiftUI

#if os(iOS)
import UIKit

struct RichTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
    }
}

#else
import AppKit

struct RichTextView: NSViewRepresentable {
    let attributedText: NSAttributedString
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
}
#endif

// SwiftUI wrapper for consistent usage
public struct DocumentRichTextView: View {
    let content: String
    let attributedContent: NSAttributedString?
    
    public init(content: String, attributedContent: NSAttributedString? = nil) {
        self.content = content
        self.attributedContent = attributedContent
    }
    
    public var body: some View {
        if let attributedContent = attributedContent {
            RichTextView(attributedText: attributedContent)
        } else {
            // Fallback to converting plain text to attributed string
            let (_, attributed) = RTFFormatter.convertToRTF(content)
            RichTextView(attributedText: attributed)
        }
    }
}
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

public struct RTFFormatter {
    
    // Convert plain text or markdown to RTF
    public static func convertToRTF(_ text: String) -> (rtfString: String, attributedString: NSAttributedString) {
        // Parse the text for markdown-style formatting
        let attributedString = parseMarkdown(text)
        
        // Convert to RTF data
        let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.rtf
            ]
        )
        
        let rtfString = rtfData.flatMap { String(data: $0, encoding: .utf8) } ?? text
        
        return (rtfString, attributedString)
    }
    
    // Parse markdown-style formatting
    private static func parseMarkdown(_ text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        #if os(iOS)
        let regularFont = UIFont.systemFont(ofSize: 12)
        let boldFont = UIFont.boldSystemFont(ofSize: 12)
        let italicFont = UIFont.italicSystemFont(ofSize: 12)
        let headingFont = UIFont.boldSystemFont(ofSize: 16)
        let subheadingFont = UIFont.boldSystemFont(ofSize: 14)
        #else
        let regularFont = NSFont.systemFont(ofSize: 12)
        let boldFont = NSFont.boldSystemFont(ofSize: 12)
        let italicFont = NSFontManager.shared.convert(regularFont, toHaveTrait: .italicFontMask)
        let headingFont = NSFont.boldSystemFont(ofSize: 16)
        let subheadingFont = NSFont.boldSystemFont(ofSize: 14)
        #endif
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8
        
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            var processedLine = line
            var attributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .paragraphStyle: paragraphStyle
            ]
            
            // Check for headings
            if processedLine.hasPrefix("# ") {
                processedLine = String(processedLine.dropFirst(2))
                attributes[.font] = headingFont
                
                // Add spacing before headings (except first line)
                if index > 0 {
                    attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
                }
            } else if processedLine.hasPrefix("## ") {
                processedLine = String(processedLine.dropFirst(3))
                attributes[.font] = subheadingFont
                
                // Add spacing before subheadings
                if index > 0 {
                    attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
                }
            }
            
            // Process inline formatting
            let mutableLine = NSMutableAttributedString(string: processedLine, attributes: attributes)
            
            // Bold text (**text**)
            let boldPattern = "\\*\\*(.*?)\\*\\*"
            processBoldText(in: mutableLine, pattern: boldPattern, font: boldFont)
            
            // Italic text (*text*)
            let italicPattern = "\\*([^\\*]+)\\*"
            processItalicText(in: mutableLine, pattern: italicPattern, font: italicFont)
            
            // Bullet points
            if processedLine.hasPrefix("- ") || processedLine.hasPrefix("• ") {
                let bulletParagraphStyle = paragraphStyle.mutableCopy() as! NSMutableParagraphStyle
                bulletParagraphStyle.firstLineHeadIndent = 0
                bulletParagraphStyle.headIndent = 20
                
                let bulletLine = NSMutableAttributedString(string: "• ", attributes: attributes)
                let content = String(processedLine.dropFirst(2))
                bulletLine.append(NSAttributedString(string: content, attributes: [
                    .font: regularFont,
                    .paragraphStyle: bulletParagraphStyle
                ]))
                
                attributedString.append(bulletLine)
            } else {
                attributedString.append(mutableLine)
            }
            
            // Add newline if not last line
            if index < lines.count - 1 {
                attributedString.append(NSAttributedString(string: "\n", attributes: attributes))
            }
        }
        
        return attributedString
    }
    
    private static func processBoldText(in attributedString: NSMutableAttributedString, pattern: String, font: Any) {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: attributedString.length)
        
        regex?.enumerateMatches(in: attributedString.string, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            
            // Replace **text** with text and apply bold
            let fullRange = match.range
            let textRange = match.range(at: 1)
            
            if let substring = attributedString.string.substring(with: textRange) {
                attributedString.replaceCharacters(in: fullRange, with: substring)
                let newRange = NSRange(location: fullRange.location, length: substring.count)
                attributedString.addAttribute(.font, value: font, range: newRange)
            }
        }
    }
    
    private static func processItalicText(in attributedString: NSMutableAttributedString, pattern: String, font: Any) {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: attributedString.length)
        
        regex?.enumerateMatches(in: attributedString.string, options: [], range: range) { match, _, _ in
            guard let match = match else { return }
            
            // Replace *text* with text and apply italic
            let fullRange = match.range
            let textRange = match.range(at: 1)
            
            if let substring = attributedString.string.substring(with: textRange) {
                attributedString.replaceCharacters(in: fullRange, with: substring)
                let newRange = NSRange(location: fullRange.location, length: substring.count)
                attributedString.addAttribute(.font, value: font, range: newRange)
            }
        }
    }
    
    // Generate RTF header
    public static func generateRTFHeader() -> String {
        return """
        {\\rtf1\\ansi\\deff0 {\\fonttbl{\\f0 Times New Roman;}}
        {\\colortbl;\\red0\\green0\\blue0;}
        \\viewkind4\\uc1\\pard\\f0\\fs24
        """
    }
    
    // Generate RTF footer
    public static func generateRTFFooter() -> String {
        return "}"
    }
    
    // Create full RTF document
    public static func createRTFDocument(title: String, content: String, metadata: [String: String] = [:]) -> String {
        var rtf = generateRTFHeader()
        
        // Title
        rtf += "\\b\\fs32 \(escapeRTF(title))\\b0\\fs24\\par\\par\n"
        
        // Metadata
        if !metadata.isEmpty {
            for (key, value) in metadata {
                rtf += "\\b \(escapeRTF(key)):\\b0 \(escapeRTF(value))\\par\n"
            }
            rtf += "\\par\n"
        }
        
        // Content
        let (rtfContent, _) = convertToRTF(content)
        rtf += rtfContent
        
        rtf += generateRTFFooter()
        
        return rtf
    }
    
    // Escape special RTF characters
    public static func escapeRTF(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
    }
}

// String extension helper
extension String {
    func substring(with nsRange: NSRange) -> String? {
        guard let range = Range(nsRange, in: self) else { return nil }
        return String(self[range])
    }
}

// Font typealias is not needed - NSFont and UIFont are already defined in their respective frameworks
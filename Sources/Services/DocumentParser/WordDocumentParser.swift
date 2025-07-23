import Compression
import Foundation
import UniformTypeIdentifiers

/// Parser for Word documents (.docx and .doc files)
public final class WordDocumentParser {
    // MARK: - Properties

    private let xmlParser = XMLParser()

    // MARK: - Public Methods

    /// Parse a Word document and extract text
    public func parse(_ data: Data, type: UTType) async throws -> String {
        // Check for modern .docx format
        if type.identifier == "com.microsoft.word.docx" ||
            type.identifier == "org.openxmlformats.wordprocessingml.document" ||
            type.identifier == "com.microsoft.word.wordml" {
            return try await parseDocx(data)
        }

        // Check if type conforms to Word document types
        let docxType = UTType(filenameExtension: "docx") ?? UTType(mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document") ?? UTType.data
        let docType = UTType(filenameExtension: "doc") ?? UTType(mimeType: "application/msword") ?? UTType.data

        if type.conforms(to: docxType) {
            return try await parseDocx(data)
        } else if type.identifier == "com.microsoft.word.doc" || type.conforms(to: docType) {
            // Legacy .doc format - extract what text we can
            return extractTextFromLegacyDoc(data)
        } else {
            throw DocumentParserError.unsupportedFormat
        }
    }

    // MARK: - Private Methods

    /// Parse modern .docx format by extracting text from the ZIP structure
    private func parseDocx(_ data: Data) async throws -> String {
        // First try to parse as ZIP and extract document.xml content
        if let xmlContent = try? extractDocumentXMLFromZip(data) {
            return try parseDocumentXML(xmlContent)
        }

        // Fallback: Try direct text extraction
        return extractTextFromDocxData(data)
    }

    /// Extract document.xml from the ZIP structure of a .docx file
    private func extractDocumentXMLFromZip(_ data: Data) throws -> Data? {
        // .docx files have a specific structure with document.xml containing the main content
        // We'll look for the local file header signature and extract the content

        let zipSignature: [UInt8] = [0x50, 0x4B, 0x03, 0x04] // "PK\x03\x04"

        var currentIndex = 0
        while currentIndex < data.count - 4 {
            // Look for ZIP local file header
            let subdata = data.subdata(in: currentIndex ..< currentIndex + 4)
            if Array(subdata) == zipSignature {
                // Found a file entry, parse the header
                if let fileData = parseZipFileEntry(data, at: currentIndex) {
                    if fileData.filename.contains("word/document.xml") {
                        return fileData.content
                    }
                }
            }
            currentIndex += 1
        }

        return nil
    }

    /// Parse a ZIP file entry at the given offset
    private func parseZipFileEntry(_ data: Data, at offset: Int) -> (filename: String, content: Data)? {
        guard offset + 30 <= data.count else { return nil }

        // Skip to filename length field (26 bytes from start)
        let filenameLengthOffset = offset + 26
        let filenameLength = data.subdata(in: filenameLengthOffset ..< filenameLengthOffset + 2).withUnsafeBytes { $0.load(as: UInt16.self) }

        // Skip to extra field length (28 bytes from start)
        let extraLengthOffset = offset + 28
        let extraLength = data.subdata(in: extraLengthOffset ..< extraLengthOffset + 2).withUnsafeBytes { $0.load(as: UInt16.self) }

        // Get filename
        let filenameStart = offset + 30
        let filenameEnd = filenameStart + Int(filenameLength)
        guard filenameEnd <= data.count else { return nil }

        let filenameData = data.subdata(in: filenameStart ..< filenameEnd)
        guard let filename = String(data: filenameData, encoding: .utf8) else { return nil }

        // Get compressed data
        let dataStart = filenameEnd + Int(extraLength)

        // For simplicity, we'll read a reasonable amount of data
        // In a real implementation, we'd parse the compressed size from the header
        let maxSize = min(1024 * 1024, data.count - dataStart) // Max 1MB
        guard dataStart + maxSize <= data.count else { return nil }

        let compressedData = data.subdata(in: dataStart ..< dataStart + maxSize)

        // Try to decompress (docx uses DEFLATE compression)
        if let decompressed = decompress(data: compressedData) {
            return (filename: filename, content: decompressed)
        }

        return nil
    }

    /// Decompress DEFLATE compressed data
    private func decompress(data: Data) -> Data? {
        data.withUnsafeBytes { bytes in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count * 10)
            defer { buffer.deallocate() }

            let result = compression_decode_buffer(
                buffer, data.count * 10,
                bytes.bindMemory(to: UInt8.self).baseAddress!, data.count,
                nil, COMPRESSION_ZLIB
            )

            guard result > 0 else { return nil }
            return Data(bytes: buffer, count: result)
        }
    }

    /// Parse the document.xml file to extract text
    private func parseDocumentXML(_ xmlData: Data) throws -> String {
        let parser = XMLParser(data: xmlData)
        let delegate = DocxParserDelegate()
        parser.delegate = delegate

        guard parser.parse() else {
            throw DocumentParserError.xmlParsingFailed
        }

        return delegate.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fallback method to extract text directly from .docx data
    private func extractTextFromDocxData(_ data: Data) -> String {
        var extractedText = ""

        // Convert data to string and look for text content between XML tags
        if let xmlString = String(data: data, encoding: .utf8) {
            extractedText = extractTextFromXMLString(xmlString)
        }

        // If UTF-8 didn't work, try UTF-16
        if extractedText.isEmpty, let xmlString = String(data: data, encoding: .utf16) {
            extractedText = extractTextFromXMLString(xmlString)
        }

        // If still no text, try binary extraction
        if extractedText.isEmpty {
            extractedText = extractTextFromBinary(data)
        }

        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extract text from XML string using regex
    private func extractTextFromXMLString(_ xmlString: String) -> String {
        var extractedText = ""

        // Look for text in <w:t> tags (Word paragraph text)
        let textPattern = "<w:t[^>]*>([^<]+)</w:t>"
        if let regex = try? NSRegularExpression(pattern: textPattern, options: []) {
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

            for match in matches {
                if let range = Range(match.range(at: 1), in: xmlString) {
                    extractedText += String(xmlString[range]) + " "
                }
            }
        }

        // Also look for text in <t> tags (alternative format)
        let altPattern = "<t[^>]*>([^<]+)</t>"
        if let regex = try? NSRegularExpression(pattern: altPattern, options: []) {
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

            for match in matches {
                if let range = Range(match.range(at: 1), in: xmlString) {
                    let text = String(xmlString[range])
                    if !extractedText.contains(text) {
                        extractedText += text + " "
                    }
                }
            }
        }

        return extractedText
    }

    /// Extract text from legacy .doc format
    private func extractTextFromLegacyDoc(_ data: Data) -> String {
        // Legacy .doc files are complex binary formats
        // We'll do our best to extract readable text

        var text = ""
        var buffer = ""
        let minWordLength = 3

        for byte in data {
            // Check if byte is printable ASCII or extended ASCII
            if (byte >= 32 && byte <= 126) || (byte >= 160 && byte <= 255) {
                buffer.append(Character(UnicodeScalar(byte)))
            } else if byte == 0x0D || byte == 0x0A {
                // Carriage return or line feed
                if buffer.count >= minWordLength {
                    text += buffer + "\n"
                }
                buffer = ""
            } else if byte == 0x20 || byte == 0x09 {
                // Space or tab
                if buffer.count >= minWordLength {
                    text += buffer + " "
                }
                buffer = ""
            } else {
                // Non-printable character
                if buffer.count >= minWordLength {
                    text += buffer + " "
                }
                buffer = ""
            }
        }

        // Don't forget the last buffer
        if buffer.count >= minWordLength {
            text += buffer
        }

        // Clean up the text
        return cleanExtractedText(text)
    }

    /// Fallback method to extract readable text from binary data
    private func extractTextFromBinary(_ data: Data) -> String {
        var text = ""
        var currentString = ""

        for byte in data {
            // Check if byte is printable ASCII
            if byte >= 32, byte <= 126 {
                currentString.append(Character(UnicodeScalar(byte)))
            } else {
                // Non-printable character - save current string if long enough
                if currentString.count > 3 {
                    text += currentString + " "
                }
                currentString = ""
            }
        }

        // Don't forget the last string
        if currentString.count > 3 {
            text += currentString
        }

        return cleanExtractedText(text)
    }

    /// Clean extracted text by removing duplicates and excessive whitespace
    private func cleanExtractedText(_ text: String) -> String {
        // Remove multiple spaces
        var cleaned = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Remove multiple newlines
        cleaned = cleaned.replacingOccurrences(of: "\\n+", with: "\n", options: .regularExpression)

        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }
}

// MARK: - XML Parser Delegate

/// Delegate to handle XML parsing of .docx document content
private class DocxParserDelegate: NSObject, XMLParserDelegate {
    var extractedText = ""
    private var currentElement = ""
    private var isInTextElement = false
    private var currentParagraph = ""

    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes _: [String: String] = [:]) {
        currentElement = elementName

        // Track when we're in a text element
        if elementName == "w:t" {
            isInTextElement = true
        } else if elementName == "w:p" {
            // New paragraph
            currentParagraph = ""
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        if isInTextElement {
            currentParagraph += string
        }
    }

    func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        if elementName == "w:t" {
            isInTextElement = false
        } else if elementName == "w:p", !currentParagraph.isEmpty {
            // End of paragraph - add to extracted text
            extractedText += currentParagraph + "\n"
            currentParagraph = ""
        }
    }
}

// MARK: - Error Types

extension DocumentParserError {
    static let invalidDocumentStructure = DocumentParserError.unsupportedFormat
    static let xmlParsingFailed = DocumentParserError.unsupportedFormat
}

// MARK: - Alternative Implementation Without ZIPFoundation

/// Alternative parser that extracts text without external dependencies
public final class WordDocumentParserLite {
    /// Parse .docx by manually reading ZIP structure
    public func parseDocx(_ data: Data) async throws -> String {
        // .docx files are ZIP archives
        // We'll implement a basic ZIP reader to extract document.xml

        // For now, we'll use a simplified approach that looks for text patterns
        // This is less accurate but doesn't require external dependencies

        var extractedText = ""

        // Convert data to string and look for text content between XML tags
        if let xmlString = String(data: data, encoding: .utf8) {
            // Simple regex to find text between <w:t> tags
            let pattern = "<w:t[^>]*>([^<]+)</w:t>"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

            for match in matches {
                if let range = Range(match.range(at: 1), in: xmlString) {
                    extractedText += String(xmlString[range]) + " "
                }
            }
        } else {
            // Try with UTF-16 encoding (some Word docs use this)
            if let xmlString = String(data: data, encoding: .utf16) {
                let pattern = "<w:t[^>]*>([^<]+)</w:t>"
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

                for match in matches {
                    if let range = Range(match.range(at: 1), in: xmlString) {
                        extractedText += String(xmlString[range]) + " "
                    }
                }
            }
        }

        // If we couldn't extract any text, try a more basic approach
        if extractedText.isEmpty {
            extractedText = extractTextFromBinary(data)
        }

        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fallback method to extract readable text from binary data
    private func extractTextFromBinary(_ data: Data) -> String {
        var text = ""
        var currentString = ""

        for byte in data {
            // Check if byte is printable ASCII
            if byte >= 32, byte <= 126 {
                currentString.append(Character(UnicodeScalar(byte)))
            } else {
                // Non-printable character - save current string if long enough
                if currentString.count > 3 {
                    text += currentString + " "
                }
                currentString = ""
            }
        }

        // Don't forget the last string
        if currentString.count > 3 {
            text += currentString
        }

        return text
    }
}

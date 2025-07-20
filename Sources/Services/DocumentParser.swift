import Foundation
import MultipartKit
import PDFKit
import UniformTypeIdentifiers
import Vision

public protocol DocumentParserProtocol {
    func parseDocument(_ data: Data, type: UTType) async throws -> String
    func parseImage(_ image: Data) async throws -> String
}

public struct DocumentParser: DocumentParserProtocol {
    private let wordParser = WordDocumentParser()
    private let validator = DocumentParserValidator()

    public init() {}

    public func parseDocument(_ data: Data, type: UTType) async throws -> String {
        // Validate document first
        try validator.validateDocument(data, type: type)

        let extractedText: String

        if type == .pdf {
            extractedText = try parsePDF(data)
        } else if type == .rtf || type.conforms(to: .text) {
            extractedText = try parseText(data)
        } else if type.conforms(to: .image) {
            extractedText = try await parseImage(data)
        } else if isWordDocument(type) {
            extractedText = try await wordParser.parse(data, type: type)
        } else {
            throw DocumentParserError.unsupportedFormat
        }

        // Validate extracted text
        try validator.validateExtractedText(extractedText)

        return extractedText
    }

    public func parseImage(_ imageData: Data) async throws -> String {
        #if os(iOS)
            guard let image = UIImage(data: imageData) else {
                throw DocumentParserError.invalidImageData
            }
        #else
            guard let image = NSImage(data: imageData) else {
                throw DocumentParserError.invalidImageData
            }
        #endif

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocumentParserError.ocrFailed)
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: recognizedText)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]

            #if os(iOS)
                guard let cgImage = image.cgImage else {
                    continuation.resume(throwing: DocumentParserError.invalidImageData)
                    return
                }
            #else
                var rect = NSRect.zero
                guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                    continuation.resume(throwing: DocumentParserError.invalidImageData)
                    return
                }
            #endif

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func parsePDF(_ data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw DocumentParserError.invalidPDFData
        }

        var text = ""
        for pageIndex in 0 ..< document.pageCount {
            if let page = document.page(at: pageIndex),
               let pageText = page.string
            {
                text += pageText + "\n"
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseText(_ data: Data) throws -> String {
        guard let text = String(data: data, encoding: .utf8) else {
            throw DocumentParserError.invalidTextEncoding
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isWordDocument(_ type: UTType) -> Bool {
        // Check for common Word document types
        let wordTypes = [
            "com.microsoft.word.doc",
            "com.microsoft.word.docx",
            "org.openxmlformats.wordprocessingml.document",
            "com.microsoft.word.wordml",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ]

        // Check by identifier
        if wordTypes.contains(type.identifier) {
            return true
        }

        // Check by file extension
        let docType = UTType(filenameExtension: "doc") ?? .data
        let docxType = UTType(filenameExtension: "docx") ?? .data

        return type.conforms(to: docType) || type.conforms(to: docxType)
    }
}

public enum DocumentParserError: Error, LocalizedError {
    case unsupportedFormat
    case invalidImageData
    case invalidPDFData
    case invalidTextEncoding
    case ocrFailed

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Unsupported document format"
        case .invalidImageData:
            "Invalid image data"
        case .invalidPDFData:
            "Invalid PDF data"
        case .invalidTextEncoding:
            "Invalid text encoding"
        case .ocrFailed:
            "OCR processing failed"
        }
    }
}

#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

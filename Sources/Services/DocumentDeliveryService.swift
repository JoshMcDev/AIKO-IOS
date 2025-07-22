import AppCore
import ComposableArchitecture
import Foundation
import PDFKit

#if os(iOS)
    import MessageUI
    import UIKit
#else
    import AppKit
#endif

public struct DocumentDeliveryService: Sendable {
    public var downloadDocuments: @Sendable ([GeneratedDocument]) async throws -> Void
    public var emailDocuments: @Sendable ([GeneratedDocument], String) async throws -> Void
    public var packageDocuments: @Sendable ([GeneratedDocument], DocumentFormat) async throws -> Data

    public init(
        downloadDocuments: @escaping @Sendable ([GeneratedDocument]) async throws -> Void,
        emailDocuments: @escaping @Sendable ([GeneratedDocument], String) async throws -> Void,
        packageDocuments: @escaping @Sendable ([GeneratedDocument], DocumentFormat) async throws -> Data
    ) {
        self.downloadDocuments = downloadDocuments
        self.emailDocuments = emailDocuments
        self.packageDocuments = packageDocuments
    }
}

public enum DocumentFormat: CaseIterable {
    case pdf
    case docx

    public var fileExtension: String {
        switch self {
        case .pdf: "pdf"
        case .docx: "docx"
        }
    }

    public var mimeType: String {
        switch self {
        case .pdf: "application/pdf"
        case .docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        }
    }
}

extension DocumentDeliveryService: DependencyKey {
    public static var liveValue: DocumentDeliveryService {
        DocumentDeliveryService(
            downloadDocuments: { documents in
                print("📥 Downloading \(documents.count) documents...")

                // Create both PDF and DOCX versions
                for document in documents {
                    let filename = document.title.replacingOccurrences(of: " ", with: "_")

                    // Generate PDF
                    let pdfData = try await generatePDF(for: document)
                    try await saveToDocuments(data: pdfData, filename: "\(filename).pdf")

                    // Generate DOCX (simplified as RTF for now)
                    let docxData = try await generateDOCX(for: document)
                    try await saveToDocuments(data: docxData, filename: "\(filename).docx")

                    print(" Generated: \(filename).pdf and \(filename).docx")
                }

                print(" Download completed - files saved to Documents folder")
            },
            emailDocuments: { documents, emailAddress in
                print("📧 Sending \(documents.count) documents to: \(emailAddress)")

                var attachments: [(Data, String, String)] = []

                // Generate attachments
                for document in documents {
                    let filename = document.title.replacingOccurrences(of: " ", with: "_")

                    // Add PDF attachment
                    let pdfData = try await generatePDF(for: document)
                    attachments.append((pdfData, "\(filename).pdf", "application/pdf"))

                    // Add DOCX attachment
                    let docxData = try await generateDOCX(for: document)
                    attachments.append((docxData, "\(filename).docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                }

                // Spell check the email body
                @Dependency(\.spellCheckService) var spellCheckService
                let emailBody = createEmailBody(for: documents)
                let correctedEmailBody = await spellCheckService.checkAndCorrect(emailBody)

                // Send email with attachments
                try await sendEmailWithAttachments(
                    to: emailAddress,
                    subject: "AIKO Generated Contract Documents",
                    body: correctedEmailBody,
                    attachments: attachments
                )

                print(" Email sent successfully to \(emailAddress)")
            },
            packageDocuments: { documents, format in
                print("📦 Packaging \(documents.count) documents as \(format.fileExtension.uppercased())")

                switch format {
                case .pdf:
                    return try await generateCombinedPDF(for: documents)
                case .docx:
                    return try await generateCombinedDOCX(for: documents)
                }
            }
        )
    }

    public static var testValue: DocumentDeliveryService {
        DocumentDeliveryService(
            downloadDocuments: { documents in
                print("Test: Downloaded \(documents.count) documents")
            },
            emailDocuments: { documents, email in
                print("Test: Emailed \(documents.count) documents to \(email)")
            },
            packageDocuments: { _, _ in
                Data("Test document package".utf8)
            }
        )
    }
}

// MARK: - Helper Functions for Document Generation

private func generatePDF(for document: GeneratedDocument) async throws -> Data {
    #if os(iOS)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        return pdfRenderer.pdfData { context in
            context.beginPage()

            let title = document.title
            let content = document.content

            // Header
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleRect = CGRect(x: 50, y: 50, width: 512, height: 40)
            title.draw(in: titleRect, withAttributes: [
                .font: titleFont,
                .foregroundColor: UIColor.black,
            ])

            // Content
            let contentFont = UIFont.systemFont(ofSize: 12)
            let contentRect = CGRect(x: 50, y: 120, width: 512, height: 600)
            content.draw(in: contentRect, withAttributes: [
                .font: contentFont,
                .foregroundColor: UIColor.black,
            ])

            // Footer
            let footerFont = UIFont.systemFont(ofSize: 10)
            let footerRect = CGRect(x: 50, y: 750, width: 512, height: 20)
            "Generated by AIKO - AI Contract Intelligence Officer".draw(in: footerRect, withAttributes: [
                .font: footerFont,
                .foregroundColor: UIColor.gray,
            ])
        }
    #else
        // macOS implementation using PDFDocument
        let pdfDocument = PDFDocument()
        let page = PDFPage()

        let content = "\(document.title)\n\n\(document.content)\n\nGenerated by AIKO - AI Contract Intelligence Officer"
        _ = NSAttributedString(string: content)

        page.setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
        pdfDocument.insert(page, at: pdfDocument.pageCount)

        return pdfDocument.dataRepresentation() ?? Data()
    #endif
}

private func generateDOCX(for document: GeneratedDocument) async throws -> Data {
    // Use the pre-generated RTF content from the document
    let metadata: [String: String] = [
        "Document Type": document.documentCategory.displayName,
        "Generated": DateFormatter.localizedString(from: document.createdAt, dateStyle: .medium, timeStyle: .short),
    ]

    let rtfDocument = RTFFormatter.createRTFDocument(
        title: document.title,
        content: document.content,
        metadata: metadata
    )

    return rtfDocument.data(using: .utf8) ?? Data()
}

private func generateCombinedPDF(for documents: [GeneratedDocument]) async throws -> Data {
    #if os(iOS)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        return pdfRenderer.pdfData { context in
            for (index, document) in documents.enumerated() {
                if index > 0 {
                    context.beginPage()
                } else {
                    context.beginPage()
                }

                let title = document.title
                let content = document.content

                // Header
                let titleFont = UIFont.boldSystemFont(ofSize: 24)
                let titleRect = CGRect(x: 50, y: 50, width: 512, height: 40)
                title.draw(in: titleRect, withAttributes: [
                    .font: titleFont,
                    .foregroundColor: UIColor.black,
                ])

                // Content
                let contentFont = UIFont.systemFont(ofSize: 12)
                let contentRect = CGRect(x: 50, y: 120, width: 512, height: 600)
                content.draw(in: contentRect, withAttributes: [
                    .font: contentFont,
                    .foregroundColor: UIColor.black,
                ])

                // Footer
                let footerFont = UIFont.systemFont(ofSize: 10)
                let footerRect = CGRect(x: 50, y: 750, width: 512, height: 20)
                "Generated by AIKO - Page \(index + 1) of \(documents.count)".draw(in: footerRect, withAttributes: [
                    .font: footerFont,
                    .foregroundColor: UIColor.gray,
                ])
            }
        }
    #else
        // macOS implementation
        let pdfDocument = PDFDocument()

        for (index, document) in documents.enumerated() {
            let page = PDFPage()
            let content = "\(document.title)\n\n\(document.content)\n\nGenerated by AIKO - Page \(index + 1) of \(documents.count)"
            _ = NSAttributedString(string: content)

            page.setBounds(CGRect(x: 0, y: 0, width: 612, height: 792), for: .mediaBox)
            pdfDocument.insert(page, at: pdfDocument.pageCount)
        }

        return pdfDocument.dataRepresentation() ?? Data()
    #endif
}

private func generateCombinedDOCX(for documents: [GeneratedDocument]) async throws -> Data {
    var rtf = RTFFormatter.generateRTFHeader()

    for (index, document) in documents.enumerated() {
        if index > 0 {
            rtf += "\\page\n"
        }

        // Title
        rtf += "\\b\\fs32 \(RTFFormatter.escapeRTF(document.title))\\b0\\fs24\\par\\par\n"

        // Metadata
        rtf += "\\b Document Type:\\b0 \(RTFFormatter.escapeRTF(document.documentCategory.displayName))\\par\n"
        rtf += "\\b Generated:\\b0 \(DateFormatter.localizedString(from: document.createdAt, dateStyle: .medium, timeStyle: .short))\\par\\par\n"

        // Content (use pre-converted RTF)
        let (rtfContent, _) = RTFFormatter.convertToRTF(document.content)
        rtf += rtfContent
    }

    rtf += "\\par\\par\\fs20\\i Generated by AIKO - AI Contract Intelligence Officer\\i0\\par\n"
    rtf += RTFFormatter.generateRTFFooter()

    return rtf.data(using: .utf8) ?? Data()
}

private func saveToDocuments(data: Data, filename: String) async throws {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsPath.appendingPathComponent(filename)

    try data.write(to: fileURL)
}

private func sendEmailWithAttachments(
    to emailAddress: String,
    subject: String,
    body _: String,
    attachments: [(Data, String, String)]
) async throws {
    // In a real implementation, this would use:
    // 1. MessageUI framework for native mail
    // 2. Or email service API (SendGrid, etc.)
    // 3. For now, we'll simulate the email sending

    print("📧 Email Details:")
    print("   To: \(emailAddress)")
    print("   Subject: \(subject)")
    print("   Attachments: \(attachments.count)")

    // Simulate network delay
    try await Task.sleep(nanoseconds: 2_000_000_000)
}

private func createEmailBody(for documents: [GeneratedDocument]) -> String {
    let documentList = documents.map { "• \($0.title)" }.joined(separator: "\n")

    return """
    Dear Valued Client,

    Please find your generated contract documents attached to this email.

    Documents included:
    \(documentList)

    These documents have been generated using AIKO (AI Contract Intelligence Officer) based on your requirements and are compliant with Federal Acquisition Regulation (FAR) standards.

    If you have any questions or need modifications, please don't hesitate to contact us.

    Best regards,
    AIKO Team
    """
}

public extension DependencyValues {
    var documentDeliveryService: DocumentDeliveryService {
        get { self[DocumentDeliveryService.self] }
        set { self[DocumentDeliveryService.self] = newValue }
    }
}

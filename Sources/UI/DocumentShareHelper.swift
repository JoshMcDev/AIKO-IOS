import AppCore
import ComposableArchitecture
import SwiftUI

// Helper to generate shareable content from various document types
enum DocumentShareHelper {
    // Generate text content for an Acquisition
    static func generateAcquisitionText(_ acquisition: Acquisition) -> String {
        var content = """
        Acquisition Report
        Generated: \(Date().formatted())

        ACQUISITION DETAILS:
        - ID: \(acquisition.id?.uuidString ?? "N/A")
        - Title: \(acquisition.title ?? "Untitled")
        - Project Number: \(acquisition.projectNumber ?? "N/A")
        - Status: \(acquisition.status ?? "Unknown")
        - Created: \(acquisition.createdDate?.formatted() ?? "Unknown")
        - Modified: \(acquisition.lastModifiedDate?.formatted() ?? "Unknown")

        REQUIREMENTS:
        \(acquisition.requirements ?? "No requirements specified")
        """

        // Add document chain metadata if available
        if let chainData = acquisition.getDocumentChain() {
            content += "\n\nDOCUMENT CHAIN METADATA:"
            for (key, value) in chainData {
                content += "\n- \(key): \(value)"
            }
        }

        // Add document count
        let docCount = acquisition.documents?.count ?? 0
        let uploadCount = acquisition.uploadedFiles?.count ?? 0
        let generatedCount = acquisition.generatedFiles?.count ?? 0

        content += """


        DOCUMENTS:
        - Acquisition Documents: \(docCount)
        - Uploaded Files: \(uploadCount)
        - Generated Files: \(generatedCount)
        """

        return content
    }

    // Generate text content for Message Cards
    static func generateMessageCardText(title: String, content: String, cardType: String) -> String {
        """
        \(cardType) Report
        Generated: \(Date().formatted())

        \(title.uppercased()):

        \(content)
        """
    }

    // Generate text content for Document Chain
    static func generateDocumentChainText(_ chain: DocumentChainProgress) -> String {
        var content = """
        Document Chain Report
        Generated: \(Date().formatted())

        CHAIN ID: \(chain.id.uuidString)
        ACQUISITION ID: \(chain.acquisitionId.uuidString)
        CREATED: \(chain.createdAt.formatted())
        UPDATED: \(chain.updatedAt.formatted())

        PLANNED DOCUMENTS (\(chain.plannedDocuments.count) total):
        """

        for (index, docType) in chain.plannedDocuments.enumerated() {
            let status = chain.completedDocuments[docType] != nil ? "✓ Completed" : "○ Pending"
            content += "\n\(index + 1). \(docType.rawValue): \(status)"

            if let completedDoc = chain.completedDocuments[docType] {
                content += "\n   - Generated: \(completedDoc.createdAt.formatted())"
            }
        }

        content += "\n\nPROGRESS: \(chain.completedDocuments.count)/\(chain.plannedDocuments.count) documents completed"
        content += "\nCURRENT INDEX: \(chain.currentIndex)"

        return content
    }

    // Generate filename based on content type
    static func generateFileName(for type: DocumentShareType, date: Date = Date()) -> String {
        let dateString = date.formatted(.dateTime.year().month().day())

        switch type {
        case .acquisition:
            return "Acquisition_\(dateString)"
        case .template:
            return "Template_\(dateString)"
        case .samReport:
            return "SAM_Report_\(dateString)"
        case .documentChain:
            return "Document_Chain_\(dateString)"
        case .approvalRequest:
            return "Approval_Request_\(dateString)"
        case .messageCard:
            return "Report_\(dateString)"
        case let .generatedDocument(docType):
            return "\(docType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(dateString)"
        }
    }

    enum DocumentShareType {
        case acquisition
        case template
        case samReport
        case documentChain
        case approvalRequest
        case messageCard
        case generatedDocument(DocumentType)
    }
}

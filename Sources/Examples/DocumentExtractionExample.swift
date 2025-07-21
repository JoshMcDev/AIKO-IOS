import Foundation
import UniformTypeIdentifiers

// MARK: - Document Extraction Example

/// Example demonstrating how the document context extraction works
/// This shows the flow from raw document upload to extracted context
@MainActor
class DocumentExtractionExample {
    private let promptingEngine: AdaptivePromptingEngine

    init() {
        promptingEngine = AdaptivePromptingEngine()
    }

    /// Example: Process a vendor quote document
    func processVendorQuote() async throws {
        print("=== Document Context Extraction Example ===\n")

        // Simulate loading a PDF vendor quote
        guard let pdfData = loadSamplePDFData() else {
            print("Error: Could not load sample PDF data")
            return
        }

        // Step 1: Extract context from the document
        print("Step 1: Extracting context from vendor quote PDF...")

        let documentData = [(data: pdfData, type: UTType.pdf)]

        do {
            let extractedContext = try await promptingEngine.extractContextFromRawDocuments(
                documentData,
                withHints: [
                    "documentType": "vendor_quote",
                    "expectedFields": ["vendor", "price", "delivery_date"]
                ]
            )

            // Step 2: Display extracted information
            print("\nStep 2: Extracted Information:")
            print("=" * 40)

            if let vendorInfo = extractedContext.vendorInfo {
                print("\nVendor Information:")
                if let name = vendorInfo.name { print("  Name: \(name)") }
                if let email = vendorInfo.email { print("  Email: \(email)") }
                if let phone = vendorInfo.phone { print("  Phone: \(phone)") }
                if let uei = vendorInfo.uei { print("  UEI: \(uei)") }
                if let cage = vendorInfo.cage { print("  CAGE: \(cage)") }
            }

            if let pricing = extractedContext.pricing {
                print("\nPricing Information:")
                if let total = pricing.totalPrice {
                    print("  Total Price: $\(total)")
                }
                if !pricing.unitPrices.isEmpty {
                    print("  Line Items: \(pricing.unitPrices.count)")
                    for (index, item) in pricing.unitPrices.prefix(3).enumerated() {
                        print("    \(index + 1). \(item.description) - $\(item.totalPrice)")
                    }
                }
            }

            if let dates = extractedContext.dates {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium

                print("\nImportant Dates:")
                if let quoteDate = dates.quoteDate {
                    print("  Quote Date: \(formatter.string(from: quoteDate))")
                }
                if let validUntil = dates.validUntil {
                    print("  Valid Until: \(formatter.string(from: validUntil))")
                }
                if let deliveryDate = dates.deliveryDate {
                    print("  Delivery Date: \(formatter.string(from: deliveryDate))")
                }
            }

            if !extractedContext.technicalDetails.isEmpty {
                print("\nTechnical Details:")
                for (index, detail) in extractedContext.technicalDetails.prefix(3).enumerated() {
                    print("  \(index + 1). \(detail)")
                }
            }

            print("\nConfidence Scores:")
            for (field, confidence) in extractedContext.confidence {
                print("  \(field.rawValue): \(Int(confidence * 100))%")
            }

            // Step 3: Start conversation with extracted context
            print("\n\nStep 3: Starting adaptive conversation...")
            print("=" * 40)

            let conversationContext = ConversationContext(
                acquisitionType: .supplies,
                uploadedDocuments: documentData.compactMap { _ in
                    // In real implementation, this would be the parsed documents
                    nil
                },
                userProfile: nil,
                historicalData: []
            )

            let session = await promptingEngine.startConversation(with: conversationContext)

            print("\nConversation session started:")
            print("  Session ID: \(session.id)")
            print("  State: \(session.state)")
            print("  Questions prepared: \(session.remainingQuestions.count)")
            print("  Initial confidence: \(session.confidence)")

            if let firstQuestion = session.remainingQuestions.first {
                print("\nFirst question to ask:")
                print("  Field: \(firstQuestion.field.rawValue)")
                print("  Prompt: \(firstQuestion.prompt)")
                print("  Priority: \(firstQuestion.priority)")
            }

        } catch {
            print("Error extracting context: \(error)")
        }
    }

    /// Simulate loading PDF data (in real app, this would load from file)
    private func loadSamplePDFData() -> Data? {
        // In a real implementation, this would load actual PDF data
        // For now, return mock data
        "Mock PDF Data".data(using: .utf8)
    }
}

// MARK: - Usage Example

extension DocumentExtractionExample {
    /// Run the example
    static func runExample() async {
        let example = DocumentExtractionExample()

        do {
            try await example.processVendorQuote()
        } catch {
            print("Example failed: \(error)")
        }
    }
}

// Helper operator for string repetition
private func * (left: String, right: Int) -> String {
    String(repeating: left, count: right)
}

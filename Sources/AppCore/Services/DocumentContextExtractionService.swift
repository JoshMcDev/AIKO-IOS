import Foundation

// MARK: - Document Context Extraction Service

/// Protocol for document context extraction from OCR results
public protocol DocumentContextExtractionService: Sendable {
    func extractComprehensiveContext(
        from ocrResults: [OCRResult],
        pageImageData: [Data],
        withHints: [String: Any]?
    ) async throws -> ComprehensiveDocumentContext
}

// MARK: - Dependency Registration

public struct DocumentContextExtractionServiceKey {
    public static var liveValue: DocumentContextExtractionService {
        LiveDocumentContextExtractionService()
    }

    public static var testValue: DocumentContextExtractionService {
        MockDocumentContextExtractionService()
    }
}

// MARK: - Live Implementation

/// Live implementation that provides basic context extraction
/// Note: This is a basic implementation for AppCore. The full implementation
/// will be provided by the main AIKO module which has access to Services.
public final class LiveDocumentContextExtractionService: DocumentContextExtractionService, @unchecked Sendable {
    public init() {}

    public func extractComprehensiveContext(
        from ocrResults: [OCRResult],
        pageImageData _: [Data],
        withHints _: [String: Any]?
    ) async throws -> ComprehensiveDocumentContext {
        // Basic implementation - the full implementation will be provided by the main module
        // For now, create a basic context from the OCR results

        let fullText = ocrResults.map(\.fullText).joined(separator: "\n")
        let avgConfidence = ocrResults.isEmpty ? 0.0 : ocrResults.map(\.confidence).reduce(0, +) / Double(ocrResults.count)

        // Create a basic extracted context
        let basicContext = ExtractedContext(
            vendorInfo: APEVendorInfo(
                name: "Document Scanner",
                address: "",
                phone: "",
                email: ""
            ),
            pricing: PricingInfo(
                totalPrice: Decimal(0),
                lineItems: []
            ),
            technicalDetails: [fullText],
            dates: ExtractedDates(
                deliveryDate: nil,
                orderDate: Date()
            ),
            specialTerms: [],
            confidence: [:]
        )

        return ComprehensiveDocumentContext(
            extractedContext: basicContext,
            parsedDocuments: [],
            adaptiveResults: [],
            confidence: avgConfidence,
            extractionDate: Date()
        )
    }
}

// MARK: - Mock Implementation

public final class MockDocumentContextExtractionService: DocumentContextExtractionService, @unchecked Sendable {
    public init() {}

    public func extractComprehensiveContext(
        from _: [OCRResult],
        pageImageData _: [Data],
        withHints _: [String: Any]?
    ) async throws -> ComprehensiveDocumentContext {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let mockContext = ExtractedContext(
            vendorInfo: APEVendorInfo(
                name: "Mock Vendor Inc.",
                address: "123 Test Street",
                phone: "(555) 123-4567",
                email: "vendor@mock.com"
            ),
            pricing: PricingInfo(
                totalPrice: Decimal(1000.50),
                lineItems: [
                    APELineItem(
                        description: "Mock Product",
                        quantity: 2,
                        unitPrice: Decimal(500.25),
                        totalPrice: Decimal(1000.50)
                    ),
                ]
            ),
            technicalDetails: ["High-quality mock product with test specifications"],
            dates: ExtractedDates(
                deliveryDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days from now
                orderDate: Date()
            ),
            specialTerms: ["NET 30", "FOB Destination"],
            confidence: [
                "overall": 0.85,
                "vendor": 0.9,
                "pricing": 0.8,
            ]
        )

        let mockParsedDoc = ParsedDocument(
            sourceType: .ocr,
            extractedText: "Mock extracted text from OCR",
            metadata: ParsedDocumentMetadata(
                fileName: "Mock Document",
                fileSize: 1024,
                pageCount: 1
            ),
            extractedData: ExtractedData(),
            confidence: 0.85
        )

        return ComprehensiveDocumentContext(
            extractedContext: mockContext,
            parsedDocuments: [mockParsedDoc],
            adaptiveResults: [],
            confidence: 0.85,
            extractionDate: Date()
        )
    }
}

// MARK: - Error Types

public enum DocumentExtractionError: LocalizedError, Sendable {
    case noDocumentsParsed
    case invalidOCRResults
    case extractionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noDocumentsParsed:
            "No documents could be parsed"
        case .invalidOCRResults:
            "Invalid OCR results provided"
        case let .extractionFailed(reason):
            "Document extraction failed: \(reason)"
        }
    }
}

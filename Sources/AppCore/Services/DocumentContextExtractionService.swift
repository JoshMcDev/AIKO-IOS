import Foundation
import ComposableArchitecture

// MARK: - Document Context Extraction Service

/// Protocol for document context extraction from OCR results
public protocol DocumentContextExtractionService {
    func extractComprehensiveContext(
        from ocrResults: [OCRResult],
        pageImageData: [Data],
        withHints: [String: Any]?
    ) async throws -> ComprehensiveDocumentContext
}

// MARK: - Dependency Registration

public struct DocumentContextExtractionServiceKey: DependencyKey {
    public static var liveValue: DocumentContextExtractionService {
        LiveDocumentContextExtractionService()
    }
    
    public static var testValue: DocumentContextExtractionService {
        MockDocumentContextExtractionService()
    }
}

extension DependencyValues {
    public var documentContextExtractor: DocumentContextExtractionService {
        get { self[DocumentContextExtractionServiceKey.self] }
        set { self[DocumentContextExtractionServiceKey.self] = newValue }
    }
}

// MARK: - Live Implementation

/// Live implementation that uses UnifiedDocumentContextExtractor from Services module
public class LiveDocumentContextExtractionService: DocumentContextExtractionService {
    public init() {}
    
    public func extractComprehensiveContext(
        from ocrResults: [OCRResult],
        pageImageData: [Data],
        withHints: [String: Any]?
    ) async throws -> ComprehensiveDocumentContext {
        // This will be implemented to call the actual UnifiedDocumentContextExtractor
        // For now, return a basic implementation
        
        guard !ocrResults.isEmpty else {
            throw DocumentExtractionError.noDocumentsParsed
        }
        
        // Extract basic context from OCR results
        let fullText = ocrResults.map { $0.fullText }.joined(separator: "\n")
        let avgConfidence = ocrResults.map { $0.confidence }.reduce(0, +) / Double(ocrResults.count)
        
        // Basic vendor extraction
        let vendorInfo = extractBasicVendorInfo(from: fullText)
        let pricing = extractBasicPricing(from: fullText)
        let dates = extractBasicDates(from: fullText)
        
        let extractedContext = ExtractedContext(
            vendorInfo: vendorInfo,
            pricing: pricing,
            technicalDetails: extractTechnicalDetails(from: fullText),
            dates: dates,
            specialTerms: extractSpecialTerms(from: fullText),
            confidence: [
                "overall": Float(avgConfidence),
                "vendor": Float(vendorInfo != nil ? 0.8 : 0.0),
                "pricing": Float(pricing != nil ? 0.8 : 0.0)
            ]
        )
        
        // Create basic parsed documents from OCR
        let parsedDocuments = ocrResults.enumerated().map { index, ocrResult in
            ParsedDocument(
                sourceType: .ocr,
                extractedText: ocrResult.fullText,
                metadata: ParsedDocumentMetadata(
                    fileName: "OCR Document \(index + 1)",
                    fileSize: ocrResult.fullText.data(using: .utf8)?.count ?? 0,
                    pageCount: 1
                ),
                extractedData: ExtractedData(),
                confidence: ocrResult.confidence
            )
        }
        
        return ComprehensiveDocumentContext(
            extractedContext: extractedContext,
            parsedDocuments: parsedDocuments,
            adaptiveResults: [],
            confidence: avgConfidence,
            extractionDate: Date()
        )
    }
    
    // MARK: - Basic Extraction Helpers
    
    private func extractBasicVendorInfo(from text: String) -> APEVendorInfo? {
        _ = text.components(separatedBy: .newlines)
        
        // Look for company patterns
        let companyPatterns = [
            #"(\b[A-Z][a-zA-Z\s&]+(?:Inc|Corp|LLC|Ltd|Corporation|Company|Co\.))"#,
            #"From:\s*([A-Za-z\s&]+)"#,
            #"Vendor:\s*([A-Za-z\s&]+)"#
        ]
        
        for pattern in companyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let vendorName = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if vendorName.count > 2 {
                    return APEVendorInfo(name: vendorName)
                }
            }
        }
        
        return nil
    }
    
    private func extractBasicPricing(from text: String) -> PricingInfo? {
        // Look for price patterns
        let pricePatterns = [
            #"\$\s*([\d,]+\.?\d*)"#,
            #"Total:\s*\$\s*([\d,]+\.?\d*)"#,
            #"Amount:\s*\$\s*([\d,]+\.?\d*)"#
        ]
        
        for pattern in pricePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let priceString = String(text[range]).replacingOccurrences(of: ",", with: "")
                if let price = Decimal(string: priceString) {
                    return PricingInfo(totalPrice: price)
                }
            }
        }
        
        return nil
    }
    
    private func extractBasicDates(from text: String) -> ExtractedDates? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // Look for date patterns
        let datePatterns = [
            #"(\d{1,2}/\d{1,2}/\d{4})"#,
            #"(\w+\s+\d{1,2},\s+\d{4})"#
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let dateString = String(text[range])
                if let date = dateFormatter.date(from: dateString) {
                    return ExtractedDates(deliveryDate: date)
                }
            }
        }
        
        return nil
    }
    
    private func extractTechnicalDetails(from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        return lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.count > 20 && trimmed.count < 200 &&
                   (trimmed.contains("specification") || 
                    trimmed.contains("requirement") ||
                    trimmed.contains("part number") ||
                    trimmed.contains("model"))
        }
    }
    
    private func extractSpecialTerms(from text: String) -> [String] {
        let specialTerms = [
            "FOB", "CIF", "NET 30", "NET 60", "warranty", "guarantee",
            "delivery", "shipping", "terms", "conditions"
        ]
        
        return specialTerms.filter { term in
            text.localizedCaseInsensitiveContains(term)
        }
    }
}

// MARK: - Mock Implementation

public class MockDocumentContextExtractionService: DocumentContextExtractionService {
    public init() {}
    
    public func extractComprehensiveContext(
        from ocrResults: [OCRResult],
        pageImageData: [Data],
        withHints: [String: Any]?
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
                    )
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
                "pricing": 0.8
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

public enum DocumentExtractionError: LocalizedError {
    case noDocumentsParsed
    case invalidOCRResults
    case extractionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noDocumentsParsed:
            return "No documents could be parsed"
        case .invalidOCRResults:
            return "Invalid OCR results provided"
        case .extractionFailed(let reason):
            return "Document extraction failed: \(reason)"
        }
    }
}
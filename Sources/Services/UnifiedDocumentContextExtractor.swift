import Foundation
import Vision
import UniformTypeIdentifiers

// MARK: - Unified Document Context Extractor

/// Unified service that orchestrates all document extraction components
/// for the Adaptive Prompting Engine
public class UnifiedDocumentContextExtractor {
    /// Shared instance for non-MainActor contexts
    @MainActor
    public static let shared = UnifiedDocumentContextExtractor()
    
    /// Non-MainActor shared instance for dependency injection
    public static let sharedNonMainActor = UnifiedDocumentContextExtractor(
        documentParser: DocumentParserEnhanced(),
        contextExtractor: DocumentContextExtractorEnhanced.shared,
        adaptiveExtractor: AdaptiveDataExtractor.shared
    )
    
    private let documentParser: DocumentParserEnhanced
    private let contextExtractor: DocumentContextExtractorEnhanced
    private let adaptiveExtractor: AdaptiveDataExtractor
    
    @MainActor
    public init() {
        self.documentParser = DocumentParserEnhanced()
        self.contextExtractor = DocumentContextExtractorEnhanced()
        self.adaptiveExtractor = AdaptiveDataExtractor()
    }
    
    public init(
        documentParser: DocumentParserEnhanced,
        contextExtractor: DocumentContextExtractorEnhanced,
        adaptiveExtractor: AdaptiveDataExtractor
    ) {
        self.documentParser = documentParser
        self.contextExtractor = contextExtractor
        self.adaptiveExtractor = adaptiveExtractor
    }
    
    /// Main entry point for document context extraction
    /// Handles everything from raw document data to structured context
    public func extractComprehensiveContext(
        from documentData: [(data: Data, type: UTType)],
        withHints: [String: Any]? = nil
    ) async throws -> ComprehensiveDocumentContext {
        
        // Step 1: Parse all documents (OCR if needed)
        var parsedDocuments: [ParsedDocument] = []
        
        for (data, type) in documentData {
            do {
                let docType = mapUTTypeToDocumentType(type)
                let parsed = try await documentParser.parse(data, type: docType)
                parsedDocuments.append(parsed)
            } catch {
                print("Warning: Failed to parse document: \(error)")
                // Continue with other documents
            }
        }
        
        guard !parsedDocuments.isEmpty else {
            throw DocumentExtractionError.noDocumentsParsed
        }
        
        // Step 2: Extract context using both standard and adaptive extraction
        let extractedContext = try await contextExtractor.extract(from: parsedDocuments)
        
        // Step 3: Apply adaptive learning for better pattern recognition
        var adaptiveResults: [AdaptiveExtractionResult] = []
        
        for document in parsedDocuments {
            let adaptiveResult = try await adaptiveExtractor.extractAdaptively(
                from: document,
                withHints: withHints
            )
            adaptiveResults.append(adaptiveResult)
        }
        
        // Step 4: Merge and consolidate all extraction results
        let consolidatedContext = consolidateResults(
            standardContext: extractedContext,
            adaptiveResults: adaptiveResults,
            parsedDocuments: parsedDocuments
        )
        
        // Step 5: Calculate overall confidence
        let confidence = calculateOverallConfidence(
            context: consolidatedContext,
            adaptiveResults: adaptiveResults
        )
        
        return ComprehensiveDocumentContext(
            extractedContext: consolidatedContext,
            parsedDocuments: parsedDocuments,
            adaptiveResults: adaptiveResults,
            confidence: confidence,
            extractionDate: Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func mapUTTypeToDocumentType(_ type: UTType) -> ParsedDocumentType {
        switch type {
        case .pdf:
            return .pdf
        case .rtf:
            return .rtf
        case .plainText:
            return .text
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .heic:
            return .heic
        default:
            if type.conforms(to: .image) {
                return .unknown // Will use OCR
            } else if isWordDocument(type) {
                return .word
            } else {
                return .unknown
            }
        }
    }
    
    private func isWordDocument(_ type: UTType) -> Bool {
        let wordTypes = [
            "com.microsoft.word.doc",
            "com.microsoft.word.docx",
            "org.openxmlformats.wordprocessingml.document"
        ]
        return wordTypes.contains(type.identifier)
    }
    
    private func consolidateResults(
        standardContext: ExtractedContext,
        adaptiveResults: [AdaptiveExtractionResult],
        parsedDocuments: [ParsedDocument]
    ) -> ExtractedContext {
        
        // Start with standard extraction results
        var consolidatedVendorInfo = standardContext.vendorInfo
        var consolidatedPricing = standardContext.pricing
        var consolidatedDates = standardContext.dates
        var consolidatedTechnicalDetails = standardContext.technicalDetails
        var consolidatedSpecialTerms = standardContext.specialTerms
        var consolidatedConfidence = standardContext.confidence
        
        // Enhance with adaptive extraction results
        for result in adaptiveResults {
            // Update vendor info with higher confidence values
            if let vendorInfo = extractVendorInfoFromAdaptive(result) {
                consolidatedVendorInfo = mergeVendorInfo(
                    existing: consolidatedVendorInfo,
                    new: vendorInfo,
                    confidence: result.confidence
                )
            }
            
            // Update pricing with more detailed line items
            if let pricing = extractPricingFromAdaptive(result) {
                consolidatedPricing = mergePricing(
                    existing: consolidatedPricing,
                    new: pricing,
                    confidence: result.confidence
                )
            }
            
            // Update dates with better pattern recognition
            if let dates = extractDatesFromAdaptive(result) {
                consolidatedDates = mergeDates(
                    existing: consolidatedDates,
                    new: dates,
                    confidence: result.confidence
                )
            }
            
            // Add technical details from adaptive extraction
            let technicalDetails = extractTechnicalDetailsFromAdaptive(result)
            consolidatedTechnicalDetails.append(contentsOf: technicalDetails)
            
            // Add special terms from adaptive extraction
            let specialTerms = extractSpecialTermsFromAdaptive(result)
            consolidatedSpecialTerms.append(contentsOf: specialTerms)
            
            // Update confidence scores
            updateConfidenceScores(
                &consolidatedConfidence,
                from: result
            )
        }
        
        // Remove duplicates and clean up
        consolidatedTechnicalDetails = Array(Set(consolidatedTechnicalDetails))
            .filter { !$0.isEmpty && $0.count > 10 }
        consolidatedSpecialTerms = Array(Set(consolidatedSpecialTerms))
        
        return ExtractedContext(
            vendorInfo: consolidatedVendorInfo,
            pricing: consolidatedPricing,
            technicalDetails: consolidatedTechnicalDetails,
            dates: consolidatedDates,
            specialTerms: consolidatedSpecialTerms,
            confidence: consolidatedConfidence
        )
    }
    
    private func extractVendorInfoFromAdaptive(_ result: AdaptiveExtractionResult) -> APEVendorInfo? {
        var vendorInfo = APEVendorInfo()
        var hasData = false
        
        for object in result.valueObjects {
            switch object.fieldName.lowercased() {
            case "vendor", "vendor_name", "company":
                vendorInfo.name = object.value
                hasData = true
            case "vendor_email", "email":
                vendorInfo.email = object.value
                hasData = true
            case "vendor_phone", "phone":
                vendorInfo.phone = object.value
                hasData = true
            case "vendor_address", "address":
                vendorInfo.address = object.value
                hasData = true
            case "uei", "vendor_uei":
                vendorInfo.uei = object.value
                hasData = true
            case "cage", "vendor_cage":
                vendorInfo.cage = object.value
                hasData = true
            default:
                break
            }
        }
        
        return hasData ? vendorInfo : nil
    }
    
    private func extractPricingFromAdaptive(_ result: AdaptiveExtractionResult) -> PricingInfo? {
        var totalPrice: Decimal?
        var lineItems: [APELineItem] = []
        
        for object in result.valueObjects {
            if object.dataType == .currency {
                if object.fieldName.lowercased().contains("total") {
                    totalPrice = Decimal(string: object.value.replacingOccurrences(of: "$", with: "")
                        .replacingOccurrences(of: ",", with: ""))
                } else {
                    // Might be a line item price
                    if let price = Decimal(string: object.value.replacingOccurrences(of: "$", with: "")
                        .replacingOccurrences(of: ",", with: "")) {
                        lineItems.append(APELineItem(
                            description: object.fieldName,
                            quantity: 1,
                            unitPrice: price,
                            totalPrice: price
                        ))
                    }
                }
            }
        }
        
        if totalPrice != nil || !lineItems.isEmpty {
            return PricingInfo(totalPrice: totalPrice, unitPrices: lineItems)
        }
        
        return nil
    }
    
    private func extractDatesFromAdaptive(_ result: AdaptiveExtractionResult) -> ExtractedDates? {
        var dates = ExtractedDates()
        var hasData = false
        
        for object in result.valueObjects {
            if object.dataType == .date {
                if let date = parseDate(object.value) {
                    switch object.fieldName.lowercased() {
                    case "quote_date", "date":
                        dates.quoteDate = date
                        hasData = true
                    case "valid_until", "expiration":
                        dates.validUntil = date
                        hasData = true
                    case "delivery_date", "due_date":
                        dates.deliveryDate = date
                        hasData = true
                    default:
                        break
                    }
                }
            }
        }
        
        return hasData ? dates : nil
    }
    
    private func extractTechnicalDetailsFromAdaptive(_ result: AdaptiveExtractionResult) -> [String] {
        return result.valueObjects
            .filter { $0.fieldName.lowercased().contains("technical") ||
                     $0.fieldName.lowercased().contains("specification") ||
                     $0.fieldName.lowercased().contains("feature") }
            .map { $0.value }
            .filter { $0.count > 20 }
    }
    
    private func extractSpecialTermsFromAdaptive(_ result: AdaptiveExtractionResult) -> [String] {
        return result.valueObjects
            .filter { $0.fieldName.lowercased().contains("term") ||
                     $0.fieldName.lowercased().contains("condition") ||
                     $0.fieldName.lowercased().contains("requirement") }
            .map { $0.value }
    }
    
    private func mergeVendorInfo(
        existing: APEVendorInfo?,
        new: APEVendorInfo,
        confidence: Double
    ) -> APEVendorInfo {
        guard let existing = existing else { return new }
        guard confidence > 0.8 else { return existing } // Only merge if high confidence
        
        return APEVendorInfo(
            name: new.name ?? existing.name,
            uei: new.uei ?? existing.uei,
            cage: new.cage ?? existing.cage,
            email: new.email ?? existing.email,
            phone: new.phone ?? existing.phone,
            address: new.address ?? existing.address
        )
    }
    
    private func mergePricing(
        existing: PricingInfo?,
        new: PricingInfo,
        confidence: Double
    ) -> PricingInfo {
        guard let existing = existing else { return new }
        guard confidence > 0.7 else { return existing }
        
        return PricingInfo(
            totalPrice: new.totalPrice ?? existing.totalPrice,
            unitPrices: existing.unitPrices + new.unitPrices,
            currency: new.currency
        )
    }
    
    private func mergeDates(
        existing: ExtractedDates?,
        new: ExtractedDates,
        confidence: Double
    ) -> ExtractedDates {
        guard let existing = existing else { return new }
        guard confidence > 0.7 else { return existing }
        
        return ExtractedDates(
            quoteDate: new.quoteDate ?? existing.quoteDate,
            validUntil: new.validUntil ?? existing.validUntil,
            deliveryDate: new.deliveryDate ?? existing.deliveryDate,
            performancePeriod: new.performancePeriod ?? existing.performancePeriod
        )
    }
    
    private func updateConfidenceScores(
        _ confidence: inout [RequirementField: Float],
        from result: AdaptiveExtractionResult
    ) {
        // Map adaptive fields to requirement fields
        let fieldMappings: [(pattern: String, field: RequirementField)] = [
            ("vendor", .vendorName),
            ("uei", .vendorUEI),
            ("cage", .vendorCAGE),
            ("price", .estimatedValue),
            ("date", .requiredDate),
            ("technical", .technicalSpecs),
            ("special", .specialConditions)
        ]
        
        for object in result.valueObjects {
            for (pattern, field) in fieldMappings {
                if object.fieldName.lowercased().contains(pattern) {
                    let currentConfidence = confidence[field] ?? 0
                    confidence[field] = max(currentConfidence, Float(object.confidence))
                }
            }
        }
    }
    
    private func calculateOverallConfidence(
        context: ExtractedContext,
        adaptiveResults: [AdaptiveExtractionResult]
    ) -> Double {
        var scores: [Double] = []
        
        // Add confidence from standard extraction
        scores.append(contentsOf: context.confidence.values.map { Double($0) })
        
        // Add confidence from adaptive extraction
        scores.append(contentsOf: adaptiveResults.map { $0.confidence })
        
        // Calculate weighted average
        guard !scores.isEmpty else { return 0.0 }
        let average = scores.reduce(0.0, +) / Double(scores.count)
        
        // Boost confidence if we have multiple extraction methods agreeing
        let agreementBonus = adaptiveResults.isEmpty ? 0.0 : 0.1
        
        return min(average + agreementBonus, 1.0)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            ISO8601DateFormatter(),
            DateFormatter.mmddyyyy,
            DateFormatter.yyyymmdd,
            DateFormatter.mmmddyyyy
        ]
        
        // Try ISO8601 first
        if let iso = formatters.first as? ISO8601DateFormatter,
           let date = iso.date(from: dateString) {
            return date
        }
        
        // Try other formatters
        for formatter in formatters.dropFirst() {
            if let formatter = formatter as? DateFormatter,
               let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types

public struct ComprehensiveDocumentContext {
    public let extractedContext: ExtractedContext
    public let parsedDocuments: [ParsedDocument]
    public let adaptiveResults: [AdaptiveExtractionResult]
    public let confidence: Double
    public let extractionDate: Date
    
    /// Check if we have sufficient context to proceed
    public var hasSufficientContext: Bool {
        confidence > 0.6 && !extractedContext.isEmpty
    }
    
    /// Get a summary of what was extracted
    public var summary: String {
        var parts: [String] = []
        
        if let vendor = extractedContext.vendorInfo?.name {
            parts.append("Vendor: \(vendor)")
        }
        
        if let price = extractedContext.pricing?.totalPrice {
            parts.append("Price: $\(price)")
        }
        
        if let date = extractedContext.dates?.deliveryDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append("Delivery: \(formatter.string(from: date))")
        }
        
        parts.append("Technical specs: \(extractedContext.technicalDetails.count)")
        parts.append("Confidence: \(Int(confidence * 100))%")
        
        return parts.joined(separator: " | ")
    }
}

extension ExtractedContext {
    var isEmpty: Bool {
        vendorInfo == nil &&
        pricing == nil &&
        technicalDetails.isEmpty &&
        dates == nil &&
        specialTerms.isEmpty
    }
}

public enum DocumentExtractionError: LocalizedError {
    case noDocumentsParsed
    case insufficientContext
    case extractionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noDocumentsParsed:
            return "No documents could be parsed successfully"
        case .insufficientContext:
            return "Insufficient context extracted from documents"
        case .extractionFailed(let reason):
            return "Document extraction failed: \(reason)"
        }
    }
}

// DateFormatter extensions are already defined in DocumentContextExtractorEnhanced.swift
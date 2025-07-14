import Foundation

// MARK: - Enhanced Document Context Extractor

/// Enhanced version that integrates with AdaptiveDataExtractor for better pattern learning
@MainActor
public class DocumentContextExtractorEnhanced {
    private let adaptiveExtractor: AdaptiveDataExtractor
    private let baseExtractor: DocumentContextExtractor
    
    public init() {
        self.adaptiveExtractor = AdaptiveDataExtractor()
        self.baseExtractor = DocumentContextExtractor()
    }
    
    public func extract(from documents: [ParsedDocument]) async throws -> ExtractedContext {
        // First use the base extractor
        let baseContext = try await baseExtractor.extract(from: documents)
        
        // Then enhance with adaptive extraction
        var enhancedVendorInfo = baseContext.vendorInfo
        var enhancedPricing = baseContext.pricing
        var enhancedTechnicalDetails = baseContext.technicalDetails
        var enhancedDates = baseContext.dates
        var enhancedSpecialTerms = baseContext.specialTerms
        var enhancedConfidence = baseContext.confidence
        
        // Process each document with adaptive extraction
        for document in documents {
            let adaptiveResult = try await adaptiveExtractor.extractAdaptively(from: document)
            
            // Enhance vendor info
            if enhancedVendorInfo == nil || needsEnhancement(baseContext.confidence[.vendorName]) {
                if let vendorInfo = extractEnhancedVendorInfo(from: adaptiveResult) {
                    enhancedVendorInfo = mergeVendorInfo(enhancedVendorInfo, vendorInfo)
                    updateConfidence(&enhancedConfidence, from: adaptiveResult, for: [.vendorName, .vendorUEI, .vendorCAGE])
                }
            }
            
            // Enhance pricing
            if enhancedPricing == nil || needsEnhancement(baseContext.confidence[.estimatedValue]) {
                if let pricing = extractEnhancedPricing(from: adaptiveResult) {
                    enhancedPricing = mergePricing(enhancedPricing, pricing)
                    updateConfidence(&enhancedConfidence, from: adaptiveResult, for: [.estimatedValue])
                }
            }
            
            // Enhance dates
            if enhancedDates == nil || needsEnhancement(baseContext.confidence[.requiredDate]) {
                if let dates = extractEnhancedDates(from: adaptiveResult) {
                    enhancedDates = mergeDates(enhancedDates, dates)
                    updateConfidence(&enhancedConfidence, from: adaptiveResult, for: [.requiredDate])
                }
            }
            
            // Enhance technical details
            let technicalDetails = extractEnhancedTechnicalDetails(from: adaptiveResult)
            enhancedTechnicalDetails.append(contentsOf: technicalDetails)
            
            // Enhance special terms
            let specialTerms = extractEnhancedSpecialTerms(from: adaptiveResult)
            enhancedSpecialTerms.append(contentsOf: specialTerms)
        }
        
        // Remove duplicates and clean up
        enhancedTechnicalDetails = Array(Set(enhancedTechnicalDetails))
            .filter { !$0.isEmpty && $0.count > 10 }
        enhancedSpecialTerms = Array(Set(enhancedSpecialTerms))
        
        return ExtractedContext(
            vendorInfo: enhancedVendorInfo,
            pricing: enhancedPricing,
            technicalDetails: enhancedTechnicalDetails,
            dates: enhancedDates,
            specialTerms: enhancedSpecialTerms,
            confidence: enhancedConfidence
        )
    }
    
    // MARK: - Private Enhancement Methods
    
    private func needsEnhancement(_ confidence: Float?) -> Bool {
        (confidence ?? 0) < 0.85
    }
    
    private func extractEnhancedVendorInfo(from result: AdaptiveExtractionResult) -> APEVendorInfo? {
        var vendorInfo = APEVendorInfo()
        var hasData = false
        
        // Map adaptive extraction fields to vendor info
        let vendorMappings: [(patterns: [String], target: WritableKeyPath<APEVendorInfo, String?>)] = [
            (["vendor", "vendor_name", "company", "supplier"], \APEVendorInfo.name),
            (["vendor_email", "email", "contact_email"], \APEVendorInfo.email),
            (["vendor_phone", "phone", "contact_phone", "telephone"], \APEVendorInfo.phone),
            (["vendor_address", "address", "location"], \APEVendorInfo.address),
            (["uei", "sam_uei"], \APEVendorInfo.uei),
            (["cage", "cage_code"], \APEVendorInfo.cage)
        ]
        
        for (patterns, keyPath) in vendorMappings {
            if let value = findValueForPatterns(patterns, in: result.valueObjects) {
                vendorInfo[keyPath: keyPath] = value
                hasData = true
            }
        }
        
        return hasData ? vendorInfo : nil
    }
    
    private func extractEnhancedPricing(from result: AdaptiveExtractionResult) -> PricingInfo? {
        var totalPrice: Decimal?
        var lineItems: [APELineItem] = []
        
        // Look for total price
        let pricingPatterns = ["total_price", "total", "grand_total", "total_cost", "amount"]
        if let priceValue = findValueForPatterns(pricingPatterns, in: result.valueObjects, dataType: DynamicValueObject.DataType.currency) {
            totalPrice = Decimal(string: priceValue.replacingOccurrences(of: ",", with: ""))
        }
        
        // Extract line items
        let itemGroups = groupRelatedLineItems(from: result.valueObjects)
        for group in itemGroups {
            if let lineItem = createLineItem(from: group) {
                lineItems.append(lineItem)
            }
        }
        
        if totalPrice != nil || !lineItems.isEmpty {
            return PricingInfo(totalPrice: totalPrice, unitPrices: lineItems)
        }
        
        return nil
    }
    
    private func extractEnhancedDates(from result: AdaptiveExtractionResult) -> ExtractedDates? {
        var dates = ExtractedDates()
        var hasData = false
        
        let dateMappings: [(patterns: [String], handler: (Date) -> Void)] = [
            (["quote_date", "estimate_date", "date"], { dates.quoteDate = $0; hasData = true }),
            (["valid_until", "expires", "expiration", "validity"], { dates.validUntil = $0; hasData = true }),
            (["delivery_date", "required_date", "due_date", "need_by"], { dates.deliveryDate = $0; hasData = true })
        ]
        
        for (patterns, handler) in dateMappings {
            if let dateValue = findValueForPatterns(patterns, in: result.valueObjects, dataType: DynamicValueObject.DataType.date) {
                if let date = parseDate(dateValue) {
                    handler(date)
                }
            }
        }
        
        // Handle ARO (Awaiting Receipt of Order) days
        if let aroValue = findValueForPatterns(["aro", "aro_days", "lead_time"], in: result.valueObjects, dataType: DynamicValueObject.DataType.number) {
            if let aroDays = Int(aroValue) {
                dates.deliveryDate = Calendar.current.date(byAdding: .day, value: aroDays, to: Date())
                hasData = true
            }
        }
        
        return hasData ? dates : nil
    }
    
    private func extractEnhancedTechnicalDetails(from result: AdaptiveExtractionResult) -> [String] {
        var details: [String] = []
        
        // Technical field patterns
        let technicalPatterns = [
            "technical_features", "features", "specifications", "specs",
            "requirements", "capabilities", "description", "details"
        ]
        
        for object in result.valueObjects {
            let fieldName = object.fieldName.lowercased()
            if technicalPatterns.contains(where: { fieldName.contains($0) }) {
                if object.dataType == .array {
                    // Handle array of features
                    if let arrayData = object.value.data(using: .utf8),
                       let features = try? JSONDecoder().decode([String].self, from: arrayData) {
                        details.append(contentsOf: features)
                    }
                } else if object.dataType == .text && object.value.count > 20 {
                    // Add text descriptions
                    details.append(object.value)
                }
            }
        }
        
        return details
    }
    
    private func extractEnhancedSpecialTerms(from result: AdaptiveExtractionResult) -> [String] {
        var terms: [String] = []
        
        // Look for government/compliance related fields
        let specialPatterns = [
            "haipe_compatible", "security_clearance", "compliance",
            "certifications", "special_requirements", "notes"
        ]
        
        for object in result.valueObjects {
            let fieldName = object.fieldName.lowercased()
            if specialPatterns.contains(where: { fieldName.contains($0) }) {
                if object.dataType == .boolean && object.value.lowercased() == "true" {
                    terms.append(fieldName.replacingOccurrences(of: "_", with: " ").capitalized)
                } else if object.dataType == .text {
                    terms.append(object.value)
                }
            }
        }
        
        // Also check document signature for special terms
        if result.documentSignature.contains("government") {
            terms.append("Government Acquisition")
        }
        if result.documentSignature.contains("classified") || result.documentSignature.contains("security") {
            terms.append("Security Requirements")
        }
        
        return terms
    }
    
    // MARK: - Helper Methods
    
    private func findValueForPatterns(_ patterns: [String], in objects: [DynamicValueObject], dataType: DynamicValueObject.DataType? = nil) -> String? {
        for pattern in patterns {
            if let object = objects.first(where: { 
                $0.fieldName.lowercased() == pattern && 
                (dataType == nil || $0.dataType == dataType)
            }) {
                return object.value
            }
        }
        return nil
    }
    
    private func groupRelatedLineItems(from objects: [DynamicValueObject]) -> [[DynamicValueObject]] {
        var groups: [[DynamicValueObject]] = []
        
        // Find all quantity objects as anchors
        let quantityObjects = objects.filter { 
            $0.fieldName.lowercased().contains("quantity") || 
            $0.fieldName.lowercased().contains("qty")
        }
        
        for qtyObject in quantityObjects {
            var group = [qtyObject]
            
            // Find related price and description
            if let priceObject = objects.first(where: { 
                $0.dataType == DynamicValueObject.DataType.currency && 
                isRelated($0, to: qtyObject)
            }) {
                group.append(priceObject)
            }
            
            if let descObject = objects.first(where: { 
                $0.dataType == .text && 
                ($0.fieldName.contains("product") || $0.fieldName.contains("item")) &&
                isRelated($0, to: qtyObject)
            }) {
                group.append(descObject)
            }
            
            if group.count >= 2 {
                groups.append(group)
            }
        }
        
        return groups
    }
    
    private func isRelated(_ object1: DynamicValueObject, to object2: DynamicValueObject) -> Bool {
        // Simple heuristic: objects are related if they have similar context
        // In a real implementation, this could use more sophisticated matching
        return true
    }
    
    private func createLineItem(from group: [DynamicValueObject]) -> APELineItem? {
        var quantity: Int?
        var unitPrice: Decimal?
        var description: String?
        
        for object in group {
            switch object.dataType {
            case .number:
                if object.fieldName.lowercased().contains("qty") || object.fieldName.lowercased().contains("quantity") {
                    quantity = Int(object.value)
                }
            case .currency:
                unitPrice = Decimal(string: object.value.replacingOccurrences(of: ",", with: ""))
            case .text:
                if object.fieldName.contains("product") || object.fieldName.contains("item") {
                    description = object.value
                }
            default:
                break
            }
        }
        
        if let qty = quantity, let price = unitPrice {
            return APELineItem(
                description: description ?? "Item",
                quantity: qty,
                unitPrice: price,
                totalPrice: price * Decimal(qty)
            )
        }
        
        return nil
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try other date formats
        let formatters: [DateFormatter] = [
            DateFormatter.mmddyyyy,
            DateFormatter.yyyymmdd,
            DateFormatter.mmmddyyyy
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func mergeVendorInfo(_ existing: APEVendorInfo?, _ new: APEVendorInfo) -> APEVendorInfo {
        var merged = existing ?? APEVendorInfo()
        
        merged.name = merged.name ?? new.name
        merged.email = merged.email ?? new.email
        merged.phone = merged.phone ?? new.phone
        merged.address = merged.address ?? new.address
        merged.uei = merged.uei ?? new.uei
        merged.cage = merged.cage ?? new.cage
        
        return merged
    }
    
    private func mergePricing(_ existing: PricingInfo?, _ new: PricingInfo) -> PricingInfo {
        let merged = existing ?? PricingInfo()
        
        return PricingInfo(
            totalPrice: new.totalPrice ?? merged.totalPrice,
            unitPrices: merged.unitPrices + new.unitPrices,
            currency: new.currency
        )
    }
    
    private func mergeDates(_ existing: ExtractedDates?, _ new: ExtractedDates) -> ExtractedDates {
        let merged = existing ?? ExtractedDates()
        
        return ExtractedDates(
            quoteDate: new.quoteDate ?? merged.quoteDate,
            validUntil: new.validUntil ?? merged.validUntil,
            deliveryDate: new.deliveryDate ?? merged.deliveryDate,
            performancePeriod: new.performancePeriod ?? merged.performancePeriod
        )
    }
    
    private func updateConfidence(_ confidence: inout [RequirementField: Float], from result: AdaptiveExtractionResult, for fields: [RequirementField]) {
        for field in fields {
            let fieldPattern = fieldToPattern(field)
            if let object = result.valueObjects.first(where: { 
                $0.fieldName.lowercased().contains(fieldPattern) 
            }) {
                let currentConfidence = confidence[field] ?? 0
                confidence[field] = max(currentConfidence, Float(object.confidence))
            }
        }
    }
    
    private func fieldToPattern(_ field: RequirementField) -> String {
        switch field {
        case .vendorName: return "vendor"
        case .vendorUEI: return "uei"
        case .vendorCAGE: return "cage"
        case .estimatedValue: return "price"
        case .requiredDate: return "date"
        default: return field.rawValue
        }
    }
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    static let mmddyyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let yyyymmdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let mmmddyyyy: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
}
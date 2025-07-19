import Foundation

// MARK: - Document Context Types

/// Comprehensive document context extracted from multiple sources
public struct ComprehensiveDocumentContext: Equatable {
    public let extractedContext: ExtractedContext
    public let parsedDocuments: [ParsedDocument]
    public let adaptiveResults: [AdaptiveExtractionResult]
    public let confidence: Double
    public let extractionDate: Date
    
    public init(
        extractedContext: ExtractedContext,
        parsedDocuments: [ParsedDocument],
        adaptiveResults: [AdaptiveExtractionResult],
        confidence: Double,
        extractionDate: Date
    ) {
        self.extractedContext = extractedContext
        self.parsedDocuments = parsedDocuments
        self.adaptiveResults = adaptiveResults
        self.confidence = confidence
        self.extractionDate = extractionDate
    }
    
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
        parts.append("Confidence: \(Int(confidence * 100))%)")
        
        return parts.joined(separator: " | ")
    }
}

/// Extracted context from document analysis
public struct ExtractedContext: Equatable {
    public let vendorInfo: APEVendorInfo?
    public let pricing: PricingInfo?
    public let technicalDetails: [String]
    public let dates: ExtractedDates?
    public let specialTerms: [String]
    public let confidence: [String: Float]
    
    public init(
        vendorInfo: APEVendorInfo? = nil,
        pricing: PricingInfo? = nil,
        technicalDetails: [String] = [],
        dates: ExtractedDates? = nil,
        specialTerms: [String] = [],
        confidence: [String: Float] = [:]
    ) {
        self.vendorInfo = vendorInfo
        self.pricing = pricing
        self.technicalDetails = technicalDetails
        self.dates = dates
        self.specialTerms = specialTerms
        self.confidence = confidence
    }
    
    var isEmpty: Bool {
        vendorInfo == nil &&
        pricing == nil &&
        technicalDetails.isEmpty &&
        dates == nil &&
        specialTerms.isEmpty
    }
}

/// Adaptive Prompting Engine vendor information
public struct APEVendorInfo: Equatable {
    public var name: String?
    public var address: String?
    public var phone: String?
    public var email: String?
    public var cage: String?
    public var uei: String?
    
    public init(
        name: String? = nil,
        address: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        cage: String? = nil,
        uei: String? = nil
    ) {
        self.name = name
        self.address = address
        self.phone = phone
        self.email = email
        self.cage = cage
        self.uei = uei
    }
}

/// Pricing information extracted from documents
public struct PricingInfo: Equatable {
    public let totalPrice: Decimal?
    public let lineItems: [APELineItem]
    
    public init(totalPrice: Decimal?, lineItems: [APELineItem] = []) {
        self.totalPrice = totalPrice
        self.lineItems = lineItems
    }
}

/// Line item for pricing breakdown
public struct APELineItem: Equatable {
    public let description: String
    public let quantity: Int
    public let unitPrice: Decimal
    public let totalPrice: Decimal
    
    public init(description: String, quantity: Int, unitPrice: Decimal, totalPrice: Decimal) {
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
    }
}

/// Extracted dates from documents
public struct ExtractedDates: Equatable {
    public let deliveryDate: Date?
    public let orderDate: Date?
    public let dueDate: Date?
    
    public init(deliveryDate: Date? = nil, orderDate: Date? = nil, dueDate: Date? = nil) {
        self.deliveryDate = deliveryDate
        self.orderDate = orderDate
        self.dueDate = dueDate
    }
}

/// Adaptive extraction result
public struct AdaptiveExtractionResult: Equatable {
    public let confidence: Double
    public let valueObjects: [ValueObject]
    public let patterns: [String]
    public let metadata: [String: String]
    
    public init(confidence: Double, valueObjects: [ValueObject], patterns: [String], metadata: [String: String] = [:]) {
        self.confidence = confidence
        self.valueObjects = valueObjects
        self.patterns = patterns
        self.metadata = metadata
    }
    
    public static func == (lhs: AdaptiveExtractionResult, rhs: AdaptiveExtractionResult) -> Bool {
        return lhs.confidence == rhs.confidence &&
               lhs.valueObjects == rhs.valueObjects &&
               lhs.patterns == rhs.patterns &&
               lhs.metadata == rhs.metadata
    }
}

/// Value object from adaptive extraction
public struct ValueObject: Equatable {
    public let fieldName: String
    public let value: String
    public let confidence: Double
    public let source: String
    
    public init(fieldName: String, value: String, confidence: Double, source: String) {
        self.fieldName = fieldName
        self.value = value
        self.confidence = confidence
        self.source = source
    }
}
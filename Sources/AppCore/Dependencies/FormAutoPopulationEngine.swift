import Foundation

// MARK: - Form Auto-Population Engine

/// Intelligent engine for extracting and mapping form data from scanned documents
public struct FormAutoPopulationEngine: Sendable {
    /// Extracts form data from a scanned document and maps to known form types
    public var extractFormData: @Sendable (ScannedDocument) async throws -> FormAutoPopulationResult

    /// Validates extracted data against form field requirements
    public var validateFormData: @Sendable (GovernmentFormData, FormType) async throws -> ValidationResult

    /// Gets supported form types for auto-population
    public var getSupportedFormTypes: @Sendable () -> [FormType] = { [] }

    /// Estimates confidence for auto-population success
    public var estimatePopulationConfidence: @Sendable (ScannedDocument) async throws -> Double
}

// MARK: - Form Auto-Population Result

/// Result of form auto-population processing
public struct FormAutoPopulationResult: Equatable, Sendable {
    public let extractedData: GovernmentFormData
    public let suggestedFormType: FormType?
    public let confidence: Double
    public let populatedFields: [ExtractedPopulatedField]
    public let processingTime: TimeInterval
    public let warnings: [String]

    public init(
        extractedData: GovernmentFormData,
        suggestedFormType: FormType? = nil,
        confidence: Double,
        populatedFields: [ExtractedPopulatedField] = [],
        processingTime: TimeInterval = 0,
        warnings: [String] = []
    ) {
        self.extractedData = extractedData
        self.suggestedFormType = suggestedFormType
        self.confidence = confidence
        self.populatedFields = populatedFields
        self.processingTime = processingTime
        self.warnings = warnings
    }

    /// Returns true if auto-population is recommended based on confidence
    public var isRecommendedForAutoPopulation: Bool {
        confidence >= 0.85 && populatedFields.count >= 3
    }

    /// Returns high-confidence fields suitable for auto-population
    public var highConfidenceFields: [ExtractedPopulatedField] {
        populatedFields.filter { $0.confidence >= 0.9 }
    }
}

// MARK: - Extracted Form Data

/// Comprehensive government form data extracted from scanned documents
public struct GovernmentFormData: Equatable, Sendable {
    public let vendorInfo: VendorInfo?
    public let contractInfo: ContractInfo?
    public let dates: [ExtractedDate]
    public let amounts: [ExtractedCurrency]
    public let addresses: [ExtractedAddress]
    public let contacts: [ContactInfo]
    public let lineItems: [LineItem]
    public let certifications: [CertificationInfo]
    public let metadata: [String: String]

    public init(
        vendorInfo: VendorInfo? = nil,
        contractInfo: ContractInfo? = nil,
        dates: [ExtractedDate] = [],
        amounts: [ExtractedCurrency] = [],
        addresses: [ExtractedAddress] = [],
        contacts: [ContactInfo] = [],
        lineItems: [LineItem] = [],
        certifications: [CertificationInfo] = [],
        metadata: [String: String] = [:]
    ) {
        self.vendorInfo = vendorInfo
        self.contractInfo = contractInfo
        self.dates = dates
        self.amounts = amounts
        self.addresses = addresses
        self.contacts = contacts
        self.lineItems = lineItems
        self.certifications = certifications
        self.metadata = metadata
    }
}

// MARK: - Vendor Information

/// Vendor information extracted from documents
public struct VendorInfo: Equatable, Sendable {
    public let name: String
    public let duns: String?
    public let cage: String?
    public let address: ExtractedAddress?
    public let phoneNumber: String?
    public let emailAddress: String?
    public let website: String?
    public let businessType: BusinessType?
    public let socioeconomicCategories: [SocioeconomicCategory]

    public init(
        name: String,
        duns: String? = nil,
        cage: String? = nil,
        address: ExtractedAddress? = nil,
        phoneNumber: String? = nil,
        emailAddress: String? = nil,
        website: String? = nil,
        businessType: BusinessType? = nil,
        socioeconomicCategories: [SocioeconomicCategory] = []
    ) {
        self.name = name
        self.duns = duns
        self.cage = cage
        self.address = address
        self.phoneNumber = phoneNumber
        self.emailAddress = emailAddress
        self.website = website
        self.businessType = businessType
        self.socioeconomicCategories = socioeconomicCategories
    }

    public enum BusinessType: String, CaseIterable, Sendable {
        case smallBusiness = "Small Business"
        case largeBusiness = "Large Business"
        case womanOwned = "Woman-Owned Small Business"
        case veteranOwned = "Veteran-Owned Small Business"
        case serviceDisabled = "Service-Disabled Veteran-Owned Small Business"
        case hubZone = "HUBZone Small Business"
        case eightA = "8(a) Small Business"
        case unknown = "Unknown"
    }

    public enum SocioeconomicCategory: String, CaseIterable, Sendable {
        case wosb = "WOSB"
        case edwosb = "EDWOSB"
        case vosb = "VOSB"
        case sdvosb = "SDVOSB"
        case hubzone = "HUBZone"
        case sdb = "SDB"
        case eightA = "8(a)"
    }
}

// MARK: - Contract Information

/// Contract-related information extracted from documents
public struct ContractInfo: Equatable, Sendable {
    public let contractNumber: String?
    public let solicitation: String?
    public let naicsCode: String?
    public let psc: String?
    public let performancePeriod: DateInterval?
    public let placeOfPerformance: ExtractedAddress?
    public let contractType: ContractType?
    public let competitionType: CompetitionType?

    public init(
        contractNumber: String? = nil,
        solicitation: String? = nil,
        naicsCode: String? = nil,
        psc: String? = nil,
        performancePeriod: DateInterval? = nil,
        placeOfPerformance: ExtractedAddress? = nil,
        contractType: ContractType? = nil,
        competitionType: CompetitionType? = nil
    ) {
        self.contractNumber = contractNumber
        self.solicitation = solicitation
        self.naicsCode = naicsCode
        self.psc = psc
        self.performancePeriod = performancePeriod
        self.placeOfPerformance = placeOfPerformance
        self.contractType = contractType
        self.competitionType = competitionType
    }

    public enum ContractType: String, CaseIterable, Sendable {
        case firmFixedPrice = "Firm Fixed Price"
        case fixedPriceIncentive = "Fixed Price Incentive"
        case costPlus = "Cost Plus"
        case timeAndMaterials = "Time and Materials"
        case laborHour = "Labor Hour"
        case indefiniteDelivery = "Indefinite Delivery"
    }

    public enum CompetitionType: String, CaseIterable, Sendable {
        case fullAndOpen = "Full and Open Competition"
        case setAside = "Set Aside"
        case soleSource = "Sole Source"
        case limitedSources = "Limited Sources"
    }
}

// MARK: - Contact Information

/// Contact information extracted from documents
public struct ContactInfo: Equatable, Sendable {
    public let name: String
    public let title: String?
    public let organization: String?
    public let phoneNumber: String?
    public let emailAddress: String?
    public let address: ExtractedAddress?
    public let role: ContactRole?

    public init(
        name: String,
        title: String? = nil,
        organization: String? = nil,
        phoneNumber: String? = nil,
        emailAddress: String? = nil,
        address: ExtractedAddress? = nil,
        role: ContactRole? = nil
    ) {
        self.name = name
        self.title = title
        self.organization = organization
        self.phoneNumber = phoneNumber
        self.emailAddress = emailAddress
        self.address = address
        self.role = role
    }

    public enum ContactRole: String, CaseIterable, Sendable {
        case contracting = "Contracting Officer"
        case technical = "Technical Point of Contact"
        case program = "Program Manager"
        case vendor = "Vendor Representative"
        case other = "Other"
    }
}

// MARK: - Line Item

/// Line item information extracted from documents
public struct LineItem: Equatable, Sendable {
    public let lineNumber: String?
    public let description: String
    public let quantity: Double?
    public let unitOfMeasure: String?
    public let unitPrice: Decimal?
    public let totalPrice: Decimal?
    public let clin: String?
    public let deliveryDate: Date?

    public init(
        lineNumber: String? = nil,
        description: String,
        quantity: Double? = nil,
        unitOfMeasure: String? = nil,
        unitPrice: Decimal? = nil,
        totalPrice: Decimal? = nil,
        clin: String? = nil,
        deliveryDate: Date? = nil
    ) {
        self.lineNumber = lineNumber
        self.description = description
        self.quantity = quantity
        self.unitOfMeasure = unitOfMeasure
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.clin = clin
        self.deliveryDate = deliveryDate
    }
}

// MARK: - Certification Information

/// Certification and compliance information
public struct CertificationInfo: Equatable, Sendable {
    public let certificationType: CertificationType
    public let issuingAuthority: String?
    public let certificationNumber: String?
    public let issueDate: Date?
    public let expirationDate: Date?
    public let status: CertificationStatus

    public init(
        certificationType: CertificationType,
        issuingAuthority: String? = nil,
        certificationNumber: String? = nil,
        issueDate: Date? = nil,
        expirationDate: Date? = nil,
        status: CertificationStatus = .unknown
    ) {
        self.certificationType = certificationType
        self.issuingAuthority = issuingAuthority
        self.certificationNumber = certificationNumber
        self.issueDate = issueDate
        self.expirationDate = expirationDate
        self.status = status
    }

    public enum CertificationType: String, CaseIterable, Sendable {
        case sba8a = "SBA 8(a)"
        case wosb = "WOSB"
        case sdvosb = "SDVOSB"
        case hubzone = "HUBZone"
        case iso9001 = "ISO 9001"
        case cmmi = "CMMI"
        case security = "Security Clearance"
        case other = "Other"
    }

    public enum CertificationStatus: String, CaseIterable, Sendable {
        case active = "Active"
        case expired = "Expired"
        case pending = "Pending"
        case suspended = "Suspended"
        case unknown = "Unknown"
    }
}

// MARK: - Populated Field

/// A field that has been populated with extracted data
public struct ExtractedPopulatedField: Equatable, Sendable {
    public let fieldName: String
    public let fieldType: FieldType
    public let extractedValue: String
    public let confidence: Double
    public let sourceText: String?
    public let sourceLocation: CGRect?

    public init(
        fieldName: String,
        fieldType: FieldType,
        extractedValue: String,
        confidence: Double,
        sourceText: String? = nil,
        sourceLocation: CGRect? = nil
    ) {
        self.fieldName = fieldName
        self.fieldType = fieldType
        self.extractedValue = extractedValue
        self.confidence = confidence
        self.sourceText = sourceText
        self.sourceLocation = sourceLocation
    }
}

// MARK: - Form Type

/// Supported government form types for auto-population
public enum FormType: String, CaseIterable, Sendable {
    case dd1155 = "DD 1155"
    case sf1449 = "SF 1449"
    case sf18 = "SF 18"
    case sf26 = "SF 26"
    case sf30 = "SF 30"
    case sf33 = "SF 33"
    case sf44 = "SF 44"
    case sf1408 = "SF 1408"
    case sf1442 = "SF 1442"
    case custom = "Custom Form"

    public var displayName: String {
        switch self {
        case .dd1155: "DD 1155 - Request and Authorization for TDY Travel"
        case .sf1449: "SF 1449 - Solicitation/Contract/Order"
        case .sf18: "SF 18 - Request for Quotations"
        case .sf26: "SF 26 - Award/Contract"
        case .sf30: "SF 30 - Amendment of Solicitation/Modification"
        case .sf33: "SF 33 - Solicitation, Offer and Award"
        case .sf44: "SF 44 - Purchase Order-Invoice-Voucher"
        case .sf1408: "SF 1408 - Preaward Survey of Prospective Contractor"
        case .sf1442: "SF 1442 - Solicitation, Offer and Award"
        case .custom: "Custom Form"
        }
    }
}

// MARK: - Validation Result

/// Result of form data validation
public struct ValidationResult: Equatable, Sendable {
    public let isValid: Bool
    public let validatedFields: [String]
    public let invalidFields: [ValidationError]
    public let warnings: [ValidationWarning]
    public let completeness: Double // 0.0 to 1.0

    public init(
        isValid: Bool,
        validatedFields: [String] = [],
        invalidFields: [ValidationError] = [],
        warnings: [ValidationWarning] = [],
        completeness: Double = 0.0
    ) {
        self.isValid = isValid
        self.validatedFields = validatedFields
        self.invalidFields = invalidFields
        self.warnings = warnings
        self.completeness = completeness
    }
}

// MARK: - Validation Error

/// Validation error for form fields
public struct ValidationError: Equatable, Sendable {
    public let fieldName: String
    public let errorType: ErrorType
    public let message: String
    public let suggestedValue: String?

    public init(
        fieldName: String,
        errorType: ErrorType,
        message: String,
        suggestedValue: String? = nil
    ) {
        self.fieldName = fieldName
        self.errorType = errorType
        self.message = message
        self.suggestedValue = suggestedValue
    }

    public enum ErrorType: String, CaseIterable, Sendable {
        case required = "Required Field Missing"
        case format = "Invalid Format"
        case range = "Value Out of Range"
        case dependency = "Dependency Not Met"
        case regulation = "Regulatory Compliance Issue"
    }
}

// MARK: - Validation Warning

/// Non-critical validation warning
public struct ValidationWarning: Equatable, Sendable {
    public let fieldName: String
    public let warningType: WarningType
    public let message: String
    public let recommendation: String?

    public init(
        fieldName: String,
        warningType: WarningType,
        message: String,
        recommendation: String? = nil
    ) {
        self.fieldName = fieldName
        self.warningType = warningType
        self.message = message
        self.recommendation = recommendation
    }

    public enum WarningType: String, CaseIterable, Sendable {
        case confidence = "Low Confidence"
        case incomplete = "Incomplete Data"
        case suggestion = "Improvement Suggestion"
        case regulatory = "Regulatory Consideration"
    }
}

// MARK: - Dependency Registration

public extension FormAutoPopulationEngine {
    static let liveValue: Self = .init(
        extractFormData: { document in
            // Live implementation would use sophisticated ML/AI processing
            // For now, return mock data based on document content
            let extractedData = GovernmentFormData(
                vendorInfo: VendorInfo(name: "Mock Vendor Inc."),
                dates: document.pages.first?.ocrResult?.extractedMetadata.dates ?? [],
                amounts: document.pages.first?.ocrResult?.extractedMetadata.currencies ?? []
            )

            return FormAutoPopulationResult(
                extractedData: extractedData,
                confidence: 0.85,
                populatedFields: [
                    ExtractedPopulatedField(
                        fieldName: "Vendor Name",
                        fieldType: .text,
                        extractedValue: "Mock Vendor Inc.",
                        confidence: 0.9
                    ),
                ]
            )
        },
        validateFormData: { _, _ in
            ValidationResult(
                isValid: true,
                validatedFields: ["Vendor Name"],
                completeness: 0.8
            )
        },
        getSupportedFormTypes: {
            FormType.allCases
        },
        estimatePopulationConfidence: { _ in
            0.85
        }
    )

    static let testValue: Self = .init(
        extractFormData: { _ in
            let extractedData = GovernmentFormData(
                vendorInfo: VendorInfo(name: "Test Vendor"),
                contractInfo: ContractInfo(contractNumber: "TEST-123")
            )

            return FormAutoPopulationResult(
                extractedData: extractedData,
                suggestedFormType: .sf1449,
                confidence: 0.9,
                populatedFields: [
                    ExtractedPopulatedField(
                        fieldName: "Test Field",
                        fieldType: .text,
                        extractedValue: "Test Value",
                        confidence: 0.95
                    ),
                ]
            )
        },
        validateFormData: { _, _ in
            ValidationResult(
                isValid: true,
                validatedFields: ["Test Field"],
                completeness: 1.0
            )
        },
        getSupportedFormTypes: {
            [.sf1449, .dd1155]
        },
        estimatePopulationConfidence: { _ in
            0.9
        }
    )
}

import CoreGraphics
import Foundation

// MARK: - Government Form OCR Models

// Phase 4.2 - Professional Document Scanner
// Smart Form Auto-Population Components

/// OCR-specific models for government form processing and field mapping
public struct GovernmentFormOCRModels: Sendable {
    // MARK: - SF-1449 Models

    /// OCR model for SF-1449 (Solicitation/Contract/Order) form
    public struct SF1449OCRData: Codable, Equatable, Sendable {
        public let solicitationNumber: OCRFieldExtraction?
        public let contractNumber: OCRFieldExtraction?
        public let requisitionNumber: OCRFieldExtraction?
        public let projectNumber: OCRFieldExtraction?
        public let issuedBy: OCRFieldExtraction?
        public let dateIssued: OCRFieldExtraction?
        public let pageOfPages: OCRFieldExtraction?
        public let contractingOfficer: OCRFieldExtraction?
        public let vendorInfo: SF1449VendorOCRData?
        public let contractInfo: SF1449ContractOCRData?
        public let deliverySchedule: OCRFieldExtraction?
        public let accountingData: OCRFieldExtraction?

        public init(
            solicitationNumber: OCRFieldExtraction? = nil,
            contractNumber: OCRFieldExtraction? = nil,
            requisitionNumber: OCRFieldExtraction? = nil,
            projectNumber: OCRFieldExtraction? = nil,
            issuedBy: OCRFieldExtraction? = nil,
            dateIssued: OCRFieldExtraction? = nil,
            pageOfPages: OCRFieldExtraction? = nil,
            contractingOfficer: OCRFieldExtraction? = nil,
            vendorInfo: SF1449VendorOCRData? = nil,
            contractInfo: SF1449ContractOCRData? = nil,
            deliverySchedule: OCRFieldExtraction? = nil,
            accountingData: OCRFieldExtraction? = nil
        ) {
            self.solicitationNumber = solicitationNumber
            self.contractNumber = contractNumber
            self.requisitionNumber = requisitionNumber
            self.projectNumber = projectNumber
            self.issuedBy = issuedBy
            self.dateIssued = dateIssued
            self.pageOfPages = pageOfPages
            self.contractingOfficer = contractingOfficer
            self.vendorInfo = vendorInfo
            self.contractInfo = contractInfo
            self.deliverySchedule = deliverySchedule
            self.accountingData = accountingData
        }
    }

    /// Vendor information specific to SF-1449 OCR extraction
    public struct SF1449VendorOCRData: Codable, Equatable, Sendable {
        public let name: OCRFieldExtraction?
        public let address: OCRFieldExtraction?
        public let cage: OCRFieldExtraction?
        public let duns: OCRFieldExtraction?
        public let phoneNumber: OCRFieldExtraction?
        public let facilityCode: OCRFieldExtraction?
        public let paymentTerms: OCRFieldExtraction?

        public init(
            name: OCRFieldExtraction? = nil,
            address: OCRFieldExtraction? = nil,
            cage: OCRFieldExtraction? = nil,
            duns: OCRFieldExtraction? = nil,
            phoneNumber: OCRFieldExtraction? = nil,
            facilityCode: OCRFieldExtraction? = nil,
            paymentTerms: OCRFieldExtraction? = nil
        ) {
            self.name = name
            self.address = address
            self.cage = cage
            self.duns = duns
            self.phoneNumber = phoneNumber
            self.facilityCode = facilityCode
            self.paymentTerms = paymentTerms
        }
    }

    /// Contract information specific to SF-1449 OCR extraction
    public struct SF1449ContractOCRData: Codable, Equatable, Sendable {
        public let type: OCRFieldExtraction?
        public let deliveryOrder: OCRFieldExtraction?
        public let taskOrder: OCRFieldExtraction?
        public let purchaseRequest: OCRFieldExtraction?
        public let confirmation: OCRFieldExtraction?
        public let deliveryDate: OCRFieldExtraction?
        public let fobPoint: OCRFieldExtraction?
        public let totalAmount: OCRFieldExtraction?

        public init(
            type: OCRFieldExtraction? = nil,
            deliveryOrder: OCRFieldExtraction? = nil,
            taskOrder: OCRFieldExtraction? = nil,
            purchaseRequest: OCRFieldExtraction? = nil,
            confirmation: OCRFieldExtraction? = nil,
            deliveryDate: OCRFieldExtraction? = nil,
            fobPoint: OCRFieldExtraction? = nil,
            totalAmount: OCRFieldExtraction? = nil
        ) {
            self.type = type
            self.deliveryOrder = deliveryOrder
            self.taskOrder = taskOrder
            self.purchaseRequest = purchaseRequest
            self.confirmation = confirmation
            self.deliveryDate = deliveryDate
            self.fobPoint = fobPoint
            self.totalAmount = totalAmount
        }
    }

    // MARK: - SF-30 Models

    /// OCR model for SF-30 (Amendment of Solicitation/Modification) form
    public struct SF30OCRData: Codable, Equatable, Sendable {
        public let amendmentNumber: OCRFieldExtraction?
        public let effectiveDate: OCRFieldExtraction?
        public let solicitationNumber: OCRFieldExtraction?
        public let contractNumber: OCRFieldExtraction?
        public let issuedBy: OCRFieldExtraction?
        public let contractingOfficer: OCRFieldExtraction?
        public let contractorInfo: SF30ContractorOCRData?
        public let modificationDetails: SF30ModificationOCRData?
        public let priceChanges: OCRFieldExtraction?
        public let periodOfPerformance: OCRFieldExtraction?
        public let accountingData: OCRFieldExtraction?

        public init(
            amendmentNumber: OCRFieldExtraction? = nil,
            effectiveDate: OCRFieldExtraction? = nil,
            solicitationNumber: OCRFieldExtraction? = nil,
            contractNumber: OCRFieldExtraction? = nil,
            issuedBy: OCRFieldExtraction? = nil,
            contractingOfficer: OCRFieldExtraction? = nil,
            contractorInfo: SF30ContractorOCRData? = nil,
            modificationDetails: SF30ModificationOCRData? = nil,
            priceChanges: OCRFieldExtraction? = nil,
            periodOfPerformance: OCRFieldExtraction? = nil,
            accountingData: OCRFieldExtraction? = nil
        ) {
            self.amendmentNumber = amendmentNumber
            self.effectiveDate = effectiveDate
            self.solicitationNumber = solicitationNumber
            self.contractNumber = contractNumber
            self.issuedBy = issuedBy
            self.contractingOfficer = contractingOfficer
            self.contractorInfo = contractorInfo
            self.modificationDetails = modificationDetails
            self.priceChanges = priceChanges
            self.periodOfPerformance = periodOfPerformance
            self.accountingData = accountingData
        }
    }

    /// Contractor information specific to SF-30 OCR extraction
    public struct SF30ContractorOCRData: Codable, Equatable, Sendable {
        public let name: OCRFieldExtraction?
        public let address: OCRFieldExtraction?
        public let cage: OCRFieldExtraction?
        public let duns: OCRFieldExtraction?
        public let contractorRepresentative: OCRFieldExtraction?
        public let signatureDate: OCRFieldExtraction?

        public init(
            name: OCRFieldExtraction? = nil,
            address: OCRFieldExtraction? = nil,
            cage: OCRFieldExtraction? = nil,
            duns: OCRFieldExtraction? = nil,
            contractorRepresentative: OCRFieldExtraction? = nil,
            signatureDate: OCRFieldExtraction? = nil
        ) {
            self.name = name
            self.address = address
            self.cage = cage
            self.duns = duns
            self.contractorRepresentative = contractorRepresentative
            self.signatureDate = signatureDate
        }
    }

    /// Modification details specific to SF-30 OCR extraction
    public struct SF30ModificationOCRData: Codable, Equatable, Sendable {
        public let modificationNumber: OCRFieldExtraction?
        public let description: OCRFieldExtraction?
        public let reason: OCRFieldExtraction?
        public let authority: OCRFieldExtraction?
        public let unilateralBilateral: OCRFieldExtraction?
        public let supplementalAgreement: OCRFieldExtraction?

        public init(
            modificationNumber: OCRFieldExtraction? = nil,
            description: OCRFieldExtraction? = nil,
            reason: OCRFieldExtraction? = nil,
            authority: OCRFieldExtraction? = nil,
            unilateralBilateral: OCRFieldExtraction? = nil,
            supplementalAgreement: OCRFieldExtraction? = nil
        ) {
            self.modificationNumber = modificationNumber
            self.description = description
            self.reason = reason
            self.authority = authority
            self.unilateralBilateral = unilateralBilateral
            self.supplementalAgreement = supplementalAgreement
        }
    }

    // MARK: - DD-1155 Models

    /// OCR model for DD-1155 (Request and Authorization for TDY Travel) form
    public struct DD1155OCRData: Codable, Equatable, Sendable {
        public let requestNumber: OCRFieldExtraction?
        public let travelerInfo: DD1155TravelerOCRData?
        public let travelInfo: DD1155TravelOCRData?
        public let authorizationInfo: DD1155AuthorizationOCRData?
        public let costEstimate: DD1155CostOCRData?
        public let approvalInfo: DD1155ApprovalOCRData?
        public let accountingInfo: OCRFieldExtraction?
        public let remarks: OCRFieldExtraction?

        public init(
            requestNumber: OCRFieldExtraction? = nil,
            travelerInfo: DD1155TravelerOCRData? = nil,
            travelInfo: DD1155TravelOCRData? = nil,
            authorizationInfo: DD1155AuthorizationOCRData? = nil,
            costEstimate: DD1155CostOCRData? = nil,
            approvalInfo: DD1155ApprovalOCRData? = nil,
            accountingInfo: OCRFieldExtraction? = nil,
            remarks: OCRFieldExtraction? = nil
        ) {
            self.requestNumber = requestNumber
            self.travelerInfo = travelerInfo
            self.travelInfo = travelInfo
            self.authorizationInfo = authorizationInfo
            self.costEstimate = costEstimate
            self.approvalInfo = approvalInfo
            self.accountingInfo = accountingInfo
            self.remarks = remarks
        }
    }

    /// Traveler information specific to DD-1155 OCR extraction
    public struct DD1155TravelerOCRData: Codable, Equatable, Sendable {
        public let name: OCRFieldExtraction?
        public let grade: OCRFieldExtraction?
        public let organization: OCRFieldExtraction?
        public let homeStation: OCRFieldExtraction?
        public let ssn: OCRFieldExtraction?
        public let phone: OCRFieldExtraction?

        public init(
            name: OCRFieldExtraction? = nil,
            grade: OCRFieldExtraction? = nil,
            organization: OCRFieldExtraction? = nil,
            homeStation: OCRFieldExtraction? = nil,
            ssn: OCRFieldExtraction? = nil,
            phone: OCRFieldExtraction? = nil
        ) {
            self.name = name
            self.grade = grade
            self.organization = organization
            self.homeStation = homeStation
            self.ssn = ssn
            self.phone = phone
        }
    }

    /// Travel information specific to DD-1155 OCR extraction
    public struct DD1155TravelOCRData: Codable, Equatable, Sendable {
        public let purpose: OCRFieldExtraction?
        public let destination: OCRFieldExtraction?
        public let departureDate: OCRFieldExtraction?
        public let returnDate: OCRFieldExtraction?
        public let modeOfTravel: OCRFieldExtraction?
        public let advanceRequired: OCRFieldExtraction?

        public init(
            purpose: OCRFieldExtraction? = nil,
            destination: OCRFieldExtraction? = nil,
            departureDate: OCRFieldExtraction? = nil,
            returnDate: OCRFieldExtraction? = nil,
            modeOfTravel: OCRFieldExtraction? = nil,
            advanceRequired: OCRFieldExtraction? = nil
        ) {
            self.purpose = purpose
            self.destination = destination
            self.departureDate = departureDate
            self.returnDate = returnDate
            self.modeOfTravel = modeOfTravel
            self.advanceRequired = advanceRequired
        }
    }

    /// Authorization information specific to DD-1155 OCR extraction
    public struct DD1155AuthorizationOCRData: Codable, Equatable, Sendable {
        public let authorizingOfficial: OCRFieldExtraction?
        public let authorizationDate: OCRFieldExtraction?
        public let signature: OCRFieldExtraction?
        public let title: OCRFieldExtraction?

        public init(
            authorizingOfficial: OCRFieldExtraction? = nil,
            authorizationDate: OCRFieldExtraction? = nil,
            signature: OCRFieldExtraction? = nil,
            title: OCRFieldExtraction? = nil
        ) {
            self.authorizingOfficial = authorizingOfficial
            self.authorizationDate = authorizationDate
            self.signature = signature
            self.title = title
        }
    }

    /// Cost estimate information specific to DD-1155 OCR extraction
    public struct DD1155CostOCRData: Codable, Equatable, Sendable {
        public let transportation: OCRFieldExtraction?
        public let lodging: OCRFieldExtraction?
        public let meals: OCRFieldExtraction?
        public let incidentals: OCRFieldExtraction?
        public let totalEstimate: OCRFieldExtraction?

        public init(
            transportation: OCRFieldExtraction? = nil,
            lodging: OCRFieldExtraction? = nil,
            meals: OCRFieldExtraction? = nil,
            incidentals: OCRFieldExtraction? = nil,
            totalEstimate: OCRFieldExtraction? = nil
        ) {
            self.transportation = transportation
            self.lodging = lodging
            self.meals = meals
            self.incidentals = incidentals
            self.totalEstimate = totalEstimate
        }
    }

    /// Approval information specific to DD-1155 OCR extraction
    public struct DD1155ApprovalOCRData: Codable, Equatable, Sendable {
        public let approvingOfficial: OCRFieldExtraction?
        public let approvalDate: OCRFieldExtraction?
        public let signature: OCRFieldExtraction?
        public let remarks: OCRFieldExtraction?

        public init(
            approvingOfficial: OCRFieldExtraction? = nil,
            approvalDate: OCRFieldExtraction? = nil,
            signature: OCRFieldExtraction? = nil,
            remarks: OCRFieldExtraction? = nil
        ) {
            self.approvingOfficial = approvingOfficial
            self.approvalDate = approvalDate
            self.signature = signature
            self.remarks = remarks
        }
    }
}

// MARK: - Core OCR Field Extraction

/// Represents a field extracted via OCR with confidence and location data
public struct OCRFieldExtraction: Codable, Equatable, Sendable {
    /// Raw text extracted from OCR
    public let rawText: String

    /// Processed/cleaned text value
    public let processedText: String

    /// Confidence score from OCR engine (0.0 - 1.0)
    public let confidence: Double

    /// Bounding box of the field in the document
    public let boundingBox: CGRect

    /// Field validation status
    public let validationStatus: ValidationStatus

    /// Type of field detected
    public let fieldType: DetectedFieldType

    /// Additional metadata from OCR processing
    public let metadata: [String: String]

    public init(
        rawText: String,
        processedText: String,
        confidence: Double,
        boundingBox: CGRect,
        validationStatus: ValidationStatus = .unknown,
        fieldType: DetectedFieldType = .unknown,
        metadata: [String: String] = [:]
    ) {
        self.rawText = rawText
        self.processedText = processedText
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.validationStatus = validationStatus
        self.fieldType = fieldType
        self.metadata = metadata
    }

    /// Returns true if field meets confidence threshold for auto-population
    public var isHighConfidence: Bool {
        confidence >= 0.85
    }

    /// Returns true if field meets confidence threshold for suggestions
    public var isMediumConfidence: Bool {
        confidence >= 0.65 && confidence < 0.85
    }

    /// Returns true if field is suitable for auto-fill based on confidence and validation
    public var isAutoFillReady: Bool {
        isHighConfidence && (validationStatus == .valid || validationStatus == .unknown)
    }
}

// MARK: - Supporting Enums

/// Validation status for extracted fields
public enum ValidationStatus: String, CaseIterable, Codable, Sendable {
    case valid
    case invalid
    case requiresReview = "requires_review"
    case unknown
}

/// Types of fields that can be detected in government forms
public enum DetectedFieldType: String, CaseIterable, Codable, Sendable {
    // Identification fields
    case contractNumber = "contract_number"
    case solicitationNumber = "solicitation_number"
    case cageCode = "cage_code"
    case dunsNumber = "duns_number"
    case uei

    // Personal information
    case name
    case address
    case phoneNumber = "phone_number"
    case email
    case ssn

    // Financial fields
    case currency
    case percentage
    case accountNumber = "account_number"

    // Dates and times
    case date
    case time
    case dateRange = "date_range"

    // Signatures and certifications
    case signature
    case checkbox
    case initials

    // Miscellaneous
    case description
    case code
    case unknown
}

// MARK: - Form Type Detection

/// Detected government form type with confidence
public struct DetectedFormType: Codable, Equatable, Sendable {
    public let formType: String
    public let confidence: Double
    public let indicators: [FormIndicator]

    public init(formType: String, confidence: Double, indicators: [FormIndicator] = []) {
        self.formType = formType
        self.confidence = confidence
        self.indicators = indicators
    }
}

/// Indicators used to detect form types
public struct FormIndicator: Codable, Equatable, Sendable {
    public let type: IndicatorType
    public let value: String
    public let weight: Double

    public init(type: IndicatorType, value: String, weight: Double) {
        self.type = type
        self.value = value
        self.weight = weight
    }

    public enum IndicatorType: String, CaseIterable, Codable, Sendable {
        case title
        case formNumber = "form_number"
        case header
        case footer
        case fieldLabel = "field_label"
        case layout
        case logo
        case watermark
    }
}

// MARK: - Validation Patterns

/// Validation patterns for government form fields
public struct ValidationPatterns: Sendable {
    /// CAGE code validation (5-character alphanumeric)
    public static let cageCode = "^[A-Z0-9]{5}$"

    /// UEI validation (12-character alphanumeric)
    public static let uei = "^[A-Z0-9]{12}$"

    /// DUNS number validation (9 digits)
    public static let duns = "^\\d{9}$"

    /// Contract number patterns (various formats)
    public static let contractNumber = "^[A-Z0-9\\-\\.]{6,20}$"

    /// Solicitation number patterns
    public static let solicitationNumber = "^[A-Z0-9\\-]{10,25}$"

    /// SSN validation
    public static let ssn = "^\\d{3}-?\\d{2}-?\\d{4}$"

    /// Phone number validation
    public static let phoneNumber = "^\\(?\\d{3}\\)?[-\\s]?\\d{3}[-\\s]?\\d{4}$"

    /// Email validation
    public static let email = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"

    /// Currency validation
    public static let currency = "^\\$?[\\d,]+\\.?\\d{0,2}$"

    /// Date validation (MM/DD/YYYY or MM-DD-YYYY)
    public static let date = "^(0?[1-9]|1[0-2])[/\\-](0?[1-9]|[12]\\d|3[01])[/\\-]\\d{4}$"
}

// MARK: - Field Mapping Configuration

/// Configuration for mapping OCR fields to form fields
public struct FieldMappingConfiguration: Sendable {
    public let formType: FormType
    public let fieldMappings: [String: FieldMapping]
    public let requiredFields: Set<String>
    public let criticalFields: Set<String>

    public init(
        formType: FormType,
        fieldMappings: [String: FieldMapping],
        requiredFields: Set<String> = [],
        criticalFields: Set<String> = []
    ) {
        self.formType = formType
        self.fieldMappings = fieldMappings
        self.requiredFields = requiredFields
        self.criticalFields = criticalFields
    }
}

/// Individual field mapping configuration
public struct FieldMapping: Sendable {
    public let targetField: String
    public let validationPattern: String?
    public let confidenceThreshold: Double
    public let isCritical: Bool
    public let transformationRules: [TransformationRule]

    public init(
        targetField: String,
        validationPattern: String? = nil,
        confidenceThreshold: Double = 0.65,
        isCritical: Bool = false,
        transformationRules: [TransformationRule] = []
    ) {
        self.targetField = targetField
        self.validationPattern = validationPattern
        self.confidenceThreshold = confidenceThreshold
        self.isCritical = isCritical
        self.transformationRules = transformationRules
    }
}

/// Rules for transforming OCR text to final field values
public struct TransformationRule: Sendable {
    public let type: TransformationType
    public let parameters: [String: String]

    public init(type: TransformationType, parameters: [String: String] = [:]) {
        self.type = type
        self.parameters = parameters
    }

    public enum TransformationType: String, CaseIterable, Sendable {
        case trimWhitespace = "trim_whitespace"
        case upperCase = "upper_case"
        case lowerCase = "lower_case"
        case removeNonAlphanumeric = "remove_non_alphanumeric"
        case formatCurrency = "format_currency"
        case formatDate = "format_date"
        case formatPhone = "format_phone"
        case validateRegex = "validate_regex"
    }
}

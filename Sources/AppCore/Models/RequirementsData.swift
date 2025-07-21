import Foundation

/// Requirements data structure for acquisition processing
/// 
/// This model captures all the essential information needed for government acquisition
/// and procurement processes, supporting both automatic extraction from documents
/// and manual input through adaptive prompting interfaces.
public struct RequirementsData: Equatable, Sendable, Codable {
    public var projectTitle: String?
    public var description: String?
    public var estimatedValue: Double?
    public var requiredDate: Date?
    public var technicalRequirements: [String]
    public var vendorInfo: APEVendorInfo?
    public var specialConditions: [String]
    public var attachments: [DocumentAttachment]
    public var performancePeriod: String?
    public var placeOfPerformance: String?
    public var businessJustification: String?
    public var acquisitionType: String?
    public var competitionMethod: String?
    public var setAsideType: String?
    public var evaluationCriteria: [String]

    // Additional properties that appear in the tests
    public var businessNeed: String?

    public init(
        projectTitle: String? = nil,
        description: String? = nil,
        estimatedValue: Double? = nil,
        requiredDate: Date? = nil,
        technicalRequirements: [String] = [],
        vendorInfo: APEVendorInfo? = nil,
        specialConditions: [String] = [],
        attachments: [DocumentAttachment] = [],
        performancePeriod: String? = nil,
        placeOfPerformance: String? = nil,
        businessJustification: String? = nil,
        acquisitionType: String? = nil,
        competitionMethod: String? = nil,
        setAsideType: String? = nil,
        evaluationCriteria: [String] = [],
        businessNeed: String? = nil
    ) {
        self.projectTitle = projectTitle
        self.description = description
        self.estimatedValue = estimatedValue
        self.requiredDate = requiredDate
        self.technicalRequirements = technicalRequirements
        self.vendorInfo = vendorInfo
        self.specialConditions = specialConditions
        self.attachments = attachments
        self.performancePeriod = performancePeriod
        self.placeOfPerformance = placeOfPerformance
        self.businessJustification = businessJustification
        self.acquisitionType = acquisitionType
        self.competitionMethod = competitionMethod
        self.setAsideType = setAsideType
        self.evaluationCriteria = evaluationCriteria
        self.businessNeed = businessNeed
    }
}

/// Document attachment for requirements tracking
public struct DocumentAttachment: Equatable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let fileName: String
    public let fileSize: Int
    public let mimeType: String
    public let uploadDate: Date
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: Int,
        mimeType: String,
        uploadDate: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.uploadDate = uploadDate
    }
}

/// Document reference for requirements tracking
public struct DocumentReference: Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let type: DocumentType
    public let url: URL?
    public let uploadDate: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: DocumentType,
        url: URL? = nil,
        uploadDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.uploadDate = uploadDate
    }
}

// MARK: - RequirementsData Extensions

public extension RequirementsData {
    /// Check if requirements data is complete with minimum required fields
    var isComplete: Bool {
        projectTitle != nil &&
        estimatedValue != nil &&
        businessNeed != nil
    }
    
    /// Validate estimated value is positive
    var isValidEstimatedValue: Bool {
        guard let value = estimatedValue else { return false }
        return value > 0
    }
    
    /// Validate required date is in the future
    var isValidRequiredDate: Bool {
        guard let date = requiredDate else { return true } // Optional field
        return date > Date()
    }
    
    /// Add a technical requirement if not already present
    mutating func addTechnicalRequirement(_ requirement: String) {
        if !technicalRequirements.contains(requirement) {
            technicalRequirements.append(requirement)
        }
    }
    
    /// Remove a technical requirement
    mutating func removeTechnicalRequirement(_ requirement: String) {
        technicalRequirements.removeAll { $0 == requirement }
    }
    
    /// Add an attachment
    mutating func addAttachment(_ attachment: DocumentAttachment) {
        attachments.append(attachment)
    }
    
    /// Remove an attachment by ID
    mutating func removeAttachment(_ id: UUID) {
        attachments.removeAll { $0.id == id }
    }
    
    /// Generate formatted string representation
    func toFormattedString() -> String {
        var result = ""
        
        if let title = projectTitle {
            result += "Project: \(title)\n"
        }
        
        if let value = estimatedValue {
            result += "Value: \(value)\n"
        }
        
        if let need = businessNeed {
            result += "Need: \(need)\n"
        }
        
        return result
    }
}
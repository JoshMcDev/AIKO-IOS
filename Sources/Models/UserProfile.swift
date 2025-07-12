import Foundation

public struct UserProfile: Equatable, Codable {
    public var id: UUID
    public var fullName: String
    public var title: String
    public var position: String
    public var email: String
    public var alternateEmail: String
    public var phoneNumber: String
    public var alternatePhoneNumber: String
    public var organizationName: String
    public var organizationalDODAAC: String
    public var agencyDepartmentService: String
    public var defaultAdministeredByAddress: Address
    public var defaultPaymentAddress: Address
    public var defaultDeliveryAddress: Address
    public var profileImageData: Data?
    public var organizationLogoData: Data?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        fullName: String = "",
        title: String = "",
        position: String = "",
        email: String = "",
        alternateEmail: String = "",
        phoneNumber: String = "",
        alternatePhoneNumber: String = "",
        organizationName: String = "",
        organizationalDODAAC: String = "",
        agencyDepartmentService: String = "",
        defaultAdministeredByAddress: Address = Address(),
        defaultPaymentAddress: Address = Address(),
        defaultDeliveryAddress: Address = Address(),
        profileImageData: Data? = nil,
        organizationLogoData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fullName = fullName
        self.title = title
        self.position = position
        self.email = email
        self.alternateEmail = alternateEmail
        self.phoneNumber = phoneNumber
        self.alternatePhoneNumber = alternatePhoneNumber
        self.organizationName = organizationName
        self.organizationalDODAAC = organizationalDODAAC
        self.agencyDepartmentService = agencyDepartmentService
        self.defaultAdministeredByAddress = defaultAdministeredByAddress
        self.defaultPaymentAddress = defaultPaymentAddress
        self.defaultDeliveryAddress = defaultDeliveryAddress
        self.profileImageData = profileImageData
        self.organizationLogoData = organizationLogoData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Address: Equatable, Codable {
    public var freeText: String
    public var street1: String
    public var street2: String
    public var city: String
    public var state: String
    public var zipCode: String
    public var country: String
    public var phone: String
    public var email: String
    
    public init(
        freeText: String = "",
        street1: String = "",
        street2: String = "",
        city: String = "",
        state: String = "",
        zipCode: String = "",
        country: String = "United States",
        phone: String = "",
        email: String = ""
    ) {
        self.freeText = freeText
        self.street1 = street1
        self.street2 = street2
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.phone = phone
        self.email = email
    }
    
    public var isComplete: Bool {
        !street1.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
    
    public var formatted: String {
        var lines: [String] = []
        
        if !street1.isEmpty {
            lines.append(street1)
        }
        if !street2.isEmpty {
            lines.append(street2)
        }
        
        var cityStateZip = ""
        if !city.isEmpty {
            cityStateZip += city
        }
        if !state.isEmpty {
            if !cityStateZip.isEmpty { cityStateZip += ", " }
            cityStateZip += state
        }
        if !zipCode.isEmpty {
            if !cityStateZip.isEmpty { cityStateZip += " " }
            cityStateZip += zipCode
        }
        
        if !cityStateZip.isEmpty {
            lines.append(cityStateZip)
        }
        
        if !country.isEmpty && country != "United States" {
            lines.append(country)
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Profile Validation
extension UserProfile {
    public var isComplete: Bool {
        // Only full name and email are required
        !fullName.isEmpty && !email.isEmpty
    }
    
    public var completionPercentage: Double {
        var completedFields = 0
        let totalFields = 15
        
        if !fullName.isEmpty { completedFields += 1 }
        if !title.isEmpty { completedFields += 1 }
        if !position.isEmpty { completedFields += 1 }
        if !email.isEmpty { completedFields += 1 }
        if !alternateEmail.isEmpty { completedFields += 1 }
        if !phoneNumber.isEmpty { completedFields += 1 }
        if !alternatePhoneNumber.isEmpty { completedFields += 1 }
        if !organizationName.isEmpty { completedFields += 1 }
        if !organizationalDODAAC.isEmpty { completedFields += 1 }
        if defaultAdministeredByAddress.isComplete { completedFields += 1 }
        if defaultPaymentAddress.isComplete { completedFields += 1 }
        if defaultDeliveryAddress.isComplete { completedFields += 1 }
        if profileImageData != nil { completedFields += 1 }
        if organizationLogoData != nil { completedFields += 1 }
        if !position.isEmpty { completedFields += 1 }
        
        return Double(completedFields) / Double(totalFields)
    }
}

// MARK: - Template Variables
extension UserProfile {
    /// Returns a dictionary of profile values for use in document templates
    public var templateVariables: [String: String] {
        var variables: [String: String] = [:]
        
        // Personal Information
        variables["USER_FULL_NAME"] = fullName
        variables["USER_TITLE"] = title
        variables["USER_POSITION"] = position
        variables["USER_EMAIL"] = email
        variables["USER_ALTERNATE_EMAIL"] = alternateEmail
        variables["USER_PHONE"] = phoneNumber
        variables["USER_ALTERNATE_PHONE"] = alternatePhoneNumber
        
        // Organization Information
        variables["ORGANIZATION_NAME"] = organizationName
        variables["ORGANIZATION_DODAAC"] = organizationalDODAAC
        variables["AGENCY_DEPARTMENT_SERVICE"] = agencyDepartmentService
        
        // Addresses
        variables["ADMINISTERED_BY_ADDRESS"] = defaultAdministeredByAddress.formatted
        variables["PAYMENT_ADDRESS"] = defaultPaymentAddress.formatted
        variables["DELIVERY_ADDRESS"] = defaultDeliveryAddress.formatted
        
        // Individual address components
        variables["ADMINISTERED_BY_STREET1"] = defaultAdministeredByAddress.street1
        variables["ADMINISTERED_BY_STREET2"] = defaultAdministeredByAddress.street2
        variables["ADMINISTERED_BY_CITY"] = defaultAdministeredByAddress.city
        variables["ADMINISTERED_BY_STATE"] = defaultAdministeredByAddress.state
        variables["ADMINISTERED_BY_ZIP"] = defaultAdministeredByAddress.zipCode
        
        variables["PAYMENT_STREET1"] = defaultPaymentAddress.street1
        variables["PAYMENT_STREET2"] = defaultPaymentAddress.street2
        variables["PAYMENT_CITY"] = defaultPaymentAddress.city
        variables["PAYMENT_STATE"] = defaultPaymentAddress.state
        variables["PAYMENT_ZIP"] = defaultPaymentAddress.zipCode
        
        variables["DELIVERY_STREET1"] = defaultDeliveryAddress.street1
        variables["DELIVERY_STREET2"] = defaultDeliveryAddress.street2
        variables["DELIVERY_CITY"] = defaultDeliveryAddress.city
        variables["DELIVERY_STATE"] = defaultDeliveryAddress.state
        variables["DELIVERY_ZIP"] = defaultDeliveryAddress.zipCode
        
        return variables
    }
}
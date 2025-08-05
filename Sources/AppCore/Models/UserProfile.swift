import Foundation

public struct UserProfile: Equatable, Codable, Sendable, Hashable {
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

    // Additional fields for 20+ field requirement
    public var website: String
    public var linkedIn: String
    public var twitter: String
    public var bio: String
    public var certifications: [String]
    public var specializations: [String]
    public var preferredLanguage: String
    public var timeZone: String
    public var mailingAddress: Address // For ProfileView compatibility

    // Template variable support for document generation
    public func asTemplateVariables() -> [String: String] {
        [
            "fullName": fullName,
            "title": title,
            "position": position,
            "email": email,
            "phoneNumber": phoneNumber,
            "organizationName": organizationName,
            "organizationalDODAAC": organizationalDODAAC,
            "agencyDepartmentService": agencyDepartmentService,
            "website": website,
            "bio": bio,
            "preferredLanguage": preferredLanguage,
            "timeZone": timeZone,
        ]
    }

    public var billingAddress: Address // For ProfileView compatibility

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
        website: String = "",
        linkedIn: String = "",
        twitter: String = "",
        bio: String = "",
        certifications: [String] = [],
        specializations: [String] = [],
        preferredLanguage: String = "en",
        timeZone: String = TimeZone.current.identifier,
        mailingAddress: Address = Address(),
        billingAddress: Address = Address(),
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
        self.website = website
        self.linkedIn = linkedIn
        self.twitter = twitter
        self.bio = bio
        self.certifications = certifications
        self.specializations = specializations
        self.preferredLanguage = preferredLanguage
        self.timeZone = timeZone
        self.mailingAddress = mailingAddress
        self.billingAddress = billingAddress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Address: Equatable, Codable, Sendable, Hashable {
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

        if !country.isEmpty, country != "United States" {
            lines.append(country)
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Profile Validation

// Extension provides compatibility with existing UI components

public extension UserProfile {
    var completionPercentage: Double {
        var completedFields = 0
        let totalFields = 24 // Updated for 20+ fields

        if !fullName.isEmpty { completedFields += 1 }
        if !title.isEmpty { completedFields += 1 }
        if !position.isEmpty { completedFields += 1 }
        if !email.isEmpty { completedFields += 1 }
        if !alternateEmail.isEmpty { completedFields += 1 }
        if !phoneNumber.isEmpty { completedFields += 1 }
        if !alternatePhoneNumber.isEmpty { completedFields += 1 }
        if !organizationName.isEmpty { completedFields += 1 }
        if !organizationalDODAAC.isEmpty { completedFields += 1 }
        if !agencyDepartmentService.isEmpty { completedFields += 1 }
        if defaultAdministeredByAddress.isComplete { completedFields += 1 }
        if defaultPaymentAddress.isComplete { completedFields += 1 }
        if defaultDeliveryAddress.isComplete { completedFields += 1 }
        if mailingAddress.isComplete { completedFields += 1 }
        if billingAddress.isComplete { completedFields += 1 }
        if profileImageData != nil { completedFields += 1 }
        if organizationLogoData != nil { completedFields += 1 }
        if !website.isEmpty { completedFields += 1 }
        if !linkedIn.isEmpty { completedFields += 1 }
        if !twitter.isEmpty { completedFields += 1 }
        if !bio.isEmpty { completedFields += 1 }
        if !certifications.isEmpty { completedFields += 1 }
        if !specializations.isEmpty { completedFields += 1 }
        if !preferredLanguage.isEmpty { completedFields += 1 }

        return Double(completedFields) / Double(totalFields)
    }

    var isComplete: Bool {
        // Only full name and email are required
        !fullName.isEmpty && !email.isEmpty
    }
}

// MARK: - Template Variables

public extension UserProfile {
    /// Returns a dictionary of profile values for use in document templates
    var templateVariables: [String: String] {
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

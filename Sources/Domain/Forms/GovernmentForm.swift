import Foundation

/// Base protocol for all government forms
public protocol GovernmentForm: ValueObject {
    var formNumber: String { get }
    var formTitle: String { get }
    var revision: String { get }
    var effectiveDate: Date { get }
    var expirationDate: Date? { get }
    var isElectronic: Bool { get }
    var metadata: FormMetadata { get }

    /// Check if form is currently valid
    func isValid(on date: Date) -> Bool

    /// Export form data for persistence
    func export() -> [String: Any]

    /// Generate a unique identifier for this form instance
    func generateIdentifier() -> String
}

/// Default implementation
public extension GovernmentForm {
    func isValid(on date: Date = Date()) -> Bool {
        if date < effectiveDate {
            return false
        }

        if let expirationDate, date > expirationDate {
            return false
        }

        return true
    }

    func generateIdentifier() -> String {
        "\(formNumber)-\(UUID().uuidString)"
    }
}

/// Base class for government forms
open class BaseGovernmentForm: GovernmentForm, Equatable {
    public let formNumber: String
    public let formTitle: String
    public let revision: String
    public let effectiveDate: Date
    public let expirationDate: Date?
    public let isElectronic: Bool
    public let metadata: FormMetadata

    public init(
        formNumber: String,
        formTitle: String,
        revision: String,
        effectiveDate: Date,
        expirationDate: Date? = nil,
        isElectronic: Bool = true,
        metadata: FormMetadata
    ) {
        self.formNumber = formNumber
        self.formTitle = formTitle
        self.revision = revision
        self.effectiveDate = effectiveDate
        self.expirationDate = expirationDate
        self.isElectronic = isElectronic
        self.metadata = metadata
    }

    // MARK: - ValueObject

    open func validate() throws {
        guard !formNumber.isEmpty else {
            throw FormError.missingFormNumber
        }

        guard !formTitle.isEmpty else {
            throw FormError.invalidField("formTitle")
        }

        guard !revision.isEmpty else {
            throw FormError.invalidField("revision")
        }
    }

    // MARK: - Equatable

    public static func == (lhs: BaseGovernmentForm, rhs: BaseGovernmentForm) -> Bool {
        lhs.formNumber == rhs.formNumber &&
            lhs.revision == rhs.revision &&
            lhs.effectiveDate == rhs.effectiveDate
    }

    // MARK: - Export

    open func export() -> [String: Any] {
        [
            "formNumber": formNumber,
            "formTitle": formTitle,
            "revision": revision,
            "effectiveDate": effectiveDate.timeIntervalSince1970,
            "expirationDate": expirationDate?.timeIntervalSince1970 as Any,
            "isElectronic": isElectronic,
            "metadata": [
                "createdBy": metadata.createdBy,
                "createdDate": metadata.createdDate.timeIntervalSince1970,
                "agency": metadata.agency,
                "purpose": metadata.purpose,
                "authority": metadata.authority as Any,
            ],
        ]
    }
}

// MARK: - Form Field Value Objects

/// Contract number value object
public struct ContractNumber: ValueObject {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("contractNumber")
        }

        // Basic format validation - alphanumeric with dashes
        let regex = #"^[A-Z0-9\-]+$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)

        guard predicate.evaluate(with: value) else {
            throw FormError.invalidField("contractNumber - must be alphanumeric with dashes")
        }
    }
}

/// Solicitation number value object
public struct SolicitationNumber: ValueObject {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("solicitationNumber")
        }

        guard value.count >= 5 else {
            throw FormError.invalidField("solicitationNumber - must be at least 5 characters")
        }
    }
}

/// Requisition/Purchase request number
public struct RequisitionNumber: ValueObject, Sendable {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("requisitionNumber")
        }
    }

    /// Default placeholder requisition number for forms
    public static let `default`: RequisitionNumber = try! RequisitionNumber("REQ-00000")
}

/// Delivery order number
public struct DeliveryOrderNumber: ValueObject {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("deliveryOrderNumber")
        }
    }
}

/// NAICS code value object for forms
public struct FormNAICSCode: ValueObject {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("NAICSCode")
        }

        // NAICS codes are 2-6 digits
        guard value.count >= 2, value.count <= 6 else {
            throw FormError.invalidField("NAICSCode - must be 2-6 digits")
        }

        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: value)) else {
            throw FormError.invalidField("NAICSCode - must contain only digits")
        }
    }
}

/// Cage code value object
public struct CageCode: ValueObject, Sendable {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("cageCode")
        }

        // CAGE codes are typically 5 characters
        guard value.count == 5 else {
            throw FormError.invalidField("cageCode - must be 5 characters")
        }
    }

    /// Empty placeholder CAGE code for forms
    public static let empty: CageCode = try! CageCode("00000")
}

/// DUNS number value object
public struct DUNSNumber: ValueObject {
    public let value: String

    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }

    public func validate() throws {
        guard !value.isEmpty else {
            throw FormError.missingRequiredField("DUNSNumber")
        }

        // DUNS numbers are 9 digits
        guard value.count == 9 else {
            throw FormError.invalidField("DUNSNumber - must be 9 digits")
        }

        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: value)) else {
            throw FormError.invalidField("DUNSNumber - must contain only digits")
        }
    }
}

/// Place of performance value object
public struct PlaceOfPerformance: ValueObject {
    public let address: PostalAddress
    public let countryCode: String
    public let principalPlaceCode: String?

    public init(
        address: PostalAddress,
        countryCode: String,
        principalPlaceCode: String? = nil
    ) throws {
        self.address = address
        self.countryCode = countryCode.uppercased()
        self.principalPlaceCode = principalPlaceCode?.uppercased()
        try validate()
    }

    public func validate() throws {
        // Country code should be 2 characters (ISO 3166-1 alpha-2)
        guard countryCode.count == 2 else {
            throw FormError.invalidField("countryCode - must be 2 characters")
        }
    }
}

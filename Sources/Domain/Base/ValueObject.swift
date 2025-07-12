import Foundation

/// Base protocol for value objects
public protocol ValueObject: Equatable {
    /// Validate the value object
    func validate() throws
}

/// Email value object
public struct Email: ValueObject {
    public let value: String
    
    public init(_ value: String) throws {
        self.value = value
        try validate()
    }
    
    public func validate() throws {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard predicate.evaluate(with: value) else {
            throw DomainError.validation("Invalid email format")
        }
    }
}

/// Phone number value object
public struct PhoneNumber: ValueObject {
    public let value: String
    
    public init(_ value: String) throws {
        // Remove formatting
        self.value = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        try validate()
    }
    
    public func validate() throws {
        guard value.count >= 10 && value.count <= 15 else {
            throw DomainError.validation("Phone number must be between 10-15 digits")
        }
    }
    
    public var formatted: String {
        guard value.count == 10 else { return value }
        
        let areaCode = String(value.prefix(3))
        let prefix = String(value.dropFirst(3).prefix(3))
        let number = String(value.dropFirst(6))
        
        return "(\(areaCode)) \(prefix)-\(number)"
    }
}

/// Money value object
public struct Money: ValueObject {
    public let amount: Decimal
    public let currency: Currency
    
    public init(amount: Decimal, currency: Currency = .usd) throws {
        self.amount = amount
        self.currency = currency
        try validate()
    }
    
    public func validate() throws {
        guard amount >= 0 else {
            throw DomainError.validation("Amount cannot be negative")
        }
    }
    
    public var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        return formatter.string(from: amount as NSNumber) ?? "\(currency.symbol)\(amount)"
    }
    
    public static func + (lhs: Money, rhs: Money) throws -> Money {
        guard lhs.currency == rhs.currency else {
            throw DomainError.businessRule("Cannot add different currencies")
        }
        return try Money(amount: lhs.amount + rhs.amount, currency: lhs.currency)
    }
    
    public static func - (lhs: Money, rhs: Money) throws -> Money {
        guard lhs.currency == rhs.currency else {
            throw DomainError.businessRule("Cannot subtract different currencies")
        }
        return try Money(amount: lhs.amount - rhs.amount, currency: lhs.currency)
    }
}

/// Currency enumeration
public enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    
    public var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }
}

/// Date range value object
public struct DateRange: ValueObject {
    public let startDate: Date
    public let endDate: Date
    
    public init(from startDate: Date, to endDate: Date) throws {
        self.startDate = startDate
        self.endDate = endDate
        try validate()
    }
    
    public func validate() throws {
        guard startDate <= endDate else {
            throw DomainError.validation("Start date must be before or equal to end date")
        }
    }
    
    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    public var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    public func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
    
    public func overlaps(with other: DateRange) -> Bool {
        return startDate <= other.endDate && endDate >= other.startDate
    }
}

/// Percentage value object
public struct Percentage: ValueObject {
    public let value: Decimal
    
    public init(_ value: Decimal) throws {
        self.value = value
        try validate()
    }
    
    public init(fraction: Decimal) throws {
        self.value = fraction * 100
        try validate()
    }
    
    public func validate() throws {
        guard value >= 0 && value <= 100 else {
            throw DomainError.validation("Percentage must be between 0 and 100")
        }
    }
    
    public var fraction: Decimal {
        value / 100
    }
    
    public var formatted: String {
        "\(value)%"
    }
}

// MARK: - Acquisition-Specific Value Objects

/// Project number value object
public struct ProjectNumber: ValueObject {
    public let value: String
    
    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }
    
    public func validate() throws {
        guard !value.isEmpty else {
            throw DomainError.validation("Project number cannot be empty")
        }
        
        guard value.count >= 3 && value.count <= 50 else {
            throw DomainError.validation("Project number must be between 3-50 characters")
        }
        
        // Basic format validation - alphanumeric with dashes and underscores
        let regex = #"^[A-Za-z0-9\-_]+$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        
        guard predicate.evaluate(with: value) else {
            throw DomainError.validation("Project number must contain only letters, numbers, dashes, and underscores")
        }
    }
}

/// Requirement description value object
public struct RequirementDescription: ValueObject {
    public let value: String
    
    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }
    
    public func validate() throws {
        guard !value.isEmpty else {
            throw DomainError.validation("Requirements cannot be empty")
        }
        
        guard value.count >= 10 else {
            throw DomainError.validation("Requirements must be at least 10 characters")
        }
        
        guard value.count <= 10000 else {
            throw DomainError.validation("Requirements must not exceed 10,000 characters")
        }
    }
    
    public var wordCount: Int {
        value.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

/// Acquisition title value object
public struct AcquisitionTitle: ValueObject {
    public let value: String
    
    public init(_ value: String) throws {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }
    
    public func validate() throws {
        guard !value.isEmpty else {
            throw DomainError.validation("Title cannot be empty")
        }
        
        guard value.count >= 3 else {
            throw DomainError.validation("Title must be at least 3 characters")
        }
        
        guard value.count <= 200 else {
            throw DomainError.validation("Title must not exceed 200 characters")
        }
    }
}

/// Document metadata value object
public struct DocumentMetadata: ValueObject {
    public let documentType: String
    public let version: String?
    public let tags: Set<String>
    
    public init(documentType: String, version: String? = nil, tags: Set<String> = []) throws {
        self.documentType = documentType
        self.version = version
        self.tags = tags
        try validate()
    }
    
    public func validate() throws {
        guard !documentType.isEmpty else {
            throw DomainError.validation("Document type cannot be empty")
        }
        
        if let version = version {
            guard !version.isEmpty else {
                throw DomainError.validation("Version cannot be empty if provided")
            }
        }
        
        // Validate tags
        for tag in tags {
            guard !tag.isEmpty else {
                throw DomainError.validation("Tags cannot be empty")
            }
            guard tag.count <= 50 else {
                throw DomainError.validation("Tag must not exceed 50 characters")
            }
        }
    }
}

/// File metadata value object
public struct FileMetadata: ValueObject {
    public let fileName: String
    public let fileSize: Int64
    public let mimeType: String?
    
    public init(fileName: String, fileSize: Int64, mimeType: String? = nil) throws {
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        try validate()
    }
    
    public func validate() throws {
        guard !fileName.isEmpty else {
            throw DomainError.validation("File name cannot be empty")
        }
        
        guard fileSize > 0 else {
            throw DomainError.validation("File size must be greater than 0")
        }
        
        // 100MB limit
        guard fileSize <= 100 * 1024 * 1024 else {
            throw DomainError.validation("File size must not exceed 100MB")
        }
        
        if let mimeType = mimeType {
            guard !mimeType.isEmpty else {
                throw DomainError.validation("MIME type cannot be empty if provided")
            }
        }
    }
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

/// Postal address value object
public struct PostalAddress: ValueObject {
    public let street: String
    public let city: String
    public let state: String
    public let zipCode: String
    public let country: String
    
    public init(street: String, city: String, state: String, zipCode: String, country: String = "USA") throws {
        self.street = street.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        self.state = state.trimmingCharacters(in: .whitespacesAndNewlines)
        self.zipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate()
    }
    
    public func validate() throws {
        guard !street.isEmpty else {
            throw DomainError.validation("Street address cannot be empty")
        }
        
        guard !city.isEmpty else {
            throw DomainError.validation("City cannot be empty")
        }
        
        guard !state.isEmpty else {
            throw DomainError.validation("State cannot be empty")
        }
        
        guard !zipCode.isEmpty else {
            throw DomainError.validation("ZIP code cannot be empty")
        }
        
        // US ZIP code validation
        if country == "USA" {
            let zipRegex = #"^\d{5}(-\d{4})?$"#
            let predicate = NSPredicate(format: "SELF MATCHES %@", zipRegex)
            
            guard predicate.evaluate(with: zipCode) else {
                throw DomainError.validation("Invalid US ZIP code format")
            }
        }
    }
    
    public var formatted: String {
        "\(street)\n\(city), \(state) \(zipCode)\n\(country)"
    }
}
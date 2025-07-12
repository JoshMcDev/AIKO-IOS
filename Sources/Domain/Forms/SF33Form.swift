import Foundation

/// SF 33 - Solicitation, Offer and Award
public final class SF33Form: BaseGovernmentForm {
    
    // MARK: - Form Sections
    
    public let solicitation: SF33SolicitationSection
    public let offer: OfferSection
    public let award: AwardSection
    
    // MARK: - Initialization
    
    public init(
        revision: String = "REV SEP 2020",
        metadata: FormMetadata,
        solicitation: SF33SolicitationSection,
        offer: OfferSection,
        award: AwardSection
    ) {
        self.solicitation = solicitation
        self.offer = offer
        self.award = award
        
        super.init(
            formNumber: "SF33",
            formTitle: "Solicitation, Offer and Award",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2020, month: 9, day: 1).date!,
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }
    
    // MARK: - Validation
    
    public override func validate() throws {
        try super.validate()
        
        // Validate all sections
        try solicitation.validate()
        try offer.validate()
        try award.validate()
    }
    
    // MARK: - Export
    
    public override func export() -> [String: Any] {
        var data = super.export()
        
        data["solicitation"] = solicitation.export()
        data["offer"] = offer.export()
        data["award"] = award.export()
        
        return data
    }
}

// MARK: - SF33 Sections

/// Solicitation section for SF33
public struct SF33SolicitationSection: ValueObject {
    public let solicitationNumber: SolicitationNumber
    public let issueDate: Date
    public let requisitionNumber: RequisitionNumber?
    public let solicitationType: SolicitationType
    public let setAsideType: SetAsideType?
    public let responseDeadline: Date
    
    public enum SolicitationType: String, CaseIterable {
        case rfp = "RFP"
        case rfq = "RFQ"
        case ifb = "IFB"
        case rfi = "RFI"
    }
    
    public enum SetAsideType: String, CaseIterable {
        case none = "NONE"
        case smallBusiness = "SMALL_BUSINESS"
        case womenOwned = "WOSB"
        case veteranOwned = "VOSB"
        case serviceDisabledVeteran = "SDVOSB"
        case hubZone = "HUBZONE"
        case section8a = "8A"
    }
    
    public init(
        solicitationNumber: SolicitationNumber,
        issueDate: Date,
        requisitionNumber: RequisitionNumber? = nil,
        solicitationType: SolicitationType,
        setAsideType: SetAsideType? = nil,
        responseDeadline: Date
    ) {
        self.solicitationNumber = solicitationNumber
        self.issueDate = issueDate
        self.requisitionNumber = requisitionNumber
        self.solicitationType = solicitationType
        self.setAsideType = setAsideType
        self.responseDeadline = responseDeadline
    }
    
    public func validate() throws {
        guard responseDeadline > issueDate else {
            throw FormError.validationFailed("Response deadline must be after issue date")
        }
    }
    
    func export() -> [String: Any] {
        [
            "solicitationNumber": solicitationNumber.value,
            "issueDate": issueDate.timeIntervalSince1970,
            "requisitionNumber": requisitionNumber?.value as Any,
            "solicitationType": solicitationType.rawValue,
            "setAsideType": setAsideType?.rawValue as Any,
            "responseDeadline": responseDeadline.timeIntervalSince1970
        ]
    }
}

/// Offer section
public struct OfferSection: ValueObject {
    public let offeror: OfferorInfo
    public let offerDate: Date
    public let offerValidityPeriod: Int // days
    public let acknowledgments: [Acknowledgment]
    public let certifications: [Certification]
    
    public struct OfferorInfo: ValueObject {
        public let name: String
        public let address: PostalAddress
        public let cageCode: CageCode?
        public let dunsNumber: DUNSNumber?
        public let taxId: String
        public let phoneNumber: PhoneNumber
        public let email: Email
        public let authorizedRepresentative: String
        
        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("offeror name")
            }
            guard !authorizedRepresentative.isEmpty else {
                throw FormError.missingRequiredField("authorized representative")
            }
        }
    }
    
    public struct Acknowledgment: ValueObject {
        public let amendmentNumber: String
        public let acknowledgedDate: Date
        
        public func validate() throws {
            guard !amendmentNumber.isEmpty else {
                throw FormError.missingRequiredField("amendment number")
            }
        }
    }
    
    public struct Certification: ValueObject {
        public let type: CertificationType
        public let certified: Bool
        public let certificationDate: Date
        
        public enum CertificationType: String, CaseIterable {
            case smallBusiness = "SMALL_BUSINESS"
            case womenOwned = "WOMEN_OWNED"
            case minorityOwned = "MINORITY_OWNED"
            case veteranOwned = "VETERAN_OWNED"
            case hubZone = "HUBZONE"
            case debarment = "DEBARMENT"
        }
        
        public func validate() throws {
            // No additional validation needed
        }
    }
    
    public init(
        offeror: OfferorInfo,
        offerDate: Date,
        offerValidityPeriod: Int,
        acknowledgments: [Acknowledgment] = [],
        certifications: [Certification] = []
    ) {
        self.offeror = offeror
        self.offerDate = offerDate
        self.offerValidityPeriod = offerValidityPeriod
        self.acknowledgments = acknowledgments
        self.certifications = certifications
    }
    
    public func validate() throws {
        try offeror.validate()
        
        guard offerValidityPeriod > 0 else {
            throw FormError.validationFailed("Offer validity period must be positive")
        }
        
        for acknowledgment in acknowledgments {
            try acknowledgment.validate()
        }
        
        for certification in certifications {
            try certification.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "offeror": [
                "name": offeror.name,
                "address": offeror.address.formatted,
                "cageCode": offeror.cageCode?.value as Any,
                "dunsNumber": offeror.dunsNumber?.value as Any,
                "taxId": offeror.taxId,
                "phoneNumber": offeror.phoneNumber.value,
                "email": offeror.email.value,
                "authorizedRepresentative": offeror.authorizedRepresentative
            ],
            "offerDate": offerDate.timeIntervalSince1970,
            "offerValidityPeriod": offerValidityPeriod,
            "acknowledgments": acknowledgments.map { ack in
                [
                    "amendmentNumber": ack.amendmentNumber,
                    "acknowledgedDate": ack.acknowledgedDate.timeIntervalSince1970
                ]
            },
            "certifications": certifications.map { cert in
                [
                    "type": cert.type.rawValue,
                    "certified": cert.certified,
                    "certificationDate": cert.certificationDate.timeIntervalSince1970
                ]
            }
        ]
    }
}

/// Award section
public struct AwardSection: ValueObject {
    public let contractNumber: ContractNumber?
    public let awardDate: Date?
    public let awardAmount: Money?
    public let contractingOfficer: ContractingOfficer?
    public let accountingData: String?
    
    public struct ContractingOfficer: ValueObject {
        public let name: String
        public let title: String
        public let signature: String? // Base64 encoded signature
        public let signatureDate: Date?
        
        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("contracting officer name")
            }
        }
    }
    
    public init(
        contractNumber: ContractNumber? = nil,
        awardDate: Date? = nil,
        awardAmount: Money? = nil,
        contractingOfficer: ContractingOfficer? = nil,
        accountingData: String? = nil
    ) {
        self.contractNumber = contractNumber
        self.awardDate = awardDate
        self.awardAmount = awardAmount
        self.contractingOfficer = contractingOfficer
        self.accountingData = accountingData
    }
    
    public func validate() throws {
        // Award section is optional until award is made
        if let contractingOfficer = contractingOfficer {
            try contractingOfficer.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "contractNumber": contractNumber?.value as Any,
            "awardDate": awardDate?.timeIntervalSince1970 as Any,
            "awardAmount": awardAmount?.amount as Any,
            "currency": awardAmount?.currency.rawValue as Any,
            "contractingOfficer": contractingOfficer.map { officer in
                [
                    "name": officer.name,
                    "title": officer.title,
                    "signature": officer.signature as Any,
                    "signatureDate": officer.signatureDate?.timeIntervalSince1970 as Any
                ]
            } as Any,
            "accountingData": accountingData as Any
        ]
    }
}

// MARK: - SF33 Factory

public final class SF33Factory: BaseFormFactory<SF33Form> {
    
    public override func createBlank() -> SF33Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "GSA",
            purpose: "Solicitation and award"
        )
        
        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )
        
        return SF33Form(
            metadata: metadata,
            solicitation: SF33SolicitationSection(
                solicitationNumber: try! SolicitationNumber("TBD-00000"),
                issueDate: Date(),
                requisitionNumber: nil,
                solicitationType: .rfp,
                setAsideType: nil,
                responseDeadline: Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
            ),
            offer: OfferSection(
                offeror: OfferSection.OfferorInfo(
                    name: "",
                    address: emptyAddress,
                    cageCode: nil,
                    dunsNumber: nil,
                    taxId: "",
                    phoneNumber: try! PhoneNumber("000-000-0000"),
                    email: try! Email("placeholder@example.com"),
                    authorizedRepresentative: ""
                ),
                offerDate: Date(),
                offerValidityPeriod: 90 // 90 days default
            ),
            award: AwardSection()
        )
    }
    
    public override func createForm(with data: FormData) throws -> SF33Form {
        let metadata = data.metadata
        
        // Extract and validate fields
        let solicitation = try createSolicitationSection(from: data.fields)
        let offer = try createOfferSection(from: data.fields)
        let award = try createAwardSection(from: data.fields)
        
        return SF33Form(
            revision: data.revision ?? "REV SEP 2020",
            metadata: metadata,
            solicitation: solicitation,
            offer: offer,
            award: award
        )
    }
    
    // Helper methods for creating sections
    private func createSolicitationSection(from fields: [String: Any]) throws -> SF33SolicitationSection {
        guard let solicitationNum = fields["solicitationNumber"] as? String else {
            throw FormError.missingRequiredField("solicitationNumber")
        }
        
        let solicitationNumber = try SolicitationNumber(solicitationNum)
        let issueDate = fields["issueDate"] as? Date ?? Date()
        
        let requisitionNumber: RequisitionNumber? = {
            if let reqNum = fields["requisitionNumber"] as? String {
                return try? RequisitionNumber(reqNum)
            }
            return nil
        }()
        
        let solicitationType = SF33SolicitationSection.SolicitationType(
            rawValue: fields["solicitationType"] as? String ?? "RFP"
        ) ?? .rfp
        
        let responseDeadline = fields["responseDeadline"] as? Date ?? 
            Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        return SF33SolicitationSection(
            solicitationNumber: solicitationNumber,
            issueDate: issueDate,
            requisitionNumber: requisitionNumber,
            solicitationType: solicitationType,
            responseDeadline: responseDeadline
        )
    }
    
    private func createOfferSection(from fields: [String: Any]) throws -> OfferSection {
        // Implementation details for extracting offer data
        let address = try PostalAddress(
            street: fields["offerorStreet"] as? String ?? "TBD",
            city: fields["offerorCity"] as? String ?? "TBD",
            state: fields["offerorState"] as? String ?? "TBD",
            zipCode: fields["offerorZip"] as? String ?? "00000"
        )
        
        let offeror = OfferSection.OfferorInfo(
            name: fields["offerorName"] as? String ?? "",
            address: address,
            cageCode: nil,
            dunsNumber: nil,
            taxId: fields["taxId"] as? String ?? "",
            phoneNumber: try PhoneNumber(fields["phoneNumber"] as? String ?? "000-000-0000"),
            email: try Email(fields["email"] as? String ?? "placeholder@example.com"),
            authorizedRepresentative: fields["authorizedRep"] as? String ?? ""
        )
        
        return OfferSection(
            offeror: offeror,
            offerDate: fields["offerDate"] as? Date ?? Date(),
            offerValidityPeriod: fields["offerValidityPeriod"] as? Int ?? 90
        )
    }
    
    private func createAwardSection(from fields: [String: Any]) throws -> AwardSection {
        // Award section is optional
        AwardSection()
    }
}
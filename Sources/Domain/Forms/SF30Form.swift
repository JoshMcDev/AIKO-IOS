import Foundation

/// SF 30 - Amendment of Solicitation/Modification of Contract
public final class SF30Form: BaseGovernmentForm {
    
    // MARK: - Form Sections
    
    public let amendmentInfo: AmendmentInfo
    public let contractInfo: ContractInfo
    public let changes: ChangesSection
    public let contractor: ContractorInfo
    public let administrativeData: AdministrativeData
    
    // MARK: - Initialization
    
    public init(
        revision: String = "REV OCT 2023",
        metadata: FormMetadata,
        amendmentInfo: AmendmentInfo,
        contractInfo: ContractInfo,
        changes: ChangesSection,
        contractor: ContractorInfo,
        administrativeData: AdministrativeData
    ) {
        self.amendmentInfo = amendmentInfo
        self.contractInfo = contractInfo
        self.changes = changes
        self.contractor = contractor
        self.administrativeData = administrativeData
        
        super.init(
            formNumber: "SF30",
            formTitle: "Amendment of Solicitation/Modification of Contract",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2023, month: 10, day: 1).date!,
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }
    
    // MARK: - Validation
    
    public override func validate() throws {
        try super.validate()
        
        // Validate all sections
        try amendmentInfo.validate()
        try contractInfo.validate()
        try changes.validate()
        try contractor.validate()
        try administrativeData.validate()
    }
    
    // MARK: - Export
    
    public override func export() -> [String: Any] {
        var data = super.export()
        
        data["amendmentInfo"] = amendmentInfo.export()
        data["contractInfo"] = contractInfo.export()
        data["changes"] = changes.export()
        data["contractor"] = contractor.export()
        data["administrativeData"] = administrativeData.export()
        
        return data
    }
}

// MARK: - SF30 Sections

/// Amendment/Modification Information
public struct AmendmentInfo: ValueObject {
    public let modificationType: ModificationType
    public let modificationNumber: String
    public let effectiveDate: Date
    public let requisitionNumber: RequisitionNumber?
    public let solicitationNumber: SolicitationNumber?
    public let contractNumber: ContractNumber?
    
    public enum ModificationType: String, CaseIterable {
        case amendmentSolicitation = "AMENDMENT_SOLICITATION"
        case modificationContract = "MODIFICATION_CONTRACT"
    }
    
    public init(
        modificationType: ModificationType,
        modificationNumber: String,
        effectiveDate: Date,
        requisitionNumber: RequisitionNumber? = nil,
        solicitationNumber: SolicitationNumber? = nil,
        contractNumber: ContractNumber? = nil
    ) {
        self.modificationType = modificationType
        self.modificationNumber = modificationNumber
        self.effectiveDate = effectiveDate
        self.requisitionNumber = requisitionNumber
        self.solicitationNumber = solicitationNumber
        self.contractNumber = contractNumber
    }
    
    public func validate() throws {
        guard !modificationNumber.isEmpty else {
            throw FormError.missingRequiredField("modification number")
        }
        
        // Validate that appropriate reference is provided
        switch modificationType {
        case .amendmentSolicitation:
            guard solicitationNumber != nil else {
                throw FormError.validationFailed("Solicitation number required for amendment")
            }
        case .modificationContract:
            guard contractNumber != nil else {
                throw FormError.validationFailed("Contract number required for modification")
            }
        }
    }
    
    func export() -> [String: Any] {
        [
            "modificationType": modificationType.rawValue,
            "modificationNumber": modificationNumber,
            "effectiveDate": effectiveDate.timeIntervalSince1970,
            "requisitionNumber": requisitionNumber?.value as Any,
            "solicitationNumber": solicitationNumber?.value as Any,
            "contractNumber": contractNumber?.value as Any
        ]
    }
}

/// Contract Information
public struct ContractInfo: ValueObject {
    public let originalContractValue: Money?
    public let currentContractValue: Money?
    public let changeAmount: Money?
    public let fundingData: FundingData?
    
    public struct FundingData: ValueObject {
        public let accountingData: String
        public let appropriation: String?
        public let obligatedAmount: Money
        
        public func validate() throws {
            guard !accountingData.isEmpty else {
                throw FormError.missingRequiredField("accounting data")
            }
        }
    }
    
    public init(
        originalContractValue: Money? = nil,
        currentContractValue: Money? = nil,
        changeAmount: Money? = nil,
        fundingData: FundingData? = nil
    ) {
        self.originalContractValue = originalContractValue
        self.currentContractValue = currentContractValue
        self.changeAmount = changeAmount
        self.fundingData = fundingData
    }
    
    public func validate() throws {
        if let fundingData = fundingData {
            try fundingData.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "originalContractValue": originalContractValue?.amount as Any,
            "currentContractValue": currentContractValue?.amount as Any,
            "changeAmount": changeAmount?.amount as Any,
            "currency": currentContractValue?.currency.rawValue as Any,
            "fundingData": fundingData.map { funding in
                [
                    "accountingData": funding.accountingData,
                    "appropriation": funding.appropriation as Any,
                    "obligatedAmount": funding.obligatedAmount.amount
                ]
            } as Any
        ]
    }
}

/// Changes Section
public struct ChangesSection: ValueObject {
    public let modificationPurpose: ModificationPurpose
    public let description: String
    public let changes: [Change]
    public let attachments: [Attachment]
    
    public enum ModificationPurpose: String, CaseIterable {
        case administrativeChange = "ADMINISTRATIVE"
        case supplementalAgreement = "SUPPLEMENTAL_AGREEMENT"
        case changeOrder = "CHANGE_ORDER"
        case terminationPartial = "TERMINATION_PARTIAL"
        case terminationComplete = "TERMINATION_COMPLETE"
        case other = "OTHER"
    }
    
    public struct Change: ValueObject {
        public let type: ChangeType
        public let description: String
        public let oldValue: String?
        public let newValue: String?
        
        public enum ChangeType: String, CaseIterable {
            case deliverySchedule = "DELIVERY_SCHEDULE"
            case quantity = "QUANTITY"
            case unitPrice = "UNIT_PRICE"
            case totalPrice = "TOTAL_PRICE"
            case specification = "SPECIFICATION"
            case terms = "TERMS"
            case other = "OTHER"
        }
        
        public func validate() throws {
            guard !description.isEmpty else {
                throw FormError.missingRequiredField("change description")
            }
        }
    }
    
    public struct Attachment: ValueObject {
        public let title: String
        public let pages: Int
        public let attachmentNumber: String
        
        public func validate() throws {
            guard !title.isEmpty else {
                throw FormError.missingRequiredField("attachment title")
            }
            guard pages > 0 else {
                throw FormError.invalidField("pages - must be positive")
            }
        }
    }
    
    public init(
        modificationPurpose: ModificationPurpose,
        description: String,
        changes: [Change] = [],
        attachments: [Attachment] = []
    ) {
        self.modificationPurpose = modificationPurpose
        self.description = description
        self.changes = changes
        self.attachments = attachments
    }
    
    public func validate() throws {
        guard !description.isEmpty else {
            throw FormError.missingRequiredField("modification description")
        }
        
        for change in changes {
            try change.validate()
        }
        
        for attachment in attachments {
            try attachment.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "modificationPurpose": modificationPurpose.rawValue,
            "description": description,
            "changes": changes.map { change in
                [
                    "type": change.type.rawValue,
                    "description": change.description,
                    "oldValue": change.oldValue as Any,
                    "newValue": change.newValue as Any
                ]
            },
            "attachments": attachments.map { attachment in
                [
                    "title": attachment.title,
                    "pages": attachment.pages,
                    "attachmentNumber": attachment.attachmentNumber
                ]
            }
        ]
    }
}

/// Contractor Information
public struct ContractorInfo: ValueObject {
    public let name: String
    public let address: PostalAddress
    public let cageCode: CageCode?
    public let dunsNumber: DUNSNumber?
    public let acknowledgment: Acknowledgment?
    
    public struct Acknowledgment: ValueObject {
        public let acknowledgedBy: String
        public let title: String
        public let acknowledgedDate: Date
        public let signature: String? // Base64 encoded
        
        public func validate() throws {
            guard !acknowledgedBy.isEmpty else {
                throw FormError.missingRequiredField("acknowledged by")
            }
        }
    }
    
    public init(
        name: String,
        address: PostalAddress,
        cageCode: CageCode? = nil,
        dunsNumber: DUNSNumber? = nil,
        acknowledgment: Acknowledgment? = nil
    ) {
        self.name = name
        self.address = address
        self.cageCode = cageCode
        self.dunsNumber = dunsNumber
        self.acknowledgment = acknowledgment
    }
    
    public func validate() throws {
        guard !name.isEmpty else {
            throw FormError.missingRequiredField("contractor name")
        }
        
        if let acknowledgment = acknowledgment {
            try acknowledgment.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "name": name,
            "address": address.formatted,
            "cageCode": cageCode?.value as Any,
            "dunsNumber": dunsNumber?.value as Any,
            "acknowledgment": acknowledgment.map { ack in
                [
                    "acknowledgedBy": ack.acknowledgedBy,
                    "title": ack.title,
                    "acknowledgedDate": ack.acknowledgedDate.timeIntervalSince1970,
                    "signature": ack.signature as Any
                ]
            } as Any
        ]
    }
}

/// Administrative Data
public struct AdministrativeData: ValueObject {
    public let contractingOfficer: ContractingOfficerData
    public let contractAdministration: ContractAdministration?
    
    public struct ContractingOfficerData: ValueObject {
        public let name: String
        public let title: String
        public let phoneNumber: PhoneNumber
        public let email: Email
        public let signature: String? // Base64 encoded
        public let signatureDate: Date?
        
        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("contracting officer name")
            }
        }
    }
    
    public struct ContractAdministration: ValueObject {
        public let office: String
        public let address: PostalAddress
        public let administrator: String
        
        public func validate() throws {
            guard !office.isEmpty else {
                throw FormError.missingRequiredField("administration office")
            }
        }
    }
    
    public init(
        contractingOfficer: ContractingOfficerData,
        contractAdministration: ContractAdministration? = nil
    ) {
        self.contractingOfficer = contractingOfficer
        self.contractAdministration = contractAdministration
    }
    
    public func validate() throws {
        try contractingOfficer.validate()
        
        if let contractAdministration = contractAdministration {
            try contractAdministration.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "contractingOfficer": [
                "name": contractingOfficer.name,
                "title": contractingOfficer.title,
                "phoneNumber": contractingOfficer.phoneNumber.value,
                "email": contractingOfficer.email.value,
                "signature": contractingOfficer.signature as Any,
                "signatureDate": contractingOfficer.signatureDate?.timeIntervalSince1970 as Any
            ],
            "contractAdministration": contractAdministration.map { admin in
                [
                    "office": admin.office,
                    "address": admin.address.formatted,
                    "administrator": admin.administrator
                ]
            } as Any
        ]
    }
}

// MARK: - SF30 Factory

public final class SF30Factory: BaseFormFactory<SF30Form> {
    
    public override func createBlank() -> SF30Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "GSA",
            purpose: "Contract modification"
        )
        
        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )
        
        return SF30Form(
            metadata: metadata,
            amendmentInfo: AmendmentInfo(
                modificationType: .modificationContract,
                modificationNumber: "P00001",
                effectiveDate: Date()
            ),
            contractInfo: ContractInfo(),
            changes: ChangesSection(
                modificationPurpose: .administrativeChange,
                description: ""
            ),
            contractor: ContractorInfo(
                name: "",
                address: emptyAddress
            ),
            administrativeData: AdministrativeData(
                contractingOfficer: AdministrativeData.ContractingOfficerData(
                    name: "",
                    title: "",
                    phoneNumber: try! PhoneNumber("000-000-0000"),
                    email: try! Email("placeholder@example.com"),
                    signature: nil,
                    signatureDate: nil
                )
            )
        )
    }
    
    public override func createForm(with data: FormData) throws -> SF30Form {
        let metadata = data.metadata
        
        // Extract and validate fields
        let amendmentInfo = try createAmendmentInfo(from: data.fields)
        let contractInfo = try createContractInfo(from: data.fields)
        let changes = try createChangesSection(from: data.fields)
        let contractor = try createContractorInfo(from: data.fields)
        let administrativeData = try createAdministrativeData(from: data.fields)
        
        return SF30Form(
            revision: data.revision ?? "REV OCT 2023",
            metadata: metadata,
            amendmentInfo: amendmentInfo,
            contractInfo: contractInfo,
            changes: changes,
            contractor: contractor,
            administrativeData: administrativeData
        )
    }
    
    // Helper methods for creating sections
    private func createAmendmentInfo(from fields: [String: Any]) throws -> AmendmentInfo {
        let modificationType = AmendmentInfo.ModificationType(
            rawValue: fields["modificationType"] as? String ?? "MODIFICATION_CONTRACT"
        ) ?? .modificationContract
        
        return AmendmentInfo(
            modificationType: modificationType,
            modificationNumber: fields["modificationNumber"] as? String ?? "P00001",
            effectiveDate: fields["effectiveDate"] as? Date ?? Date()
        )
    }
    
    private func createContractInfo(from fields: [String: Any]) throws -> ContractInfo {
        ContractInfo()
    }
    
    private func createChangesSection(from fields: [String: Any]) throws -> ChangesSection {
        ChangesSection(
            modificationPurpose: .administrativeChange,
            description: fields["changeDescription"] as? String ?? ""
        )
    }
    
    private func createContractorInfo(from fields: [String: Any]) throws -> ContractorInfo {
        let address = try PostalAddress(
            street: fields["contractorStreet"] as? String ?? "TBD",
            city: fields["contractorCity"] as? String ?? "TBD",
            state: fields["contractorState"] as? String ?? "TBD",
            zipCode: fields["contractorZip"] as? String ?? "00000"
        )
        
        return ContractorInfo(
            name: fields["contractorName"] as? String ?? "",
            address: address
        )
    }
    
    private func createAdministrativeData(from fields: [String: Any]) throws -> AdministrativeData {
        let officer = AdministrativeData.ContractingOfficerData(
            name: fields["coName"] as? String ?? "",
            title: fields["coTitle"] as? String ?? "",
            phoneNumber: try PhoneNumber(fields["coPhone"] as? String ?? "000-000-0000"),
            email: try Email(fields["coEmail"] as? String ?? "placeholder@example.com"),
            signature: nil,
            signatureDate: nil
        )
        
        return AdministrativeData(contractingOfficer: officer)
    }
}
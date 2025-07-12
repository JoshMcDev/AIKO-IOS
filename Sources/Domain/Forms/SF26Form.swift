import Foundation

/// SF 26 - Award/Contract
public final class SF26Form: BaseGovernmentForm {
    
    // MARK: - Form Sections
    
    public let contractInfo: ContractInformation
    public let vendorInfo: VendorInformation
    public let supplies: SuppliesSection
    public let accounting: AccountingSection
    public let signatures: SignatureSection
    
    // MARK: - Initialization
    
    public init(
        revision: String = "REV APR 2018",
        metadata: FormMetadata,
        contractInfo: ContractInformation,
        vendorInfo: VendorInformation,
        supplies: SuppliesSection,
        accounting: AccountingSection,
        signatures: SignatureSection
    ) {
        self.contractInfo = contractInfo
        self.vendorInfo = vendorInfo
        self.supplies = supplies
        self.accounting = accounting
        self.signatures = signatures
        
        super.init(
            formNumber: "SF26",
            formTitle: "Award/Contract",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2018, month: 4, day: 1).date!,
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }
    
    // MARK: - Validation
    
    public override func validate() throws {
        try super.validate()
        
        // Validate all sections
        try contractInfo.validate()
        try vendorInfo.validate()
        try supplies.validate()
        try accounting.validate()
        try signatures.validate()
    }
    
    // MARK: - Export
    
    public override func export() -> [String: Any] {
        var data = super.export()
        
        data["contractInfo"] = contractInfo.export()
        data["vendorInfo"] = vendorInfo.export()
        data["supplies"] = supplies.export()
        data["accounting"] = accounting.export()
        data["signatures"] = signatures.export()
        
        return data
    }
}

// MARK: - SF26 Sections

/// Contract Information
public struct ContractInformation: ValueObject {
    public let contractNumber: ContractNumber
    public let awardDate: Date
    public let requisitionNumber: RequisitionNumber?
    public let solicitationNumber: SolicitationNumber?
    public let contractType: ContractType
    public let totalAmount: Money
    
    public enum ContractType: String, CaseIterable {
        case firmFixedPrice = "FFP"
        case costPlusFixedFee = "CPFF"
        case costPlusIncentiveFee = "CPIF"
        case costPlusAwardFee = "CPAF"
        case timeAndMaterials = "T&M"
        case laborHour = "LH"
        case indefiniteDelivery = "IDIQ"
    }
    
    public init(
        contractNumber: ContractNumber,
        awardDate: Date,
        requisitionNumber: RequisitionNumber? = nil,
        solicitationNumber: SolicitationNumber? = nil,
        contractType: ContractType,
        totalAmount: Money
    ) {
        self.contractNumber = contractNumber
        self.awardDate = awardDate
        self.requisitionNumber = requisitionNumber
        self.solicitationNumber = solicitationNumber
        self.contractType = contractType
        self.totalAmount = totalAmount
    }
    
    public func validate() throws {
        // No additional validation needed - value objects validate themselves
    }
    
    func export() -> [String: Any] {
        [
            "contractNumber": contractNumber.value,
            "awardDate": awardDate.timeIntervalSince1970,
            "requisitionNumber": requisitionNumber?.value as Any,
            "solicitationNumber": solicitationNumber?.value as Any,
            "contractType": contractType.rawValue,
            "totalAmount": totalAmount.amount,
            "currency": totalAmount.currency.rawValue
        ]
    }
}

/// Vendor Information
public struct VendorInformation: ValueObject {
    public let name: String
    public let address: PostalAddress
    public let cageCode: CageCode
    public let dunsNumber: DUNSNumber?
    public let taxId: String
    public let smallBusinessPrograms: [SmallBusinessProgram]
    
    public enum SmallBusinessProgram: String, CaseIterable {
        case smallBusiness = "SB"
        case womenOwned = "WOSB"
        case veteranOwned = "VOSB"
        case serviceDisabledVeteran = "SDVOSB"
        case hubZone = "HUBZone"
        case section8a = "8(a)"
        case historicallyBlackCollege = "HBCU"
        case minorityInstitution = "MI"
    }
    
    public init(
        name: String,
        address: PostalAddress,
        cageCode: CageCode,
        dunsNumber: DUNSNumber? = nil,
        taxId: String,
        smallBusinessPrograms: [SmallBusinessProgram] = []
    ) {
        self.name = name
        self.address = address
        self.cageCode = cageCode
        self.dunsNumber = dunsNumber
        self.taxId = taxId
        self.smallBusinessPrograms = smallBusinessPrograms
    }
    
    public func validate() throws {
        guard !name.isEmpty else {
            throw FormError.missingRequiredField("vendor name")
        }
        
        guard !taxId.isEmpty else {
            throw FormError.missingRequiredField("tax ID")
        }
    }
    
    func export() -> [String: Any] {
        [
            "name": name,
            "address": address.formatted,
            "cageCode": cageCode.value,
            "dunsNumber": dunsNumber?.value as Any,
            "taxId": taxId,
            "smallBusinessPrograms": smallBusinessPrograms.map { $0.rawValue }
        ]
    }
}

/// Supplies/Services Section
public struct SuppliesSection: ValueObject {
    public let items: [ContractLineItem]
    public let performancePeriod: DateRange
    public let placeOfPerformance: PlaceOfPerformance
    
    public struct ContractLineItem: ValueObject {
        public let clin: String
        public let description: String
        public let quantity: Decimal
        public let unit: String
        public let unitPrice: Money
        public let totalPrice: Money
        public let naicsCode: FormNAICSCode?
        public let psc: String? // Product Service Code
        
        public init(
            clin: String,
            description: String,
            quantity: Decimal,
            unit: String,
            unitPrice: Money,
            totalPrice: Money,
            naicsCode: FormNAICSCode? = nil,
            psc: String? = nil
        ) {
            self.clin = clin
            self.description = description
            self.quantity = quantity
            self.unit = unit
            self.unitPrice = unitPrice
            self.totalPrice = totalPrice
            self.naicsCode = naicsCode
            self.psc = psc
        }
        
        public func validate() throws {
            guard !clin.isEmpty else {
                throw FormError.missingRequiredField("CLIN")
            }
            
            guard !description.isEmpty else {
                throw FormError.missingRequiredField("description")
            }
            
            guard quantity > 0 else {
                throw FormError.invalidField("quantity - must be positive")
            }
            
            // Validate total = quantity * unit price
            let calculatedTotal = quantity * unitPrice.amount
            guard abs(calculatedTotal - totalPrice.amount) < 0.01 else {
                throw FormError.validationFailed("Total price does not match quantity × unit price")
            }
        }
    }
    
    public init(
        items: [ContractLineItem],
        performancePeriod: DateRange,
        placeOfPerformance: PlaceOfPerformance
    ) {
        self.items = items
        self.performancePeriod = performancePeriod
        self.placeOfPerformance = placeOfPerformance
    }
    
    public func validate() throws {
        guard !items.isEmpty else {
            throw FormError.validationFailed("At least one line item is required")
        }
        
        for item in items {
            try item.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "items": items.map { item in
                [
                    "clin": item.clin,
                    "description": item.description,
                    "quantity": item.quantity,
                    "unit": item.unit,
                    "unitPrice": item.unitPrice.amount,
                    "totalPrice": item.totalPrice.amount,
                    "naicsCode": item.naicsCode?.value as Any,
                    "psc": item.psc as Any
                ]
            },
            "performancePeriod": [
                "startDate": performancePeriod.startDate.timeIntervalSince1970,
                "endDate": performancePeriod.endDate.timeIntervalSince1970
            ],
            "placeOfPerformance": [
                "address": placeOfPerformance.address.formatted,
                "countryCode": placeOfPerformance.countryCode,
                "principalPlaceCode": placeOfPerformance.principalPlaceCode as Any
            ]
        ]
    }
}

/// Accounting and Appropriation Data
public struct AccountingSection: ValueObject {
    public let accountingClassification: String
    public let appropriation: String
    public let objectClass: String?
    public let stationNumber: String?
    public let obligation: Money
    
    public init(
        accountingClassification: String,
        appropriation: String,
        objectClass: String? = nil,
        stationNumber: String? = nil,
        obligation: Money
    ) {
        self.accountingClassification = accountingClassification
        self.appropriation = appropriation
        self.objectClass = objectClass
        self.stationNumber = stationNumber
        self.obligation = obligation
    }
    
    public func validate() throws {
        guard !accountingClassification.isEmpty else {
            throw FormError.missingRequiredField("accounting classification")
        }
        
        guard !appropriation.isEmpty else {
            throw FormError.missingRequiredField("appropriation")
        }
    }
    
    func export() -> [String: Any] {
        [
            "accountingClassification": accountingClassification,
            "appropriation": appropriation,
            "objectClass": objectClass as Any,
            "stationNumber": stationNumber as Any,
            "obligation": obligation.amount,
            "currency": obligation.currency.rawValue
        ]
    }
}

/// Signature Section
public struct SignatureSection: ValueObject {
    public let contractingOfficer: SignatureBlock
    public let vendor: SignatureBlock?
    
    public struct SignatureBlock: ValueObject {
        public let name: String
        public let title: String
        public let signature: String? // Base64 encoded
        public let signatureDate: Date?
        
        public init(
            name: String,
            title: String,
            signature: String? = nil,
            signatureDate: Date? = nil
        ) {
            self.name = name
            self.title = title
            self.signature = signature
            self.signatureDate = signatureDate
        }
        
        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("name")
            }
            
            guard !title.isEmpty else {
                throw FormError.missingRequiredField("title")
            }
        }
    }
    
    public init(
        contractingOfficer: SignatureBlock,
        vendor: SignatureBlock? = nil
    ) {
        self.contractingOfficer = contractingOfficer
        self.vendor = vendor
    }
    
    public func validate() throws {
        try contractingOfficer.validate()
        
        if let vendor = vendor {
            try vendor.validate()
        }
    }
    
    func export() -> [String: Any] {
        [
            "contractingOfficer": [
                "name": contractingOfficer.name,
                "title": contractingOfficer.title,
                "signature": contractingOfficer.signature as Any,
                "signatureDate": contractingOfficer.signatureDate?.timeIntervalSince1970 as Any
            ],
            "vendor": vendor.map { v in
                [
                    "name": v.name,
                    "title": v.title,
                    "signature": v.signature as Any,
                    "signatureDate": v.signatureDate?.timeIntervalSince1970 as Any
                ]
            } as Any
        ]
    }
}

// MARK: - SF26 Factory

public final class SF26Factory: BaseFormFactory<SF26Form> {
    
    public override func createBlank() -> SF26Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "GSA",
            purpose: "Contract award"
        )
        
        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )
        
        return SF26Form(
            metadata: metadata,
            contractInfo: ContractInformation(
                contractNumber: try! ContractNumber("TBD-00000"),
                awardDate: Date(),
                contractType: .firmFixedPrice,
                totalAmount: try! Money(amount: 0, currency: .usd)
            ),
            vendorInfo: VendorInformation(
                name: "",
                address: emptyAddress,
                cageCode: try! CageCode("00000"),
                taxId: ""
            ),
            supplies: SuppliesSection(
                items: [],
                performancePeriod: try! DateRange(
                    from: Date(),
                    to: Date().addingTimeInterval(365 * 24 * 60 * 60)
                ),
                placeOfPerformance: try! PlaceOfPerformance(
                    address: emptyAddress,
                    countryCode: "US"
                )
            ),
            accounting: AccountingSection(
                accountingClassification: "",
                appropriation: "",
                obligation: try! Money(amount: 0, currency: .usd)
            ),
            signatures: SignatureSection(
                contractingOfficer: SignatureSection.SignatureBlock(
                    name: "",
                    title: ""
                )
            )
        )
    }
    
    public override func createForm(with data: FormData) throws -> SF26Form {
        let metadata = data.metadata
        
        // Extract and validate fields
        let contractInfo = try createContractInfo(from: data.fields)
        let vendorInfo = try createVendorInfo(from: data.fields)
        let supplies = try createSuppliesSection(from: data.fields)
        let accounting = try createAccountingSection(from: data.fields)
        let signatures = try createSignatureSection(from: data.fields)
        
        return SF26Form(
            revision: data.revision ?? "REV APR 2018",
            metadata: metadata,
            contractInfo: contractInfo,
            vendorInfo: vendorInfo,
            supplies: supplies,
            accounting: accounting,
            signatures: signatures
        )
    }
    
    // Helper methods for creating sections
    private func createContractInfo(from fields: [String: Any]) throws -> ContractInformation {
        guard let contractNum = fields["contractNumber"] as? String else {
            throw FormError.missingRequiredField("contractNumber")
        }
        
        let contractNumber = try ContractNumber(contractNum)
        let awardDate = fields["awardDate"] as? Date ?? Date()
        let contractType = ContractInformation.ContractType(
            rawValue: fields["contractType"] as? String ?? "FFP"
        ) ?? .firmFixedPrice
        let totalAmount = try Money(
            amount: fields["totalAmount"] as? Decimal ?? 0,
            currency: .usd
        )
        
        return ContractInformation(
            contractNumber: contractNumber,
            awardDate: awardDate,
            contractType: contractType,
            totalAmount: totalAmount
        )
    }
    
    private func createVendorInfo(from fields: [String: Any]) throws -> VendorInformation {
        let address = try PostalAddress(
            street: fields["vendorStreet"] as? String ?? "TBD",
            city: fields["vendorCity"] as? String ?? "TBD",
            state: fields["vendorState"] as? String ?? "TBD",
            zipCode: fields["vendorZip"] as? String ?? "00000"
        )
        
        return VendorInformation(
            name: fields["vendorName"] as? String ?? "",
            address: address,
            cageCode: try CageCode(fields["cageCode"] as? String ?? "00000"),
            taxId: fields["taxId"] as? String ?? ""
        )
    }
    
    private func createSuppliesSection(from fields: [String: Any]) throws -> SuppliesSection {
        let popAddress = try PostalAddress(
            street: fields["popStreet"] as? String ?? "TBD",
            city: fields["popCity"] as? String ?? "TBD",
            state: fields["popState"] as? String ?? "TBD",
            zipCode: fields["popZip"] as? String ?? "00000"
        )
        
        return SuppliesSection(
            items: [],
            performancePeriod: try DateRange(
                from: fields["startDate"] as? Date ?? Date(),
                to: fields["endDate"] as? Date ?? Date().addingTimeInterval(365 * 24 * 60 * 60)
            ),
            placeOfPerformance: try PlaceOfPerformance(
                address: popAddress,
                countryCode: "US"
            )
        )
    }
    
    private func createAccountingSection(from fields: [String: Any]) throws -> AccountingSection {
        AccountingSection(
            accountingClassification: fields["accountingClass"] as? String ?? "",
            appropriation: fields["appropriation"] as? String ?? "",
            obligation: try Money(
                amount: fields["obligation"] as? Decimal ?? 0,
                currency: .usd
            )
        )
    }
    
    private func createSignatureSection(from fields: [String: Any]) throws -> SignatureSection {
        SignatureSection(
            contractingOfficer: SignatureSection.SignatureBlock(
                name: fields["coName"] as? String ?? "",
                title: fields["coTitle"] as? String ?? ""
            )
        )
    }
}
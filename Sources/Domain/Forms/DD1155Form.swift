import Foundation

/// DD Form 1155 - Order for Supplies or Services
public final class DD1155Form: BaseGovernmentForm {
    // MARK: - Form Sections

    public let orderInfo: OrderInformation
    public let contractor: ContractorInformation
    public let deliveryInfo: DD1155DeliveryInformation
    public let itemsOrdered: ItemsOrderedSection
    public let accounting: AccountingData
    public let authorization: AuthorizationSection

    // MARK: - Initialization

    public init(
        revision: String = "JUN 2022",
        metadata: FormMetadata,
        orderInfo: OrderInformation,
        contractor: ContractorInformation,
        deliveryInfo: DD1155DeliveryInformation,
        itemsOrdered: ItemsOrderedSection,
        accounting: AccountingData,
        authorization: AuthorizationSection
    ) {
        self.orderInfo = orderInfo
        self.contractor = contractor
        self.deliveryInfo = deliveryInfo
        self.itemsOrdered = itemsOrdered
        self.accounting = accounting
        self.authorization = authorization

        super.init(
            formNumber: "DD1155",
            formTitle: "Order for Supplies or Services",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2022, month: 6, day: 1).date ?? Date(),
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }

    // MARK: - Validation

    override public func validate() throws {
        try super.validate()

        // Validate all sections
        try orderInfo.validate()
        try contractor.validate()
        try deliveryInfo.validate()
        try itemsOrdered.validate()
        try accounting.validate()
        try authorization.validate()
    }

    // MARK: - Export

    override public func export() -> [String: Any] {
        var data = super.export()

        data["orderInfo"] = orderInfo.export()
        data["contractor"] = contractor.export()
        data["deliveryInfo"] = deliveryInfo.export()
        data["itemsOrdered"] = itemsOrdered.export()
        data["accounting"] = accounting.export()
        data["authorization"] = authorization.export()

        return data
    }
}

// MARK: - DD1155 Sections

/// Order Information
public struct OrderInformation: ValueObject {
    public let orderNumber: String
    public let callOrderNumber: DeliveryOrderNumber?
    public let orderDate: Date
    public let requisitionNumber: RequisitionNumber
    public let priorityRating: PriorityRating?
    public let contractNumber: ContractNumber?
    public let modificationNumber: String?
    public let issuingOffice: IssuingOfficeInfo

    public enum PriorityRating: String, CaseIterable {
        case dxHighest = "DX"
        case doUrgent = "DO"
        case normal = "NORMAL"
    }

    public struct IssuingOfficeInfo: ValueObject {
        public let name: String
        public let code: String
        public let address: PostalAddress
        public let dodaac: String? // Department of Defense Activity Address Code

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("issuing office name")
            }
            guard !code.isEmpty else {
                throw FormError.missingRequiredField("issuing office code")
            }
            if let dodaac {
                guard dodaac.count == 6 else {
                    throw FormError.invalidField("DODAAC must be 6 characters")
                }
            }
        }
    }

    public init(
        orderNumber: String,
        callOrderNumber: DeliveryOrderNumber? = nil,
        orderDate: Date,
        requisitionNumber: RequisitionNumber,
        priorityRating: PriorityRating? = nil,
        contractNumber: ContractNumber? = nil,
        modificationNumber: String? = nil,
        issuingOffice: IssuingOfficeInfo
    ) {
        self.orderNumber = orderNumber
        self.callOrderNumber = callOrderNumber
        self.orderDate = orderDate
        self.requisitionNumber = requisitionNumber
        self.priorityRating = priorityRating
        self.contractNumber = contractNumber
        self.modificationNumber = modificationNumber
        self.issuingOffice = issuingOffice
    }

    public func validate() throws {
        guard !orderNumber.isEmpty else {
            throw FormError.missingRequiredField("order number")
        }
        try issuingOffice.validate()
    }

    func export() -> [String: Any] {
        [
            "orderNumber": orderNumber,
            "callOrderNumber": callOrderNumber?.value as Any,
            "orderDate": orderDate.timeIntervalSince1970,
            "requisitionNumber": requisitionNumber.value,
            "priorityRating": priorityRating?.rawValue as Any,
            "contractNumber": contractNumber?.value as Any,
            "modificationNumber": modificationNumber as Any,
            "issuingOffice": [
                "name": issuingOffice.name,
                "code": issuingOffice.code,
                "address": issuingOffice.address.formatted,
                "dodaac": issuingOffice.dodaac as Any,
            ],
        ]
    }
}

/// Contractor Information
public struct ContractorInformation: ValueObject {
    public let name: String
    public let address: PostalAddress
    public let cageCode: CageCode
    public let taxId: String?
    public let phoneNumber: PhoneNumber
    public let contactPerson: String?
    public let email: Email?

    public init(
        name: String,
        address: PostalAddress,
        cageCode: CageCode,
        taxId: String? = nil,
        phoneNumber: PhoneNumber,
        contactPerson: String? = nil,
        email: Email? = nil
    ) {
        self.name = name
        self.address = address
        self.cageCode = cageCode
        self.taxId = taxId
        self.phoneNumber = phoneNumber
        self.contactPerson = contactPerson
        self.email = email
    }

    public func validate() throws {
        guard !name.isEmpty else {
            throw FormError.missingRequiredField("contractor name")
        }
    }

    func export() -> [String: Any] {
        [
            "name": name,
            "address": address.formatted,
            "cageCode": cageCode.value,
            "taxId": taxId as Any,
            "phoneNumber": phoneNumber.value,
            "contactPerson": contactPerson as Any,
            "email": email?.value as Any,
        ]
    }
}

/// Delivery Information
public struct DD1155DeliveryInformation: ValueObject {
    public let fobPoint: FOBPoint
    public let deliveryDate: Date?
    public let deliveryDays: Int?
    public let shipTo: ShipToAddress
    public let markFor: String?
    public let shippingInstructions: String?

    public enum FOBPoint: String, CaseIterable {
        case origin = "ORIGIN"
        case destination = "DESTINATION"
        case other = "OTHER"
    }

    public struct ShipToAddress: ValueObject {
        public let code: String
        public let address: PostalAddress
        public let dodaac: String?

        public func validate() throws {
            guard !code.isEmpty else {
                throw FormError.missingRequiredField("ship to code")
            }
        }
    }

    public init(
        fobPoint: FOBPoint,
        deliveryDate: Date? = nil,
        deliveryDays: Int? = nil,
        shipTo: ShipToAddress,
        markFor: String? = nil,
        shippingInstructions: String? = nil
    ) {
        self.fobPoint = fobPoint
        self.deliveryDate = deliveryDate
        self.deliveryDays = deliveryDays
        self.shipTo = shipTo
        self.markFor = markFor
        self.shippingInstructions = shippingInstructions
    }

    public func validate() throws {
        // Either delivery date or days must be specified
        if deliveryDate == nil, deliveryDays == nil {
            throw FormError.validationFailed("Either delivery date or delivery days must be specified")
        }
        try shipTo.validate()
    }

    func export() -> [String: Any] {
        [
            "fobPoint": fobPoint.rawValue,
            "deliveryDate": deliveryDate?.timeIntervalSince1970 as Any,
            "deliveryDays": deliveryDays as Any,
            "shipTo": [
                "code": shipTo.code,
                "address": shipTo.address.formatted,
                "dodaac": shipTo.dodaac as Any,
            ],
            "markFor": markFor as Any,
            "shippingInstructions": shippingInstructions as Any,
        ]
    }
}

/// Items Ordered Section
public struct ItemsOrderedSection: ValueObject {
    public let items: [OrderedItem]
    public let totalAmount: Money
    public let discount: DiscountTerms?

    public struct OrderedItem: ValueObject {
        public let itemNumber: String
        public let stockNumber: String?
        public let description: String
        public let quantity: Decimal
        public let unit: String
        public let unitPrice: Money
        public let amount: Money

        public init(
            itemNumber: String,
            stockNumber: String? = nil,
            description: String,
            quantity: Decimal,
            unit: String,
            unitPrice: Money,
            amount: Money
        ) {
            self.itemNumber = itemNumber
            self.stockNumber = stockNumber
            self.description = description
            self.quantity = quantity
            self.unit = unit
            self.unitPrice = unitPrice
            self.amount = amount
        }

        public func validate() throws {
            guard !itemNumber.isEmpty else {
                throw FormError.missingRequiredField("item number")
            }

            guard !description.isEmpty else {
                throw FormError.missingRequiredField("description")
            }

            guard quantity > 0 else {
                throw FormError.invalidField("quantity - must be positive")
            }

            // Validate amount
            let calculatedAmount = quantity * unitPrice.amount
            guard abs(calculatedAmount - amount.amount) < 0.01 else {
                throw FormError.validationFailed("Amount does not match quantity × unit price")
            }
        }
    }

    public struct DiscountTerms: ValueObject {
        public let percentage: Percentage
        public let netDays: Int

        public func validate() throws {
            guard netDays > 0 else {
                throw FormError.invalidField("net days - must be positive")
            }
        }
    }

    public init(
        items: [OrderedItem],
        totalAmount: Money,
        discount: DiscountTerms? = nil
    ) {
        self.items = items
        self.totalAmount = totalAmount
        self.discount = discount
    }

    public func validate() throws {
        guard !items.isEmpty else {
            throw FormError.validationFailed("At least one item must be ordered")
        }

        for item in items {
            try item.validate()
        }

        if let discount {
            try discount.validate()
        }

        // Validate total
        let calculatedTotal = items.reduce(Decimal(0)) { $0 + $1.amount.amount }
        guard abs(calculatedTotal - totalAmount.amount) < 0.01 else {
            throw FormError.validationFailed("Total amount does not match sum of items")
        }
    }

    func export() -> [String: Any] {
        [
            "items": items.map { item in
                [
                    "itemNumber": item.itemNumber,
                    "stockNumber": item.stockNumber as Any,
                    "description": item.description,
                    "quantity": item.quantity,
                    "unit": item.unit,
                    "unitPrice": item.unitPrice.amount,
                    "amount": item.amount.amount,
                ]
            },
            "totalAmount": totalAmount.amount,
            "currency": totalAmount.currency.rawValue,
            "discount": discount.map { d in
                [
                    "percentage": d.percentage.value,
                    "netDays": d.netDays,
                ]
            } as Any,
        ]
    }
}

/// Accounting Data
public struct AccountingData: ValueObject {
    public let appropriation: String
    public let objectClass: String
    public let subObjectClass: String?
    public let jobOrderNumber: String?
    public let projectCode: String?
    public let workUnitCode: String?
    public let costCenterCode: String?

    public init(
        appropriation: String,
        objectClass: String,
        subObjectClass: String? = nil,
        jobOrderNumber: String? = nil,
        projectCode: String? = nil,
        workUnitCode: String? = nil,
        costCenterCode: String? = nil
    ) {
        self.appropriation = appropriation
        self.objectClass = objectClass
        self.subObjectClass = subObjectClass
        self.jobOrderNumber = jobOrderNumber
        self.projectCode = projectCode
        self.workUnitCode = workUnitCode
        self.costCenterCode = costCenterCode
    }

    public func validate() throws {
        guard !appropriation.isEmpty else {
            throw FormError.missingRequiredField("appropriation")
        }

        guard !objectClass.isEmpty else {
            throw FormError.missingRequiredField("object class")
        }
    }

    func export() -> [String: Any] {
        [
            "appropriation": appropriation,
            "objectClass": objectClass,
            "subObjectClass": subObjectClass as Any,
            "jobOrderNumber": jobOrderNumber as Any,
            "projectCode": projectCode as Any,
            "workUnitCode": workUnitCode as Any,
            "costCenterCode": costCenterCode as Any,
        ]
    }
}

/// Authorization Section
public struct AuthorizationSection: ValueObject {
    public let authorizedBy: AuthorizedOfficial
    public let contractingOfficer: ContractingOfficerInfo?

    public struct AuthorizedOfficial: ValueObject {
        public let name: String
        public let title: String
        public let signature: String? // Base64 encoded
        public let signatureDate: Date?

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("authorized official name")
            }

            guard !title.isEmpty else {
                throw FormError.missingRequiredField("authorized official title")
            }
        }
    }

    public struct ContractingOfficerInfo: ValueObject {
        public let name: String
        public let phoneNumber: PhoneNumber

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("contracting officer name")
            }
        }
    }

    public init(
        authorizedBy: AuthorizedOfficial,
        contractingOfficer: ContractingOfficerInfo? = nil
    ) {
        self.authorizedBy = authorizedBy
        self.contractingOfficer = contractingOfficer
    }

    public func validate() throws {
        try authorizedBy.validate()

        if let contractingOfficer {
            try contractingOfficer.validate()
        }
    }

    func export() -> [String: Any] {
        [
            "authorizedBy": [
                "name": authorizedBy.name,
                "title": authorizedBy.title,
                "signature": authorizedBy.signature as Any,
                "signatureDate": authorizedBy.signatureDate?.timeIntervalSince1970 as Any,
            ],
            "contractingOfficer": contractingOfficer.map { co in
                [
                    "name": co.name,
                    "phoneNumber": co.phoneNumber.value,
                ]
            } as Any,
        ]
    }
}

// MARK: - DD1155 Factory

public final class DD1155Factory: BaseFormFactory<DD1155Form> {
    override public func createBlank() -> DD1155Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "DoD",
            purpose: "Order for supplies or services"
        )

        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )

        return DD1155Form(
            metadata: metadata,
            orderInfo: OrderInformation(
                orderNumber: "ORDER-00000",
                orderDate: Date(),
                requisitionNumber: try! RequisitionNumber("REQ-00000"),
                issuingOffice: OrderInformation.IssuingOfficeInfo(
                    name: "",
                    code: "",
                    address: emptyAddress,
                    dodaac: nil
                )
            ),
            contractor: ContractorInformation(
                name: "",
                address: emptyAddress,
                cageCode: try! CageCode("00000"),
                phoneNumber: try! PhoneNumber("000-000-0000")
            ),
            deliveryInfo: DD1155DeliveryInformation(
                fobPoint: .destination,
                shipTo: DD1155DeliveryInformation.ShipToAddress(
                    code: "",
                    address: emptyAddress,
                    dodaac: nil
                )
            ),
            itemsOrdered: ItemsOrderedSection(
                items: [],
                totalAmount: try! Money(amount: 0, currency: .usd)
            ),
            accounting: AccountingData(
                appropriation: "",
                objectClass: ""
            ),
            authorization: AuthorizationSection(
                authorizedBy: AuthorizationSection.AuthorizedOfficial(
                    name: "",
                    title: "",
                    signature: nil,
                    signatureDate: nil
                )
            )
        )
    }

    override public func createForm(with data: FormData) throws -> DD1155Form {
        let metadata = data.metadata

        // Extract and validate fields
        let orderInfo = try createOrderInfo(from: data.fields)
        let contractor = try createContractorInfo(from: data.fields)
        let deliveryInfo = try createDeliveryInfo(from: data.fields)
        let itemsOrdered = try createItemsOrderedSection(from: data.fields)
        let accounting = try createAccountingData(from: data.fields)
        let authorization = try createAuthorizationSection(from: data.fields)

        return DD1155Form(
            revision: data.revision ?? "JUN 2022",
            metadata: metadata,
            orderInfo: orderInfo,
            contractor: contractor,
            deliveryInfo: deliveryInfo,
            itemsOrdered: itemsOrdered,
            accounting: accounting,
            authorization: authorization
        )
    }

    // Helper methods for creating sections
    private func createOrderInfo(from fields: [String: Any]) throws -> OrderInformation {
        let officeAddress = try PostalAddress(
            street: fields["officeStreet"] as? String ?? "TBD",
            city: fields["officeCity"] as? String ?? "TBD",
            state: fields["officeState"] as? String ?? "TBD",
            zipCode: fields["officeZip"] as? String ?? "00000"
        )

        let office = OrderInformation.IssuingOfficeInfo(
            name: fields["officeName"] as? String ?? "",
            code: fields["officeCode"] as? String ?? "",
            address: officeAddress,
            dodaac: fields["dodaac"] as? String
        )

        return try OrderInformation(
            orderNumber: fields["orderNumber"] as? String ?? "ORDER-00000",
            orderDate: fields["orderDate"] as? Date ?? Date(),
            requisitionNumber: RequisitionNumber(fields["requisitionNumber"] as? String ?? "REQ-00000"),
            issuingOffice: office
        )
    }

    private func createContractorInfo(from fields: [String: Any]) throws -> ContractorInformation {
        let address = try PostalAddress(
            street: fields["contractorStreet"] as? String ?? "TBD",
            city: fields["contractorCity"] as? String ?? "TBD",
            state: fields["contractorState"] as? String ?? "TBD",
            zipCode: fields["contractorZip"] as? String ?? "00000"
        )

        return try ContractorInformation(
            name: fields["contractorName"] as? String ?? "",
            address: address,
            cageCode: CageCode(fields["cageCode"] as? String ?? "00000"),
            phoneNumber: PhoneNumber(fields["phoneNumber"] as? String ?? "000-000-0000")
        )
    }

    private func createDeliveryInfo(from fields: [String: Any]) throws -> DD1155DeliveryInformation {
        let shipToAddress = try PostalAddress(
            street: fields["shipToStreet"] as? String ?? "TBD",
            city: fields["shipToCity"] as? String ?? "TBD",
            state: fields["shipToState"] as? String ?? "TBD",
            zipCode: fields["shipToZip"] as? String ?? "00000"
        )

        let shipTo = DD1155DeliveryInformation.ShipToAddress(
            code: fields["shipToCode"] as? String ?? "",
            address: shipToAddress,
            dodaac: fields["shipToDodaac"] as? String
        )

        return DD1155DeliveryInformation(
            fobPoint: .destination,
            deliveryDate: fields["deliveryDate"] as? Date,
            shipTo: shipTo
        )
    }

    private func createItemsOrderedSection(from fields: [String: Any]) throws -> ItemsOrderedSection {
        let total = try Money(
            amount: fields["totalAmount"] as? Decimal ?? 0,
            currency: .usd
        )

        return ItemsOrderedSection(
            items: [],
            totalAmount: total
        )
    }

    private func createAccountingData(from fields: [String: Any]) throws -> AccountingData {
        AccountingData(
            appropriation: fields["appropriation"] as? String ?? "",
            objectClass: fields["objectClass"] as? String ?? ""
        )
    }

    private func createAuthorizationSection(from fields: [String: Any]) throws -> AuthorizationSection {
        let authorized = AuthorizationSection.AuthorizedOfficial(
            name: fields["authorizedName"] as? String ?? "",
            title: fields["authorizedTitle"] as? String ?? "",
            signature: fields["authorizedSignature"] as? String,
            signatureDate: fields["authorizedSignatureDate"] as? Date
        )

        return AuthorizationSection(authorizedBy: authorized)
    }
}

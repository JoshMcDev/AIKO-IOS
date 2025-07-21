import Foundation

/// SF 18 - Request for Quotations
public final class SF18Form: BaseGovernmentForm {
    // MARK: - Form Sections

    public let requestInfo: RequestInfo
    public let itemsRequested: ItemsSection
    public let deliveryInfo: SF18DeliveryInformation
    public let solicitationInfo: SolicitationInformation

    // MARK: - Initialization

    public init(
        revision: String = "REV JUN 2016",
        metadata: FormMetadata,
        requestInfo: RequestInfo,
        itemsRequested: ItemsSection,
        deliveryInfo: SF18DeliveryInformation,
        solicitationInfo: SolicitationInformation
    ) {
        self.requestInfo = requestInfo
        self.itemsRequested = itemsRequested
        self.deliveryInfo = deliveryInfo
        self.solicitationInfo = solicitationInfo

        super.init(
            formNumber: "SF18",
            formTitle: "Request for Quotations",
            revision: revision,
            effectiveDate: DateComponents(calendar: .current, year: 2016, month: 6, day: 1).date!,
            expirationDate: nil,
            isElectronic: true,
            metadata: metadata
        )
    }

    // MARK: - Validation

    override public func validate() throws {
        try super.validate()

        // Validate all sections
        try requestInfo.validate()
        try itemsRequested.validate()
        try deliveryInfo.validate()
        try solicitationInfo.validate()
    }

    // MARK: - Export

    override public func export() -> [String: Any] {
        var data = super.export()

        data["requestInfo"] = requestInfo.export()
        data["itemsRequested"] = itemsRequested.export()
        data["deliveryInfo"] = deliveryInfo.export()
        data["solicitationInfo"] = solicitationInfo.export()

        return data
    }
}

// MARK: - SF18 Sections

/// Request Information
public struct RequestInfo: ValueObject {
    public let rfqNumber: String
    public let issueDate: Date
    public let requisitionNumber: RequisitionNumber?
    public let responseDeadline: Date
    public let pageCount: Int

    public init(
        rfqNumber: String,
        issueDate: Date,
        requisitionNumber: RequisitionNumber? = nil,
        responseDeadline: Date,
        pageCount: Int = 1
    ) {
        self.rfqNumber = rfqNumber
        self.issueDate = issueDate
        self.requisitionNumber = requisitionNumber
        self.responseDeadline = responseDeadline
        self.pageCount = pageCount
    }

    public func validate() throws {
        guard !rfqNumber.isEmpty else {
            throw FormError.missingRequiredField("RFQ number")
        }

        guard responseDeadline > issueDate else {
            throw FormError.validationFailed("Response deadline must be after issue date")
        }

        guard pageCount > 0 else {
            throw FormError.invalidField("page count - must be positive")
        }
    }

    func export() -> [String: Any] {
        [
            "rfqNumber": rfqNumber,
            "issueDate": issueDate.timeIntervalSince1970,
            "requisitionNumber": requisitionNumber?.value as Any,
            "responseDeadline": responseDeadline.timeIntervalSince1970,
            "pageCount": pageCount
        ]
    }
}

/// Items Requested Section
public struct ItemsSection: ValueObject {
    public let items: [RequestedItem]
    public let totalEstimatedCost: Money?

    public struct RequestedItem: ValueObject {
        public let itemNumber: String
        public let stockNumber: String?
        public let description: String
        public let quantity: Decimal
        public let unit: String
        public let unitPrice: Money?
        public let estimatedCost: Money?

        public init(
            itemNumber: String,
            stockNumber: String? = nil,
            description: String,
            quantity: Decimal,
            unit: String,
            unitPrice: Money? = nil,
            estimatedCost: Money? = nil
        ) {
            self.itemNumber = itemNumber
            self.stockNumber = stockNumber
            self.description = description
            self.quantity = quantity
            self.unit = unit
            self.unitPrice = unitPrice
            self.estimatedCost = estimatedCost
        }

        public func validate() throws {
            guard !itemNumber.isEmpty else {
                throw FormError.missingRequiredField("item number")
            }

            guard !description.isEmpty else {
                throw FormError.missingRequiredField("item description")
            }

            guard quantity > 0 else {
                throw FormError.invalidField("quantity - must be positive")
            }

            guard !unit.isEmpty else {
                throw FormError.missingRequiredField("unit of measure")
            }
        }
    }

    public init(
        items: [RequestedItem],
        totalEstimatedCost: Money? = nil
    ) {
        self.items = items
        self.totalEstimatedCost = totalEstimatedCost
    }

    public func validate() throws {
        guard !items.isEmpty else {
            throw FormError.validationFailed("At least one item must be requested")
        }

        for item in items {
            try item.validate()
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
                    "unitPrice": item.unitPrice?.amount as Any,
                    "estimatedCost": item.estimatedCost?.amount as Any
                ]
            },
            "totalEstimatedCost": totalEstimatedCost?.amount as Any,
            "currency": totalEstimatedCost?.currency.rawValue as Any
        ]
    }
}

/// Delivery Information
public struct SF18DeliveryInformation: ValueObject {
    public let requiredDate: Date?
    public let afterDate: Date?
    public let beforeDate: Date?
    public let deliveryDays: Int?
    public let deliveryAddress: PostalAddress
    public let deliveryTerms: DeliveryTerms
    public let fobPoint: FOBPoint

    public enum DeliveryTerms: String, CaseIterable {
        case immediate = "IMMEDIATE"
        case asRequired = "AS_REQUIRED"
        case scheduled = "SCHEDULED"
        case other = "OTHER"
    }

    public enum FOBPoint: String, CaseIterable {
        case destination = "DESTINATION"
        case origin = "ORIGIN"
    }

    public init(
        requiredDate: Date? = nil,
        afterDate: Date? = nil,
        beforeDate: Date? = nil,
        deliveryDays: Int? = nil,
        deliveryAddress: PostalAddress,
        deliveryTerms: DeliveryTerms = .asRequired,
        fobPoint: FOBPoint = .destination
    ) {
        self.requiredDate = requiredDate
        self.afterDate = afterDate
        self.beforeDate = beforeDate
        self.deliveryDays = deliveryDays
        self.deliveryAddress = deliveryAddress
        self.deliveryTerms = deliveryTerms
        self.fobPoint = fobPoint
    }

    public func validate() throws {
        // At least one delivery specification must be provided
        if requiredDate == nil, afterDate == nil, beforeDate == nil, deliveryDays == nil {
            throw FormError.validationFailed("At least one delivery time specification is required")
        }

        // Validate date ranges if both after and before dates are specified
        if let afterDate, let beforeDate {
            guard beforeDate > afterDate else {
                throw FormError.validationFailed("Before date must be after the after date")
            }
        }
    }

    func export() -> [String: Any] {
        [
            "requiredDate": requiredDate?.timeIntervalSince1970 as Any,
            "afterDate": afterDate?.timeIntervalSince1970 as Any,
            "beforeDate": beforeDate?.timeIntervalSince1970 as Any,
            "deliveryDays": deliveryDays as Any,
            "deliveryAddress": deliveryAddress.formatted,
            "deliveryTerms": deliveryTerms.rawValue,
            "fobPoint": fobPoint.rawValue
        ]
    }
}

/// Solicitation Information
public struct SolicitationInformation: ValueObject {
    public let issuingOffice: IssuingOffice
    public let contractingOfficer: ContractingOfficerInfo
    public let telephoneQuotesAccepted: Bool
    public let depositRequired: Bool
    public let depositAmount: Money?
    public let depositAccount: String?

    public struct IssuingOffice: ValueObject {
        public let name: String
        public let address: PostalAddress
        public let phoneNumber: PhoneNumber?
        public let faxNumber: String?

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("issuing office name")
            }
        }
    }

    public struct ContractingOfficerInfo: ValueObject {
        public let name: String
        public let title: String
        public let phoneNumber: PhoneNumber
        public let email: Email?

        public func validate() throws {
            guard !name.isEmpty else {
                throw FormError.missingRequiredField("contracting officer name")
            }
        }
    }

    public init(
        issuingOffice: IssuingOffice,
        contractingOfficer: ContractingOfficerInfo,
        telephoneQuotesAccepted: Bool = false,
        depositRequired: Bool = false,
        depositAmount: Money? = nil,
        depositAccount: String? = nil
    ) {
        self.issuingOffice = issuingOffice
        self.contractingOfficer = contractingOfficer
        self.telephoneQuotesAccepted = telephoneQuotesAccepted
        self.depositRequired = depositRequired
        self.depositAmount = depositAmount
        self.depositAccount = depositAccount
    }

    public func validate() throws {
        try issuingOffice.validate()
        try contractingOfficer.validate()

        if depositRequired {
            guard depositAmount != nil else {
                throw FormError.validationFailed("Deposit amount required when deposit is required")
            }
        }
    }

    func export() -> [String: Any] {
        [
            "issuingOffice": [
                "name": issuingOffice.name,
                "address": issuingOffice.address.formatted,
                "phoneNumber": issuingOffice.phoneNumber?.value as Any,
                "faxNumber": issuingOffice.faxNumber as Any
            ],
            "contractingOfficer": [
                "name": contractingOfficer.name,
                "title": contractingOfficer.title,
                "phoneNumber": contractingOfficer.phoneNumber.value,
                "email": contractingOfficer.email?.value as Any
            ],
            "telephoneQuotesAccepted": telephoneQuotesAccepted,
            "depositRequired": depositRequired,
            "depositAmount": depositAmount?.amount as Any,
            "depositCurrency": depositAmount?.currency.rawValue as Any,
            "depositAccount": depositAccount as Any
        ]
    }
}

// MARK: - SF18 Factory

public final class SF18Factory: BaseFormFactory<SF18Form> {
    override public func createBlank() -> SF18Form {
        let metadata = FormMetadata(
            createdBy: "System",
            agency: "GSA",
            purpose: "Request for quotations"
        )

        let emptyAddress = try! PostalAddress(
            street: "TBD",
            city: "TBD",
            state: "TBD",
            zipCode: "00000",
            country: "USA"
        )

        return SF18Form(
            metadata: metadata,
            requestInfo: RequestInfo(
                rfqNumber: "RFQ-00000",
                issueDate: Date(),
                responseDeadline: Date().addingTimeInterval(14 * 24 * 60 * 60) // 14 days
            ),
            itemsRequested: ItemsSection(items: []),
            deliveryInfo: SF18DeliveryInformation(
                deliveryAddress: emptyAddress
            ),
            solicitationInfo: SolicitationInformation(
                issuingOffice: SolicitationInformation.IssuingOffice(
                    name: "",
                    address: emptyAddress,
                    phoneNumber: nil,
                    faxNumber: nil
                ),
                contractingOfficer: SolicitationInformation.ContractingOfficerInfo(
                    name: "",
                    title: "",
                    phoneNumber: try! PhoneNumber("000-000-0000"),
                    email: nil
                )
            )
        )
    }

    override public func createForm(with data: FormData) throws -> SF18Form {
        let metadata = data.metadata

        // Extract and validate fields
        let requestInfo = try createRequestInfo(from: data.fields)
        let itemsRequested = try createItemsSection(from: data.fields)
        let deliveryInfo = try createDeliveryInfo(from: data.fields)
        let solicitationInfo = try createSolicitationInfo(from: data.fields)

        return SF18Form(
            revision: data.revision ?? "REV JUN 2016",
            metadata: metadata,
            requestInfo: requestInfo,
            itemsRequested: itemsRequested,
            deliveryInfo: deliveryInfo,
            solicitationInfo: solicitationInfo
        )
    }

    // Helper methods for creating sections
    private func createRequestInfo(from fields: [String: Any]) throws -> RequestInfo {
        RequestInfo(
            rfqNumber: fields["rfqNumber"] as? String ?? "RFQ-00000",
            issueDate: fields["issueDate"] as? Date ?? Date(),
            responseDeadline: fields["responseDeadline"] as? Date ??
                Date().addingTimeInterval(14 * 24 * 60 * 60)
        )
    }

    private func createItemsSection(from _: [String: Any]) throws -> ItemsSection {
        // Extract items from fields
        ItemsSection(items: [])
    }

    private func createDeliveryInfo(from fields: [String: Any]) throws -> SF18DeliveryInformation {
        let address = try PostalAddress(
            street: fields["deliveryStreet"] as? String ?? "TBD",
            city: fields["deliveryCity"] as? String ?? "TBD",
            state: fields["deliveryState"] as? String ?? "TBD",
            zipCode: fields["deliveryZip"] as? String ?? "00000"
        )

        return SF18DeliveryInformation(deliveryAddress: address)
    }

    private func createSolicitationInfo(from fields: [String: Any]) throws -> SolicitationInformation {
        let officeAddress = try PostalAddress(
            street: fields["officeStreet"] as? String ?? "TBD",
            city: fields["officeCity"] as? String ?? "TBD",
            state: fields["officeState"] as? String ?? "TBD",
            zipCode: fields["officeZip"] as? String ?? "00000"
        )

        let office = SolicitationInformation.IssuingOffice(
            name: fields["officeName"] as? String ?? "",
            address: officeAddress,
            phoneNumber: nil,
            faxNumber: nil
        )

        let officer = try SolicitationInformation.ContractingOfficerInfo(
            name: fields["coName"] as? String ?? "",
            title: fields["coTitle"] as? String ?? "",
            phoneNumber: PhoneNumber(fields["coPhone"] as? String ?? "000-000-0000"),
            email: nil
        )

        return SolicitationInformation(
            issuingOffice: office,
            contractingOfficer: officer
        )
    }
}

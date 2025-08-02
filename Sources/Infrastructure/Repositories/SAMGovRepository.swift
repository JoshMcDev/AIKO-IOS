import Foundation
import AppCore

// MARK: - SAM.gov API Repository Implementation

/// Production SAM.gov API repository with live API integration
public actor SAMGovRepository {
    
    // MARK: - Configuration
    
    private let apiKey = "zBy0Oy4TmGnzgqEWeKoRiifzDm9jotNwAitkOp89"
    private let baseURL = "https://api.sam.gov/entity-information/v3"
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API Methods
    
    /// Search entities by name, keywords, or general query
    public func searchEntities(
        query: String,
        page: Int = 1,
        size: Int = 10
    ) async throws -> EntitySearchResult {
        let endpoint = "/entities"
        var components = URLComponents(string: baseURL + endpoint)!
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "entityName", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "format", value: "JSON")
        ]
        
        guard let url = components.url else {
            throw SAMGovError.invalidResponse
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SAMGovError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw SAMGovError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let apiResponse = try decoder.decode(SAMGovAPIResponse.self, from: data)
            return EntitySearchResult(
                entities: apiResponse.entityData?.map { convertToEntitySummary($0) } ?? [],
                totalCount: apiResponse.totalRecords ?? 0
            )
            
        } catch {
            if error is SAMGovError {
                throw error
            } else {
                throw SAMGovError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// Get entity details by CAGE code
    public func getEntityByCAGE(_ cageCode: String) async throws -> EntityDetail {
        let endpoint = "/entities"
        var components = URLComponents(string: baseURL + endpoint)!
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "cageCode", value: cageCode),
            URLQueryItem(name: "format", value: "JSON")
        ]
        
        guard let url = components.url else {
            throw SAMGovError.invalidResponse
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SAMGovError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw SAMGovError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let apiResponse = try decoder.decode(SAMGovAPIResponse.self, from: data)
            
            guard let entityData = apiResponse.entityData?.first else {
                throw SAMGovError.entityNotFound
            }
            
            return convertToEntityDetail(entityData)
            
        } catch {
            if error is SAMGovError {
                throw error
            } else {
                throw SAMGovError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// Get entity details by UEI (Unique Entity Identifier)
    public func getEntityByUEI(_ uei: String) async throws -> EntityDetail {
        let endpoint = "/entities"
        var components = URLComponents(string: baseURL + endpoint)!
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "ueiSAM", value: uei),
            URLQueryItem(name: "format", value: "JSON")
        ]
        
        guard let url = components.url else {
            throw SAMGovError.invalidResponse
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SAMGovError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw SAMGovError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let apiResponse = try decoder.decode(SAMGovAPIResponse.self, from: data)
            
            guard let entityData = apiResponse.entityData?.first else {
                throw SAMGovError.entityNotFound
            }
            
            return convertToEntityDetail(entityData)
            
        } catch {
            if error is SAMGovError {
                throw error
            } else {
                throw SAMGovError.networkError(error.localizedDescription)
            }
        }
    }
}

// MARK: - SAM.gov API Response Models

struct SAMGovAPIResponse: Codable {
    let totalRecords: Int?
    let entityData: [SAMGovEntityData]?
    let links: SAMGovLinks?
}

struct SAMGovEntityData: Codable {
    let entityRegistration: EntityRegistration?
    let coreData: CoreData?
    let assertions: Assertions?
    let repsAndCerts: RepsAndCerts?
    let pointsOfContact: [PointOfContactData]?
}

struct EntityRegistration: Codable {
    let ueiSAM: String?
    let entityEFTIndicator: String?
    let cageCode: String?
    let dodaac: String?
    let legalBusinessName: String?
    let registrationStatus: String?
    let registrationDate: String?
    let lastUpdateDate: String?
    let registrationExpirationDate: String?
    let activationDate: String?
    let ueiStatus: String?
    let ueiExpirationDate: String?
    let ueiCreationDate: String?
    let publicDisplayFlag: String?
    let exclusionStatusFlag: String?
    let exclusionURL: String?
    let dnbOpenData: String?
}

struct CoreData: Codable {
    let entityHierarchyInformation: EntityHierarchyInformation?
    let entityInformation: EntityInformation?
    let physicalAddress: PhysicalAddressData?
    let mailingAddress: MailingAddressData?
    let congressionalDistrict: String?
    let generalInformation: GeneralInformation?
    let businessTypes: BusinessTypes?
    let financialInformation: FinancialInformation?
}

struct EntityHierarchyInformation: Codable {
    let immediateParentEntity: ParentEntity?
    let highestParentEntity: ParentEntity?
}

struct ParentEntity: Codable {
    let ueiSAM: String?
    let legalBusinessName: String?
    let physicalAddress: PhysicalAddressData?
    let phoneNumber: String?
}

struct EntityInformation: Codable {
    let entityURL: String?
    let entityDivisionName: String?
    let entityDivisionNumber: String?
    let entityStartDate: String?
    let fiscalYearEndCloseDate: String?
    let submissionDate: String?
}

struct PhysicalAddressData: Codable {
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvinceCode: String?
    let zipCode: String?
    let zipCodePlus4: String?
    let countryCode: String?
}

struct MailingAddressData: Codable {
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvinceCode: String?
    let zipCode: String?
    let zipCodePlus4: String?
    let countryCode: String?
}

struct GeneralInformation: Codable {
    let agencyBusinessPurposeCode: String?
    let agencyBusinessPurposeDesc: String?
    let entityStructureCode: String?
    let entityStructureDesc: String?
    let entityTypeCode: String?
    let entityTypeDesc: String?
    let profitStructureCode: String?
    let profitStructureDesc: String?
    let organizationStructureCode: String?
    let organizationStructureDesc: String?
    let stateOfIncorporationCode: String?
    let stateOfIncorporationDesc: String?
    let countryOfIncorporationCode: String?
    let countryOfIncorporationDesc: String?
}

struct BusinessTypes: Codable {
    let businessTypeList: [BusinessType]?
}

struct BusinessType: Codable {
    let businessTypeCode: String?
    let businessTypeDesc: String?
}

struct FinancialInformation: Codable {
    let creditCardUsage: String?
    let debtSubjectToOffset: String?
}

struct Assertions: Codable {
    let goodsAndServices: GoodsAndServices?
}

struct GoodsAndServices: Codable {
    let naicsCode: [NAICSCodeData]?
    let pscCode: [PSCCodeData]?
}

struct NAICSCodeData: Codable {
    let naicsCode: String?
    let naicsName: String?
    let isPrimary: String?
    let isSmallBusiness: String?
    let exceptionCounter: String?
}

struct PSCCodeData: Codable {
    let pscCode: String?
    let pscName: String?
}

struct RepsAndCerts: Codable {
    let certifications: Certifications?
}

struct Certifications: Codable {
    let fARResponses: FARResponses?
    let dFARResponses: DFARResponses?
}

struct FARResponses: Codable {
    let provisionId: String?
    let listOfAnswers: [FARAnswer]?
}

struct FARAnswer: Codable {
    let section: String?
    let questionText: String?
    let answerId: String?
    let answerText: String?
    let country: String?
    let company: String?
    let highestLevelOwnerCage: String?
    let highestLevelOwnerName: String?
    let immediateOwnerCage: String?
    let immediateOwnerName: String?
    let personFirstName: String?
    let personLastName: String?
    let personMiddleInitial: String?
    let personTitle: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvince: String?
    let zipCode: String?
    let zipCodePlus4: String?
}

struct DFARResponses: Codable {
    let provisionId: String?
    let listOfAnswers: [DFARAnswer]?
}

struct DFARAnswer: Codable {
    let section: String?
    let questionText: String?
    let answerId: String?
    let answerText: String?
}

struct PointOfContactData: Codable {
    let firstName: String?
    let middleInitial: String?
    let lastName: String?
    let title: String?
    let telephoneNumber: String?
    let phoneExtension: String?
    let internationalNumber: String?
    let faxNumber: String?
    let email: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvinceCode: String?
    let zipCode: String?
    let zipCodePlus4: String?
    let countryCode: String?
}

struct SAMGovLinks: Codable {
    let selfLink: String?
    let nextLink: String?
    let prevLink: String?
}

// MARK: - Error Types
// Note: SAMGovError is defined in SAMGovService.swift to avoid duplication

// MARK: - Data Conversion Helpers

extension SAMGovRepository {
    
    private func convertToEntitySummary(_ data: SAMGovEntityData) -> EntitySummary {
        let registration = data.entityRegistration
        let coreData = data.coreData
        
        return EntitySummary(
            ueiSAM: registration?.ueiSAM ?? "",
            entityName: coreData?.entityInformation?.entityDivisionName ?? registration?.legalBusinessName ?? "Unknown Entity",
            legalBusinessName: registration?.legalBusinessName,
            cageCode: registration?.cageCode,
            registrationStatus: registration?.registrationStatus ?? "Unknown",
            businessTypes: extractBusinessTypes(from: coreData?.businessTypes),
            primaryNAICS: extractPrimaryNAICS(from: data.assertions?.goodsAndServices?.naicsCode),
            address: convertToEntityAddress(coreData?.physicalAddress),
            isSmallBusiness: checkSmallBusinessStatus(from: data.assertions?.goodsAndServices?.naicsCode),
            lastUpdatedDate: parseDate(registration?.lastUpdateDate)
        )
    }
    
    private func convertToEntityDetail(_ data: SAMGovEntityData) -> EntityDetail {
        let registration = data.entityRegistration
        let coreData = data.coreData
        let assertions = data.assertions
        
        return EntityDetail(
            ueiSAM: registration?.ueiSAM ?? "",
            entityName: coreData?.entityInformation?.entityDivisionName ?? registration?.legalBusinessName ?? "Unknown Entity",
            legalBusinessName: registration?.legalBusinessName ?? "Unknown",
            cageCode: registration?.cageCode,
            duns: nil, // DUNS deprecated in favor of UEI
            ncage: nil,
            registrationStatus: registration?.registrationStatus ?? "Unknown",
            registrationDate: parseDate(registration?.registrationDate),
            expirationDate: parseDate(registration?.registrationExpirationDate),
            lastUpdatedDate: parseDate(registration?.lastUpdateDate),
            businessTypes: extractBusinessTypes(from: coreData?.businessTypes),
            primaryNAICS: extractPrimaryNAICS(from: assertions?.goodsAndServices?.naicsCode),
            address: convertToEntityAddress(coreData?.physicalAddress),
            pointOfContact: convertToPointOfContact(data.pointsOfContact?.first),
            hasActiveExclusions: parseExclusionStatus(registration?.exclusionStatusFlag),
            naicsCodes: convertToNAICSCodes(assertions?.goodsAndServices?.naicsCode),
            isSmallBusiness: checkSmallBusinessStatus(from: assertions?.goodsAndServices?.naicsCode),
            isVeteranOwned: checkBusinessType(coreData?.businessTypes, code: "XV"),
            isServiceDisabledVeteranOwned: checkBusinessType(coreData?.businessTypes, code: "QF"),
            isWomanOwned: checkBusinessType(coreData?.businessTypes, code: "A6"),
            is8aProgram: checkBusinessType(coreData?.businessTypes, code: "XX"),
            isHUBZone: checkBusinessType(coreData?.businessTypes, code: "XS")
        )
    }
    
    private func extractBusinessTypes(from businessTypes: BusinessTypes?) -> [String] {
        return businessTypes?.businessTypeList?.compactMap { $0.businessTypeDesc } ?? []
    }
    
    private func extractPrimaryNAICS(from naicsCodes: [NAICSCodeData]?) -> String? {
        return naicsCodes?.first { $0.isPrimary == "Y" }?.naicsCode ??
               naicsCodes?.first?.naicsCode
    }
    
    private func convertToEntityAddress(_ addressData: PhysicalAddressData?) -> EntityAddress? {
        guard let addressData = addressData else { return nil }
        
        return EntityAddress(
            line1: addressData.addressLine1 ?? "",
            line2: addressData.addressLine2,
            city: addressData.city ?? "",
            state: addressData.stateOrProvinceCode ?? "",
            zipCode: addressData.zipCode ?? "",
            country: addressData.countryCode ?? "USA"
        )
    }
    
    private func convertToPointOfContact(_ pocData: PointOfContactData?) -> PointOfContact? {
        guard let pocData = pocData else { return nil }
        
        return PointOfContact(
            firstName: pocData.firstName ?? "",
            lastName: pocData.lastName ?? "",
            title: pocData.title,
            email: pocData.email,
            phone: pocData.telephoneNumber
        )
    }
    
    private func convertToNAICSCodes(_ naicsData: [NAICSCodeData]?) -> [NAICSCode] {
        return naicsData?.map { data in
            NAICSCode(
                code: data.naicsCode ?? "",
                description: data.naicsName ?? "",
                isPrimary: data.isPrimary == "Y"
            )
        } ?? []
    }
    
    private func checkSmallBusinessStatus(from naicsCodes: [NAICSCodeData]?) -> Bool {
        return naicsCodes?.contains { $0.isSmallBusiness == "Y" } ?? false
    }
    
    private func checkBusinessType(_ businessTypes: BusinessTypes?, code: String) -> Bool {
        return businessTypes?.businessTypeList?.contains { $0.businessTypeCode == code } ?? false
    }
    
    private func parseExclusionStatus(_ exclusionFlag: String?) -> Bool {
        return exclusionFlag?.lowercased() == "y" || exclusionFlag?.lowercased() == "yes"
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.date(from: dateString) ?? 
               ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Factory Method

extension SAMGovRepository {
    
    /// Create a live SAMGovService using this repository
    public func createService() -> SAMGovService {
        return SAMGovService(
            searchEntity: { [weak self] query in
                guard let self = self else {
                    throw SAMGovError.invalidResponse
                }
                return try await self.searchEntities(query: query)
            },
            getEntityByCAGE: { [weak self] cageCode in
                guard let self = self else {
                    throw SAMGovError.invalidResponse
                }
                return try await self.getEntityByCAGE(cageCode)
            },
            getEntityByUEI: { [weak self] uei in
                guard let self = self else {
                    throw SAMGovError.invalidResponse
                }
                return try await self.getEntityByUEI(uei)
            }
        )
    }
}
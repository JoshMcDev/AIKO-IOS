import ComposableArchitecture
import Foundation

/// SAM.gov service-specific errors
public enum SAMGovServiceError: Error, Equatable, Sendable {
    case invalidURL
}

/// Service for interacting with SAM.gov Entity API
public struct SAMGovService: Sendable {
    public var searchEntity: @Sendable (String) async throws -> EntitySearchResult
    public var getEntityByCAGE: @Sendable (String) async throws -> EntityDetail
    public var getEntityByUEI: @Sendable (String) async throws -> EntityDetail

    public init(
        searchEntity: @escaping @Sendable (String) async throws -> EntitySearchResult,
        getEntityByCAGE: @escaping @Sendable (String) async throws -> EntityDetail,
        getEntityByUEI: @escaping @Sendable (String) async throws -> EntityDetail
    ) {
        self.searchEntity = searchEntity
        self.getEntityByCAGE = getEntityByCAGE
        self.getEntityByUEI = getEntityByUEI
    }
}

// MARK: - Models

public struct EntitySearchResult: Equatable, Sendable {
    public let totalRecords: Int
    public let entities: [EntitySummary]
}

public struct EntitySummary: Equatable, Sendable {
    public let ueiSAM: String
    public let cageCode: String?
    public let legalBusinessName: String
    public let registrationStatus: String
    public let registrationDate: Date?
    public let expirationDate: Date?
}

public struct EntityDetail: Equatable, Sendable {
    public let ueiSAM: String
    public let cageCode: String?
    public let legalBusinessName: String
    public let registrationStatus: String
    public let registrationDate: Date?
    public let expirationDate: Date?
    public let cageCodeExpirationDate: Date?
    public let physicalAddress: SAMGovAddress?
    public let businessTypes: [BusinessType]
    public let naicsCodes: [NAICSCode]
    public let pointsOfContact: [PointOfContact]
    public let isSmallBusiness: Bool
    public let isVeteranOwned: Bool
    public let isServiceDisabledVeteranOwned: Bool
    public let isWomanOwned: Bool
    public let is8aProgram: Bool
    public let isHUBZone: Bool
    public let section889Certifications: Section889Status?
    public let hasActiveExclusions: Bool
    public let exclusionURL: String?
    public let responsibilityInformation: ResponsibilityInfo?
    public let architectEngineerQualifications: ArchitectEngineerInfo?
    public let foreignGovtEntities: [ForeignGovtEntity]
}

public struct Section889Status: Equatable, Sendable {
    public let doesNotProvideProhibitedTelecom: Bool?
    public let doesNotUseProhibitedTelecom: Bool?
    public let certificationDate: Date?
}

public struct ResponsibilityInfo: Equatable, Sendable {
    public let hasDelinquentFederalDebt: Bool?
    public let hasUnpaidTaxLiability: Bool?
    public let integrityRecords: [IntegrityRecord]
}

public struct IntegrityRecord: Equatable, Sendable {
    public let proceedingType: String?
    public let proceedingDescription: String?
    public let proceedingDate: Date?
    public let terminationDate: Date?
    public let agency: String?
}

public struct ArchitectEngineerInfo: Equatable, Sendable {
    public let hasArchitectEngineerResponses: Bool
    public let hasSF330Filed: Bool
    public let lastSF330Date: Date?
    public let disciplines: [String]
}

public struct ForeignGovtEntity: Equatable, Sendable {
    public let country: String
    public let name: String
    public let interestType: String?
    public let ownershipPercentage: String?
    public let controlDescription: String?
}

public struct BusinessType: Equatable, Sendable {
    public let code: String
    public let description: String
}

public struct SAMGovAddress: Equatable, Sendable {
    public let streetAddress: String?
    public let city: String?
    public let state: String?
    public let zipCode: String?
    public let country: String?
}

public struct NAICSCode: Equatable, Sendable {
    public let code: String
    public let description: String
    public let isPrimary: Bool
}

public struct PointOfContact: Equatable, Sendable {
    public let firstName: String?
    public let lastName: String?
    public let title: String?
    public let email: String?
    public let phone: String?
}

// MARK: - Errors

public enum SAMGovError: Error, LocalizedError, Sendable {
    case invalidAPIKey
    case entityNotFound
    case rateLimitExceeded
    case invalidResponse
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            "Invalid SAM.gov API key"
        case .entityNotFound:
            "Entity not found in SAM.gov"
        case .rateLimitExceeded:
            "SAM.gov API rate limit exceeded"
        case .invalidResponse:
            "Invalid response from SAM.gov API"
        case let .networkError(message):
            "Network error: \(message)"
        }
    }
}

// MARK: - Live Implementation

extension SAMGovService: DependencyKey {
    public static var liveValue: SAMGovService {
        // Always use repository-based implementation as part of Phase 4 migration
        .liveValueWithRepository
    }

    // Keep the old implementation as a backup/reference
    static var directAPIValue: SAMGovService {
        SAMGovService(
            searchEntity: { query in
                // Get API key from settings
                @Dependency(\.settingsManager) var settingsManager
                let settings = try await settingsManager.loadSettings()
                let apiKey = settings.apiSettings.samGovAPIKey
                guard !apiKey.isEmpty else {
                    throw SAMGovError.invalidAPIKey
                }

                // Build URL with query parameters
                guard var components = URLComponents(string: "https://api.sam.gov/entity-information/v3/entities") else {
<<<<<<< HEAD
                    throw SAMGovError.networkError("Invalid URL")
=======
                    throw SAMGovServiceError.invalidURL
>>>>>>> Main
                }
                components.queryItems = [
                    URLQueryItem(name: "api_key", value: apiKey),
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "registrationStatus", value: "A"), // Active only
                    URLQueryItem(name: "includeSections", value: "entityRegistration,coreData,assertions,repsAndCerts,integrityInformation"),
                ]

                guard let url = components.url else {
                    throw SAMGovError.networkError("Invalid URL")
                }

                // Make request
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Accept")

                let (data, response) = try await URLSession.shared.data(for: request)

                // Check response
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        break
                    case 401:
                        throw SAMGovError.invalidAPIKey
                    case 429:
                        throw SAMGovError.rateLimitExceeded
                    case 404:
                        throw SAMGovError.entityNotFound
                    default:
                        throw SAMGovError.networkError("HTTP \(httpResponse.statusCode)")
                    }
                }

                // Parse response
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                do {
                    let apiResponse = try decoder.decode(SAMGovAPIResponse.self, from: data)

                    let entities = apiResponse.entityData?.map { entity in
                        EntitySummary(
                            ueiSAM: entity.entityRegistration?.ueiSAM ?? "",
                            cageCode: entity.entityRegistration?.cageCode,
                            legalBusinessName: entity.entityRegistration?.legalBusinessName ?? "",
                            registrationStatus: entity.entityRegistration?.registrationStatus ?? "",
                            registrationDate: entity.entityRegistration?.registrationDate,
                            expirationDate: entity.entityRegistration?.expirationDate
                        )
                    } ?? []

                    return EntitySearchResult(
                        totalRecords: apiResponse.totalRecords ?? 0,
                        entities: entities
                    )
                } catch {
                    // If parsing fails, try to print the raw response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("SAM.gov API Response: \(responseString)")
                    }
                    throw SAMGovError.invalidResponse
                }
            },
            getEntityByCAGE: { cageCode in
                // Search by CAGE code
                let searchResult = try await SAMGovService.liveValue.searchEntity("CAGE:\(cageCode)")

                guard let firstEntity = searchResult.entities.first else {
                    throw SAMGovError.entityNotFound
                }

                // Get full details by UEI
                return try await SAMGovService.liveValue.getEntityByUEI(firstEntity.ueiSAM)
            },
            getEntityByUEI: { uei in
                // Get API key from settings
                @Dependency(\.settingsManager) var settingsManager
                let settings = try await settingsManager.loadSettings()
                let apiKey = settings.apiSettings.samGovAPIKey
                guard !apiKey.isEmpty else {
                    throw SAMGovError.invalidAPIKey
                }

                // Build URL for specific entity
                let urlString = "https://api.sam.gov/entity-information/v3/entities/\(uei)"
                guard var components = URLComponents(string: urlString) else {
<<<<<<< HEAD
                    throw SAMGovError.networkError("Invalid URL")
=======
                    throw SAMGovServiceError.invalidURL
>>>>>>> Main
                }
                components.queryItems = [
                    URLQueryItem(name: "api_key", value: apiKey),
                    URLQueryItem(name: "includeSections", value: "entityRegistration,coreData,assertions,repsAndCerts,integrityInformation"),
                ]

                guard let url = components.url else {
                    throw SAMGovError.networkError("Invalid URL")
                }

                // Make request
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Accept")

                let (data, response) = try await URLSession.shared.data(for: request)

                // Check response
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        break
                    case 401:
                        throw SAMGovError.invalidAPIKey
                    case 429:
                        throw SAMGovError.rateLimitExceeded
                    case 404:
                        throw SAMGovError.entityNotFound
                    default:
                        throw SAMGovError.networkError("HTTP \(httpResponse.statusCode)")
                    }
                }

                // Parse response
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let entity = try decoder.decode(SAMGovEntityResponse.self, from: data)

                // Parse business types
                var businessTypes: [BusinessType] = []
                var isSmallBusiness = false
                var isVeteranOwned = false
                var isServiceDisabledVeteranOwned = false
                var isWomanOwned = false
                var is8aProgram = false
                var isHUBZone = false

                if let coreData = entity.coreData,
                   let businessTypesData = coreData.businessTypes,
                   let typeList = businessTypesData.businessTypeList {
                    businessTypes = typeList.compactMap { type in
                        guard let code = type.businessTypeCode,
                              let desc = type.businessTypeDesc else { return nil }

                        // Check for specific business types
                        switch code {
                        case "A5": isVeteranOwned = true
                        case "QF": isServiceDisabledVeteranOwned = true
                        case "A2": isWomanOwned = true
                        case "XX": is8aProgram = true
                        case "A8": isHUBZone = true
                        case "A6", "JT", "ZS": isSmallBusiness = true
                        default: break
                        }

                        return BusinessType(code: code, description: desc)
                    }
                }

                // Parse NAICS codes from assertions
                var naicsCodes: [NAICSCode] = []
                var primaryNAICS: String?

                if let assertions = entity.assertions,
                   let goodsAndServices = assertions.goodsAndServices {
                    primaryNAICS = goodsAndServices.primaryNaics

                    if let naicsList = goodsAndServices.naicsList {
                        naicsCodes = naicsList.compactMap { naics in
                            guard let code = naics.naicsCode,
                                  let desc = naics.naicsDescription else { return nil }

                            // Check small business status from NAICS
                            if let sbaSmallBusiness = naics.sbaSmallBusiness {
                                switch sbaSmallBusiness {
                                case "Y", "E":
                                    isSmallBusiness = true
                                default:
                                    break
                                }
                            }

                            let isPrimary = (code == primaryNAICS)
                            return NAICSCode(code: code, description: desc, isPrimary: isPrimary)
                        }
                    }
                }

                // Parse address
                var address: SAMGovAddress?
                if let coreData = entity.coreData,
                   let physAddr = coreData.physicalAddress {
                    address = SAMGovAddress(
                        streetAddress: physAddr.addressLine1,
                        city: physAddr.city,
                        state: physAddr.stateOrProvinceCode,
                        zipCode: physAddr.zipCode,
                        country: physAddr.countryCode
                    )
                }

                // Parse Section 889 certifications
                var section889Status: Section889Status?
                var foreignGovtEntities: [ForeignGovtEntity] = []

                if let repsAndCerts = entity.repsAndCerts,
                   let certifications = repsAndCerts.certifications {
                    // Check both farResponses and fARResponses (different naming in API)
                    let allFarResponses = (certifications.farResponses ?? []) + (certifications.fARResponses ?? [])

                    var doesNotProvide: Bool?
                    var doesNotUse: Bool?

                    for response in allFarResponses {
                        // Section 889 Part A(1)(A) - Does not provide prohibited telecom
                        if response.provisionId == "FAR 52.204-26" ||
                            response.provisionId?.contains("52.204-26") == true {
                            if let answers = response.listOfAnswers {
                                for answer in answers {
                                    // Check specific sections
                                    if answer.section == "52.204-26.c.1" ||
                                        answer.questionText?.lowercased().contains("provide covered telecommunications") == true {
                                        doesNotProvide = answer.answerText?.lowercased() == "no"
                                    }
                                    if answer.section == "52.204-26.c.2" ||
                                        answer.questionText?.lowercased().contains("use covered telecommunications") == true {
                                        doesNotUse = answer.answerText?.lowercased() == "no"
                                    }

                                    // Extract foreign government entities
                                    if let fgeList = answer.foreignGovtEntitiesList, !fgeList.isEmpty {
                                        for fge in fgeList {
                                            if let country = fge.country,
                                               let name = fge.name {
                                                let entity = ForeignGovtEntity(
                                                    country: country,
                                                    name: name,
                                                    interestType: fge.interestType,
                                                    ownershipPercentage: fge.ownershipPercentage,
                                                    controlDescription: fge.controlDescription
                                                )
                                                foreignGovtEntities.append(entity)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Also check for foreign government control questions
                        if response.provisionId?.contains("252.209-7002") == true {
                            if let answers = response.listOfAnswers {
                                for answer in answers {
                                    if let fgeList = answer.foreignGovtEntitiesList, !fgeList.isEmpty {
                                        for fge in fgeList {
                                            if let country = fge.country,
                                               let name = fge.name {
                                                let entity = ForeignGovtEntity(
                                                    country: country,
                                                    name: name,
                                                    interestType: fge.interestType,
                                                    ownershipPercentage: fge.ownershipPercentage,
                                                    controlDescription: fge.controlDescription
                                                )
                                                foreignGovtEntities.append(entity)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if doesNotProvide != nil || doesNotUse != nil {
                        section889Status = Section889Status(
                            doesNotProvideProhibitedTelecom: doesNotProvide,
                            doesNotUseProhibitedTelecom: doesNotUse,
                            certificationDate: entity.entityRegistration?.registrationDate
                        )
                    }
                }

                // Parse exclusion status
                let hasActiveExclusions = entity.entityRegistration?.exclusionStatusFlag == "Y"
                let exclusionURL = entity.entityRegistration?.exclusionURL

                // Parse responsibility information
                var responsibilityInfo: ResponsibilityInfo?
                if let financialInfo = entity.coreData?.financialInformation {
                    let hasDelinquentDebt = financialInfo.delinquentFederalDebt == "Y"
                    let hasUnpaidTax = financialInfo.unpaidTaxLiability == "Y"

                    var integrityRecords: [IntegrityRecord] = []
                    if let records = entity.integrityInformation?.integrityRecords {
                        integrityRecords = records.compactMap { record in
                            IntegrityRecord(
                                proceedingType: record.proceedingType,
                                proceedingDescription: record.proceedingDescription,
                                proceedingDate: record.proceedingDate,
                                terminationDate: record.terminationDate,
                                agency: record.agency
                            )
                        }
                    }

                    responsibilityInfo = ResponsibilityInfo(
                        hasDelinquentFederalDebt: hasDelinquentDebt,
                        hasUnpaidTaxLiability: hasUnpaidTax,
                        integrityRecords: integrityRecords
                    )
                }

                // Parse architect-engineer qualifications
                var architectEngineerInfo: ArchitectEngineerInfo?
                if let qualifications = entity.repsAndCerts?.qualifications,
                   let aeResponses = qualifications.architectEngineerResponses {
                    let hasResponses = aeResponses.architectExperiencesList?.isEmpty == false
                    let disciplines = aeResponses.architectExperiencesList?.compactMap(\.experienceDescription) ?? []

                    architectEngineerInfo = ArchitectEngineerInfo(
                        hasArchitectEngineerResponses: hasResponses,
                        hasSF330Filed: hasResponses, // If they have responses, they've filed SF330
                        lastSF330Date: entity.entityRegistration?.registrationDate, // Use registration date as proxy
                        disciplines: disciplines
                    )
                }

                return EntityDetail(
                    ueiSAM: entity.entityRegistration?.ueiSAM ?? uei,
                    cageCode: entity.entityRegistration?.cageCode,
                    legalBusinessName: entity.entityRegistration?.legalBusinessName ?? "",
                    registrationStatus: entity.entityRegistration?.registrationStatus ?? "",
                    registrationDate: entity.entityRegistration?.registrationDate,
                    expirationDate: entity.entityRegistration?.expirationDate,
                    cageCodeExpirationDate: entity.entityRegistration?.expirationDate,
                    physicalAddress: address,
                    businessTypes: businessTypes,
                    naicsCodes: naicsCodes,
                    pointsOfContact: [],
                    isSmallBusiness: isSmallBusiness,
                    isVeteranOwned: isVeteranOwned,
                    isServiceDisabledVeteranOwned: isServiceDisabledVeteranOwned,
                    isWomanOwned: isWomanOwned,
                    is8aProgram: is8aProgram,
                    isHUBZone: isHUBZone,
                    section889Certifications: section889Status,
                    hasActiveExclusions: hasActiveExclusions,
                    exclusionURL: exclusionURL,
                    responsibilityInformation: responsibilityInfo,
                    architectEngineerQualifications: architectEngineerInfo,
                    foreignGovtEntities: foreignGovtEntities
                )
            }
        )
    }

    public static var testValue: SAMGovService {
        SAMGovService(
            searchEntity: { _ in
                EntitySearchResult(totalRecords: 1, entities: [
                    EntitySummary(
                        ueiSAM: "TEST123456789",
                        cageCode: "1TEST",
                        legalBusinessName: "Test Company",
                        registrationStatus: "Active",
                        registrationDate: Date(),
                        expirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60)
                    ),
                ])
            },
            getEntityByCAGE: { _ in
                EntityDetail(
                    ueiSAM: "TEST123456789",
                    cageCode: "1TEST",
                    legalBusinessName: "Test Company",
                    registrationStatus: "Active",
                    registrationDate: Date(),
                    expirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                    cageCodeExpirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                    physicalAddress: nil as SAMGovAddress?,
                    businessTypes: [],
                    naicsCodes: [],
                    pointsOfContact: [],
                    isSmallBusiness: false,
                    isVeteranOwned: false,
                    isServiceDisabledVeteranOwned: false,
                    isWomanOwned: false,
                    is8aProgram: false,
                    isHUBZone: false,
                    section889Certifications: nil,
                    hasActiveExclusions: false,
                    exclusionURL: nil,
                    responsibilityInformation: nil,
                    architectEngineerQualifications: nil,
                    foreignGovtEntities: []
                )
            },
            getEntityByUEI: { _ in
                EntityDetail(
                    ueiSAM: "TEST123456789",
                    cageCode: "1TEST",
                    legalBusinessName: "Test Company",
                    registrationStatus: "Active",
                    registrationDate: Date(),
                    expirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                    cageCodeExpirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                    physicalAddress: nil as SAMGovAddress?,
                    businessTypes: [],
                    naicsCodes: [],
                    pointsOfContact: [],
                    isSmallBusiness: false,
                    isVeteranOwned: false,
                    isServiceDisabledVeteranOwned: false,
                    isWomanOwned: false,
                    is8aProgram: false,
                    isHUBZone: false,
                    section889Certifications: nil,
                    hasActiveExclusions: false,
                    exclusionURL: nil,
                    responsibilityInformation: nil,
                    architectEngineerQualifications: nil,
                    foreignGovtEntities: []
                )
            }
        )
    }
}

// MARK: - API Response Models

private struct SAMGovAPIResponse: Decodable {
    let totalRecords: Int?
    let entityData: [SAMGovEntity]?
}

private struct SAMGovEntityResponse: Decodable {
    let entityRegistration: SAMGovEntityRegistration?
    let coreData: SAMGovCoreData?
    let assertions: SAMGovAssertions?
    let repsAndCerts: SAMGovRepsAndCerts?
    let integrityInformation: SAMGovIntegrityInformation?
}

private struct SAMGovEntity: Decodable {
    let entityRegistration: SAMGovEntityRegistration?
    let coreData: SAMGovCoreData?
    let assertions: SAMGovAssertions?
    let repsAndCerts: SAMGovRepsAndCerts?
    let integrityInformation: SAMGovIntegrityInformation?
}

private struct SAMGovEntityRegistration: Decodable {
    let ueiSAM: String?
    let cageCode: String?
    let legalBusinessName: String?
    let registrationStatus: String?
    let registrationDate: Date?
    let expirationDate: Date?
    let registrationExpirationDate: Date?
    let exclusionStatusFlag: String?
    let exclusionURL: String?
}

private struct SAMGovCoreData: Decodable {
    let businessTypes: SAMGovBusinessTypes?
    let physicalAddress: SAMGovAddressData?
    let financialInformation: SAMGovFinancialInformation?
}

private struct SAMGovFinancialInformation: Decodable {
    let delinquentFederalDebt: String?
    let unpaidTaxLiability: String?
}

private struct SAMGovBusinessTypes: Decodable {
    let businessTypeList: [SAMGovBusinessType]?
    let sbaBusinessTypeList: [SAMGovSBABusinessType]?
}

private struct SAMGovBusinessType: Decodable {
    let businessTypeCode: String?
    let businessTypeDesc: String?
}

private struct SAMGovSBABusinessType: Decodable {
    let sbaBusinessTypeCode: String?
    let sbaBusinessTypeDesc: String?
    let certificationEntryDate: Date?
    let certificationExitDate: Date?
}

private struct SAMGovAddressData: Decodable {
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvinceCode: String?
    let zipCode: String?
    let zipCodePlus4: String?
    let countryCode: String?
}

private struct SAMGovAssertions: Decodable {
    let goodsAndServices: SAMGovGoodsAndServices?
}

private struct SAMGovGoodsAndServices: Decodable {
    let primaryNaics: String?
    let naicsList: [SAMGovNAICS]?
}

private struct SAMGovNAICS: Decodable {
    let naicsCode: String?
    let naicsDescription: String?
    let sbaSmallBusiness: String?
    let naicsException: String?
}

private struct SAMGovRepsAndCerts: Decodable {
    let certifications: SAMGovCertifications?
    let qualifications: SAMGovQualifications?
}

private struct SAMGovCertifications: Decodable {
    let farResponses: [SAMGovFARResponse]?
    let fARResponses: [SAMGovFARResponse]?
}

private struct SAMGovQualifications: Decodable {
    let architectEngineerResponses: SAMGovArchitectEngineerResponses?
}

private struct SAMGovArchitectEngineerResponses: Decodable {
    let provisionId: String?
    let architectExperiencesList: [SAMGovArchitectExperience]?
}

private struct SAMGovArchitectExperience: Decodable {
    let experienceCode: String?
    let experienceDescription: String?
}

private struct SAMGovFARResponse: Decodable {
    let provisionId: String?
    let listOfAnswers: [SAMGovFARAnswer]?
}

private struct SAMGovFARAnswer: Decodable {
    let answerId: String?
    let answerText: String?
    let country: String?
    let companyName: String?
    let highestLevelOwnerCage: String?
    let immediateOwnerCage: String?
    let section: String?
    let questionText: String?
    let foreignGovtEntitiesList: [SAMGovForeignGovtEntity]?
}

private struct SAMGovForeignGovtEntity: Decodable {
    let country: String?
    let name: String?
    let interestType: String?
    let ownershipPercentage: String?
    let controlDescription: String?
}

private struct SAMGovIntegrityInformation: Decodable {
    let integrityRecords: [SAMGovIntegrityRecord]?
}

private struct SAMGovIntegrityRecord: Decodable {
    let proceedingType: String?
    let proceedingDescription: String?
    let proceedingDate: Date?
    let terminationDate: Date?
    let recordStatus: String?
    let agency: String?
}

public extension DependencyValues {
    var samGovService: SAMGovService {
        get { self[SAMGovService.self] }
        set { self[SAMGovService.self] = newValue }
    }
}

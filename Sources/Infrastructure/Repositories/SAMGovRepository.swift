import Foundation

/// Repository for SAM.gov entity interactions following domain-driven design
public final class SAMGovRepository: @unchecked Sendable {
    // MARK: - Private Properties

    private let apiKey: String
    private let baseURL = "https://api.sam.gov/entity-information/v3"
    private let session: URLSession

    // MARK: - Initialization

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    // MARK: - Public Methods

    /// Search for entities by query
    public func searchEntities(_ query: String) async throws -> EntitySearchResult {
        guard var components = URLComponents(string: "\(baseURL)/entities") else {
<<<<<<< HEAD
            throw SAMGovError.networkError("Invalid base URL")
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

        let data = try await performRequest(url: url)
        let apiResponse = try decodeResponse(SAMGovAPIResponse.self, from: data)

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
    }

    /// Get entity details by CAGE code
    public func getEntityByCAGE(_ cageCode: String) async throws -> EntityDetail {
        // Search by CAGE code first
        let searchResult = try await searchEntities("CAGE:\(cageCode)")

        guard let firstEntity = searchResult.entities.first else {
            throw SAMGovError.entityNotFound
        }

        // Get full details by UEI
        return try await getEntityByUEI(firstEntity.ueiSAM)
    }

    /// Get entity details by UEI
    public func getEntityByUEI(_ uei: String) async throws -> EntityDetail {
        guard var components = URLComponents(string: "\(baseURL)/entities/\(uei)") else {
<<<<<<< HEAD
            throw SAMGovError.networkError("Invalid entity URL")
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

        let data = try await performRequest(url: url)
        let entity = try decodeResponse(SAMGovEntityResponse.self, from: data)

        return parseEntityDetail(from: entity)
    }

    // MARK: - Private Methods

    private func performRequest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                return data
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

        return data
    }

    private func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(type, from: data)
        } catch {
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("SAM.gov API Response: \(responseString)")
            }
            throw SAMGovError.invalidResponse
        }
    }

    private func parseEntityDetail(from entity: SAMGovEntityResponse) -> EntityDetail {
        // Parse business types and socioeconomic indicators
        var businessTypes: [BusinessType] = []
        var isSmallBusiness = false
        var isVeteranOwned = false
        var isServiceDisabledVeteranOwned = false
        var isWomanOwned = false
        var is8aProgram = false
        var isHUBZone = false

        // Parse business types from assertions
        if let assertions = entity.assertions {
            // Small Business
            if assertions.goodsAndServices?.primaryNaics?.isSmallBusiness == "Y" {
                isSmallBusiness = true
                businessTypes.append(BusinessType(code: "2X", description: "Small Business"))
            }

            // Veteran Owned
            if assertions.goodsAndServices?.veteranOwnedBusiness == "Y" {
                isVeteranOwned = true
                businessTypes.append(BusinessType(code: "A2", description: "Veteran-Owned Business"))
            }

            // Service Disabled Veteran Owned
            if assertions.goodsAndServices?.serviceDisabledVeteranOwnedBusiness == "Y" {
                isServiceDisabledVeteranOwned = true
                businessTypes.append(BusinessType(code: "A5", description: "Service-Disabled Veteran-Owned Business"))
            }

            // Woman Owned
            if assertions.goodsAndServices?.womenOwnedBusiness == "Y" {
                isWomanOwned = true
                businessTypes.append(BusinessType(code: "8W", description: "Women-Owned Business"))
            }

            // 8(a) Program
            if assertions.goodsAndServices?.sba8aProgramParticipant == "Y" {
                is8aProgram = true
                businessTypes.append(BusinessType(code: "8A", description: "8(a) Program Participant"))
            }

            // HUBZone
            if assertions.goodsAndServices?.hubZoneBusiness == "Y" {
                isHUBZone = true
                businessTypes.append(BusinessType(code: "JV", description: "HUBZone Business"))
            }
        }

        // Parse NAICS codes
        let naicsCodes = entity.coreData?.entityInformation?.primaryNaics?.map { naics in
            NAICSCode(
                code: naics.naicsCode ?? "",
                description: naics.naicsDesc ?? "",
                isPrimary: true
            )
        } ?? []

        // Parse address
        let physicalAddress = entity.coreData?.mailingAddress.flatMap { addr in
            SAMGovAddress(
                streetAddress: addr.streetAddress,
                city: addr.city,
                state: addr.stateOrProvinceCode,
                zipCode: addr.zipCode,
                country: addr.countryCode
            )
        }

        // Parse points of contact
        let pointsOfContact = entity.repsAndCerts?.pointsOfContact?.map { poc in
            PointOfContact(
                firstName: poc.firstName,
                lastName: poc.lastName,
                title: poc.title,
                email: poc.email,
                phone: poc.usPhone
            )
        } ?? []

        // Parse Section 889 certifications
        let section889Status = entity.assertions?.section889.flatMap { section889 in
            Section889Status(
                doesNotProvideProhibitedTelecom: section889.doesNotProvideProhibitedTelecom == "Y",
                doesNotUseProhibitedTelecom: section889.doesNotUseProhibitedTelecom == "Y",
                certificationDate: section889.certificationDate
            )
        }

        // Parse responsibility information
        let responsibilityInfo = entity.integrityInformation.flatMap { integrity in
            ResponsibilityInfo(
                hasDelinquentFederalDebt: integrity.delinquentFederalDebt == "Y",
                hasUnpaidTaxLiability: integrity.unpaidFederalTaxLiability == "Y",
                integrityRecords: integrity.proceedingData?.map { proc in
                    IntegrityRecord(
                        proceedingType: proc.proceedingType,
                        proceedingDescription: proc.proceedingDescription,
                        proceedingDate: proc.proceedingDate,
                        terminationDate: proc.terminationDate,
                        agency: proc.agency
                    )
                } ?? []
            )
        }

        // Parse foreign government entities
        let foreignGovtEntities = entity.coreData?.foreignGovtEntities?.map { fge in
            ForeignGovtEntity(
                country: fge.country ?? "",
                name: fge.name ?? "",
                interestType: fge.interestType,
                ownershipPercentage: fge.ownershipPercentage,
                controlDescription: fge.controlDescription
            )
        } ?? []

        return EntityDetail(
            ueiSAM: entity.entityRegistration?.ueiSAM ?? "",
            cageCode: entity.entityRegistration?.cageCode,
            legalBusinessName: entity.entityRegistration?.legalBusinessName ?? "",
            registrationStatus: entity.entityRegistration?.registrationStatus ?? "",
            registrationDate: entity.entityRegistration?.registrationDate,
            expirationDate: entity.entityRegistration?.expirationDate,
            cageCodeExpirationDate: entity.entityRegistration?.cageCodeAssignmentDate,
            physicalAddress: physicalAddress,
            businessTypes: businessTypes,
            naicsCodes: naicsCodes,
            pointsOfContact: pointsOfContact,
            isSmallBusiness: isSmallBusiness,
            isVeteranOwned: isVeteranOwned,
            isServiceDisabledVeteranOwned: isServiceDisabledVeteranOwned,
            isWomanOwned: isWomanOwned,
            is8aProgram: is8aProgram,
            isHUBZone: isHUBZone,
            section889Certifications: section889Status,
            hasActiveExclusions: entity.entityRegistration?.exclusionStatusFlag == "Y",
            exclusionURL: entity.entityRegistration?.exclusionURL,
            responsibilityInformation: responsibilityInfo,
            architectEngineerQualifications: nil, // Not implemented in this version
            foreignGovtEntities: foreignGovtEntities
        )
    }
}

// MARK: - API Response Models

private struct SAMGovAPIResponse: Decodable {
    let totalRecords: Int?
    let entityData: [SAMGovEntityResponse]?
}

private struct SAMGovEntityResponse: Decodable {
    let entityRegistration: EntityRegistration?
    let coreData: CoreDataSection?
    let assertions: Assertions?
    let repsAndCerts: RepsAndCerts?
    let integrityInformation: IntegrityInformation?
}

private struct EntityRegistration: Decodable {
    let ueiSAM: String?
    let cageCode: String?
    let legalBusinessName: String?
    let registrationStatus: String?
    let registrationDate: Date?
    let expirationDate: Date?
    let cageCodeAssignmentDate: Date?
    let exclusionStatusFlag: String?
    let exclusionURL: String?
}

private struct CoreDataSection: Decodable {
    let entityInformation: EntityInformation?
    let mailingAddress: SAMGovAddressData?
    let foreignGovtEntities: [ForeignGovtEntityData]?
}

private struct EntityInformation: Decodable {
    let primaryNaics: [NAICSData]?
}

private struct NAICSData: Decodable {
    let naicsCode: String?
    let naicsDesc: String?
}

private struct SAMGovAddressData: Decodable {
    let streetAddress: String?
    let city: String?
    let stateOrProvinceCode: String?
    let zipCode: String?
    let countryCode: String?
}

private struct Assertions: Decodable {
    let goodsAndServices: GoodsAndServices?
    let section889: Section889Data?
}

private struct GoodsAndServices: Decodable {
    let primaryNaics: PrimaryNaics?
    let veteranOwnedBusiness: String?
    let serviceDisabledVeteranOwnedBusiness: String?
    let womenOwnedBusiness: String?
    let sba8aProgramParticipant: String?
    let hubZoneBusiness: String?
}

private struct PrimaryNaics: Decodable {
    let isSmallBusiness: String?
}

private struct Section889Data: Decodable {
    let doesNotProvideProhibitedTelecom: String?
    let doesNotUseProhibitedTelecom: String?
    let certificationDate: Date?
}

private struct RepsAndCerts: Decodable {
    let pointsOfContact: [PointOfContactData]?
}

private struct PointOfContactData: Decodable {
    let firstName: String?
    let lastName: String?
    let title: String?
    let email: String?
    let usPhone: String?
}

private struct IntegrityInformation: Decodable {
    let delinquentFederalDebt: String?
    let unpaidFederalTaxLiability: String?
    let proceedingData: [ProceedingData]?
}

private struct ProceedingData: Decodable {
    let proceedingType: String?
    let proceedingDescription: String?
    let proceedingDate: Date?
    let terminationDate: Date?
    let agency: String?
}

private struct ForeignGovtEntityData: Decodable {
    let country: String?
    let name: String?
    let interestType: String?
    let ownershipPercentage: String?
    let controlDescription: String?
}

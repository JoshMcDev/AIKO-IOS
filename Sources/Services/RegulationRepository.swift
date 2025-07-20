import ComposableArchitecture
import Foundation

// MARK: - Regulation Repository Service

/// Manages federal acquisition regulations and agency-specific supplements
public struct RegulationRepository: Sendable {
    public var getRegulationsForAgency: @Sendable (String) async throws -> RegulationSet
    public var checkForUpdates: @Sendable () async throws -> [RegulationUpdate]
    public var downloadRegulation: @Sendable (RegulationType) async throws -> RegulationContent
    public var searchRegulations: @Sendable (String, RegulationSet) async throws -> [RegulationSearchResult]

    public init(
        getRegulationsForAgency: @escaping @Sendable (String) async throws -> RegulationSet,
        checkForUpdates: @escaping @Sendable () async throws -> [RegulationUpdate],
        downloadRegulation: @escaping @Sendable (RegulationType) async throws -> RegulationContent,
        searchRegulations: @escaping @Sendable (String, RegulationSet) async throws -> [RegulationSearchResult]
    ) {
        self.getRegulationsForAgency = getRegulationsForAgency
        self.checkForUpdates = checkForUpdates
        self.downloadRegulation = downloadRegulation
        self.searchRegulations = searchRegulations
    }
}

// MARK: - Models

public struct RegulationSet: Equatable {
    public let agency: String
    public let regulations: [RegulationType]
    public let lastUpdated: Date

    public init(agency: String, regulations: [RegulationType], lastUpdated: Date = Date()) {
        self.agency = agency
        self.regulations = regulations
        self.lastUpdated = lastUpdated
    }
}

public enum RegulationType: String, Equatable, CaseIterable {
    // Base regulations
    case FAR = "Federal Acquisition Regulation"
    case DFARS = "Defense Federal Acquisition Regulation Supplement"

    // Agency supplements
    case SOFARS = "Special Operations Federal Acquisition Regulation Supplement"
    case VAAR = "Veterans Affairs Acquisition Regulation"
    case HHSAR = "Health and Human Services Acquisition Regulation"
    case AGAR = "Agriculture Acquisition Regulation"
    case GSAM = "General Services Acquisition Manual"
    case NASA_FAR = "NASA FAR Supplement"
    case DOSAR = "Department of State Acquisition Regulation"
    case AIDAR = "Agency for International Development Acquisition Regulation"
    case DIAR = "Defense Information Acquisition Regulation"
    case DTAR = "Department of Transportation Acquisition Regulation"
    case DEAR = "Department of Energy Acquisition Regulation"
    case DOLAR = "Department of Labor Acquisition Regulation"
    case HUDAR = "HUD Acquisition Regulation"
    case LIFAR = "Library of Congress FAR Supplement"
    case CAR = "Commerce Acquisition Regulation"
    case EPAAR = "Environmental Protection Agency Acquisition Regulation"
    case FEHBAR = "Federal Employees Health Benefits Acquisition Regulation"
    case NFS = "NFS (NASA FAR Supplement)"
    case TAR = "Treasury Acquisition Regulation"
    case USCGAR = "U.S. Coast Guard Acquisition Regulation"

    public var githubRepository: String {
        switch self {
        case .FAR:
            "https://github.com/GSA/GSA-Acquisition-FAR"
        case .DFARS:
            "https://github.com/GSA/GSA-Acquisition-DFARS"
        case .VAAR:
            "https://github.com/GSA/GSA-Acquisition-VAAR"
        case .HHSAR:
            "https://github.com/GSA/GSA-Acquisition-HHSAR"
        case .AGAR:
            "https://github.com/GSA/GSA-Acquisition-AGAR"
        case .GSAM:
            "https://github.com/GSA/GSA-Acquisition-GSAM"
        case .NASA_FAR, .NFS:
            "https://github.com/GSA/GSA-Acquisition-NFS"
        case .DOSAR:
            "https://github.com/GSA/GSA-Acquisition-DOSAR"
        case .AIDAR:
            "https://github.com/GSA/GSA-Acquisition-AIDAR"
        case .DTAR:
            "https://github.com/GSA/GSA-Acquisition-DTAR"
        case .DEAR:
            "https://github.com/GSA/GSA-Acquisition-DEAR"
        case .DOLAR:
            "https://github.com/GSA/GSA-Acquisition-DOLAR"
        case .HUDAR:
            "https://github.com/GSA/GSA-Acquisition-HUDAR"
        case .CAR:
            "https://github.com/GSA/GSA-Acquisition-CAR"
        case .EPAAR:
            "https://github.com/GSA/GSA-Acquisition-EPAAR"
        case .TAR:
            "https://github.com/GSA/GSA-Acquisition-TAR"
        default:
            "" // Some don't have dedicated repos yet
        }
    }
}

// Note: RegulationContent, RegulationUpdate, and RegulationSearchResult
// are now imported from Models module to avoid duplication

// MARK: - Agency Mapping

public extension RegulationRepository {
    static func regulationsForAgency(_ agency: String) -> [RegulationType] {
        let normalizedAgency = agency.uppercased()

        // Base regulations that apply to everyone
        var regulations: [RegulationType] = [.FAR]

        // Map agencies to their specific regulations
        switch normalizedAgency {
        case let str where str.contains("DOD") || str.contains("DEFENSE"):
            regulations.append(contentsOf: [.DFARS])

        case let str where str.contains("SOCOM") || str.contains("USSOCOM") || str.contains("SPECIAL OPERATIONS"):
            regulations.append(contentsOf: [.DFARS, .SOFARS])

        case let str where str.contains("VA") || str.contains("VETERANS"):
            regulations.append(.VAAR)

        case let str where str.contains("HHS") || str.contains("HEALTH"):
            regulations.append(.HHSAR)

        case let str where str.contains("USDA") || str.contains("AGRICULTURE"):
            regulations.append(.AGAR)

        case let str where str.contains("GSA") || str.contains("GENERAL SERVICES"):
            regulations.append(.GSAM)

        case let str where str.contains("NASA"):
            regulations.append(.NASA_FAR)

        case let str where str.contains("STATE") || str.contains("DOS"):
            regulations.append(.DOSAR)

        case let str where str.contains("USAID") || str.contains("AID"):
            regulations.append(.AIDAR)

        case let str where str.contains("DOT") || str.contains("TRANSPORTATION"):
            regulations.append(.DTAR)

        case let str where str.contains("DOE") || str.contains("ENERGY"):
            regulations.append(.DEAR)

        case let str where str.contains("DOL") || str.contains("LABOR"):
            regulations.append(.DOLAR)

        case let str where str.contains("HUD") || str.contains("HOUSING"):
            regulations.append(.HUDAR)

        case let str where str.contains("COMMERCE"):
            regulations.append(.CAR)

        case let str where str.contains("EPA") || str.contains("ENVIRONMENTAL"):
            regulations.append(.EPAAR)

        case let str where str.contains("TREASURY"):
            regulations.append(.TAR)

        case let str where str.contains("COAST GUARD") || str.contains("USCG"):
            regulations.append(.USCGAR)

        case let str where str.contains("ARMY"):
            regulations.append(.DFARS)

        case let str where str.contains("NAVY"):
            regulations.append(.DFARS)

        case let str where str.contains("AIR FORCE") || str.contains("USAF"):
            regulations.append(.DFARS)

        case let str where str.contains("MARINE") || str.contains("USMC"):
            regulations.append(.DFARS)

        case let str where str.contains("SPACE FORCE") || str.contains("USSF"):
            regulations.append(.DFARS)

        default:
            // If no specific agency match, just use FAR
            break
        }

        return regulations
    }
}

// MARK: - Dependency Key

extension RegulationRepository: DependencyKey {
    public static var liveValue: RegulationRepository {
        RegulationRepository(
            getRegulationsForAgency: { agency in
                let regulations = Self.regulationsForAgency(agency)
                return RegulationSet(
                    agency: agency,
                    regulations: regulations,
                    lastUpdated: Date()
                )
            },

            checkForUpdates: {
                // In production, this would check GitHub repos for changes
                // For now, return empty array
                []
            },

            downloadRegulation: { regulationType in
                // In production, this would fetch from GitHub
                // For now, return placeholder
                RegulationContent(
                    type: regulationType,
                    content: "Regulation content would be loaded here",
                    lastModified: Date(),
                    version: "1.0"
                )
            },

            searchRegulations: { _, _ in
                // In production, this would search through regulation content
                // For now, return empty results
                []
            }
        )
    }
}

public extension DependencyValues {
    var regulationRepository: RegulationRepository {
        get { self[RegulationRepository.self] }
        set { self[RegulationRepository.self] = newValue }
    }
}

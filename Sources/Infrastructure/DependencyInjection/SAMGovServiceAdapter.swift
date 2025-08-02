import Foundation

/// Adapter that bridges the TCA SAMGovService dependency with the new SAMGovRepository
public extension SAMGovService {
    /// Creates a SAMGovService backed by the object-oriented SAMGovRepository
    static func repositoryBased(apiKey: String = "") -> SAMGovService {
        let repository = SAMGovRepository()

        return SAMGovService(
            searchEntity: { query in
                try await repository.searchEntities(query: query)
            },

            getEntityByCAGE: { cageCode in
                try await repository.getEntityByCAGE(cageCode)
            },

            getEntityByUEI: { uei in
                try await repository.getEntityByUEI(uei)
            }
        )
    }

    /// Creates a SAMGovService with API key from settings
    static var repositoryBased: SAMGovService {
        get async throws {
            // TODO: Replace with proper dependency injection
            let settingsManager = SettingsManager.liveValue
            let settings = try await settingsManager.loadSettings()
            let apiKey = settings.apiSettings.samGovAPIKey

            guard !apiKey.isEmpty else {
                throw SAMGovError.invalidAPIKey
            }

            return repositoryBased(apiKey: apiKey)
        }
    }
}

// MARK: - Dependency Override

public extension SAMGovService {
    /// Override the live value to use repository-based implementation
    static var liveValueWithRepository: SAMGovService {
        SAMGovService(
            searchEntity: { query in
                let service = try await SAMGovService.repositoryBased
                return try await service.searchEntity(query)
            },

            getEntityByCAGE: { cageCode in
                let service = try await SAMGovService.repositoryBased
                return try await service.getEntityByCAGE(cageCode)
            },

            getEntityByUEI: { uei in
                let service = try await SAMGovService.repositoryBased
                return try await service.getEntityByUEI(uei)
            }
        )
    }
}

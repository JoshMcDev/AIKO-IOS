import Foundation
import AppCore

/// SAMGovLookupViewModel - SwiftUI @Observable Implementation
/// PHASE 2: Business Logic View with Federal Entity Search Capabilities
/// Supports batch lookup with three search types: CAGE Code, Company Name, UEI
@Observable
public final class SAMGovLookupViewModel: @unchecked Sendable {
    // MARK: - Constants
    private static let defaultSearchEntryCount = 3

    // MARK: - State Management
    public var searchEntries: [SAMGovSearchEntry] = {
        (0..<defaultSearchEntryCount).map { _ in SAMGovSearchEntry() }
    }()
    public var searchResults: [EntityDetail] = []
    public var isSearching: Bool = false
    public var errorMessage: String?
    public var showingReportPreview: Bool = false
    public var showingAPIKeyAlert: Bool = false
    public var selectedEntityForReport: EntityDetail?

    // MARK: - Computed Properties
    public var shouldDisableBatchSearch: Bool {
        hasAnyActiveSearch || !hasValidSearchEntries
    }

    private var hasAnyActiveSearch: Bool {
        searchEntries.contains { $0.isSearching }
    }

    private var hasValidSearchEntries: Bool {
        searchEntries.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: - Service Dependencies
    private let samGovService: SAMGovServiceProtocol

    // MARK: - Initialization
    public init(samGovService: SAMGovServiceProtocol) {
        self.samGovService = samGovService
    }

    // MARK: - Search Operations

    @MainActor
    public func performSearch(for index: Int) async {
        guard isValidSearchIndex(index),
              let searchText = validateAndPrepareSearch(at: index) else { return }

        await executeSearch(at: index, searchText: searchText)
    }

    @MainActor
    private func executeSearch(at index: Int, searchText: String) async {
        setSearchState(at: index, isSearching: true)

        do {
            let result = try await performSearchByType(searchText, type: searchEntries[index].type)
            handleSearchSuccess(at: index, result: result)
        } catch {
            handleSearchError(error)
        }

        setSearchState(at: index, isSearching: false)
    }

    private func performSearchByType(_ searchText: String, type: SAMGovSearchType) async throws -> EntityDetail {
        switch type {
        case .cage:
            return try await samGovService.getEntityByCAGE(searchText)
        case .uei:
            return try await samGovService.getEntityByUEI(searchText)
        case .companyName:
            let searchResult = try await samGovService.searchEntity(searchText)
            guard let firstEntity = searchResult.entities.first else {
                throw SAMGovError.entityNotFound
            }
            return try await samGovService.getEntityByUEI(firstEntity.ueiSAM)
        }
    }

    @MainActor
    private func handleSearchSuccess(at index: Int, result: EntityDetail) {
        searchEntries[index].result = result
        addUniqueSearchResult(result)
        clearErrorMessage()
    }

    @MainActor
    private func handleSearchError(_ error: Error) {
        errorMessage = mapErrorToUserFriendlyMessage(error)
    }

    @MainActor
    public func performAllSearches() async {
        let searchableIndices = getSearchableEntryIndices()

        await withTaskGroup(of: Void.self) { group in
            for index in searchableIndices {
                group.addTask { [weak self] in
                    await self?.performSearch(for: index)
                }
            }
        }
    }

    private func getSearchableEntryIndices() -> [Int] {
        return searchEntries.enumerated().compactMap { index, entry in
            guard !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !entry.isSearching else { return nil }
            return index
        }
    }

    @MainActor
    public func addSearchEntry() {
        let newEntry = SAMGovSearchEntry()
        searchEntries.append(newEntry)
    }

    @MainActor
    public func removeSearchEntry(at index: Int) {
        guard canRemoveSearchEntry(at: index) else { return }
        searchEntries.remove(at: index)
    }

    private func canRemoveSearchEntry(at index: Int) -> Bool {
        return index > 0 &&
               index < searchEntries.count &&
               searchEntries.count > 1 &&
               !searchEntries[index].isSearching
    }

    @MainActor
    public func selectEntityForReport(_ entity: EntityDetail) {
        selectedEntityForReport = entity
        showingReportPreview = true
    }

    @MainActor
    public func navigateToSettings() {
        // TODO: Implement navigation to settings
        showingAPIKeyAlert = false
    }

    @MainActor
    public func generateBatchReport() {
        guard !searchResults.isEmpty else { return }
        if let firstResult = searchResults.first {
            selectEntityForReport(firstResult)
        }
    }

    // MARK: - Private Helper Methods

    private func isValidSearchIndex(_ index: Int) -> Bool {
        return index >= 0 && index < searchEntries.count
    }

    @MainActor
    private func validateAndPrepareSearch(at index: Int) -> String? {
        let searchText = searchEntries[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return nil }
        return searchText
    }

    @MainActor
    private func setSearchState(at index: Int, isSearching: Bool) {
        searchEntries[index].isSearching = isSearching
        if isSearching {
            searchEntries[index].result = nil
        }
    }

    @MainActor
    private func addUniqueSearchResult(_ result: EntityDetail) {
        if !searchResults.contains(where: { $0.ueiSAM == result.ueiSAM }) {
            searchResults.append(result)
        }
    }

    @MainActor
    private func clearErrorMessage() {
        errorMessage = nil
    }

    // MARK: - Error Handling

    private func mapErrorToUserFriendlyMessage(_ error: Error) -> String {
        switch error {
        case let urlError as URLError:
            return mapURLErrorToMessage(urlError)
        case let samGovError as SAMGovError:
            return mapSAMGovErrorToMessage(samGovError)
        default:
            return error.localizedDescription
        }
    }

    private func mapURLErrorToMessage(_ urlError: URLError) -> String {
        switch urlError.code {
        case .notConnectedToInternet:
            return "No Internet connection available. Please check your network settings."
        case .timedOut:
            return "Request timed out. Please try again."
        case .cannotFindHost, .cannotConnectToHost:
            return "Cannot connect to SAM.gov servers. Please try again later."
        case .networkConnectionLost:
            return "Network connection lost. Please check your Internet connection."
        default:
            return "Network error occurred: \(urlError.localizedDescription)"
        }
    }

    private func mapSAMGovErrorToMessage(_ samGovError: SAMGovError) -> String {
        switch samGovError {
        case .rateLimited:
            return "API rate limit exceeded. Please wait a moment before trying again."
        case .invalidFormat:
            return "Invalid UEI format - must be 12 characters."
        case .authenticationFailed:
            return "Authentication failed - check API credentials."
        case .entityNotFound:
            return "Entity not found in SAM.gov database."
        default:
            return samGovError.localizedDescription
        }
    }
}

// MARK: - Supporting Data Structures

public struct SAMGovSearchEntry: Identifiable, Sendable {
    public let id = UUID()
    public var text: String = ""
    public var type: SAMGovSearchType = .cage
    public var isSearching: Bool = false
    public var result: EntityDetail?

    public init() {}
}

public enum SAMGovSearchType: String, CaseIterable, Sendable {
    case cage = "CAGE Code"
    case companyName = "Company Name"
    case uei = "UEI"

    public var placeholder: String {
        switch self {
        case .companyName: return "Enter company name..."
        case .uei: return "Enter UEI (12 characters)..."
        case .cage: return "Enter CAGE code..."
        }
    }

    public var icon: String {
        switch self {
        case .companyName: return "building.2"
        case .uei: return "number"
        case .cage: return "barcode"
        }
    }
}

// MARK: - Service Protocol

public protocol SAMGovServiceProtocol: Sendable {
    func getEntityByCAGE(_ cage: String) async throws -> EntityDetail
    func getEntityByUEI(_ uei: String) async throws -> EntityDetail
    func searchEntity(_ query: String) async throws -> EntitySearchResult
}

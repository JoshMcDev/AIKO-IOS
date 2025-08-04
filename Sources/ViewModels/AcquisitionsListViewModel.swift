import Foundation
import AppCore

/// AcquisitionsListViewModel - SwiftUI @Observable Implementation
/// PHASE 2: Business Logic View for Federal Acquisition Management
/// Supports filtering, sorting, search, and CRUD operations for government acquisitions
@MainActor
@Observable
public final class AcquisitionsListViewModel: @unchecked Sendable {

    // MARK: - Dependencies
    private let acquisitionService: AcquisitionService

    // MARK: - Published State
    public var acquisitions: [AppCore.Acquisition] = []
    public var filteredAcquisitions: [AppCore.Acquisition] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var searchText: String = ""
    public var selectedFilters: AcquisitionFilters = .init()
    public var currentSort: AcquisitionSort = .init()
    public var selectedAcquisition: AppCore.Acquisition?
    public var showingAcquisitionDetails: Bool = false
    public var showingCreateAcquisition: Bool = false

    // MARK: - Computed Properties

    /// Count of acquisitions with active status (draft, inProgress, underReview, approved, onHold)
    public var activeAcquisitionsCount: Int {
        acquisitions.filter { $0.status.isActive }.count
    }

    /// Whether any filters or search are currently applied
    public var hasFiltersApplied: Bool {
        !selectedFilters.statuses.isEmpty ||
            selectedFilters.phase != nil ||
            !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Initialization

    public init(acquisitionService: AcquisitionService = .liveValue) {
        self.acquisitionService = acquisitionService
    }

    // MARK: - Data Loading

    /// Load all acquisitions from the service
    public func loadAcquisitions() async {
        isLoading = true
        errorMessage = nil

        do {
            acquisitions = try await acquisitionService.fetchAcquisitions()
            applyFiltersAndSort()
        } catch {
            errorMessage = error.localizedDescription
            acquisitions = []
            filteredAcquisitions = []
        }

        isLoading = false
    }

    // MARK: - Filtering

    /// Toggle status filter on/off
    public func toggleStatusFilter(_ status: AcquisitionStatus) {
        if selectedFilters.statuses.contains(status) {
            selectedFilters.statuses.remove(status)
        } else {
            selectedFilters.statuses.insert(status)
        }
        applyFiltersAndSort()
    }

    /// Filter by acquisition lifecycle phase
    public func filterByPhase(_ phase: AcquisitionStatus.Phase) {
        selectedFilters.phase = phase
        applyFiltersAndSort()
    }

    /// Clear all filters and search
    public func clearAllFilters() {
        selectedFilters = .init()
        searchText = ""
        applyFiltersAndSort()
    }

    // MARK: - Search

    /// Update search text and reapply filters
    public func updateSearchText(_ text: String) {
        searchText = text
        applyFiltersAndSort()
    }

    // MARK: - Sorting

    /// Sort acquisitions by specified field and direction
    public func sortBy(_ field: AcquisitionSort.Field, ascending: Bool) {
        currentSort = AcquisitionSort(field: field, ascending: ascending)
        applyFiltersAndSort()
    }

    // MARK: - Navigation

    /// Select an acquisition to view details
    public func selectAcquisition(_ acquisition: AppCore.Acquisition) {
        selectedAcquisition = acquisition
        showingAcquisitionDetails = true
    }

    /// Show create new acquisition sheet
    public func createNewAcquisition() {
        showingCreateAcquisition = true
    }

    // MARK: - Private Helper Methods

    private func applyFiltersAndSort() {
        // Start with all acquisitions
        var filtered = acquisitions

        // Apply status filters
        if !selectedFilters.statuses.isEmpty {
            filtered = filtered.filter { selectedFilters.statuses.contains($0.status) }
        }

        // Apply phase filter
        if let phase = selectedFilters.phase {
            filtered = filtered.filter { $0.status.phase == phase }
        }

        // Apply search text
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            filtered = filtered.filter { acquisition in
                acquisition.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                    acquisition.requirements.localizedCaseInsensitiveContains(trimmedSearch) ||
                    (acquisition.projectNumber?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            }
        }

        // Apply sorting
        filtered.sort(by: { lhs, rhs in
            switch currentSort.field {
            case .title:
                return currentSort.ascending ? lhs.title < rhs.title : lhs.title > rhs.title
            case .createdDate:
                return currentSort.ascending ? lhs.createdDate < rhs.createdDate : lhs.createdDate > rhs.createdDate
            case .lastModifiedDate:
                return currentSort.ascending ? lhs.lastModifiedDate < rhs.lastModifiedDate : lhs.lastModifiedDate > rhs.lastModifiedDate
            case .status:
                return currentSort.ascending ? lhs.status.rawValue < rhs.status.rawValue : lhs.status.rawValue > rhs.status.rawValue
            }
        })

        filteredAcquisitions = filtered
    }
}

// MARK: - Supporting Types

/// Filter configuration for acquisitions list
public struct AcquisitionFilters: Sendable {
    public var statuses: Set<AcquisitionStatus> = []
    public var phase: AcquisitionStatus.Phase?

    public init() {}
}

/// Sort configuration for acquisitions list
public struct AcquisitionSort: Sendable {
    public enum Field: String, CaseIterable, Sendable {
        case title = "Title"
        case createdDate = "Created Date"
        case lastModifiedDate = "Last Modified"
        case status = "Status"
    }

    public var field: Field = .lastModifiedDate
    public var ascending: Bool = false // Default: newest first

    public init(field: Field = .lastModifiedDate, ascending: Bool = false) {
        self.field = field
        self.ascending = ascending
    }
}

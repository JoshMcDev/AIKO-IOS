@testable import AIKO
@testable import AppCore
import Foundation
import Testing

/// TDD Test Suite for AcquisitionsListViewModel
/// PHASE 2: Business Logic Views - Federal Acquisition Management
/// Tests cover: Data fetching, filtering, sorting, CRUD operations, status management
@MainActor
final class AcquisitionsListViewModelTests {
    // MARK: - Test Data Setup

    private func createMockAcquisitions() -> [AppCore.Acquisition] {
        [
            AppCore.Acquisition(
                id: UUID(),
                title: "Software Development Services",
                requirements: "Agile development team for enterprise software",
                projectNumber: "ACQ-20250123-1001",
                status: .inProgress,
                createdDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                lastModifiedDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                uploadedFiles: [],
                generatedFiles: []
            ),
            AppCore.Acquisition(
                id: UUID(),
                title: "Cloud Infrastructure Migration",
                requirements: "Migrate legacy systems to cloud infrastructure",
                projectNumber: "ACQ-20250123-1002",
                status: .underReview,
                createdDate: Date().addingTimeInterval(-86400 * 14), // 14 days ago
                lastModifiedDate: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                uploadedFiles: [],
                generatedFiles: []
            ),
            AppCore.Acquisition(
                id: UUID(),
                title: "Network Security Audit",
                requirements: "Comprehensive security assessment and recommendations",
                projectNumber: "ACQ-20250123-1003",
                status: .completed,
                createdDate: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                lastModifiedDate: Date().addingTimeInterval(-86400 * 5), // 5 days ago
                uploadedFiles: [],
                generatedFiles: []
            ),
            AppCore.Acquisition(
                id: UUID(),
                title: "Data Analytics Platform",
                requirements: "Business intelligence and analytics capabilities",
                projectNumber: "ACQ-20250123-1004",
                status: .draft,
                createdDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                lastModifiedDate: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                uploadedFiles: [],
                generatedFiles: []
            ),
        ]
    }

    private func createMockAcquisitionService() -> AcquisitionService {
        let mockAcquisitions = createMockAcquisitions()

        return AcquisitionService(
            createAcquisition: { title, requirements, uploadedDocs in
                AppCore.Acquisition(
                    title: title,
                    requirements: requirements,
                    uploadedFiles: uploadedDocs
                )
            },
            fetchAcquisitions: { mockAcquisitions },
            fetchAcquisition: { id in
                mockAcquisitions.first { $0.id == id }
            },
            updateAcquisition: { _, _ in
                // Mock implementation - in real service would update persistent storage
            },
            deleteAcquisition: { _ in
                // Mock implementation - in real service would delete from persistent storage
            },
            addUploadedFiles: { _, _ in
                // Mock implementation
            },
            addGeneratedDocuments: { _, _ in
                // Mock implementation
            },
            updateStatus: { _, _ in
                // Mock implementation
            }
        )
    }

    // MARK: - Initialization Tests

    @Test("AcquisitionsListViewModel initializes with empty state")
    func initialization() {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        #expect(viewModel.acquisitions.isEmpty)
        #expect(viewModel.filteredAcquisitions.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.selectedFilters.statuses.isEmpty)
        #expect(viewModel.selectedFilters.phase == nil)
        #expect(viewModel.searchText.isEmpty)
    }

    // MARK: - Data Loading Tests

    @Test("AcquisitionsListViewModel loads acquisitions successfully")
    func testLoadAcquisitions() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()

        #expect(viewModel.acquisitions.count == 4)
        #expect(viewModel.filteredAcquisitions.count == 4)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("AcquisitionsListViewModel handles loading errors")
    func loadAcquisitionsError() async {
        let errorService = AcquisitionService(
            createAcquisition: { _, _, _ in throw AcquisitionError.invalidData },
            fetchAcquisitions: { throw AcquisitionError.notFound },
            fetchAcquisition: { _ in nil },
            updateAcquisition: { _, _ in },
            deleteAcquisition: { _ in },
            addUploadedFiles: { _, _ in },
            addGeneratedDocuments: { _, _ in },
            updateStatus: { _, _ in }
        )
        let viewModel = AcquisitionsListViewModel(acquisitionService: errorService)

        await viewModel.loadAcquisitions()

        #expect(viewModel.acquisitions.isEmpty)
        #expect(viewModel.filteredAcquisitions.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("not found") == true)
    }

    @Test("AcquisitionsListViewModel sets loading state during fetch")
    func loadingState() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        // Initially not loading
        #expect(viewModel.isLoading == false)

        // After loading completes, should not be loading
        await viewModel.loadAcquisitions()
        #expect(viewModel.isLoading == false)
        #expect(viewModel.acquisitions.count == 4)
    }

    // MARK: - Filtering Tests

    @Test("AcquisitionsListViewModel filters by single status")
    func filterBySingleStatus() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.toggleStatusFilter(.inProgress)

        #expect(viewModel.filteredAcquisitions.count == 1)
        #expect(viewModel.filteredAcquisitions.first?.status == .inProgress)
        #expect(viewModel.selectedFilters.statuses.contains(.inProgress))
    }

    @Test("AcquisitionsListViewModel filters by multiple statuses")
    func filterByMultipleStatuses() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.toggleStatusFilter(.inProgress)
        viewModel.toggleStatusFilter(.underReview)

        #expect(viewModel.filteredAcquisitions.count == 2)
        #expect(viewModel.selectedFilters.statuses.contains(.inProgress))
        #expect(viewModel.selectedFilters.statuses.contains(.underReview))
    }

    @Test("AcquisitionsListViewModel filters by lifecycle phase")
    func testFilterByPhase() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.filterByPhase(.execution)

        let executionStatuses: Set<AcquisitionStatus> = [.inProgress, .underReview, .approved, .onHold]
        let filteredStatuses = Set(viewModel.filteredAcquisitions.map(\.status))

        #expect(viewModel.filteredAcquisitions.count >= 1)
        #expect(filteredStatuses.isSubset(of: executionStatuses))
        #expect(viewModel.selectedFilters.phase == .execution)
    }

    @Test("AcquisitionsListViewModel clears all filters")
    func testClearAllFilters() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.toggleStatusFilter(.inProgress)
        viewModel.filterByPhase(.completion)
        viewModel.clearAllFilters()

        #expect(viewModel.filteredAcquisitions.count == 4)
        #expect(viewModel.selectedFilters.statuses.isEmpty)
        #expect(viewModel.selectedFilters.phase == nil)
    }

    // MARK: - Search Tests

    @Test("AcquisitionsListViewModel searches by title")
    func searchByTitle() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.updateSearchText("Software")

        #expect(viewModel.filteredAcquisitions.count == 1)
        #expect(viewModel.filteredAcquisitions.first?.title.contains("Software") == true)
        #expect(viewModel.searchText == "Software")
    }

    @Test("AcquisitionsListViewModel searches by requirements")
    func searchByRequirements() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.updateSearchText("cloud")

        #expect(viewModel.filteredAcquisitions.count == 1)
        #expect(viewModel.filteredAcquisitions.first?.requirements.lowercased().contains("cloud") == true)
    }

    @Test("AcquisitionsListViewModel searches by project number")
    func searchByProjectNumber() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.updateSearchText("1001")

        #expect(viewModel.filteredAcquisitions.count == 1)
        #expect(viewModel.filteredAcquisitions.first?.projectNumber?.contains("1001") == true)
    }

    @Test("AcquisitionsListViewModel handles empty search results")
    func emptySearchResults() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.updateSearchText("nonexistent")

        #expect(viewModel.filteredAcquisitions.isEmpty)
        #expect(viewModel.searchText == "nonexistent")
    }

    // MARK: - Sorting Tests

    @Test("AcquisitionsListViewModel sorts by title ascending")
    func sortByTitleAscending() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.sortBy(.title, ascending: true)

        let titles = viewModel.filteredAcquisitions.map(\.title)
        let sortedTitles = titles.sorted()

        #expect(titles == sortedTitles)
        #expect(viewModel.currentSort.field == .title)
        #expect(viewModel.currentSort.ascending == true)
    }

    @Test("AcquisitionsListViewModel sorts by creation date descending")
    func sortByCreationDateDescending() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.sortBy(.createdDate, ascending: false)

        let dates = viewModel.filteredAcquisitions.map(\.createdDate)
        let sortedDates = dates.sorted(by: >)

        #expect(dates == sortedDates)
        #expect(viewModel.currentSort.field == .createdDate)
        #expect(viewModel.currentSort.ascending == false)
    }

    @Test("AcquisitionsListViewModel sorts by status")
    func sortByStatus() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.sortBy(.status, ascending: true)

        let statuses = viewModel.filteredAcquisitions.map(\.status.rawValue)
        let sortedStatuses = statuses.sorted()

        #expect(statuses == sortedStatuses)
        #expect(viewModel.currentSort.field == .status)
    }

    // MARK: - Combined Filter and Search Tests

    @Test("AcquisitionsListViewModel applies search and filters together")
    func searchAndFilterCombination() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        viewModel.updateSearchText("Software")
        viewModel.toggleStatusFilter(.inProgress)

        #expect(viewModel.filteredAcquisitions.count == 1)
        #expect(viewModel.filteredAcquisitions.first?.title.contains("Software") == true)
        #expect(viewModel.filteredAcquisitions.first?.status == .inProgress)
    }

    // MARK: - Navigation Tests

    @Test("AcquisitionsListViewModel selects acquisition for details")
    func selectAcquisitionForDetails() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        guard let firstAcquisition = viewModel.filteredAcquisitions.first else {
            #expect(Bool(false), "Expected at least one acquisition")
            return
        }
        viewModel.selectAcquisition(firstAcquisition)

        #expect(viewModel.selectedAcquisition?.id == firstAcquisition.id)
        #expect(viewModel.showingAcquisitionDetails == true)
    }

    @Test("AcquisitionsListViewModel creates new acquisition")
    func testCreateNewAcquisition() {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        viewModel.createNewAcquisition()

        #expect(viewModel.showingCreateAcquisition == true)
    }

    // MARK: - Computed Properties Tests

    @Test("AcquisitionsListViewModel computes active acquisitions count")
    func testActiveAcquisitionsCount() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()

        // Based on mock data: draft(1) + inProgress(1) + underReview(1) = 3 active
        #expect(viewModel.activeAcquisitionsCount == 3)
    }

    @Test("AcquisitionsListViewModel computes has filters applied")
    func testHasFiltersApplied() async {
        let mockService = createMockAcquisitionService()
        let viewModel = AcquisitionsListViewModel(acquisitionService: mockService)

        await viewModel.loadAcquisitions()
        #expect(viewModel.hasFiltersApplied == false)

        viewModel.toggleStatusFilter(.inProgress)
        #expect(viewModel.hasFiltersApplied == true)

        viewModel.clearAllFilters()
        #expect(viewModel.hasFiltersApplied == false)

        viewModel.updateSearchText("test")
        #expect(viewModel.hasFiltersApplied == true)
    }
}

// MARK: - Supporting Types for Tests

enum AcquisitionError: LocalizedError {
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notFound:
            "Acquisition not found"
        case .invalidData:
            "Invalid acquisition data"
        }
    }
}

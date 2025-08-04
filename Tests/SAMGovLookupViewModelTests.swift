import Testing
import Foundation
import AppCore
@testable import AIKO

/// SAMGovLookupViewModel Test Suite
/// PHASE 2: TDD Implementation - RED PHASE
/// Following PHASE2_Restore_Business_Logic_Views_rubric.md requirements

final class SAMGovLookupViewModelTests {

    // MARK: - Core Functionality Tests (RED PHASE)

    @Test("SAMGov CAGE code search returns valid EntityDetail")
    func testCAGECodeSearchSuccess() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let expectedEntity = EntityDetail.mockCAGEEntity()
        await mockService.setEntityByCAGE("1ABC2", result: .success(expectedEntity))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "1ABC2"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.searchEntries[0].result?.ueiSAM == expectedEntity.ueiSAM)
        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("UEI search with valid 12-character UEI")
    func testValidUEISearch() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let expectedEntity = EntityDetail.mockUEIEntity()
        await mockService.setEntityByUEI("ABC123DEF456", result: .success(expectedEntity))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "ABC123DEF456"
        viewModel.searchEntries[0].type = .uei
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.searchEntries[0].result?.ueiSAM == expectedEntity.ueiSAM)
        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Company name search with exact match")
    func testCompanyNameExactMatch() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let searchResult = EntitySearchResult.mockSearchResult()
        let expectedEntity = EntityDetail.mockCompanyEntity()
        await mockService.setSearchEntity("Test Defense Contractor", result: .success(searchResult))
        guard let firstEntity = searchResult.entities.first else {
            fatalError("Expected at least one entity in search results")
        }
        await mockService.setEntityByUEI(firstEntity.ueiSAM, result: .success(expectedEntity))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "Test Defense Contractor"
        viewModel.searchEntries[0].type = .companyName
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.searchEntries[0].result?.entityName == expectedEntity.entityName)
        #expect(viewModel.searchResults.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Multiple simultaneous searches complete successfully")
    func testBatchSearchSuccess() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let entity1 = EntityDetail.mockCAGEEntity()
        let entity2 = EntityDetail.mockUEIEntity()
        await mockService.setEntityByCAGE("1ABC2", result: .success(entity1))
        await mockService.setEntityByUEI("XYZ789UVW012", result: .success(entity2))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "1ABC2"
        viewModel.searchEntries[0].type = .cage
        viewModel.searchEntries[1].text = "XYZ789UVW012"
        viewModel.searchEntries[1].type = .uei
        await viewModel.performAllSearches()

        // ASSERT
        #expect(viewModel.searchResults.count == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Add search entry increases entry count")
    @MainActor func testAddSearchEntry() {
        // ARRANGE
        let viewModel = SAMGovLookupViewModel(samGovService: MockSAMGovService())
        let initialCount = viewModel.searchEntries.count

        // ACT
        viewModel.addSearchEntry()

        // ASSERT
        #expect(viewModel.searchEntries.count == initialCount + 1)
    }

    @Test("Remove search entry decreases count (except first entry)")
    @MainActor func testRemoveSearchEntry() {
        // ARRANGE
        let viewModel = SAMGovLookupViewModel(samGovService: MockSAMGovService())
        viewModel.addSearchEntry() // Add a second entry
        let initialCount = viewModel.searchEntries.count

        // ACT
        viewModel.removeSearchEntry(at: 1) // Remove second entry

        // ASSERT
        #expect(viewModel.searchEntries.count == initialCount - 1)
        #expect(viewModel.searchEntries.count >= 1) // First entry always remains
    }

    @Test("Invalid CAGE code shows appropriate error")
    func testInvalidCAGEError() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        await mockService.setEntityByCAGE("INVALID", result: .failure(SAMGovError.entityNotFound))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "INVALID"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.searchEntries[0].result == nil)
    }

    @Test("Network failure displays user-friendly message")
    func testNetworkFailureHandling() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        await mockService.setEntityByCAGE("NETWORK_FAIL", result: .failure(URLError(.notConnectedToInternet)))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "NETWORK_FAIL"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.errorMessage?.contains("Internet") == true)
        #expect(viewModel.searchEntries[0].isSearching == false)
    }

    @Test("API rate limiting handled gracefully")
    func testRateLimitHandling() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        await mockService.setEntityByCAGE("RATE_LIMITED", result: .failure(SAMGovError.rateLimited))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "RATE_LIMITED"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.errorMessage?.contains("rate limit") == true)
        #expect(viewModel.searchEntries[0].isSearching == false)
    }

    @Test("Search state updates correctly during async operations")
    func testSearchStateManagement() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let entity = EntityDetail.mockCAGEEntity()
        await mockService.setEntityByCAGE("1ABC2", result: .success(entity))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT & ASSERT
        viewModel.searchEntries[0].text = "1ABC2"
        viewModel.searchEntries[0].type = .cage

        // Initial state
        #expect(viewModel.searchEntries[0].isSearching == false)

        await viewModel.performSearch(for: 0)

        // Final state
        #expect(viewModel.searchEntries[0].isSearching == false)
        #expect(viewModel.searchEntries[0].result != nil)
    }

    @Test("Multiple search results accumulate properly")
    func testResultAccumulation() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let entity1 = EntityDetail.mockCAGEEntity()
        let entity2 = EntityDetail.mockUEIEntity()
        await mockService.setEntityByCAGE("1ABC2", result: .success(entity1))
        await mockService.setEntityByUEI("XYZ789UVW012", result: .success(entity2))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "1ABC2"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        viewModel.searchEntries[1].text = "XYZ789UVW012"
        viewModel.searchEntries[1].type = .uei
        await viewModel.performSearch(for: 1)

        // ASSERT
        #expect(viewModel.searchResults.count == 2)
        #expect(viewModel.searchResults.contains { $0.ueiSAM == entity1.ueiSAM })
        #expect(viewModel.searchResults.contains { $0.ueiSAM == entity2.ueiSAM })
    }

    // MARK: - Service Integration Tests (RED PHASE)

    @Test("SAMGovService dependency injection functional")
    func testServiceInjection() {
        // ARRANGE & ACT
        let service = MockSAMGovService()
        let viewModel = SAMGovLookupViewModel(samGovService: service)

        // ASSERT
        #expect(viewModel.searchEntries.count >= 3) // ViewModel initialized with 3 default entries
    }

    @Test("Mock service responses handled correctly")
    func testMockServiceIntegration() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let expectedEntity = EntityDetail.mockCAGEEntity()
        await mockService.setEntityByCAGE("TEST123", result: .success(expectedEntity))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "TEST123"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.searchEntries[0].result?.entityName == expectedEntity.entityName)
    }

    @Test("Service error propagation to ViewModel")
    func testServiceErrorHandling() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        let testError = SAMGovError.authenticationFailed
        await mockService.setEntityByCAGE("AUTH_FAIL", result: .failure(testError))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "AUTH_FAIL"
        viewModel.searchEntries[0].type = .cage
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.searchEntries[0].result == nil)
    }

    @Test("Invalid UEI format shows validation error")
    func testInvalidUEIValidation() async {
        // ARRANGE
        let mockService = MockSAMGovService()
        await mockService.setEntityByUEI("INVALID_UEI", result: .failure(SAMGovError.invalidFormat))
        let viewModel = SAMGovLookupViewModel(samGovService: mockService)

        // ACT
        viewModel.searchEntries[0].text = "INVALID_UEI"
        viewModel.searchEntries[0].type = .uei
        await viewModel.performSearch(for: 0)

        // ASSERT
        #expect(viewModel.errorMessage?.contains("UEI format") == true)
    }
}

// MARK: - Mock Service Implementation

/// Mock SAMGovService for testing
/// Implements the service protocol for isolated testing
actor MockSAMGovService: SAMGovServiceProtocol {
    private var cageResults: [String: Result<EntityDetail, Error>] = [:]
    private var ueiResults: [String: Result<EntityDetail, Error>] = [:]
    private var searchResults: [String: Result<EntitySearchResult, Error>] = [:]

    func setEntityByCAGE(_ cage: String, result: Result<EntityDetail, Error>) {
        cageResults[cage] = result
    }

    func setEntityByUEI(_ uei: String, result: Result<EntityDetail, Error>) {
        ueiResults[uei] = result
    }

    func setSearchEntity(_ query: String, result: Result<EntitySearchResult, Error>) {
        searchResults[query] = result
    }

    func getEntityByCAGE(_ cage: String) async throws -> EntityDetail {
        guard let result = cageResults[cage] else {
            throw SAMGovError.entityNotFound
        }

        switch result {
        case .success(let entity): return entity
        case .failure(let error): throw error
        }
    }

    func getEntityByUEI(_ uei: String) async throws -> EntityDetail {
        guard let result = ueiResults[uei] else {
            throw SAMGovError.entityNotFound
        }

        switch result {
        case .success(let entity): return entity
        case .failure(let error): throw error
        }
    }

    func searchEntity(_ query: String) async throws -> EntitySearchResult {
        guard let result = searchResults[query] else {
            throw SAMGovError.entityNotFound
        }

        switch result {
        case .success(let searchResult): return searchResult
        case .failure(let error): throw error
        }
    }
}

// MARK: - Test Data Fixtures

extension EntityDetail {
    static func mockCAGEEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "ABC123DEF456",
            entityName: "Test Defense Contractor",
            legalBusinessName: "Test Defense Contractor LLC",
            cageCode: "1ABC2",
            registrationStatus: "Active",
            businessTypes: ["Small Business", "Veteran-Owned"],
            hasActiveExclusions: false
        )
    }

    static func mockUEIEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "XYZ789UVW012",
            entityName: "UEI Test Entity",
            legalBusinessName: "UEI Test Entity Inc",
            cageCode: "9XYZ8",
            registrationStatus: "Active",
            businessTypes: ["Large Business"],
            hasActiveExclusions: false
        )
    }

    static func mockCompanyEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "COMP123ENTITY",
            entityName: "Test Defense Contractor",
            legalBusinessName: "Test Defense Contractor Corporation",
            cageCode: "COMP1",
            registrationStatus: "Active",
            businessTypes: ["Small Business", "Woman-Owned"],
            hasActiveExclusions: false
        )
    }

    static func mockExcludedEntity() -> EntityDetail {
        EntityDetail(
            ueiSAM: "EXCL789ENTITY",
            entityName: "Excluded Contractor",
            legalBusinessName: "Excluded Contractor Inc",
            cageCode: "EXCL9",
            registrationStatus: "Active",
            businessTypes: ["Large Business"],
            hasActiveExclusions: true
        )
    }
}

extension EntitySearchResult {
    static func mockSearchResult() -> EntitySearchResult {
        EntitySearchResult(
            entities: [
                EntitySummary(
                    ueiSAM: "COMP123ENTITY",
                    entityName: "Test Defense Contractor",
                    registrationStatus: "Active"
                )
            ],
            totalCount: 1
        )
    }
}

// MARK: - SAMGov Errors for Testing
// Note: Using SAMGovError from SAMGovService.swift

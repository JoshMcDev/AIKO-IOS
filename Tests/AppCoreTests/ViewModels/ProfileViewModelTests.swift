//
//  ProfileViewModelTests.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import XCTest
@testable import AppCore

/// ProfileViewModelTests - TDD RED Phase
/// Comprehensive test suite for ProfileViewModel following TDD rubric
/// Target Coverage: >95%
final class ProfileViewModelTests: XCTestCase {
    
    @MainActor
    private func createViewModel() -> (ProfileViewModel, MockProfileService) {
        let mockService = MockProfileService()
        let viewModel = ProfileViewModel(service: mockService)
        return (viewModel, mockService)
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testInitialization_SetsCorrectDefaults() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Assert
        XCTAssertEqual(sut.uiState, .idle)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isEditing)
        XCTAssertFalse(sut.isSaving)
        XCTAssertNotNil(sut.profile)
    }
    
    // MARK: - Profile Loading Tests
    
    @MainActor
    func testLoadProfile_Success_UpdatesProfile() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        let expectedProfile = UserProfile.mock()
        mockService.loadProfileResult = .success(expectedProfile)
        
        // Act
        await sut.loadProfile()
        
        // Assert
        XCTAssertEqual(sut.profile, expectedProfile)
        XCTAssertEqual(sut.uiState, .loaded)
        XCTAssertNil(sut.error)
    }
    
    @MainActor
    func testLoadProfile_Failure_SetsError() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        mockService.loadProfileResult = .failure(ProfileError.loadFailed)
        
        // Act
        await sut.loadProfile()
        
        // Assert
        XCTAssertEqual(sut.uiState, .error)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error as? ProfileError, ProfileError.loadFailed)
    }
    
    // MARK: - Field Validation Tests
    
    @MainActor
    func testValidateEmail_ValidEmail_ReturnsNil() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Act
        let error = sut.validateEmail("test@example.com")
        
        // Assert
        XCTAssertNil(error)
    }
    
    @MainActor
    func testValidateEmail_InvalidEmail_ReturnsError() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Act
        let error = sut.validateEmail("invalid-email")
        
        // Assert
        XCTAssertNotNil(error)
        XCTAssertEqual(error, "Invalid email format")
    }
    
    @MainActor
    func testValidatePhone_ValidPhone_ReturnsNil() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Act
        let error = sut.validatePhone("+1 (555) 123-4567")
        
        // Assert
        XCTAssertNil(error)
    }
    
    @MainActor
    func testValidatePhone_InvalidPhone_ReturnsError() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Act
        let error = sut.validatePhone("123")
        
        // Assert
        XCTAssertNotNil(error)
        XCTAssertEqual(error, "Invalid phone number format")
    }
    
    @MainActor
    func testValidateRequired_NotEmpty_ReturnsNil() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Act
        let error = sut.validateRequired("John Doe", fieldName: "Name")
        
        // Assert
        XCTAssertNil(error)
    }
    
    @MainActor
    func testValidateRequired_Empty_ReturnsError() async {
        // Arrange
        let (sut, _) = createViewModel()
        
        // Act
        let error = sut.validateRequired("", fieldName: "Name")
        
        // Assert
        XCTAssertNotNil(error)
        XCTAssertEqual(error, "Name is required")
    }
    
    // MARK: - Save Functionality Tests
    
    @MainActor
    func testSaveProfile_Success_UpdatesStateCorrectly() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        sut.profile.fullName = "John Doe"
        mockService.saveProfileResult = .success(())
        
        // Act
        await sut.saveProfile()
        
        // Assert
        XCTAssertFalse(sut.isSaving)
        XCTAssertEqual(sut.uiState, .loaded)
        XCTAssertNil(sut.error)
        XCTAssertTrue(mockService.saveProfileCalled)
        XCTAssertEqual(mockService.savedProfile?.fullName, "John Doe")
    }
    
    @MainActor
    func testSaveProfile_Failure_SetsError() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        mockService.saveProfileResult = .failure(ProfileError.saveFailed)
        
        // Act
        await sut.saveProfile()
        
        // Assert
        XCTAssertFalse(sut.isSaving)
        XCTAssertEqual(sut.uiState, .error)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error as? ProfileError, ProfileError.saveFailed)
    }
    
    @MainActor
    func testSaveProfile_WithValidation_ValidatesBeforeSaving() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        sut.profile.email = "invalid-email"
        sut.profile.fullName = "" // Required field empty
        
        // Act
        await sut.saveProfile()
        
        // Assert
        XCTAssertFalse(sut.isSaving)
        XCTAssertFalse(mockService.saveProfileCalled) // Should not save
        XCTAssertNotNil(sut.validationErrors["email"])
        XCTAssertNotNil(sut.validationErrors["fullName"])
    }
    
    // MARK: - Profile Completion Tests
    
    @MainActor
    func testProfileCompletion_AllRequiredFields_Returns100Percent() async {
        // Arrange
        let (sut, _) = createViewModel()
        sut.profile = UserProfile(
            fullName: "John Doe",
            title: "Senior Developer",
            email: "john@example.com",
            phoneNumber: "+1-555-123-4567",
            organizationName: "AIKO Corp"
        )
        
        // Act
        let completion = sut.profileCompletionPercentage
        
        // Assert
        XCTAssertEqual(completion, 1.0)
    }
    
    @MainActor
    func testProfileCompletion_MissingOptionalFields_ReturnsPartialCompletion() async {
        // Arrange
        let (sut, _) = createViewModel()
        sut.profile = UserProfile(
            fullName: "John Doe",
            title: "",
            email: "john@example.com",
            phoneNumber: "",
            organizationName: ""
        )
        
        // Act
        let completion = sut.profileCompletionPercentage
        
        // Assert
        XCTAssertLessThan(completion, 1.0)
        XCTAssertGreaterThan(completion, 0.0)
    }
    
    // MARK: - Edit Mode Tests
    
    @MainActor
    func testToggleEditMode_TogglesCorrectly() async {
        // Arrange
        let (sut, _) = createViewModel()
        XCTAssertFalse(sut.isEditing)
        
        // Act
        sut.toggleEditMode()
        
        // Assert
        XCTAssertTrue(sut.isEditing)
        
        // Act again
        sut.toggleEditMode()
        
        // Assert
        XCTAssertFalse(sut.isEditing)
    }
    
    @MainActor
    func testCancelEditing_ResetsToOriginalProfile() async throws {
        // Arrange
        let (sut, _) = createViewModel()
        let originalProfile = UserProfile(fullName: "Original Name")
        sut.profile = originalProfile
        sut.isEditing = true
        sut.profile.fullName = "Modified Name"
        
        // Act
        sut.cancelEditing()
        
        // Assert
        XCTAssertEqual(sut.profile.fullName, "Original Name")
        XCTAssertFalse(sut.isEditing)
    }
    
    // MARK: - Auto-Save Tests
    
    @MainActor
    func testAutoSave_DebouncesMultipleChanges() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        sut.enableAutoSave = true
        sut.isEditing = true
        
        // Act - Make rapid changes
        sut.profile.fullName = "Change 1"
        sut.profile.fullName = "Change 2"
        sut.profile.fullName = "Change 3"
        
        // Wait for debounce
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Assert
        XCTAssertTrue(mockService.saveProfileCalled)
        XCTAssertEqual(mockService.saveProfileCallCount, 1) // Only one save
        XCTAssertEqual(mockService.savedProfile?.fullName, "Change 3")
    }
    
    // MARK: - Profile Image Tests
    
    @MainActor
    func testUpdateProfileImage_Success_UpdatesImageData() async throws {
        // Arrange
        let (sut, mockService) = createViewModel()
        let imageData = Data("test-image".utf8)
        mockService.saveProfileResult = .success(())
        
        // Act
        await sut.updateProfileImage(imageData)
        
        // Assert
        XCTAssertEqual(sut.profile.profileImageData, imageData)
        XCTAssertTrue(mockService.saveProfileCalled)
    }
    
    // MARK: - Address Management Tests
    
    @MainActor
    func testCopyMailingToBilling_CopiesCorrectly() async {
        // Arrange
        let (sut, _) = createViewModel()
        sut.profile.mailingAddress = Address(
            street1: "123 Main St",
            city: "Anytown",
            state: "CA",
            zipCode: "12345",
            country: "USA"
        )
        
        // Act
        sut.copyMailingToBillingAddress()
        
        // Assert
        XCTAssertEqual(sut.profile.billingAddress, sut.profile.mailingAddress)
    }
}

// MARK: - Mock Service

private final class MockProfileService: ProfileServiceProtocol, @unchecked Sendable {
    var loadProfileResult: Result<UserProfile, Error> = .success(UserProfile())
    var saveProfileResult: Result<Void, Error> = .success(())
    
    var loadProfileCalled = false
    var saveProfileCalled = false
    var saveProfileCallCount = 0
    var savedProfile: UserProfile?
    
    func loadProfile() async throws -> UserProfile {
        loadProfileCalled = true
        switch loadProfileResult {
        case .success(let profile):
            return profile
        case .failure(let error):
            throw error
        }
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        saveProfileCalled = true
        saveProfileCallCount += 1
        savedProfile = profile
        switch saveProfileResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Test Helpers

private enum ProfileError: Error, Equatable {
    case loadFailed
    case saveFailed
}

private extension UserProfile {
    static func mock() -> UserProfile {
        UserProfile(
            fullName: "Test User",
            title: "Test Title",
            email: "test@example.com",
            phoneNumber: "+1-555-123-4567",
            organizationName: "Test Organization"
        )
    }
}
//
//  ProfileViewModel.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import Foundation
import SwiftUI

/// ProfileViewModel - SwiftUI @Observable pattern implementation
/// Manages user profile state and business logic
/// Replaces TCA pattern with native SwiftUI state management
@MainActor
@Observable
public final class ProfileViewModel: ObservableObject {
    // MARK: - Constants

    private enum Constants {
        static let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        static let minimumPhoneDigits = 10
        static let autoSaveDebounceInterval: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
    }

    private enum ValidationMessage {
        static let invalidEmail = "Invalid email format"
        static let invalidPhone = "Invalid phone number format"
        static func requiredField(_ fieldName: String) -> String {
            "\(fieldName) is required"
        }
    }

    // MARK: - UI State

    public enum UIState: Equatable {
        case idle
        case loading
        case loaded
        case saving
        case error
    }

    // MARK: - Published State

    public var uiState: UIState = .idle
    public var profile = UserProfile()
    public var error: Error?
    public var isEditing = false
    public var isSaving = false
    public var validationErrors: [String: String] = [:]
    public var enableAutoSave = false

    // MARK: - Dependencies

    private let service: ProfileServiceProtocol
    @ObservationIgnored
    private var autoSaveTask: Task<Void, Never>?
    private var originalProfile: UserProfile?

    // MARK: - Initialization

    public init(service: ProfileServiceProtocol = ProfileService()) {
        self.service = service
    }

    deinit {
        autoSaveTask?.cancel()
    }

    // MARK: - Public Methods

    public func loadProfile() async {
        uiState = .loading
        error = nil

        do {
            profile = try await service.loadProfile()
            uiState = .loaded
        } catch {
            self.error = error
            uiState = .error
        }
    }

    public func saveProfile() async {
        // Validate before saving
        if !validateProfile() {
            return
        }

        isSaving = true
        uiState = .saving
        error = nil

        do {
            try await service.saveProfile(profile)
            uiState = .loaded
        } catch {
            self.error = error
            uiState = .error
        }

        isSaving = false
    }

    public func toggleEditMode() {
        if isEditing {
            // Exiting edit mode
            isEditing = false
            autoSaveTask?.cancel()
        } else {
            // Entering edit mode
            originalProfile = profile
            isEditing = true
            if enableAutoSave {
                startAutoSave()
            }
        }
    }

    public func cancelEditing() {
        if let originalProfile {
            profile = originalProfile
        }
        isEditing = false
        validationErrors.removeAll()
        autoSaveTask?.cancel()
    }

    public func updateProfileImage(_ imageData: Data) async {
        profile.profileImageData = imageData
        await saveProfile()
    }

    public func copyMailingToBillingAddress() {
        profile.billingAddress = profile.mailingAddress
    }

    // MARK: - Validation

    public func validateEmail(_ email: String) -> String? {
        let predicate = NSPredicate(format: "SELF MATCHES %@", Constants.emailRegex)
        return predicate.evaluate(with: email) ? nil : ValidationMessage.invalidEmail
    }

    public func validatePhone(_ phone: String) -> String? {
        // Remove non-numeric characters for validation
        let cleanPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleanPhone.count >= Constants.minimumPhoneDigits ? nil : ValidationMessage.invalidPhone
    }

    public func validateRequired(_ value: String, fieldName: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ValidationMessage.requiredField(fieldName) : nil
    }

    // MARK: - Computed Properties

    public var profileCompletionPercentage: Double {
        // Delegate to the UserProfile's own completionPercentage implementation
        profile.completionPercentage
    }

    // MARK: - Private Methods

    private func validateProfile() -> Bool {
        validationErrors.removeAll()

        // Validate required fields
        if let error = validateRequired(profile.fullName, fieldName: "fullName") {
            validationErrors["fullName"] = error
        }

        // Validate email if provided
        if !profile.email.isEmpty {
            if let error = validateEmail(profile.email) {
                validationErrors["email"] = error
            }
        }

        // Validate phone if provided
        if !profile.phoneNumber.isEmpty {
            if let error = validatePhone(profile.phoneNumber) {
                validationErrors["phoneNumber"] = error
            }
        }

        return validationErrors.isEmpty
    }

    private func startAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            while !Task.isCancelled, isEditing {
                do {
                    try await Task.sleep(nanoseconds: Constants.autoSaveDebounceInterval)
                    if !Task.isCancelled, isEditing, validateProfile() {
                        await saveProfile()
                    }
                } catch {
                    break
                }
            }
        }
    }
}

// MARK: - ProfileServiceProtocol

public protocol ProfileServiceProtocol: Sendable {
    func loadProfile() async throws -> UserProfile
    func saveProfile(_ profile: UserProfile) async throws
}

// MARK: - Default ProfileService Implementation

public actor ProfileService: ProfileServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let profileKey = "com.aiko.userProfile"

    public init() {}

    public func loadProfile() async throws -> UserProfile {
        guard let data = userDefaults.data(forKey: profileKey) else {
            return UserProfile()
        }

        let decoder = JSONDecoder()
        return try decoder.decode(UserProfile.self, from: data)
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        userDefaults.set(data, forKey: profileKey)
    }
}

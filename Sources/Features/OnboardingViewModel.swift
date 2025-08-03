import SwiftUI
import Foundation
import LocalAuthentication
import AppCore

// MARK: - OnboardingStep Enum

@frozen
public enum OnboardingStep: Int, CaseIterable, Comparable {
    case welcome = 0
    case apiSetup = 1
    case permissions = 2
    case completion = 3

    public static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public extension OnboardingStep {
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to AIKO"
        case .apiSetup:
            return "API Configuration"
        case .permissions:
            return "Permissions"
        case .completion:
            return "Setup Complete"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Let's get started with a quick introduction to set up your AI assistant."
        case .apiSetup:
            return "Configure your API keys to connect with AI services for enhanced functionality."
        case .permissions:
            return "Grant necessary permissions for optimal security and user experience."
        case .completion:
            return "Your setup is now complete! You're ready to start using AIKO."
        }
    }

    var progress: Double {
        switch self {
        case .welcome:
            return 0.25
        case .apiSetup:
            return 0.5
        case .permissions:
            return 0.75
        case .completion:
            return 1.0
        }
    }
}

// MARK: - OnboardingViewModel

@MainActor
@Observable
public final class OnboardingViewModel {

    // MARK: - Dependencies

    private let settingsManager: SettingsManager

    // MARK: - State Properties

    public var currentStep: OnboardingStep = .welcome
    public var isCompleted: Bool = false
    public var isLoading: Bool = false

    // MARK: - Onboarding Completion State

    public var isOnboardingCompleted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "onboardingCompleted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "onboardingCompleted")
        }
    }

    // MARK: - Navigation Properties

    public var navigationPath = NavigationPath()

    // MARK: - API Key Properties

    public var apiKey: String = ""
    public var isAPIKeyValidated: Bool = false
    public var validationError: String?

    // MARK: - Permissions Properties

    public var faceIDEnabled: Bool = false

    // MARK: - Computed Properties

    public var canProceed: Bool {
        if isLoading {
            return false
        }

        switch currentStep {
        case .welcome:
            return true
        case .apiSetup:
            return !apiKey.isEmpty && isAPIKeyValidated
        case .permissions:
            return true
        case .completion:
            return !apiKey.isEmpty && isAPIKeyValidated
        }
    }

    // MARK: - Initialization

    public init(settingsManager: SettingsManager = .liveValue) {
        self.settingsManager = settingsManager
        // Initialize with default state
    }

    // MARK: - Navigation Methods

    public func nextStep() {
        guard currentStep != .completion else { return }

        let nextStepValue = currentStep.rawValue + 1
        if let nextStep = OnboardingStep(rawValue: nextStepValue) {
            currentStep = nextStep
        }
    }

    public func proceedToNext() async {
        guard canProceed else { return }

        isLoading = true

        // Add any async validation or setup needed before proceeding
        switch currentStep {
        case .welcome:
            // No special handling needed for welcome step
            break
        case .apiSetup:
            // Validate API key if not already validated
            if !isAPIKeyValidated && !apiKey.isEmpty {
                await validateAPIKey()
            }
        case .permissions:
            // No special handling needed for permissions step
            break
        case .completion:
            // This should trigger completion workflow
            await completeOnboarding()
            isLoading = false
            return
        }

        nextStep()
        isLoading = false
    }

    public func previousStep() {
        guard currentStep != .welcome else { return }

        let previousStepValue = currentStep.rawValue - 1
        if let previousStep = OnboardingStep(rawValue: previousStepValue) {
            currentStep = previousStep
        }
    }

    public func skipStep() {
        // Only allow skipping API setup, not completion
        guard currentStep != .completion else { return }
        nextStep()
    }

    public func skipAPISetup() async {
        // Special method for skipping API setup step
        guard currentStep == .apiSetup else { return }
        isLoading = true
        nextStep()
        isLoading = false
    }

    public func goBack() async {
        // Go to previous step
        isLoading = true
        previousStep()
        isLoading = false
    }

    // MARK: - API Key Methods

    public func validateAPIKey() async {
        guard !apiKey.isEmpty else {
            validationError = "API key cannot be empty"
            isAPIKeyValidated = false
            return
        }

        isLoading = true
        validationError = nil

        // Use SettingsManager's real validation
        let isValid = await settingsManager.validateAPIKey(apiKey)

        if isValid {
            isAPIKeyValidated = true
            validationError = nil
        } else {
            isAPIKeyValidated = false
            validationError = "API key format is invalid. Must start with 'sk-ant-' and be at least 20 characters."
        }

        isLoading = false
    }

    // MARK: - Face ID Methods

    public func toggleFaceID(_ enabled: Bool) async {
        guard enabled else {
            // Simply disable Face ID
            faceIDEnabled = false
            return
        }

        isLoading = true

        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let reason = "Enable biometric authentication for secure access to your API keys"
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)

                if success {
                    faceIDEnabled = true
                } else {
                    faceIDEnabled = false
                    // User cancelled or authentication failed
                }
            } catch {
                faceIDEnabled = false
                print("Face ID authentication failed: \(error.localizedDescription)")
            }
        } else {
            faceIDEnabled = false
            print("Face ID not available: \(error?.localizedDescription ?? "Unknown error")")
        }

        isLoading = false
    }

    // MARK: - Completion Methods

    public func completeOnboarding() async {
        guard canProceed else { return }

        isLoading = true

        do {
            // Save API key to Keychain using SettingsManager
            if !apiKey.isEmpty {
                try await settingsManager.saveAPIKey(apiKey)
            }

            // Load current settings and update Face ID preference
            var settings = try await settingsManager.loadSettings()
            settings.appSettings.faceIDEnabled = faceIDEnabled

            // Save updated settings
            try await settingsManager.saveSettings()

            // Mark onboarding as completed
            UserDefaults.standard.set(true, forKey: "onboardingCompleted")

            isCompleted = true

        } catch {
            print("Failed to complete onboarding: \(error.localizedDescription)")
            // Handle error gracefully - could show alert to user
            validationError = "Failed to save settings. Please try again."
        }

        isLoading = false
    }
}

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentStep: Step = .welcome
        public var profile: UserProfile = .init()
        public var isLoading: Bool = false
        public var showingImagePicker: Bool = false
        public var imagePickerType: ProfileFeature.State.ImageType = .profile
        public var validationErrors: [String] = []
        public var apiKey: String = ""
        public var showingAPIKey: Bool = false
        public var apiKeyValidated: Bool = false
        public var faceIDEnabled: Bool = false

        public enum Step: Int, CaseIterable {
            case welcome = 0
            case personalInfo = 1
            case contactInfo = 2
            case organizationInfo = 3
            case addresses = 4
            case apiKey = 5
            case review = 6

            var title: String {
                switch self {
                case .welcome: "Welcome to AIKO"
                case .personalInfo: "Personal Information"
                case .contactInfo: "Contact Information"
                case .organizationInfo: "Organization"
                case .addresses: "Default Addresses"
                case .apiKey: "API Configuration"
                case .review: "Review & Complete"
                }
            }

            var subtitle: String {
                switch self {
                case .welcome: "Let's set up your profile"
                case .personalInfo: "Tell us about yourself"
                case .contactInfo: "How can we reach you?"
                case .organizationInfo: "Your organization details"
                case .addresses: "Set your default addresses"
                case .apiKey: "Configure your Anthropic API key"
                case .review: "Review your information"
                }
            }

            var progress: Double {
                Double(rawValue + 1) / Double(Step.allCases.count)
            }
        }

        public init() {}

        public var canProceed: Bool {
            switch currentStep {
            case .welcome:
                true

            case .personalInfo:
                // Only full name is required
                !profile.fullName.isEmpty

            case .contactInfo:
                // Only email is required
                !profile.email.isEmpty

            case .organizationInfo:
                // Organization info is optional
                true

            case .addresses:
                // Addresses are optional
                true

            case .apiKey:
                // API key is required and must be validated
                apiKeyValidated

            case .review:
                true
            }
        }
    }

    public enum Action {
        case nextStep
        case previousStep
        case skipStep
        case completeOnboarding
        case onboardingCompleted

        // Profile updates
        case updateFullName(String)
        case updateTitle(String)
        case updatePosition(String)
        case updateEmail(String)
        case updateAlternateEmail(String)
        case updatePhoneNumber(String)
        case updateAlternatePhoneNumber(String)
        case updateOrganizationName(String)
        case updateOrganizationalDODAAC(String)
        case updateAddress(ProfileFeature.State.AddressType, Address)

        // Image actions
        case showImagePicker(ProfileFeature.State.ImageType)
        case dismissImagePicker
        case updateProfileImage(Data)
        case updateOrganizationLogo(Data)

        // Address copying
        case copyAddressToAll
        case copyPaymentToDelivery
        case copyDeliveryToPayment

        // API key actions
        case updateAPIKey(String)
        case toggleShowAPIKey(Bool)
        case validateAPIKey
        case apiKeyValidationResult(Bool)

        // Face ID
        case toggleFaceID(Bool)
    }

    @Dependency(\.userProfileService) var userProfileService
    @Dependency(\.settingsManager) var settingsManager

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nextStep:
                guard state.canProceed else { return .none }

                if let nextStep = State.Step(rawValue: state.currentStep.rawValue + 1) {
                    state.currentStep = nextStep
                }
                return .none

            case .previousStep:
                if let previousStep = State.Step(rawValue: state.currentStep.rawValue - 1) {
                    state.currentStep = previousStep
                }
                return .none

            case .skipStep:
                if let nextStep = State.Step(rawValue: state.currentStep.rawValue + 1) {
                    state.currentStep = nextStep
                }
                return .none

            case .completeOnboarding:
                state.isLoading = true
                return .run { [profile = state.profile, faceIDEnabled = state.faceIDEnabled] send in
                    try await userProfileService.saveProfile(profile)
                    // Save Face ID preference
                    if faceIDEnabled {
                        var settings = try await settingsManager.loadSettings()
                        settings.appSettings.faceIDEnabled = true
                        try await settingsManager.saveSettings()
                    }
                    await send(.onboardingCompleted)
                }

            case .onboardingCompleted:
                state.isLoading = false
                return .none

            case let .updateFullName(name):
                state.profile.fullName = name
                return .none

            case let .updateTitle(title):
                state.profile.title = title
                return .none

            case let .updatePosition(position):
                state.profile.position = position
                return .none

            case let .updateEmail(email):
                state.profile.email = email
                return .none

            case let .updateAlternateEmail(email):
                state.profile.alternateEmail = email
                return .none

            case let .updatePhoneNumber(phone):
                state.profile.phoneNumber = phone
                return .none

            case let .updateAlternatePhoneNumber(phone):
                state.profile.alternatePhoneNumber = phone
                return .none

            case let .updateOrganizationName(name):
                state.profile.organizationName = name
                return .none

            case let .updateOrganizationalDODAAC(dodaac):
                state.profile.organizationalDODAAC = dodaac.uppercased()
                return .none

            case let .updateAddress(type, address):
                switch type {
                case .administeredBy:
                    state.profile.defaultAdministeredByAddress = address
                case .payment:
                    state.profile.defaultPaymentAddress = address
                case .delivery:
                    state.profile.defaultDeliveryAddress = address
                }
                return .none

            case let .showImagePicker(type):
                state.imagePickerType = type
                state.showingImagePicker = true
                return .none

            case .dismissImagePicker:
                state.showingImagePicker = false
                return .none

            case let .updateProfileImage(data):
                state.profile.profileImageData = data
                state.showingImagePicker = false
                return .none

            case let .updateOrganizationLogo(data):
                state.profile.organizationLogoData = data
                state.showingImagePicker = false
                return .none

            case .copyAddressToAll:
                let adminAddress = state.profile.defaultAdministeredByAddress
                state.profile.defaultPaymentAddress = adminAddress
                state.profile.defaultDeliveryAddress = adminAddress
                return .none

            case .copyPaymentToDelivery:
                state.profile.defaultDeliveryAddress = state.profile.defaultPaymentAddress
                return .none

            case .copyDeliveryToPayment:
                state.profile.defaultPaymentAddress = state.profile.defaultDeliveryAddress
                return .none

            case let .updateAPIKey(key):
                state.apiKey = key
                state.apiKeyValidated = false
                return .none

            case let .toggleShowAPIKey(show):
                state.showingAPIKey = show
                return .none

            case .validateAPIKey:
                guard !state.apiKey.isEmpty else { return .none }
                state.isLoading = true
                return .run { [key = state.apiKey] send in
                    let isValid = await settingsManager.validateAPIKey(key)
                    await send(.apiKeyValidationResult(isValid))
                }

            case let .apiKeyValidationResult(isValid):
                state.isLoading = false
                state.apiKeyValidated = isValid
                if isValid {
                    return .run { [key = state.apiKey] _ in
                        try? await settingsManager.saveAPIKey(key)
                    }
                } else {
                    state.validationErrors = ["Invalid API key. Please check your key and try again."]
                }
                return .none

            case let .toggleFaceID(enabled):
                state.faceIDEnabled = enabled
                return .none
            }
        }
    }
}

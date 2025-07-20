import AppCore
import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct ProfileFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var profile: UserProfile
        public var isEditing: Bool = false
        public var isSaving: Bool = false
        public var showingImagePicker: Bool = false
        public var showingLogoPicker: Bool = false
        public var imagePickerType: ImageType = .profile
        public var showingAddressCopy: Bool = false
        public var addressCopySource: AddressType = .administeredBy
        public var validationErrors: [ValidationError] = []

        public enum ImageType: Equatable {
            case profile
            case logo
        }

        public enum AddressType: String, CaseIterable {
            case administeredBy = "Administered By"
            case payment = "Payment"
            case delivery = "Delivery"
        }

        public struct ValidationError: Equatable, Identifiable {
            public let id = UUID()
            public let field: String
            public let message: String
        }

        public init(profile: UserProfile = UserProfile()) {
            self.profile = profile
        }
    }

    public enum Action {
        // Profile actions
        case loadProfile
        case profileLoaded(UserProfile?)
        case saveProfile
        case profileSaved
        case deleteProfile
        case profileDeleted

        // Editing actions
        case setEditing(Bool)
        case updateFullName(String)
        case updateTitle(String)
        case updatePosition(String)
        case updateEmail(String)
        case updateAlternateEmail(String)
        case updatePhoneNumber(String)
        case updateAlternatePhoneNumber(String)
        case updateOrganizationName(String)
        case updateOrganizationalDODAAC(String)
        case updateAgencyDepartmentService(String)

        // Address actions
        case updateAddress(State.AddressType, Address)
        case showAddressCopy(State.AddressType)
        case copyAddress(from: State.AddressType, to: State.AddressType)
        case dismissAddressCopy

        // Image actions
        case showImagePicker(State.ImageType)
        case dismissImagePicker
        case updateProfileImage(Data)
        case updateOrganizationLogo(Data)
        case removeProfileImage
        case removeOrganizationLogo

        // Validation
        case validateProfile
        case validationCompleted([State.ValidationError])
    }

    @Dependency(\.userProfileService) var userProfileService

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadProfile:
                return .run { send in
                    let profile = try await userProfileService.loadProfile()
                    await send(.profileLoaded(profile))
                }

            case let .profileLoaded(profile):
                if let profile {
                    state.profile = profile
                }
                return .none

            case .saveProfile:
                state.isSaving = true
                return .run { [profile = state.profile] send in
                    try await userProfileService.saveProfile(profile)
                    await send(.profileSaved)
                }

            case .profileSaved:
                state.isSaving = false
                state.isEditing = false
                return .none

            case .deleteProfile:
                return .run { send in
                    try await userProfileService.deleteProfile()
                    await send(.profileDeleted)
                }

            case .profileDeleted:
                state.profile = UserProfile()
                return .none

            case let .setEditing(isEditing):
                state.isEditing = isEditing
                if !isEditing {
                    return .send(.saveProfile)
                }
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
                state.profile.organizationalDODAAC = dodaac
                return .none

            case let .updateAgencyDepartmentService(agency):
                state.profile.agencyDepartmentService = agency
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

            case let .showAddressCopy(sourceType):
                state.showingAddressCopy = true
                state.addressCopySource = sourceType
                return .none

            case let .copyAddress(from: source, to: destination):
                let sourceAddress: Address = switch source {
                case .administeredBy:
                    state.profile.defaultAdministeredByAddress
                case .payment:
                    state.profile.defaultPaymentAddress
                case .delivery:
                    state.profile.defaultDeliveryAddress
                }

                switch destination {
                case .administeredBy:
                    state.profile.defaultAdministeredByAddress = sourceAddress
                case .payment:
                    state.profile.defaultPaymentAddress = sourceAddress
                case .delivery:
                    state.profile.defaultDeliveryAddress = sourceAddress
                }

                state.showingAddressCopy = false
                return .none

            case .dismissAddressCopy:
                state.showingAddressCopy = false
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
                state.showingLogoPicker = false
                return .none

            case .removeProfileImage:
                state.profile.profileImageData = nil
                return .none

            case .removeOrganizationLogo:
                state.profile.organizationLogoData = nil
                return .none

            case .validateProfile:
                var errors: [State.ValidationError] = []

                // Email validation
                if !state.profile.email.isEmpty, !isValidEmail(state.profile.email) {
                    errors.append(.init(field: "Email", message: "Invalid email format"))
                }

                if !state.profile.alternateEmail.isEmpty, !isValidEmail(state.profile.alternateEmail) {
                    errors.append(.init(field: "Alternate Email", message: "Invalid email format"))
                }

                // Phone validation
                if !state.profile.phoneNumber.isEmpty, !isValidPhone(state.profile.phoneNumber) {
                    errors.append(.init(field: "Phone", message: "Invalid phone format"))
                }

                if !state.profile.alternatePhoneNumber.isEmpty, !isValidPhone(state.profile.alternatePhoneNumber) {
                    errors.append(.init(field: "Alternate Phone", message: "Invalid phone format"))
                }

                // DODAAC validation (6 characters)
                if !state.profile.organizationalDODAAC.isEmpty, state.profile.organizationalDODAAC.count != 6 {
                    errors.append(.init(field: "DODAAC", message: "DODAAC must be 6 characters"))
                }

                return .send(.validationCompleted(errors))

            case let .validationCompleted(errors):
                state.validationErrors = errors
                return .none
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[\\+]?[(]?[0-9]{3}[)]?[-\\s\\.]?[(]?[0-9]{3}[)]?[-\\s\\.]?[0-9]{4,6}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePred.evaluate(with: phone)
    }
}

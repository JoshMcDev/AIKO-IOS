import ComposableArchitecture
import Foundation
import AppCore

@Reducer
public struct DocumentDeliveryFeature {
    @ObservableState
    public struct State: Equatable {
        public var generatedDocuments: [GeneratedDocument] = []
        public var showingDeliveryOptions: Bool = false
        public var showingEmailConfirmation: Bool = false
        public var userProfileEmail: String = "user@example.com" // Should come from user profile
        public var customEmailAddress: String = ""
        public var selectedEmailOption: EmailOption = .profile
        public var isDelivering: Bool = false
        public var deliveryError: String?

        public init() {}
    }

    public enum EmailOption: CaseIterable, Equatable {
        case profile
        case different
        case noProfile

        public var title: String {
            switch self {
            case .profile: "Use Profile Email"
            case .different: "Different Email Address"
            case .noProfile: "Enter Email Address"
            }
        }
    }

    public enum DeliveryOption: CaseIterable {
        case download
        case email
        case both

        public var title: String {
            switch self {
            case .download: "Download"
            case .email: "Email"
            case .both: "Both"
            }
        }

        public var icon: String {
            switch self {
            case .download: "arrow.down.circle"
            case .email: "envelope"
            case .both: "square.and.arrow.up"
            }
        }
    }

    public enum Action {
        case setGeneratedDocuments([GeneratedDocument])
        case showDeliveryOptions(Bool)
        case deliverDocuments(DeliveryOption)
        case downloadDocuments
        case showEmailConfirmation(Bool)
        case updateEmailOption(EmailOption)
        case updateCustomEmail(String)
        case sendDocumentsViaEmail
        case deliveryCompleted
        case deliveryFailed(String)
        case clearError
        case updateUserProfileEmail(String)
    }

    @Dependency(\.documentDeliveryService) var documentDeliveryService

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setGeneratedDocuments(documents):
                state.generatedDocuments = documents
                return .none

            case let .showDeliveryOptions(show):
                state.showingDeliveryOptions = show
                return .none

            case let .deliverDocuments(option):
                switch option {
                case .download:
                    return .send(.downloadDocuments)
                case .email:
                    return .send(.showEmailConfirmation(true))
                case .both:
                    return .merge(
                        .send(.downloadDocuments),
                        .send(.showEmailConfirmation(true))
                    )
                }

            case .downloadDocuments:
                state.isDelivering = true
                state.deliveryError = nil

                return .run { [documents = state.generatedDocuments] send in
                    do {
                        try await documentDeliveryService.downloadDocuments(documents)
                        await send(.deliveryCompleted)
                    } catch {
                        await send(.deliveryFailed("Download failed: \(error.localizedDescription)"))
                    }
                }

            case let .showEmailConfirmation(show):
                if show {
                    // Set email option based on profile
                    if state.userProfileEmail.isEmpty {
                        state.selectedEmailOption = .noProfile
                    } else {
                        state.selectedEmailOption = .profile
                    }
                }
                state.showingEmailConfirmation = show
                return .none

            case let .updateEmailOption(option):
                state.selectedEmailOption = option
                return .none

            case let .updateCustomEmail(email):
                state.customEmailAddress = email
                return .none

            case .sendDocumentsViaEmail:
                let emailAddress: String = switch state.selectedEmailOption {
                case .profile:
                    state.userProfileEmail
                case .different, .noProfile:
                    state.customEmailAddress
                }

                guard !emailAddress.isEmpty else {
                    return .send(.deliveryFailed("Please provide a valid email address"))
                }

                state.isDelivering = true
                state.deliveryError = nil

                return .run { [documents = state.generatedDocuments] send in
                    do {
                        try await documentDeliveryService.emailDocuments(documents, emailAddress)
                        await send(.deliveryCompleted)
                    } catch {
                        await send(.deliveryFailed("Email failed: \(error.localizedDescription)"))
                    }
                }

            case .deliveryCompleted:
                state.isDelivering = false
                state.showingEmailConfirmation = false
                state.showingDeliveryOptions = false
                return .none

            case let .deliveryFailed(error):
                state.isDelivering = false
                state.deliveryError = error
                return .none

            case .clearError:
                state.deliveryError = nil
                return .none

            case let .updateUserProfileEmail(email):
                state.userProfileEmail = email
                return .none
            }
        }
    }
}

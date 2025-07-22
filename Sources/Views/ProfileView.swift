import AppCore
import ComposableArchitecture
import SwiftUI
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

public struct ProfileView: View {
    let store: StoreOf<ProfileFeature>

    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Info message about profile usage
                    HStack(alignment: .top, spacing: Theme.Spacing.small) {
                        Image(systemName: "sparkles")
                            .font(.body)
                            .foregroundColor(.blue)

                        Text("Your profile information automatically fills into all generated documents, saving you time by eliminating repetitive data entry.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(Color.blue.opacity(0.1))
                    )

                    // Profile Header
                    ProfileHeaderView(
                        profile: viewStore.profile,
                        isEditing: viewStore.isEditing,
                        onEditToggle: { viewStore.send(.setEditing(!viewStore.isEditing)) },
                        onImageTap: { viewStore.send(.showImagePicker(.profile)) }
                    )

                    // Personal Information Section
                    ProfileSectionView(title: "Personal Information", icon: "person.fill") {
                        ProfileTextField(
                            title: "Full Name",
                            text: .init(
                                get: { viewStore.profile.fullName },
                                set: { viewStore.send(.updateFullName($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: true
                        )

                        ProfileTextField(
                            title: "Title",
                            text: .init(
                                get: { viewStore.profile.title },
                                set: { viewStore.send(.updateTitle($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: false,
                            placeholder: "Mr. / Mrs."
                        )

                        ProfileTextField(
                            title: "Position",
                            text: .init(
                                get: { viewStore.profile.position },
                                set: { viewStore.send(.updatePosition($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: false,
                            placeholder: "Contracting Officer"
                        )
                    }

                    // Contact Information Section
                    ProfileSectionView(title: "Contact Information", icon: "phone.fill") {
                        ProfileTextField(
                            title: "Email",
                            text: .init(
                                get: { viewStore.profile.email },
                                set: { viewStore.send(.updateEmail($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: true,
                            error: viewStore.validationErrors.first(where: { $0.field == "Email" })?.message
                        )

                        ProfileTextField(
                            title: "Alternate Email",
                            text: .init(
                                get: { viewStore.profile.alternateEmail },
                                set: { viewStore.send(.updateAlternateEmail($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            error: viewStore.validationErrors.first(where: { $0.field == "Alternate Email" })?.message
                        )

                        ProfileTextField(
                            title: "Phone Number",
                            text: .init(
                                get: { viewStore.profile.phoneNumber },
                                set: { viewStore.send(.updatePhoneNumber($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: false,
                            error: viewStore.validationErrors.first(where: { $0.field == "Phone" })?.message
                        )

                        ProfileTextField(
                            title: "Alternate Phone",
                            text: .init(
                                get: { viewStore.profile.alternatePhoneNumber },
                                set: { viewStore.send(.updateAlternatePhoneNumber($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            error: viewStore.validationErrors.first(where: { $0.field == "Alternate Phone" })?.message
                        )
                    }

                    // Organization Section
                    ProfileSectionView(title: "Organization", icon: "building.2.fill") {
                        ProfileTextField(
                            title: "Organization Name",
                            text: .init(
                                get: { viewStore.profile.organizationName },
                                set: { viewStore.send(.updateOrganizationName($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: false
                        )

                        ProfileTextField(
                            title: "DODAAC",
                            text: .init(
                                get: { viewStore.profile.organizationalDODAAC },
                                set: { viewStore.send(.updateOrganizationalDODAAC($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: false,
                            placeholder: "6-character code",
                            error: viewStore.validationErrors.first(where: { $0.field == "DODAAC" })?.message
                        )

                        ProfileTextField(
                            title: "Agency/Department/Service",
                            text: .init(
                                get: { viewStore.profile.agencyDepartmentService },
                                set: { viewStore.send(.updateAgencyDepartmentService($0)) }
                            ),
                            isEditing: viewStore.isEditing,
                            isRequired: false,
                            placeholder: "e.g. SOCOM, NASA, VA, USAF",
                            helpText: "Used to determine applicable regulations (FAR, DFARS, agency supplements)"
                        )

                        // Organization Logo
                        OrganizationLogoView(
                            logoData: viewStore.profile.organizationLogoData,
                            isEditing: viewStore.isEditing,
                            onTap: { viewStore.send(.showImagePicker(.logo)) },
                            onRemove: { viewStore.send(.removeOrganizationLogo) }
                        )
                    }

                    // Addresses Section
                    VStack(spacing: Theme.Spacing.large) {
                        // Administered By Address
                        AddressSectionView(
                            title: "Default Administered By Address",
                            address: viewStore.profile.defaultAdministeredByAddress,
                            isEditing: viewStore.isEditing,
                            isRequired: false,
                            onUpdate: { address in
                                viewStore.send(.updateAddress(.administeredBy, address))
                            },
                            onCopyFrom: {
                                viewStore.send(.showAddressCopy(.administeredBy))
                            }
                        )

                        // Payment Address
                        AddressSectionView(
                            title: "Default Payment Address",
                            address: viewStore.profile.defaultPaymentAddress,
                            isEditing: viewStore.isEditing,
                            onUpdate: { address in
                                viewStore.send(.updateAddress(.payment, address))
                            },
                            onCopyFrom: {
                                viewStore.send(.showAddressCopy(.payment))
                            }
                        )

                        // Delivery Address
                        AddressSectionView(
                            title: "Default Delivery Address",
                            address: viewStore.profile.defaultDeliveryAddress,
                            isEditing: viewStore.isEditing,
                            onUpdate: { address in
                                viewStore.send(.updateAddress(.delivery, address))
                            },
                            onCopyFrom: {
                                viewStore.send(.showAddressCopy(.delivery))
                            }
                        )
                    }

                    // Completion Status
                    ProfileCompletionView(profile: viewStore.profile)

                    Spacer(minLength: 50)
                }
                .padding(Theme.Spacing.large)
            }
            .background(Theme.Colors.aikoBackground)
            .navigationTitle("My Profile")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
                .toolbar {
                    if viewStore.isEditing {
                        #if os(iOS)
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    viewStore.send(.validateProfile)
                                    viewStore.send(.setEditing(false))
                                }
                                .fontWeight(.semibold)
                            }
                        #else
                            ToolbarItem(placement: .automatic) {
                                Button("Done") {
                                    viewStore.send(.validateProfile)
                                    viewStore.send(.setEditing(false))
                                }
                                .fontWeight(.semibold)
                            }
                        #endif
                    }
                }
                .sheet(isPresented: .init(
                    get: { viewStore.showingImagePicker },
                    set: { _ in viewStore.send(.dismissImagePicker) }
                )) {
                    #if os(iOS)
                        ProfileImagePicker(
                            onImageSelected: { data in
                                switch viewStore.imagePickerType {
                                case .profile:
                                    viewStore.send(.updateProfileImage(data))
                                case .logo:
                                    viewStore.send(.updateOrganizationLogo(data))
                                }
                            }
                        )
                    #endif
                }
                .confirmationDialog(
                    "Copy Address From",
                    isPresented: .init(
                        get: { viewStore.showingAddressCopy },
                        set: { _ in viewStore.send(.dismissAddressCopy) }
                    )
                ) {
                    ForEach(ProfileFeature.State.AddressType.allCases, id: \.self) { addressType in
                        if addressType != viewStore.addressCopySource {
                            Button(addressType.rawValue) {
                                viewStore.send(.copyAddress(from: addressType, to: viewStore.addressCopySource))
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .onAppear {
                    viewStore.send(.loadProfile)
                }
        }
    }
}

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    let profile: UserProfile
    let isEditing: Bool
    let onEditToggle: () -> Void
    let onImageTap: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            // Profile Image
            Button(action: isEditing ? onImageTap : {}) {
                ZStack {
                    if let imageData = profile.profileImageData {
                        #if os(iOS)
                            if let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            }
                        #else
                            if let nsImage = NSImage(data: imageData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            }
                        #endif
                    } else {
                        Circle()
                            .fill(Theme.Colors.aikoSecondary)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }

                    if isEditing {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 120, height: 120)
                            .overlay(
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Change")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                }
            }
            .disabled(!isEditing)

            // Name and Title
            VStack(spacing: 4) {
                Text(profile.fullName.isEmpty ? "Your Name" : profile.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(profile.title.isEmpty ? "Your Title" : profile.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Edit Button
            Button(action: onEditToggle) {
                Label(isEditing ? "Done Editing" : "Edit Profile", systemImage: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isEditing ? .green : .blue)
                    .padding(.horizontal, Theme.Spacing.large)
                    .padding(.vertical, Theme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(isEditing ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    )
            }
        }
        .padding(.vertical, Theme.Spacing.xl)
    }
}

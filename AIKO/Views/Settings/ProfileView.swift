//
//  ProfileView.swift
//  AIKO
//
//  Created by AIKO Development Team
//  Copyright © 2025 AIKO. All rights reserved.
//

import SwiftUI
import PhotosUI
import AppCore

/// ProfileView - SwiftUI view for managing user profile
/// PHASE 3: Enhanced Features implementation
/// Replaces TCA pattern with native SwiftUI @Observable
struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // Profile Image Section
                profileImageSection

                // Personal Information Section
                personalInformationSection

                // Contact Information Section
                contactInformationSection

                // Organization Information Section
                organizationInformationSection

                // Address Sections
                addressSections

                // Social & Professional Section
                socialProfessionalSection

                // Actions Section
                if viewModel.isEditing {
                    actionsSection
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .alert("Profile", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await viewModel.loadProfile()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        await viewModel.updateProfileImage(data)
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var profileImageSection: some View {
        Section {
            HStack {
                Spacer()
                VStack {
                    if let imageData = viewModel.profile.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }

                    if viewModel.isEditing {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text("Change Photo")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.top, 8)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    private var personalInformationSection: some View {
        Section(header: Text("Personal Information")) {
            profileField("Full Name", text: $viewModel.profile.fullName, isRequired: true)
            profileField("Title", text: $viewModel.profile.title)
            profileField("Position", text: $viewModel.profile.position)

            // Bio with multi-line support
            VStack(alignment: .leading, spacing: 4) {
                Text("Bio")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $viewModel.profile.bio)
                    .frame(minHeight: 80)
                    .disabled(!viewModel.isEditing)
            }
        }
    }

    private var contactInformationSection: some View {
        Section(header: Text("Contact Information")) {
            profileField("Email", text: $viewModel.profile.email, isRequired: true, keyboardType: .emailAddress)
                .textContentType(.emailAddress)
            profileField("Alternate Email", text: $viewModel.profile.alternateEmail, keyboardType: .emailAddress)
                .textContentType(.emailAddress)
            profileField("Phone", text: $viewModel.profile.phoneNumber, keyboardType: .phonePad)
                .textContentType(.telephoneNumber)
            profileField("Alternate Phone", text: $viewModel.profile.alternatePhoneNumber, keyboardType: .phonePad)
                .textContentType(.telephoneNumber)
        }
    }

    private var organizationInformationSection: some View {
        Section(header: Text("Organization")) {
            profileField("Organization Name", text: $viewModel.profile.organizationName)
            profileField("DODAAC", text: $viewModel.profile.organizationalDODAAC)
            profileField("Agency/Department/Service", text: $viewModel.profile.agencyDepartmentService)
        }
    }

    private var addressSections: some View {
        Group {
            // Mailing Address
            addressSection(
                title: "Mailing Address",
                address: $viewModel.profile.mailingAddress
            )

            // Billing Address
            addressSection(
                title: "Billing Address",
                address: $viewModel.profile.billingAddress,
                showCopyButton: true,
                copyAction: {
                    viewModel.copyMailingToBillingAddress()
                }
            )

            // Administered By Address
            addressSection(
                title: "Administered By Address",
                address: $viewModel.profile.defaultAdministeredByAddress
            )

            // Payment Address
            addressSection(
                title: "Payment Address",
                address: $viewModel.profile.defaultPaymentAddress
            )

            // Delivery Address
            addressSection(
                title: "Delivery Address",
                address: $viewModel.profile.defaultDeliveryAddress
            )
        }
    }

    private var socialProfessionalSection: some View {
        Section(header: Text("Social & Professional")) {
            profileField("Website", text: $viewModel.profile.website, keyboardType: .URL)
                .textContentType(.URL)
            profileField("LinkedIn", text: $viewModel.profile.linkedIn)
            profileField("Twitter", text: $viewModel.profile.twitter)

            // Language & Time Zone
            HStack {
                Text("Preferred Language")
                Spacer()
                Text(viewModel.profile.preferredLanguage)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Time Zone")
                Spacer()
                Text(viewModel.profile.timeZone)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        Section {
            // Auto-save toggle
            Toggle("Enable Auto-Save", isOn: $viewModel.enableAutoSave)

            // Save button
            Button(action: {
                Task {
                    await saveProfile()
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save Changes")
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isSaving || !viewModel.validationErrors.isEmpty)

            // Cancel button
            Button(action: {
                viewModel.cancelEditing()
            }) {
                HStack {
                    Spacer()
                    Text("Cancel")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }

    private var editButton: some View {
        Button(viewModel.isEditing ? "Done" : "Edit") {
            if viewModel.isEditing {
                Task {
                    await saveProfile()
                }
            } else {
                viewModel.toggleEditMode()
            }
        }
    }

    // MARK: - Helper Views

    private func profileField(
        _ label: String,
        text: Binding<String>,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            TextField(label, text: text)
                .keyboardType(keyboardType)
                .disabled(!viewModel.isEditing)

            if let error = viewModel.validationErrors[label.lowercased().replacingOccurrences(of: " ", with: "")] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private func addressSection(
        title: String,
        address: Binding<Address>,
        showCopyButton: Bool = false,
        copyAction: (() -> Void)? = nil
    ) -> some View {
        Section(header: HStack {
            Text(title)
            if showCopyButton, viewModel.isEditing {
                Spacer()
                Button(action: {
                    copyAction?()
                }) {
                    Text("Copy from Mailing")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }) {
            profileField("Street 1", text: address.street1)
            profileField("Street 2", text: address.street2)
            profileField("City", text: address.city)
            profileField("State", text: address.state)
            profileField("ZIP Code", text: address.zipCode)
            profileField("Country", text: address.country)
        }
    }

    // MARK: - Actions

    private func saveProfile() async {
        await viewModel.saveProfile()

        if viewModel.error != nil {
            alertMessage = "Failed to save profile. Please try again."
            showingAlert = true
        } else if viewModel.validationErrors.isEmpty {
            viewModel.toggleEditMode()
            alertMessage = "Profile saved successfully!"
            showingAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}

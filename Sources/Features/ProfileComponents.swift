import AppCore
import SwiftUI
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

// MARK: - Profile Text Field

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let isEditing: Bool
    var isRequired: Bool = false
    var placeholder: String = ""
    #if os(iOS)
        var keyboardType: UIKeyboardType = .default
    #else
        var keyboardType: String = "default"
    #endif
    var error: String?
    var helpText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if isEditing {
                TextField("", text: $text, prompt: Text("...").foregroundColor(.gray))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1)
                            )
                    )
                #if os(iOS)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(keyboardType == .emailAddress)
                #endif
            } else {
                Text(text.isEmpty ? "-" : text)
                    .font(.body)
                    .foregroundColor(text.isEmpty ? .secondary : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.white.opacity(0.05))
                    )
            }

            if let error {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
            } else if let helpText {
                Text(helpText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Profile Text Editor

struct ProfileTextEditor: View {
    let title: String
    @Binding var text: String
    let isEditing: Bool
    var isRequired: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if isEditing {
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .padding(Theme.Spacing.small)
                    .frame(minHeight: 80, maxHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.white.opacity(0.1))
                    )
            } else {
                Text(text.isEmpty ? "-" : text)
                    .font(.body)
                    .foregroundColor(text.isEmpty ? .secondary : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
    }
}

// MARK: - Address Section View

struct AddressSectionView: View {
    let title: String
    var address: Address
    let isEditing: Bool
    var isRequired: Bool = false
    let onUpdate: (Address) -> Void
    let onCopyFrom: () -> Void

    @State private var localAddress: Address

    init(title: String, address: Address, isEditing: Bool, isRequired: Bool = false, onUpdate: @escaping (Address) -> Void, onCopyFrom: @escaping () -> Void) {
        self.title = title
        self.address = address
        self.isEditing = isEditing
        self.isRequired = isRequired
        self.onUpdate = onUpdate
        self.onCopyFrom = onCopyFrom
        _localAddress = State(initialValue: address)
    }

    var body: some View {
        ProfileSectionView(title: title, icon: "location.fill") {
            if isEditing {
                Button(action: onCopyFrom) {
                    Label("Copy from another address", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ProfileTextEditor(
                title: "Address Description",
                text: .init(
                    get: { localAddress.freeText },
                    set: {
                        localAddress.freeText = $0
                        onUpdate(localAddress)
                    }
                ),
                isEditing: isEditing
            )

            AddressFieldView(
                title: "Street Address 1",
                text: .init(
                    get: { localAddress.street1 },
                    set: {
                        localAddress.street1 = $0
                        onUpdate(localAddress)
                    }
                ),
                isEditing: isEditing,
                isRequired: false
            )

            AddressFieldView(
                title: "Street Address 2",
                text: .init(
                    get: { localAddress.street2 },
                    set: {
                        localAddress.street2 = $0
                        onUpdate(localAddress)
                    }
                ),
                isEditing: isEditing
            )

            HStack(spacing: Theme.Spacing.medium) {
                AddressFieldView(
                    title: "City",
                    text: .init(
                        get: { localAddress.city },
                        set: {
                            localAddress.city = $0
                            onUpdate(localAddress)
                        }
                    ),
                    isEditing: isEditing,
                    isRequired: false
                )

                AddressFieldView(
                    title: "State",
                    text: .init(
                        get: { localAddress.state },
                        set: {
                            localAddress.state = $0
                            onUpdate(localAddress)
                        }
                    ),
                    isEditing: isEditing,
                    isRequired: false
                )
                .frame(maxWidth: 100)
            }

            HStack(spacing: Theme.Spacing.medium) {
                AddressFieldView(
                    title: "ZIP Code",
                    text: .init(
                        get: { localAddress.zipCode },
                        set: {
                            localAddress.zipCode = $0
                            onUpdate(localAddress)
                        }
                    ),
                    isEditing: isEditing,
                    isRequired: false
                )
                .frame(maxWidth: 120)

                AddressFieldView(
                    title: "Country",
                    text: .init(
                        get: { localAddress.country },
                        set: {
                            localAddress.country = $0
                            onUpdate(localAddress)
                        }
                    ),
                    isEditing: isEditing
                )
            }

            AddressFieldView(
                title: "Phone Number",
                text: .init(
                    get: { localAddress.phone },
                    set: {
                        localAddress.phone = $0
                        onUpdate(localAddress)
                    }
                ),
                isEditing: isEditing,
                isRequired: false
            )

            #if os(iOS)
                AddressFieldView(
                    title: "Email Address",
                    text: .init(
                        get: { localAddress.email },
                        set: {
                            localAddress.email = $0
                            onUpdate(localAddress)
                        }
                    ),
                    isEditing: isEditing,
                    isRequired: false,
                    keyboardType: .emailAddress
                )
            #else
                AddressFieldView(
                    title: "Email Address",
                    text: .init(
                        get: { localAddress.email },
                        set: {
                            localAddress.email = $0
                            onUpdate(localAddress)
                        }
                    ),
                    isEditing: isEditing,
                    isRequired: false,
                    keyboardType: "emailAddress"
                )
            #endif

            if !isEditing, address.isComplete {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Formatted Address")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(address.formatted)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
        }
        .onChange(of: address) { _, newAddress in
            localAddress = newAddress
        }
    }
}

// MARK: - Address Field View

struct AddressFieldView: View {
    let title: String
    @Binding var text: String
    let isEditing: Bool
    var isRequired: Bool = false
    #if os(iOS)
        var keyboardType: UIKeyboardType = .default
    #else
        var keyboardType: String = "default"
    #endif

    var body: some View {
        ProfileTextField(
            title: title,
            text: $text,
            isEditing: isEditing,
            isRequired: isRequired,
            keyboardType: keyboardType
        )
    }
}

// MARK: - Organization Logo View

struct OrganizationLogoView: View {
    let logoData: Data?
    let isEditing: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Organization Logo")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button(action: isEditing ? onTap : {}) {
                    if let logoData {
                        #if os(iOS)
                            if let uiImage = UIImage(data: logoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                                    .cornerRadius(Theme.CornerRadius.small)
                            }
                        #else
                            if let nsImage = NSImage(data: logoData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                                    .cornerRadius(Theme.CornerRadius.small)
                            }
                        #endif
                    } else {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 60)
                            .overlay(
                                VStack {
                                    Image(systemName: "building.2")
                                        .font(.title2)
                                        .foregroundColor(.white.opacity(0.3))
                                    if isEditing {
                                        Text("Add Logo")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                }
                            )
                    }
                }
                .disabled(!isEditing)

                if isEditing, logoData != nil {
                    Button(action: onRemove) {
                        Label("Remove", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Profile Section View

struct ProfileSectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: Theme.Spacing.medium) {
                content()
            }
            .padding(Theme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Theme.Colors.aikoSecondary)
            )
        }
    }
}

// MARK: - Profile Completion View

struct ProfileCompletionView: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            HStack {
                Text("Profile Completion")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(profile.completionPercentage * 100))%")
                    .font(.headline)
                    .foregroundColor(profile.isComplete ? .green : .orange)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(profile.isComplete ? Color.green : Color.orange)
                        .frame(width: geometry.size.width * profile.completionPercentage, height: 12)
                        .animation(.easeInOut(duration: 0.3), value: profile.completionPercentage)
                }
            }
            .frame(height: 12)

            if !profile.isComplete {
                Text("Complete your profile to unlock all features")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Theme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(Theme.Colors.aikoSecondary)
        )
    }
}

// MARK: - Profile Image Picker

#if os(iOS)
    struct ProfileImagePicker: View {
        let onImageSelected: (Data) -> Void
        @State private var showingImagePicker = false
        @State private var showingSourceDialog = false
        @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
        @Environment(\.dismiss) var dismiss

        var body: some View {
            VStack {
                Spacer()

                VStack(spacing: Theme.Spacing.large) {
                    Text("Choose Image Source")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(spacing: Theme.Spacing.medium) {
                        Button(action: {
                            imageSourceType = .camera
                            showingImagePicker = true
                        }, label: {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.aikoPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(Theme.CornerRadius.small)
                        })

                        Button(action: {
                            imageSourceType = .photoLibrary
                            showingImagePicker = true
                        }, label: {
                            Label("Choose from Library", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.aikoSecondary)
                                .foregroundColor(.white)
                                .cornerRadius(Theme.CornerRadius.small)
                        })

                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                    }
                }
                .padding(Theme.Spacing.extraLarge)

                Spacer()
            }
            .background(Theme.Colors.aikoBackground)
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerRepresentable(sourceType: imageSourceType) { image in
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        onImageSelected(imageData)
                        dismiss()
                    }
                }
            }
        }
    }

    struct ImagePickerRepresentable: UIViewControllerRepresentable {
        let sourceType: UIImagePickerController.SourceType
        let onImagePicked: (UIImage) -> Void
        @Environment(\.dismiss) var dismiss

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = sourceType
            picker.allowsEditing = true
            return picker
        }

        func updateUIViewController(_: UIImagePickerController, context _: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePickerRepresentable

            init(_ parent: ImagePickerRepresentable) {
                self.parent = parent
            }

            func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let editedImage = info[.editedImage] as? UIImage {
                    parent.onImagePicked(editedImage)
                } else if let originalImage = info[.originalImage] as? UIImage {
                    parent.onImagePicked(originalImage)
                }
                parent.dismiss()
            }

            func imagePickerControllerDidCancel(_: UIImagePickerController) {
                parent.dismiss()
            }
        }
    }
#endif

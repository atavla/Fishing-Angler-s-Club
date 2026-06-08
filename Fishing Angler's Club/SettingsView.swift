import PhotosUI
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var loginPresented = false
    @State private var photoLoading = false
    @State private var isEditingName = false
    @State private var draftName = ""

    var body: some View {
        ZStack {
            ScreenBackground(assetName: "background_settings")

            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                    HStack(spacing: 14) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                AvatarView(image: appState.avatarImage, size: 82)
                                Image(systemName: photoLoading ? "hourglass" : "camera.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(AppTheme.orange, in: Circle())
                                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            }
                        }
                        .disabled(photoLoading)
                        .accessibilityLabel("Choose profile photo")

                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                draftName = appState.data.displayName
                                isEditingName = true
                            } label: {
                                HStack(spacing: 6) {
                                    Text(appState.data.displayName)
                                        .font(.headline)
                                    Image(systemName: "pencil")
                                        .font(.caption.bold())
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit display name")

                            Text("Data is stored locally on this device.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                }

                    GlassCard {
                        VStack(spacing: 0) {
                            Button {
                                loginPresented = true
                            } label: {
                                SettingsRow(icon: "person.badge.key.fill", title: "Log in", value: nil)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $loginPresented) {
            LoginView()
        }
        .alert("Edit name", isPresented: $isEditingName) {
            TextField("Display name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    appState.updateDisplayName(trimmed)
                }
            }
        } message: {
            Text("This name is stored only on this device.")
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            photoLoading = true
            Task {
                let data = try? await item.loadTransferable(type: Data.self)
                await MainActor.run {
                    if let data {
                        appState.updateAvatar(with: data)
                    } else {
                        appState.storageErrorMessage = "The selected photo could not be loaded."
                    }
                    selectedPhoto = nil
                    photoLoading = false
                }
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
            if let value {
                Text(value)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))
        }
        .foregroundStyle(.white)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

private struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case username
        case password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground(assetName: "background_login")
                ScrollView {
                    VStack(spacing: 18) {
                        AssetArtwork(name: "home_vertical_logo", scaling: .contain)
                            .frame(height: 145)

                        GlassCard {
                            VStack(spacing: 14) {
                                TextField("Username", text: $username)
                                    .textContentType(.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .username)
                                    .padding()
                                    .background(GlassPanelBackground(cornerRadius: 12))

                                SecureField("Password", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .padding()
                                    .background(GlassPanelBackground(cornerRadius: 12))

                                if let errorMessage {
                                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.red.opacity(0.95))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .accessibilityLabel("Login error: \(errorMessage)")
                                }

                                Button {
                                    attemptLogin()
                                } label: {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Log in")
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isLoading || username.isEmpty || password.isEmpty)
                            }
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .foregroundStyle(.white)
            .navigationTitle("Account login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }

    private func attemptLogin() {
        focusedField = nil
        errorMessage = nil
        isLoading = true
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            isLoading = false
            errorMessage = "The username or password is incorrect. Check your details and try again."
        }
    }
}

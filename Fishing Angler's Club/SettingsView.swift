import PhotosUI
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var displayedAvatar: UIImage?
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
                                AvatarView(image: displayedAvatar, size: 82)
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
                            Text(AppState.reviewerEmail)
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
                                appState.logOut()
                            } label: {
                                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Log out", value: nil)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            displayedAvatar = appState.avatarImage
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
                        displayedAvatar = appState.avatarImage
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

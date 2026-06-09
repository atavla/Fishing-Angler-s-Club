import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ZStack {
            ScreenBackground(assetName: "background_login")

            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 34)

                    AssetArtwork(name: "home_vertical_logo", scaling: .contain)
                        .frame(height: 180)

                    GlassCard {
                        VStack(spacing: 16) {
                            Text("Welcome")
                                .font(.largeTitle.bold())

                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                                .focused($focusedField, equals: .email)
                                .onSubmit { focusedField = .password }
                                .padding()
                                .background(GlassPanelBackground(cornerRadius: 12))

                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .focused($focusedField, equals: .password)
                                .onSubmit { attemptLogin() }
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
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(.white)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }

    private func attemptLogin() {
        guard !isLoading, !email.isEmpty, !password.isEmpty else { return }
        focusedField = nil
        errorMessage = nil
        isLoading = true

        Task {
            try? await Task.sleep(for: .milliseconds(700))
            if !appState.logIn(email: email, password: password) {
                errorMessage = "The email or password is incorrect."
            }
            isLoading = false
        }
    }
}

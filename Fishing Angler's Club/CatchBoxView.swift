import CoreImage.CIFilterBuiltins
import SwiftUI

struct CatchBoxView: View {
    @EnvironmentObject private var appState: AppState
    @State private var archiveExpanded = false

    var body: some View {
        ZStack {
            ScreenBackground(assetName: "background_catch")

            if appState.activeBonuses.isEmpty && appState.archivedBonuses.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "Your catch box is empty",
                    message: "Complete the daily quiz with a perfect score to unlock your first reward."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if appState.activeBonuses.isEmpty {
                            GlassCard {
                                Text("No active rewards. Your used and expired catches remain in the archive.")
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            ForEach(appState.activeBonuses) { bonus in
                                if bonus.isRevealed {
                                    NavigationLink(value: bonus.id) {
                                        BonusCard(bonus: bonus)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        appState.presentedScratchBonus = bonus
                                    } label: {
                                        BonusCard(bonus: bonus)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if !appState.archivedBonuses.isEmpty {
                            DisclosureGroup("Used & expired catches", isExpanded: $archiveExpanded) {
                                VStack(spacing: 12) {
                                    ForEach(appState.archivedBonuses) { bonus in
                                        NavigationLink(value: bonus.id) {
                                            BonusCard(bonus: bonus)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.top, 12)
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("My Catch")
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { id in
            if let bonus = appState.bonus(withID: id) {
                BonusDetailView(bonusID: bonus.id)
            } else {
                EmptyStateView(icon: "exclamationmark.triangle", title: "Reward unavailable", message: "This reward could not be found.")
            }
        }
    }
}

private struct BonusCard: View {
    let bonus: RewardBonus

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                AssetArtwork(name: bonus.isRevealed ? bonus.kind.assetName : "scratch_card_cover", scaling: .contain, cornerRadius: 12)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 7) {
                    Text(bonus.isRevealed ? bonus.kind.title : "Unopened ice card")
                        .font(.headline)
                    if bonus.isRevealed {
                        Label(expiryText, systemImage: bonus.isExpired ? "clock.badge.exclamationmark" : "clock")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(bonus.isExpired ? AppTheme.danger : .white.opacity(0.72))
                    } else {
                        Text("Tap to open and scratch")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(.white)
        }
        .opacity(bonus.isArchived ? 0.62 : 1)
    }

    private var expiryText: String {
        if bonus.isExpired { return "Expired" }
        return "Expires \(bonus.expiresAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct BonusDetailView: View {
    @EnvironmentObject private var appState: AppState
    let bonusID: UUID
    @State private var confirmUse = false

    var body: some View {
        ZStack {
            ScreenBackground(assetName: "background_bonus_detail")
            if let bonus = appState.bonus(withID: bonusID) {
                ScrollView {
                    GlassCard {
                        VStack(spacing: 20) {
                            AssetArtwork(name: bonus.kind.assetName, scaling: .contain)
                                .frame(height: 160)

                            Text(bonus.kind.title)
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                            Text(bonus.kind.details)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.78))

                            if !bonus.isExpired && bonus.usedAt == nil {
                                QRCodeView(seed: bonus.redemptionSeed)
                                    .frame(width: 230, height: 230)
                                    .padding(14)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 22))

                                Button("Mark as used") {
                                    confirmUse = true
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            } else {
                                Label(
                                    bonus.isExpired ? "This reward has expired" : "Used \(bonus.usedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")",
                                    systemImage: bonus.isExpired ? "clock.badge.exclamationmark" : "checkmark.seal.fill"
                                )
                                .font(.headline)
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .foregroundStyle(.white)
        .navigationTitle("Reward")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog("Mark this reward as used?", isPresented: $confirmUse, titleVisibility: .visible) {
            Button("Mark as used") {
                if let bonus = appState.bonus(withID: bonusID) {
                    appState.markBonusUsed(bonus)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The reward will move to your archive.")
        }
    }
}

private struct QRCodeView: View {
    let seed: String

    var body: some View {
        if let image = makeQRCode() {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Reward QR code")
        } else {
            ContentUnavailableView("QR unavailable", systemImage: "qrcode")
                .foregroundStyle(.black)
        }
    }

    private func makeQRCode() -> UIImage? {
        let payload = "FISHING-CLUB|\(seed)"
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

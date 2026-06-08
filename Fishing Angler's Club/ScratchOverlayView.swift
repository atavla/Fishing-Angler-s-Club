import SwiftUI

struct ScratchOverlayView: View {
    @EnvironmentObject private var appState: AppState
    let bonus: RewardBonus
    @State private var appeared = false
    @State private var touchedCells: Set<Int> = []
    @State private var isRevealed = false
    @State private var pulse = false

    private let gridColumns = 10
    private let gridRows = 14

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.72 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isRevealed else { return }
                    close()
                }

            VStack(spacing: 18) {
                scratchCard
                    .frame(maxWidth: 350)
                    .aspectRatio(0.72, contentMode: .fit)
                    .scaleEffect(appeared ? (pulse ? 1.035 : 1) : 0.78)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.52, dampingFraction: 0.72), value: appeared)
                    .animation(.easeInOut(duration: 0.2).repeatCount(2, autoreverses: true), value: pulse)

                Text(isRevealed ? "Your reward is ready." : "Rub the card to clear the ice.")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)

                if isRevealed {
                    Button("Collect reward") {
                        close()
                        appState.selectedTab = .catchBox
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(20)
        }
        .onAppear {
            withAnimation { appeared = true }
            if bonus.isRevealed {
                isRevealed = true
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private var scratchCard: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.94), AppTheme.sky],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    AssetArtwork(name: bonus.kind.assetName, scaling: .contain)
                        .frame(height: proxy.size.height * 0.35)
                    Text(bonus.kind.title)
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.deepIce)
                        .multilineTextAlignment(.center)
                    Text(bonus.kind.details)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.navy.opacity(0.8))
                        .multilineTextAlignment(.center)
                    Label("Valid for 48 hours", systemImage: "clock.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.navy)
                }
                .padding(24)
                .blur(radius: isRevealed ? 0 : 10)
                .animation(.easeOut(duration: 0.35), value: isRevealed)

                if !isRevealed {
                    scratchLayer(size: proxy.size)
                        .opacity(scratchLayerOpacity)
                        .transition(.opacity)
                        .gesture(scratchGesture(size: proxy.size))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(.white.opacity(0.8), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.35), radius: 22, y: 10)
        }
    }

    private func scratchLayer(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.72, green: 0.88, blue: 0.95), Color(red: 0.18, green: 0.48, blue: 0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            AssetArtwork(name: "scratch_card_cover", scaling: .fill, cornerRadius: 28)
                .frame(width: size.width, height: size.height)
        }
        .overlay {
            VStack(spacing: 12) {
                Text("ICE SCRATCH & PULL")
                    .font(.title2.bold())
                Text("Scratch to reveal your catch")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(24)
            .allowsHitTesting(false)
        }
    }

    private func scratchGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location
                guard point.x >= 0, point.y >= 0, point.x <= size.width, point.y <= size.height else { return }

                let column = min(gridColumns - 1, max(0, Int(point.x / size.width * CGFloat(gridColumns))))
                let row = min(gridRows - 1, max(0, Int(point.y / size.height * CGFloat(gridRows))))
                touchedCells.insert(row * gridColumns + column)

                let progress = Double(touchedCells.count) / Double(gridColumns * gridRows)
                if progress >= 0.5 {
                    reveal()
                }
            }
    }

    private var scratchProgress: Double {
        Double(touchedCells.count) / Double(gridColumns * gridRows)
    }

    private var scratchLayerOpacity: Double {
        max(0, 1 - scratchProgress * 2)
    }

    private func reveal() {
        guard !isRevealed else { return }
        pulse = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        appState.revealBonus(bonus)
        withAnimation(.easeOut(duration: 0.32)) {
            isRevealed = true
        }
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.2)) {
            appeared = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(210))
            appState.presentedScratchBonus = nil
        }
    }
}

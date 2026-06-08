import Combine
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var quizPresented = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ScreenBackground(assetName: "background_home")

            ScrollView {
                VStack(spacing: 18) {
                    logo
                    profileCard
                    quizCard
                    clubSummary
                }
                .padding()
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Ice Pier")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $quizPresented) {
            DailyQuizView()
        }
        .onReceive(timer) { now = $0 }
    }

    private var logo: some View {
        AssetArtwork(name: "home_vertical_logo", scaling: .contain)
            .frame(height: 150)
            .padding(.top, 4)
    }

    private var profileCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                AvatarView(image: appState.avatarImage, size: 62)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Welcome, \(appState.data.displayName)")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)

                    HStack(spacing: 7) {
                        AssetArtwork(name: "icon_experience", scaling: .contain, cornerRadius: 6)
                            .frame(width: 24, height: 24)
                        Text("\(appState.data.experience) XP")
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                    .foregroundStyle(AppTheme.sky)
                }
                Spacer()
            }
        }
    }

    private var quizCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                AssetArtwork(name: "daily_quiz_button", scaling: .contain, cornerRadius: 18)
                    .frame(height: 170)

                if appState.quizCompletedToday {
                    Label(timeUntilTomorrow, systemImage: "clock.fill")
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white)
                    Text("Today's challenge is complete. A new quiz unlocks at midnight.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.78))
                } else {
                    Text("Daily Icebreaker Quiz")
                        .font(.title2.bold())
                    Text("Answer five questions. A perfect score unlocks an ice scratch card.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.78))
                    Button("Start today's quiz") {
                        quizPresented = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .foregroundStyle(.white)
        }
    }

    private var clubSummary: some View {
        GlassCard {
            HStack {
                Label("\(appState.activeBonuses.count) active rewards", systemImage: "gift.fill")
                Spacer()
                Button("Open catch") {
                    appState.selectedTab = .catchBox
                }
                .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
        }
    }

    private var timeUntilTomorrow: String {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let interval = max(0, Int(tomorrow.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", interval / 3600, (interval % 3600) / 60, interval % 60)
    }
}

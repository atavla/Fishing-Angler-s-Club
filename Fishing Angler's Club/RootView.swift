import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                ZStack {
                    TabView(selection: $appState.selectedTab) {
                        NavigationStack {
                            HomeView()
                        }
                        .tag(AppTab.home)
                        .tabItem { Label("Pier", systemImage: "house.fill") }

                        NavigationStack {
                            CatchBoxView()
                        }
                        .tag(AppTab.catchBox)
                        .tabItem { Label("My Catch", systemImage: "shippingbox.fill") }

                        NavigationStack {
                            GuideView()
                        }
                        .tag(AppTab.guide)
                        .tabItem { Label("Guide", systemImage: "book.fill") }

                        NavigationStack {
                            SettingsView()
                        }
                        .tag(AppTab.settings)
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    }
                    .tint(AppTheme.orange)

                    if let bonus = appState.presentedScratchBonus {
                        ScratchOverlayView(bonus: bonus)
                            .zIndex(10)
                            .transition(.opacity)
                    }
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.22), value: appState.presentedScratchBonus)
        .alert(
            "Storage Notice",
            isPresented: Binding(
                get: { appState.storageErrorMessage != nil },
                set: { if !$0 { appState.storageErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.storageErrorMessage ?? "")
        }
    }
}

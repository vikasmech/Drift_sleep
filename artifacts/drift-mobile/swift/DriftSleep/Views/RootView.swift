import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        Group {
            if store.showChooser {
                ChooseView()
            } else {
                tabs
            }
        }
        .fullScreenCover(isPresented: $store.showPaywall, onDismiss: { store.dismissPaywall() }) {
            PaywallView().environmentObject(store)
        }
    }

    private var tabs: some View {
        TabView(selection: $store.tab) {
            TonightView()
                .tabItem { Label("Tonight", systemImage: "moon.stars") }
                .tag(AppTab.tonight)
            SoundsView()
                .tabItem { Label("Sounds", systemImage: "waveform") }
                .tag(AppTab.sounds)
            FavouritesView()
                .tabItem { Label("Favourites", systemImage: "heart") }
                .tag(AppTab.favourites)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Theme.amber)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Button { store.returnToChooser() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.leading, 8)
            .background(Color.black)
        }
    }
}

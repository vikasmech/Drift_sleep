import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        Group {
            if store.showOneTap {
                OneTapView()
            } else {
                tabs
            }
        }
        .tint(Theme.amber)
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
    }
}

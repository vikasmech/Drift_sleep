import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TonightView().tabItem { Label("Tonight", systemImage: "moon.stars") }
            SoundsView().tabItem { Label("Sounds", systemImage: "waveform") }
            FavouritesView().tabItem { Label("Favourites", systemImage: "heart") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.amber)
    }
}

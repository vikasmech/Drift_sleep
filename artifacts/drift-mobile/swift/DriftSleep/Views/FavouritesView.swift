import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject private var store: DriftStore

    private var items: [Soundscape] { Soundscape.all.filter { store.favourites.contains($0.id) } }

    var body: some View {
        Screen(title: "Favourites") {
            if items.isEmpty {
                Card {
                    Image(systemName: "heart").font(.largeTitle).foregroundStyle(Theme.amber).accessibilityHidden(true)
                    Text("Nothing saved yet").font(.headline).foregroundStyle(Theme.text)
                    Text("Tap the heart on any sound in Sounds and it will wait for you here.")
                        .foregroundStyle(Theme.muted)
                }
            } else {
                ForEach(items) { SoundRow(sound: $0) }
            }
        }
    }
}

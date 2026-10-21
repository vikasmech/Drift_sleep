import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject private var store: DriftStore

    private var sounds: [Soundscape] { Soundscape.all.filter { store.favourites.contains($0.id) } }
    private var sessions: [GuidedSession] { GuidedSession.all.filter { store.favourites.contains($0.id) } }
    private var isEmpty: Bool { sounds.isEmpty && sessions.isEmpty }

    var body: some View {
        Screen(title: "Favourites") {
            if isEmpty {
                Card {
                    Image(systemName: "heart").font(.largeTitle).foregroundStyle(Theme.amber).accessibilityHidden(true)
                    Text("Nothing saved").font(.headline).foregroundStyle(Theme.text)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(sessions) { GuidedTile(session: $0) }
                    ForEach(sounds) { SoundTile(sound: $0) }
                }
            }
        }
    }
}

import SwiftUI

struct SoundRow: View {
    @EnvironmentObject private var store: DriftStore
    let sound: Soundscape

    private var isCurrent: Bool { store.currentID == sound.id }
    private var active: Bool { isCurrent && (store.state == .playing || store.state == .loading) }
    private var status: String? {
        guard isCurrent else { return nil }
        switch store.state {
        case .loading: return "Loading"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .ended: return "Preview finished"
        case .error: return store.errorMessage ?? "Could not play"
        case .idle: return nil
        }
    }

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.title).font(.headline).foregroundStyle(Theme.text)
                    Text(sound.detail).font(.subheadline).foregroundStyle(Theme.muted)
                    Text(sound.isFree ? "\(sound.category) · Free, unlimited" : "\(sound.category) · 30-second preview only")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(sound.isFree ? Theme.amber : Theme.muted)
                }
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    Button { store.toggle(sound) } label: {
                        Image(systemName: active ? "pause.fill" : "play.fill")
                            .font(.title3).foregroundStyle(Theme.onAmber)
                            .frame(width: 48, height: 48).background(Theme.amber, in: Circle())
                    }
                    .accessibilityLabel(active ? "Pause \(sound.title)" : (sound.isFree ? "Play \(sound.title)" : "Preview \(sound.title)"))
                    Button { store.toggleFavourite(sound) } label: {
                        Image(systemName: store.favourites.contains(sound.id) ? "heart.fill" : "heart")
                            .foregroundStyle(Theme.amber).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(store.favourites.contains(sound.id) ? "Remove \(sound.title) from favourites" : "Add \(sound.title) to favourites")
                }
            }
            if let status {
                HStack(spacing: 8) {
                    if store.state == .loading { ProgressView().tint(Theme.amber) }
                    Text(status).font(.footnote)
                        .foregroundStyle(store.state == .error ? Theme.danger : Theme.muted)
                    if isCurrent, store.state == .playing || store.state == .paused || store.state == .error || store.state == .ended {
                        Spacer()
                        Button(store.state == .error ? "Retry" : "Stop") {
                            if store.state == .error { store.play(sound) } else { store.stop() }
                        }.buttonStyle(AmberButtonStyle(filled: false))
                    }
                }
                if isCurrent, store.state == .playing, sound.isFree, let left = store.remainingSeconds {
                    Text("Fades out in \(clock(left))").font(.footnote.monospacedDigit()).foregroundStyle(Theme.amber)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

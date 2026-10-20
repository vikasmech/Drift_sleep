import SwiftUI

struct SoundRow: View {
    @EnvironmentObject private var store: DriftStore
    let sound: Soundscape

    private var active: Bool {
        store.currentID == sound.id && (store.state == .playing || store.state == .loading)
    }
    private var line: String {
        sound.detail.split(separator: ".").first.map(String.init) ?? sound.detail
    }

    var body: some View {
        HStack(spacing: 8) {
            Button { store.selectSound(sound, autoplay: true) } label: {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.title)
                            .font(.body)
                            .foregroundStyle(.white)
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if active {
                        Image(systemName: "waveform")
                            .foregroundStyle(.white)
                    }
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(sound.title)")
            Button { store.toggleFavourite(sound) } label: {
                Image(systemName: store.favourites.contains(sound.id) ? "heart.fill" : "heart")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.favourites.contains(sound.id) ? "Remove \(sound.title) from favourites" : "Add \(sound.title) to favourites")
        }
    }

    private var icon: String {
        switch sound.category {
        case "Rain": return "cloud.rain"
        case "Water": return "water.waves"
        case "Nature": return "leaf"
        case "Music": return "moon"
        default: return "waveform"
        }
    }
}

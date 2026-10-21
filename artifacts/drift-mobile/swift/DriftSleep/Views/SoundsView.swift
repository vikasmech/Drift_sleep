import SwiftUI

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, yoga, nsdr, rain, whiteNoise, water, noise, nature, music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .yoga: return "Yoga Nidra"
        case .nsdr: return "NSDR"
        case .rain: return "Rain"
        case .whiteNoise: return "White Noise"
        case .water: return "Water"
        case .noise: return "Noise"
        case .nature: return "Nature"
        case .music: return "Music"
        }
    }

    var sessions: [GuidedSession] {
        switch self {
        case .all: return GuidedSession.all
        case .yoga: return GuidedSession.all.filter { $0.practice == "Yoga Nidra" }
        case .nsdr: return GuidedSession.all.filter { $0.practice == "NSDR" }
        default: return []
        }
    }

    var sounds: [Soundscape] {
        switch self {
        case .all: return Soundscape.all
        case .rain: return Soundscape.all.filter { $0.category == "Rain" }
        case .whiteNoise: return Soundscape.all.filter { $0.id == "white-noise" }
        case .water: return Soundscape.all.filter { $0.category == "Water" }
        case .noise: return Soundscape.all.filter { $0.category == "Noise" }
        case .nature: return Soundscape.all.filter { $0.category == "Nature" }
        case .music: return Soundscape.all.filter { $0.category == "Music" }
        default: return []
        }
    }
}

struct SoundsView: View {
    @EnvironmentObject private var store: DriftStore
    @State private var filter: LibraryFilter = .all

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Find your quiet")
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 20)
                    filterBar
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filter.sessions) { session in
                            GuidedTile(session: session)
                        }
                        ForEach(filter.sounds) { sound in
                            SoundTile(sound: sound)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(MidnightBackground())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { item in
                    let on = filter == item
                    Button { filter = item } label: {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundStyle(on ? Theme.onAmber : Theme.muted)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(on ? Theme.text : Color.clear, in: Capsule())
                            .overlay(Capsule().stroke(on ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct SoundTile: View {
    @EnvironmentObject private var store: DriftStore
    let sound: Soundscape

    private var active: Bool {
        store.currentID == sound.id && (store.state == .playing || store.state == .loading)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button { store.selectSound(sound, autoplay: true) } label: {
                tileFace(
                    tint: AmbientTint.sound(sound),
                    kicker: sound.category.uppercased(),
                    title: sound.title,
                    active: active
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(sound.title)")
            heart(on: store.favourites.contains(sound.id)) { store.toggleFavourite(sound) }
                .accessibilityLabel(store.favourites.contains(sound.id) ? "Remove \(sound.title) from favourites" : "Add \(sound.title) to favourites")
        }
    }
}

struct GuidedTile: View {
    @EnvironmentObject private var store: DriftStore
    let session: GuidedSession

    private var active: Bool {
        store.currentID == session.id && (store.state == .playing || store.state == .loading)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button { store.selectGuided(session, autoplay: true) } label: {
                tileFace(
                    tint: AmbientTint.session(session),
                    kicker: session.practice.uppercased(),
                    title: session.title,
                    active: active
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(session.title)")
            heart(on: store.favourites.contains(session.id)) { store.toggleFavourite(session.id) }
                .accessibilityLabel(store.favourites.contains(session.id) ? "Remove \(session.title) from favourites" : "Add \(session.title) to favourites")
        }
    }
}

private func tileFace(tint: Color, kicker: String, title: String, active: Bool) -> some View {
    ZStack(alignment: .bottomLeading) {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Theme.card)
        RadialGradient(
            colors: [tint.opacity(0.14), Color.clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: 120
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                Text(kicker)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(Theme.muted)
            }
            Text(title)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .padding(.trailing, 28)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 168)
    .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(active ? Theme.text.opacity(0.28) : Theme.border, lineWidth: 1)
    )
}

private func heart(on: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: on ? "heart.fill" : "heart")
            .font(.footnote)
            .foregroundStyle(on ? Theme.text : Theme.quiet)
            .frame(width: 36, height: 36)
    }
    .buttonStyle(.plain)
    .padding(6)
}

enum AmbientTint {
    static func sound(_ sound: Soundscape) -> Color {
        switch sound.category {
        case "Rain": return Color(red: 138 / 255, green: 160 / 255, blue: 184 / 255)
        case "Water": return Color(red: 122 / 255, green: 154 / 255, blue: 156 / 255)
        case "Nature": return Color(red: 142 / 255, green: 158 / 255, blue: 136 / 255)
        case "Music": return Color(red: 155 / 255, green: 147 / 255, blue: 176 / 255)
        default: return Color(red: 168 / 255, green: 154 / 255, blue: 140 / 255)
        }
    }

    static func session(_ session: GuidedSession) -> Color {
        session.practice == "Yoga Nidra"
            ? Color(red: 168 / 255, green: 148 / 255, blue: 160 / 255)
            : Color(red: 154 / 255, green: 150 / 255, blue: 196 / 255)
    }
}

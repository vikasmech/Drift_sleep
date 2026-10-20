import SwiftUI

struct GuidedRow: View {
    @EnvironmentObject private var store: DriftStore
    let session: GuidedSession

    private var active: Bool { store.currentID == session.id && store.state == .playing }

    var body: some View {
        HStack(spacing: 8) {
            Button { store.selectGuided(session, autoplay: true) } label: {
                HStack(spacing: 16) {
                    Image(systemName: "moon.stars")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.title)
                            .font(.body)
                            .foregroundStyle(.white)
                        Text("\(session.practice) · \(session.minutes) min")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.45))
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
            .accessibilityLabel("Play \(session.title)")
            Button { store.toggleFavourite(session.id) } label: {
                Image(systemName: store.favourites.contains(session.id) ? "heart.fill" : "heart")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.favourites.contains(session.id) ? "Remove \(session.title) from favourites" : "Add \(session.title) to favourites")
        }
    }
}

import SwiftUI

struct TonightView: View {
    @EnvironmentObject private var store: DriftStore

    private var session: GuidedSession? { GuidedSession.find(store.selectedID) }
    private var sound: Soundscape { store.selectedSound }
    private var title: String { session?.title ?? sound.title }
    private var showing: Bool { store.currentID == store.selectedID }
    private var isPlaying: Bool { showing && (store.state == .playing || store.state == .loading) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Button { store.toggleFavourite(store.selectedID) } label: {
                    Image(systemName: store.favourites.contains(store.selectedID) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(store.favourites.contains(store.selectedID) ? "Remove favourite" : "Add favourite")
                if isPlaying {
                    Waveform(samples: store.wave, time: store.waveTime)
                        .frame(height: 140)
                        .padding(.horizontal, 28)
                        .onTapGesture { store.playSelected() }
                        .accessibilityLabel("Pause")
                } else {
                    Button { store.playSelected() } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 156, height: 156)
                            .overlay(
                                Text(showing && store.state == .paused ? "resume" : "play")
                                    .font(.title3)
                                    .foregroundStyle(.black)
                            )
                    }
                    .accessibilityLabel(showing && store.state == .paused ? "Resume" : "Play")
                }
                if showing, store.state == .error {
                    Text(store.errorMessage ?? "Could not play.")
                        .font(.footnote)
                        .foregroundStyle(Theme.danger)
                        .multilineTextAlignment(.center)
                    Button("Retry") { store.playSelected() }
                        .font(.footnote)
                        .foregroundStyle(.white)
                }
                if isPlaying {
                    Button("Stop") { store.stop() }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 28)
        }
    }
}

struct Waveform: View {
    var samples: [CGFloat]
    var time: CGFloat

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let columns = 36
            let rows = 11
            let count = max(samples.count, 1)
            for column in 0..<columns {
                let nx = CGFloat(column) / CGFloat(columns - 1)
                let index = min(count - 1, Int(nx * CGFloat(count - 1)))
                let level = samples[index]
                let envelope = sin(nx * .pi)
                let travel = sin(nx * .pi * 4 + time * 2.4)
                let center = ((level - 0.45) * 0.7 + travel * (0.25 + level * 0.75)) * envelope
                let thickness = 0.07 + level * 0.38
                for row in 0..<rows {
                    let ny = (CGFloat(row) / CGFloat(rows - 1)) * 2 - 1
                    let band = abs(ny - center)
                    guard band < thickness * envelope + 0.04 else { continue }
                    let fade = (1 - band) * (0.35 + level * 0.65) * envelope
                    let dot = CGRect(
                        x: nx * size.width - 1.4,
                        y: midY + ny * size.height * 0.46 - 1.4,
                        width: 2.8,
                        height: 2.8
                    )
                    context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.2 + 0.8 * fade)))
                }
            }
        }
        .animation(.linear(duration: 0.08), value: samples)
    }
}

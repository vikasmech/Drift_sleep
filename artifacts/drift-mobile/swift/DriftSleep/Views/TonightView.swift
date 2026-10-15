import SwiftUI

struct TonightView: View {
    @EnvironmentObject private var store: DriftStore

    private var usual: Soundscape { store.usualSound }
    private var showingUsual: Bool { store.currentID == usual.id }
    private var isPlaying: Bool { showingUsual && store.state == .playing }

    var body: some View {
        Screen(title: "Tonight") {
            Card {
                Text("Your usual").font(.subheadline).foregroundStyle(Theme.muted)
                Text(usual.title).font(.largeTitle.weight(.semibold)).foregroundStyle(Theme.text)
                Text(usual.detail).foregroundStyle(Theme.muted)
                HStack(spacing: 12) {
                    Button {
                        if showingUsual { store.toggle(usual) } else { store.play(usual) }
                    } label: {
                        Label(label, systemImage: isPlaying || (showingUsual && store.state == .loading) ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(AmberButtonStyle())
                    if store.currentID != nil {
                        Button { store.stop() } label: { Label("Stop", systemImage: "stop.fill") }
                            .buttonStyle(AmberButtonStyle(filled: false))
                    }
                }
                if store.state == .loading, showingUsual {
                    HStack { ProgressView().tint(Theme.amber); Text("Getting your sound ready").foregroundStyle(Theme.muted) }
                }
                if store.state == .error, showingUsual {
                    Text(store.errorMessage ?? "Could not play.").font(.footnote).foregroundStyle(Theme.danger)
                    Button("Retry") { store.play(usual) }.buttonStyle(AmberButtonStyle())
                }
                if isPlaying, let left = store.remainingSeconds {
                    Text(left > 0 ? "Stops in \(clock(left))" : "Stopping").font(.title3.monospacedDigit()).foregroundStyle(Theme.amber)
                        .accessibilityLabel("Stops in \(clock(left))")
                }
            }
            if let other = store.currentSound, other.id != usual.id {
                Card {
                    Text("Also selected").font(.subheadline).foregroundStyle(Theme.muted)
                    Text(other.title).font(.headline).foregroundStyle(Theme.text)
                    Text(other.isFree ? "Playing without limits." : "30-second preview, then it ends. No timer applies.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                    if store.state == .error {
                        Text(store.errorMessage ?? "Could not play.").font(.footnote).foregroundStyle(Theme.danger)
                        Button("Retry") { store.play(other) }.buttonStyle(AmberButtonStyle())
                    }
                }
            }
            Card {
                Text("Sleep timer").font(.headline).foregroundStyle(Theme.text)
                TimerPicker()
                Text("Sound fades gently over the last 8 seconds, then stops. Applies to free sounds.")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
    }

    private var label: String {
        guard showingUsual else { return "Play" }
        switch store.state {
        case .playing, .loading: return "Pause"
        case .paused: return "Resume"
        default: return "Play"
        }
    }
}

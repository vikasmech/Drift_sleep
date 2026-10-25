import SwiftUI

struct TonightView: View {
    @EnvironmentObject private var store: DriftStore

    private var session: GuidedSession? { GuidedSession.find(store.selectedID) }
    private var sound: Soundscape { store.selectedSound }
    private var title: String { session?.title ?? sound.title }
    private var eyebrow: String { session?.practice.uppercased() ?? "TONIGHT'S AMBIENCE" }
    private var showing: Bool { store.currentID == store.selectedID }
    private var isPlaying: Bool { showing && (store.state == .playing || store.state == .loading) }
    private var isPaused: Bool { showing && store.state == .paused }

    var body: some View {
        ZStack {
            MidnightBackground()
            VStack(spacing: 0) {
                titleBlock
                    .padding(.top, 12)
                Spacer(minLength: 20)
                player
                Spacer(minLength: 20)
                controls
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 28)
        }
    }

    private var titleBlock: some View {
        HStack(alignment: .center) {
            Color.clear.frame(width: 44, height: 44)
            VStack(spacing: 10) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(3.2)
                    .foregroundStyle(Theme.muted)
                Text(title)
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            Button { store.toggleFavourite(store.selectedID) } label: {
                Image(systemName: store.favourites.contains(store.selectedID) ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundStyle(Theme.muted)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(store.favourites.contains(store.selectedID) ? "Remove favourite" : "Add favourite")
        }
    }

    private var player: some View {
        Button { store.playSelected() } label: {
            ZStack {
                if isPlaying {
                    AmbientField(samples: store.wave, time: store.waveTime)
                } else {
                    restingDisc
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause" : isPaused ? "Resume" : "Play")
    }

    private var restingDisc: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let breath = (sin(timeline.date.timeIntervalSinceReferenceDate * 0.7) + 1) / 2
            ZStack {
                Circle()
                    .stroke(Theme.hairline.opacity(0.45 + breath * 0.4), lineWidth: 1)
                    .frame(width: 214 + breath * 18, height: 214 + breath * 18)
                Circle()
                    .stroke(Theme.hairline.opacity(0.28), lineWidth: 1)
                    .frame(width: 252, height: 252)
                Circle()
                    .fill(Color.white.opacity(0.045))
                    .frame(width: 168, height: 168)
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                    .shadow(color: Color.white.opacity(0.05), radius: 28)
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.text.opacity(0.88))
                    .offset(x: 2)
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 18) {
            if showing, store.state == .error {
                Text(store.errorMessage ?? "Could not play.")
                    .font(.footnote)
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
                Button("Retry") { store.playSelected() }
                    .font(.footnote)
                    .foregroundStyle(Theme.text)
            }
            HStack(spacing: 10) {
                timerChip
                if session == nil && PlaybackPolicy.isLoopable(isFreeSound: sound.isFree, isPurchased: store.isPurchased) {
                    loopChip
                }
            }
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .accessibilityHidden(true)
                Slider(value: $store.volume, in: 0...1)
                    .tint(Theme.muted)
                    .accessibilityLabel("Volume")
                    .accessibilityValue("\(Int(store.volume * 100)) percent")
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .accessibilityHidden(true)
            }
        }
    }

    private var timerChip: some View {
        Menu {
            ForEach(DriftStore.timerOptions, id: \.self) { minutes in
                Button(timerLabel(minutes)) { store.timerMinutes = minutes }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                Text(timerChipTitle)
            }
            .font(.footnote)
            .foregroundStyle(Theme.text.opacity(0.86))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Color.white.opacity(0.05), in: Capsule())
            .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        }
        .accessibilityLabel("Sleep timer, \(timerChipTitle)")
    }

    private var loopChip: some View {
        Button { store.loops.toggle() } label: {
            HStack(spacing: 6) {
                Image(systemName: "repeat")
                Text("Loop")
            }
            .font(.footnote)
            .foregroundStyle(store.loops ? Theme.text.opacity(0.86) : Theme.muted)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(store.loops ? Color.white.opacity(0.08) : Color.white.opacity(0.05), in: Capsule())
            .overlay(Capsule().stroke(store.loops ? Theme.hairline : Theme.hairline.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Loop")
        .accessibilityValue(store.loops ? "On" : "Off")
        .accessibilityAddTraits(store.loops ? .isSelected : [])
    }

    private var timerChipTitle: String {
        if isPlaying, let left = store.remainingSeconds, store.timerMinutes > 0 {
            return clock(left)
        }
        return store.timerMinutes == 0 ? "Off" : "\(store.timerMinutes)m"
    }
}

struct AmbientField: View {
    var samples: [CGFloat]
    var time: CGFloat

    var body: some View {
        Canvas { context, size in
            let count = max(samples.count, 1)
            let level = samples.reduce(0, +) / CGFloat(count)
            let mid = size.height / 2
            for wave in 0..<3 {
                var path = Path()
                let depth = CGFloat(wave)
                let amplitude = (16 + level * 42) * (1 - depth * 0.22)
                let phase = time * (0.55 + depth * 0.12) + depth * 1.15
                let frequency = 1.35 + depth * 0.4
                var started = false
                stride(from: 0, through: size.width, by: 2).forEach { x in
                    let nx = x / max(size.width, 1)
                    let envelope = sin(nx * .pi)
                    let y = mid + sin(nx * .pi * frequency * 2 + phase) * amplitude * envelope
                    let point = CGPoint(x: x, y: y)
                    if started { path.addLine(to: point) } else { path.move(to: point); started = true }
                }
                let opacity = 0.16 + 0.42 * level - depth * 0.04
                context.stroke(
                    path,
                    with: .color(Theme.text.opacity(max(0.08, opacity))),
                    style: StrokeStyle(lineWidth: 1.6 - depth * 0.3, lineCap: .round)
                )
            }
        }
    }
}

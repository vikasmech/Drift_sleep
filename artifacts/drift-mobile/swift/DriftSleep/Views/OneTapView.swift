import SwiftUI

struct OneTapView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        ZStack {
            MidnightBackground()
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Text("DRIFT")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(3.2)
                        .foregroundStyle(Theme.muted)
                    Text("One tap\nsleep")
                        .font(.system(size: 44, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.top, 36)
                Spacer()
                Button { store.beginSleep() } label: {
                    restingDisc
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play \(store.usualSound.title)")
                Spacer()
                VStack(spacing: 22) {
                    Text(store.usualSound.title)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.muted)
                    Button { store.openLibrary() } label: {
                        Text("Choose a sound")
                            .font(.subheadline)
                            .foregroundStyle(Theme.quiet)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 28)
        }
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
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.text.opacity(0.88))
                    .offset(x: 2)
            }
        }
    }
}

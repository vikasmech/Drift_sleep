import SwiftUI

enum Theme {
    static func hsl(_ h: Double, _ s: Double, _ l: Double) -> Color {
        let sn = s / 100, ln = l / 100
        let v = ln + sn * min(ln, 1 - ln)
        let sb = v == 0 ? 0 : 2 * (1 - ln / v)
        return Color(hue: h / 360, saturation: sb, brightness: v)
    }
    static let background = Color(red: 10 / 255, green: 11 / 255, blue: 14 / 255)
    static let lift = Color(red: 18 / 255, green: 20 / 255, blue: 26 / 255)
    static let card = Color(red: 20 / 255, green: 22 / 255, blue: 28 / 255)
    static let secondary = Color.white.opacity(0.08)
    static let text = Color(red: 237 / 255, green: 236 / 255, blue: 232 / 255)
    static let amber = text
    static let onAmber = background
    static let muted = Color(red: 125 / 255, green: 130 / 255, blue: 141 / 255)
    static let quiet = Color(red: 82 / 255, green: 86 / 255, blue: 96 / 255)
    static let accent = Color.white.opacity(0.06)
    static let danger = Color(red: 1, green: 0.55, blue: 0.48)
    static let border = Color.white.opacity(0.07)
    static let hairline = Color.white.opacity(0.07)
}

struct MidnightBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Theme.lift, Theme.background],
                center: .center,
                startRadius: 40,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border))
    }
}

struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) { content }
                    .padding(.horizontal, 20).padding(.bottom, 32)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct AmberButtonStyle: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(filled ? Theme.onAmber : Theme.amber)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(filled ? Theme.amber : Theme.secondary, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

func clock(_ seconds: TimeInterval) -> String {
    let s = Int(seconds.rounded(.up))
    return String(format: "%d:%02d", s / 60, s % 60)
}

func timerLabel(_ minutes: Int) -> String { minutes == 0 ? "No timer" : "\(minutes) min" }

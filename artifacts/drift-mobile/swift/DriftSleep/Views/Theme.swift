import SwiftUI

enum Theme {
    static func hsl(_ h: Double, _ s: Double, _ l: Double) -> Color {
        let sn = s / 100, ln = l / 100
        let v = ln + sn * min(ln, 1 - ln)
        let sb = v == 0 ? 0 : 2 * (1 - ln / v)
        return Color(hue: h / 360, saturation: sb, brightness: v)
    }
    static let background = hsl(233, 40, 8)
    static let card = hsl(233, 34, 12)
    static let secondary = hsl(233, 30, 17)
    static let text = hsl(38, 40, 90)
    static let amber = hsl(38, 72, 72)
    static let onAmber = hsl(233, 40, 10)
    static let muted = hsl(232, 18, 66)
    static let accent = hsl(250, 34, 24)
    static let danger = hsl(8, 60, 58)
    static let border = hsl(233, 26, 18)
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

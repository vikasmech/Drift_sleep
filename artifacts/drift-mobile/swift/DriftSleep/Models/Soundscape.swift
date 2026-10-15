import Foundation

struct Soundscape: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let category: String
    let isFree: Bool

    var filename: String { isFree ? "loop-v2-\(id).wav" : "native-\(id).mp3" }

    static let all: [Soundscape] = [
        .init(id: "gentle-rain", title: "Gentle rain", detail: "A soft, steady shower. Nothing to think about.", category: "Rain", isFree: true),
        .init(id: "ocean-waves", title: "Ocean waves", detail: "Slow surf rolling onto a quiet shore.", category: "Water", isFree: true),
        .init(id: "brown-noise", title: "Brown noise", detail: "Deep, warm noise that settles into the background.", category: "Noise", isFree: true),
        .init(id: "pink-noise", title: "Pink noise", detail: "Balanced, softly textured noise.", category: "Noise", isFree: true),
        .init(id: "soft-fan", title: "Soft fan", detail: "A familiar, low whirr for your bedside.", category: "Noise", isFree: true),
        .init(id: "rain-on-glass", title: "Rain on glass", detail: "A softened shower, as heard through a window.", category: "Rain", isFree: false),
        .init(id: "warm-rain", title: "Warm rain", detail: "A deeper, muted rainfall texture.", category: "Rain", isFree: false),
        .init(id: "distant-rain", title: "Distant rain", detail: "Rainfall softened by distance.", category: "Rain", isFree: false),
        .init(id: "evening-shower", title: "Evening shower", detail: "A lighter veil of falling rain.", category: "Rain", isFree: false),
        .init(id: "rainy-room", title: "Rainy room", detail: "A sheltered, warm version of gentle rain.", category: "Rain", isFree: false),
        .init(id: "quiet-cove", title: "Quiet cove", detail: "A gentler, sheltered ocean wash.", category: "Water", isFree: false),
        .init(id: "distant-surf", title: "Distant surf", detail: "The low wash of a faraway shoreline.", category: "Water", isFree: false),
        .init(id: "moonlit-sea", title: "Moonlit sea", detail: "A wide, slow ocean texture.", category: "Water", isFree: false),
        .init(id: "soft-tide", title: "Soft tide", detail: "A warm, softened tide.", category: "Water", isFree: false),
        .init(id: "deep-water", title: "Deep water", detail: "Deep layers of flowing sound.", category: "Water", isFree: false),
        .init(id: "white-noise", title: "White noise", detail: "Even, full-spectrum masking noise.", category: "Noise", isFree: false),
        .init(id: "velvet-noise", title: "Velvet noise", detail: "A very soft, low-frequency noise bed.", category: "Noise", isFree: false),
        .init(id: "warm-static", title: "Warm static", detail: "Gentle filtered static without sharp edges.", category: "Noise", isFree: false),
        .init(id: "cabin-fan", title: "Cabin fan", detail: "A deeper fan texture with a steady hum.", category: "Noise", isFree: false),
        .init(id: "airflow", title: "Airflow", detail: "An airy, smooth background hush.", category: "Noise", isFree: false),
        .init(id: "night-forest", title: "Night forest", detail: "Soft crickets and a breeze through leaves.", category: "Nature", isFree: false),
        .init(id: "woodland-hush", title: "Woodland hush", detail: "A muted version of the nighttime forest.", category: "Nature", isFree: false),
        .init(id: "distant-crickets", title: "Distant crickets", detail: "A lighter, distant nocturnal texture.", category: "Nature", isFree: false),
        .init(id: "sheltered-grove", title: "Sheltered grove", detail: "A warm, enclosed woodland ambience.", category: "Nature", isFree: false),
        .init(id: "evening-breeze", title: "Evening breeze", detail: "Soft leaves and a filtered evening hush.", category: "Nature", isFree: false),
        .init(id: "soft-ambient", title: "Soft ambient", detail: "Slow, warm instrumental pads. No beat.", category: "Music", isFree: false),
        .init(id: "low-glow", title: "Low glow", detail: "A deeper, softer ambient layer.", category: "Music", isFree: false),
        .init(id: "quiet-orbit", title: "Quiet orbit", detail: "An airy edit of the ambient collection.", category: "Music", isFree: false),
        .init(id: "stillness", title: "Stillness", detail: "Gentle sustained chords, softly filtered.", category: "Music", isFree: false),
        .init(id: "last-light", title: "Last light", detail: "A warm, close version of the ambient pads.", category: "Music", isFree: false)
    ]
    static let free = all.filter(\.isFree)
    static let categories = ["Rain", "Water", "Noise", "Nature", "Music"]
    static func find(_ id: String) -> Soundscape? { all.first { $0.id == id } }
}

enum PlayState: String { case idle, loading, playing, paused, ended, error }

struct SleepDeadline {
    private(set) var end: Date?
    mutating func start(minutes: Int, now: Date = Date()) {
        end = minutes > 0 ? now.addingTimeInterval(Double(minutes) * 60) : nil
    }
    mutating func clear() { end = nil }
    func remaining(now: Date = Date()) -> TimeInterval? {
        end.map { max(0, $0.timeIntervalSince(now)) }
    }
    func gain(now: Date = Date()) -> Float {
        guard let remaining = remaining(now: now) else { return 1 }
        return Float(min(1, remaining / 8))
    }
}

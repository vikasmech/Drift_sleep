import SwiftUI

struct SoundsView: View {
    @State private var category: String?

    private var sounds: [Soundscape] {
        Soundscape.all.filter { category == nil || $0.category == category }
    }

    var body: some View {
        Screen(title: "Sounds") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("All", nil)
                    ForEach(Soundscape.categories, id: \.self) { chip($0, $0) }
                }
            }
            Text("Five sounds are free and unlimited. The other \(Soundscape.all.count - Soundscape.free.count) are 30-second previews only.")
                .font(.footnote).foregroundStyle(Theme.muted)
            ForEach(sounds) { SoundRow(sound: $0) }
        }
    }

    private func chip(_ title: String, _ value: String?) -> some View {
        let on = category == value
        return Button { category = value } label: {
            Text(title).font(.subheadline.weight(.medium))
                .foregroundStyle(on ? Theme.onAmber : Theme.text)
                .padding(.horizontal, 16).frame(minHeight: 44)
                .background(on ? Theme.amber : Theme.secondary, in: Capsule())
        }
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

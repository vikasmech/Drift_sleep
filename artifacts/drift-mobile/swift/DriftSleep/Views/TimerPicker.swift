import SwiftUI

struct TimerPicker: View {
    @EnvironmentObject private var store: DriftStore
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DriftStore.timerOptions, id: \.self) { m in
                    let on = store.timerMinutes == m
                    Button { store.timerMinutes = m } label: {
                        Text(timerLabel(m)).font(.subheadline.weight(.medium))
                            .foregroundStyle(on ? Theme.onAmber : Theme.text)
                            .padding(.horizontal, 14).frame(minHeight: 44)
                            .background(on ? Theme.amber : Theme.secondary, in: Capsule())
                    }
                    .accessibilityLabel(timerLabel(m))
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }
}

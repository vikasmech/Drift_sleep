import SwiftUI

struct ChooseView: View {
    @EnvironmentObject private var store: DriftStore

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            LazyVGrid(columns: columns, spacing: 14) {
                pill("Yoga Nidra") { store.chooseGuided("nothing-more-tonight") }
                pill("NSDR") { store.chooseGuided("little-space") }
                pill("Rain") { store.chooseSound("gentle-rain") }
                pill("White Noise") { store.chooseSound("white-noise") }
            }
            .padding(.horizontal, 22)
            .padding(.top, 36)
        }
    }

    private func pill(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white.opacity(0.04), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

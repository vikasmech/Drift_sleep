import SwiftUI

struct SoundsView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Find your quiet")
                        .font(.title2)
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Soundscape.all) { SoundRow(sound: $0) }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(.bottom, 8)
                        ForEach(GuidedSession.all) { GuidedRow(session: $0) }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep timer")
                            .font(.title3)
                            .foregroundStyle(.white)
                        TimerPicker()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

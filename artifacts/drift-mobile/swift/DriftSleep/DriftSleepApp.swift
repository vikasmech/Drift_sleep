import SwiftUI

@main
@MainActor
struct DriftSleepApp: App {
    @StateObject private var store = DriftStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.checkDeadline()
                        store.onForeground()
                    }
                }
        }
    }
}

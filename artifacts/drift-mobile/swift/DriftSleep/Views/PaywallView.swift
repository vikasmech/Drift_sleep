import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 12)
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(description)
                    .foregroundStyle(Theme.muted)
                if !store.hasStartedTrial && !store.isPurchased {
                    Text(trialDisclosure)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                    Button {
                        Task { await store.startFreeTrial() }
                    } label: {
                        Label(store.isPurchasing ? "Starting…" : "Start 7-day free trial", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AmberButtonStyle())
                    .disabled(store.isPurchasing || store.trialProduct == nil || store.plusProduct == nil)
                }
                if let purchaseError = store.purchaseError {
                    Text(purchaseError).font(.footnote).foregroundStyle(Theme.danger)
                }
                Button {
                    Task { await store.purchasePlus() }
                } label: {
                    Label(unlockTitle, systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AmberButtonStyle())
                .disabled(store.isPurchasing || store.plusProduct == nil)
                Button("Restore purchase") {
                    Task { await store.restorePurchases() }
                }
                .buttonStyle(AmberButtonStyle(filled: false))
                .disabled(store.isPurchasing)
                Button("Not now") { store.dismissPaywall() }
                    .font(.headline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
                Spacer(minLength: 12)
            }
            .padding(24)
        }
    }

    private var title: String {
        if store.isPurchased { return "Drift Plus is unlocked" }
        if store.hasStartedTrial && store.trialDaysRemaining == 0 { return "Your preview ended" }
        if store.hasStartedTrial { return "Your Drift preview" }
        return "Find your quiet"
    }

    private var description: String {
        if store.trialDaysRemaining > 0 { return store.accessSummary }
        if store.hasStartedTrial { return "Your five free sounds are still here. Unlock Drift Plus for full-length tracks and guided sessions." }
        return "Choose a 7-day free preview or unlock Drift Plus with a one-time purchase. Your five free sounds stay available either way."
    }

    private var trialDisclosure: String {
        let price = store.plusProduct?.displayPrice ?? "price shown by the App Store"
        return "The free trial lasts 7 days. After it ends, the five free sounds remain available; the other 25 full tracks and guided sessions require a one-time Drift Plus purchase for \(price). There is no automatic charge when the trial ends."
    }

    private var unlockTitle: String {
        if store.isPurchasing { return "Processing…" }
        if let price = store.plusProduct?.displayPrice { return "Unlock Drift Plus · \(price) one-time" }
        return "Loading Drift Plus price…"
    }

}

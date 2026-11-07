import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Drift Plus")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    Text(store.paywallLead)
                        .foregroundStyle(Theme.muted)
                    Text(store.paywallOffer)
                        .foregroundStyle(Theme.text)
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
                    .disabled(store.isPurchasing)
                    Button("Restore purchase") {
                        Task { await store.restorePurchases() }
                    }
                    .buttonStyle(AmberButtonStyle(filled: false))
                    .disabled(store.isPurchasing)
                    Button("Keep the free sounds") { store.dismissPaywall() }
                        .font(.headline)
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(24)
            }
        }
    }

    private var unlockTitle: String {
        if store.isPurchasing { return "Unlocking…" }
        return "Unlock Drift Plus · \(store.plusPriceText)"
    }
}

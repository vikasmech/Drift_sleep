import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: DriftStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 12)
                Text("Preview ended")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text("Unlock Drift Plus to keep playing.")
                    .foregroundStyle(Theme.muted)
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
                Button("Not now") { store.dismissPaywall() }
                    .font(.headline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
                Spacer(minLength: 12)
            }
            .padding(24)
        }
    }

    private var unlockTitle: String {
        if store.isPurchasing { return "Unlocking…" }
        if let price = store.plusProduct?.displayPrice { return "Unlock Drift Plus · \(price)" }
        return "Unlock Drift Plus"
    }

}

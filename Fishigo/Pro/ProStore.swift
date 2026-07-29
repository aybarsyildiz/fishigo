import StoreKit
import Observation

/// StoreKit 2 entitlement + purchase (§2.1-11, now live per owner override of
/// the v1 stub). Source of truth for whether the user has Fishigo Pro. All
/// client-side Pro gating reads `isPro`; the recognition quota is raised
/// server-side when the client sends the Pro flag (see ProxyAPI / CLAUDE.md).
@MainActor
@Observable
final class ProStore {
    static let monthlyId = "com.netnucleus.fishigo.pro.monthly"
    static let annualId = "com.netnucleus.fishigo.pro.annual"
    static let productIds = [monthlyId, annualId]

    /// Legal links — hosted on the proxy so the paywall's Terms/Privacy links
    /// are functional (Apple Guideline 3.1.2).
    static let privacyURL = URL(string: "https://fishigo-tanima.toneamp.workers.dev/gizlilik")!
    static let termsURL = URL(string: "https://fishigo-tanima.toneamp.workers.dev/kosullar")!
    static let manageURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    private(set) var products: [Product] = []
    private(set) var purchasedProductIds: Set<String> = []
    /// Reviewer demo unlock (playbook §6) — grants Pro without a purchase while
    /// the proxy's demo flag is on. Never persisted.
    private var demoUnlocked = false

    var isPro: Bool { !purchasedProductIds.isEmpty || demoUnlocked }

    /// Mirror the entitlement to the flag the stateless recognizers read.
    private func syncEntitlement() { Entitlement.isPro = isPro }

    var monthly: Product? { products.first { $0.id == Self.monthlyId } }
    var annual: Product? { products.first { $0.id == Self.annualId } }

    private var updatesTask: Task<Void, Never>?

    init() {
        // Listen for transactions that arrive outside a purchase() call
        // (renewals, Ask-to-Buy approvals, purchases on other devices).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(verification: update)
            }
        }
        Task { await load() }
    }

    func load() async {
        products = (try? await Product.products(for: Self.productIds)) ?? []
        products.sort { ($0.price) < ($1.price) }
        await refreshEntitlements()
    }

    /// Current entitlements — the authoritative "is the sub active right now".
    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIds.contains(transaction.productID),
               transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIds = owned
        syncEntitlement()
    }

    enum PurchaseResult { case success, pending, cancelled, failed }

    func purchase(_ product: Product) async -> PurchaseResult {
        guard let outcome = try? await product.purchase() else { return .failed }
        switch outcome {
        case .success(let verification):
            await handle(verification: verification)
            return .success
        case .pending:
            return .pending // Ask-to-Buy / SCA — resolves later via Transaction.updates
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .failed
        }
    }

    /// §3.1.2 requires a Restore Purchases affordance.
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func handle(verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    // MARK: Reviewer demo (playbook §6)

    /// Unlocks Pro for the reviewer IF the proxy's demo flag is on. The owner
    /// flips DEMO_ACIK to "0" after approval to disable it in production.
    func tryDemoUnlock(code: String) async -> Bool {
        guard code == "LUFER2026" else { return false }
        guard let (data, _) = try? await URLSession.shared.data(
            from: ProxyConfig.baseURL.appending(path: "demo")),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              obj["enabled"] as? Bool == true else { return false }
        demoUnlocked = true
        syncEntitlement()
        return true
    }
}

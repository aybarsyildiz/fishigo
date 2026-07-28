import Foundation

/// §5 legality states. Lookup is 100% on-device and deterministic — the LLM
/// NEVER answers legality. Real regulations.json loader lands in M6; the UI
/// speaks this enum from M1 on so M6 is pure data plumbing.
enum LegalityStatus: Equatable {
    /// ✅ serbest
    case serbest
    /// ⚠️ boy limiti altı
    case boyAlti(minCm: Int)
    /// ⛔ dönem yasağı
    case donemYasagi
    /// Species missing from the table — shown neutrally, never alarming.
    case bilgiYok
}

protocol LegalityChecking {
    func check(speciesId: String, lengthCm: Int, date: Date) -> LegalityStatus
}

/// M1 stub. M6 replaces this with the bundled+remote regulations.json lookup.
/// Never put real limit values here — the owner populates the real table.
struct StubLegality: LegalityChecking {
    func check(speciesId: String, lengthCm: Int, date: Date) -> LegalityStatus {
        .bilgiYok
    }
}

enum LegalityCopy {
    /// §5: persistent disclaimer, always visible wherever a status is shown.
    static let disclaimer = "Bilgilendirme amaçlıdır; bağlayıcı kaynak Resmî Gazete/Bakanlık tebliğidir."
}

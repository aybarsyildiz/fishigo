import Foundation

/// One entry of species.json — the closed list the recognizer chooses from.
struct Species: Identifiable, Codable, Hashable {
    /// Canonical id (size-named variants like çinekop map to ONE id).
    let id: String
    let ad: String
    let latince: String
    let nadirlik: Rarity
    /// Rough body outline used for the deks engraving silhouette.
    let siluet: Siluet?
    /// Ordered size-name chain with cm thresholds; also the evolution line.
    /// `maxCm == nil` marks the open-ended top of the chain.
    let boyAdlari: [SizeName]
    /// Turkish seas the species is recorded in (GBIF/OBIS — reliable signal).
    let denizler: [Deniz]?
    /// Months with occurrence records (GBIF). OBSERVATION data, NOT fishing
    /// season — the binding season is the closed period in regulations.json.
    let gozlemAylari: [Int]?

    var siluetTipi: Siluet { siluet ?? .uzun }

    enum Siluet: String, Codable {
        case uzun, oval, yassi, yilansi, kafadan
    }

    enum Deniz: String, Codable, CaseIterable {
        case karadeniz, marmara, ege, akdeniz

        var ad: String {
            switch self {
            case .karadeniz: "Karadeniz"
            case .marmara: "Marmara"
            case .ege: "Ege"
            case .akdeniz: "Akdeniz"
            }
        }
    }

    /// §4 display-name rule: species + length → local size-name.
    func displayName(lengthCm: Int) -> String {
        for size in boyAdlari {
            if let max = size.maxCm, lengthCm <= max { return size.ad }
        }
        return boyAdlari.last?.ad ?? ad
    }

    /// True when the species has a real size-name chain (çinekop→…→kofana).
    var hasEvolutionLine: Bool { boyAdlari.count > 1 }
}

struct SizeName: Codable, Hashable {
    let ad: String
    let maxCm: Int?
}

/// §8 rarity tiers. Values are PLACEHOLDER until the owner tunes species.json.
enum Rarity: String, Codable {
    case yaygin = "yaygın"
    case azBulunur = "az bulunur"
    case epik = "epik"
    case efsanevi = "efsanevi"

    /// Brass accents appear from epik upward (card frames, deks sorting weight).
    var hasBrassAccent: Bool { self == .epik || self == .efsanevi }
}

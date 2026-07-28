import Foundation

/// The eight Turkish wind names — the language every angler on the shore
/// already speaks. Degrees are meteorological (direction the wind comes FROM).
enum RuzgarYonu: Int, CaseIterable {
    case yildiz     // N
    case poyraz     // NE
    case gundogusu  // E
    case kesisleme  // SE
    case kible      // S
    case lodos      // SW
    case gunbatisi  // W
    case karayel    // NW

    static func from(degrees: Double) -> RuzgarYonu {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let index = Int((positive / 45).rounded()) % 8
        return RuzgarYonu(rawValue: index) ?? .yildiz
    }

    var ad: String {
        switch self {
        case .yildiz: "Yıldız"
        case .poyraz: "Poyraz"
        case .gundogusu: "Gündoğusu"
        case .kesisleme: "Keşişleme"
        case .kible: "Kıble"
        case .lodos: "Lodos"
        case .gunbatisi: "Günbatısı"
        case .karayel: "Karayel"
        }
    }

    /// "En çok ___ tutuyorsun" — locative form.
    var lokatif: String {
        switch self {
        case .yildiz: "yıldızda"
        case .poyraz: "poyrazda"
        case .gundogusu: "gündoğusunda"
        case .kesisleme: "keşişlemede"
        case .kible: "kıblede"
        case .lodos: "lodosta"
        case .gunbatisi: "günbatısında"
        case .karayel: "karayelde"
        }
    }
}

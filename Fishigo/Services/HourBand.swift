import Foundation

/// Fishing-relevant hour bands — shared by stats and the condition score's
/// "senin saatin" bonus.
enum HourBand: Int, CaseIterable {
    case sabah, ogle, aksam, gece

    var label: String {
        switch self {
        case .sabah: "SABAH"
        case .ogle: "ÖĞLE"
        case .aksam: "AKŞAM"
        case .gece: "GECE"
        }
    }

    /// "En çok ___ tutuyorsun"
    var insightPhrase: String {
        switch self {
        case .sabah: "sabahları"
        case .ogle: "öğlen"
        case .aksam: "akşamları"
        case .gece: "geceleri"
        }
    }

    static func band(forHour hour: Int) -> HourBand {
        switch hour {
        case 5..<11: .sabah
        case 11..<17: .ogle
        case 17..<22: .aksam
        default: .gece
        }
    }

    /// The band with the most catches, when there's enough history to mean
    /// anything (≥3 records). Used by stats insight + condition bonus.
    static func topBand(dates: [Date], calendar: Calendar = .current) -> HourBand? {
        guard dates.count >= 3 else { return nil }
        let counts = Dictionary(grouping: dates) {
            band(forHour: calendar.component(.hour, from: $0))
        }
        return counts.max { $0.value.count < $1.value.count }?.key
    }
}

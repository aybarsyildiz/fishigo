import SwiftUI
import SwiftData
import Charts

/// Stats v1 (§2.1-8): catches by month and by hour-band, one insight line.
/// The wind-direction panel arrives with M7's weather snapshots.
struct StatsView: View {
    @Query private var records: [CatchRecord]

    var body: some View {
        if records.isEmpty {
            DefterEmptyState(caption: "İSTATİSTİKLER YAKALAYIŞLARINLA\nBİRLİKTE ORTAYA ÇIKAR")
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    if let insight {
                        Text(insight)
                            .font(Typo.display(20))
                            .foregroundStyle(Ink.kagit)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    StatPanel(title: "AYLARA GÖRE") {
                        Chart(monthBars) { bar in
                            BarMark(
                                x: .value("Ay", bar.label),
                                y: .value("Adet", bar.count))
                                .foregroundStyle(Ink.kagit.opacity(0.85))
                        }
                        .chartXScale(domain: monthBars.map(\.label))
                    }

                    StatPanel(title: "SAAT DİLİMİNE GÖRE") {
                        Chart(hourBars) { bar in
                            BarMark(
                                x: .value("Dilim", bar.label),
                                y: .value("Adet", bar.count))
                                .foregroundStyle(Ink.kagit.opacity(0.85))
                        }
                        .chartXScale(domain: hourBars.map(\.label))
                    }

                    StatPanel(title: "RÜZGÂRA GÖRE") {
                        Text("HAVA KAYDIYLA BİRLİKTE GELECEK — M7")
                            .font(Typo.data(10))
                            .kerning(1)
                            .foregroundStyle(Ink.kagit.opacity(0.4))
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: Data

    private struct CountBar: Identifiable {
        let id: Int
        let label: String
        let count: Int
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMM"
        return formatter
    }()

    /// Last six months, oldest first.
    private var monthBars: [CountBar] {
        let calendar = Calendar.current
        return (0..<6).reversed().enumerated().map { index, offset in
            let date = calendar.date(byAdding: .month, value: -offset, to: .now) ?? .now
            let target = calendar.dateComponents([.year, .month], from: date)
            let count = records.count {
                calendar.dateComponents([.year, .month], from: $0.date) == target
            }
            return CountBar(
                id: index,
                label: Self.monthFormatter.string(from: date).localizedUppercase,
                count: count)
        }
    }

    private enum HourBand: Int, CaseIterable {
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
    }

    private var hourBars: [CountBar] {
        let calendar = Calendar.current
        return HourBand.allCases.map { band in
            let count = records.count {
                HourBand.band(forHour: calendar.component(.hour, from: $0.date)) == band
            }
            return CountBar(id: band.rawValue, label: band.label, count: count)
        }
    }

    /// One insight line, phrased as observed habit — never a promise of fish.
    private var insight: String? {
        guard records.count >= 3 else { return nil }
        let calendar = Calendar.current
        let counts = Dictionary(grouping: records) {
            HourBand.band(forHour: calendar.component(.hour, from: $0.date))
        }
        guard let top = counts.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return "En çok \(top.key.insightPhrase) tutuyorsun"
    }
}

/// Framed chart panel in the archive language.
struct StatPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Typo.data(10, weight: .medium))
                .kerning(2)
                .foregroundStyle(Ink.kagit.opacity(0.5))
            content
                .frame(height: 130)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(Ink.cizgi.opacity(0.6))
                        AxisValueLabel()
                            .font(Typo.data(9))
                            .foregroundStyle(Ink.kagit.opacity(0.45))
                    }
                }
                .chartXAxis {
                    AxisMarks {
                        AxisValueLabel()
                            .font(Typo.data(9))
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                    }
                }
        }
        .padding(16)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }
}

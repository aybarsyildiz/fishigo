import SwiftUI
import SwiftData
import Charts

/// Stats v1 (§2.1-8): catches by month and by hour-band, one insight line.
/// The wind-direction panel arrives with M7's weather snapshots.
struct StatsView: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]

    @State private var showSezon = false
    @State private var showPaywall = false

    var body: some View {
        if records.isEmpty {
            DefterEmptyState(caption: "İSTATİSTİKLER YAKALAYIŞLARINLA\nBİRLİKTE ORTAYA ÇIKAR")
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    Button {
                        Feel.shared.buttonTap()
                        if app.pro.isPro { showSezon = true } else { showPaywall = true }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 15))
                            Text("BU AYIN SEZON KARTI")
                                .font(Typo.data(11, weight: .medium)).kerning(1.5)
                            if !app.pro.isPro {
                                Text("PRO").font(Typo.data(8, weight: .semibold)).kerning(1)
                                    .foregroundStyle(Ink.pirinc)
                            }
                            Spacer()
                            Image(systemName: app.pro.isPro ? "chevron.right" : "lock")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(Ink.kagit.opacity(0.75))
                        .padding(.horizontal, 16).padding(.vertical, 13)
                        .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 8)

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
                        if windBars.contains(where: { $0.count > 0 }) {
                            Chart(windBars) { bar in
                                BarMark(
                                    x: .value("Yön", bar.label),
                                    y: .value("Adet", bar.count))
                                    .foregroundStyle(Ink.kagit.opacity(0.85))
                            }
                            .chartXScale(domain: windBars.map(\.label))
                        } else {
                            Text("HAVA KAYITLI SEFER HENÜZ YOK —\nYENİ YAKALAYIŞLARLA DOLACAK")
                                .font(Typo.data(10))
                                .kerning(1)
                                .foregroundStyle(Ink.kagit.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        }
                    }
                }
                .padding(20)
            }
            .sheet(isPresented: $showSezon) { SezonSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
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

    private var windBars: [CountBar] {
        RuzgarYonu.allCases.map { yon in
            let count = records.count { record in
                record.windDirectionDeg.map { RuzgarYonu.from(degrees: $0) } == yon
            }
            return CountBar(id: 100 + yon.rawValue, label: yon.ad.localizedUppercase, count: count)
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
    /// Prefers the wind habit once weather-tagged records exist (the brief's
    /// own example: "En çok lodosta tutuyorsun").
    private var insight: String? {
        let winds = records.compactMap(\.windDirectionDeg).map { RuzgarYonu.from(degrees: $0) }
        if winds.count >= 3,
           let top = Dictionary(grouping: winds, by: { $0 })
               .max(by: { $0.value.count < $1.value.count })?.key {
            return "En çok \(top.lokatif) tutuyorsun"
        }
        guard let top = HourBand.topBand(dates: records.map(\.date)) else { return nil }
        return "En çok \(top.insightPhrase) tutuyorsun"
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

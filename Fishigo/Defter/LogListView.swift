import SwiftUI
import SwiftData

/// Catch records, newest first, filterable by species and month (§2.1-7).
struct LogListView: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    @State private var speciesFilter: String?
    @State private var monthFilter: Int?
    @State private var shareRecord: CatchRecord?

    private var filtered: [CatchRecord] {
        records.filter { record in
            (speciesFilter == nil || record.speciesId == speciesFilter)
                && (monthFilter == nil || Calendar.current.component(.month, from: record.date) == monthFilter)
        }
    }

    var body: some View {
        if records.isEmpty {
            DefterEmptyState(caption: "İLK YAKALAYIŞINLA BİRLİKTE\nBURASI DOLMAYA BAŞLAR")
        } else {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                if filtered.isEmpty {
                    DefterEmptyState(caption: "BU FİLTREYE UYAN KAYIT YOK")
                } else {
                    List(filtered) { record in
                        LogRow(record: record)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Feel.shared.cardLift()
                                shareRecord = record
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Ink.cizgi.opacity(0.5))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .sheet(item: $shareRecord) { record in
                SharePreviewSheet(record: record)
            }
        }
    }

    // MARK: Filters

    private var caughtSpecies: [Species] {
        let ids = Set(records.map(\.speciesId))
        return app.species.all.filter { ids.contains($0.id) }
    }

    private var monthsPresent: [Int] {
        Array(Set(records.map { Calendar.current.component(.month, from: $0.date) })).sorted()
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            Menu {
                Button("Tümü") { speciesFilter = nil }
                ForEach(caughtSpecies) { species in
                    Button(species.ad) { speciesFilter = species.id }
                }
            } label: {
                FilterChip(
                    label: speciesFilter.flatMap { app.species.species(id: $0)?.ad } ?? "TÜR",
                    active: speciesFilter != nil)
            }

            Menu {
                Button("Tümü") { monthFilter = nil }
                ForEach(monthsPresent, id: \.self) { month in
                    Button(Self.monthName(month)) { monthFilter = month }
                }
            } label: {
                FilterChip(
                    label: monthFilter.map(Self.monthName) ?? "AY",
                    active: monthFilter != nil)
            }

            Spacer()

            Text("\(filtered.count) KAYIT")
                .font(Typo.data(10))
                .kerning(1)
                .foregroundStyle(Ink.kagit.opacity(0.4))
        }
    }

    static func monthName(_ month: Int) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "tr_TR")
        return calendar.standaloneMonthSymbols[month - 1].localizedCapitalized
    }
}

struct FilterChip: View {
    let label: String
    let active: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(label.localizedUppercase)
                .font(Typo.data(11, weight: active ? .medium : .regular))
                .kerning(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
        }
        .foregroundStyle(active ? Ink.murekkepKoyu : Ink.kagit.opacity(0.7))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            active ? Ink.kagit : Ink.murekkep,
            in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Ink.cizgi.opacity(active ? 0 : 0.7), lineWidth: 0.5))
    }
}

struct LogRow: View {
    @Environment(AppModel.self) private var app
    let record: CatchRecord

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM y · HH:mm"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let data = record.photoJPEG, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Ink.murekkep
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Ink.cizgi, lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(Typo.display(17))
                        .foregroundStyle(Ink.kagit)
                    if record.isFirstOfSpecies {
                        Text("İLK")
                            .font(Typo.data(8, weight: .semibold))
                            .kerning(1)
                            .foregroundStyle(Ink.muhur)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .overlay(Rectangle().strokeBorder(Ink.muhur, lineWidth: 1))
                            .rotationEffect(.degrees(-4))
                    } else if record.isPersonalRecord {
                        Text("REKOR")
                            .font(Typo.data(8, weight: .semibold))
                            .kerning(1)
                            .foregroundStyle(Ink.pirinc)
                    }
                }
                Text(statsLine)
                    .font(Typo.data(11))
                    .foregroundStyle(Ink.kagit.opacity(0.55))
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var displayName: String {
        app.species.species(id: record.speciesId)?.displayName(lengthCm: record.lengthCm) ?? record.speciesId
    }

    private var statsLine: String {
        var parts = ["\(record.lengthCm) CM", Self.dateFormatter.string(from: record.date).localizedUppercase]
        if record.released { parts.append("SALINDI") }
        return parts.joined(separator: " · ")
    }
}

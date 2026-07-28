import SwiftUI
import SwiftData

/// "Bugün ne tutulur" — region + season species suggestions, built from data
/// we already have: GBIF sea presence, the M6 closed-season regulations, and
/// the user's most recent located catch. NOT a fish promise — it lists what is
/// *in season and recorded in your sea*, phrased as guidance.
struct BugunModel {
    struct Oneri: Identifiable {
        let species: Species
        let inClosedSeason: Bool
        var id: String { species.id }
    }

    let deniz: Species.Deniz?
    let oneriler: [Oneri]

    @MainActor
    static func build(records: [CatchRecord], app: AppModel, now: Date = .now) -> BugunModel {
        let located = records.sorted { $0.date > $1.date }.first { $0.coordinate != nil }
        let deniz = located?.coordinate.flatMap(SeaLocator.sea(for:))

        let month = Calendar.current.component(.month, from: now)
        let day = Calendar.current.component(.day, from: now)

        let matches = app.species.all.compactMap { species -> Oneri? in
            guard let denizler = species.denizler, !denizler.isEmpty else { return nil }
            // If we know the user's sea, require presence there; otherwise show
            // anything with sea data.
            if let deniz, !denizler.contains(deniz) { return nil }

            let kural = app.regulations.kural(for: species.id)
            let kapali = kural?.yasak?.contains { $0.contains(month: month, day: day) } ?? false
            return Oneri(species: species, inClosedSeason: kapali)
        }

        // Open-season first, then by rarity (rarer feels more rewarding to seek).
        let order: [Rarity] = [.efsanevi, .epik, .azBulunur, .yaygin]
        let sorted = matches.sorted { a, b in
            if a.inClosedSeason != b.inClosedSeason { return !a.inClosedSeason }
            let ra = order.firstIndex(of: a.species.nadirlik) ?? 3
            let rb = order.firstIndex(of: b.species.nadirlik) ?? 3
            return ra < rb
        }
        return BugunModel(deniz: deniz, oneriler: sorted)
    }
}

/// Full list, opened from the hook module.
struct BugunSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    var body: some View {
        let model = BugunModel.build(records: records, app: app)
        let acik = model.oneriler.filter { !$0.inClosedSeason }
        let kapali = model.oneriler.filter { $0.inClosedSeason }

        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("BUGÜN NE TUTULUR")
                                .font(Typo.data(11, weight: .medium))
                                .kerning(2)
                                .foregroundStyle(Ink.kagit.opacity(0.5))
                            Text(model.deniz.map { "\($0.ad.localizedUppercase) · SON KONUMUNA GÖRE" } ?? "BÖLGEN İÇİN KONUMLU KAYIT GEREK")
                                .font(Typo.data(9))
                                .kerning(1)
                                .foregroundStyle(Ink.kagit.opacity(0.4))
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Ink.kagit.opacity(0.6))
                                .padding(8)
                        }
                    }
                    .padding(.top, 16)

                    if model.oneriler.isEmpty {
                        Text("BU BÖLGE İÇİN VERİ YOK")
                            .font(Typo.data(11)).kerning(1)
                            .foregroundStyle(Ink.kagit.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                    }

                    ForEach(acik) { oneri in
                        OneriRow(species: oneri.species, closed: false)
                    }

                    if !kapali.isEmpty {
                        Text("ŞU AN DÖNEM YASAĞINDA")
                            .font(Typo.data(9, weight: .medium)).kerning(1.5)
                            .foregroundStyle(Ink.muhur.opacity(0.8))
                            .padding(.top, 8)
                        ForEach(kapali) { oneri in
                            OneriRow(species: oneri.species, closed: true)
                        }
                    }

                    Text("Bölge & mevsim bilgisi yol göstericidir, balık sözü değildir. Bağlayıcı sezon Bakanlık tebliğidir.")
                        .font(Typo.data(9))
                        .foregroundStyle(Ink.kagit.opacity(0.35))
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .presentationBackground(Ink.murekkepKoyu)
    }
}

private struct OneriRow: View {
    let species: Species
    let closed: Bool

    var body: some View {
        HStack(spacing: 12) {
            SilhouetteView(tip: species.siluetTipi, caught: !closed)
                .frame(width: 46, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(species.ad)
                    .font(Typo.data(14, weight: .medium))
                    .foregroundStyle(closed ? Ink.kagit.opacity(0.5) : Ink.kagit)
                Text(species.latince)
                    .font(Typo.latin(11))
                    .foregroundStyle(Ink.kagit.opacity(0.45))
            }
            Spacer()
            if closed {
                Text("YASAK")
                    .font(Typo.data(8, weight: .semibold)).kerning(1)
                    .foregroundStyle(Ink.muhur)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .overlay(Rectangle().strokeBorder(Ink.muhur, lineWidth: 1))
            } else if species.nadirlik.hasBrassAccent {
                Text(species.nadirlik.rawValue.localizedUppercase)
                    .font(Typo.data(8, weight: .medium)).kerning(1)
                    .foregroundStyle(Ink.pirinc)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(Ink.cizgi.opacity(0.4)).frame(height: 0.5) }
    }
}

/// Hook-page module (wide, under koşullar — they pair naturally).
struct BugunModule: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    @State private var show = false

    var body: some View {
        let model = BugunModel.build(records: records, app: app)
        let acik = model.oneriler.filter { !$0.inClosedSeason }.prefix(3)

        Button {
            Feel.shared.buttonTap()
            show = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BUGÜN NE TUTULUR")
                        .font(Typo.data(9, weight: .medium)).kerning(1.5)
                        .foregroundStyle(Ink.kagit.opacity(0.45))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                }
                if acik.isEmpty {
                    Text("BÖLGEN İÇİN KONUMLU KAYIT GEREK")
                        .font(Typo.data(10)).kerning(0.5)
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                } else {
                    Text(acik.map(\.species.ad).joined(separator: " · "))
                        .font(Typo.data(14, weight: .medium))
                        .foregroundStyle(Ink.kagit)
                        .lineLimit(1)
                    Text(model.deniz.map { "\($0.ad.localizedUppercase) · SEZONDA" } ?? "SEZONDA")
                        .font(Typo.data(8)).kerning(1)
                        .foregroundStyle(Ink.kagit.opacity(0.45))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
        .sheet(isPresented: $show) { BugunSheet() }
    }
}

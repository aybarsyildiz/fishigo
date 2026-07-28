import SwiftUI

/// Monthly recap — a shareable "sezon kartı" (Spotify-Wrapped energy, single
/// player). Reuses the M4 chart-paper card language and the 9:16 export path.
struct SezonOzeti {
    let ay: Date
    let toplam: Int
    let yeniTur: Int
    let enBuyuk: (ad: String, boy: Int)?
    let enCokRuzgar: RuzgarYonu?
    let deksToplam: Int
    let deksGenel: Int

    @MainActor
    static func build(month: Date, app: AppModel) -> SezonOzeti {
        let calendar = Calendar.current
        let target = calendar.dateComponents([.year, .month], from: month)
        let all = app.log.records
        let inMonth = all.filter { calendar.dateComponents([.year, .month], from: $0.date) == target }

        // New species = first-ever caught within this month.
        let firstDatePerSpecies = Dictionary(all.map { ($0.speciesId, $0.date) }, uniquingKeysWith: min)
        let yeni = firstDatePerSpecies.filter { calendar.dateComponents([.year, .month], from: $0.value) == target }.count

        let biggest = inMonth.filter { $0.lengthCm > 0 }.max { $0.lengthCm < $1.lengthCm }
        let enBuyuk = biggest.map {
            (ad: app.species.species(id: $0.speciesId)?.displayName(lengthCm: $0.lengthCm) ?? $0.speciesId,
             boy: $0.lengthCm)
        }

        let winds = inMonth.compactMap(\.windDirectionDeg).map { RuzgarYonu.from(degrees: $0) }
        let topWind = Dictionary(grouping: winds, by: { $0 }).max { $0.value.count < $1.value.count }?.key

        return SezonOzeti(
            ay: month,
            toplam: inMonth.count,
            yeniTur: yeni,
            enBuyuk: enBuyuk,
            enCokRuzgar: topWind,
            deksToplam: DeksProgress.caughtIds(all).count,
            deksGenel: app.species.all.count)
    }
}

/// 360×640 recap card — same design grammar as the specimen share card.
struct SezonCardView: View {
    let ozeti: SezonOzeti

    private static let ayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            Ink.kagit
            ChartFragment(ink: Ink.murekkep).opacity(0.14)

            VStack(spacing: 0) {
                Text("SEFER ÖZETİ")
                    .font(Typo.data(9, weight: .medium)).kerning(3)
                    .foregroundStyle(Ink.murekkep.opacity(0.5))
                    .padding(.top, 34)
                Text(Self.ayFormatter.string(from: ozeti.ay).localizedUppercase)
                    .font(Typo.display(30))
                    .foregroundStyle(Ink.murekkep)
                    .padding(.top, 6)

                VStack(spacing: 0) {
                    bigStat("\(ozeti.toplam)", "YAKALAYIŞ")
                    rule
                    HStack(spacing: 0) {
                        smallStat("\(ozeti.yeniTur)", "YENİ TÜR")
                        vrule
                        smallStat("\(ozeti.deksToplam)/\(ozeti.deksGenel)", "BALIKDEKS")
                    }
                    if let big = ozeti.enBuyuk {
                        rule
                        smallStat("\(big.boy) CM", "EN BÜYÜK · \(big.ad.localizedUppercase)")
                    }
                    if let wind = ozeti.enCokRuzgar {
                        rule
                        smallStat(wind.ad.localizedUppercase, "EN ÇOK RÜZGÂR")
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .background(Ink.kagit)
                .overlay(DoubleRuleFrame(color: Ink.murekkep.opacity(0.75)))
                .padding(.horizontal, 30)
                .padding(.top, 24)

                Spacer(minLength: 0)

                HStack {
                    Text("NOKTAN SENDE KALIR")
                        .font(Typo.data(8)).kerning(1.5)
                        .foregroundStyle(Ink.murekkep.opacity(0.5))
                    Spacer()
                    Text("FISHIGO")
                        .font(Typo.data(10, weight: .semibold)).kerning(3)
                        .foregroundStyle(Ink.kagit)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Ink.murekkep)
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 34)
            }
        }
        .frame(width: 360, height: 640)
        .overlay(DoubleRuleFrame(color: Ink.murekkep.opacity(0.8)).padding(14))
    }

    private var rule: some View { Rectangle().fill(Ink.murekkep.opacity(0.2)).frame(height: 1).padding(.vertical, 12) }
    private var vrule: some View { Rectangle().fill(Ink.murekkep.opacity(0.2)).frame(width: 1, height: 34) }

    private func bigStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Typo.data(46, weight: .semibold)).foregroundStyle(Ink.murekkep).monospacedDigit()
            Text(label).font(Typo.data(10, weight: .medium)).kerning(2).foregroundStyle(Ink.murekkep.opacity(0.55))
        }
    }

    private func smallStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Typo.data(18, weight: .medium)).foregroundStyle(Ink.murekkep).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(Typo.data(8)).kerning(1).foregroundStyle(Ink.murekkep.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
enum SezonRenderer {
    static func image(_ ozeti: SezonOzeti) -> UIImage? {
        let renderer = ImageRenderer(content: SezonCardView(ozeti: ozeti))
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

/// Preview + share, opened from the Defter stats section.
struct SezonSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var rendered: UIImage?

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Text("SEZON KARTI")
                        .font(Typo.data(11, weight: .medium)).kerning(2)
                        .foregroundStyle(Ink.kagit.opacity(0.5))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Ink.kagit.opacity(0.6)).padding(8)
                    }
                }
                .padding(.top, 16)

                if let rendered {
                    Image(uiImage: rendered)
                        .resizable().scaledToFit()
                        .overlay(Rectangle().strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
                    ShareLink(
                        item: Image(uiImage: rendered),
                        preview: SharePreview("Sezon Kartı", image: Image(uiImage: rendered))
                    ) {
                        ArchiveButtonLabel(title: "Paylaş", systemImage: "square.and.arrow.up")
                    }
                    .simultaneousGesture(TapGesture().onEnded { Feel.shared.buttonTap() })
                    .frame(maxWidth: 260)
                } else {
                    Spacer()
                    Text("KART BASILIYOR…")
                        .font(Typo.data(11)).kerning(2)
                        .foregroundStyle(Ink.kagit.opacity(0.4))
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .task {
            rendered = SezonRenderer.image(SezonOzeti.build(month: .now, app: app))
        }
    }
}

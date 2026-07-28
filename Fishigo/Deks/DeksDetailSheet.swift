import SwiftUI
import SwiftData

/// One species, opened from the grid: photo (if caught) or silhouette, rarity,
/// the evolution line with band states, and personal stats.
struct DeksDetailSheet: View {
    @Environment(AppModel.self) private var app
    @Query private var records: [CatchRecord]

    let species: Species

    private var own: [CatchRecord] {
        records.filter { $0.speciesId == species.id }
    }

    private var caught: Bool { !own.isEmpty }

    private var bestPhoto: UIImage? {
        let best = own.max { $0.lengthCm < $1.lengthCm }
        return best?.photoJPEG.flatMap(UIImage.init(data:))
    }

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    // Plate
                    Group {
                        if let photo = bestPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 190)
                                .clipped()
                        } else {
                            SilhouetteView(tip: species.siluetTipi, caught: false)
                                .frame(height: 110)
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .background(Ink.murekkep)
                    .overlay(DoubleRuleFrame(color: caught && species.nadirlik.hasBrassAccent ? Ink.pirinc : Ink.cizgi))

                    VStack(spacing: 4) {
                        Text(species.ad)
                            .font(Typo.display(30))
                            .foregroundStyle(Ink.kagit)
                        Text(species.latince)
                            .font(Typo.latin(15))
                            .foregroundStyle(Ink.kagit.opacity(0.6))
                        Text(species.nadirlik.rawValue.localizedUppercase)
                            .font(Typo.data(10, weight: .medium))
                            .kerning(2)
                            .foregroundStyle(species.nadirlik.hasBrassAccent ? Ink.pirinc : Ink.kagit.opacity(0.45))
                            .padding(.top, 6)
                    }

                    if species.denizler?.isEmpty == false || species.gozlemAylari?.isEmpty == false {
                        RegionPanel(species: species)
                    }

                    if species.hasEvolutionLine {
                        EvolutionLineView(
                            species: species,
                            bandsCaught: DeksProgress.bandsCaught(species, records: records))
                    }

                    Group {
                        if caught {
                            Text("\(own.count) ADET · REKOR \(own.map(\.lengthCm).max() ?? 0) CM")
                        } else {
                            Text("HENÜZ YAKALANMADI")
                        }
                    }
                    .font(Typo.data(11))
                    .kerning(1.5)
                    .foregroundStyle(Ink.kagit.opacity(0.5))
                    .monospacedDigit()
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Ink.murekkepKoyu)
    }
}

/// The size-name chain (§8): each band solid once a catch landed in it,
/// dotted until then. Completing the whole chain is a ceremony moment.
struct EvolutionLineView: View {
    let species: Species
    let bandsCaught: Set<Int>

    var body: some View {
        VStack(spacing: 10) {
            Text("BOY SERİSİ")
                .font(Typo.data(9, weight: .medium))
                .kerning(2)
                .foregroundStyle(Ink.kagit.opacity(0.4))

            HStack(spacing: 6) {
                ForEach(Array(species.boyAdlari.enumerated()), id: \.offset) { index, band in
                    if index > 0 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Ink.kagit.opacity(0.35))
                    }
                    bandChip(band, achieved: bandsCaught.contains(index))
                }
            }

            if bandsCaught.count == species.boyAdlari.count {
                Text("SERİ TAMAM")
                    .font(Typo.data(9, weight: .semibold))
                    .kerning(2)
                    .foregroundStyle(Ink.pirinc)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }

    private func bandChip(_ band: SizeName, achieved: Bool) -> some View {
        VStack(spacing: 3) {
            Text(band.ad.localizedUppercase)
                .font(Typo.data(8, weight: achieved ? .semibold : .regular))
                .kerning(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(band.maxCm.map { "≤\($0)" } ?? "+")
                .font(Typo.data(7))
                .opacity(0.7)
        }
        .foregroundStyle(achieved ? Ink.murekkepKoyu : Ink.kagit.opacity(0.45))
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(achieved ? Ink.kagit : .clear)
        .overlay(
            Rectangle().strokeBorder(
                achieved ? Ink.kagit : Ink.cizgi,
                style: achieved
                    ? StrokeStyle(lineWidth: 1)
                    : StrokeStyle(lineWidth: 1, dash: [1, 2.5])))
    }
}

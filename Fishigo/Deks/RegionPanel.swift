import SwiftUI

/// §Balıkdeks region panel — GBIF/OBIS-backed presence. Sea presence is the
/// reliable headline; the observation-month strip is labelled strictly as
/// scientific records, never a fishing season (that stays with legality).
struct RegionPanel: View {
    let species: Species

    private static let ayHarfleri = ["O", "Ş", "M", "N", "M", "H", "T", "A", "E", "E", "K", "A"]

    var body: some View {
        VStack(spacing: 12) {
            Text("BÖLGE & KAYIT")
                .font(Typo.data(9, weight: .medium))
                .kerning(2)
                .foregroundStyle(Ink.kagit.opacity(0.45))

            // Four seas — a lit chip means recorded there.
            HStack(spacing: 6) {
                ForEach(Species.Deniz.allCases, id: \.self) { deniz in
                    let present = species.denizler?.contains(deniz) ?? false
                    Text(deniz.ad.localizedUppercase)
                        .font(Typo.data(9, weight: present ? .semibold : .regular))
                        .kerning(0.5)
                        .foregroundStyle(present ? Ink.murekkepKoyu : Ink.kagit.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(present ? Ink.kagit : .clear)
                        .overlay(
                            Rectangle().strokeBorder(
                                present ? Ink.kagit : Ink.cizgi,
                                style: present ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 1, dash: [1, 2.5])))
                }
            }

            if let aylar = species.gozlemAylari, !aylar.isEmpty {
                VStack(spacing: 6) {
                    HStack(spacing: 3) {
                        ForEach(1...12, id: \.self) { ay in
                            let seen = aylar.contains(ay)
                            Text(Self.ayHarfleri[ay - 1])
                                .font(Typo.data(8, weight: seen ? .semibold : .regular))
                                .foregroundStyle(seen ? Ink.kagit : Ink.kagit.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(seen ? Ink.cizgi : .clear)
                        }
                    }
                    Text("GÖZLEM KAYITLARI (GBIF) — AV SEZONU DEĞİL")
                        .font(Typo.data(7))
                        .kerning(1)
                        .foregroundStyle(Ink.kagit.opacity(0.35))
                }
            }

            Text("Kaynak: GBIF & OBIS açık veri. Bölge bilgisi yol göstericidir.")
                .font(Typo.data(8))
                .foregroundStyle(Ink.kagit.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }
}

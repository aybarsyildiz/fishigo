import SwiftUI
import SwiftData

/// Hook-shelf module: the day's condition score for the user's region.
/// Full-width — the phrase and factors deserve room. Tap for the breakdown.
struct KosullarModule: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    @State private var showSheet = false

    var body: some View {
        Button {
            Feel.shared.buttonTap()
            showSheet = true
        } label: {
            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Ink.murekkep, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Ink.cizgi.opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(PressableStyle())
        .task {
            await app.conditions.refreshIfStale(records: records)
        }
        .sheet(isPresented: $showSheet) {
            KosullarSheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch app.conditions.durum {
        case .bekliyor(let mesaj):
            VStack(alignment: .leading, spacing: 6) {
                baslik
                Text(mesaj)
                    .font(Typo.data(10))
                    .kerning(0.5)
                    .foregroundStyle(Ink.kagit.opacity(0.4))
            }
        case .yukleniyor:
            VStack(alignment: .leading, spacing: 6) {
                baslik
                Text("HAVA OKUNUYOR…")
                    .font(Typo.data(10))
                    .kerning(1)
                    .foregroundStyle(Ink.kagit.opacity(0.4))
            }
        case .hazir(let rapor):
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    baslik
                    Text(rapor.ifade)
                        .font(Typo.display(20))
                        .foregroundStyle(Ink.kagit)
                    Text(altSatir(rapor))
                        .font(Typo.data(9))
                        .kerning(1)
                        .foregroundStyle(Ink.kagit.opacity(0.5))
                        .lineLimit(1)
                }
                Spacer()
                Text("\(rapor.puan)")
                    .font(Typo.data(30, weight: .medium))
                    .foregroundStyle(Ink.kagit)
                    .monospacedDigit()
            }
        }
    }

    private var baslik: some View {
        Text("KOŞULLAR")
            .font(Typo.data(9, weight: .medium))
            .kerning(1.5)
            .foregroundStyle(Ink.kagit.opacity(0.45))
    }

    private func altSatir(_ rapor: KosulRaporu) -> String {
        var parts: [String] = []
        if let il = rapor.il { parts.append(il.localizedUppercase) }
        if let ruzgar = rapor.faktorler.first(where: { $0.ad == "RÜZGÂR" }) {
            parts.append(ruzgar.deger)
        }
        return parts.joined(separator: " · ")
    }
}

/// The full breakdown: every factor with its weight, today's solunar windows,
/// the daily-notice toggle, and the non-negotiable disclaimers.
struct KosullarSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CatchRecord.date, order: .reverse) private var records: [CatchRecord]

    @AppStorage("kosulBildirimi") private var bildirim = false
    @AppStorage("sesAcik") private var sesAcik = true

    private static let saatFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        ZStack {
            Ink.murekkepKoyu.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Text("GÜNÜN KOŞULLARI")
                            .font(Typo.data(11, weight: .medium))
                            .kerning(2)
                            .foregroundStyle(Ink.kagit.opacity(0.5))
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Ink.kagit.opacity(0.6))
                                .padding(8)
                        }
                    }
                    .padding(.top, 16)

                    if case .hazir(let rapor) = app.conditions.durum {
                        raporGovdesi(rapor)
                    } else {
                        Text("KOŞUL RAPORU İÇİN KONUMLU BİR KAYIT GEREK —\nİLK YAKALAYIŞTA KENDİLİĞİNDEN GELİR")
                            .font(Typo.data(11))
                            .kerning(1)
                            .foregroundStyle(Ink.kagit.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 60)
                    }

                    // §9: notifications only after the first completed catch.
                    if app.log.count > 0 {
                        bildirimBolumu
                    }

                    sesBolumu

                    VStack(spacing: 4) {
                        Text("KOŞUL PUANI BALIK SÖZÜ DEĞİLDİR — SADECE ŞARTLARI ÖZETLER.")
                        Text("SOLUNAR YAKLAŞIK HESAPTIR (±30 DK).")
                    }
                    .font(Typo.data(9))
                    .kerning(0.5)
                    .foregroundStyle(Ink.kagit.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 22)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Ink.murekkepKoyu)
        .task {
            await app.conditions.refreshIfStale(records: records)
        }
    }

    @ViewBuilder
    private func raporGovdesi(_ rapor: KosulRaporu) -> some View {
        VStack(spacing: 10) {
            Text("\(rapor.puan)")
                .font(Typo.data(52, weight: .medium))
                .foregroundStyle(Ink.kagit)
                .monospacedDigit()
            Text(rapor.ifade)
                .font(Typo.display(26))
                .foregroundStyle(Ink.kagit)
            if let il = rapor.il {
                Text("BÖLGE: \(il.localizedUppercase) — SON KONUMLU KAYDINA GÖRE")
                    .font(Typo.data(9))
                    .kerning(1)
                    .foregroundStyle(Ink.kagit.opacity(0.4))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())

        VStack(spacing: 0) {
            ForEach(rapor.faktorler) { faktor in
                HStack {
                    Text(faktor.ad)
                        .font(Typo.data(11, weight: .medium))
                        .kerning(1)
                    Spacer()
                    Text(faktor.deger)
                        .font(Typo.data(11))
                        .foregroundStyle(Ink.kagit.opacity(0.65))
                    Text(faktor.etkiMetni)
                        .font(Typo.data(11, weight: .medium))
                        .foregroundStyle(faktor.etki > 0 ? Ink.pirinc : (faktor.etki < 0 ? Ink.muhur : Ink.kagit.opacity(0.4)))
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
                .foregroundStyle(Ink.kagit)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                if faktor.id != rapor.faktorler.last?.id {
                    Rectangle().fill(Ink.cizgi.opacity(0.5)).frame(height: 0.5)
                }
            }
        }
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())

        VStack(spacing: 8) {
            Text("BUGÜNÜN SOLUNAR PENCERELERİ")
                .font(Typo.data(9, weight: .medium))
                .kerning(1.5)
                .foregroundStyle(Ink.kagit.opacity(0.45))
            ForEach(Array(rapor.majorlar.enumerated()), id: \.offset) { _, pencere in
                pencereSatiri("MAJÖR", pencere)
            }
            ForEach(Array(rapor.minorlar.enumerated()), id: \.offset) { _, pencere in
                pencereSatiri("MİNÖR", pencere)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }

    private func pencereSatiri(_ tip: String, _ pencere: DateInterval) -> some View {
        HStack {
            Text(tip)
                .font(Typo.data(10, weight: tip == "MAJÖR" ? .semibold : .regular))
                .kerning(1)
                .foregroundStyle(tip == "MAJÖR" ? Ink.pirinc : Ink.kagit.opacity(0.6))
            Spacer()
            Text("\(Self.saatFormatter.string(from: pencere.start)) – \(Self.saatFormatter.string(from: pencere.end))")
                .font(Typo.data(11))
                .foregroundStyle(Ink.kagit.opacity(0.75))
                .monospacedDigit()
        }
    }

    private var bildirimBolumu: some View {
        VStack(spacing: 8) {
            Toggle(isOn: $bildirim) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Günlük koşul bildirimi")
                        .font(Typo.data(13))
                        .foregroundStyle(Ink.kagit)
                    Text("HER SABAH 07:30 · GÜNDE EN FAZLA 1")
                        .font(Typo.data(8))
                        .kerning(1)
                        .foregroundStyle(Ink.kagit.opacity(0.45))
                }
            }
            .tint(Ink.cizgi)
            .onChange(of: bildirim) {
                Feel.shared.buttonTap()
                if bildirim {
                    Task {
                        if await DailyNotice.enable() == false {
                            bildirim = false
                        }
                    }
                } else {
                    DailyNotice.disable()
                }
            }
        }
        .padding(14)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }

    /// §7: all sounds optional. The silent switch is the hardware control; this
    /// is the in-app one. (Onboarding/settings screen can host it too in M8.)
    private var sesBolumu: some View {
        Toggle(isOn: $sesAcik) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Sesler")
                    .font(Typo.data(13))
                    .foregroundStyle(Ink.kagit)
                Text("MAKARA TIKLARI · DAMGA · YENİ TÜR")
                    .font(Typo.data(8))
                    .kerning(1)
                    .foregroundStyle(Ink.kagit.opacity(0.45))
            }
        }
        .tint(Ink.cizgi)
        .onChange(of: sesAcik) { Feel.shared.buttonTap() }
        .padding(14)
        .background(Ink.murekkep)
        .overlay(DoubleRuleFrame())
    }
}

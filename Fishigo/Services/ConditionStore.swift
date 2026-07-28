import Foundation
import CoreLocation
import Observation

struct KosulFaktoru: Identifiable {
    let ad: String
    let deger: String
    let etki: Int

    var id: String { ad }

    var etkiMetni: String {
        etki > 0 ? "+\(etki)" : (etki < 0 ? "\(etki)" : "±0")
    }
}

/// §2.1-10 condition report. Phrased as conditions — NEVER a fish promise.
struct KosulRaporu {
    let puan: Int
    let ifade: String
    let il: String?
    let faktorler: [KosulFaktoru]
    let majorlar: [DateInterval]
    let minorlar: [DateInterval]
    let zaman: Date
}

/// Computes the condition score for the user's region (v1: the most recent
/// located catch — flagged simplification; saved regions can come later).
/// Weights are PLACEHOLDER v1 values, tuned by feel not by data.
@MainActor
@Observable
final class ConditionStore {
    enum Durum {
        case bekliyor(String)
        case yukleniyor
        case hazir(KosulRaporu)
    }

    private(set) var durum: Durum = .bekliyor("KOŞUL PUANI İÇİN KONUMLU BİR KAYIT GEREK")
    private var sonYenileme: Date?

    /// Views call this freely; real fetches happen at most every 15 min.
    func refreshIfStale(records: [CatchRecord]) async {
        if case .hazir = durum, let son = sonYenileme, Date.now.timeIntervalSince(son) < 900 {
            return
        }
        await refresh(records: records)
    }

    func refresh(records: [CatchRecord]) async {
        let sorted = records.sorted { $0.date > $1.date }
        guard let bolgeKaydi = sorted.first(where: { $0.coordinate != nil }),
              let coordinate = bolgeKaydi.coordinate else {
            durum = .bekliyor("KOŞUL PUANI İÇİN KONUMLU BİR KAYIT GEREK")
            return
        }
        durum = .yukleniyor

        async let havaTask = WeatherService.current(coordinate)
        async let denizTask = WeatherService.marine(coordinate)
        guard let hava = await havaTask else {
            durum = .bekliyor("HAVA SERVİSİNE ULAŞILAMADI — SONRA TEKRAR DENE")
            return
        }
        let deniz = await denizTask

        durum = .hazir(hesapla(
            hava: hava,
            deniz: deniz,
            coordinate: coordinate,
            il: bolgeKaydi.il,
            catchDates: records.map(\.date),
            now: .now))
        sonYenileme = .now
    }

    // MARK: Scoring — v1 placeholder weights

    private func hesapla(
        hava: HavaDurumu,
        deniz: DenizDurumu,
        coordinate: CLLocationCoordinate2D,
        il: String?,
        catchDates: [Date],
        now: Date
    ) -> KosulRaporu {
        let dalgaM = deniz.dalgaM
        var faktorler: [KosulFaktoru] = []
        var puan = 50

        // Wind
        let yon = RuzgarYonu.from(degrees: hava.ruzgarYonuDeg)
        let ruzgarEtki: Int
        switch hava.ruzgarKmh {
        case ..<10: ruzgarEtki = 15
        case ..<25: ruzgarEtki = 5
        case ..<40: ruzgarEtki = -10
        default: ruzgarEtki = -25
        }
        faktorler.append(KosulFaktoru(
            ad: "RÜZGÂR",
            deger: "\(yon.ad.localizedUppercase) \(Int(hava.ruzgarKmh)) KM/S",
            etki: ruzgarEtki))
        puan += ruzgarEtki

        // Waves (coastal only — inland/no-data just skips)
        if let dalgaM {
            let dalgaEtki: Int
            switch dalgaM {
            case ..<0.3: dalgaEtki = 10
            case ..<1.0: dalgaEtki = 5
            case ..<2.0: dalgaEtki = -10
            default: dalgaEtki = -20
            }
            faktorler.append(KosulFaktoru(
                ad: "DALGA",
                deger: String(format: "%.1f M", dalgaM),
                etki: dalgaEtki))
            puan += dalgaEtki
        }

        // Pressure — near-normal is mildly good; trend needs history (v1.x).
        let basincEtki = abs(hava.basincHPa - 1013) <= 7 ? 5 : 0
        faktorler.append(KosulFaktoru(
            ad: "BASINÇ",
            deger: "\(Int(hava.basincHPa)) HPA",
            etki: basincEtki))
        puan += basincEtki

        // SST (Open-Meteo marine). 14–22 °C is the broad temperate-fishing
        // sweet spot; extremes push fish deep/off the bite. Placeholder band.
        if let sst = deniz.sstC {
            let sstEtki: Int
            switch sst {
            case 14...22: sstEtki = 10
            case 10..<14, 22..<26: sstEtki = 3
            default: sstEtki = -8
            }
            faktorler.append(KosulFaktoru(
                ad: "DENİZ SICAKLIĞI",
                deger: String(format: "%.1f °C", sst),
                etki: sstEtki))
            puan += sstEtki
        }

        // Solunar
        let pencereler = Solunar.windows(on: now, longitude: coordinate.longitude)
        let solunarEtki: Int
        let solunarDeger: String
        if pencereler.major.contains(where: { $0.contains(now) }) {
            solunarEtki = 15
            solunarDeger = "MAJÖR DÖNEM"
        } else if pencereler.minor.contains(where: { $0.contains(now) }) {
            solunarEtki = 8
            solunarDeger = "MİNÖR DÖNEM"
        } else {
            solunarEtki = 0
            solunarDeger = "ARA DÖNEM"
        }
        faktorler.append(KosulFaktoru(ad: "SOLUNAR", deger: solunarDeger, etki: solunarEtki))
        puan += solunarEtki

        // §2.1-10: tied to the user's own history when possible.
        if let top = HourBand.topBand(dates: catchDates),
           HourBand.band(forHour: Calendar.current.component(.hour, from: now)) == top {
            faktorler.append(KosulFaktoru(ad: "SENİN SAATİN", deger: top.label, etki: 10))
            puan += 10
        }

        puan = min(max(puan, 0), 100)
        let ifade = puan >= 70 ? "Koşullar uygun" : (puan >= 40 ? "Koşullar orta" : "Koşullar zayıf")

        return KosulRaporu(
            puan: puan,
            ifade: ifade,
            il: il,
            faktorler: faktorler,
            majorlar: pencereler.major,
            minorlar: pencereler.minor,
            zaman: now)
    }
}

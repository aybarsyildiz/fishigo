import Foundation

/// Everything an achievement needs to be drawn + evaluated. Pure value type;
/// evaluation is a closure over the (already-fetched) data snapshot so the
/// grid, the hook module, and any future "just earned" ceremony share one truth.
struct Rozet: Identifiable {
    let id: String
    let ad: String
    let aciklama: String
    let sembol: String
    let kazanildi: (RozetVerisi) -> Bool
}

/// Snapshot the evaluator reads — kept flat so it's cheap to build per render.
struct RozetVerisi {
    let records: [CatchRecord]
    let emptyTrips: [EmptyTrip]
    let species: SpeciesStore
    let caughtSpeciesCount: Int
    let totalSpecies: Int
    let streakWeeks: Int

    private var calendar: Calendar { .current }

    func speciesRarity(_ id: String) -> Rarity? { species.species(id: id)?.nadirlik }

    func hasHourBand(_ band: HourBand) -> Bool {
        records.contains { HourBand.band(forHour: calendar.component(.hour, from: $0.date)) == band }
    }

    func hasWind(_ yon: RuzgarYonu) -> Bool {
        records.contains { $0.windDirectionDeg.map { RuzgarYonu.from(degrees: $0) } == yon }
    }

    var seasCaught: Set<Species.Deniz> {
        Set(records.compactMap { r in r.coordinate.flatMap(SeaLocator.sea(for:)) })
    }

    var maxInAnyMonth: Int {
        let groups = Dictionary(grouping: records) {
            calendar.dateComponents([.year, .month], from: $0.date)
        }
        return groups.values.map(\.count).max() ?? 0
    }

    func completedEvolutionLine() -> Bool {
        species.all.contains { DeksProgress.isLineComplete($0, records: records) }
    }
}

/// The catalogue. Placeholder set — the owner can retune names/criteria.
enum Rozetler {
    static let hepsi: [Rozet] = [
        Rozet(id: "ilk", ad: "İlk Yakalayış", aciklama: "İlk balığını deftere işledin", sembol: "fish") { !$0.records.isEmpty },
        Rozet(id: "on-tur", ad: "Koleksiyoncu", aciklama: "10 farklı tür", sembol: "square.grid.2x2") { $0.caughtSpeciesCount >= 10 },
        Rozet(id: "yirmibes-tur", ad: "Meraklı", aciklama: "25 farklı tür", sembol: "square.grid.3x3") { $0.caughtSpeciesCount >= 25 },
        Rozet(id: "elli-tur", ad: "Uzman", aciklama: "50 farklı tür", sembol: "rectangle.grid.3x2") { $0.caughtSpeciesCount >= 50 },
        Rozet(id: "deks-tamam", ad: "Balıkdeks Tamam", aciklama: "Tüm türler toplandı", sembol: "checkmark.seal") { $0.caughtSpeciesCount >= $0.totalSpecies && $0.totalSpecies > 0 },
        Rozet(id: "seri-tamam", ad: "Boy Serisi", aciklama: "Bir evrim serisini tamamladın", sembol: "arrow.right.circle") { $0.completedEvolutionLine() },
        Rozet(id: "seri-4", ad: "Düzenli", aciklama: "4 hafta sefer serisi", sembol: "flame") { $0.streakWeeks >= 4 },
        Rozet(id: "seri-12", ad: "Sadık", aciklama: "12 hafta sefer serisi", sembol: "flame.fill") { $0.streakWeeks >= 12 },
        Rozet(id: "gece", ad: "Gece Avcısı", aciklama: "Gece yakalayışı", sembol: "moon.stars") { $0.hasHourBand(.gece) },
        Rozet(id: "safak", ad: "Şafak", aciklama: "Sabah yakalayışı", sembol: "sunrise") { $0.hasHourBand(.sabah) },
        Rozet(id: "dort-deniz", ad: "Dört Deniz", aciklama: "Dört denizde de yakaladın", sembol: "water.waves") { $0.seasCaught.count >= 4 },
        Rozet(id: "lodos", ad: "Lodos Ustası", aciklama: "Lodosta yakaladın", sembol: "wind") { $0.hasWind(.lodos) },
        Rozet(id: "salma", ad: "Denize Saygı", aciklama: "Bir balığı geri bıraktın", sembol: "arrow.uturn.left") { $0.records.contains(where: \.released) },
        Rozet(id: "bos", ad: "Boş Dönmek de Var", aciklama: "İlk boş seferini işledin", sembol: "circle.dashed") { !$0.emptyTrips.isEmpty },
        Rozet(id: "epik", ad: "Nadir Bulunmuş", aciklama: "Epik bir tür yakaladın", sembol: "diamond") { d in d.records.contains { d.speciesRarity($0.speciesId)?.hasBrassAccent == true } },
        Rozet(id: "aylik-10", ad: "Verimli Ay", aciklama: "Bir ayda 10 yakalayış", sembol: "calendar") { $0.maxInAnyMonth >= 10 },
        Rozet(id: "yuz", ad: "Yüzler", aciklama: "Toplam 100 yakalayış", sembol: "number") { $0.records.count >= 100 },
    ]

    static func earnedIds(_ veri: RozetVerisi) -> Set<String> {
        Set(hepsi.filter { $0.kazanildi(veri) }.map(\.id))
    }
}

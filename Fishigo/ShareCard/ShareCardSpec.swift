import UIKit

/// Everything the share renderer needs, resolved up front — the card view is
/// a pure function of this spec (plus a progress scalar for the v1.1 video
/// path), so it can render off-live-data at any size or frame time.
struct ShareCardSpec {
    let photo: UIImage?
    let siluet: Species.Siluet
    let displayName: String
    let latin: String
    let lengthCm: Int
    let date: Date
    let released: Bool
    /// §9: province only — never coordinates, never district.
    let il: String?
    let rarity: Rarity
    let isFirstOfSpecies: Bool
    let deksCaught: Int
    let deksTotal: Int

    @MainActor
    static func make(record: CatchRecord, app: AppModel) -> ShareCardSpec {
        let species = app.species.species(id: record.speciesId)
        return ShareCardSpec(
            photo: record.photoJPEG.flatMap(UIImage.init(data:)),
            siluet: species?.siluetTipi ?? .uzun,
            displayName: species?.displayName(lengthCm: record.lengthCm) ?? record.speciesId,
            latin: species?.latince ?? "",
            lengthCm: record.lengthCm,
            date: record.date,
            released: record.released,
            il: record.il,
            rarity: species?.nadirlik ?? .yaygin,
            isFirstOfSpecies: record.isFirstOfSpecies,
            deksCaught: DeksProgress.caughtIds(app.log.records).count,
            deksTotal: app.species.all.count)
    }
}

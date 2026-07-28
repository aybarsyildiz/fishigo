import UIKit
import CoreLocation
import Observation

/// §7: every animated element is a state machine tied to app state. This is
/// that state machine for the core loop — the views only render `phase`.
///
/// foto → tanima (ANTICIPATION) → [suspense beat] → onay | fotoYok
///      → olcum → acilis (reveal ceremony) → kaydedildi → foto
@MainActor
@Observable
final class CatchFlowModel {
    enum Phase: Equatable {
        /// Waiting for a photo (camera / gallery).
        case foto
        /// Recognition in flight — line-tension animation, never a spinner.
        case tanima
        /// Result arrived: confirm chip(s) per §4 confidence rules.
        case onay
        /// balik_yok — friendly retry, never blame.
        case fotoYok
        /// Network/service failure — retry or manual species pick. Never "no fish".
        case hata
        /// Free quota exhausted (server 429) — paywall stub + manual pick.
        case kota
        /// Length ruler + released toggle + note.
        case olcum
        /// Card reveal ceremony (flip, count, stamp).
        case acilis
        /// Saved to the log.
        case kaydedildi
    }

    private(set) var phase: Phase = .foto

    private(set) var photo: UIImage?
    private(set) var photoJPEG: Data?
    private(set) var sonuc: TanimaSonucu?
    private(set) var secilenTur: Species?
    var lengthCm: Int = 25
    var released = false
    var note = ""
    private(set) var savedRecord: CatchRecord?

    /// One-shot GPS fix, started the moment a photo lands (§9: permission
    /// prompt appears in-context, at the first catch).
    private var locationTask: Task<CLLocationCoordinate2D?, Never>?

    private let app: AppModel

    init(app: AppModel) {
        self.app = app
    }

    // MARK: Derived

    var legality: LegalityStatus {
        guard let tur = secilenTur else { return .bilgiYok }
        return app.legality.check(speciesId: tur.id, lengthCm: lengthCm, date: .now)
    }

    var displayName: String {
        secilenTur.map { $0.displayName(lengthCm: lengthCm) } ?? ""
    }

    /// §5: the source line accompanies every legality status.
    var mevzuatKaynagi: String {
        app.regulations.kaynak
    }

    var gunlukLimit: String? {
        secilenTur.flatMap { app.regulations.kural(for: $0.id)?.gunlukLimit }
    }

    var isFirstOfSpecies: Bool {
        guard let tur = secilenTur else { return false }
        return app.log.isFirst(speciesId: tur.id)
    }

    /// Longest logged catch of the selected species, nil when none.
    var personalBest: Int? {
        secilenTur.flatMap { app.log.personalBest(speciesId: $0.id) }
    }

    /// Primary + alternatives resolved against the closed list.
    var candidates: [Species] {
        guard let sonuc else { return [] }
        let ids = [sonuc.turId].compactMap { $0 } + sonuc.alternatifler
        return ids.compactMap { app.species.species(id: $0) }
    }

    // MARK: Transitions

    func photoPicked(_ image: UIImage) {
        photo = image
        photoJPEG = ImagePipeline.recognitionJPEG(from: image)
        phase = .tanima
        let locationService = app.location
        locationTask = Task { await locationService.captureLocation() }
        Task { await recognize() }
    }

    private func recognize() async {
        guard let jpeg = photoJPEG else { return retry() }
        do {
            let yanit = try await app.recognizer.identify(jpeg)
            if let kalan = yanit.kalanHak {
                UserDefaults.standard.set(kalan, forKey: "kalanTanima")
            }

            // §7 reveal choreography step 2: hold AFTER the result arrives. Intentional.
            try? await Task.sleep(for: .milliseconds(400))

            guard phase == .tanima else { return }
            sonuc = yanit.sonuc
            if !yanit.sonuc.balikYok, !candidates.isEmpty {
                phase = .onay
            } else {
                phase = .fotoYok
            }
        } catch TanimaHata.kotaBitti {
            UserDefaults.standard.set(0, forKey: "kalanTanima")
            guard phase == .tanima else { return }
            phase = .kota
        } catch {
            guard phase == .tanima else { return }
            phase = .hata
        }
    }

    /// Retry recognition with the same photo (network hiccups on the water).
    func tekrarTani() {
        guard photoJPEG != nil else { return retry() }
        phase = .tanima
        Task { await recognize() }
    }

    func confirm(_ species: Species) {
        logCorrectionIfNeeded(chosen: species)
        secilenTur = species
        Feel.shared.speciesConfirmed()
        phase = .olcum
    }

    /// §4: the model suggested one thing, the angler confirmed another —
    /// gold-standard training signal. Photo hash only, never the photo.
    private func logCorrectionIfNeeded(chosen: Species) {
        guard let sonuc, !sonuc.balikYok,
              let onerilen = sonuc.turId,
              onerilen != chosen.id,
              let jpeg = photoJPEG else { return }
        app.corrections.log(
            photoHash: ImagePipeline.sha256Hex(jpeg),
            onerilen: onerilen,
            duzeltilen: chosen.id)
    }

    func retry() {
        photo = nil
        photoJPEG = nil
        sonuc = nil
        phase = .foto
    }

    func measurementDone() {
        Feel.shared.buttonTap()
        phase = .acilis
    }

    func saveCatch() {
        guard let tur = secilenTur else { return }
        let pendingLocation = locationTask
        Task {
            // Wait briefly for the GPS fix; a catch is never held hostage by one.
            let coordinate = await withTaskGroup(of: CLLocationCoordinate2D?.self) { group in
                group.addTask { await pendingLocation?.value }
                group.addTask {
                    try? await Task.sleep(for: .seconds(3))
                    return nil
                }
                let first = await group.next() ?? nil
                group.cancelAll()
                return first
            }
            let record = app.log.save(
                speciesId: tur.id,
                lengthCm: lengthCm,
                photoJPEG: photoJPEG,
                released: released,
                note: note,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude)
            savedRecord = record
            phase = .kaydedildi

            // §9: enrich with the province (the only shareable location fact),
            // best-effort in the background.
            if let coordinate {
                let log = app.log
                Task {
                    if let il = await ProvinceResolver.il(for: coordinate) {
                        log.attachProvince(il, to: record)
                    }
                }
            }
        }
    }

    var logCount: Int {
        app.log.count
    }

    // MARK: Deks summary for the saved screen

    var deksCaughtCount: Int {
        DeksProgress.caughtIds(app.log.records).count
    }

    var deksTotal: Int {
        app.species.all.count
    }

    /// True when the just-saved record filled the LAST missing band of the
    /// species' size-name chain (§8: completing a line triggers a ceremony).
    var lineJustCompleted: Bool {
        guard let record = savedRecord,
              let tur = app.species.species(id: record.speciesId),
              tur.hasEvolutionLine else { return false }
        let own = app.log.records.filter { $0.speciesId == tur.id }
        let bandsNow = Set(own.map { DeksProgress.bandIndex(of: tur, lengthCm: $0.lengthCm) })
        guard bandsNow.count == tur.boyAdlari.count else { return false }
        let bandsBefore = Set(own
            .filter { $0.persistentModelID != record.persistentModelID }
            .map { DeksProgress.bandIndex(of: tur, lengthCm: $0.lengthCm) })
        return bandsBefore.count < bandsNow.count
    }

    func reset() {
        photo = nil
        photoJPEG = nil
        sonuc = nil
        secilenTur = nil
        lengthCm = 25
        released = false
        note = ""
        savedRecord = nil
        locationTask = nil
        phase = .foto
    }
}

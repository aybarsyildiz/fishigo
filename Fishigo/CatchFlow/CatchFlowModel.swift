import UIKit
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
        Task { await recognize() }
    }

    private func recognize() async {
        guard let jpeg = photoJPEG else { return retry() }
        let sonuc = try? await app.recognizer.identify(jpeg)

        // §7 reveal choreography step 2: hold AFTER the result arrives. Intentional.
        try? await Task.sleep(for: .milliseconds(400))

        guard phase == .tanima else { return }
        self.sonuc = sonuc
        if let sonuc, !sonuc.balikYok, !candidates.isEmpty {
            phase = .onay
        } else {
            phase = .fotoYok
        }
    }

    func confirm(_ species: Species) {
        secilenTur = species
        Feel.shared.speciesConfirmed()
        phase = .olcum
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
        savedRecord = app.log.save(
            speciesId: tur.id,
            lengthCm: lengthCm,
            photoJPEG: photoJPEG,
            released: released,
            note: note)
        phase = .kaydedildi
    }

    var logCount: Int {
        app.log.records.count
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
        phase = .foto
    }
}

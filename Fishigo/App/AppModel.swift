import Foundation
import Observation

/// Composition root — every service seam lives here so M2/M5/M6 can swap
/// implementations (SwiftData log, proxy recognizer, real regulations) in one
/// place without touching views.
@MainActor
@Observable
final class AppModel {
    let species: SpeciesStore
    let log: CatchLog
    let recognizer: any SpeciesRecognizing
    let legality: any LegalityChecking

    init() {
        species = SpeciesStore.loadBundled()
        log = CatchLog()
        recognizer = MockSpeciesRecognizer()
        legality = StubLegality()
    }
}

import Foundation
import SwiftData
import Observation

enum AppTab: Hashable {
    case deks, yakala, defter
}

/// Composition root — every service seam lives here so M5/M6 can swap
/// implementations (proxy recognizer, real regulations) in one place without
/// touching views.
@MainActor
@Observable
final class AppModel {
    /// Root tab selection — lives here so hook modules can route across tabs.
    var tab: AppTab = .yakala

    let container: ModelContainer
    let species: SpeciesStore
    let log: CatchLog
    let location: LocationService
    let recognizer: any SpeciesRecognizing
    let legality: any LegalityChecking

    init() {
        do {
            container = try ModelContainer(for: CatchRecord.self)
        } catch {
            fatalError("ModelContainer kurulamadı: \(error)")
        }
        species = SpeciesStore.loadBundled()
        log = CatchLog(context: container.mainContext)
        location = LocationService()
        recognizer = MockSpeciesRecognizer()
        legality = StubLegality()
    }
}

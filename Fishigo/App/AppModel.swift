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
    let corrections: CorrectionStore
    let location: LocationService
    let regulations: RegulationsStore
    let recognizer: any SpeciesRecognizing
    let legality: any LegalityChecking

    init() {
        do {
            container = try ModelContainer(for: CatchRecord.self, CorrectionEntry.self)
        } catch {
            fatalError("ModelContainer kurulamadı: \(error)")
        }
        species = SpeciesStore.loadBundled()
        log = CatchLog(context: container.mainContext)
        corrections = CorrectionStore(context: container.mainContext)
        location = LocationService()
        regulations = RegulationsStore()
        // Geliştirme fikstürleri gerekirse: MockSpeciesRecognizer()
        recognizer = ProxySpeciesRecognizer()
        legality = RegulationsLegality(store: regulations)

        let regulations = self.regulations
        Task { await regulations.refresh() }
    }
}

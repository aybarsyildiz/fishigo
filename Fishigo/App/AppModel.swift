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
    let conditions: ConditionStore
    let pro: ProStore
    let recognizer: any SpeciesRecognizing
    let legality: any LegalityChecking

    init() {
        do {
            // Private CloudKit backup + cross-device sync, pinned to our
            // container (never .default). Falls back to local-only when the
            // device has no iCloud account — a catch is never blocked.
            let config = ModelConfiguration(
                cloudKitDatabase: .private("iCloud.com.netnucleus.fishigo"))
            container = try ModelContainer(
                for: CatchRecord.self, CorrectionEntry.self, EmptyTrip.self,
                configurations: config)
        } catch {
            fatalError("ModelContainer kurulamadı: \(error)")
        }
        species = SpeciesStore.loadBundled()
        log = CatchLog(context: container.mainContext)
        corrections = CorrectionStore(context: container.mainContext)
        location = LocationService()
        regulations = RegulationsStore()
        conditions = ConditionStore()
        pro = ProStore()
        // Geliştirme fikstürleri gerekirse: MockSpeciesRecognizer()
        recognizer = ProxySpeciesRecognizer()
        legality = RegulationsLegality(store: regulations)

        let regulations = self.regulations
        let conditions = self.conditions
        let log = self.log
        Task {
            await regulations.refresh()
            await conditions.refresh(records: log.records)
        }
    }
}

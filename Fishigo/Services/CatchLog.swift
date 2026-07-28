import Foundation
import Observation

/// M1 in-memory catch log. M2 swaps the storage for SwiftData behind the same
/// surface; view code must not care which one it is talking to.
@Observable
final class CatchLog {
    private(set) var records: [CatchRecord] = []

    var caughtSpeciesIds: Set<String> {
        Set(records.map(\.speciesId))
    }

    func isFirst(speciesId: String) -> Bool {
        !caughtSpeciesIds.contains(speciesId)
    }

    func personalBest(speciesId: String) -> Int? {
        records.filter { $0.speciesId == speciesId }.map(\.lengthCm).max()
    }

    /// Builds and appends the record; first-catch and record flags are decided
    /// here, once, so the reveal and the log always agree.
    @discardableResult
    func save(speciesId: String, lengthCm: Int, photoJPEG: Data?, released: Bool, note: String) -> CatchRecord {
        let record = CatchRecord(
            id: UUID(),
            speciesId: speciesId,
            lengthCm: lengthCm,
            photoJPEG: photoJPEG,
            date: .now,
            released: released,
            note: note,
            isFirstOfSpecies: isFirst(speciesId: speciesId),
            isPersonalRecord: lengthCm > (personalBest(speciesId: speciesId) ?? 0))
        records.append(record)
        return record
    }
}

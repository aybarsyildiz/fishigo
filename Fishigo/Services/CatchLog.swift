import Foundation
import SwiftData
import Observation

/// Write side + flow queries over the SwiftData store. List/map/stats views
/// observe the store directly via @Query; this type exists so the catch flow
/// and future services never touch ModelContext themselves.
@MainActor
@Observable
final class CatchLog {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    var records: [CatchRecord] {
        let descriptor = FetchDescriptor<CatchRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    var count: Int {
        (try? context.fetchCount(FetchDescriptor<CatchRecord>())) ?? 0
    }

    func isFirst(speciesId: String) -> Bool {
        let descriptor = FetchDescriptor<CatchRecord>(
            predicate: #Predicate { $0.speciesId == speciesId })
        return ((try? context.fetchCount(descriptor)) ?? 0) == 0
    }

    func personalBest(speciesId: String) -> Int? {
        let descriptor = FetchDescriptor<CatchRecord>(
            predicate: #Predicate { $0.speciesId == speciesId })
        let lengths = (try? context.fetch(descriptor))?.map(\.lengthCm) ?? []
        return lengths.max()
    }

    /// First-catch and record flags are decided here, once, so the reveal and
    /// the log always agree.
    @discardableResult
    func save(
        speciesId: String,
        lengthCm: Int,
        photoJPEG: Data?,
        released: Bool,
        note: String,
        latitude: Double?,
        longitude: Double?
    ) -> CatchRecord {
        let record = CatchRecord(
            speciesId: speciesId,
            lengthCm: lengthCm,
            photoJPEG: photoJPEG,
            date: .now,
            released: released,
            note: note,
            isFirstOfSpecies: isFirst(speciesId: speciesId),
            isPersonalRecord: lengthCm > (personalBest(speciesId: speciesId) ?? 0),
            latitude: latitude,
            longitude: longitude)
        context.insert(record)
        try? context.save()
        return record
    }
}

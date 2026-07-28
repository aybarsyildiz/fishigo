import Foundation

/// One logged catch. M1: in-memory value type. M2 replaces the store with
/// SwiftData; keep this shape stable so the migration is mechanical.
struct CatchRecord: Identifiable, Hashable {
    let id: UUID
    let speciesId: String
    let lengthCm: Int
    /// Downscaled JPEG (same pipeline the recognizer uses).
    let photoJPEG: Data?
    let date: Date
    let released: Bool
    let note: String
    let isFirstOfSpecies: Bool
    let isPersonalRecord: Bool
    // TODO(M2): GPS (private), TODO(M7): weather snapshot at catch time.
}

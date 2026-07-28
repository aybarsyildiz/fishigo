import Foundation
import SwiftData
import CoreLocation

/// One logged catch — SwiftData-backed, local-first.
/// TODO(M2.5): CloudKit private-database sync once entitlements/team are set.
@Model
final class CatchRecord {
    var speciesId: String
    var lengthCm: Int
    /// Downscaled JPEG (same pipeline the recognizer uses).
    @Attribute(.externalStorage) var photoJPEG: Data?
    var date: Date
    var released: Bool
    var note: String
    var isFirstOfSpecies: Bool
    var isPersonalRecord: Bool

    /// §9: private by default — only ever rendered on the user's own map.
    /// Share surfaces may show the PROVINCE, never coordinates.
    var latitude: Double?
    var longitude: Double?
    /// Reverse-geocoded province (il) — the ONLY location detail a share
    /// card may carry (§9). Resolved best-effort after save.
    var il: String?

    // M7 weather snapshot at catch time (Open-Meteo). Optional so adding the
    // service later needs no migration.
    var windDirectionDeg: Double?
    var windSpeedKmh: Double?
    var pressureHPa: Double?
    var temperatureC: Double?

    init(
        speciesId: String,
        lengthCm: Int,
        photoJPEG: Data?,
        date: Date,
        released: Bool,
        note: String,
        isFirstOfSpecies: Bool,
        isPersonalRecord: Bool,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.speciesId = speciesId
        self.lengthCm = lengthCm
        self.photoJPEG = photoJPEG
        self.date = date
        self.released = released
        self.note = note
        self.isFirstOfSpecies = isFirstOfSpecies
        self.isPersonalRecord = isPersonalRecord
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

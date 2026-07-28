import Foundation
import CoreLocation

/// Maps a coordinate to one of the four Turkish seas, using the same rough
/// boxes as the GBIF presence fetch. Checked most-specific-first (Marmara is
/// small and central, so it wins over the basins it borders).
enum SeaLocator {
    private struct Box {
        let deniz: Species.Deniz
        let lonMin, lonMax, latMin, latMax: Double
        func contains(_ c: CLLocationCoordinate2D) -> Bool {
            c.longitude >= lonMin && c.longitude <= lonMax
                && c.latitude >= latMin && c.latitude <= latMax
        }
    }

    private static let boxes: [Box] = [
        Box(deniz: .marmara, lonMin: 26.3, lonMax: 30.0, latMin: 40.3, latMax: 41.2),
        Box(deniz: .karadeniz, lonMin: 27.5, lonMax: 42.0, latMin: 41.0, latMax: 43.0),
        Box(deniz: .ege, lonMin: 25.0, lonMax: 27.5, latMin: 35.8, latMax: 40.5),
        Box(deniz: .akdeniz, lonMin: 27.5, lonMax: 36.5, latMin: 35.8, latMax: 37.0),
    ]

    static func sea(for coordinate: CLLocationCoordinate2D) -> Species.Deniz? {
        boxes.first { $0.contains(coordinate) }?.deniz
    }
}

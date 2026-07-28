import Foundation
import CoreLocation

/// Coordinate → province (il), best-effort. §9: the province is the only
/// location fact that ever leaves the private map.
/// CLGeocoder is deprecated as of the iOS 26 SDK but is the only API that
/// reaches back to our iOS 17 floor. TODO: branch to MKReverseGeocodingRequest
/// when the deployment target moves past 26.
enum ProvinceResolver {
    static func il(for coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        return placemark?.administrativeArea
    }
}

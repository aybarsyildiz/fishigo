import Foundation
import CoreLocation

/// Current conditions at a point (§2.1-2 snapshot, §2.1-10 score inputs).
struct HavaDurumu {
    let sicaklikC: Double
    let basincHPa: Double
    let ruzgarKmh: Double
    let ruzgarYonuDeg: Double
}

/// Marine snapshot — wave height + sea-surface temperature (SST). Nil far from
/// open water. SST feeds the condition score and the catch snapshot.
struct DenizDurumu {
    let dalgaM: Double?
    let sstC: Double?
}

/// Open-Meteo forecast + marine (§3: free, no key). Best-effort everywhere —
/// missing weather never blocks a catch or the app.
enum WeatherService {
    static func current(_ coordinate: CLLocationCoordinate2D) async -> HavaDurumu? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,surface_pressure,wind_speed_10m,wind_direction_10m"),
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let yanit = try? JSONDecoder().decode(ForecastYanit.self, from: data) else { return nil }
        return HavaDurumu(
            sicaklikC: yanit.current.temperature,
            basincHPa: yanit.current.pressure,
            ruzgarKmh: yanit.current.windSpeed,
            ruzgarYonuDeg: yanit.current.windDirection)
    }

    /// Marine wave height + sea-surface temperature; nil fields far from open
    /// water or on service failure.
    static func marine(_ coordinate: CLLocationCoordinate2D) async -> DenizDurumu {
        var components = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "wave_height,sea_surface_temperature"),
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let yanit = try? JSONDecoder().decode(MarineYanit.self, from: data) else {
            return DenizDurumu(dalgaM: nil, sstC: nil)
        }
        return DenizDurumu(dalgaM: yanit.current.waveHeight, sstC: yanit.current.sst)
    }

    // MARK: Wire types

    private struct ForecastYanit: Codable {
        let current: Current

        struct Current: Codable {
            let temperature: Double
            let pressure: Double
            let windSpeed: Double
            let windDirection: Double

            enum CodingKeys: String, CodingKey {
                case temperature = "temperature_2m"
                case pressure = "surface_pressure"
                case windSpeed = "wind_speed_10m"
                case windDirection = "wind_direction_10m"
            }
        }
    }

    private struct MarineYanit: Codable {
        let current: Current

        struct Current: Codable {
            let waveHeight: Double?
            let sst: Double?

            enum CodingKeys: String, CodingKey {
                case waveHeight = "wave_height"
                case sst = "sea_surface_temperature"
            }
        }
    }
}

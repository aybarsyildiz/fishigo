import Foundation
import Observation

// §5: legality is 100% on-device and deterministic, from bundled + remote
// regulations.json. The LLM NEVER answers legality. Values are populated by
// the owner from the official tebliğ — this code only loads and looks up.

struct RegulationsFile: Codable {
    let version: String
    let kaynak: String
    let turler: [String: Kural]

    enum CodingKeys: String, CodingKey {
        case version, kaynak
        case turler = "türler"
    }
}

struct Kural: Codable {
    let minBoyCm: Int?
    let yasak: [YasakDonemi]?
    let gunlukLimit: String?
    let not: String?

    enum CodingKeys: String, CodingKey {
        case minBoyCm = "min_boy_cm"
        case yasak
        case gunlukLimit = "gunluk_limit"
        case not
    }
}

/// Closed season as "MM-DD" endpoints; may wrap the year end (12-15 → 02-28).
struct YasakDonemi: Codable {
    let bas: String
    let bit: String

    func contains(month: Int, day: Int) -> Bool {
        guard let start = Self.key(bas), let end = Self.key(bit) else { return false }
        let key = month * 100 + day
        return start <= end
            ? (key >= start && key <= end)
            : (key >= start || key <= end)
    }

    private static func key(_ mmdd: String) -> Int? {
        let parts = mmdd.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 100 + parts[1]
    }
}

/// Bundled sample → cached remote copy → ETag-refreshed at launch.
/// Rule updates ship with a Worker deploy, never an app release.
/// Not actor-isolated: the sync §5 lookup path must stay callable from the
/// nonisolated LegalityChecking protocol; all mutation happens at launch.
@Observable
final class RegulationsStore {
    private(set) var file: RegulationsFile

    var kaynak: String { file.kaynak }

    init() {
        file = Self.loadCachedRemote() ?? Self.loadBundled()
    }

    func kural(for turId: String) -> Kural? {
        file.turler[turId]
    }

    /// Conditional GET against the proxy; 304 means we're already current.
    func refresh() async {
        var request = URLRequest(url: ProxyConfig.baseURL.appending(path: "kurallar"))
        request.timeoutInterval = 15
        if let etag = UserDefaults.standard.string(forKey: "kurallarEtag") {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let parsed = try? Self.decoder.decode(RegulationsFile.self, from: data) else { return }
        file = parsed
        try? data.write(to: Self.cacheURL, options: .atomic)
        if let etag = http.value(forHTTPHeaderField: "Etag") {
            UserDefaults.standard.set(etag, forKey: "kurallarEtag")
        }
    }

    // MARK: Sources

    private static let decoder = JSONDecoder()

    private static var cacheURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "regulations.json")
    }

    private static func loadCachedRemote() -> RegulationsFile? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? decoder.decode(RegulationsFile.self, from: data)
    }

    private static func loadBundled() -> RegulationsFile {
        guard let url = Bundle.main.url(forResource: "regulations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let parsed = try? decoder.decode(RegulationsFile.self, from: data) else {
            assertionFailure("bundled regulations.json missing/malformed")
            return RegulationsFile(version: "yok", kaynak: "", turler: [:])
        }
        return parsed
    }
}

/// The deterministic §5 lookup. Closed season outranks size limit.
struct RegulationsLegality: LegalityChecking {
    let store: RegulationsStore

    func check(speciesId: String, lengthCm: Int, date: Date) -> LegalityStatus {
        guard let kural = store.kural(for: speciesId) else { return .bilgiYok }

        let components = Calendar.current.dateComponents([.month, .day], from: date)
        if let month = components.month, let day = components.day,
           let donemler = kural.yasak,
           donemler.contains(where: { $0.contains(month: month, day: day) }) {
            return .donemYasagi
        }
        if let min = kural.minBoyCm, lengthCm < min {
            return .boyAlti(minCm: min)
        }
        return .serbest
    }
}

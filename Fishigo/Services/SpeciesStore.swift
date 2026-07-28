import Foundation
import Observation

/// Loads the closed species list from bundled species.json and answers lookups.
@Observable
final class SpeciesStore {
    let all: [Species]
    private let byId: [String: Species]

    init(species: [Species]) {
        all = species.sorted { $0.ad.localizedCompare($1.ad) == .orderedAscending }
        byId = Dictionary(uniqueKeysWithValues: species.map { ($0.id, $0) })
    }

    func species(id: String) -> Species? {
        byId[id]
    }

    func search(_ query: String) -> [Species] {
        guard !query.isEmpty else { return all }
        return all.filter { species in
            species.ad.localizedCaseInsensitiveContains(query)
                || species.latince.localizedCaseInsensitiveContains(query)
                || species.boyAdlari.contains { $0.ad.localizedCaseInsensitiveContains(query) }
        }
    }

    static func loadBundled() -> SpeciesStore {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let url = Bundle.main.url(forResource: "species", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? decoder.decode(SpeciesFile.self, from: data) else {
            assertionFailure("species.json missing or malformed")
            return SpeciesStore(species: [])
        }
        return SpeciesStore(species: file.turler)
    }

    private struct SpeciesFile: Codable {
        let version: String
        let turler: [Species]
    }
}

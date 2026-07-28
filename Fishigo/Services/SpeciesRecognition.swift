import Foundation

/// §4 recognition result — mirrors the proxy's JSON contract exactly:
/// { "tur_id": string|null, "guven": 0-1, "alternatifler": [ids], "balik_yok": bool }
struct TanimaSonucu: Codable, Equatable {
    let turId: String?
    let guven: Double
    let alternatifler: [String]
    let balikYok: Bool

    /// §4 client rule: ≥ 0.8 → single confirm chip, below → candidate chips.
    var isConfident: Bool { guven >= 0.8 }
}

/// Result + the server-checked free-quota remainder (nil when the backend
/// doesn't meter, e.g. the mock).
struct TanimaYaniti {
    let sonuc: TanimaSonucu
    let kalanHak: Int?
}

enum TanimaHata: Error {
    /// 10/month free quota exhausted (server-checked) → paywall stub.
    case kotaBitti
    /// Network / service failure → retry state, never "no fish".
    case ag
}

protocol SpeciesRecognizing {
    func identify(_ jpeg: Data) async throws -> TanimaYaniti
}

/// Dev/preview mock: cycles through bundled fixture results so every §4 state
/// can be exercised without burning quota. Swap in via AppModel.
@MainActor
final class MockSpeciesRecognizer: SpeciesRecognizing {
    private let fixtures: [TanimaSonucu]
    private var nextIndex = 0

    init() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let url = Bundle.main.url(forResource: "recognition.fixtures", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? decoder.decode(FixtureFile.self, from: data) {
            fixtures = file.fixtures
        } else {
            fixtures = [TanimaSonucu(turId: "lufer", guven: 0.92, alternatifler: [], balikYok: false)]
        }
    }

    func identify(_ jpeg: Data) async throws -> TanimaYaniti {
        try await Task.sleep(for: .milliseconds(1700))
        let sonuc = fixtures[nextIndex % fixtures.count]
        nextIndex += 1
        return TanimaYaniti(sonuc: sonuc, kalanHak: nil)
    }

    private struct FixtureFile: Codable {
        let fixtures: [TanimaSonucu]
    }
}

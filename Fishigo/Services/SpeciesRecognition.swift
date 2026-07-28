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

/// Seam for M5: the real implementation will POST the downscaled JPEG to the
/// serverless proxy. Callers never know the difference.
protocol SpeciesRecognizing {
    func identify(_ jpeg: Data) async throws -> TanimaSonucu
}

/// M1 mock: cycles through bundled fixture results so every §4 state
/// (confident / low-confidence / no-fish) can be exercised on device.
/// The artificial delay exists to exercise the ANTICIPATION state — do not
/// remove it, the choreography depends on having something to wait through.
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

    func identify(_ jpeg: Data) async throws -> TanimaSonucu {
        try await Task.sleep(for: .milliseconds(1700))
        let sonuc = fixtures[nextIndex % fixtures.count]
        nextIndex += 1
        return sonuc
    }

    private struct FixtureFile: Codable {
        let fixtures: [TanimaSonucu]
    }
}

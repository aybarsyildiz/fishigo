import Foundation

/// The single place the client knows about the recognition proxy (§3): the
/// Worker holds the Anthropic key and the quota; the app only ever sends a
/// downscaled JPEG and a device id.
enum ProxyConfig {
    static let baseURL = URL(string: "https://fishigo-tanima.toneamp.workers.dev")!
}

/// Anonymous per-install id for the server-side quota. UserDefaults-backed —
/// a reinstall resets it, which is acceptable for a soft free-tier cap.
enum DeviceIdentity {
    static var id: String {
        let key = "cihazKimligi"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }
}

/// Live recognizer — POSTs to the Worker, which calls claude-haiku-4-5 with
/// the closed species list (§4). Errors map to flow states, never to "no fish".
@MainActor
final class ProxySpeciesRecognizer: SpeciesRecognizing {
    func identify(_ jpeg: Data) async throws -> TanimaYaniti {
        var request = URLRequest(url: ProxyConfig.baseURL.appending(path: "tanima"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIdentity.id, forHTTPHeaderField: "x-cihaz")
        request.httpBody = try? JSONEncoder().encode(["gorsel": jpeg.base64EncodedString()])

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TanimaHata.ag
        }
        guard let http = response as? HTTPURLResponse else { throw TanimaHata.ag }
        if http.statusCode == 429 { throw TanimaHata.kotaBitti }
        guard http.statusCode == 200 else { throw TanimaHata.ag }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let yanit = try? decoder.decode(ProxyYanit.self, from: data) else {
            throw TanimaHata.ag
        }
        return TanimaYaniti(
            sonuc: TanimaSonucu(
                turId: yanit.turId,
                guven: yanit.guven,
                alternatifler: yanit.alternatifler,
                balikYok: yanit.balikYok),
            kalanHak: yanit.kalanHak)
    }

    private struct ProxyYanit: Codable {
        let turId: String?
        let guven: Double
        let alternatifler: [String]
        let balikYok: Bool
        let kalanHak: Int?
    }
}

/// Best-effort correction upload (§4 accuracy dataset). Returns success so the
/// local queue can mark entries uploaded; failures just stay queued.
enum ProxyAPI {
    static func uploadCorrection(photoHash: String, onerilen: String?, duzeltilen: String) async -> Bool {
        var request = URLRequest(url: ProxyConfig.baseURL.appending(path: "duzeltme"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIdentity.id, forHTTPHeaderField: "x-cihaz")
        let body: [String: String?] = [
            "foto_ozet": photoHash,
            "onerilen": onerilen,
            "duzeltilen": duzeltilen,
        ]
        request.httpBody = try? JSONEncoder().encode(body)
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }
}

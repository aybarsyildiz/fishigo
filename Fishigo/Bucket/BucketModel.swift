import UIKit
import CoreLocation
import Observation

/// "Kova modu" — bulk logging for a whole catch in one photo. Deliberately NOT
/// ceremonial: the single-catch flow keeps its sacred reveal; this is the
/// utility path for the angler with a full bucket who won't shoot 20 fish one
/// by one. Recognize → review/edit the list → bulk-save. Length is optional
/// here (speed over detail); it can be set later.
@MainActor
@Observable
final class BucketModel {
    enum Phase: Equatable {
        case tanima
        case liste
        case hata
        case kota
        case kaydedildi(Int)
    }

    private(set) var phase: Phase = .tanima
    private(set) var photo: UIImage?
    private(set) var photoJPEG: Data?
    var satirlar: [KovaBaligi] = []

    private var coordinate: CLLocationCoordinate2D?
    private let app: AppModel

    init(app: AppModel, image: UIImage) {
        self.app = app
        photo = image
        photoJPEG = ImagePipeline.recognitionJPEG(from: image)
        let location = app.location
        Task { coordinate = await location.captureLocation() }
        Task { await recognize() }
    }

    private func recognize() async {
        guard let jpeg = photoJPEG else { phase = .hata; return }
        do {
            let (baliklar, kalan) = try await BucketRecognizer.identifyMany(jpeg)
            if let kalan { UserDefaults.standard.set(kalan, forKey: "kalanTanima") }
            satirlar = baliklar
            phase = .liste
        } catch TanimaHata.kotaBitti {
            UserDefaults.standard.set(0, forKey: "kalanTanima")
            phase = .kota
        } catch {
            phase = .hata
        }
    }

    func species(_ row: KovaBaligi) -> Species? {
        app.species.species(id: row.turId)
    }

    func changeSpecies(_ rowId: UUID, to species: Species) {
        guard let index = satirlar.firstIndex(where: { $0.id == rowId }) else { return }
        satirlar[index].turId = species.id
        satirlar[index].guven = 1
        Feel.shared.buttonTap()
    }

    func remove(_ rowId: UUID) {
        satirlar.removeAll { $0.id == rowId }
        Feel.shared.buttonTap()
    }

    func addSpecies(_ species: Species) {
        satirlar.append(KovaBaligi(turId: species.id, guven: 1))
        Feel.shared.buttonTap()
    }

    /// Bulk-write every row as a catch record sharing the one photo. Length is
    /// left unmeasured (0); §2.1-2 weather is stamped once for the batch.
    func saveAll() {
        let jpeg = photoJPEG
        let coordinate = self.coordinate
        var kaydedilen: [CatchRecord] = []
        for row in satirlar {
            let record = app.log.save(
                speciesId: row.turId,
                lengthCm: 0,
                photoJPEG: jpeg,
                released: false,
                note: "Kova modu",
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude)
            kaydedilen.append(record)
        }
        Feel.shared.record()

        if let coordinate, let first = kaydedilen.first {
            let log = app.log
            Task {
                if let il = await ProvinceResolver.il(for: coordinate) {
                    for record in kaydedilen { log.attachProvince(il, to: record) }
                }
            }
            Task {
                async let havaTask = WeatherService.current(coordinate)
                async let denizTask = WeatherService.marine(coordinate)
                if let hava = await havaTask {
                    let deniz = await denizTask
                    for record in kaydedilen { log.attachWeather(hava, deniz: deniz, to: record) }
                }
                _ = first
            }
        }
        phase = .kaydedildi(satirlar.count)
    }
}

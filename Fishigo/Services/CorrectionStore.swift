import Foundation
import SwiftData
import Observation

/// Local-first correction queue. Writes always land; upload is opportunistic.
/// TODO(M8): sweep unuploaded entries at launch.
@MainActor
@Observable
final class CorrectionStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func log(photoHash: String, onerilen: String?, duzeltilen: String) {
        let entry = CorrectionEntry(
            photoHash: photoHash,
            onerilenId: onerilen,
            duzeltilenId: duzeltilen,
            date: .now,
            uploaded: false)
        context.insert(entry)
        try? context.save()

        Task {
            if await ProxyAPI.uploadCorrection(photoHash: photoHash, onerilen: onerilen, duzeltilen: duzeltilen) {
                entry.uploaded = true
                try? self.context.save()
            }
        }
    }
}

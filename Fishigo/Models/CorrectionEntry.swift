import Foundation
import SwiftData

/// §4: every user correction (suggested id ≠ confirmed id) is logged locally
/// and queued for optional upload — the future accuracy dataset. Only a photo
/// hash travels, never the photo itself.
@Model
final class CorrectionEntry {
    var photoHash: String = ""
    var onerilenId: String?
    var duzeltilenId: String = ""
    var date: Date = Date()
    var uploaded: Bool = false

    init(photoHash: String, onerilenId: String?, duzeltilenId: String, date: Date, uploaded: Bool) {
        self.photoHash = photoHash
        self.onerilenId = onerilenId
        self.duzeltilenId = duzeltilenId
        self.date = date
        self.uploaded = uploaded
    }
}

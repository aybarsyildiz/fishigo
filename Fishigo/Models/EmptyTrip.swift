import Foundation
import SwiftData

/// §2.1-9: a fishless outing, logged as a first-class entry. The habit being
/// rewarded is LOGGING, not catching — an empty trip keeps the streak alive
/// and the copy around it never shames.
@Model
final class EmptyTrip {
    var date: Date = Date()

    init(date: Date) {
        self.date = date
    }
}

import Foundation
import UserNotifications

/// §2.1-10: ONE daily local notification max, opt-in only, and per §9 the
/// toggle is only reachable after the first completed catch. The copy invites
/// the user to check conditions — it never promises fish.
enum DailyNotice {
    private static let id = "gunluk-kosul"

    /// Requests permission in-context and schedules the daily notice.
    /// Returns false if the user declined — the caller resets the toggle.
    static func enable() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Seyir Arşivi"
        content.body = "Günaydın. Bugünün koşulları hazır — çıkmadan bir göz at."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 7
        comps.minute = 30
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
        try? await center.add(request)
        return true
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

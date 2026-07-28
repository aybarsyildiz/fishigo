import Foundation

/// On-device solunar periods (§3: sun/moon math, no package).
///
/// v1 uses the classic lunar-lag approximation: the moon transits the local
/// meridian roughly 50.47 minutes later each day of its age, so
///   upper transit ≈ local solar noon + age × 50.47 min.
/// Major periods = upper/lower transit ±1 h; minor = quarter points ±30 min.
/// Accuracy ≈ ±30–40 min — fine for "koşullar", which is never a fish promise.
/// TODO(v1.x): upgrade to Meeus lunar position if precision ever matters.
enum Solunar {
    /// Reference new moon: 2000-01-06 18:14 UTC.
    private static let newMoonEpoch = Date(timeIntervalSince1970: 947_182_440)
    private static let synodicDays = 29.530588
    private static let lunarDay: TimeInterval = 24.8412 * 3600

    struct Pencereler {
        let major: [DateInterval]
        let minor: [DateInterval]
    }

    static func windows(on day: Date, longitude: Double, calendar: Calendar = .current) -> Pencereler {
        let startOfDay = calendar.startOfDay(for: day)
        let dayInterval = DateInterval(start: startOfDay, duration: 86_400)

        // Local solar transit in UTC ≈ 12:00 − longitude/15 h, on this civil date.
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let comps = calendar.dateComponents([.year, .month, .day], from: day)
        guard let utcMidnight = utcCalendar.date(from: comps) else {
            return Pencereler(major: [], minor: [])
        }
        let solarTransit = utcMidnight.addingTimeInterval((12 - longitude / 15) * 3600)

        let age = (day.timeIntervalSince(newMoonEpoch) / 86_400)
            .truncatingRemainder(dividingBy: synodicDays)
        let upperTransit = solarTransit.addingTimeInterval(age * 50.47 * 60)

        var majorCenters: [Date] = []
        var minorCenters: [Date] = []
        for n in -2...2 {
            let upper = upperTransit.addingTimeInterval(Double(n) * lunarDay)
            majorCenters.append(upper)
            majorCenters.append(upper.addingTimeInterval(lunarDay / 2))
            minorCenters.append(upper.addingTimeInterval(lunarDay / 4))
            minorCenters.append(upper.addingTimeInterval(-lunarDay / 4))
        }

        func clip(_ centers: [Date], halfWidth: TimeInterval) -> [DateInterval] {
            centers
                .map { DateInterval(start: $0.addingTimeInterval(-halfWidth), duration: halfWidth * 2) }
                .filter { $0.intersects(dayInterval) }
                .sorted { $0.start < $1.start }
        }

        return Pencereler(
            major: clip(majorCenters, halfWidth: 3600),
            minor: clip(minorCenters, halfWidth: 1800))
    }
}

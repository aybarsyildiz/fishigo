import Foundation

/// Weekly outing streak math (§2.1-9). An "outing" is any catch OR any logged
/// empty trip. The streak is alive if last week had an outing even when the
/// current week doesn't yet — never punish a fishless (or fishing-less) day.
enum Sefer {
    static func haftalikSeri(outings: [Date], now: Date = .now, calendar: Calendar = .current) -> Int {
        let keys = Set(outings.map { haftaAnahtari($0, calendar) })
        guard !keys.isEmpty else { return 0 }

        var cursor = now
        if !keys.contains(haftaAnahtari(cursor, calendar)) {
            guard let previous = calendar.date(byAdding: .day, value: -7, to: cursor),
                  keys.contains(haftaAnahtari(previous, calendar)) else { return 0 }
            cursor = previous
        }

        var streak = 0
        while keys.contains(haftaAnahtari(cursor, calendar)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -7, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func buHaftaVar(outings: [Date], now: Date = .now, calendar: Calendar = .current) -> Bool {
        let key = haftaAnahtari(now, calendar)
        return outings.contains { haftaAnahtari($0, calendar) == key }
    }

    static func bugunVar(outings: [Date], calendar: Calendar = .current) -> Bool {
        outings.contains { calendar.isDateInToday($0) }
    }

    /// Last `n` weeks as filled/empty, oldest first — the ledger tally row.
    static func sonHaftalar(_ n: Int, outings: [Date], now: Date = .now, calendar: Calendar = .current) -> [Bool] {
        let keys = Set(outings.map { haftaAnahtari($0, calendar) })
        return (0..<n).reversed().map { back in
            guard let date = calendar.date(byAdding: .day, value: -7 * back, to: now) else { return false }
            return keys.contains(haftaAnahtari(date, calendar))
        }
    }

    private static func haftaAnahtari(_ date: Date, _ calendar: Calendar) -> Int {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (comps.yearForWeekOfYear ?? 0) * 100 + (comps.weekOfYear ?? 0)
    }
}

import Foundation

struct HolidayCacheEntry: Codable {
    let holidays: [Holiday]
    let cachedAt: Date
}

enum HolidayCachePolicy {
    static let currentYearTTL: TimeInterval = 7 * 24 * 60 * 60  // 7일

    static func isStale(entry: HolidayCacheEntry, for year: Int, now: Date = Date()) -> Bool {
        let currentYear = Calendar.current.component(.year, from: now)
        guard year == currentYear else { return false }
        return now.timeIntervalSince(entry.cachedAt) > currentYearTTL
    }
}

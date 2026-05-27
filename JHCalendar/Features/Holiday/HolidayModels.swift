import Foundation

struct Holiday: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let name: String

    init(id: UUID = UUID(), date: Date, name: String) {
        self.id = id
        self.date = date
        self.name = name
    }
}

extension HolidayDTO {
    var asHoliday: Holiday? {
        guard isHoliday == "Y" else { return nil }
        // 20260301 → Date
        let s = String(locdate)
        guard s.count == 8,
              let y = Int(s.prefix(4)),
              let m = Int(s.dropFirst(4).prefix(2)),
              let d = Int(s.suffix(2)) else { return nil }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        guard let date = Calendar.current.date(from: comps) else { return nil }
        return Holiday(date: Calendar.current.startOfDay(for: date), name: dateName)
    }
}

import SwiftUI

@MainActor
final class HolidayStore: ObservableObject {
    @Published private(set) var byDay: [Date: Holiday] = [:]
    private var loadedYears: Set<Int> = []
    
    func load(year: Int) async {
        guard !loadedYears.contains(year) else { return }
        if let cached = readCache(year: year),
           !HolidayCachePolicy.isStale(entry: cached, for: year) {
            merge(cached.holidays); loadedYears.insert(year); return
        }
        
        do {
            let dtos = try await fetchHoliday(year: year)
            let holidays = dtos.compactMap { $0.asHoliday }
            writeCache(year: year, holidays: holidays)
            merge(holidays)
            loadedYears.insert(year)
        } catch {
            if let cached = readCache(year: year) {
                merge(cached.holidays)
                loadedYears.insert(year)
            }
            print("⚠️ holiday fetch failed:", error)
        }
    }

    private func readCache(year: Int) -> HolidayCacheEntry? {
        if let data = UserDefaults.standard.data(forKey: "holidays.\(year)"),
           let entry = try? JSONDecoder().decode(HolidayCacheEntry.self, from: data) {
            return entry
        }
        return nil
    }

    private func writeCache(year: Int, holidays: [Holiday]) {
        let entry = HolidayCacheEntry(holidays: holidays, cachedAt: Date())
        guard let data = try? JSONEncoder().encode(entry) else { return }
        UserDefaults.standard.set(data, forKey: "holidays.\(year)")
    }

    private func merge(_ holidays: [Holiday]) {
        let cal = Calendar.current
        for holiday in holidays {
            byDay[cal.startOfDay(for: holiday.date)] = holiday
        }
    }
}

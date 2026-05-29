import SwiftData
import SwiftUI

@Model
final class Event {
    var name: String
    var isAllDay: Bool
    var category: Category?
    var startDate: Date
    var endDate: Date
    var recurrence: RecurrenceRule = RecurrenceRule.none
    
    var color: Color {
        category?.color ?? .secondary
    }
    
    init(name: String, isAllDay: Bool, category: Category? = nil,
         startDate: Date, endDate: Date, recurrence: RecurrenceRule = .none) {
        self.name = name
        self.isAllDay = isAllDay
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.recurrence = recurrence
    }
}

// 반복
enum RecurrenceRule: String, Codable, CaseIterable {
    case none, daily, weekly, monthly, yearly, yearlyLunar
}

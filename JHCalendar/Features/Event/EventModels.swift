import SwiftData
import SwiftUI

@Model
final class Event {
    var name: String
    var isAllDay: Bool
    var category: Category?
    var startDate: Date
    var endDate: Date
    
    init(name: String, isAllDay: Bool, category: Category? = nil, startDate: Date, endDate: Date) {
        self.name = name
        self.isAllDay = isAllDay
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
    }
}

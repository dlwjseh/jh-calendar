import SwiftData

@Model
final class Event {
    var name: String
    var isAllDay: Bool
    var category: Category?
    
    init(name: String, isAllDay: Bool, category: Category? = nil) {
        self.name = name
        self.isAllDay = isAllDay
        self.category = category
    }
}

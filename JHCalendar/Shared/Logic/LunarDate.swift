import Foundation

enum LunarDate {
    static let calendar = Calendar(identifier: .chinese)
    
    /// 양력 Date -> 음력 (월, 일, 윤달여부)
    static func components(from date: Date) -> (month: Int, day: Int, isLeap: Bool)? {
        let comp = calendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        
        guard let month = comp.month,
              let day = comp.day,
              let isLeap = comp.isLeapMonth
        else { return nil }
        
        return (month: month, day: day, isLeap: isLeap)
    }
    
    /// "(음) 4.13" 형태 라벨
    static func shortLabel(from date: Date) -> String {
        guard let comp = components(from: date) else { return "" }
        return "(음)\(comp.month).\(comp.day)"
    }
}

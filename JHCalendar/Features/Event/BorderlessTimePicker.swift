import SwiftUI

enum Meridiem {
    case am, pm

    var label: String {
        switch self {
        case .am: "오전"
        case .pm: "오후"
        }
    }

    mutating func toggle() {
        self = self == .am ? .pm : .am
    }
}

struct BorderlessTimePicker: View {
    @Binding var date: Date
    @FocusState private var isMeridiemFocused: Bool
    @FocusState private var isHourFocused: Bool
    @FocusState private var isMinuteFocused: Bool
    
    private let cal = Calendar.current

    private var displayHour: Int {
        let hour24 = cal.dateComponents([.hour], from: date).hour ?? 0
        if hour24 == 0 || hour24 == 12 {
            return 12
        } else if hour24 > 12 {
            return hour24 - 12
        } else {
            return hour24
        }
    }
    private var displayHourFormat: String {
        return String(format: "%02d", displayHour)
    }
    
    private var displayMinute: Int {
        cal.dateComponents([.minute], from: date).minute ?? 0
    }
    private var displayMinuteFormat: String {
        return String(format: "%02d", displayMinute)
    }
    
    private var displayMeridiem: Meridiem {
        let hour24 = cal.dateComponents([.hour], from: date).hour ?? 0
        return hour24 >= 12 ? .pm : .am
    }

    /// 12시제 입력을 24h 로 환산해 date 에 되써넣는 단일 통로
    private func commit(hour12: Int, minute: Int, meridiem: Meridiem) {
        var newComp = cal.dateComponents([.year, .month, .day], from: date)
        if meridiem == .am {
            newComp.hour = hour12 == 12 ? 0 : hour12
        } else {
            newComp.hour = hour12 == 12 ? 12 : (hour12 + 12)
        }
        newComp.minute = minute
        
        if let newDate = cal.date(from: newComp) {
            date = newDate
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(displayMeridiem.label)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .focusable()
                .focused($isMeridiemFocused)
                .onTapGesture { isMeridiemFocused = true }
                .onMoveCommand { direction in
                    switch direction {
                    case .up, .down:
                        commit(hour12: displayHour, minute: displayMinute, meridiem: displayMeridiem == .am ? .pm : .am)
                    default:
                        break
                    }
                }
            
            Text(displayHourFormat)
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
                .focusable()
                .focused($isHourFocused)
                .onTapGesture { isHourFocused = true }
                .onKeyPress { keyPress in
                    if let digit = Int(keyPress.characters), (0...9).contains(digit) {
                        let candidate = displayHour * 10 + digit
                        let newHour = candidate <= 12 ? candidate : digit
                        
                        if newHour == 0 {
                            commit(hour12: 12, minute: displayMinute, meridiem: displayMeridiem == .am ? .pm : .am)
                        } else {
                            commit(hour12: newHour, minute: displayMinute, meridiem: displayMeridiem)
                        }
                        return .handled
                    }
                    return .ignored
                }
            
            Text(":")
            
            Text(displayMinuteFormat)
                .padding(.vertical, 2)
                .focusable()
                .focused($isMinuteFocused)
                .onTapGesture { isMinuteFocused = true }
                .onKeyPress { keyPress in
                    if let digit = Int(keyPress.characters), (0...9).contains(digit) {
                        let candidate = displayMinute * 10 + digit
                        commit(hour12: displayHour, minute: candidate < 60 ? candidate : digit, meridiem: displayMeridiem)
                        return .handled
                    }
                    return .ignored
                }
        }
    }
}

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
    @State private var meridiem: Meridiem = .am
    @FocusState private var isMeridiemFocused: Bool
    @State private var hour: Int = 12
    @FocusState private var isHourFocused: Bool
    @State private var minute: Int = 0
    @FocusState private var isMinuteFocused: Bool
    
    private var hourFormat: String {
        String(format: "%02d", hour)
    }
    private var minuteFormat: String {
        String(format: "%02d", minute)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(meridiem.label)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .focusable()
                .focused($isMeridiemFocused)
                .onTapGesture { isMeridiemFocused = true }
                .onMoveCommand { direction in
                    switch direction {
                    case .up, .down:
                        meridiem.toggle()
                    default:
                        break
                    }
                }
            
            Text(hourFormat)
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
                .focusable()
                .focused($isHourFocused)
                .onTapGesture { isHourFocused = true }
                .onKeyPress { keyPress in
                    if let digit = Int(keyPress.characters), (0...9).contains(digit) {
                        let candidate = hour * 10 + digit
                        var newHour = candidate <= 12 ? candidate : digit
                        if newHour == 0 {
                            meridiem.toggle()
                            newHour = 12
                        }
                        hour = newHour
                        
                        return .handled
                    }
                    return .ignored
                }
            
            Text(":")
            
            Text(minuteFormat)
                .padding(.vertical, 2)
                .focusable()
                .focused($isMinuteFocused)
                .onTapGesture { isMinuteFocused = true }
                .onKeyPress { keyPress in
                    if let digit = Int(keyPress.characters), (0...9).contains(digit) {
                        let candidate = minute * 10 + digit
                        minute = candidate < 60 ? candidate : digit
                        return .handled
                    }
                    return .ignored
                }
        }
    }
}

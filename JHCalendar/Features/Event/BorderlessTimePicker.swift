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
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Text(meridiem.label)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .focusable()
            .focused($isFocused)
            .onTapGesture { isFocused = true }
            .onMoveCommand { direction in
                switch direction {
                case .up, .down:
                    meridiem.toggle()
                default:
                    break
                }
            }
    }
}

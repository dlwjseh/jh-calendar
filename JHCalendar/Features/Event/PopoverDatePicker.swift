import SwiftUI

struct PopoverDatePicker: View {
    @State private var showStartPicker = false
    @Binding var date: Date
    
    var body: some View {
        Button {
              showStartPicker.toggle()
          } label: {
              Text(date.formatted(
                    Date.FormatStyle()
                        .year(.defaultDigits)
                        .month(.twoDigits)
                        .day(.twoDigits)
                        .locale(Locale(identifier: "ko_KR"))
                ))
              .padding(.vertical, 2)
          }
          .buttonStyle(.plain)
          .popover(isPresented: $showStartPicker, arrowEdge: .bottom) {
              DatePicker("", selection: $date, displayedComponents: .date)
                  .datePickerStyle(.graphical)
                  .labelsHidden()
                  .environment(\.locale, Locale(identifier: "ko_KR"))
                  .padding()
          }
    }
}

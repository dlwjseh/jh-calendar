import SwiftUI

struct MonthlyCalendarView: View {
    private let referenceDate = Date()
    private let rows: [[DayCell]]
    
    init() {
        let cells = makeDayCells(for: Date())
        self.rows = stride(from: 0, to: cells.count, by: 7).map { start in
            Array(cells[start..<start + 7])
        }
    }

    private static let yearMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f
    }()
    
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 년월 헤더
            Text(Self.yearMonthFormatter.string(from: referenceDate))
                .font(.title)
                .padding(.leading, 50)
            
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Divider()
            }
            
            // 일 그리드
            VStack(spacing: 0) {
                ForEach(rows, id: \.first?.id) { row in
                    HStack(spacing: 0) {
                        ForEach(row) { cell in
                            DayCellView(cell: cell)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .padding(.top, 70)
    }
}

#Preview {
    MonthlyCalendarView()
}

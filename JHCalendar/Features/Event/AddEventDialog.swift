import SwiftUI

enum EventDialogMode {
    case add(Date)
    case edit(Event)
}

struct AddEventDialog: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var isAllDay = true
    @State private var selectedCategory: Category? = nil
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAddMenuPresented = false
    @State private var showRecurrence = false
    
    let mode: EventDialogMode
    let categories: [Category]
    var onDismiss: () -> Void
    
    private static func sameDayOneHourLater(after date: Date) -> Date {
        let cal = Calendar.current
        let oneHourLater = cal.date(byAdding: .hour, value: 1, to: date) ?? date
        let sameDayEnd = cal.date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
        return min(oneHourLater, sameDayEnd)
    }
    
    init(mode: EventDialogMode, categories: [Category], onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.categories = categories
        self.onDismiss = onDismiss
        
        switch mode {
        case .add(let day):
            _startDate = State(initialValue: day)
            _endDate   = State(initialValue: AddEventDialog.sameDayOneHourLater(after: day))
        case .edit(let event):
            _startDate = State(initialValue: event.startDate)
            _endDate   = State(initialValue: event.endDate)
            _name      = State(initialValue: event.name)
            _isAllDay  = State(initialValue: event.isAllDay)
            _selectedCategory = State(initialValue: event.category)
        }
    }
    
    private var title: String {
        switch mode {
        case .add:  "이벤트 추가"
        case .edit: "이벤트 수정"
        }
    }
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
    private var isSaveEnabled: Bool {
        selectedCategory != nil && !trimmedName.isEmpty
        && endDate >= startDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack(alignment: .top, spacing: 5) {
                Image(systemName: "calendar.badge.plus")
                Text(title)
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 19) {
                HStack(alignment: .top, spacing: 5) {
                    fieldLabel("카테고리")
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(categories) { category in
                            CategoryChip(selectedCategory: $selectedCategory, category: category)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 5) {
                    fieldLabel("이벤트명")
                    TextField("이벤트명", text: $name)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3), lineWidth: 1))
                }
                
                HStack(spacing: 5) {
                    fieldLabel("종일")
                    Toggle("종일", isOn: $isAllDay)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                HStack(spacing: 5) {
                    fieldLabel("시작")
                    PopoverDatePicker(date: $startDate)
                    if !isAllDay {
                        BorderlessTimePicker(date: $startDate)
                    }
                }
                
                HStack(spacing: 5) {
                    fieldLabel("종료")
                    PopoverDatePicker(date: $endDate)
                    if !isAllDay {
                        BorderlessTimePicker(date: $endDate)
                    }
                }
                
                if showRecurrence {
                    HStack(spacing: 5) {
                        fieldLabel("반복")
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.smooth(duration: 0.25)) { showRecurrence = false }
                            } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain)
                            Text("반복 설정 (다음 단계)").foregroundStyle(.secondary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                HoverButton {
                    isAddMenuPresented.toggle()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                        Text("추가")
                    }
                }
                .padding(4)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .overlay(Capsule().strokeBorder(.secondary, lineWidth: 1))
                .contentShape(Capsule())
                .popover(isPresented: $isAddMenuPresented, arrowEdge: .trailing) {
                    VStack(alignment: .leading, spacing: 4) {
                        HoverButton {
                            isAddMenuPresented = false
                            withAnimation(.smooth(duration: 0.3)) {
                                showRecurrence = true
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "repeat")
                                Text("반복")
                            }
                            .font(.system(size: 12))
                            .frame(minWidth: 55, alignment: .leading)
                        }
                        .disabled(showRecurrence)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                }
            }
            
            HStack(spacing: 13) {
                if case .edit(let event) = mode {
                    HoverButton {
                        withAnimation(.smooth(duration: 0.25)) {
                            modelContext.delete(event)
                            onDismiss()
                        }
                    } label: {
                        HStack (spacing: 4) { Image(systemName: "trash"); Text("삭제") }
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 5)
                    }
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
                
                HoverButton {
                    withAnimation(.smooth(duration: 0.3)) {
                        onDismiss()
                    }
                } label: {
                    HStack (spacing: 4) { Image(systemName: "xmark.circle"); Text("취소") }
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 5)
                }
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.cancelAction)
                HoverButton {
                    if isAllDay {
                        startDate = Calendar.current.startOfDay(for: startDate)
                        endDate = Calendar.current.startOfDay(for: endDate)
                    }
                    
                    switch mode {
                    case .add:
                        let event = Event(name: trimmedName, isAllDay: isAllDay, category: selectedCategory,
                                          startDate: startDate, endDate: endDate)
                        modelContext.insert(event)
                    case .edit(let event):
                        event.name = trimmedName
                        event.isAllDay = isAllDay
                        event.category = selectedCategory
                        event.startDate = startDate
                        event.endDate = endDate
                    }
                    withAnimation(.smooth(duration: 0.3)) {
                        onDismiss()
                    }
                } label: {
                    HStack (spacing: 4) { Image(systemName: "checkmark"); Text("저장") }
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 5)
                }
                .disabled(!isSaveEnabled)
                .background(Color.accentColor.opacity(isSaveEnabled ? 1 : 0.4))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 25)
        .frame(width: 350)
        .background(.background)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y:8)
        .onChange(of: startDate) { _, newStart in
            if newStart > endDate {
                endDate = AddEventDialog.sameDayOneHourLater(after: newStart)
            }
        }
    }
    
    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(width: 50, alignment: .leading)
    }
}

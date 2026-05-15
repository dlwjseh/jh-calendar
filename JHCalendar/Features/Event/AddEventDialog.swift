import SwiftUI

enum EventDialogMode {
    case add
    case edit(Event)
}

struct AddEventDialog: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var isAllDay = false
    @State private var selectedCategory: Category? = nil
    @State private var startDate = Date()
    @State private var showStartPicker = false
    @State private var showStartTimePicker = false
    
    let mode: EventDialogMode
    let categories: [Category]
    var onDismiss: () -> Void
    
    init(mode: EventDialogMode, categories: [Category], onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.categories = categories
        self.onDismiss = onDismiss
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }
    private var isSaveEnabled: Bool {
        false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack(spacing: 5) {
                Image(systemName: "calendar.badge.plus")
                Text("이벤트 추가")
            }
            .font(.system(size: 14, weight: .bold))
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 19) {
                HStack(spacing: 5) {
                    Text("카테고리")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories) { category in
                                CategoryChip(selectedCategory: $selectedCategory, category: category)
                            }
                        }
                    }
                }
                
                HStack(spacing: 5) {
                    Text("이벤트명")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    TextField("이벤트명", text: $name)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(.background, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3), lineWidth: 1))
                }
                
                HStack(spacing: 5) {
                    Text("종일")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    Toggle("종일", isOn: $isAllDay)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                HStack(spacing: 5) {
                    Text("시작")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    
                    
                    Button {
                          showStartPicker.toggle()
                      } label: {
                          Text(startDate.formatted(
                                Date.FormatStyle()
                                    .year(.defaultDigits)
                                    .month(.twoDigits)
                                    .day(.twoDigits)
                                    .locale(Locale(identifier: "ko_KR"))
                            ))
                      }
                      .buttonStyle(.plain)
                      .popover(isPresented: $showStartPicker, arrowEdge: .bottom) {
                          DatePicker("", selection: $startDate, displayedComponents: .date)
                              .datePickerStyle(.graphical)
                              .labelsHidden()
                              .environment(\.locale, Locale(identifier: "ko_KR"))
                              .padding()
                      }
                    
                    BorderlessTimePicker()
                }
            }
            
            HStack(spacing: 13) {
                HoverButton {
                    withAnimation(.smooth(duration: 0.3)) {
                        onDismiss()
                    }
                } label: {
                    Text("취소")
                        .foregroundStyle(.primary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 7)
                }
                .background(Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .keyboardShortcut(.cancelAction)
                HoverButton {
                    switch mode {
                    case .add:
                        let event = Event(name: trimmedName, isAllDay: isAllDay, category: selectedCategory)
                        modelContext.insert(event)
                    case .edit(let event):
                        event.name = trimmedName
                        event.isAllDay = isAllDay
                        event.category = selectedCategory
                    }
                    withAnimation(.smooth(duration: 0.3)) {
                        onDismiss()
                    }
                } label: {
                    Text("저장")
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 7)
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
    }
}

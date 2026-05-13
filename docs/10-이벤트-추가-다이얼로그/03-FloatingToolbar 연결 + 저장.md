# 단계 3: FloatingToolbar `+` 연결 + 저장

## 작업 목표
- `FloatingToolbar` 의 `+` 버튼을 `eventDialog = .add` 로 연결.
- `ContentView` 에 `eventDialog` state 추가 후 09 와 같은 패턴으로 다이얼로그 + Backdrop 띄우기.
- 저장 버튼이 실제로 `Event` 인스턴스를 `selectedCategory.events` 에 등록.
- 추가된 이벤트가 재시작 후에도 유지되는지 확인.

> 새 Swift 개념은 없다. 09 의 **`@Binding` 으로 dialog state 끌어내리기 + `modelContext` 자동 저장** 패턴을 그대로 재적용.

## 사전 지식
- 09 산출물 — `folderDialog` / `categoryDialog` state 가 `ContentView` 에 있고, `Sidebar` 로 `@Binding` 으로 내려보낸 구조
- `@Binding`, `@State` → [01-타이틀바-호버표시](../01-타이틀바-호버표시/) · [09](../09-폴더-카테고리-데이터-영속화/) 참고
- `modelContext.insert(...)` vs `relationship.append(...)` → [09/05-카테고리 추가 저장.md](../09-폴더-카테고리-데이터-영속화/05-카테고리%20추가%20저장.md) 참고
- `DialogBackdrop` 패턴 → `JHCalendar/Features/Sidebar/DialogBackdrop.swift`

## 작업 가이드

### 등록 방식 — `category.events.append(event)` (A 방식)

09/05 에서 두 가지 등록 방식을 비교했는데, 이번에도 같은 결로 **A 방식** 으로 가는 게 일관:

```swift
let event = Event(name: trimmedName, isAllDay: isAllDay, category: selectedCategory)
selectedCategory.events.append(event)
// modelContext.insert 명시적 호출 불필요 — 관계로 연결된 새 인스턴스 자동 인식
```

> "왜 `category` 인자 + `append` 둘 다 하는지" — `init` 의 `category:` 가 한쪽을 잡고, `append` 가 반대쪽 컬렉션도 자동 갱신 (SwiftData 가 inverse 로 묶어줌). 한 줄만 써도 결과는 같지만, 09 의 양방향 안전 원칙대로 두 줄.

### 파일 변경 계획
- `ContentView.swift`
  - `@State private var eventDialog: EventDialogMode? = nil` 추가
  - 09 의 `if let mode = categoryDialog { ... }` 바로 아래에 같은 패턴으로 `if let mode = eventDialog { ... }` 블록 추가
  - `FloatingToolbar(isSidebarVisible: ...)` 호출에 `eventDialog: $eventDialog` 바인딩 전달
- `FloatingToolbar.swift`
  - `@Binding var eventDialog: EventDialogMode?` 추가
  - `+` 버튼의 `print(...)` → `withAnimation(.smooth(duration: 0.3)) { eventDialog = .add }`
- `AddEventDialog.swift`
  - 02 에서 비워둔 저장 액션 채우기
  - `@Environment(\.modelContext) private var modelContext` 추가 (현재 코드 경로엔 직접 안 쓰여도 추후 확장 대비 — 선택)
  - 09 의 `AddCategoryDialog` 저장 분기를 본떠 `switch mode` 처리

### 핵심 골격

```swift
// ContentView.swift 추가분
@State private var eventDialog: EventDialogMode? = nil

// ... ZStack 안, categoryDialog 처리 바로 아래 ...
if let mode = eventDialog {
    DialogBackdrop { eventDialog = nil }
        .transition(.opacity)
    AddEventDialog(
        mode: mode,
        folders: folders,
        onDismiss: { eventDialog = nil }
    ).transition(.opacity.combined(with: .scale(scale: 0.96)))
}
```

```swift
// FloatingToolbar.swift
@Binding var eventDialog: EventDialogMode?
// ...
HoverButton {
    withAnimation(.smooth(duration: 0.3)) {
        eventDialog = .add
    }
} label: {
    Image(systemName: "plus") ...
}
```

```swift
// AddEventDialog 저장 액션
HoverButton {
    switch mode {
    case .add:
        guard let category = selectedCategory else { return }
        let event = Event(name: trimmedName, isAllDay: isAllDay, category: category)
        category.events.append(event)
    case .edit(let event):
        event.name = trimmedName
        event.isAllDay = isAllDay
        event.category = selectedCategory
    }
    withAnimation(.smooth(duration: 0.3)) { onDismiss() }
} label: { Text("저장") ... }
```

### 막힐 만한 지점 — 힌트

- **다이얼로그가 떴다가 카테고리 옵션이 비어 있음** — `folders` 인자를 `ContentView` 에서 전달 안 했거나, `@Query` 가 비어 있을 가능성. 사이드바에 카테고리가 적어도 하나 보이는 상태인지 먼저 확인.
- **저장 후 사이드바엔 변화가 없어 보임** — 정상. 이벤트는 사이드바에 안 보이는 데이터 (월간 뷰에서 표시될 예정). 검증은 **재시작 후 다시 같은 카테고리에 이벤트가 살아 있는지** 로 — SwiftData 인스펙터(Xcode → Open Developer Tool → SwiftData) 또는 임시로 사이드바에 카테고리별 이벤트 개수를 표시해보는 방식.
- **`category.events` 에 append 했는데 `event.category` 가 nil 로 남음** — 보통 SwiftData 가 자동으로 연결해주지만, 안 풀리면 명시적으로 `event.category = category` 한 줄 더. 양방향 안전 원칙.
- **`+` 버튼 눌렀는데 다이얼로그가 안 뜸** — `FloatingToolbar` 에 `@Binding` 전달했는지, `ContentView` 의 `eventDialog` state 가 살아 있는지 점검. 09 의 `folderDialog`/`categoryDialog` 와 같은 줄에서 비교하면 빠르다.

## 직접 구현하기
- [ ] `ContentView` 에 `eventDialog` state + 다이얼로그/Backdrop 띄우기 블록 추가
- [ ] `FloatingToolbar` 가 `@Binding var eventDialog` 받고, `+` 클릭에서 `.add` 로 set
- [ ] `AddEventDialog` 저장 액션 채우기 — `.add` / `.edit` 두 분기
- [ ] 추가 → 다이얼로그 닫힘 + 재시작 시에도 이벤트 유지 확인
- [ ] 카테고리 선택 안 됐을 때 저장 비활성 (`isSaveEnabled` 점검)

## 자가 점검
- `+` 버튼 → 다이얼로그 등장(09 와 같은 부드러운 등장)?
- 카테고리 + 이벤트명 + (종일 토글) → 저장 → 다이얼로그 닫힘?
- 앱 재시작 후 같은 카테고리에 이벤트가 살아 있는가 (검증 방법은 위 막힐 만한 지점 참고)?
- 이해도 퀴즈
  1. `eventDialog` 를 `ContentView` 에 두고 `FloatingToolbar` 로 `@Binding` 으로 내려보내는 이유는? (왜 `FloatingToolbar` 안 `@State` 가 아닌지)
  2. 09 에서 `Folder` 삭제 시 카테고리는 `.cascade` 로 같이 죽었다. 이번 모델에서 `Category` 를 삭제하면 이벤트는 어떻게 되는가? — 01 단계의 `.nullify` 선택이 여기서 어떻게 드러나는지 머릿속으로 한 번 시뮬레이션.

## Claude 리뷰 체크리스트
- [ ] `ContentView` 의 dialog 블록 3개(folder/category/event)가 같은 패턴으로 일관
- [ ] `FloatingToolbar` 가 `eventDialog` 를 `@Binding` 으로 받고, 09 의 `withAnimation(.smooth(duration: 0.3))` 와 같은 톤으로 set
- [ ] 저장 분기 — `.add` 는 `category.events.append`, `.edit` 는 기존 인스턴스 mutation
- [ ] 재시작 후 영속화 검증

## 회고
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 이벤트 편집 진입점 — 월간 뷰에서 이벤트 셀을 클릭/contextMenu 로 `eventDialog = .edit(event)` 띄우기. 본 기능 범위 밖, 후속 기능에서.
- 이벤트가 사이드바에 카운트로 표시되면 학습 단계 검증이 쉬워짐 — 임시로 `Text("\(category.events.count)")` 를 `CategoryRow` 우측에 띄워봐도 좋음 (검증용, 커밋 전 제거).

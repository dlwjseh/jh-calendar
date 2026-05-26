# 단계 1: 상태 가변화 + prev/next 메서드 + 헤더 화살표

## 학습 목표
- `CalendarStore` 의 `referenceDate` / `gridInterval` 을 변경 가능한 reactive state 로 전환.
- `prevMonth()` / `nextMonth()` 메서드로 월 이동 시 그리드(`rows`, `gridInterval`)가 자동 재계산.
- 년월 헤더 좌우에 < > 버튼을 두어 클릭으로 월 이동 (애니메이션은 다음 단계).

## 사전 산출물
- `CalendarStore.swift`:
  ```swift
  final class CalendarStore: ObservableObject {
      @Published private(set) var rows: [[DayCell]] = []
      let referenceDate: Date           // ← 지금은 let
      let gridInterval: DateInterval    // ← 지금은 let
      init(referenceDate: Date = Date()) { ... }
  }
  ```
- `MonthlyCalendarView.swift` 년월 헤더 — 현재 `Text(...)` 단독.

## Swift / SwiftUI 개념

### `let → @Published var` 전환

`let` 은 init 시점에 한 번 정해지면 끝. 월 이동이 가능하려면 store 내부 메서드가 값을 바꿀 수 있어야 함 → `var`. 그리고 SwiftUI 가 변경을 감지하려면 `@Published`:

```swift
@Published private(set) var referenceDate: Date
@Published private(set) var gridInterval: DateInterval
```

- `private(set)` — 외부 read OK, write 는 store 안에서만. 메서드 (`prevMonth`, `nextMonth`) 를 통한 통제된 mutation 만 허용.
- `@Published` 가 붙은 property 가 변경되면 `ObservableObject` 의 publisher 가 트리거 → 이걸 watch 하는 `@StateObject` / `@ObservedObject` 의 view 가 재렌더. ([07-03](../07-사이드바-토글-다듬기/03-CalendarStore%20도입%20-%20ObservableObject.md) 참고)

> Vue 비유: `const referenceDate = ref(...)` + `readonly(referenceDate)` 로 외부 노출, mutation 은 store 내부에서만. Java 비유: `private final → private` + setter 메서드.

### 그리드 재계산을 한 곳에 모으기

기존 init 안에 흩어진 grid/rows 계산 로직을 별도 private 메서드로 추출해 init / prev / next 가 같은 경로를 쓰게:

```swift
private func rebuild(for date: Date) {
    let grid = makeDayCells(for: date)
    self.referenceDate = date
    self.gridInterval = grid.interval
    self.rows = stride(from: 0, to: grid.cells.count, by: 7).map { start in
        Array(grid.cells[start..<start + 7])
    }
}
```

세 줄을 set 하는 동안 `@Published` 가 세 번 emit 하지만, SwiftUI 의 갱신은 run loop 단위로 묶여 한 번에 처리되니 성능 걱정은 X.

## 구현 가이드

### 1) `CalendarStore` 수정
- `let referenceDate / gridInterval` → `@Published private(set) var ...`
- init 의 grid 계산을 `private func rebuild(for date: Date)` 로 추출, init 에서 호출
- `prevMonth()`, `nextMonth()` 메서드:

```swift
func prevMonth() {
    let prev = Calendar.current.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
    rebuild(for: prev)
}
func nextMonth() {
    // TODO: 위와 같은 패턴, value: 1
}
```

### 2) 헤더에 좌우 화살표

현재 `Text(...)` 한 줄을 `HStack` 으로 감싸고 좌우에 `Button { } label: { Image(systemName: ...) }`. 추천 아이콘은 `chevron.left` / `chevron.right`.

골격:
```swift
HStack(spacing: 20) {
    Button {
        store.prevMonth()
    } label: {
        Image(systemName: "chevron.left")
    }

    Text(Self.yearMonthFormatter.string(from: store.referenceDate))
        .font(.system(size: 24, weight: .bold))

    // TODO: 오른쪽 버튼
}
.buttonStyle(.plain)   // 기본 button chrome 제거
```

- `buttonStyle(.plain)` — macOS 의 기본 button 모양 (옅은 배경 + 테두리) 을 벗기고 icon 만 보이게.
- 호버 효과 원하면 기존 `HoverButton` 으로 대체 가능. 어느 쪽이든 일관성만 유지.

## 직접 구현하기
- [ ] `CalendarStore`: `let → @Published private(set) var` (referenceDate, gridInterval)
- [ ] init 의 grid 계산을 `rebuild(for:)` 로 추출, init 에서 호출
- [ ] `prevMonth()`, `nextMonth()` 메서드 추가
- [ ] 헤더를 `HStack` 으로 감싸고 < > 버튼 좌우 배치
- [ ] 버튼 클릭 시 월 이동 — 그리드 + 이벤트 즉시 갱신되는지 확인 (애니메이션은 아직 X)

## 자가 점검
- 빌드 통과?
- < 클릭 → 이전 달, > 클릭 → 다음 달. 그리드 + 이벤트 둘 다 갱신되는가?
- 연도 경계 (12월 → 1월, 1월 → 12월) 도 잘 넘어가는가? — `Calendar.date(byAdding: .month, value: ±1, ...)` 이 알아서 처리.
- 퀴즈: `@Published private(set)` 으로 한 이유가 뭐였지? 그냥 `@Published var` 와의 차이는?
- 퀴즈: `rebuild` 안에서 세 property 를 연속 set 하는데, view 가 세 번 다시 그려질까?

## Claude 리뷰 체크리스트
- [ ] `referenceDate`, `gridInterval` 둘 다 `@Published private(set) var`
- [ ] init 의 grid 계산 로직이 `rebuild(for:)` 로 추출되어 init / prev / next 가 같은 경로 사용
- [ ] prev/next 가 `Calendar.date(byAdding: .month, value: ±1, to:)` 사용
- [ ] 헤더 버튼이 `buttonStyle(.plain)` 또는 유사한 minimal chrome (또는 `HoverButton`)
- [ ] 월 이동 시 그리드/이벤트 갱신 (reactive 흐름 정상)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- "오늘" 버튼 — `func today() { rebuild(for: Date()) }` 한 줄 + 헤더에 추가.
- 키보드 단축키 `⌘←` / `⌘→` / `⌘T` — `.keyboardShortcut(.leftArrow, modifiers: .command)` 등 macOS 캘린더 표준.
- "yyyy년 M월" 클릭 시 월 선택 popover — `DatePicker(..., displayedComponents: [.date]).datePickerStyle(.graphical)`.

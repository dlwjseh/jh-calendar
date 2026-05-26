# 월 이동

## 목표
달력의 표시 월을 이전/다음으로 전환. 년월 헤더 좌우의 < > 화살표 버튼이 트리거이며, 달이 바뀔 때 방향성 있는 슬라이드 애니메이션이 깔린다.

## 의존 관계
- 사전 필요:
  - `05-월간-달력-UI` — `CalendarStore`, `makeDayCells`, `MonthlyCalendarView` 의 헤더/그리드 구조
  - `07-3` — `ObservableObject`, `@Published`, `@StateObject` ([07-03](../07-사이드바-토글-다듬기/03-CalendarStore%20도입%20-%20ObservableObject.md))
  - `자주-쓰는-기술들/Calendar-와-Date` — `Calendar.date(byAdding:value:to:)` ([Calendar-와-Date](../자주-쓰는-기술들/Calendar-와-Date.md))
  - `15-3` — `withAnimation` + `.transition` 협력, `.animation(_:value:)` ([15-03](../15-이벤트-삭제/03-삭제-애니메이션.md))
- 이후 영향: 없음 (leaf)

## 단계 체크리스트
- [x] 01 - 상태 가변화 + prev/next 메서드 + 헤더 화살표 버튼
- [ ] 02 - 방향성 있는 슬라이드 애니메이션

## 이 기능에서 학습할 Swift / SwiftUI 개념

**새로 등장**:
- `let → @Published var` 전환 — 같은 `ObservableObject` 안에서 불변 property 를 reactive 한 가변 state 로 승격. (Vue 의 `const x = ref(...)` 에서 `x.value` 를 mutate 가능하게 만드는 결.)
- `.transition(.asymmetric(insertion:removal:))` — 들어오는 효과와 나가는 효과를 분리. (15-3 "조금 더" 에만 언급됐던 것을 본격 사용.)
- `.id(value)` — view 에 explicit identity 부여. value 가 바뀌면 SwiftUI 가 "다른 view" 로 보고 기존 제거 + 새 view 삽입 → transition 트리거하는 트릭.

**다시 쓰는 개념** (링크):
- `ObservableObject`, `@StateObject`, `@Published` → [07-03](../07-사이드바-토글-다듬기/03-CalendarStore%20도입%20-%20ObservableObject.md)
- `Calendar.date(byAdding:value:to:)` → [Calendar-와-Date](../자주-쓰는-기술들/Calendar-와-Date.md)
- `withAnimation` + `.transition` 협력 → [15-03](../15-이벤트-삭제/03-삭제-애니메이션.md)
- `Button { } label: { Image(systemName: ...) }` → 여러 곳에서 다룸

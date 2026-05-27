# 오늘 표시 + 오늘 버튼

## 목표
달력 그리드의 **오늘 날짜 셀**을 시각적으로 강조하고, 상단 툴바에 **"오늘"** 버튼을 추가해 클릭 시 오늘이 있는 달로 즉시 돌아온다. 다른 달에서 클릭하면 16-2 의 슬라이드가 자연스럽게 재사용된다.

## 의존 관계
- 사전 필요:
  - `05-월간-달력-UI` — `DayCellView`, `DayCell` 구조
  - `16-월-이동` — `CalendarStore` 의 `rebuild(for:)` 단일 진입점, `direction` 배칭 회피 패턴 ([16-01](../16-월-이동/01-상태-가변화-prev-next-버튼.md), [16-02](../16-월-이동/02-슬라이드-애니메이션.md))
  - `02-상단-플로팅-툴바` — `FloatingToolbar`, `HoverButton`
  - `자주-쓰는-기술들/Calendar-와-Date` — `Calendar.isDateInToday(_:)`, `isDate(_:equalTo:toGranularity:)` ([Calendar-와-Date](../자주-쓰는-기술들/Calendar-와-Date.md))
- 이후 영향: 없음 (leaf)

## 단계 체크리스트
- [x] 01 - 오늘 셀 강조 (DayCellView)
- [x] 02 - "오늘" 버튼 (FloatingToolbar + CalendarStore.today)

## 이 기능에서 학습할 Swift / SwiftUI 개념

**새로 등장**:
- `Circle()` shape primitive 를 **배경 레이어**로 깔기 — `.background { Circle().fill(...) }`. (이전엔 WeekRowView 의 multiday bar 내부 dot 용으로 한 번 등장했을 뿐, "셀 배경으로 강조" 용도는 처음.)
- **조건부 view 합성 패턴** — "오늘만 추가 layer" 같은 경우 `if cond { 뷰 }` 를 `.background` / `.overlay` 안에 넣어 분기. (요일 색 분기처럼 값을 바꾸는 게 아니라 **레이어 자체가 있을 수도/없을 수도** 있는 케이스.)
- **여러 시각 규칙의 우선순위 결정** — 오늘 = 주말 일 때 글자색을 흰색으로 덮을지, 빨강을 유지할지. switch 로 다 갈리는 logic 을 어떻게 깔끔히 짤지.

**다시 쓰는 개념** (링크):
- `Calendar.isDateInToday(_:)`, `isDate(_:equalTo:toGranularity:)` → [Calendar-와-Date 3-7, 3-8](../자주-쓰는-기술들/Calendar-와-Date.md)
- `CalendarStore.rebuild(for:)` 단일 진입점 → [16-01](../16-월-이동/01-상태-가변화-prev-next-버튼.md)
- `direction` 세팅 + `DispatchQueue.main.async { withAnimation { rebuild } }` 두 패스 분리 → [16-02 함정 ①](../16-월-이동/02-슬라이드-애니메이션.md)
- `HoverButton`, `FloatingToolbar` 슬롯 추가 → [02-상단-플로팅-툴바](../02-상단-플로팅-툴바/README.md)

# 단계 12: 멀티데이 바 클릭 → `.edit` 진입

> 새 개념 없음. [12-04](../12-일-팝업/04-이벤트클릭-수정-프리필완성.md) 와 [13-4](../13-이벤트-다이얼로그-마무리/04-수정모드-타이틀.md) 에서 만든 **`.edit(Event)` 모드 진입 경로** 를 멀티데이 바에서도 재사용.

## 작업 목표
멀티데이 바 어디를 클릭해도 (어느 토막이든) 해당 이벤트의 **수정 다이얼로그** 가 열린다.

## 사전 산출물
- `AddEventDialog(mode: .edit(event), ...)` — 이미 12-04 / 13-4 에서 완성.
- 어디서 다이얼로그를 띄울지: 11번 팝업에서는 `eventToEdit: Event?` 같은 상태로 띄웠다. 멀티데이 클릭에서도 같은 진입 경로를 쓰면 일관성 OK.

## 작업 가이드

**1) 상태 끌어올리기 — 어디까지 올릴까**

`WeekRowView` 가 자체 `@State eventToEdit: Event?` 를 들고 다이얼로그를 띄울 수도 있지만, 더 자연스러운 위치는 **`MonthlyCalendarView` 또는 더 상위** (현재 일 팝업 띄우는 곳과 같은 레벨).

이미 캘린더 그리드 어디서든 클릭 시 다이얼로그가 나와야 하므로, 다이얼로그 컨테이너는 **루트 가까이** 두는 게 좋다. 현재 구조 (12 일 팝업) 를 보고 동일 패턴.

```swift
// MonthlyCalendarView 또는 그 상위에
@State private var eventToEdit: Event?

// ...
WeekRowView(...,
            onSelectMultiday: { event in
                withAnimation(.smooth(duration: 0.2)) {
                    eventToEdit = event
                }
            })
```

> 12 일 팝업의 `dayPopup` 처럼 옵셔널 바인딩 + 비-nil 일 때 다이얼로그 렌더링.

**2) 멀티데이 바에 `.onTapGesture`**

```swift
.background(UnevenRoundedRectangle(...).fill(laned.event.color))
.offset(x: f.x, y: 24 + CGFloat(laned.lane) * (16 + 2))
.contentShape(Rectangle())              // 빈 영역까지 hit-test
.onTapGesture { onSelectMultiday(laned.event) }
.pointerStyle(.link)                    // 손모양 (13-3 와 동일 일관성)
```

- **`.contentShape(Rectangle())`** — `.background` 만 있고 명시적 `Shape` 가 없는 컨테이너에 hit-test 영역을 명시. 13-3 카테고리 칩에서도 같은 결로 썼음.
- **`.pointerStyle(.link)`** — 일 팝업 행, 카테고리 칩과 동일 → 클릭 가능 시각 단서 일관.

**3) 셀 클릭과의 충돌**

멀티데이 바는 셀 위에 overlay 로 얹혀 있으니 같은 화면 좌표를 셀이 차지하고 있다. SwiftUI 의 hit-test 는 **상위(=overlay) 가 우선** 이라 자동으로 멀티데이 바 클릭이 먼저 잡힘. 단, 다음을 확인:

- 셀의 `.onTapGesture { onSelectDay(...) }` 가 멀티데이 바 영역의 클릭도 받아 일 팝업이 같이 열리면 안 됨 → SwiftUI 의 hit-test 가 상위 우선이라 보통 OK.
- 만약 충돌이 보이면 멀티데이 바 쪽에 `.allowsHitTesting(true)` (기본) 와 셀 `.onTapGesture` 의 우선순위 확인. 셀에 `.simultaneousGesture` 가 있는지도 점검.

**4) 호버 강조 (선택)**

카테고리 칩 (13-3) 처럼 호버 강조를 더하면 클릭 가능성이 더 명확:

```swift
.brightness(isHoveredThisBar ? 0.05 : 0)
.onHover { isHoveredThisBar = $0 }
```

각 바마다 `@State` 가 필요해 다소 번거로움 — 학습 범위 외 옵션.

## 직접 구현하기
- [ ] 상위 View 에 `@State var eventToEdit: Event?` (또는 동등 패턴)
- [ ] `WeekRowView` 에 `onSelectMultiday: (Event) -> Void` 콜백 prop 추가
- [ ] 멀티데이 바에 `.contentShape(Rectangle()) + .onTapGesture + .pointerStyle(.link)`
- [ ] 클릭 → `AddEventDialog(mode: .edit(event), ...)` 가 열리는지 확인
- [ ] 다이얼로그가 닫히면 상태가 nil 로 돌아가는지

## 자가 점검
- 빌드 통과?
- 멀티데이 바 어디(시작/중간/끝 토막)를 눌러도 같은 이벤트의 수정 다이얼로그가 열리나?
- 다이얼로그 헤더가 "이벤트 수정" 으로 (13-4)?
- 카테고리/시작·종료일/이름이 모두 프리필? (12-04 의 검증과 같은 셋업)
- 같은 칸의 빈 영역(멀티데이 바 밖, 단일 일 영역) 을 클릭하면 셀 → 일 팝업으로 가나? (충돌 없음)
- 퀴즈: 멀티데이 바 hit-test 우선순위가 셀보다 높은 이유는 SwiftUI 의 어떤 동작 원리 때문인가?

## Claude 리뷰 체크리스트
- [ ] `.onTapGesture` 와 `.pointerStyle(.link)` 둘 다 부착 (13-3 / 12-04 와 동일 패턴)
- [ ] `.contentShape(Rectangle())` 로 hit-test 영역 명시
- [ ] `eventToEdit` 상태는 상위에 둬 다이얼로그가 그리드 어디서든 일관 표시
- [ ] 셀 `onSelectDay` 와의 충돌 없음

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **드래그로 멀티데이 이동/리사이즈** — 본격적인 캘린더 앱의 다음 단계. `DragGesture` + 셀 너비 단위 스냅 + 좌/우 끝에서만 리사이즈 핸들 식. 별도 기능으로 분리 추천.
- **컨텍스트 메뉴** — 마우스 우클릭으로 "수정/삭제/복제" 같은 메뉴. `.contextMenu { ... }` 한 줄로 시작 가능.

# 일 팝업 (Day Popup)

## 목표
달력의 하루(day) 셀을 다루는 인터랙션을 완성한다.

1. 일 셀에 **마우스 오버 → 셀 배경색 변경**
2. 일 셀 **클릭 → 그 날의 이벤트 목록 모달**(날짜 헤더 + 색점·이름·시각)
3. 모달 우상단 **`＋` → 이벤트 추가 다이얼로그**(시작/종료일 = 그 날짜로 프리필)
4. 모달의 **이벤트 클릭 → 수정 다이얼로그**(`.edit` 폼 프리필까지 완성)

> 팝업은 **중앙 모달** 방식 — 기존 `AddEventDialog` 처럼 `ContentView` 의 상태 + `DialogBackdrop` + 카드. (사용자 결정)

## 의존 관계
- 사전 필요:
  - `11-달력-이벤트-표시` — `DayCellView(events:)`, `eventsByDay` 순수함수, `Event` 모델
  - `10-이벤트-추가-다이얼로그` — `AddEventDialog`, `EventDialogMode(.add/.edit)`, `ContentView` 의 `eventDialog` 모달 패턴
- 이후 영향:
  - **멀티 데이 일정 렌더링** (11-06 로드맵) — 그 다음 차례
  - 이번에 `.edit` 폼 프리필이 닫히면서 11-01 의 "후속: `.edit` 프리필" 항목도 같이 종료

## 단계 체크리스트
- [x] 01 - 일 셀 호버 배경 — *`@State isHovered` + `.onHover`(체인 끝, 02 탭 영역과 일치) + `.background` 테두리 안쪽. 강조 0.03(은은).*
- [x] 02 - 일 클릭 → 일 팝업 모달 (이벤트 목록) — *`onSelectDay` 클로저로 상태 끌어올리기 + `DayPopupDialog` `init` 에서 동적 `@Query` (`[dayStart, dayEnd)` 범위 `#Predicate`). 카드/헤더 레이아웃·종일 우측 표기·빈 상태 정렬은 사용자 취향 유지.*
- [ ] 03 - 팝업 `＋` → 이벤트 추가 (그 날짜 프리필)
- [ ] 04 - 이벤트 클릭 → 수정 다이얼로그 (`.edit` 프리필 완성)

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **상태 끌어올리기**: 깊은 자식(`DayCellView`)의 클릭을 `@Binding` 으로 `ContentView` 까지 전달 (`FloatingToolbar` 의 `eventDialog` 바인딩과 같은 패턴을 일반화)
- **`@State` 를 `init` 에서 초기화**: `_startDate = State(initialValue:)` — 프로퍼티 래퍼의 밑줄(`_`) 접근
- **enum 연관값으로 의도+데이터 함께 전달**: `.add(Date)` / `.edit(Event)`
- 버튼이 아닌 뷰를 탭 가능하게: `contentShape` + `onTapGesture`
- 리프 다이얼로그가 **자체 `@Query` 로 범위 한정 조회** (`eventsByDay` 순수함수 재사용 — 11 의 "멍청한 셀" 철학 유지)
- (선택) 음력 표기 — `Calendar(identifier: .chinese)`

## 설계 한눈에 (상태 흐름)

```
DayCellView (.onTapGesture)
        │  날짜 1개를 위로
        ▼  @Binding
MonthlyCalendarView ──@Binding──▶ ContentView
                                     │  @State dayPopup: Date?
                                     ▼  (기존 eventDialog 와 동형)
                          DialogBackdrop + DayPopupDialog(date:)
                                     │            │
                            onAddEvent(date)   onEditEvent(event)
                                     ▼            ▼
                          eventDialog = .add(date) / .edit(event)
                                     ▼
                              AddEventDialog  ← @State 를 init 에서 프리필
```

핵심: 팝업/다이얼로그 **상태는 전부 `ContentView` 한 곳**(기존 패턴 유지). 셀은 "어떤 날을 눌렀다"만 위로 올리고 직접 모달을 띄우지 않는다(11 의 멍청한 셀 원칙 연장).

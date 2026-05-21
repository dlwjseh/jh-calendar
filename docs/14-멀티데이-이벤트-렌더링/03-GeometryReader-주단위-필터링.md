# 단계 3: `GeometryReader` 로 행 너비 측정 + 주 단위 멀티데이 필터링

## 학습 목표
- 부모가 자식에게 준 공간 크기를 측정할 수 있게 된다 (`GeometryReader`).
- 한 주 안에 "보여야 할 멀티데이 이벤트" 만 골라내는 **순수 함수** 를 분리한다.

## 사전 지식
- 02 단계의 `WeekRowView` 가 있어야 함.
- `Calendar` / `startOfDay` / `dateInterval(of:.weekOfYear, for:)` → [자주-쓰는-기술들/Calendar-와-Date.md](../자주-쓰는-기술들/Calendar-와-Date.md)

## Swift / SwiftUI 개념

### `GeometryReader`

부모가 자신에게 준 사이즈(폭·높이) 를 **자식에게 알려주는 컨테이너**. 일종의 "내가 받은 공간이 얼마인가요?" 질의를 해주는 View.

```swift
GeometryReader { geo in
    // geo.size.width  : 부모가 내게 준 가로 폭
    // geo.size.height : 가로 세로
    // geo.frame(in: .local | .global) : 좌표
    Text("내 너비: \(geo.size.width)")
}
```

> CSS 의 `ResizeObserver` / JS 의 `getBoundingClientRect()` 와 비슷한 결. 차이: SwiftUI 는 선언적이라 측정값을 **그 자리에서 자식 레이아웃에 바로** 쓸 수 있다.

**중요 특징 / 함정**:
1. **`GeometryReader` 자체가 가능한 가장 큰 공간을 먹는다.** 부모가 `.frame(maxHeight: .infinity)` 같이 늘어나는 환경이면 `GeometryReader` 도 그만큼 차지함. 의도와 다르게 너무 커질 수 있다.
2. 위 1번 때문에, **자식의 자연 크기로 줄어들지 않는다.** 그래서 보통은 "이미 크기가 결정된 컨테이너" 안에서 측정용으로만 쓴다.
3. 우리의 사용처는 안전한 케이스 — `WeekRowView` 가 어차피 가로로 전체 너비, 세로로 한 주 공간을 차지하므로 그 안에 `GeometryReader` 가 들어가도 영향 없음.

```swift
struct WeekRowView: View {
    // ...
    var body: some View {
        GeometryReader { geo in
            let rowWidth = geo.size.width
            HStack(spacing: 0) {
                ForEach(row) { cell in /* 기존 */ }
            }
            // 디버그용으로 잠깐 표시 가능:
            // .overlay(alignment: .topTrailing) {
            //     Text("\(Int(rowWidth))px / \(weekMultidays.count)개")
            //         .font(.system(size: 9)).foregroundStyle(.secondary)
            // }
        }
    }
}
```

### 순수 함수로 "이 주의 멀티데이" 필터링

`eventsByDay` 가 셀별 단순 조회용이라면, **주 단위 overlay 용 인덱스** 는 별도로 만든다. 이유:
- 셀용 인덱스에 있는 단일 일 이벤트는 overlay 대상이 아니다.
- 주 단위로 묶어 lane 배치(08) / 토막(07) 등 추가 가공을 하려면 입력 형태가 "주 → [멀티데이 이벤트]" 가 편하다.

```swift
/// 멀티데이 여부 — startOfDay 기준 시작일과 종료일이 다른 날이면 멀티데이.
func isMultiday(_ event: Event, calendar cal: Calendar = .current) -> Bool {
    cal.startOfDay(for: event.startDate) != cal.startOfDay(for: event.endDate)
}

/// 주어진 주(week) 와 겹치는 멀티데이 이벤트들.
func multidayEvents(in weekInterval: DateInterval,
                    from events: [Event],
                    calendar cal: Calendar = .current) -> [Event] {
    events.filter { isMultiday($0, calendar: cal) }
          .filter { event in
              let eventInterval = DateInterval(start: event.startDate, end: event.endDate)
              return weekInterval.intersects(eventInterval)
          }
}
```

- 두 함수 모두 **순수**. `EventIndex.swift` 옆에 같이 두면 자연스럽다.
- `weekInterval` 은 `cal.dateInterval(of: .weekOfYear, for: row.first!.date)!` 로 얻을 수 있다.

## 구현 가이드

**1) `EventIndex.swift` 에 두 함수 추가**

위 두 함수를 그대로. `isMultiday` 는 다음 단계들에서도 셀 분기(05) 에 재사용.

**2) `WeekRowView` 에 `GeometryReader` 감싸기**

```swift
var body: some View {
    GeometryReader { geo in
        // TODO: rowWidth = geo.size.width
        // TODO: 이 주의 시작일 → weekInterval
        // TODO: multidayEvents(in: weekInterval, from: ?) — 아직 events 를 prop 으로 안 받음

        HStack(spacing: 0) {
            ForEach(row) { cell in /* 기존 */ }
        }
        // (선택) 디버그 overlay
    }
}
```

**3) `WeekRowView` 가 멀티데이 입력을 받아야 한다**

지금까지 `eventsByDayIndex: [Date: [Event]]` 만 prop 으로 받았는데, 주 단위 필터링을 하려면 **원본 `[Event]` 리스트** 도 필요. 또는 부모가 미리 주 단위로 잘라서 넘기는 방식이 더 깔끔.

→ **부모(`MonthlyCalendarView`) 가 주별 멀티데이 사전을 한 번 만들어** 자식에 넘기는 게 11번의 "셀은 멍청하게" 와 같은 결.

```swift
// MonthlyCalendarView 에 파생 프로퍼티 추가
private var multidaysByWeek: [Date: [Event]] {
    var result: [Date: [Event]] = [:]
    for row in store.rows {
        guard let firstCell = row.first,
              let week = calendar.dateInterval(of: .weekOfYear, for: firstCell.date) else { continue }
        result[week.start] = multidayEvents(in: week, from: events, calendar: calendar)
    }
    return result
}
```

```swift
// 호출부
WeekRowView(row: row,
            eventsByDayIndex: eventsByDayIndex,
            weekMultidays: multidaysByWeek[calendar.startOfDay(for: row.first!.date)] ?? [],
            onSelectDay: { ... })
```

> 키를 `week.start` 로 정규화. `row.first!.date` 는 그 주의 첫 셀 = 일요일 0시일 가능성이 높지만, 안전하게 `startOfDay` 로 한 번 더 정규화.

**4) (선택) 디버그 overlay 로 확인**

당장 다음 단계에서 실제 바를 그릴 거지만, 이번 단계 끝에 "측정과 필터링이 잘 됐는지" 만 확인하고 싶다면 임시 `.overlay` 한 줄:

```swift
.overlay(alignment: .topTrailing) {
    Text("w=\(Int(rowWidth)) m=\(weekMultidays.count)")
        .font(.system(size: 9))
        .foregroundStyle(.secondary)
        .padding(2)
}
```

다음 단계로 가기 전에 지워도 OK.

## 직접 구현하기
- [x] `isMultiday(_:)`, `multidayEvents(in:from:)` 를 `EventIndex.swift` 에 추가
- [x] `MonthlyCalendarView` 에 `multidaysByWeek` 파생 프로퍼티 추가
- [x] `WeekRowView` 에 `weekMultidays: [Event]` prop 추가
- [x] `WeekRowView` body 를 `GeometryReader` 로 감싸고 `rowWidth` 얻기
- [ ] (선택) 디버그 overlay 로 측정값/필터 결과 확인
- [x] 시각: 단계 1~2 와 동일 (멀티데이는 아직 토막바 상태) + 모서리에 디버그 텍스트(선택)

## 자가 점검
- 빌드 통과?
- `geo.size.width` 가 화면 너비 - 좌우 패딩과 일치하나? (수치 어림 확인)
- 멀티데이 이벤트 하나 만들었을 때, 그 이벤트가 걸치는 주들에서 `weekMultidays.count` 가 1 이상으로 잡히는지?
- 같은 주에 단일 일 이벤트만 있으면 `weekMultidays.count == 0` 인지?
- 퀴즈: `GeometryReader` 를 `HStack { ForEach }` 안쪽에 두면 어떻게 되나? (셀 너비 측정엔 어떤 차이?)

## Claude 리뷰 체크리스트
- [x] `isMultiday`, `multidayEvents(in:)` 순수 함수로 분리 (View 안에 박지 않음)
- [x] `multidaysByWeek` 의 키가 `week.start` 또는 `startOfDay` 로 정규화
- [x] `GeometryReader` 안에서 `rowWidth` 변수로 명시적 보관 (다음 단계 좌표 계산 준비)
- [x] 디버그 overlay 는 임시 — 다음 단계에서 실제 바로 대체

## 리뷰 노트
- 1차 제출에서 `dateInterval(of: .weekday, ...)` 오타 → `.weekOfYear` 로 수정. `.weekday` 는 "요일(1~7)" 컴포넌트라 주 인터벌이 안 나옴 — 동작이 조용히 비어버리는 함정.

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- iOS 16+ / macOS 13+ 부터는 **`Layout` 프로토콜** 로 더 정교한 측정·배치 가능. `GeometryReader` 는 가장 가볍고 흔한 방식.
- **`onGeometryChange(for:of:)`** (macOS 15+) 또는 **`PreferenceKey`** 로 측정값을 부모로 올려 보낼 수도 있다. 지금은 자식 안에서 다 끝나니 불필요.

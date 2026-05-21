# 단계 1: `eventsByDay` 를 멀티데이까지 확장

> 새 개념 없음. [11-03 날짜별 인덱스](../11-달력-이벤트-표시/03-날짜별-인덱스-성능핵심.md) 에서 "멀티데이 확장 지점" 으로 미리 격리해 둔 **`eventsByDay` 한 곳만** 손댄다.

## 작업 목표
멀티데이 이벤트가 **start~end 사이의 모든 날 키** 에 등록되어 각 셀이 자기 날짜에서 O(1) 로 가져갈 수 있게 한다.

- 단일 일 이벤트 (`startOfDay(start) == startOfDay(end)`) → 한 키에만 (지금과 동일)
- 멀티데이 이벤트 → 시작일~종료일 사이 모든 날에 각각

## 사전 산출물
- [`JHCalendar/Features/MonthlyCalendar/EventIndex.swift`](../../JHCalendar/Features/MonthlyCalendar/EventIndex.swift) — 현재 `Dictionary(grouping:)` 한 줄.
- `Event` 모델에 `startDate` / `endDate` 가 이미 있다.

## 작업 가이드

**1) 왜 `Dictionary(grouping:)` 으로 못 하나**

`Dictionary(grouping:by:)` 는 **한 원소를 한 키에만** 넣는다. 멀티데이는 N개 키에 같은 이벤트가 들어가야 하므로 grouping 만으론 부족하다 → 직접 루프.

```swift
func eventsByDay(_ events: [Event], calendar cal: Calendar = .current) -> [Date: [Event]] {
    var result: [Date: [Event]] = [:]
    for event in events {
        // TODO: startOfDay(startDate) 부터 startOfDay(endDate) 까지 1일씩 더하며
        // TODO: 각 key 에 event 를 append
    }
    return result
}
```

**2) 종료일 포함 여부**

- "5/20 09:00 ~ 5/22 15:00" 이벤트는 **5/20, 5/21, 5/22 세 칸** 모두 보여야 한다 → **종료일 포함**.
- 비교는 `startOfDay(endDate)` 기준. 시/분/초가 어떻든 그 날 0시까지 키를 등록.

```swift
let startKey = cal.startOfDay(for: event.startDate)
let endKey   = cal.startOfDay(for: event.endDate)
var day = startKey
while day <= endKey {
    result[day, default: []].append(event)
    day = cal.date(byAdding: .day, value: 1, to: day)!   // 다음 날
}
```

> `result[day, default: []]` — `Dictionary` 의 subscript-with-default 패턴. Java `computeIfAbsent(k, _ -> new ArrayList<>()).add(v)` 와 같은 결.

**3) 무한 루프 방지 (옵셔널 풀기)**

`cal.date(byAdding:value:to:)` 는 옵셔널을 반환한다. 그레고리력에서 +1일 실패는 거의 없지만, `!` 대신 `guard let next = ... else { break }` 로 풀어두면 안전.

## 직접 구현하기
- [ ] `eventsByDay` 본문을 grouping 한 줄 → 직접 루프로 교체
- [ ] 단일 일 이벤트도 (start == end) 정상 동작하는지 확인 (1회 append 로 끝)
- [ ] 빌드 통과 후 앱 실행

## 자가 점검
- 빌드 통과?
- 멀티데이 이벤트 하나 추가 (예: 오늘 ~ 모레) → **세 칸**에 모두 표시되는지?
- 단일 일 이벤트는 여전히 한 칸에만 나오는지?
- 멀티데이가 종일이 아닌 시간지정이어도 동일하게 세 칸에 나오는지? (이번 단계에선 isAllDay 분기 없음)
- 퀴즈: `cal.startOfDay` 를 안 거치고 그냥 `event.startDate` 부터 1일씩 더했을 때 어떤 문제가 생기나?

## Claude 리뷰 체크리스트
- [ ] grouping 한 줄 → 명시적 루프로 깔끔하게 교체
- [ ] `startOfDay` 양쪽에 적용해 키가 항상 같은 시각(0시) 으로 정규화
- [ ] 종료일 포함 (`while day <= endKey`)
- [ ] 무한 루프 안전 (옵셔널 처리)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 만약 멀티데이가 매우 길면 (예: 1년) 키 N개를 추가하는 비용이 든다. 캘린더 앱에선 보통 표시 그리드 범위(`gridInterval`) 안으로 클램프해서 키를 만들면 더 안전. 이번 범위에선 짧은 멀티데이만 가정하므로 생략.

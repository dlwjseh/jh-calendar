# Calendar 와 Date 다루기

> Swift 에서 "시각" 을 표현하는 `Date` 와, "달력의 규칙(연/월/일/요일 등)" 을 알고 있는 `Calendar` 의 분업 구조. Java 의 `Instant` ↔ `ZonedDateTime` / `LocalDate` 관계와 비슷하다.

---

## 1. `Date` 는 그냥 "시점" 이다

`Date` 는 **타임존도, 달력도 모르는 절대 시각** 한 개. 내부적으론 2001-01-01 00:00:00 UTC 로부터의 초(`TimeInterval` = `Double`)다.

```swift
let now = Date()              // 지금 이 순간
print(now)                    // 2026-05-20 11:32:01 +0000 (UTC 로 출력)
print(now.timeIntervalSince1970)
```

> Java 비유: `java.time.Instant`.
> **`LocalDate` / `LocalDateTime` / `ZonedDateTime` 같은 게 따로 없다.** "2026년 5월 20일" 같은 사람 단위 표현은 `Date` 자체가 아니라 **`Calendar` 가 해석해서 꺼내는** 것.
> JS 비유: `Date` 가 timestamp 하나만 들고 있다는 점은 같음. 차이는 Swift `Date` 는 더 가볍고 (포맷/연산 기능 없음), 그 일은 전부 `Calendar` / `DateFormatter` 가 한다.

핵심: **`Date` 단독으로는 "이 날짜의 요일" 같은 걸 알 수 없다.** 반드시 `Calendar` 가 필요하다.

```swift
let weekday = Calendar.current.component(.weekday, from: now)   // 1~7 (일~토)
```

---

## 2. `Calendar` 는 도구상자

`Calendar.current` 가 사용자 시스템 설정(달력 종류 / 타임존 / 로케일) 을 따르는 기본 캘린더.

```swift
let cal = Calendar.current
```

이 프로젝트는 전부 `Calendar.current` 를 쓴다. 그래도 의미는 알아두자:

| 속성 | 무엇 |
|---|---|
| `cal.identifier` | `.gregorian`, `.iso8601` 등. 국내 사용자는 보통 그레고리력 |
| `cal.timeZone` | 시각 ↔ 연/월/일 변환 시 쓰는 타임존 |
| `cal.locale` | 요일 이름 같은 표시용 (계산에는 영향 X) |
| `cal.firstWeekday` | 1=일요일 (US/KR 기본), 2=월요일 (유럽 일부) |

> "테스트할 때 타임존 고정하고 싶다" 같은 상황엔 `var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "Asia/Seoul")!` 처럼 새로 만들어 쓴다.

### `Calendar.Component`

대부분의 메서드가 받는 enum. **자주 쓰는 것만:**
`.year` `.month` `.day` `.hour` `.minute` `.second` `.weekday` `.weekOfYear`.

---

## 3. 이 프로젝트에서 실제로 쓰는 패턴

전부 [`CalendarMath.swift`](../../JHCalendar/Features/MonthlyCalendar/CalendarMath.swift), [`EventIndex.swift`](../../JHCalendar/Features/MonthlyCalendar/EventIndex.swift), [`DayPopupDialog.swift`](../../JHCalendar/Features/Event/DayPopupDialog.swift) 에서 발췌.

### 3-1. 특정 컴포넌트 뽑기 — `component(_:from:)`

```swift
let day = cal.component(.day, from: date)         // 20
let weekday = cal.component(.weekday, from: date) // 1=일 … 7=토
```

⚠️ `.weekday` 는 **1-base, 일요일=1**. JS `getDay()` 와 같음.
Java `DayOfWeek.MONDAY.getValue() == 1` 과 **다름**.

### 3-2. "이 달의 첫날" — `dateInterval(of:for:)`

```swift
let firstOfMonth = cal.dateInterval(of: .month, for: referenceDate)!.start
```

`.month` 자리에 `.day` / `.weekOfYear` / `.year` 도 가능.
반환은 옵셔널 `DateInterval?` 이지만 그레고리력에서 실패할 일이 거의 없어 `!` 로 푸는 게 관용.

### 3-3. "이 달의 일수" — `range(of:in:for:)`

```swift
let daysInMonth = cal.range(of: .day, in: .month, for: firstOfMonth)!.count
// 28 / 29 / 30 / 31
```

> Java 의 `YearMonth.from(date).lengthOfMonth()` 와 같은 결.

### 3-4. 날짜 더하기/빼기 — `date(byAdding:value:to:)`

```swift
let tomorrow  = cal.date(byAdding: .day, value:  1, to: today)!
let lastWeek  = cal.date(byAdding: .day, value: -7, to: today)!
let nextMonth = cal.date(byAdding: .month, value: 1, to: today)!
```

⚠️ **단순 산술이 아니다.** DST(서머타임) / 윤년 / 월말 처리를 캘린더가 알아서 한다.
예: 1월 31일 + 1 month = 2월 28일 (또는 29일).

### 3-5. "이 날짜의 0시 0분" — `startOfDay(for:)`

```swift
let dayStart = cal.startOfDay(for: date)
```

이벤트를 "날짜별로 그룹핑" 할 때의 핵심. 시/분/초가 다른 두 `Date` 도 `startOfDay` 를 거치면 같은 키가 된다.

```swift
// EventIndex.swift
Dictionary(grouping: events) { calendar.startOfDay(for: $0.startDate) }
```

### 3-6. "하루 범위로 필터링"

`DayPopupDialog.swift` 패턴:

```swift
let dayStart = cal.startOfDay(for: date)
let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
// [dayStart, dayEnd) 반열린 구간으로 비교
event.startDate >= dayStart && event.startDate < dayEnd
```

> SQL `BETWEEN` 대신 **반열린 구간 `[start, end)`** 를 쓰는 게 시간 비교의 정석. 자정에 걸리는 이벤트 중복/누락이 안 생긴다.

### 3-7. "같은 달인지" — `isDate(_:equalTo:toGranularity:)`

```swift
let sameMonth = cal.isDate(date, equalTo: firstOfMonth, toGranularity: .month)
```

granularity 자리에 `.day` 면 "같은 날" 비교. 시/분/초가 달라도 같은 날이면 true.

> `date1 == date2` 는 **밀리초 단위까지 같아야** true 라서 잘 안 쓴다.

### 3-8. 빠른 유틸리티 — `isDateInToday` 등

```swift
cal.isDateInToday(date)
cal.isDateInYesterday(date)
cal.isDateInTomorrow(date)
cal.isDateInWeekend(date)
```

요건만 맞으면 위의 granularity 비교보다 가독성 좋음.

---

## 4. 포맷팅: 사람이 읽는 문자열로

### 4-1. `DateFormatter` (전통적, 정확한 제어)

`MonthlyCalendarView.swift` 패턴:

```swift
private static let yearMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyy년 M월"
    return f
}()

Text(Self.yearMonthFormatter.string(from: date))
```

- **`static let` 으로 캐싱** 하는 게 관용 — `DateFormatter` 인스턴스 생성이 의외로 비싸다.
- `dateFormat` 패턴: `yyyy` 연도, `M`/`MM` 월, `d`/`dd` 일, `H`/`HH` 24시, `h`/`hh` 12시, `m`/`mm` 분, `s` 초, `E`/`EEEE` 요일.
- 임의 로케일 출력은 반드시 `.locale` 명시.

### 4-2. `Date.formatted(...)` (Swift 5.5+, 더 권장)

내부에서 캐싱도 해주고 타입 안전.

```swift
date.formatted(.dateTime.year().month().day())
// 2026. 5. 20.
date.formatted(date: .long, time: .omitted)
// 2026년 5월 20일
date.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "ko_KR")))
// 수요일
```

> 단순 표시에는 `formatted` 가 짧고 안전. 다만 **고정 포맷 문자열을 정확히 통제** 해야 할 때 (외부 시스템과 주고받는 등) 는 여전히 `DateFormatter`.

### 4-3. 상대 시간 — `RelativeDateTimeFormatter`

```swift
let rdf = RelativeDateTimeFormatter()
rdf.locale = Locale(identifier: "ko_KR")
rdf.localizedString(for: yesterday, relativeTo: Date())  // "어제"
```

---

## 5. 비교 / 정렬

```swift
date1 < date2       // 시각 비교 가능 (Comparable)
date1 == date2      // 정확한 동일 시각 (millisecond)
[date1, date2, date3].sorted()
```

옵셔널 `Date?` 끼리는 `<` 안 됨. `if let` 으로 풀고 비교.

---

## 6. `DateInterval` — "기간"

```swift
let interval = DateInterval(start: dayStart, end: dayEnd)
interval.contains(someDate)
interval.duration            // 초 단위 (TimeInterval)
interval.intersects(other)
```

`CalendarStore` 의 `gridInterval` 이 이걸 써서 "이 달력 그리드가 표시하는 범위" 를 표현하고, `MonthlyCalendarView` 에서 `gridInterval.contains(event.startDate)` 로 필터한다.

---

## 7. `DateComponents` — 조립용

날짜의 부분들을 묶은 값 타입. **분해할 때** 또는 **조립할 때** 둘 다 쓴다.

### 분해

```swift
let dc = cal.dateComponents([.year, .month, .day], from: date)
print(dc.year!, dc.month!, dc.day!)
```

### 조립 ("2026-05-20 09:00" 만들기)

```swift
var dc = DateComponents()
dc.year = 2026; dc.month = 5; dc.day = 20
dc.hour = 9;    dc.minute = 0
let date = cal.date(from: dc)!
```

### 두 날짜 사이 — `dateComponents(_:from:to:)`

```swift
let diff = cal.dateComponents([.day], from: a, to: b)
print(diff.day!)   // 13
```

---

## 8. SwiftUI 와의 접점

### 8-1. `DatePicker`

```swift
@State private var date = Date()

DatePicker("시작", selection: $date, displayedComponents: [.date, .hourAndMinute])
```

`displayedComponents` 에 `.date` 만 / `.hourAndMinute` 만 / 둘 다 — 셋 중 선택.

### 8-2. 텍스트로 표시

```swift
Text(date, style: .date)     // 자동 로케일 포맷
Text(date, style: .time)
Text(date, style: .relative) // "5분 전"
Text(date, format: .dateTime.year().month())
```

> 단순 표시는 이게 제일 짧다. `DateFormatter` 안 만들어도 됨.

---

## 9. 흔한 함정

1. **`Date` 끝에 시/분/초가 붙어 있다.** "이 날짜 같음" 판정엔 `startOfDay` 통과 후 비교하거나 `isDate(_, equalTo:, toGranularity: .day)` 를 쓴다. 그냥 `==` 면 거의 다 false.
2. **`.weekday` 는 1=일요일.** 월요일=1 로 착각 잦음.
3. **`Calendar.current` 는 시스템 설정 의존.** 유닛 테스트에선 `Calendar(identifier: .gregorian)` + 고정 타임존을 직접 만들자.
4. **`DateFormatter` 매번 생성 금지.** `static let` 캐시 또는 `Date.formatted` 사용.
5. **타임존 미명시 + 자정 비교.** UTC 기준으로 비교했다가 한국 시간 기준으론 다른 날이 되는 경우. 일별 그룹핑은 항상 같은 `Calendar` 인스턴스로 `startOfDay` 통과시켜 키를 통일.
6. **음수 `value` 도 OK.** `cal.date(byAdding: .day, value: -1, to: x)` 어제.

---

## 10. 의사결정 치트시트

| 하고 싶은 것 | 코드 |
|---|---|
| 지금 시각 | `Date()` |
| 이 달의 1일 | `cal.dateInterval(of: .month, for: date)!.start` |
| 이 달의 일수 | `cal.range(of: .day, in: .month, for: date)!.count` |
| N일 더하기 | `cal.date(byAdding: .day, value: N, to: date)!` |
| 이 날짜의 0시 | `cal.startOfDay(for: date)` |
| 요일 (1~7) | `cal.component(.weekday, from: date)` |
| "같은 날인가" | `cal.isDate(a, equalTo: b, toGranularity: .day)` |
| "오늘인가" | `cal.isDateInToday(date)` |
| 하루 범위 필터 | `start <= x && x < cal.date(byAdding: .day, value: 1, to: start)!` |
| "yyyy년 M월" 출력 | `DateFormatter`(캐시) 또는 `date.formatted(...)` |
| 두 날짜 차이(일수) | `cal.dateComponents([.day], from: a, to: b).day!` |
| 기간 표현 | `DateInterval(start:end:)` + `.contains(_:)` |

---

## 11. 이 프로젝트에서 자주 쓰는 곳

- **월간 달력 그리드 생성**: [`CalendarMath.swift`](../../JHCalendar/Features/MonthlyCalendar/CalendarMath.swift) — `dateInterval` / `component(.weekday)` / `range(of:.day)` / `date(byAdding:.day)` / `isDate(_,equalTo:,toGranularity:)` 를 거의 다 쓴다.
- **이벤트 일자별 인덱싱**: [`EventIndex.swift`](../../JHCalendar/Features/MonthlyCalendar/EventIndex.swift) — `startOfDay` 를 키로 `Dictionary(grouping:)`.
- **하루 이벤트 쿼리**: [`DayPopupDialog.swift`](../../JHCalendar/Features/Event/DayPopupDialog.swift) — `startOfDay` + `byAdding:.day,value:1` 로 반열린 구간 만들어 `#Predicate` 에 사용.
- **년월 헤더 표시**: [`MonthlyCalendarView.swift`](../../JHCalendar/Features/MonthlyCalendar/MonthlyCalendarView.swift) — `static let DateFormatter` 캐시.
- **이벤트 시작/종일 입력**: [`AddEventDialog.swift`](../../JHCalendar/Features/Event/AddEventDialog.swift) — 종일 토글 시 `startOfDay` 로 시/분 절삭.

---

## 조금 더 (선택)

- **`Date.now`** — `Date()` 와 동일. 가독성 위주의 신문법.
- **`ISO8601DateFormatter`** — 서버와 `2026-05-20T09:00:00Z` 형태로 주고받을 때 전용.
- **`Duration` / `ContinuousClock`** — Swift Concurrency 에서 "5초 대기" 같은 시간 간격 표현. `Date` 와는 별개 타입.
- **`Calendar.dateInterval(of: .weekOfYear, for:)`** — 주 단위 시작/끝. 주간 뷰 만들 때.
- **`@Environment(\.calendar)`** — SwiftUI 에서 시스템 캘린더 주입받기. 테스트나 다국적 앱에서 유용.

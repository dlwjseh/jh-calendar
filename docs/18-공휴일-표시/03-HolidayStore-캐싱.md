# 단계 3: HolidayStore + 연 단위 캐싱

## 학습 목표
- DTO → 도메인 모델 (`Holiday`) 변환을 익힌다 — 디코딩 타입과 앱이 쓰는 타입을 분리하는 이유.
- 연 단위 캐시를 가진 **스토어** 를 만들고 SwiftUI 에서 `@EnvironmentObject` 로 주입한다.
- `UserDefaults` 에 Codable JSON 을 직렬화/역직렬화 해 디스크에 캐싱한다.
- `.task` modifier 와 비동기 흐름 + 메인 액터 격리를 익힌다.

## 사전 산출물
- [02-API-호출-JSON](02-API-호출-JSON.md) 의 `fetchHolidays(year:)` 가 동작.
- `HolidayDTO`, `HolidayAPIError` 정의.

## Swift / SwiftUI 개념

### DTO vs 도메인 모델

`HolidayDTO` (02 단계의 디코딩 타입) 는 응답 구조 그대로다 — `locdate: Int = 20260301`, `isHoliday: String = "Y"`. UI 가 다루기엔 어색하다.

→ 앱이 쓰는 **도메인 모델** 을 따로 둔다:

```swift
struct Holiday: Identifiable, Hashable, Codable {
    let id: UUID = UUID()
    let date: Date           // 2026-03-01 00:00 (startOfDay)
    let name: String         // "삼일절"
}
```

- `Identifiable` — `ForEach` 에 쓰기 위함.
- `Hashable` — `Set` / dictionary key.
- `Codable` — `UserDefaults` 저장용.

> Spring 비유: 외부 API DTO 와 내부 도메인 객체를 분리하는 헥사고날 결. 외부가 바뀌어도 도메인은 안전.

DTO → Domain 변환:

```swift
extension HolidayDTO {
    var asHoliday: Holiday? {
        guard isHoliday == "Y" else { return nil }
        // 20260301 → Date
        let s = String(locdate)
        guard s.count == 8,
              let y = Int(s.prefix(4)),
              let m = Int(s.dropFirst(4).prefix(2)),
              let d = Int(s.suffix(2)) else { return nil }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        guard let date = Calendar.current.date(from: comps) else { return nil }
        return Holiday(date: Calendar.current.startOfDay(for: date), name: dateName)
    }
}
```

> 함정: `Date` 는 시각까지 가진다 → 캘린더 표시는 `startOfDay` 로 정규화한 키여야 사용자 이벤트와 매칭 비교가 쉽다.

### `UserDefaults` + Codable

```swift
let key = "holidays.\(year)"
let data = try JSONEncoder().encode(holidays)
UserDefaults.standard.set(data, forKey: key)

// 읽기
if let data = UserDefaults.standard.data(forKey: key),
   let cached = try? JSONDecoder().decode([Holiday].self, from: data) {
    return cached
}
```

- `UserDefaults.standard` 는 macOS 의 plist 기반 KV store. 작은 데이터 (수십 KB 이내) 에 적합. 공휴일 한 해는 수십 항목이라 충분.
- 인코딩 실패는 거의 없지만 디코딩은 형식 변경 시 깨질 수 있음 → `try?` 로 nil 흡수 후 재 fetch.

> Spring 비유: 적합한 비유 없음. JS 의 `localStorage` 와 결이 비슷 (KV 영속).

### `@MainActor` + `ObservableObject` 스토어

```swift
@MainActor
final class HolidayStore: ObservableObject {
    @Published private(set) var byDay: [Date: Holiday] = [:]
    private var loadedYears: Set<Int> = []
    
    func load(year: Int) async {
        guard !loadedYears.contains(year) else { return }
        // 1) 캐시 시도
        if let cached = readCache(year: year) {
            merge(cached); loadedYears.insert(year); return
        }
        // 2) 네트워크
        do {
            let dtos = try await fetchHolidays(year: year)
            let holidays = dtos.compactMap { $0.asHoliday }
            writeCache(year: year, holidays: holidays)
            merge(holidays); loadedYears.insert(year)
        } catch {
            print("⚠️ holiday fetch failed:", error)
        }
    }
}
```

- `@MainActor` → 이 클래스의 모든 멤버는 메인 스레드에서만 접근. `@Published` 변경이 UI 업데이트를 안전하게 트리거.
- `byDay: [Date: Holiday]` — `startOfDay(for:)` 키 사전. 셀에서 `dict[startOfDay] != nil` 한 번에 조회 ([EventIndex.swift](../../JHCalendar/Features/MonthlyCalendar/EventIndex.swift) 의 `eventsByDay` 같은 결).
- `loadedYears` — 같은 연도 중복 요청 방지.
- `print` 에 머무는 에러 처리는 PoC 수준. 다음 단계에서도 충분 (UI 상으론 "공휴일이 안 보임" 으로 자연 fallback).

### `.task(id:)` modifier

```swift
.task(id: store.referenceDate) {
    let year = Calendar.current.component(.year, from: store.referenceDate)
    await holidayStore.load(year: year)
}
```

- `.task` 는 view 가 화면에 올라올 때 비동기 task 실행.
- `id:` 파라미터를 주면 그 값이 바뀔 때마다 task 가 **취소되고 다시 실행** — 월을 옮겨 연도가 바뀌면 자동 재요청.
- 같은 연도 안에서 월 이동만 하면 `load(year:)` 의 가드로 빠르게 return.

> JS 의 `useEffect(() => {...}, [year])` 와 결이 같음. Swift 는 cancel 까지 자동.

## 구현 가이드

### 1) `Holiday` 도메인 모델 + 변환

`JHCalendar/Features/Holiday/HolidayModels.swift` (또는 `HolidayAPI.swift` 와 같은 파일):

```swift
struct Holiday: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let name: String
    
    init(id: UUID = UUID(), date: Date, name: String) {
        // TODO
    }
}

extension HolidayDTO {
    var asHoliday: Holiday? {
        // TODO: locdate Int → Date 변환, isHoliday=="Y" 만 통과
    }
}
```

> 함정: `id: UUID = UUID()` 를 그대로 `Codable` 로 만들면 매번 디코드할 때 새 id 가 들어간다. 캐시 일관성 측면에서는 OK (그 해 안에서만 살아있는 id). 만약 일관 id 가 필요하면 `locdate + seq` 기반으로 deterministic id 를 만들 것.

### 2) `HolidayStore`

같은 폴더 `HolidayStore.swift`:

```swift
@MainActor
final class HolidayStore: ObservableObject {
    @Published private(set) var byDay: [Date: Holiday] = [:]
    private var loadedYears: Set<Int> = []
    
    func load(year: Int) async {
        // TODO
    }
    
    private func readCache(year: Int) -> [Holiday]? {
        // TODO: UserDefaults.standard.data(forKey:) → JSONDecoder
    }
    
    private func writeCache(year: Int, holidays: [Holiday]) {
        // TODO: JSONEncoder().encode → UserDefaults.standard.set
    }
    
    private func merge(_ holidays: [Holiday]) {
        // TODO: byDay[startOfDay(for:)] = holiday
    }
}
```

체크포인트:
- [ ] `load(year:)` 가 같은 연도 중복 호출 시 즉시 return
- [ ] 캐시 hit / miss 로 분기, miss 면 네트워크 + 캐시 저장
- [ ] `merge` 는 dict 키를 반드시 `startOfDay(for:)` 정규화

### 3) 앱 진입점에서 주입

`JHCalendarApp.swift`:

```swift
@StateObject private var holidayStore = HolidayStore()

WindowGroup {
    ContentView()
        .environmentObject(holidayStore)
}
```

> 참고: `CalendarStore` 도 같은 패턴으로 이미 들어가 있을 것 — 그 옆에 한 줄 더.

### 4) `MonthlyCalendarView` 에서 `.task(id:)`

`MonthlyCalendarView.swift`:

```swift
@EnvironmentObject private var holidayStore: HolidayStore

var body: some View {
    VStack { ... }
        .task(id: store.referenceDate) {
            let year = Calendar.current.component(.year, from: store.referenceDate)
            await holidayStore.load(year: year)
        }
}
```

- 첫 진입 + 월 이동 시 모두 트리거. 같은 연도 안에서는 store 가 빠르게 return.
- 12월 → 1월 같은 경계 전환 시 자동으로 새 연도 로드.

### 5) 임시 로그로 동작 확인

PoC 답게:
```swift
.task(id: store.referenceDate) {
    let year = Calendar.current.component(.year, from: store.referenceDate)
    await holidayStore.load(year: year)
    print("holidays byDay.count =", holidayStore.byDay.count)
}
```

- 첫 실행: 네트워크 호출 → byDay 가 채워짐.
- 앱 재시작: 캐시 hit → 네트워크 안 침. (네트워크 인디케이터 / 콘솔 로그로 확인.)
- 연도 이동: 캐시 없는 해는 다시 네트워크.

### 6) 함정 대응 — 응답 0건 / 에러 본문

02 단계에서 보류한 케이스:
- 응답에서 `body.items` 가 빈 문자열로 올 때 → `JSONDecoder` 가 실패 → `do/catch` 에서 잡힘 → store 는 그냥 빈 상태 유지.
- 한 건짜리 연도 (`item` 이 객체 1개로 옴) → 거의 안 일어나지만 안전 위해 디코더에 single-or-array 처리를 더 깔 수도. **본 단계 생략**, 부딪히면 그때 보강.

## 직접 구현하기
- [ ] `Holiday` struct 정의 (Codable, Identifiable, Hashable)
- [ ] `HolidayDTO.asHoliday` 변환 (`locdate` Int → Date)
- [ ] `HolidayStore` 작성 (`@MainActor`, `byDay`, `loadedYears`, `load`, 캐시 R/W, merge)
- [ ] `JHCalendarApp` 에서 `@StateObject` + `.environmentObject(...)`
- [ ] `MonthlyCalendarView` 에 `@EnvironmentObject` + `.task(id:)`
- [ ] 첫 실행 — 네트워크 호출 발생, byDay 채워짐 (콘솔로 확인)
- [ ] 앱 재시작 — UserDefaults 에서 캐시 읽기 (네트워크 호출 0회)
- [ ] 월 이동으로 연도 경계 넘기기 — 새 연도 캐시 미스 → 네트워크 호출

## 자가 점검
- 빌드 + 실행 OK?
- 첫 실행 시 byDay 가 채워지는가? (예: 2026 → 약 15건)
- 앱을 완전히 종료 후 재실행해도 같은 byDay 가 즉시 채워지는가? (오프라인 상태에서 재실행해 확인하면 가장 확실)
- 12월에서 1월로 넘어가면 새 연도 fetch 가 일어나는가?
- 퀴즈: `@MainActor` 가 안 붙어있으면 무슨 문제가 생기는가? — `@Published` 업데이트가 백그라운드 스레드에서 일어나면 SwiftUI 가 경고. 비결정 동작 가능.
- 퀴즈: `loadedYears` 에 의존하지 않고 `byDay.keys.contains` 만으로 중복 가드해도 되나? — 안 됨. 그 해에 공휴일 0건이 정상인 시나리오가 있다면 (드물지만) 매번 재요청.

## Claude 리뷰 체크리스트
- [ ] `Holiday` 가 `Codable` (UserDefaults 저장 가능)
- [ ] `byDay` 키가 `startOfDay(for:)` 로 정규화
- [ ] 캐시 hit 시 네트워크 호출 안 일어남
- [ ] `.task(id:)` 의 id 가 적절 (연도가 바뀔 때만 실제 fetch)
- [ ] 에러 시 앱이 죽지 않고 byDay 가 빈 상태로 살아 있음
- [ ] `@MainActor` 격리

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 현재 연도의 캐시는 **N일 뒤 stale** 로 보고 강제 재요청 (임시공휴일 대비). `cachedAt: Date` 필드 + TTL.
- `HolidayStore` 를 `@Observable` 매크로 버전으로 마이그레이션해 `@Published` / `ObservableObject` 보일러를 줄일 수 있음. 다만 `CalendarStore` 가 아직 `ObservableObject` 라 일관성 차원에서 보류.
- 진짜 빨리 띄우려면 last-known-good 캐시 표시 → 백그라운드 갱신 패턴 (stale-while-revalidate). 본 프로젝트엔 오버킬.
